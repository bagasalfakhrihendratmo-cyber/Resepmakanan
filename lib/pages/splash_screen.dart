import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:makanan/providers/recipe_provider.dart';

import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Entrance animations ──────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final Animation<double> _logoScaleAnim;
  late final Animation<double> _logoOpacityAnim;

  late final AnimationController _titleController;
  late final Animation<Offset> _titleSlideAnim;
  late final Animation<double> _titleOpacityAnim;

  late final AnimationController _subtitleController;
  late final Animation<Offset> _subtitleSlideAnim;

  // ─── Exit animation (entire splash fades/scales out) ──────────────────────
  late final AnimationController _exitController;
  late final Animation<double> _exitScaleAnim;
  late final Animation<double> _exitOpacityAnim;

  // ─── Progress & effects ───────────────────────────────────────────────────
  late final AnimationController _progressController;
  late final Animation<double> _progressAnim;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  late final AnimationController _floatController;
  final List<_FloatingEmoji> _floatingEmojis = [];

  bool _isExiting = false;
  late final DateTime _splashStartTime;
  bool _exitTriggered = false;

  /// Tracks the last known progress so we can re-trigger the
  /// bar animation on every real change from the provider.
  double _lastProgress = -1.0;

  // Minimum splash duration so the entrance animation doesn't cut off.
  static const Duration _minSplashDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();

    _splashStartTime = DateTime.now();

    _initEntranceAnimations();
    _initExitAnimation();
    _initEffects();
    _initFloatingEmojis();

    // ─── Start entrance animations ─────────────────────────────────────────
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _subtitleController.forward();
    });
  }

  void _initEntranceAnimations() {
    // Logo pulse
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));
    _logoOpacityAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Title slide
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleSlideAnim = Tween<Offset>(
      begin: const Offset(0, 40),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));
    _titleOpacityAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Subtitle slide
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _subtitleSlideAnim = Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _initExitAnimation() {
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _exitScaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeOutCubic),
    );
    _exitOpacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  void _initEffects() {
    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    // Glow effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Floating emojis
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  void _initFloatingEmojis() {
    const emojis = ['🍳', '🍝', '🥗', '🍲', '🍛', '🥘', '🧑‍🍳', '🌶️', '🥬', '🧄'];
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _floatingEmojis.add(_FloatingEmoji(
        emoji: emojis[i % emojis.length],
        startX: random.nextDouble() * 0.9 + 0.05,
        startY: 0.6 + random.nextDouble() * 0.4,
        size: 18.0 + random.nextDouble() * 16.0,
        speed: 1.0 + random.nextDouble() * 2.0,
        drift: random.nextDouble() * 0.3 - 0.15,
        delay: random.nextDouble() * 4.0,
      ));
    }
  }

  /// Called whenever the provider updates its `appInitProgress`.
  /// We check whether initialisation is truly done AND enough time
  /// has passed so the entrance animations feel complete.
  void _checkExitCondition(double progress) {
    if (_exitTriggered) return;
    if (progress < 1.0) return;

    final elapsed = DateTime.now().difference(_splashStartTime);
    if (elapsed < _minSplashDuration) return;

    _exitTriggered = true;
    _startExitAnimation();
  }

  Future<void> _startExitAnimation() async {
    setState(() => _isExiting = true);
    _exitController.forward();

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return _buildMainScreenTransition(animation);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  Widget _buildMainScreenTransition(Animation<double> routeAnim) {
    final curvedAnim = CurvedAnimation(
      parent: routeAnim,
      curve: Curves.easeOutCubic,
    );

    final scaleTween = Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim);
    final opacityTween = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnim);
    final slideTween = Tween<double>(begin: 0.035, end: 0.0).animate(curvedAnim);

    return AnimatedBuilder(
      animation: routeAnim,
      builder: (context, _) {
        return Opacity(
          opacity: opacityTween.value,
          child: Transform.scale(
            scale: scaleTween.value,
            child: Transform.translate(
              offset: Offset(
                0,
                MediaQuery.of(context).size.height * slideTween.value,
              ),
              child: const MainScreen(),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _exitController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // ─── Real progress from the provider ─────────────────────────────────
    final provider = context.watch<RecipeProvider>();
    final realProgress = provider.appInitProgress;
    final realStatus = provider.initStatus;

    // Forward the bar animation each time the provider's progress ticks up
    if (realProgress != _lastProgress) {
      _lastProgress = realProgress;
      _progressController.forward(from: 0.0);
    }

    // Trigger exit check on every rebuild (provider notifications)
    _checkExitCondition(realProgress);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _floatController,
        builder: (context, _) {
          return _buildSplashContent(
            isDark: isDark,
            progress: realProgress,
            status: realStatus,
          );
        },
      ),
    );
  }

  Widget _buildSplashContent({
    required bool isDark,
    required double progress,
    required String status,
  }) {
    final content = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A0A00),
                  const Color(0xFF2D1810),
                  const Color(0xFF1A1A2E),
                ]
              : [
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFE0B2),
                  const Color(0xFFFFF8E1),
                ],
        ),
      ),
      child: Stack(
        children: [
          _buildBackgroundPattern(isDark),
          ..._floatingEmojis.map((e) => _buildFloatingEmoji(e, isDark)),
          Center(child: _buildMainContent(isDark)),
          _buildLoadingSection(isDark, progress: progress, status: status),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildVersionText(isDark),
          ),
        ],
      ),
    );

    if (_isExiting) {
      return AnimatedBuilder(
        animation: _exitController,
        builder: (context, _) {
          return Opacity(
            opacity: _exitOpacityAnim.value,
            child: Transform.scale(
              scale: _exitScaleAnim.value,
              child: content,
            ),
          );
        },
      );
    }

    return content;
  }

  Widget _buildBackgroundPattern(bool isDark) {
    return Opacity(
      opacity: 0.04,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BackgroundPatternPainter(isDark: isDark),
      ),
    );
  }

  Widget _buildFloatingEmoji(_FloatingEmoji e, bool isDark) {
    final phase = (_floatController.value * e.speed + e.delay) % 1.0;
    final x = e.startX + math.sin(phase * math.pi * 2) * e.drift;
    final y = e.startY - phase * 0.5;
    final opacity = phase < 0.1
        ? phase / 0.1
        : phase > 0.8
            ? (1.0 - phase) / 0.2
            : 1.0;

    return Positioned(
      left: MediaQuery.of(context).size.width * x,
      top: MediaQuery.of(context).size.height * y,
      child: Opacity(
        opacity: opacity * (isDark ? 0.35 : 0.2),
        child: Text(e.emoji, style: TextStyle(fontSize: e.size)),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _logoController,
          builder: (context, _) {
            return Opacity(
              opacity: _logoOpacityAnim.value,
              child: Transform.scale(
                scale: _logoScaleAnim.value,
                child: _buildGlowingLogo(isDark),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        SlideTransition(
          position: _titleSlideAnim,
          child: FadeTransition(
            opacity: _titleOpacityAnim,
            child: Text(
              'Resep Masakan',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF2C3E50),
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SlideTransition(
          position: _subtitleSlideAnim,
          child: Opacity(
            opacity: _titleOpacityAnim.value,
            child: Text(
              'Temukan inspirasi masakan lezat',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white70 : const Color(0xFF7F8C8D),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingLogo(bool isDark) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Container(
                width: 120 + 40 * _glowAnim.value,
                height: 120 + 40 * _glowAnim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE8733A)
                          .withValues(alpha: 0.3 * _glowAnim.value),
                      const Color(0xFFE8733A).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8733A), Color(0xFFD35400)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8733A)
                      .withValues(alpha: isDark ? 0.5 : 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('🍳', style: TextStyle(fontSize: 48)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection(
    bool isDark, {
    required double progress,
    required String status,
  }) {
    if (_isExiting) return const SizedBox.shrink();

    return Positioned(
      left: 40,
      right: 40,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Progress bar (tracks REAL init progress) ──────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, _) {
                  final animatedProgress = progress * _progressAnim.value;
                  final trackWidth = MediaQuery.of(context).size.width - 80;

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFE8733A),
                                Color(0xFFFF9A5C),
                              ],
                            ),
                          ),
                          width: trackWidth * animatedProgress,
                        ),
                      ),
                      if (progress < 1.0)
                        Positioned(
                          left: trackWidth * animatedProgress - 4,
                          top: -2,
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, _) {
                              return Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFF9A5C),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE8733A)
                                          .withValues(
                                              alpha: 0.6 * _glowAnim.value),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── REAL loading status from provider ──────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              status,
              key: ValueKey(status),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF95A5A6),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ─── REAL percentage ────────────────────────────────────────────
          Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white38
                  : const Color(0xFFE8733A).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionText(bool isDark) {
    if (_isExiting) return const SizedBox.shrink();

    return Text(
      'v1.0.0 • by M.Bagas & Asqilah Yasmin',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white24 : const Color(0xFFBDC3C7),
      ),
    );
  }
}

// ─── Floating Emoji Data ──────────────────────────────────────────────────────
class _FloatingEmoji {
  final String emoji;
  final double startX;
  final double startY;
  final double size;
  final double speed;
  final double drift;
  final double delay;

  const _FloatingEmoji({
    required this.emoji,
    required this.startX,
    required this.startY,
    required this.size,
    required this.speed,
    required this.drift,
    required this.delay,
  });
}

// ─── Background Pattern Painter ──────────────────────────────────────────────
class _BackgroundPatternPainter extends CustomPainter {
  final bool isDark;

  _BackgroundPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.3)
          : const Color(0xFFE8733A).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      final r = 20.0 + random.nextDouble() * 80.0;

      paint.color = (isDark ? Colors.white : const Color(0xFFE8733A))
          .withValues(alpha: 0.05 + random.nextDouble() * 0.05);
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    final linePaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFFE8733A))
          .withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 6; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + (random.nextDouble() - 0.5) * 200;
      final endY = startY + (random.nextDouble() - 0.5) * 200;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
