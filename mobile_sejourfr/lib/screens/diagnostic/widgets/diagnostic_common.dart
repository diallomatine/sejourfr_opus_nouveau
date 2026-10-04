import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

// ---------------------------------------------------------------------------
// Revenir à son écrit depuis l'écran de compte (parcours invité)
// ---------------------------------------------------------------------------
// Miroir mot pour mot de `web_sejoufr/lib/diagnostic.ts`
// (`DIAGNOSTIC_EDIT_*`, `diagnosticEditNote`).

/// Le retour de l'écran de compte vers l'écrit, pré-rempli.
const kDiagnosticEditWrittenCta = 'Modifier mon texte';

/// Quitter la modification sans rien changer à la production enregistrée.
const kDiagnosticEditCancel = 'Revenir sans modifier';

/// Le bouton de l'écrit rouvert : il remplace la production, puis ramène au
/// compte.
const kDiagnosticEditSubmit = 'Enregistrer mes modifications';

/// Ce qui ne bouge pas tant que la modification n'est pas enregistrée.
String diagnosticEditNote({required bool hasOral}) => hasOral
    ? 'Votre texte et votre enregistrement restent conservés tant que vous '
        'n’enregistrez pas vos modifications.'
    : 'Votre texte reste conservé tant que vous n’enregistrez pas vos '
        'modifications.';

/// Lien de retour dans le parcours (« ← Modifier mon texte », « ← Revenir
/// sans modifier ») : flèche + libellé, zone tactile de 44 px.
class DiagnosticBackLink extends StatelessWidget {
  const DiagnosticBackLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.arrowLeft,
                    size: 16,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppFonts.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Combien d'exercices d'expression compte ce diagnostic : un écrit, plus un
/// oral **seulement s'il est servi** (L3 — le rapide n'en a pas).
int diagnosticExpressionSteps({required bool hasOral}) => hasOral ? 2 : 1;

/// Le sous-titre d'en-tête d'une étape d'expression — « Étape 1 sur 2 · Écrit »,
/// ou « Écrit » tout court quand l'écrit est le seul exercice : « 1 sur 1 »
/// n'apprend rien au candidat.
String diagnosticStepHeader({
  required int step,
  required bool hasOral,
  required String label,
}) {
  final total = diagnosticExpressionSteps(hasOral: hasOral);
  return total == 1 ? label : 'Étape $step sur $total · $label';
}

/// La barre des exercices d'expression du diagnostic, un segment par exercice.
///
/// 🛑 **Le nombre de segments suit la FORME servie** ([diagnosticExpressionSteps]) :
/// le diagnostic rapide n'a qu'un écrit (oral `null`), et une barre à deux
/// segments y ferait croire qu'une étape reste à venir. Miroir de
/// `diagnosticSteps({oral})` (`web_sejoufr/app/_components/diagnostic/DiagnosticSteps.tsx`).
class DiagnosticProgress extends StatelessWidget {
  const DiagnosticProgress({
    super.key,
    required this.activeStep,
    required this.completedSteps,
    required this.totalSteps,
  });

