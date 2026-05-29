import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Splash shown at `/`. The router's auth-aware `redirect` sends the user to
/// `/home` or `/login` after the first frame, so this is a brief branded
/// loading screen. The Lablio mark animates in with a modern spring + fade,
/// a sweeping shine, and a settling word-mark.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with TickerProviderStateMixin {
  late final AnimationController _intro; // icon entrance
  late final AnimationController _shine; // looping sheen sweep

  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _wordSlide;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _iconScale = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack),
    );
    _iconFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _wordFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );
    _wordSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _intro.forward();
    // Start the shine sweep once the icon has popped in, then loop gently.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _shine.repeat();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Light background matches the app-icon tile (#EAF4FB).
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon with spring entrance + sweeping sheen ──
            FadeTransition(
              opacity: _iconFade,
              child: ScaleTransition(
                scale: _iconScale,
                child: AnimatedBuilder(
                  animation: _shine,
                  builder: (context, child) {
                    return ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (rect) {
                        final x = _shine.value; // 0..1 sweep position
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            Colors.transparent,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [
                            (x - 0.18).clamp(0.0, 1.0),
                            x.clamp(0.0, 1.0),
                            (x + 0.18).clamp(0.0, 1.0),
                          ],
                        ).createShader(rect);
                      },
                      child: child,
                    );
                  },
                  child: Container(
                    width: 132,
                    height: 132,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icon/icon_foreground.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            // ── Word-mark slides up + fades in ──
            SlideTransition(
              position: _wordSlide,
              child: FadeTransition(
                opacity: _wordFade,
                child: const Text(
                  'Lablio',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: _wordFade,
              child: Text(
                'Biomarker tracking',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
