import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/eyebrow.dart';
import '../../core/widgets/sejourfr_logo.dart';

const _kOnboardingSeenKey = 'sejourfr.onboardingSeen';

/// Provider pour savoir si l'onboarding a deja ete vu.
/// Utilise par le router pour rediriger ou pas.
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSeenKey) ?? false;
});

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      eyebrow: '§ 01 — Bienvenue',
      title: 'Préparez vos examens',
      titleEmphasis: 'sereinement',
      description:
          'Civique et TCF, dans une seule app. Entraînement par questions, corrections expliquées, examens blancs.',
      icon: Icons.school_outlined,
      accent: AppColors.blue,
    ),
    _Slide(
      eyebrow: '§ 02 — Adapté à votre objectif',
      title: 'CSP, carte de résident,',
      titleEmphasis: 'naturalisation',
      description: 'Trois niveaux de difficulté pour le civique, trois pour le TCF. Choisissez le vôtre.',
      icon: Icons.flag_outlined,
      accent: AppColors.red,
    ),
    _Slide(
      eyebrow: '§ 03 — En conditions réelles',
      title: 'Passez des',
      titleEmphasis: 'examens blancs',
      description:
          '40 questions en 45 minutes pour le civique. Chronomètre, score, seuil de réussite. Comme le jour J.',
      icon: Icons.timer_outlined,
      accent: AppColors.amber,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
    ref.invalidate(onboardingSeenProvider);
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header : logo + skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Cocarde(size: 32),
                  const SizedBox(width: 10),
                  const SejourFrWordmark(fontSize: 20),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Passer',
                      style: AppFonts.jakarta(
                        size: 13,
                        color: AppColors.muted,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Slides
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            // Indicateurs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.blue : AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: AppButton(
                label: _page == _slides.length - 1 ? 'Commencer' : 'Suivant',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.eyebrow,
    required this.title,
    required this.titleEmphasis,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final String titleEmphasis;
  final String description;
  final IconData icon;
  final Color accent;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: slide.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(slide.icon, color: slide.accent, size: 44),
          ),
          const SizedBox(height: 28),
          Eyebrow(slide.eyebrow),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: AppFonts.fraunces(size: 32, weight: FontWeight.w600),
              children: [
                TextSpan(text: '${slide.title} '),
                TextSpan(
                  text: slide.titleEmphasis,
                  style: TextStyle(
                    color: slide.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.description,
            style: AppFonts.jakarta(
              size: 14.5,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
