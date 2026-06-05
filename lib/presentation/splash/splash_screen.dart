import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animation controllers ────────────────────────────────────────────────

  late final AnimationController _particleController;
  late final AnimationController _logoController;
  late final AnimationController _wordmarkController;
  late final AnimationController _exitController;

  // Spark particles fade in
  late final Animation<double> _particleFade;

  // Logo mark: scale + fade
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Progress arc sweep (0 → ~0.8 of full circle)
  late final Animation<double> _arcSweep;

  // Wordmark fade + slide up
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;

  // Tagline fade
  late final Animation<double> _taglineFade;

  // Exit: entire screen fades out
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Controller durations ──────────────────────────────────────────────

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // ── Animations ────────────────────────────────────────────────────────

    _particleFade = CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _arcSweep = Tween<double>(begin: 0.0, end: 0.78).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _wordmarkFade = CurvedAnimation(
      parent: _wordmarkController,
      curve: Curves.easeOut,
    );

    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _wordmarkController,
      curve: Curves.easeOutCubic,
    ));

    _taglineFade = CurvedAnimation(
      parent: _wordmarkController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // ── Sequence ──────────────────────────────────────────────────────────

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Particles appear
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _particleController.forward();

    // 2. Logo mark animates in
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();

    // 3. Wordmark slides up
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _wordmarkController.forward();

    // 4. Hold on screen, then check auth
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final session = Supabase.instance.client.auth.currentSession;
    final destination = session != null ? '/home' : '/login';

    // Exit animation
    await _exitController.forward();
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  void dispose() {
    _particleController.dispose();
    _logoController.dispose();
    _wordmarkController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: FadeTransition(
        opacity: _exitFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Spark particles (background layer) ──────────────────────
            FadeTransition(
              opacity: _particleFade,
              child: const _SparkParticles(),
            ),

            // ── Center content ───────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo mark
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: AnimatedBuilder(
                        animation: _arcSweep,
                        builder: (context, _) {
                          return _LogoMark(arcProgress: _arcSweep.value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Wordmark + tagline
                  SlideTransition(
                    position: _wordmarkSlide,
                    child: FadeTransition(
                      opacity: _wordmarkFade,
                      child: Column(
                        children: [
                          // "Focus Forge" wordmark
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Focus ',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Forge',
                                  style: GoogleFonts.instrumentSerif(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.accent,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tagline
                          FadeTransition(
                            opacity: _taglineFade,
                            child: Text(
                              'BUILD THE HABIT. FORGE THE DISCIPLINE.',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logo Mark Widget ─────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final double arcProgress; // 0.0 → 1.0

  const _LogoMark({required this.arcProgress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: _LogoPainter(arcProgress: arcProgress),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double arcProgress;

  const _LogoPainter({required this.arcProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // ── Track ring ────────────────────────────────────────────────────────
    final trackPaint = Paint()
      ..color = const Color(0xFF1A2535)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, trackPaint);

    // ── Progress arc ──────────────────────────────────────────────────────
    final arcPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5707963; // -π/2 (top)
    final sweepAngle = arcProgress * 2 * 3.1415926 * 0.78;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // ── Ascending bars (discipline symbol) ───────────────────────────────
    const barColor = AppTheme.accent;
    const barCount = 4;
    const barWidth = 4.5;
    const barSpacing = 6.5;
    final totalWidth = barCount * barWidth + (barCount - 1) * barSpacing;
    final startX = center.dx - totalWidth / 2;
    final baseY = center.dy + 14.0;

    // Heights: ascending left to right
    const heights = [10.0, 16.0, 22.0, 28.0];
    const opacities = [0.35, 0.55, 0.75, 1.0];

    for (int i = 0; i < barCount; i++) {
      final barPaint = Paint()
        ..color = barColor.withOpacity(opacities[i])
        ..style = PaintingStyle.fill;

      final x = startX + i * (barWidth + barSpacing);
      final h = heights[i];
      final y = baseY - h;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rrect, barPaint);
    }

    // ── Spark dot at top of tallest bar ──────────────────────────────────
    if (arcProgress > 0.5) {
      final sparkOpacity = ((arcProgress - 0.5) / 0.5).clamp(0.0, 1.0);

      final sparkX = startX + 3 * (barWidth + barSpacing) + barWidth / 2;
      final sparkY = baseY - heights[3] - 6;

      // Inner dot
      final dotPaint = Paint()
        ..color = AppTheme.accent.withOpacity(sparkOpacity);
      canvas.drawCircle(Offset(sparkX, sparkY), 2.5, dotPaint);

      // Outer ring
      final ringPaint = Paint()
        ..color = AppTheme.accent.withOpacity(sparkOpacity * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(Offset(sparkX, sparkY), 5.0, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.arcProgress != arcProgress;
}

// ─── Spark Particles ──────────────────────────────────────────────────────────

class _SparkParticles extends StatelessWidget {
  const _SparkParticles();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Fixed particle positions (relative to screen size)
    // Each entry: [xFraction, yFraction, sizeFraction, opacity]
    const particles = [
      [0.15, 0.22, 0.004, 0.25],
      [0.82, 0.18, 0.005, 0.20],
      [0.08, 0.55, 0.003, 0.15],
      [0.90, 0.45, 0.004, 0.20],
      [0.25, 0.78, 0.003, 0.15],
      [0.72, 0.72, 0.005, 0.18],
      [0.45, 0.12, 0.003, 0.12],
      [0.60, 0.85, 0.004, 0.15],
      [0.35, 0.40, 0.002, 0.10],
      [0.78, 0.58, 0.003, 0.12],
    ];

    return Stack(
      children: particles.map((p) {
        return Positioned(
          left: size.width * (p[0] as double),
          top: size.height * (p[1] as double),
          child: Container(
            width: size.width * (p[2] as double),
            height: size.width * (p[2] as double),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(p[3] as double),
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }
}