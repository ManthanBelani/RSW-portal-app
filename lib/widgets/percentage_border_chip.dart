import 'package:flutter/material.dart';

class PercentageBorderChip extends StatelessWidget {
  final double percentage; // 0-100
  final bool isProfit;
  final Widget label;
  final String size;

  const PercentageBorderChip({
    super.key,
    required this.percentage,
    required this.isProfit,
    required this.label,
    this.size = 'medium',
  });

  @override
  Widget build(BuildContext context) {
    // Clamp percentage between 0 and 100
    final clampedPercentage = percentage.clamp(0.0, 100.0);
    
    // Determine colors based on profit/loss
    final fillColor = isProfit ? Colors.green : Colors.red;
    final borderColor = isProfit ? Colors.green : Colors.red;
    
    // Size configurations
    final double chipHeight = size == 'large' ? 36 : 32;
    
    return Container(
      height: chipHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Background gradient based on percentage
            CustomPaint(
              painter: _PercentageBackgroundPainter(
                percentage: clampedPercentage,
                fillColor: fillColor,
              ),
              child: SizedBox(
                width: double.infinity,
                height: chipHeight,
              ),
            ),
            // Label
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: borderColor.shade700,
                    fontSize: size == 'large' ? 13 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  child: label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentageBackgroundPainter extends CustomPainter {
  final double percentage;
  final Color fillColor;

  _PercentageBackgroundPainter({
    required this.percentage,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the width to fill based on percentage
    final fillWidth = (size.width * percentage) / 100;

    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    
    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    canvas.drawRect(fillRect, fillPaint);
    
    // Draw the white/unfilled portion (right side)
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final whiteRect = Rect.fromLTWH(fillWidth, 0, size.width - fillWidth, size.height);
    canvas.drawRect(whiteRect, whitePaint);
  }

  @override
  bool shouldRepaint(_PercentageBackgroundPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.fillColor != fillColor;
  }
}


