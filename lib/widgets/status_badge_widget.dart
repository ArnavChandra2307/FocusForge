// lib/widgets/status_badge_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum BadgeStatus { active, completed, pending, warning, streak }

class StatusBadgeWidget extends StatelessWidget {
  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.status,
    this.fontSize = 11,
  });

  final String label;
  final BadgeStatus status;
  final double fontSize;

  // Maps each status to a V2 semantic color
  Color get _color {
    switch (status) {
      case BadgeStatus.active:
        return AppTheme.accent;    // #4F8CFF blue
      case BadgeStatus.completed:
        return AppTheme.success;   // #00D26A green
      case BadgeStatus.pending:
        return AppTheme.warning;   // #FFB800 amber
      case BadgeStatus.warning:
        return AppTheme.danger;    // #FF4D4D red
      case BadgeStatus.streak:
        return const Color(0xFF8B6FFF); // violet (secondary from colorScheme)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: _color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}