// lib/features/auth/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/app_theme.dart';
import 'widgets/auth_widgets.dart'; // ← shared widgets

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth                      = AuthRepository();
  final _formKey                   = GlobalKey<FormState>();

  bool _isLoading      = false;
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _emailSent      = false;

  late final AnimationController _entryController;
  late final AnimationController _successController;

  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _successScale;
  late final Animation<double> _successFade;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _entryFade = CurvedAnimation(
        parent: _entryController, curve: Curves.easeOut);

    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryController, curve: Curves.easeOutCubic));

    _successScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _successController, curve: Curves.easeOutBack),
    );

    _successFade = CurvedAnimation(
        parent: _successController, curve: Curves.easeOut);

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _successController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Auth logic ──────────────────────────────────────────────────────────────

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
        _successController.forward();
      }
    } on Exception catch (e) {
      if (mounted) {
        _showErrorSnackBar(_parseError(e.toString())); // fixed: SnackBar
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(String raw) {
    if (raw.contains('User already registered') ||
        raw.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('Password should be')) {
      return 'Password must be at least 6 characters.';
    }
    if (raw.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('network') || raw.contains('socket')) {
      return 'No internet connection.';
    }
    if (raw.contains('too many requests')) {
      return 'Too many attempts. Try again later.';
    }
    return 'Signup failed. Please try again.';
  }

  void _showErrorSnackBar(String message) {
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
              color: AppTheme.danger.withValues(alpha: 0.3), // ← fixed
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.danger,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _emailSent ? _buildSuccessCard() : _buildForm(),
                  if (!_emailSent) ...[
                    const SizedBox(height: 32),
                    _buildLoginLink(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.borderDefault,
                width: 0.5,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textSecondary,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const MiniLogoMark(),   // ← now from auth_widgets.dart
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Focus ',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextSpan(
                text: 'Forge',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Form ────────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Create\n',
                style: GoogleFonts.dmSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
              TextSpan(
                text: 'account.',
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
          'Start forging your study discipline today',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 36),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full name
              const FieldLabel(label: 'FULL NAME'),
              const SizedBox(height: 6),
              AuthInputField(
                controller: _nameController,
                hint: 'Your name',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name required';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email
              const FieldLabel(label: 'EMAIL'),
              const SizedBox(height: 6),
              AuthInputField(
                controller: _emailController,
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password
              const FieldLabel(label: 'PASSWORD'),
              const SizedBox(height: 6),
              AuthInputField(
                controller: _passwordController,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePass,
                textInputAction: TextInputAction.next,
                suffixIcon: VisibilityToggle(
                  obscure: _obscurePass,
                  onTap: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Confirm password
              const FieldLabel(label: 'CONFIRM PASSWORD'),
              const SizedBox(height: 6),
              AuthInputField(
                controller: _confirmPasswordController,
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _signup(),
                suffixIcon: VisibilityToggle(
                  obscure: _obscureConfirm,
                  onTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 36),

              PrimaryButton(
                label: 'Create account',
                isLoading: _isLoading,
                onTap: _isLoading ? null : _signup,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Success card ─────────────────────────────────────────────────────────────

  Widget _buildSuccessCard() {
    return ScaleTransition(
      scale: _successScale,
      child: FadeTransition(
        opacity: _successFade,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.2), // ← fixed
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1), // ← fixed
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.25), // ← fixed
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppTheme.success,
                  size: 28,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Verify your email',
                style: GoogleFonts.dmSans(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'We sent a confirmation link to',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _emailController.text.trim(),
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppTheme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Click the link in your email to activate your account, then sign in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Go to sign in',
                isLoading: false,
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Login link ───────────────────────────────────────────────────────────────

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppTheme.textMuted,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Sign in',
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