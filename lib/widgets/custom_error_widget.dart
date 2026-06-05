// lib/widgets/custom_error_widget.dart
//
// Fixes applied:
// 1. Removed `../core/app_export.dart` — replaced with direct imports
// 2. Replaced `AppRoutes.initial` with the actual route string '/splash'
// 3. Replaced SvgPicture.asset (missing svg asset) with an Icon fallback
// 4. Removed unused flutter_svg import

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget({
    super.key,
    this.errorDetails,
    this.errorMessage,
  });

  final FlutterErrorDetails? errorDetails;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sad face icon — replaces missing SVG asset
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
                  child: const Icon(
                    Icons.sentiment_dissatisfied_outlined,
                    color: AppTheme.textMuted,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Something went wrong',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'We encountered an unexpected error while processing your request.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),

                // Show error detail in debug mode only
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppTheme.danger,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      } else {
                        // Fall back to splash — avoids importing app_routes
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/splash',
                              (_) => false,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Go back',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
}