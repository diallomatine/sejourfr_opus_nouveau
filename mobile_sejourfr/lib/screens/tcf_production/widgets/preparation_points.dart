import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Points de préparation « Pour réussir, pensez à » par épreuve / tâche.
/// Source unique, partagée par le briefing EO/EE, le plan de méthode, etc.
List<(String, String)> productionPreparationPoints({
  required bool isEo,
  required int tache,
}) {
  if (isEo) {
    return switch (tache) {
      1 => const [
          ('Présentez-vous', 'Prénom, origine, ville et situation actuelle.'),
          (
            'Parlez de votre quotidien',
            'Travail ou études, famille, activités.'
          ),
          (
            'Terminez par votre projet',
            'Pourquoi vous passez le TCF, vos objectifs.'
          ),
        ],
      2 => const [
          (
            'Posez des questions claires',
            'Au moins 4 questions sur des aspects différents.'
          ),
          (
            'Réagissez à l\'interlocuteur',
            '« D\'accord », « Très bien », « C\'est possible quand ? »'
          ),
          ('Terminez l\'échange', 'Proposez une suite, puis remerciez.'),
        ],
      _ => const [
          ('Annoncez votre position', '« À mon avis… », « Je pense que… »'),
          (
            'Donnez deux arguments',
            '« D\'abord… ensuite… » avec un exemple pour chacun.'
          ),
          ('Concluez en nuançant', '« Cependant… », « Pour finir… »'),
        ],
    };
  }
  return switch (tache) {
    1 => const [
        (
          'Répondez au message reçu',
          'Acceptez ou refusez, réagissez au déclencheur.'
        ),
        (
          'Donnez les informations utiles',
          'Jour, heure, lieu, détails demandés.'
        ),
        (
          'Posez une question et concluez',
          'Avec une formule de fin adaptée à un ami.'
        ),
      ],
    2 => const [
        ('Plantez le décor', 'Quand, où, avec qui.'),
        (
          'Racontez le déroulement',
          'Au passé composé / imparfait, avec une anecdote.'
        ),
        ('Terminez par un bilan', 'Ce que vous en avez retenu.'),
      ],
    _ => const [
        ('Annoncez votre thèse', '« Selon moi… », « Je pense que… »'),
        ('Donnez deux arguments illustrés', 'Un exemple concret pour chacun.'),
        ('Traitez une objection', '« Certes… toutefois… » puis concluez.'),
      ],
  };
}

/// Liste numérotée « POUR RÉUSSIR, PENSEZ À » : pastilles rouges + titre + aide.
class PreparationPoints extends StatelessWidget {
  const PreparationPoints({
    super.key,
    required this.isEo,
    required this.tache,
    this.label = 'POUR RÉUSSIR, PENSEZ À',
  });

  final bool isEo;
  final int tache;
  final String label;

  @override
  Widget build(BuildContext context) {
    final points = productionPreparationPoints(isEo: isEo, tache: tache);
    if (points.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.mono(
            size: 9.5,
            color: AppColors.muted,
            letterSpacing: 1.6,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final (i, point) in points.indexed) ...[
          _PreparationPoint(index: i + 1, titre: point.$1, aide: point.$2),
          if (i < points.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PreparationPoint extends StatelessWidget {
  const _PreparationPoint({
    required this.index,
    required this.titre,
    required this.aide,
  });

  final int index;
  final String titre;
  final String aide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.redLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: AppFonts.ui(
                    size: 13.5,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  aide,
                  style: AppFonts.ui(
                    size: 12,
                    color: AppColors.muted,
                    height: 1.4,
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
