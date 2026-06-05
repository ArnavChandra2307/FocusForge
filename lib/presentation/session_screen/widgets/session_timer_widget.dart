import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../session_screen.dart';

class SessionTimerWidget extends StatelessWidget {
  final int elapsedSeconds;
  final int goalSeconds;
  final SessionState sessionState;
  final Animation<double> glowAnim;
  final Animation<double> pulseAnim;
  final String Function(int) formatTime;
  final int todayMinutes;

  const SessionTimerWidget({
    super.key,
    required this.elapsedSeconds,
    required this.goalSeconds,
    required this.sessionState,
    required this.glowAnim,
    required this.pulseAnim,
    required this.formatTime,
    required this.todayMinutes,
  });

  Color get _accentColor {
    switch (sessionState) {
      case SessionState.running:
        return elapsedSeconds >= goalSeconds
            ? AppTheme.success
            : AppTheme.accent;
      case SessionState.paused:
        return AppTheme.warning;
      case SessionState.completed:
        return AppTheme.success;
      case SessionState.idle:
        return AppTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (sessionState) {
      case SessionState.idle:      return 'Ready';
      case SessionState.running:   return 'In Focus';
      case SessionState.paused:    return 'Paused';
      case SessionState.completed: return 'Complete';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalMinutes = todayMinutes + (elapsedSeconds ~/ 60);
    final int remainingMinutes = (120 - totalMinutes).clamp(0, 120);
    final double progress = (totalMinutes / 120.0).clamp(0.0, 1.0);
    final bool goalMet = totalMinutes >= 120;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sessionState == SessionState.running
              ? _accentColor.withOpacity(0.2)
              : AppTheme.borderSubtle,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // ── Timer ring ────────────────────────────────────────────────
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: sessionState == SessionState.running
                  ? pulseAnim.value
                  : 1.0,
              child: child,
            ),
            child: SizedBox(
              width: 192,
              height: 192,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 192,
                    height: 192,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, value, __) =>
                          CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            backgroundColor: AppTheme.borderSubtle,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(_accentColor),
                            strokeCap: StrokeCap.round,
                          ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timer display — Instrument Serif
                      Text(
                        formatTime(elapsedSeconds),
                        style: GoogleFonts.instrumentSerif(
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: _accentColor,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _statusLabel.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _accentColor.withOpacity(0.6),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Daily progress bar ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goalMet
                    ? 'Goal achieved'
                    : '${remainingMinutes}m remaining',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: goalMet ? AppTheme.success : AppTheme.textMuted,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _accentColor,
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
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),

          // ── Goal reached chip ─────────────────────────────────────────
          if (elapsedSeconds >= goalSeconds) ...[
            const SizedBox(height: 12),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.25),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 13, color: AppTheme.success),
                  const SizedBox(width: 5),
                  Text(
                    'Streak goal reached — keep going',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}