import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../session_screen.dart';

class SessionSubjectSelectorWidget extends StatelessWidget {
  final String selectedSubject;
  final TextEditingController topicController;
  final SessionState sessionState;
  final ValueChanged<String> onSubjectChanged;
  final ValueChanged<String> onTopicChanged;

  const SessionSubjectSelectorWidget({
    super.key,
    required this.selectedSubject,
    required this.topicController,
    required this.sessionState,
    required this.onSubjectChanged,
    required this.onTopicChanged,
  });

  // V2 canonical subject list
  static const List<String> _subjects = [
    'Physics',
    'Chemistry',
    'Biology',
    'Mathematics',
    'English Language',
    'English Literature',
    'Hindi',
    'Geography',
    'History & Civics',
    'Computer Applications',
  ];

  bool get _isEditable =>
      sessionState == SessionState.idle ||
          sessionState == SessionState.paused;

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = AppTheme.subjectColor(selectedSubject);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT ARE YOU STUDYING',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          // ── Subject dropdown ──
          _SelectorLabel(label: 'Subject'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isEditable
                    ? subjectColor.withOpacity(0.35)
                    : AppTheme.borderSubtle,
                width: 0.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSubject,
                isExpanded: true,
                dropdownColor: AppTheme.backgroundSecondary,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _isEditable
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isEditable
                      ? AppTheme.textSecondary
                      : AppTheme.textDisabled,
                  size: 18,
                ),
                onChanged: _isEditable
                    ? (v) {
                  if (v != null) onSubjectChanged(v);
                }
                    : null,
                items: _subjects
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppTheme.subjectColor(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Topic input ──
          _SelectorLabel(label: 'Topic (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: topicController,
            enabled: _isEditable,
            onChanged: onTopicChanged,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Thermodynamics — Chapter 3',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textDisabled,
              ),
              prefixIcon: const Icon(
                Icons.menu_book_outlined,
                color: AppTheme.textMuted,
                size: 16,
              ),
              filled: true,
              fillColor: AppTheme.backgroundSecondary,
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
                borderSide:
                const BorderSide(color: AppTheme.accent, width: 1.0),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppTheme.borderSubtle, width: 0.5),
              ),
            ),
          ),

          if (!_isEditable && sessionState == SessionState.running) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 11, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Pause to change subject or topic',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectorLabel extends StatelessWidget {
  final String label;
  const _SelectorLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppTheme.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}