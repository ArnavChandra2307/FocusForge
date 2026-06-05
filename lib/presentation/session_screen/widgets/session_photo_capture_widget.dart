import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../theme/app_theme.dart';

class SessionPhotoCaptureWidget extends StatefulWidget {
  final int elapsedSeconds;
  final String subject;
  final String topic;
  final VoidCallback onComplete;

  const SessionPhotoCaptureWidget({
    super.key,
    required this.elapsedSeconds,
    required this.subject,
    required this.topic,
    required this.onComplete,
  });

  @override
  State<SessionPhotoCaptureWidget> createState() =>
      _SessionPhotoCaptureWidgetState();
}

class _SessionPhotoCaptureWidgetState
    extends State<SessionPhotoCaptureWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _photoTaken = false;
  bool _isSaving = false;

  // ── Helpers (unchanged) ───────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Future<void> _handlePhotoOption(String option) async {
    try {
      XFile? image;
      if (kIsWeb ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS) {
        image = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 70);
      } else {
        image = await _picker.pickImage(
          source: option == 'camera'
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 70,
        );
      }
      if (image != null) {
        setState(() {
          _selectedImage = File(image!.path);
          _photoTaken = true;
        });
      }
    } catch (e) {
      debugPrint('IMAGE PICK ERROR: $e');
    }
  }

  Future<void> _saveSession() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isSaving = false);
      widget.onComplete();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool goalMet = widget.elapsedSeconds >= 7200;
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.80,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: goalMet
                              ? AppTheme.successTint
                              : AppTheme.accentTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          goalMet
                              ? Icons.verified_outlined
                              : Icons.camera_alt_outlined,
                          color: goalMet
                              ? AppTheme.success
                              : AppTheme.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Register Your Session',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Capture proof to verify your study session',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Session summary ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: goalMet
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.warning.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              label: 'Duration',
                              value: _formatDuration(
                                  widget.elapsedSeconds),
                              color: goalMet
                                  ? AppTheme.success
                                  : AppTheme.accent,
                            ),
                            _SummaryItem(
                              label: 'Subject',
                              value: widget.subject,
                              color: AppTheme.subjectColor(
                                  widget.subject),
                            ),
                            _SummaryItem(
                              label: 'Streak',
                              value: goalMet ? 'Secured' : 'Not Met',
                              color: goalMet
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ],
                        ),
                        if (widget.topic.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(
                              color: AppTheme.borderSubtle,
                              height: 1,
                              thickness: 0.5),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.menu_book_outlined,
                                  size: 13,
                                  color: AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.topic,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'STUDY PROOF',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Take or upload a photo of your study setup to verify your session.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!_photoTaken) ...[
                    // ── Photo options ──
                    Row(
                      children: [
                        Expanded(
                          child: _PhotoOptionCard(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            subtitle: 'Take a photo',
                            onTap: () =>
                                _handlePhotoOption('camera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PhotoOptionCard(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            subtitle: 'Choose existing',
                            onTap: () =>
                                _handlePhotoOption('gallery'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _saveSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: const BorderSide(
                              color: AppTheme.borderDefault, width: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Skip photo (streak may not count)',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── Photo taken state ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.successTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_selectedImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                height: 110,
                                width: 110,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Icon(Icons.check_circle_outline_rounded,
                                color: AppTheme.success, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'Photo captured',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your proof is ready to submit',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _photoTaken = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                              side: const BorderSide(
                                  color: AppTheme.borderDefault,
                                  width: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            child: Text(
                              'Retake',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(
                              'Save Session',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Local widgets ─────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 9,
            color: AppTheme.textMuted,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PhotoOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoOptionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppTheme.borderDefault, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.accent, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}