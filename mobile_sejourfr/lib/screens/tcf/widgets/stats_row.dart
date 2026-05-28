import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Trois mini-cards stats (Séances / Pratique / Jours actifs) en bas du hub
/// TCF. Valeurs `null` rendues en « — » (placeholder).
class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.sessions,
    required this.practice,
    required this.activeDays,
  });

  /// Nombre de séances (attempts) déjà passées.
  final String? sessions;

  /// Temps de pratique cumulé (ex. « 4h 20 »). Pas encore branché côté
  /// backend → null pour l'instant.
  final String? practice;

  /// Nombre de jours actifs distincts (streak / activité). Pas encore
  /// branché côté backend → null pour l'instant.
  final String? activeDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCell(value: sessions ?? '—', label: 'Séances')),
        const SizedBox(width: 8),
        Expanded(child: _StatCell(value: practice ?? '—', label: 'Pratique')),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(value: activeDays ?? '—', label: 'Jours actifs'),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.jakarta(
              size: 16,
              weight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.jakarta(size: 10.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
