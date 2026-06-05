// lib/widgets/empty_state_widget.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with subtle tint background
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.borderDefault,
                  width: 0.5,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppTheme.textMuted,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              description,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onCta,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(ctaLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}