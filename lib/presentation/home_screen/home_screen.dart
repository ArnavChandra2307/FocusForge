import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navigation.dart';
import '../settings_screen/settings_screen.dart';
import '../stats_screen/stats_screen.dart';
import './widgets/home_app_bar_widget.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _countdownTimer;

  Map<String, dynamic> _userData = {
    'name': '',
    'email': '',
    'streak': 0,
    'todayMinutes': 0,
    'goalMinutes': 120,
    'avatarUrl': '',
    'avatarSemanticLabel': '',
  };
  List<Map<String, dynamic>> _tasks = [];
  Map<String, double> _subjectMinutes = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTasks();
    NotificationService.scheduleSessionReminders();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Data loading (unchanged) ───────────────────────────────────────────────

  Future<void> _loadTasks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(data);
      });
      debugPrint('✅ TASKS LOADED: $_tasks');
    } catch (e) {
      debugPrint('❌ TASK LOAD ERROR: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('No logged in user');
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final sessions = await Supabase.instance.client
          .from('study_sessions')
          .select('subject, duration_minutes, created_at')
          .eq('user_id', user.id)
          .gte('created_at', startOfWeek.toUtc().toIso8601String())
          .lt('created_at', endOfWeek.toUtc().toIso8601String())
          .order('created_at');

      final Map<String, double> subjectData = {};
      for (final session in sessions) {
        final subject = (session['subject'] as String?) ?? 'Unknown';
        final minutes =
        ((session['duration_minutes'] as num?) ?? 0).toDouble();
        if (minutes <= 0) continue;
        subjectData[subject] = (subjectData[subject] ?? 0) + minutes;
      }

      final String? lastActiveDateStr =
      response['last_active_date'] as String?;
      final DateTime? lastActiveDate = lastActiveDateStr != null
          ? DateTime.parse(lastActiveDateStr)
          : null;
      final bool isNewDay =
          lastActiveDate == null || lastActiveDate.isBefore(today);

      final DateTime yesterday = today.subtract(const Duration(days: 1));
      final bool streakValid = lastActiveDate != null &&
          !DateTime(lastActiveDate.year, lastActiveDate.month,
              lastActiveDate.day)
              .isBefore(yesterday);

      final int currentStreak = response['streak'] ?? 0;
      if (!streakValid && currentStreak > 0) {
        await Supabase.instance.client
            .from('profiles')
            .update({'streak': 0}).eq('id', user.id);
      }

      if (isNewDay) {
        await Supabase.instance.client
            .from('profiles')
            .update({'today_minutes': 0}).eq('id', user.id);
      }

      setState(() {
        _subjectMinutes = subjectData;
        _userData = {
          'name': response['name'] ?? 'User',
          'email': response['email'] ?? '',
          'streak': (!streakValid) ? 0 : (response['streak'] ?? 0),
          'todayMinutes': isNewDay ? 0 : (response['today_minutes'] ?? 0),
          'goalMinutes': 120,
          'avatarUrl': response['avatar_url'] ?? '',
          'avatarSemanticLabel': '',
        };
      });
    } catch (e) {
      debugPrint('PROFILE FETCH ERROR: $e');
    }

    await NotificationService.updateNotificationsBasedOnProgress();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
      // FAB — only on home tab
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.session);
          await _loadUserData();
        },
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(
          'Start Session',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      )
          : null,
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeTab(),
        const StatsScreen(),
        SettingsScreen(
          userData: _userData,
          onNameUpdated: (newName) {
            setState(() => _userData = {..._userData, 'name': newName});
          },
          onAvatarUpdated: (newUrl) {
            setState(() => _userData = {..._userData, 'avatarUrl': newUrl});
          },
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HomeAppBarWidget(userData: _userData),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: _buildContent(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStreakHeroCard(),
        const SizedBox(height: 12),
        _buildSubjectDistribution(),
        const SizedBox(height: 12),
        _buildTasksCard(),
        const SizedBox(height: 12),
        _buildImportantTasksCard(),
      ],
    );
  }

  // ── Streak Hero Card ───────────────────────────────────────────────────────

  Widget _buildStreakHeroCard() {
    final int todayMinutes = _userData['todayMinutes'] as int;
    final int streak = _userData['streak'] as int;
    final double progress = (todayMinutes / 120.0).clamp(0.0, 1.0);
    final bool goalMet = progress >= 1.0;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final remaining = midnight.difference(now);
    final hh = remaining.inHours.toString().padLeft(2, '0');
    final mm = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final bool isUrgent = remaining.inHours < 3 && !goalMet;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent
              ? AppTheme.warning.withOpacity(0.3)
              : goalMet
              ? AppTheme.success.withOpacity(0.2)
              : AppTheme.borderSubtle,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // ── Top row: streak number + progress ring ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT STREAK',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$streak',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 56,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textPrimary,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      streak == 1 ? 'day' : 'days',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress ring
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: progress,
                    goalMet: goalMet,
                    isUrgent: isUrgent,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'today',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress bar ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatMinutes(todayMinutes)} studied',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: goalMet
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '2h goal',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppTheme.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goalMet
                        ? AppTheme.success
                        : isUrgent
                        ? AppTheme.warning
                        : AppTheme.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Divider ──
          const Divider(color: AppTheme.borderSubtle, height: 1, thickness: 0.5),

          const SizedBox(height: 14),

          // ── Countdown or goal met ──
          if (goalMet)
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.success, size: 15),
                const SizedBox(width: 8),
                Text(
                  'Daily goal achieved — streak secured',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  isUrgent
                      ? Icons.warning_amber_rounded
                      : Icons.timer_outlined,
                  color:
                  isUrgent ? AppTheme.warning : AppTheme.textMuted,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  isUrgent ? 'Streak ending soon' : 'Resets in',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isUrgent
                        ? AppTheme.warning
                        : AppTheme.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  '$hh:$mm:$ss',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isUrgent
                        ? AppTheme.warning
                        : AppTheme.textPrimary,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Subject Distribution ───────────────────────────────────────────────────

  Widget _buildSubjectDistribution() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'This Week'),
          const SizedBox(height: 14),

          if (_subjectMinutes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No sessions this week. Start studying!',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            )
          else ...[
            // Total this week
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _formatMinutes(_subjectMinutes.values
                      .fold(0.0, (a, b) => a + b)
                      .toInt()),
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 28,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'total',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject bars
            ..._subjectMinutes.entries.map((entry) {
              final maxMinutes = _subjectMinutes.values
                  .reduce((a, b) => a > b ? a : b);
              final ratio = entry.value / maxMinutes;
              final color = AppTheme.subjectColor(entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _formatMinutes(entry.value.toInt()),
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 3,
                        backgroundColor: AppTheme.borderSubtle,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Tasks Card ─────────────────────────────────────────────────────────────

  Widget _buildTasksCard() {
    final pending = _tasks
        .where((t) => t['important'] != true && t['completed'] != true)
        .toList();
    final completed = _tasks
        .where((t) => t['important'] != true && t['completed'] == true)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 0),
            child: Row(
              children: [
                _CardHeader(title: 'Tasks'),
                const Spacer(),
                if (pending.isNotEmpty)
                  _CountBadge(count: pending.length),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _showAddTaskDialog,
                  icon: const Icon(Icons.add_rounded,
                      color: AppTheme.accent, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (pending.isEmpty && completed.isEmpty)
            _EmptyTasksHint(message: 'No tasks yet — add one')
          else ...[
            ...pending.map((t) => _buildTaskTile(t, false)),
            if (completed.isNotEmpty) ...[
              _SectionLabel(label: 'Completed'),
              ...completed.map((t) => _buildTaskTile(t, false)),
            ],
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildImportantTasksCard() {
    final pending = _tasks
        .where((t) => t['important'] == true && t['completed'] != true)
        .toList()
      ..sort((a, b) {
        final da = a['deadline'] != null
            ? DateTime.parse(a['deadline'])
            : DateTime(2100);
        final db = b['deadline'] != null
            ? DateTime.parse(b['deadline'])
            : DateTime(2100);
        return da.compareTo(db);
      });
    final completed = _tasks
        .where((t) => t['important'] == true && t['completed'] == true)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.warning.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 0),
            child: Row(
              children: [
                _CardHeader(title: 'Important', color: AppTheme.warning),
                const Spacer(),
                if (pending.isNotEmpty)
                  _CountBadge(
                      count: pending.length, color: AppTheme.warning),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _showAddTaskDialog,
                  icon: const Icon(Icons.add_rounded,
                      color: AppTheme.warning, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (pending.isEmpty && completed.isEmpty)
            _EmptyTasksHint(message: 'No important tasks')
          else ...[
            ...pending.map((t) => _buildTaskTile(t, true)),
            if (completed.isNotEmpty) ...[
              _SectionLabel(label: 'Completed'),
              ...completed.map((t) => _buildTaskTile(t, true)),
            ],
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Task Tile (logic preserved, visuals updated) ───────────────────────────

  Widget _buildTaskTile(Map<String, dynamic> task, bool isImportant) {
    final bool completed = task['completed'] == true;
    final String subject = task['subject'] ?? '';
    final String? deadlineStr = task['deadline'] as String?;
    DateTime? deadline;
    if (deadlineStr != null) {
      try {
        deadline = DateTime.parse(deadlineStr);
      } catch (_) {}
    }

    int? daysLeft;
    Color deadlineColor = AppTheme.warning;
    if (deadline != null) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final deadlineDay =
      DateTime(deadline.year, deadline.month, deadline.day);
      daysLeft = deadlineDay.difference(today).inDays;
      if (daysLeft <= 1) {
        deadlineColor = AppTheme.danger;
      } else if (daysLeft <= 3) {
        deadlineColor = AppTheme.warning;
      } else {
        deadlineColor = AppTheme.success;
      }
    }

    return Dismissible(
      key: Key(task['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.dangerTint,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.danger, size: 18),
      ),
      onDismissed: (_) async {
        await Supabase.instance.client
            .from('tasks')
            .delete()
            .eq('id', task['id']);
        _loadTasks();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: completed
              ? Colors.transparent
              : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: completed
                ? AppTheme.borderSubtle
                : AppTheme.borderDefault,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () async {
                await Supabase.instance.client
                    .from('tasks')
                    .update({'completed': !completed})
                    .eq('id', task['id']);
                _loadTasks();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: completed
                      ? AppTheme.successTint
                      : Colors.transparent,
                  border: Border.all(
                    color: completed
                        ? AppTheme.success
                        : AppTheme.borderDefault,
                    width: 0.5,
                  ),
                ),
                child: completed
                    ? const Icon(Icons.check_rounded,
                    color: AppTheme.success, size: 13)
                    : null,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['task'] ?? '',
                    style: GoogleFonts.dmSans(
                      color: completed
                          ? AppTheme.textMuted
                          : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppTheme.textMuted,
                    ),
                  ),
                  if (subject.isNotEmpty || daysLeft != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (subject.isNotEmpty)
                          Text(
                            subject,
                            style: GoogleFonts.dmSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        if (subject.isNotEmpty && daysLeft != null)
                          Text(
                            ' · ',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.textDisabled,
                              fontSize: 11,
                            ),
                          ),
                        if (daysLeft != null)
                          Text(
                            daysLeft == 0
                                ? 'Due today'
                                : daysLeft == 1
                                ? 'Due tomorrow'
                                : '$daysLeft days left',
                            style: GoogleFonts.dmSans(
                              color: deadlineColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Task Dialog (logic preserved, visuals updated) ────────────────────

  Future<void> _showAddTaskDialog() async {
    final TextEditingController taskController = TextEditingController();
    String selectedSubject = 'Physics';
    bool important = false;
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.borderDefault, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'New task',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted, size: 20),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Task name
                _DialogLabel(label: 'Task'),
                const SizedBox(height: 6),
                TextField(
                  controller: taskController,
                  autofocus: true,
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: GoogleFonts.dmSans(
                        color: AppTheme.textDisabled, fontSize: 14),
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppTheme.borderDefault, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppTheme.borderDefault, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppTheme.accent, width: 1.0),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Subject
                _DialogLabel(label: 'Subject'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.borderDefault, width: 0.5),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSubject,
                    isExpanded: true,
                    dropdownColor: AppTheme.backgroundSecondary,
                    underline: const SizedBox(),
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary, fontSize: 14),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textMuted, size: 18),
                    items: [
                      'Physics',
                      'Mathematics',
                      'Chemistry',
                      'Biology',
                      'English Language',
                      'English Literature',
                      'Hindi',
                      'Geography',
                      'History & Civics',
                      'Computer Applications',
                    ]
                        .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: GoogleFonts.dmSans(
                                color: AppTheme.textPrimary,
                                fontSize: 13))))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedSubject = v!),
                  ),
                ),

                const SizedBox(height: 16),

                // Important toggle
                GestureDetector(
                  onTap: () =>
                      setDialogState(() => important = !important),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: important
                          ? AppTheme.warningTint
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: important
                            ? AppTheme.warning.withOpacity(0.3)
                            : AppTheme.borderDefault,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          important
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: important
                              ? AppTheme.warning
                              : AppTheme.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          important ? 'Marked as important' : 'Mark as important',
                          style: GoogleFonts.dmSans(
                            color: important
                                ? AppTheme.warning
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Deadline picker
                if (important) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.accent,
                              surface: AppTheme.backgroundSecondary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: selectedDate != null
                            ? AppTheme.accentTint
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedDate != null
                              ? AppTheme.accent.withOpacity(0.3)
                              : AppTheme.borderDefault,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: selectedDate != null
                                ? AppTheme.accent
                                : AppTheme.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            selectedDate == null
                                ? 'Set deadline'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                            style: GoogleFonts.dmSans(
                              color: selectedDate != null
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // Add button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (taskController.text.trim().isEmpty) return;
                      final user =
                          Supabase.instance.client.auth.currentUser;
                      if (user == null) return;
                      await Supabase.instance.client
                          .from('tasks')
                          .insert({
                        'user_id': user.id,
                        'task': taskController.text.trim(),
                        'subject': selectedSubject,
                        'important': important,
                        'deadline': selectedDate?.toIso8601String(),
                        'completed': false,
                      });
                      if (context.mounted) Navigator.pop(context);
                      _loadTasks();
                      if (important && selectedDate != null) {
                        await NotificationService
                            .scheduleDeadlineNotifications(
                          tasks: _tasks,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Add task',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Local widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _CardHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _CardHeader({
    required this.title,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({
    required this.count,
    this.color = AppTheme.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: AppTheme.textDisabled,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmptyTasksHint extends StatelessWidget {
  final String message;
  const _EmptyTasksHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
      child: Text(
        message,
        style: GoogleFonts.dmSans(
          color: AppTheme.textDisabled,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DialogLabel extends StatelessWidget {
  final String label;
  const _DialogLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.dmSans(
        color: AppTheme.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Progress ring painter ──────────────────────────────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final bool goalMet;
  final bool isUrgent;

  const _ProgressRingPainter({
    required this.progress,
    required this.goalMet,
    required this.isUrgent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.borderSubtle
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    if (progress <= 0) return;

    // Progress arc
    final color = goalMet
        ? AppTheme.success
        : isUrgent
        ? AppTheme.warning
        : AppTheme.accent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963,
      progress.clamp(0.0, 1.0) * 2 * 3.1415926,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress ||
          old.goalMet != goalMet ||
          old.isUrgent != isUrgent;
}