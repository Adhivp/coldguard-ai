import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_card_ai/core/routes/route_names.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animation values
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _radiusAnimation;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _iconOpacityAnimation;

  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoOpacityAnimation;

  late final Animation<double> _textOpacityAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _pageOpacityAnimation;

  // Orbiting icons configuration
  final List<Map<String, dynamic>> _orbitingItems = [
    {
      'icon': Icons.qr_code_scanner_rounded,
      'color': const Color(0xFF4ECDC4),
    }, // Scanner
    {
      'icon': Icons.inventory_2_rounded,
      'color': const Color(0xFF9E77F1),
    }, // Package
    {
      'icon': Icons.ac_unit_rounded,
      'color': const Color(0xFF00ACC1),
    }, // Cold/Snowflake
    {
      'icon': Icons.local_shipping_rounded,
      'color': const Color(0xFFFF8906),
    }, // Logistics
    {
      'icon': Icons.security_rounded,
      'color': const Color(0xFF10B981),
    }, // Shield
    {'icon': Icons.sensors_rounded, 'color': const Color(0xFFEF4444)}, // Sensor
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    // 1. Orbiting items rotation (spins about 2.25 times)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOutCubic),
      ),
    );

    // 2. Orbiting radius shrinkage (starts at 1.0, spiraling down to 0.0)
    _radiusAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.60, curve: Curves.easeInOutBack),
      ),
    );

    // 3. Orbiting icons scale down as they merge
    _iconScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.58, curve: Curves.easeIn),
      ),
    );

    // 4. Orbiting icons opacity fades out on merge
    _iconOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.58, curve: Curves.easeOut),
      ),
    );

    // 5. Central logo scales up with bouncy elastic effect
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.78, curve: Curves.elasticOut),
      ),
    );

    // 6. Central logo opacity fades in
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.68, curve: Curves.easeIn),
      ),
    );

    // 9. Brand text opacity reveal
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.88, curve: Curves.easeIn),
      ),
    );

    // 10. Brand text slide up
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.68, 0.88, curve: Curves.easeOutCubic),
          ),
        );

    // 11. Soft screen-wide fade out at the end of the animation
    _pageOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.92, 1.0, curve: Curves.easeOut),
      ),
    );

    // Play animation and trigger redirection to HomePage
    _controller.forward().then((_) {
      if (mounted) {
        context.go(RouteNames.homePath);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Adaptive colors
    final bgGradientColors = isDark
        ? [const Color(0xFF0F0E17), const Color(0xFF1E1C2A)]
        : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)];

    final mainTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark
        ? const Color(0xFFA7A9BE)
        : const Color(0xFF475569);
    final orbitPathColor = isDark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFF6366F1).withOpacity(0.12);

    final maxRadius = math.min(MediaQuery.of(context).size.width * 0.32, 125.0);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Calculate periodic laser sweeps for central logo
          final double laserSweep =
              (math.sin(_controller.value * 2 * math.pi * 3.5) + 1.0) / 2.0;

          return FadeTransition(
            opacity: _pageOpacityAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: bgGradientColors,
                  center: Alignment.center,
                  radius: 1.2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 3. Glowing orbit path circle
                  if (_iconOpacityAnimation.value > 0)
                    CustomPaint(
                      size: Size.infinite,
                      painter: OrbitPathPainter(
                        radius: maxRadius * _radiusAnimation.value,
                        opacity: _iconOpacityAnimation.value,
                        color: orbitPathColor,
                      ),
                    ),

                  // 4. Orbiting Icons Stack
                  if (_iconOpacityAnimation.value > 0)
                    ...List.generate(_orbitingItems.length, (index) {
                      final item = _orbitingItems[index];
                      // Angle offset for even circular distribution
                      final double startAngle =
                          index * (2.0 * math.pi / _orbitingItems.length);
                      final double currentAngle =
                          startAngle +
                          (_rotationAnimation.value * 2.0 * math.pi);
                      final double currentRadius =
                          maxRadius * _radiusAnimation.value;

                      final double x = math.cos(currentAngle) * currentRadius;
                      final double y = math.sin(currentAngle) * currentRadius;

                      return Transform.translate(
                        offset: Offset(x, y),
                        child: Transform.scale(
                          scale: _iconScaleAnimation.value,
                          child: Opacity(
                            opacity: _iconOpacityAnimation.value,
                            child: OrbitIconBadge(
                              icon: item['icon'] as IconData,
                              color: item['color'] as Color,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      );
                    }),

                  // 5. Central Logo and Text Container
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Central Logo
                        Opacity(
                          opacity: _logoOpacityAnimation.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: ScannerLogo(
                              sweepProgress: laserSweep,
                              isDark: isDark,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Brand Text & Tagline
                        Opacity(
                          opacity: _textOpacityAnimation.value.clamp(0.0, 1.0),
                          child: SlideTransition(
                            position: _textSlideAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ColdGuard AI',
                                  style: GoogleFonts.outfit(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: mainTextColor,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                    shadows: isDark
                                        ? [
                                            Shadow(
                                              color: const Color(
                                                0xFF9E77F1,
                                              ).withOpacity(0.4),
                                              blurRadius: 15,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Live intelligence for every shipment',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
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
        },
      ),
    );
  }
}

// Orbit path circular dotted line painter
class OrbitPathPainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Color color;

  OrbitPathPainter({
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || radius <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final double circumference = 2.0 * math.pi * radius;
    const int dashCount = 42;
    final double dashLength = circumference / (dashCount * 2.0);

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * 2.0 * dashLength) / radius;
      final double sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbitPathPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.opacity != opacity ||
        oldDelegate.color != color;
  }
}

// Orbiting icon badge container
class OrbitIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const OrbitIconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? const Color(0xFF1E1C2A).withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: Icon(icon, color: color, size: 22)),
    );
  }
}

// Logo custom camera scanner brackets painter
class ScannerCornersPainter extends CustomPainter {
  final Color color;

  ScannerCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double len = 15.0; // corner line length
    const double gap = 4.0; // distance from boundary

    // Top Left
    canvas.drawLine(
      const Offset(gap, gap + len),
      const Offset(gap, gap),
      paint,
    );
    canvas.drawLine(
      const Offset(gap, gap),
      const Offset(gap + len, gap),
      paint,
    );

    // Top Right
    canvas.drawLine(
      Offset(size.width - gap, gap + len),
      Offset(size.width - gap, gap),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - gap, gap),
      Offset(size.width - gap - len, gap),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(gap, size.height - gap - len),
      Offset(gap, size.height - gap),
      paint,
    );
    canvas.drawLine(
      Offset(gap, size.height - gap),
      Offset(gap + len, size.height - gap),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width - gap, size.height - gap - len),
      Offset(size.width - gap, size.height - gap),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - gap, size.height - gap),
      Offset(size.width - gap - len, size.height - gap),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerCornersPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// Scanner central widget
class ScannerLogo extends StatelessWidget {
  final double sweepProgress;
  final bool isDark;

  const ScannerLogo({
    super.key,
    required this.sweepProgress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark
        ? const Color(0xFF9E77F1)
        : const Color(0xFF6366F1);
    final secondaryColor = isDark
        ? const Color(0xFF4ECDC4)
        : const Color(0xFF00ACC1);

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Scanner Corners (drawn with custom brackets)
          CustomPaint(
            size: const Size(110, 110),
            painter: ScannerCornersPainter(color: primaryColor),
          ),

          // Outer Soft Glow Ring
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: secondaryColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Shield and Snowflake Centerpiece
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A273D) : Colors.white,
              border: Border.all(
                color: primaryColor.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/cg..png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Sweeping Laser Scan Line
          Positioned(
            top:
                15 +
                (sweepProgress * 80), // Sweeps between top and bottom bounds
            left: 15,
            right: 15,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: secondaryColor,
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.8),
                    blurRadius: 6,
                    spreadRadius: 1.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
