import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class BotanicalDecoration extends StatelessWidget {
  const BotanicalDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Elegant botanical leaf branch illustration
          Positioned(
            left: 40,
            bottom: -30,
            child: Opacity(
              opacity: 0.35,
              child: CustomPaint(
                size: const Size(180, 260),
                painter: _BotanicalBranchPainter(),
              ),
            ),
          ),
          // Slogan & Divider at the bottom left
          Positioned(
            left: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Better',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 19,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8C7F72),
                    height: 1.1,
                  ),
                ),
                Text(
                  'People',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 19,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8C7F72),
                    height: 1.1,
                  ),
                ),
                Text(
                  'Brighter You',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 19,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8C7F72),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 22,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0A292),
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

class _BotanicalBranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.botanicalLeaf
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = AppColors.botanicalLeafLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Stem path
    final stemPath = Path();
    stemPath.moveTo(size.width * 0.2, size.height);
    stemPath.cubicTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.45,
      size.height * 0.35,
      size.width * 0.65,
      size.height * 0.05,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Leaf drawing helper
    void drawLeaf(
      double startX,
      double startY,
      double tipX,
      double tipY,
      double bulgeWidth,
    ) {
      final path = Path();
      path.moveTo(startX, startY);
      final midX = (startX + tipX) / 2;
      final midY = (startY + tipY) / 2;
      final dx = tipX - startX;
      final dy = tipY - startY;
      final normalX = -dy / 8;
      final normalY = dx / 8;

      path.quadraticBezierTo(
        midX + normalX * bulgeWidth,
        midY + normalY * bulgeWidth,
        tipX,
        tipY,
      );
      path.quadraticBezierTo(
        midX - normalX * bulgeWidth * 0.7,
        midY - normalY * bulgeWidth * 0.7,
        startX,
        startY,
      );
      path.close();
      canvas.drawPath(path, paint);
    }

    // Leaf 1 (lowest left)
    drawLeaf(
      size.width * 0.22,
      size.height * 0.75,
      size.width * 0.05,
      size.height * 0.62,
      2.5,
    );

    // Leaf 2 (lowest right)
    drawLeaf(
      size.width * 0.28,
      size.height * 0.70,
      size.width * 0.55,
      size.height * 0.60,
      2.8,
    );

    // Leaf 3 (mid left)
    drawLeaf(
      size.width * 0.35,
      size.height * 0.50,
      size.width * 0.15,
      size.height * 0.38,
      2.7,
    );

    // Leaf 4 (mid right)
    drawLeaf(
      size.width * 0.42,
      size.height * 0.45,
      size.width * 0.75,
      size.height * 0.33,
      3.0,
    );

    // Leaf 5 (upper left)
    drawLeaf(
      size.width * 0.50,
      size.height * 0.26,
      size.width * 0.30,
      size.height * 0.15,
      2.4,
    );

    // Leaf 6 (upper right)
    drawLeaf(
      size.width * 0.58,
      size.height * 0.20,
      size.width * 0.88,
      size.height * 0.12,
      2.5,
    );

    // Top terminal leaf
    drawLeaf(
      size.width * 0.65,
      size.height * 0.05,
      size.width * 0.75,
      0,
      2.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
