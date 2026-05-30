import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The Lablio mark (the "L5_gradfill" logo) that draws itself on:
/// the gradient L traces along its path, then the cyan dot pops in with a
/// small bounce, followed by a gentle shine sweep.
///
/// Drop it anywhere — splash, loading states, empty states, About screen.
/// Set [repeat] for a looping draw (e.g. a branded loading indicator).
class AnimatedLablioLogo extends StatefulWidget {
  final double size;
  final Duration duration;

  /// Loop the whole draw continuously (good for loading screens).
  final bool repeat;

  /// Paint the light rounded card behind the mark (matches the app icon).
  final bool background;

  /// Called once when a non-repeating animation finishes.
  final VoidCallback? onComplete;

  const AnimatedLablioLogo({
    super.key,
    this.size = 120,
    this.duration = const Duration(milliseconds: 1500),
    this.repeat = false,
    this.background = false,
    this.onComplete,
  });

  @override
  State<AnimatedLablioLogo> createState() => _AnimatedLablioLogoState();
}

class _AnimatedLablioLogoState extends State<AnimatedLablioLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.onComplete != null) {
      _c.addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete!.call();
      });
    }
    if (widget.repeat) {
      // Draw on, then draw off — a gentle "breathing" loop for loaders.
      _c.repeat(reverse: true);
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          // Timeline: draw the stroke, then pop the dot, then sweep a shine.
          final draw =
              Curves.easeInOutCubic.transform((t / 0.60).clamp(0.0, 1.0));
          final dot =
              Curves.easeOutBack.transform(((t - 0.52) / 0.30).clamp(0.0, 1.0));
          final shine =
              Curves.easeOut.transform(((t - 0.62) / 0.38).clamp(0.0, 1.0));
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _LablioLogoPainter(
              draw: draw,
              dot: dot,
              shine: shine,
              background: widget.background,
            ),
          );
        },
      ),
    );
  }
}

/// The Lablio mark sized for an AppBar `leading` slot. Draws itself once each
/// time the page is mounted (i.e. when you switch to that tab).
class LablioAppBarLogo extends StatelessWidget {
  final double size;
  const LablioAppBarLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedLablioLogo(
            size: size,
            duration: const Duration(milliseconds: 1300),
          ),
          const SizedBox(width: 5),
          // Subtle divider so the mark reads as a brand badge, not part of
          // the title text — white in dark mode, black in light mode.
          Container(
            width: 1,
            height: 20,
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}

/// A centered, looping Lablio mark for page-level loading states — a branded
/// replacement for a full-screen [CircularProgressIndicator].
class LablioLoader extends StatelessWidget {
  final double size;
  const LablioLoader({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedLablioLogo(
        size: size,
        repeat: true,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }
}

class _LablioLogoPainter extends CustomPainter {
  final double draw;
  final double dot;
  final double shine;
  final bool background;

  _LablioLogoPainter({
    required this.draw,
    required this.dot,
    required this.shine,
    required this.background,
  });

  // Source geometry from L5_gradfill.svg (512×512 viewBox).
  static const _vb = 512.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / _vb;
    final rect = Offset.zero & size;

    if (background) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(120 * s)),
        Paint()..color = const Color(0xFFEAF4FB),
      );
    }

    // The L: down the stem, round the corner, across the foot. Round join/caps
    // reproduce the SVG's small corner arc.
    final full = Path()
      ..moveTo(196 * s, 150 * s)
      ..lineTo(196 * s, 340 * s)
      ..lineTo(334 * s, 340 * s);

    // Extract the portion of the path drawn so far.
    final drawn = Path();
    final metrics = full.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var remaining = draw * total;
    for (final m in metrics) {
      if (remaining <= 0) break;
      final len = math.min(remaining, m.length);
      drawn.addPath(m.extractPath(0, len), Offset.zero);
      remaining -= len;
    }

    final shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0096C7), Color(0xFF023E8A)],
    ).createShader(rect);

    final stroke = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 46 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(drawn, stroke);

    // The cyan dot pops in after the stroke is mostly drawn.
    if (dot > 0) {
      canvas.drawCircle(
        Offset(324 * s, 180 * s),
        26 * s * dot,
        Paint()..color = const Color(0xFF0096C7),
      );
    }

    // A gentle white highlight sweeps along the finished stroke.
    if (draw >= 1 && shine > 0 && shine < 1) {
      final pos = 0.2 + shine * 0.6; // keep stops safely inside 0..1
      final sweep = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.6),
          Colors.transparent,
        ],
        stops: [pos - 0.14, pos, pos + 0.14],
      ).createShader(rect);
      final shinePaint = Paint()
        ..shader = sweep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 46 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.plus;
      canvas.drawPath(full, shinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LablioLogoPainter old) =>
      old.draw != draw ||
      old.dot != dot ||
      old.shine != shine ||
      old.background != background;
}
