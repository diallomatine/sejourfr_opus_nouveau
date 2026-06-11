import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sejourfr_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _haloLoop;
  late final Animation<double> _cocardeScale;
  late final Animation<double> _cocardeFade;
  late final Animation<double> _wordmarkSlide;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _haloPulse;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _haloLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Cocarde : scale 0.6 → 1.0 avec un overshoot léger.
    _cocardeScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entry,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _cocardeFade = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // Wordmark : slide-up + fade après la cocarde.
    _wordmarkSlide = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
    );
    _taglineSlide = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
    );

    // Halo : pulsation douce en boucle (mouvement de vie pendant le boot).
    _haloPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _haloLoop, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _haloLoop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Halos pastel animés en boucle (effet de respiration).
          AnimatedBuilder(
            animation: _haloPulse,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -120,
                    left: -120,
                    child: Transform.scale(
                      scale: _haloPulse.value,
                      child: Container(
                        width: 360,
                        height: 360,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.blue.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -100,
                    child: Transform.scale(
                      scale: 2.0 - _haloPulse.value, // contre-phase
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.red.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          Center(
            child: AnimatedBuilder(
              animation: _entry,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cocarde : scale + fade
                    Opacity(
                      opacity: _cocardeFade.value,
                      child: Transform.scale(
                        scale: _cocardeScale.value,
                        child: const Cocarde(size: 140),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Wordmark : slide-up + fade
                    Opacity(
                      opacity: _wordmarkSlide.value,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - _wordmarkSlide.value)),
                        child: const SejourFrWordmark(fontSize: 48),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Tagline : slide-up + fade (un peu après le wordmark)
                    Opacity(
                      opacity: _taglineSlide.value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _taglineSlide.value)),
                        child: const SejourFrTagline(fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 56),
                    // Loader : visible une fois l'entrée terminée
                    Opacity(
                      opacity: _taglineSlide.value,
                      child: _AnimatedLoader(),
                    ),
                  ],
                );
              },
            ),
          ),

          // Footer fixe en bas
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Center(
              child: AnimatedBuilder(
                animation: _taglineSlide,
                builder: (context, _) {
                  return Opacity(
                    opacity: _taglineSlide.value * 0.9,
                    child: Text(
                      'Préparez votre titre de séjour ou votre naturalisation',
                      style: AppFonts.ui(
                        size: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoader extends StatefulWidget {
  @override
  State<_AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<_AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value + i / 3) % 1.0;
            final opacity = (1 - (phase * 2 - 1).abs()) * 0.7 + 0.3;
            final color = i == 0
                ? AppColors.blue
                : (i == 1 ? AppColors.muted2 : AppColors.red);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: opacity.clamp(0.2, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
