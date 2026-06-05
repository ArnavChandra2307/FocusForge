import 'dart:ui' show FontFeature;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedWeekOffset = 0;

  List<Map<String, dynamic>> _weeklyDataMaps    = [];
  List<Map<String, dynamic>> _topicProgressMaps = [];
  double _totalWeekHours = 0;
  int _goalDays      = 0;
  int _totalSessions = 0;
  int _streak        = 0;
  bool _loading      = true;

  final List<String> _weekDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading (unchanged) ───────────────────────────────────────────────

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('streak')
          .eq('id', user.id)
          .single();

      final now   = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentWeekMonday =
      today.subtract(Duration(days: today.weekday - 1));
      final startOfWeek =
      currentWeekMonday.add(Duration(days: _selectedWeekOffset * 7));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final sessions = await Supabase.instance.client
          .from('study_sessions')
          .select('subject, topic, duration_minutes, created_at')
          .eq('user_id', user.id)
          .gte('created_at', startOfWeek.toUtc().toIso8601String())
          .lt('created_at', endOfWeek.toUtc().toIso8601String())
          .order('created_at', ascending: true);

      final Map<String, Map<String, dynamic>> topicMap       = {};
      final Map<String, List<double>>         subjectDailyH  = {};
      final Map<String, int>                  dailyMinutes   = {};
      double totalMinutes  = 0;
      int    weekSessions  = 0;

      for (final session in sessions) {
        final String subject = (session['subject'] as String?) ?? 'Unknown';
        final String topic   = (session['topic']   as String?) ?? 'No Topic';
        final int    minutes = (session['duration_minutes'] as int?) ?? 0;
        if (minutes <= 0) continue;

        final DateTime createdAt =
        DateTime.parse(session['created_at'] as String).toLocal();
        final double hours = minutes / 60.0;
        totalMinutes += minutes;
        weekSessions++;

        subjectDailyH.putIfAbsent(subject, () => List.filled(7, 0.0));
        final int weekday = createdAt.weekday - 1;
        if (weekday >= 0 && weekday < 7) {
          subjectDailyH[subject]![weekday] += hours;
        }

        final String key = '$subject|||$topic';
        if (!topicMap.containsKey(key)) {
          topicMap[key] = {
            'subject': subject, 'topic': topic,
            'sessions': 0, 'totalHours': 0.0,
            'lastStudied': createdAt, 'completion': 0.0,
          };
        }
        topicMap[key]!['sessions'] =
            (topicMap[key]!['sessions'] as int) + 1;
        topicMap[key]!['totalHours'] =
            (topicMap[key]!['totalHours'] as double) + hours;
        if (createdAt
            .isAfter(topicMap[key]!['lastStudied'] as DateTime)) {
          topicMap[key]!['lastStudied'] = createdAt;
        }

        final String dateKey =
            '${createdAt.year}-${createdAt.month}-${createdAt.day}';
        dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + minutes;
      }

      int goalDays = 0;
      for (final t in dailyMinutes.values) {
        if (t >= 120) goalDays++;
      }

      final List<Map<String, dynamic>> weeklyMaps = [];
      subjectDailyH.forEach((subject, hoursList) {
        final double total = hoursList.fold(0.0, (a, b) => a + b);
        weeklyMaps.add({
          'subject': subject,
          'hours': List<double>.from(hoursList),
          'totalHours': total,
          'color': AppTheme.subjectColor(subject),
        });
      });
      weeklyMaps.sort((a, b) =>
          (b['totalHours'] as double).compareTo(a['totalHours'] as double));

      if (totalMinutes > 0) {
        for (final key in topicMap.keys) {
          final double topicH = topicMap[key]!['totalHours'] as double;
          topicMap[key]!['completion'] =
              (topicH / (totalMinutes / 60.0)).clamp(0.0, 1.0);
        }
      }

      final List<Map<String, dynamic>> topicList =
      topicMap.values.toList();
      topicList.sort((a, b) =>
          (b['totalHours'] as double).compareTo(a['totalHours'] as double));

      if (mounted) {
        setState(() {
          _weeklyDataMaps    = weeklyMaps;
          _topicProgressMaps = topicList;
          _totalWeekHours    = totalMinutes / 60.0;
          _goalDays          = goalDays;
          _totalSessions     = weekSessions;
          _streak            = (profile['streak'] as int?) ?? 0;
          _loading           = false;
        });
      }
    } catch (e) {
      debugPrint('STATS ERROR: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers (unchanged) ────────────────────────────────────────────────────

  String _formatCurrentMonth() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekStart = monday.add(Duration(days: _selectedWeekOffset * 7));
    return '${months[weekStart.month - 1]} ${weekStart.year}';
  }

  String _formatWeekRange() {
    final now  = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: _selectedWeekOffset * 7));
    final end = start.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[start.month - 1]} ${start.day} – '
        '${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  List<BarChartGroupData> _buildDailyBarGroups() {
    final List<double> dailyTotals = List.filled(7, 0.0);
    for (final d in _weeklyDataMaps) {
      final hours = d['hours'] as List<double>;
      for (int i = 0; i < 7; i++) dailyTotals[i] += hours[i];
    }
    return List.generate(7, (i) {
      final bool goalMet = dailyTotals[i] >= 2.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dailyTotals[i],
            width: 18,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(5)),
            color: goalMet
                ? AppTheme.accent
                : AppTheme.accent.withOpacity(0.35),
          ),
        ],
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 2,
        ),
      );
    }

    return Column(
      children: [
        _buildAppBar(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWeeklyHoursTab(),
              _buildTopicProgressTab(),
              _buildWeeklyReportTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Statistics',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.accentTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.accent.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 11, color: AppTheme.accent),
                const SizedBox(width: 5),
                Text(
                  _formatCurrentMonth(),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.backgroundPrimary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.accent,
        indicatorWeight: 1.5,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: 'Hours'),
          Tab(text: 'Topics'),
          Tab(text: 'Report'),
        ],
      ),
    );
  }

  // ── Tab 1: Weekly Hours ────────────────────────────────────────────────────

  Widget _buildWeeklyHoursTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildWeekSelector(),
        const SizedBox(height: 12),
        _buildWeeklyBarChart(),
        const SizedBox(height: 12),
        _buildSubjectHoursList(),
      ],
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() => _selectedWeekOffset--);
              _loadStats();
            },
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppTheme.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Column(
            children: [
              Text(
                _selectedWeekOffset == 0
                    ? 'This Week'
                    : _selectedWeekOffset == -1
                    ? 'Last Week'
                    : '${_selectedWeekOffset.abs()} weeks ago',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _formatWeekRange(),
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          IconButton(
            onPressed: _selectedWeekOffset < 0
                ? () {
              setState(() => _selectedWeekOffset++);
              _loadStats();
            }
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _selectedWeekOffset < 0
                  ? AppTheme.textSecondary
                  : AppTheme.textDisabled,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily study hours',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Total: ${_totalWeekHours.toStringAsFixed(1)}h this week',
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.accent),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                    AppTheme.backgroundSecondary,
                    getTooltipItem:
                        (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)}h',
                          GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.accent,
                          ),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _weekDays[value.toInt()],
                        style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}h',
                        style: GoogleFonts.dmSans(
                            fontSize: 9, color: AppTheme.textMuted),
                      ),
                      reservedSize: 26,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.borderSubtle,
                    strokeWidth: 0.5,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildDailyBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectHoursList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hours per subject',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          if (_weeklyDataMaps.isEmpty)
            Text(
              'No sessions this week.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textMuted),
            )
          else
            ..._weeklyDataMaps.map((data) {
              final double hours = data['totalHours'] as double;
              final Color color  = data['color'] as Color;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(data['subject'] as String,
                              style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ]),
                        Text(
                          '${hours.toStringAsFixed(1)}h',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: hours / 12.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 3,
                          backgroundColor: AppTheme.borderSubtle,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Tab 2: Topic Progress ──────────────────────────────────────────────────

  Widget _buildTopicProgressTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Topics covered this week',
          style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),
        if (_topicProgressMaps.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.borderSubtle, width: 0.5),
            ),
            child: Text(
              'No topics recorded yet. Start a session and enter a topic.',
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppTheme.textMuted, height: 1.5),
            ),
          )
        else
          ..._topicProgressMaps.map((t) => _buildTopicCard(t)),
      ],
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    final double completion =
    topic['completion'] as double;
    final Color subjectColor =
    AppTheme.subjectColor(topic['subject'] as String);
    final bool isCompleted = completion >= 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? AppTheme.success.withOpacity(0.2)
                : AppTheme.borderSubtle,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    topic['subject'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: subjectColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Complete',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${(completion * 100).toInt()}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? AppTheme.success
                        : subjectColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              topic['topic'] as String,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: completion),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 3,
                  backgroundColor: AppTheme.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? AppTheme.success : subjectColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 11, color: AppTheme.textMuted),
                const SizedBox(width: 3),
                Text(
                  '${(topic['totalHours'] as double).toStringAsFixed(1)}h',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.repeat_rounded,
                    size: 11, color: AppTheme.textMuted),
                const SizedBox(width: 3),
                Text(
                  '${topic['sessions']} sessions',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppTheme.textMuted),
                ),
                const Spacer(),
                Text(
                  (topic['lastStudied'] as DateTime)
                      .toLocal()
                      .toString()
                      .split(' ')[0],
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Weekly Report ───────────────────────────────────────────────────

  Widget _buildWeeklyReportTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildReportHeader(),
        const SizedBox(height: 12),
        _buildReportSummaryCards(),
        const SizedBox(height: 12),
        _buildReportSubjectBreakdown(),
        const SizedBox(height: 12),
        _buildReportInsights(),
      ],
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Weekly Report',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successTint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.2),
                      width: 0.5),
                ),
                child: Text(
                  'Generated',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatWeekRange(),
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            'You studied for ${_totalWeekHours.toStringAsFixed(1)}h '
                'across ${_weeklyDataMaps.length} subjects, meeting your '
                'daily goal on $_goalDays of 7 days. '
                'Current streak: $_streak days.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummaryCards() {
    final List<Map<String, dynamic>> cards = [
      {
        'label': 'Total Hours',
        'value': '${_totalWeekHours.toStringAsFixed(1)}h',
        'icon': Icons.access_time_rounded,
        'color': AppTheme.accent,
        'sub': '${_weeklyDataMaps.length} subjects',
      },
      {
        'label': 'Goal Days',
        'value': '$_goalDays/7',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppTheme.success,
        'sub': '2h daily target',
      },
      {
        'label': 'Sessions',
        'value': '$_totalSessions',
        'icon': Icons.trending_up_rounded,
        'color': AppTheme.warning,
        'sub': 'This week',
      },
      {
        'label': 'Streak',
        'value': '$_streak',
        'icon': Icons.local_fire_department_rounded,
        'color': AppTheme.danger,
        'sub': 'Current',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final card  = cards[i];
        final Color color = card['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withOpacity(0.15), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(card['icon'] as IconData,
                      color: color, size: 16),
                  Text(
                    card['value'] as String,
                    style: GoogleFonts.instrumentSerif(
                      fontSize: 22,
                      color: color,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['label'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    card['sub'] as String,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportSubjectBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject breakdown',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          if (_weeklyDataMaps.isEmpty)
            Text('No data.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppTheme.textMuted))
          else
            ..._weeklyDataMaps.map((data) {
              final hours = (data['hours'] as List<double>)
                  .fold(0.0, (a, b) => a + b);
              final Color color = data['color'] as Color;
              final double total =
              _totalWeekHours == 0 ? 1 : _totalWeekHours;
              final pct =
              (hours / total * 100).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['subject'] as String,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary),
                      ),
                    ),
                    Text(
                      '${hours.toStringAsFixed(1)}h',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: hours / total,
                          minHeight: 3,
                          backgroundColor: AppTheme.borderSubtle,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$pct%',
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppTheme.textMuted),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReportInsights() {
    final sorted = [..._weeklyDataMaps]
      ..sort((a, b) => (b['totalHours'] as double)
          .compareTo(a['totalHours'] as double));

    final strongest = sorted.isNotEmpty ? sorted.first : null;
    final weakest   = sorted.length > 1  ? sorted.last  : null;

    final List<Map<String, dynamic>> insights = [
      if (strongest != null)
        {
          'icon':  Icons.trending_up_rounded,
          'title': 'Strongest subject',
          'body':  '${strongest['subject']} — '
              '${(strongest['totalHours'] as double).toStringAsFixed(1)}h this week.',
          'color': AppTheme.success,
        },
      if (weakest != null)
        {
          'icon':  Icons.warning_amber_rounded,
          'title': 'Needs attention',
          'body':  '${weakest['subject']} had the least study time.',
          'color': AppTheme.warning,
        },
      {
        'icon':  Icons.local_fire_department_rounded,
        'title': 'Current streak',
        'body':  'You are on a $_streak day streak. Keep going.',
        'color': AppTheme.accent,
      },
      {
        'icon':  Icons.book_outlined,
        'title': 'Sessions this week',
        'body':  'Completed $_totalSessions study sessions.',
        'color': AppTheme.textSecondary,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) {
            final Color color = insight['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: color.withOpacity(0.15), width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(insight['icon'] as IconData,
                        color: color, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight['title'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            insight['body'] as String,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}