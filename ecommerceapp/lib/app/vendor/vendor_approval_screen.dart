import 'package:flutter/material.dart';
import 'package:pet_shop/base/get/route_key.dart';

class VendorApprovalScreen extends StatefulWidget {
  const VendorApprovalScreen({super.key});

  @override
  State<VendorApprovalScreen> createState() => _VendorApprovalScreenState();
}

class _VendorApprovalScreenState extends State<VendorApprovalScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _checkController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Circle scale in
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Text fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Tick draw
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOut,
    );

    // Subtle pulse on circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sequence: scale → tick → text → 3s wait → redirect to signup
    _scaleController.forward().then((_) {
      _checkController.forward().then((_) {
        _fadeController.forward().then((_) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              // ✅ Clear entire stack and go back to signup/registration
              Navigator.pushNamedAndRemoveUntil(
                context,
                registrationRoute,
                (route) => false,
              );
            }
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _checkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Animated tick circle
            ScaleTransition(
              scale: _scaleAnim,
              child: ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D9488),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.35),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _checkAnim,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _TickPainter(_checkAnim.value),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Submitted text
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const Text(
                    "Profile Submitted!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F2622),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      "Your vendor profile is under review.\nAdmin will approve shortly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF0F766E),
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _DotProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Draws the animated checkmark tick
class _TickPainter extends CustomPainter {
  final double progress;
  _TickPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx - 22, cy)
      ..lineTo(cx - 6, cy + 16)
      ..lineTo(cx + 22, cy - 16);

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}

// Animated 3-dot loader
class _DotProgressIndicator extends StatefulWidget {
  const _DotProgressIndicator();

  @override
  State<_DotProgressIndicator> createState() => _DotProgressIndicatorState();
}

class _DotProgressIndicatorState extends State<_DotProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            final bounce = (offset < 0.5 ? offset : 1.0 - offset) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8 + bounce * 6,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFB2DFDB),
                  const Color(0xFF0D9488),
                  bounce,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}