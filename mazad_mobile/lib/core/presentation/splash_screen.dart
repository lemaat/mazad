import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  /// Called once the animation has completed one full cycle.
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _angle;
  late final Animation<double> _dust;
  late final Animation<double> _squash;

  @override
  void initState() {
    super.initState();

    // Full loop: 1600 ms — rest → wind-up → fast strike → impact → rebound → settle
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Pendulum angle (radians, CW from straight-down).
    // Positive angle = gavel swings to the right of centre.
    _angle = TweenSequence<double>([
      // Rest at right (+0.70 ≈ 40°)
      TweenSequenceItem(tween: ConstantTween(0.70), weight: 10),
      // Wind-up: pull further right (+1.20 ≈ 69°)
      TweenSequenceItem(
        tween: Tween(begin: 0.70, end: 1.20)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      // Fast strike: swing left through centre (≈0°) and just past (0.05)
      TweenSequenceItem(
        tween: Tween(begin: 1.20, end: 0.05)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 18,
      ),
      // Hold at impact
      TweenSequenceItem(tween: ConstantTween(0.05), weight: 7),
      // Rebound: bounce left past rest (−0.40)
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: -0.40)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 17,
      ),
      // Settle back to rest with slight elastic overshoot
      TweenSequenceItem(
        tween: Tween(begin: -0.40, end: 0.70)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 23,
      ),
    ]).animate(_ctrl);

    // Dust opacity: spikes exactly at impact
    _dust = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 53),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 7),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 13),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 27),
    ]).animate(_ctrl);

    // Head squash (1.0 = normal; dips to 0.65 at impact)
    _squash = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 53),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.65)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 7,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.65, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 13,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 27),
    ]).animate(_ctrl);

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentYellow,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(200, 230),
                painter: _GavelPainter(
                  angle: _angle.value,
                  dustOpacity: _dust.value,
                  headSquash: _squash.value,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'MAZAD',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GavelPainter extends CustomPainter {
  const _GavelPainter({
    required this.angle,
    required this.dustOpacity,
    required this.headSquash,
  });

  final double angle;       // radians CW from straight-down
  final double dustOpacity; // 0–1
  final double headSquash;  // 1.0 normal, <1 squashed at impact

  static const _paint = Color(0xFF0A66C2); // AppColors.primaryBlue (const-safe)

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = _paint..style = PaintingStyle.fill;

    final cx = size.width / 2;

    // Pivot fixed in upper-centre: gavel hangs and swings below it.
    const pivotY = 42.0;
    final pivotX = cx;
    const handleLen = 108.0;

    // Impact point: directly below pivot at handleLen (angle == 0).
    final strikeY = pivotY + handleLen;

    // --- Sound block (static, centred on impact point) ---
    final blockTop = strikeY + 6;
    canvas.drawRRect(
      RRect.fromLTRBR(
          cx - 38, blockTop, cx + 38, blockTop + 16, const Radius.circular(4)),
      p,
    );
    // Legs
    canvas.drawRRect(
      RRect.fromLTRBR(cx - 27, blockTop + 16, cx - 15, blockTop + 28,
          const Radius.circular(2)),
      p,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(cx + 15, blockTop + 16, cx + 27, blockTop + 28,
          const Radius.circular(2)),
      p,
    );

    // --- Dust particles at impact ---
    if (dustOpacity > 0) {
      final dp = Paint()
        ..color = _paint.withValues(alpha: dustOpacity * 0.50)
        ..style = PaintingStyle.fill;
      final spread = dustOpacity * 24.0;
      final r = 4.5 + dustOpacity * 3.5;
      canvas.drawCircle(Offset(pivotX - 36 - spread, strikeY + 7), r, dp);
      canvas.drawCircle(
          Offset(pivotX, strikeY - 16 - spread * 0.55), r * 0.70, dp);
      canvas.drawCircle(Offset(pivotX + 36 + spread, strikeY + 7), r, dp);
    }

    // --- Gavel (pendulum) — rotated around pivot ---
    canvas.save();
    canvas.translate(pivotX, pivotY);
    canvas.rotate(angle);

    // Handle: from pivot straight down
    const handleW = 11.0;
    canvas.drawRRect(
      RRect.fromLTRBR(
          -handleW / 2, 0, handleW / 2, handleLen, const Radius.circular(5)),
      p,
    );

    // Head at striking end (bottom of handle).
    // Width expands / height compresses during squash to conserve visual mass.
    const nomHeadW = 48.0;
    const nomHeadH = 22.0;
    final headH = nomHeadH * headSquash;
    final headW = headSquash < 1.0
        ? nomHeadW * (1.0 + (1.0 - headSquash) * 0.6)
        : nomHeadW;
    const headTop = handleLen - 1.0;

    canvas.drawRRect(
      RRect.fromLTRBR(
          -headW / 2, headTop, headW / 2, headTop + headH,
          const Radius.circular(6)),
      p,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GavelPainter old) =>
      old.angle != angle ||
      old.dustOpacity != dustOpacity ||
      old.headSquash != headSquash;
}
