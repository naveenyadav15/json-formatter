import 'package:flutter/material.dart';

class LineNumberGutter extends StatelessWidget {
  final int totalLines;
  final double scrollOffset;
  final double lineHeight;
  final double width;
  final EdgeInsets padding;

  const LineNumberGutter({
    super.key,
    required this.totalLines,
    required this.scrollOffset,
    required this.lineHeight,
    this.width = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: CustomPaint(
        painter: _LineNumberPainter(
          totalLines: totalLines,
          scrollOffset: scrollOffset,
          lineHeight: lineHeight,
          textStyle: TextStyle(
            fontFamily: 'SF Mono',
            height: 1.4,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          padding: padding,
          dividerColor: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
    );
  }
}

class _LineNumberPainter extends CustomPainter {
  final int totalLines;
  final double scrollOffset;
  final double lineHeight;
  final TextStyle textStyle;
  final EdgeInsets padding;
  final Color dividerColor;

  _LineNumberPainter({
    required this.totalLines,
    required this.scrollOffset,
    required this.lineHeight,
    required this.textStyle,
    required this.padding,
    required this.dividerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw right divider
    final paint = Paint()
      ..color = dividerColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width - 0.5, 0),
        Offset(size.width - 0.5, size.height), paint);

    final startLine = (scrollOffset / lineHeight).floor();
    final visibleLines = (size.height / lineHeight).ceil() + 1;
    final endLine = (startLine + visibleLines).clamp(0, totalLines);

    double y = -(scrollOffset % lineHeight);
    for (int i = startLine; i < endLine; i++) {
      final textSpan = TextSpan(text: '${i + 1}', style: textStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas,
          Offset(size.width - padding.right - tp.width, y + padding.top));
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _LineNumberPainter oldDelegate) {
    return oldDelegate.totalLines != totalLines ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.textStyle != textStyle;
  }
}
