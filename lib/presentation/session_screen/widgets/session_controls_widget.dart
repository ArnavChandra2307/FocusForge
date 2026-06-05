import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../session_screen.dart';

class SessionControlsWidget extends StatelessWidget {
  final SessionState sessionState;
  final int elapsedSeconds;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  final Animation<double> glowAnim;

  const SessionControlsWidget({
    super.key,
    required this.sessionState,
    required this.elapsedSeconds,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    required this.glowAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (sessionState == SessionState.idle)     _buildStartButton(),
        if (sessionState == SessionState.running)  _buildRunningControls(),
        if (sessionState == SessionState.paused)   _buildPausedControls(),
        if (sessionState == SessionState.completed) _buildCompletedState(),
      ],
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: Text(
          'Begin Session',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRunningControls() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onPause,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.warning,
                side: BorderSide(
                  color: AppTheme.warning.withOpacity(0.4),
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.pause_rounded, size: 18),
              label: Text(
                'Pause',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onEnd,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: BorderSide(
                  color: AppTheme.danger.withOpacity(0.4),
                  width: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: Text(
                'End Session',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPausedControls() {
    return Column(
      children: [
        // Paused indicator
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.warningTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.warning.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pause_circle_outline_rounded,
                  size: 14, color: AppTheme.warning),
              const SizedBox(width: 8),
              Text(
                'Session paused — resume when ready',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        Row(
          children: [
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    'Resume',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onEnd,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: BorderSide(
                      color: AppTheme.danger.withOpacity(0.4),
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.stop_rounded, size: 16),
                  label: Text(
                    'End',
                    style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.success.withOpacity(0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppTheme.success, size: 18),
          const SizedBox(width: 8),
          Text(
            'Session complete',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}