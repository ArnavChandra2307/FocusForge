import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../services/session_foreground_service.dart';
import '../../theme/app_theme.dart';
import './widgets/session_controls_widget.dart';
import './widgets/session_music_widget.dart';
import './widgets/session_photo_capture_widget.dart';
import './widgets/session_subject_selector_widget.dart';
import './widgets/session_timer_widget.dart';

enum SessionState { idle, running, paused, completed }

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin {
  SessionState _sessionState = SessionState.idle;
  String _selectedSubject = 'Physics';
  String _topicText = '';
  int _elapsedSeconds = 0;
  static const int _goalSeconds = 7200;
  bool _musicPlaying = false;
  bool _goalReached = false;
  int _todayMinutes = 0;

  Timer? _timer;

  // Pulse animation — only used during running state
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Glow animation — passed to widgets that need it
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  final TextEditingController _topicController = TextEditingController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _fetchTodayMinutes();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _timer?.cancel();
    _glowController.dispose();
    _pulseController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  // ── Foreground task callback (unchanged) ──────────────────────────────────

  void _onTaskData(Object data) {
    if (data is Map) {
      final button = data['button'];
      if (!mounted) return;
      if (button == 'pause' && _sessionState == SessionState.running) {
        _pauseSession();
      } else if (button == 'pause' && _sessionState == SessionState.paused) {
        _resumeSession();
      } else if (button == 'end') {
        _endSession();
      }
    }
  }

  // ── Data (unchanged) ──────────────────────────────────────────────────────

  Future<void> _fetchTodayMinutes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('today_minutes')
        .eq('id', user.id)
        .single();
    if (mounted) {
      setState(() =>
      _todayMinutes = (profile['today_minutes'] as int?) ?? 0);
    }
  }

  // ── Session logic (unchanged) ─────────────────────────────────────────────

  void _startSession() {
    debugPrint('▶️ START SESSION CALLED');
    if (_sessionState == SessionState.idle ||
        _sessionState == SessionState.completed) {
      _elapsedSeconds = 0;
      _goalReached = false;
    }

    setState(() => _sessionState = SessionState.running);

    SessionForegroundService.setActionCallback((action) {
      if (!mounted) return;
      if (action == 'pause' && _sessionState == SessionState.running) {
        _pauseSession();
      } else if (action == 'pause' && _sessionState == SessionState.paused) {
        _resumeSession();
      } else if (action == 'end') {
        _endSession();
      }
    });

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds >= _goalSeconds && !_goalReached) {
          _goalReached = true;
          _showGoalReachedSnack();
        }
      });
      SessionForegroundService.update(_formatTime(_elapsedSeconds));
    });
  }

  void _pauseSession() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _sessionState = SessionState.paused);
    SessionForegroundService.update(
        _formatTime(_elapsedSeconds), paused: true);
  }

  void _resumeSession() {
    setState(() => _sessionState = SessionState.running);
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      SessionForegroundService.update(_formatTime(_elapsedSeconds));
    });
  }

  Future<void> _endSession() async {
    _timer?.cancel();
    _pulseController.stop();
    final int finalElapsedSeconds = _elapsedSeconds;
    setState(() => _sessionState = SessionState.completed);
    SessionForegroundService.stop();

    final user = Supabase.instance.client.auth.currentUser;
    final int completedMinutes = ((_elapsedSeconds + 30) / 60).floor();

    try {
      if (user == null) {
        debugPrint('❌ No logged in user');
        return;
      }

      debugPrint('🔄 USER ID: ${user.id}');
      debugPrint('🔄 COMPLETED MINUTES: $completedMinutes');

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('today_minutes, streak, last_active_date')
          .eq('id', user.id)
          .single();

      debugPrint('🔄 CURRENT PROFILE: $profile');

      final int currentStreak = (profile['streak'] as int?) ?? 0;
      final String? lastActiveDateStr =
      profile['last_active_date'] as String?;
      final DateTime today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final DateTime? lastActiveDate = lastActiveDateStr != null
          ? DateTime.parse(lastActiveDateStr)
          : null;
      final DateTime? lastActiveDateOnly = lastActiveDate != null
          ? DateTime(lastActiveDate.year, lastActiveDate.month,
          lastActiveDate.day)
          : null;
      final bool isNewDay = lastActiveDateOnly == null ||
          lastActiveDateOnly.isBefore(today);

      final int currentMinutes =
      isNewDay ? 0 : (profile['today_minutes'] as int?) ?? 0;
      final int updatedMinutes = currentMinutes + completedMinutes;

      int updatedStreak = currentStreak;
      if (isNewDay) {
        final DateTime yesterday =
        today.subtract(const Duration(days: 1));
        final bool studiedYesterday = lastActiveDate != null &&
            lastActiveDate.year == yesterday.year &&
            lastActiveDate.month == yesterday.month &&
            lastActiveDate.day == yesterday.day;
        if (!studiedYesterday) {
          updatedStreak = 0;
          debugPrint('💔 Streak reset — missed a day');
        }
      }

      if (updatedMinutes >= 120 && currentMinutes < 120) {
        updatedStreak = updatedStreak + 1;
        debugPrint('🎉 2 HOUR GOAL COMPLETED — streak: $updatedStreak');
      }

      final updated = await Supabase.instance.client
          .from('profiles')
          .update({
        'today_minutes': updatedMinutes,
        'streak': updatedStreak,
        'last_active_date': today.toIso8601String().split('T')[0],
      })
          .eq('id', user.id)
          .select()
          .single();

      debugPrint('✅ UPDATED PROFILE: $updated');

      await Supabase.instance.client.from('study_sessions').insert({
        'user_id': user.id,
        'subject': _selectedSubject,
        'topic': _topicText,
        'duration_minutes': completedMinutes,
      });

      await Supabase.instance.client.rpc(
        'update_topic_progress',
        params: {
          'p_subject': _selectedSubject,
          'p_topic': _topicText,
          'p_duration': completedMinutes,
        },
      );

      debugPrint('✅ SESSION SAVED');
    } on PostgrestException catch (e) {
      debugPrint('❌ SUPABASE ERROR: ${e.message}');
      debugPrint('❌ ERROR CODE: ${e.code}');
    } catch (e) {
      debugPrint('❌ UNKNOWN ERROR: $e');
    }

    _showSessionSummarySheet(finalElapsedSeconds);
    _elapsedSeconds = 0;
    _goalReached = false;
  }

  void _showGoalReachedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.success, size: 18),
            const SizedBox(width: 8),
            Text(
              '2-hour goal reached — streak secured',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: AppTheme.success.withOpacity(0.3), width: 0.5),
        ),
        elevation: 0,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSessionSummarySheet(int elapsedSeconds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionPhotoCaptureWidget(
        elapsedSeconds: elapsedSeconds,
        subject: _selectedSubject,
        topic: _topicText,
        onComplete: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildAppBar()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SessionTimerWidget(
                  elapsedSeconds: _elapsedSeconds,
                  goalSeconds: _goalSeconds,
                  sessionState: _sessionState,
                  glowAnim: _glowAnim,
                  pulseAnim: _pulseAnim,
                  formatTime: _formatTime,
                  todayMinutes: _todayMinutes,
                ),
                const SizedBox(height: 14),
                SessionSubjectSelectorWidget(
                  selectedSubject: _selectedSubject,
                  topicController: _topicController,
                  sessionState: _sessionState,
                  onSubjectChanged: (s) =>
                      setState(() => _selectedSubject = s),
                  onTopicChanged: (t) => setState(() => _topicText = t),
                ),
                const SizedBox(height: 14),
                SessionControlsWidget(
                  sessionState: _sessionState,
                  elapsedSeconds: _elapsedSeconds,
                  onStart: _startSession,
                  onPause: _pauseSession,
                  onResume: _resumeSession,
                  onEnd: _endSession,
                  glowAnim: _glowAnim,
                ),
                const SizedBox(height: 14),
                SessionMusicWidget(
                  isPlaying: _musicPlaying,
                  onToggle: () =>
                      setState(() => _musicPlaying = !_musicPlaying),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 16),
                SessionTimerWidget(
                  elapsedSeconds: _elapsedSeconds,
                  goalSeconds: _goalSeconds,
                  sessionState: _sessionState,
                  glowAnim: _glowAnim,
                  pulseAnim: _pulseAnim,
                  formatTime: _formatTime,
                  todayMinutes: _todayMinutes,
                ),
                const SizedBox(height: 20),
                SessionControlsWidget(
                  sessionState: _sessionState,
                  elapsedSeconds: _elapsedSeconds,
                  onStart: _startSession,
                  onPause: _pauseSession,
                  onResume: _resumeSession,
                  onEnd: _endSession,
                  glowAnim: _glowAnim,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
            child: Column(
              children: [
                SessionSubjectSelectorWidget(
                  selectedSubject: _selectedSubject,
                  topicController: _topicController,
                  sessionState: _sessionState,
                  onSubjectChanged: (s) =>
                      setState(() => _selectedSubject = s),
                  onTopicChanged: (t) => setState(() => _topicText = t),
                ),
                const SizedBox(height: 14),
                SessionMusicWidget(
                  isPlaying: _musicPlaying,
                  onToggle: () =>
                      setState(() => _musicPlaying = !_musicPlaying),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_sessionState == SessionState.running) {
                _pauseSession();
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppTheme.textSecondary, size: 20),
          ),
          Text(
            'Study Session',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          if (_sessionState == SessionState.running)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.success,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}