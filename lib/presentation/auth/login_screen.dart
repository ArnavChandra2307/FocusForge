import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth               = AuthRepository();
  final _formKey            = GlobalKey<FormState>();

  bool _isLoading      = false;
  bool _isResetting    = false;
  bool _obscurePassword = true;

  late final AnimationController _entryController;
  late final Animation<double>   _entryFade;
  late final Animation<Offset>   _entrySlide;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ──────────────────────────────────────────────

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showForgotPasswordDialog();
      return;
    }
    await _sendResetEmail(email);
  }

  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderDefault, width: 0.5),
        ),
        title: Text('Reset password',
            style: GoogleFonts.dmSans(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your email and we'll send a reset link.",
              style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _AuthInputField(
              controller: ctrl,
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendResetEmail(ctrl.text.trim());
            },
            child: Text('Send link',
                style: GoogleFonts.dmSans(
                    color: AppTheme.accent, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackbar('Please enter a valid email address.');
      return;
    }
    setState(() => _isResetting = true);
    try {
      await _auth.resetPassword(email: email);
      if (mounted) _showSuccessSnackbar('Reset link sent! Check your inbox.');
    } on Exception catch (e) {
      if (mounted) _showErrorSnackbar(_parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on Exception catch (e) {
      if (mounted) _showErrorSnackbar(_parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String raw) {
    debugPrint('AUTH ERROR: $raw');
    if (raw.contains('Invalid login credentials')) return 'Incorrect email or password.';
    if (raw.contains('Email not confirmed'))        return 'Please verify your email first.';
    if (raw.contains('network') || raw.contains('socket')) return 'No internet connection.';
    if (raw.contains('too many requests'))          return 'Too many attempts. Try again later.';
    return 'Login failed. Please try again.';
  }

  // ── Snackbars ───────────────────────────────────────────────────────────

  void _showSuccessSnackbar(String message) {
    _showSnackbar(message, AppTheme.success, Icons.check_circle_outline_rounded);
  }

  void _showErrorSnackbar(String message) {
    _showSnackbar(message, AppTheme.danger, Icons.error_outline_rounded);
  }

  void _showSnackbar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withOpacity(0.3), width: 0.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),
                  _buildBrand(),
                  const SizedBox(height: 48),
                  _buildForm(),
                  const SizedBox(height: 32),
                  _buildSignupLink(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo mark — same as splash
        const _MiniLogoMark(),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Welcome\n',
                style: GoogleFonts.dmSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
              TextSpan(
                text: 'back.',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.accent,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your streak',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Email ──
          _FieldLabel(label: 'Email'),
          const SizedBox(height: 6),
          _AuthInputField(
            controller: _emailController,
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // ── Password ──
          _FieldLabel(label: 'Password'),
          const SizedBox(height: 6),
          _AuthInputField(
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: _VisibilityToggle(
              obscure: _obscurePassword,
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),

          const SizedBox(height: 12),

          // ── Forgot password ──
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: (_isLoading || _isResetting)
                  ? null
                  : _handleForgotPassword,
              child: Text(
                _isResetting ? 'Sending...' : 'Forgot password?',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Login button ──
          _PrimaryButton(
            label: 'Sign in',
            isLoading: _isLoading,
            onTap: (_isLoading || _isResetting) ? null : _login,
          ),
        ],
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.dmSans(
              fontSize: 13, color: AppTheme.textMuted),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/signup'),
          child: Text(
            'Create one',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared auth widgets (used by both login + signup)
// ═══════════════════════════════════════════════════════════════════════════════

/// Small version of the Focus Forge logo mark for auth screens
class _MiniLogoMark extends StatelessWidget {
  const _MiniLogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(painter: _MiniLogoPainter()),
    );
  }
}

class _MiniLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1A2535)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Arc (~78%)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963,
      2 * 3.1415926 * 0.78,
      false,
      Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Ascending bars
    const barW = 3.0;
    const gap  = 4.0;
    const heights = [6.0, 10.0, 13.0, 17.0];
    const opacities = [0.35, 0.55, 0.75, 1.0];
    final totalW = 4 * barW + 3 * gap;
    final startX = center.dx - totalW / 2;
    final baseY  = center.dy + 8.0;

    for (int i = 0; i < 4; i++) {
      final x = startX + i * (barW + gap);
      final h = heights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, baseY - h, barW, h),
          const Radius.circular(1.0),
        ),
        Paint()..color = AppTheme.accent.withOpacity(opacities[i]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Field label above each input
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppTheme.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// Reusable text input for auth screens
class _AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.dmSans(
        color: AppTheme.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            color: AppTheme.textDisabled, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.backgroundSecondary,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          borderSide:
          const BorderSide(color: AppTheme.accent, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppTheme.danger, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: AppTheme.danger, width: 1.0),
        ),
        errorStyle: GoogleFonts.dmSans(
            color: AppTheme.danger, fontSize: 11),
      ),
    );
  }
}

/// Password visibility toggle icon
class _VisibilityToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _VisibilityToggle({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        color: AppTheme.textMuted,
        size: 18,
      ),
      onPressed: onTap,
    );
  }
}

/// Primary CTA button used across auth screens
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
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
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
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