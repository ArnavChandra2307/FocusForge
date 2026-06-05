// lib/features/auth/widgets/auth_widgets.dart
//
// Shared widgets used by both LoginScreen and SignupScreen.
// Extracted here because private classes (underscore-prefix) are
// file-scoped in Dart — they cannot be referenced across files.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mini logo mark  (the small arc/flame icon in the header row)
// ─────────────────────────────────────────────────────────────────────────────

class MiniLogoMark extends StatelessWidget {
  const MiniLogoMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.accentTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: const Icon(
        Icons.local_fire_department_rounded,
        color: AppTheme.accent,
        size: 15,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field label  (small uppercase label above each input)
// ─────────────────────────────────────────────────────────────────────────────

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppTheme.textSecondary,
        letterSpacing: 0.7,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth input field
// ─────────────────────────────────────────────────────────────────────────────

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      obscuringCharacter: '•',
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppTheme.textDisabled,
        ),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 17),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.backgroundSecondary,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppTheme.borderDefault, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppTheme.borderDefault, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppTheme.danger, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.0),
        ),
        errorStyle: GoogleFonts.dmSans(
          fontSize: 11,
          color: AppTheme.danger,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visibility toggle  (show / hide password suffix icon)
// ─────────────────────────────────────────────────────────────────────────────

class VisibilityToggle extends StatelessWidget {
  const VisibilityToggle({
    super.key,
    required this.obscure,
    required this.onTap,
  });

  final bool obscure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppTheme.textMuted,
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary button  (full-width accent button with loading state)
// ─────────────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.borderDefault,
          disabledForegroundColor: AppTheme.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}