  final int activeStep;
  final int completedSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape $activeStep sur $totalSteps, $completedSteps exercice'
          '${completedSteps > 1 ? 's' : ''} terminé'
          '${completedSteps > 1 ? 's' : ''}',
      child: Row(
        children: [
          for (var index = 1; index <= totalSteps; index++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 5,
                decoration: BoxDecoration(
                  color: index <= completedSteps || index == activeStep
                      ? AppColors.blue
                      : AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            if (index != totalSteps) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// L'écran d'un exercice du diagnostic (écrit, oral)
// ---------------------------------------------------------------------------
// Miroir mot pour mot de `web_sejoufr/lib/diagnostic.ts`
// (`DIAGNOSTIC_EXERCISE_*`, `diagnosticExerciseSub`,
// `diagnosticWrittenSubmitLabel`, `diagnosticConsigneBlocks`).

enum DiagnosticExerciseKind { written, oral }

/// Sur-titre de l'écran d'exercice.
String diagnosticExerciseKicker(DiagnosticExerciseKind kind) => switch (kind) {
      DiagnosticExerciseKind.written => 'Diagnostic TCF · Expression écrite',
      DiagnosticExerciseKind.oral => 'Diagnostic TCF · Expression orale',
    };

/// Titre : `lead` puis `em` (rouge), puis `tail` collé.
({String lead, String em, String tail}) diagnosticExerciseTitle(
  DiagnosticExerciseKind kind,
) =>
    switch (kind) {
      DiagnosticExerciseKind.written => (
          lead: 'Votre texte,',
          em: 'votre niveau',
          tail: '.'
        ),
      DiagnosticExerciseKind.oral => (
          lead: 'Votre voix,',
          em: 'votre niveau',
          tail: '.'
        ),
    };

/// La ligne sous le titre. 🛑 **Le rang se lit sur la FORME servie** (oral
/// `null` ⇒ exercice unique) : le diagnostic rapide n'a qu'un écrit.
String diagnosticExerciseSub(
  DiagnosticExerciseKind kind, {
  required bool hasOral,
}) {
  final rang = kind == DiagnosticExerciseKind.oral
      ? 'Deuxième et dernier exercice'
      : hasOral
          ? 'Premier exercice sur deux'
          : 'Un seul exercice';
  return '$rang · aucune note sur 20.';
}

/// Tête de la zone de saisie de l'écrit.
const kDiagnosticWrittenEditorTitle = 'Votre texte';

/// Sur-titre de la carte du sujet.
const kDiagnosticSubjectTag = 'Votre sujet';

/// Le bouton de l'écrit : il dit ce qui se passe **ensuite**, selon la forme
/// servie et le régime. Avec un oral, on continue ; sans, un visiteur valide
/// son texte (le compte vient après), un compte lance l'analyse.
String diagnosticWrittenSubmitLabel({
  required bool guest,
  required bool hasOral,
}) {
  if (hasOral) return 'Continuer vers l’oral';
  return guest ? 'Valider mon texte' : 'Lancer mon analyse';
}

/// Un bloc de consigne : un paragraphe (`items` vide), ou une liste précédée
/// de son amorce.
class DiagnosticConsigneBlock {
  const DiagnosticConsigneBlock.paragraph(String this.text)
      : lead = null,
        items = const [],
        ordered = false;

  const DiagnosticConsigneBlock.list({
    required this.lead,
    required this.items,
    required this.ordered,
  }) : text = null;

  final String? text;
  final String? lead;
  final List<String> items;
  final bool ordered;

  bool get isList => text == null;
}

final _consigneBullet = RegExp(r'^\s*(?:[-•*]|\d+[.)])\s+');
final _consigneNumbered = RegExp(r'^\s*\d+[.)]\s+');

/// **Met en forme** la consigne servie, sans en réécrire un mot : paragraphes
/// séparés par une ligne vide ; un paragraphe dont les lignes suivantes
/// commencent par « - », « • », « * » ou « 1. » devient une liste, sa
/// première ligne (« Dans un seul texte : ») en devient l'amorce. Une liste
/// numérotée le reste (`ordered`).
List<DiagnosticConsigneBlock> diagnosticConsigneBlocks(String text) {
  final paragraphs = text
      .replaceAll('\r\n', '\n')
      .trim()
      .split(RegExp(r'\n\s*\n'))
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty);
  return [
    for (final paragraph in paragraphs) _consigneBlock(paragraph),
  ];
}

DiagnosticConsigneBlock _consigneBlock(String paragraph) {
  final lines = paragraph
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  final firstBullet = lines.indexWhere(_consigneBullet.hasMatch);
  final bullets =
      firstBullet < 0 ? const <String>[] : lines.sublist(firstBullet);
  final bulletsOnly =
      firstBullet >= 0 && bullets.every(_consigneBullet.hasMatch);
  if (!bulletsOnly || firstBullet > 1 || bullets.length < 2) {
    return DiagnosticConsigneBlock.paragraph(paragraph);
  }
  return DiagnosticConsigneBlock.list(
    lead: firstBullet == 1 ? lines.first : null,
    ordered: bullets.every(_consigneNumbered.hasMatch),
    items: [
      for (final line in bullets) line.replaceFirst(_consigneBullet, ''),
    ],
  );
}

/// En-tête d'un exercice : sur-titre, titre à mot rouge, puis le rang **lu sur
/// la forme servie** et « aucune note sur 20 ». Miroir d'`ExerciseHeader`
/// (`DiagnosticView.tsx`).
class DiagnosticExerciseHeader extends StatelessWidget {
  const DiagnosticExerciseHeader({
    super.key,
    required this.kind,
    required this.hasOral,
  });

  final DiagnosticExerciseKind kind;
  final bool hasOral;

  @override
  Widget build(BuildContext context) {
    final title = diagnosticExerciseTitle(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diagnosticExerciseKicker(kind).toUpperCase(),
          style: AppFonts.label(size: 11, color: AppColors.blue),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${title.lead} '),
              TextSpan(
                text: title.em,
                style: const TextStyle(color: AppColors.red),
              ),
              TextSpan(text: title.tail),
            ],
          ),
          style: AppFonts.display(size: 28, height: 1.12),
        ),
        const SizedBox(height: 8),
        Text(
          diagnosticExerciseSub(kind, hasOral: hasOral),
          style: AppFonts.ui(size: 14, color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

/// La carte du sujet : liseré tricolore, sur-titre, titre du sujet, consigne
/// servie mise en forme (paragraphes et puces), puis une ligne discrète sur
/// le pourquoi de l'exercice. 🛑 **Aucune fourchette de mots ici** : elle vit
/// dans la zone de saisie, à côté du compteur. Miroir d'`ExercisePrompt`.
class DiagnosticExerciseCard extends StatelessWidget {
  const DiagnosticExerciseCard({super.key, required this.exercise});

  final DiagnosticExerciseView exercise;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: AppRadii.xl,
      padding: EdgeInsets.zero,
      // Le liseré suit l'arrondi de la carte (bord de 1 px compris).
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl - 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FlagRule(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kDiagnosticSubjectTag.toUpperCase(),
                    style: AppFonts.label(size: 10.5, color: AppColors.blue),
                  ),
                  const SizedBox(height: 6),
                  Text(exercise.title, style: AppFonts.display(size: 21)),
                  const SizedBox(height: 14),
                  DiagnosticConsigne(text: exercise.instruction),
                  if (exercise.helperText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.line2),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.info,
                            size: 14,
                            color: AppColors.muted2,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            exercise.helperText,
                            style: AppFonts.ui(
                              size: 12.5,
                              color: AppColors.muted,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liseré bleu / blanc / rouge en tête de la carte du sujet.
class _FlagRule extends StatelessWidget {
  const _FlagRule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 4,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: AppColors.blue)),
          Expanded(child: ColoredBox(color: AppColors.line)),
          Expanded(child: ColoredBox(color: AppColors.red)),
        ],
      ),
    );
  }
}

/// La consigne servie mise en forme par [diagnosticConsigneBlocks] — partagée
/// par la carte du sujet et « Revoir ma réponse ».
class DiagnosticConsigne extends StatelessWidget {
  const DiagnosticConsigne({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.ui(size: 15, color: AppColors.ink2, height: 1.55);
    final blocks = diagnosticConsigneBlocks(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i != 0) const SizedBox(height: 12),
          if (!blocks[i].isList)
            Text(blocks[i].text!, style: style)
          else ...[
            if (blocks[i].lead != null) ...[
              Text(
                blocks[i].lead!,
                style: style.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            for (var j = 0; j < blocks[i].items.length; j++) ...[
              if (j != 0) const SizedBox(height: 8),
              _ConsigneItem(
                text: blocks[i].items[j],
                rank: blocks[i].ordered ? j + 1 : null,
                style: style,
              ),
            ],
          ],
        ],
      ],
    );
  }
}

class _ConsigneItem extends StatelessWidget {
  const _ConsigneItem({
    required this.text,
    required this.rank,
    required this.style,
  });

  final String text;

  /// Rang d'une liste numérotée ; `null` = puce.
  final int? rank;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: rank != null
                ? Text(
                    '$rank',
                    style: AppFonts.label(size: 13, color: AppColors.blue),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class DiagnosticErrorBanner extends StatelessWidget {
  const DiagnosticErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.redLight,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              size: 18,
              color: AppColors.red,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: AppFonts.ui(
                  size: 13,
                  color: AppColors.redDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le chargement d'une session de diagnostic, puis son échec avec
/// « Réessayer ». Partagé par le parcours (`DiagnosticScreen`) et la relecture
/// d'un diagnostic clos (`DiagnosticRapportScreen`).
class DiagnosticLoadState extends StatelessWidget {
  const DiagnosticLoadState({
    super.key,
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading && errorMessage == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            children: [
              if (errorMessage != null)
                DiagnosticErrorBanner(message: errorMessage!),
              const SizedBox(height: 14),
              AppButton(
                label: 'Réessayer',
                variant: AppButtonVariant.soft,
                isLoading: isLoading,
                onPressed: isLoading ? null : onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
