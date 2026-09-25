import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/eyebrow.dart';
import '../../../core/widgets/fixed_action_bar.dart';
import '../diagnostic_intro_labels.dart';
import 'diagnostic_common.dart';

/// Présentation du diagnostic TCF pour un **compte connecté**.
///
/// 🛑 **Le visiteur ne passe plus par ici** (2026-09-26) : son entrée est le
/// choix d'examen TCF ⇄ civique, `DiagnosticChoice`. Un compte connecté a déjà
/// choisi son parcours — il arrive depuis le Plan TCF ou l'Accueil TCF (souvent
/// avec `?demarrer=1`, qui saute cet écran) : on ne lui rouvre pas le choix, et
/// le diagnostic civique garde ses propres portes. Miroir web :
/// `DiagnosticIntro.tsx` / `DiagnosticChoice.tsx`.
class DiagnosticIntro extends StatelessWidget {
  const DiagnosticIntro({
    super.key,
    required this.isStarting,
    required this.onStart,
    this.written,
    this.oral,
    this.errorMessage,
  });

  final bool isStarting;

  final VoidCallback onStart;

  /// Les deux sujets servis, quand ils existent : c'est d'eux que sortent les
  /// mesures annoncées. Absents (compte sans session, réseau), l'écran retombe
  /// sur une description sans chiffre plutôt que d'en inventer un.
  final DiagnosticExerciseView? written;
  final DiagnosticExerciseView? oral;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final minutes = diagnosticExpressionMinutes(written, oral);
    final duree = minutes == null ? null : '≈ $minutes min';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Text(
                'Quel examen préparez-vous ?',
                style: AppFonts.display(size: 26, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Les deux diagnostics sont gratuits. Choisissez celui qui '
                'correspond à votre démarche ; vous pourrez faire l’autre plus '
                'tard.',
                style: AppFonts.ui(
                  size: 14,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                DiagnosticErrorBanner(message: errorMessage!),
              ],
              const SizedBox(height: 18),

              _ExamCard(
                emoji: '🇫🇷',
                title: 'TCF IRN',
                meta: oral != null
                    ? 'Expression écrite + expression orale'
                    : 'Une production écrite',
                duration: duree,
                highlights: const [
                  'Une estimation de votre niveau, sur ce que vous savez '
                      'réellement produire',
                  'Ce qu’il faut travailler pour atteindre votre objectif',
                  'Vous commencez à écrire tout de suite',
                ],
                highlighted: true,
              ),
              const SizedBox(height: 24),
              // 🛑 On n'annonce que ce qui existe (L3) : sans étape orale, dire
              // « les deux premiers exercices » puis n'en montrer qu'un fausse
              // l'engagement du candidat dès la première seconde.
              Eyebrow(oral == null
                  ? 'CE QUE CONTIENT LE DIAGNOSTIC TCF'
                  : 'LES DEUX PREMIERS EXERCICES'),
              const SizedBox(height: 10),
              _IntroItem(
                icon: LucideIcons.penLine,
                title: 'Écrit',
                measure:
                    diagnosticWrittenMeasureLabel(written) ?? 'un court texte',
                text: 'Vous rédigez un court texte.',
              ),
              if (oral != null) ...[
                const SizedBox(height: 10),
                _IntroItem(
                  icon: LucideIcons.mic,
                  title: 'Oral',
                  measure: diagnosticOralMeasureLabel(oral) ??
                      'un court enregistrement',
                  text: 'Vous vous enregistrez, sans conversation en direct.',
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Pas besoin d’être parfait. Répondez naturellement : '
                'l’objectif est simplement d’estimer votre niveau et de '
                'construire votre plan.',
                style: AppFonts.ui(
                  size: 13.5,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Votre diagnostic reste accessible ensuite : vous pouvez '
                'compléter les épreuves manquantes quand vous voulez.',
                style: AppFonts.ui(
                  size: 12,
                  color: AppColors.inkFaint,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Estimation d’entraînement, non officielle.',
                textAlign: TextAlign.center,
                style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
        FixedActionBar(
          child: AppButton(
            label: 'Commencer le diagnostic TCF',
            iconRight: LucideIcons.arrowRight,
            isLoading: isStarting,
            onPressed: isStarting ? null : onStart,
          ),
        ),
      ],
    );
  }
}

/// La carte d'examen TCF. Elle n'a **pas** de bouton : son action est la barre
/// fixe du bas, qui reste atteignable quel que soit le
/// défilement.
class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.emoji,
    required this.title,
    required this.meta,
    required this.highlights,
    this.duration,
    this.highlighted = false,
  });

  final String emoji;
  final String title;
  final String meta;
  final List<String> highlights;
  final String? duration;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: highlighted ? AppColors.blueSoft : AppColors.white,
      border: Border.all(
        color: highlighted ? AppColors.blue : AppColors.line,
        width: highlighted ? 1.5 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppFonts.display(size: 19)),
              ),
              const SizedBox(width: 8),
              // 🛑 « Sans compte » des DEUX côtés : les deux diagnostics se
              // passent avant l'inscription.
              const AppTag(label: 'Sans compte', tone: TagTone.blue),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Flexible(
                child: Text(
                  meta,
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
              if (duration != null) ...[
                const SizedBox(width: 12),
                const Icon(LucideIcons.clock,
                    size: 13, color: AppColors.inkFaint),
                const SizedBox(width: 5),
                Text(
                  duration!,
                  style: AppFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          for (final highlight in highlights) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(LucideIcons.check,
                      size: 14, color: AppColors.blue),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    highlight,
                    style: AppFonts.ui(
                      size: 13.5,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _IntroItem extends StatelessWidget {
  const _IntroItem({
    required this.icon,
    required this.title,
    required this.measure,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String measure;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 21, color: AppColors.blue),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title,
                        style:
                            AppFonts.ui(size: 14.5, weight: FontWeight.w700)),
                    Text(
                      measure,
                      style: AppFonts.ui(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.inkFaint,
                    height: 1.35,
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
