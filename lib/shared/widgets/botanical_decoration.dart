import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BotanicalDecoration extends StatelessWidget {
  /// When true, renders smaller and lower-contrast — for sidebars where the
  /// decoration should read as a quiet footer, not compete with navigation.
  /// Defaults to false so existing (Admin) usage is unaffected.
  final bool compact;
  final Color? barColor;

  const BotanicalDecoration({
    super.key,
    this.compact = false,
    this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 150.0 : 210.0;
    final fontSize = compact ? 13.0 : 15.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background subtle ambient restorative healthcare aura
          Positioned(
            right: 0,
            bottom: 0,
            width: compact ? 140 : 180,
            height: compact ? 140 : 180,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.4, 0.4),
                    radius: 0.85,
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.04),
                      const Color(0xFF0F766E).withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Botanical art: positioned on the right side so it NEVER underlaps or intersects the text
          Positioned(
            right: compact ? 4 : 8,
            bottom: compact ? 0 : 4,
            child: CustomPaint(
              size: compact ? const Size(100, 142) : const Size(130, 185),
              painter: _BotanicalArtPainter(),
            ),
          ),

          // Clean, unhindered inspirational clinic quote at the bottom-left
          Positioned(
            left: compact ? 18 : 22,
            bottom: compact ? 14 : 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Better People',
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.22,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Brighter You',
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                    height: 1.22,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: compact ? 7 : 9),
                Container(
                  width: compact ? 22 : 28,
                  height: 2,
                  decoration: BoxDecoration(
                    color: barColor ?? const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotanicalArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette: Soothing healthcare botanicals (Sage, Emerald & Herbal Teal)
    const primaryLeafColor = Color(0xFF0D9488);
    const secondaryLeafColor = Color(0xFF10B981);
    const stemColor = Color(0xFF14B8A6);
    const accentNodeColor = Color(0xFF5E35B1);

    final stemPaint = Paint()
      ..color = stemColor.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final secondaryStemPaint = Paint()
      ..color = stemColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()
      ..color = primaryLeafColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final secondaryLeafPaint = Paint()
      ..color = secondaryLeafColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final veinPaint = Paint()
      ..color = const Color(0xFF042F2E).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    // Helper to draw an organic botanical leaf with a delicate central vein
    void drawBotanicalLeaf({
      required Canvas canvas,
      required Offset base,
      required Offset tip,
      required double curvature,
      required Paint fillPaint,
      bool drawVein = true,
    }) {
      final dx = tip.dx - base.dx;
      final dy = tip.dy - base.dy;
      final midX = (base.dx + tip.dx) / 2;
      final midY = (base.dy + tip.dy) / 2;
      final normalX = -dy * curvature;
      final normalY = dx * curvature;

      final path = Path();
      path.moveTo(base.dx, base.dy);
      path.quadraticBezierTo(
        midX + normalX,
        midY + normalY,
        tip.dx,
        tip.dy,
      );
      path.quadraticBezierTo(
        midX - normalX * 0.75,
        midY - normalY * 0.75,
        base.dx,
        base.dy,
      );
      path.close();
      canvas.drawPath(path, fillPaint);

      if (drawVein) {
        final veinPath = Path();
        veinPath.moveTo(base.dx, base.dy);
        veinPath.quadraticBezierTo(
          midX + normalX * 0.15,
          midY + normalY * 0.15,
          base.dx + dx * 0.85,
          base.dy + dy * 0.85,
        );
        canvas.drawPath(veinPath, veinPaint);
      }
    }

    // 1. PRIMARY STEM (Gracefully sweeping eucalyptus/olive branch)
    final mainStemPath = Path();
    mainStemPath.moveTo(w * 0.82, h * 0.98);
    mainStemPath.cubicTo(
      w * 0.76, h * 0.70,
      w * 0.65, h * 0.38,
      w * 0.52, h * 0.06,
    );
    canvas.drawPath(mainStemPath, stemPaint);

    // Primary Stem Leaves (Pairs / Alternating nodes along main stem)
    // Node 1 (lower)
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.78, h * 0.80),
      tip: Offset(w * 0.48, h * 0.74),
      curvature: 0.26,
      fillPaint: leafPaint,
    );
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.75, h * 0.72),
      tip: Offset(w * 0.98, h * 0.65),
      curvature: 0.24,
      fillPaint: leafPaint,
    );

    // Node 2 (mid)
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.69, h * 0.52),
      tip: Offset(w * 0.40, h * 0.44),
      curvature: 0.26,
      fillPaint: leafPaint,
    );
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.64, h * 0.44),
      tip: Offset(w * 0.90, h * 0.36),
      curvature: 0.24,
      fillPaint: leafPaint,
    );

    // Node 3 (upper)
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.58, h * 0.28),
      tip: Offset(w * 0.32, h * 0.20),
      curvature: 0.24,
      fillPaint: leafPaint,
    );
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.54, h * 0.18),
      tip: Offset(w * 0.78, h * 0.12),
      curvature: 0.22,
      fillPaint: leafPaint,
    );

    // Terminal leaf at the top
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.52, h * 0.06),
      tip: Offset(w * 0.55, 0),
      curvature: 0.18,
      fillPaint: leafPaint,
    );

    // 2. SECONDARY ACCENT SPRIG (Delicate herbal branch branching to the right)
    final secondaryStemPath = Path();
    secondaryStemPath.moveTo(w * 0.78, h * 0.78);
    secondaryStemPath.cubicTo(
      w * 0.88, h * 0.70,
      w * 0.96, h * 0.55,
      w * 0.92, h * 0.38,
    );
    canvas.drawPath(secondaryStemPath, secondaryStemPaint);

    // Secondary Sprig Leaves
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.85, h * 0.68),
      tip: Offset(w * 1.00, h * 0.72),
      curvature: 0.20,
      fillPaint: secondaryLeafPaint,
      drawVein: false,
    );
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.92, h * 0.52),
      tip: Offset(w * 1.02, h * 0.46),
      curvature: 0.20,
      fillPaint: secondaryLeafPaint,
      drawVein: false,
    );
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.92, h * 0.38),
      tip: Offset(w * 0.98, h * 0.30),
      curvature: 0.18,
      fillPaint: secondaryLeafPaint,
      drawVein: false,
    );

    // 3. REFINED HEALTHCARE MOTIFS (Subtle wellness dew/accents & floating leaf)
    final nodePaint = Paint()
      ..color = accentNodeColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.74, h * 0.62), 2.0, nodePaint);
    canvas.drawCircle(Offset(w * 0.90, h * 0.45), 1.8, nodePaint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.35), 1.6, nodePaint);

    // Floating petal accent drifting peacefully
    drawBotanicalLeaf(
      canvas: canvas,
      base: Offset(w * 0.42, h * 0.58),
      tip: Offset(w * 0.30, h * 0.50),
      curvature: 0.22,
      fillPaint: Paint()..color = secondaryLeafColor.withValues(alpha: 0.18),
      drawVein: false,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
