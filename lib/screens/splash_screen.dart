import 'dart:math';
import 'package:flutter/material.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _scaleAnim = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _textFade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _logoController.forward().then((_) => _fadeController.forward());

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ));
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // Cinematic background — film reels & light beams
          const _CinematicBackground(),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5383B), width: 3),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFE5383B).withOpacity(0.4), blurRadius: 30, spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.movie_filter_rounded, color: Color(0xFFE5383B), size: 56),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // App name
                FadeTransition(
                  opacity: _textFade,
                  child: const Text(
                    'AddisCinema',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    'Your Cinema Experience',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          // Bottom loading bar
          Positioned(
            bottom: 60,
            left: 60,
            right: 60,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(children: [
                Text('Loading...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFF2A2A2A),
                    color: Color(0xFFE5383B),
                    minHeight: 3,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicBackground extends StatefulWidget {
  const _CinematicBackground();

  @override
  State<_CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<_CinematicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _BackgroundPainter(_controller.value),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double t;
  _BackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Light beams from top
    final beamPaint = Paint()..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE5383B).withOpacity(0.08 + 0.04 * sin(t * 2 * pi)),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.1 + i * 0.2 + 0.02 * sin(t * 2 * pi + i));
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x - 40, size.height * 0.6)
        ..lineTo(x + 40, size.height * 0.6)
        ..close();
      canvas.drawPath(path, beamPaint);
    }

    // Film reel circles — corners
    final reelPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _drawReel(canvas, Offset(60, 80), 55, reelPaint);
    _drawReel(canvas, Offset(size.width - 60, 80), 55, reelPaint);
    _drawReel(canvas, Offset(40, size.height - 100), 40, reelPaint);
    _drawReel(canvas, Offset(size.width - 40, size.height - 100), 40, reelPaint);
  }

  void _drawReel(Canvas canvas, Offset center, double r, Paint paint) {
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center, r * 0.35, paint);
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + t * 2 * pi;
      final x1 = center.dx + r * 0.4 * cos(angle);
      final y1 = center.dy + r * 0.4 * sin(angle);
      final x2 = center.dx + r * 0.85 * cos(angle);
      final y2 = center.dy + r * 0.85 * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t;
}
