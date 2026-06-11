import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import 'level_pill.dart';

enum TaskProgressStatus { done, current, todo }

/// Ligne d'une tache dans la liste de progression :
///   - numero rond (bleu si done, gris sinon)
///   - nom de la tache + meta (Score / À faire / ...)
///   - pill niveau cible + score (si done) + pill niveau obtenu (si done)
/// Equivalent de `.task-progress-item` du mockup HTML.
class TaskProgressItem extends StatelessWidget {
  const TaskProgressItem({
    super.key,
    required this.number,
    required this.name,
    required this.niveauCible,
    required this.status,
    this.score,
    this.niveauObtenu,
  });

  final int number;
  final String name;
  final String niveauCible;
  final TaskProgressStatus status;
  final double? score;
  final NiveauCecrl? niveauObtenu;

  bool get _isDone => status == TaskProgressStatus.done;

  NiveauCecrl? _parseNiveauCible() {
    switch (niveauCible.toUpperCase()) {
      case 'A1':
        return NiveauCecrl.a1;
      case 'A2':
        return NiveauCecrl.a2;
      case 'B1':
        return NiveauCecrl.b1;
      case 'B2':
        return NiveauCecrl.b2;
      case 'C1':
        return NiveauCecrl.c1;
      case 'C2':
        return NiveauCecrl.c2;
      default:
        return null;
    }
  }

  String _formatScore(double s) {
    if (s == s.truncateToDouble()) return s.toInt().toString();
    return s.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final cibleNiveau = _parseNiveauCible();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isDone ? AppColors.blue : AppColors.bg,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w700,
                color: _isDone ? AppColors.white : AppColors.muted2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppFonts.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (_isDone && score != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Score',
                    style: AppFonts.ui(size: 12, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (cibleNiveau != null) ...[
            LevelPill(level: cibleNiveau, small: true),
            const SizedBox(width: 8),
          ],
          if (_isDone && score != null)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatScore(score!),
                    style: AppFonts.ui(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  TextSpan(
                    text: '/20',
                    style: AppFonts.ui(
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppColors.muted2,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              status == TaskProgressStatus.current ? 'En cours' : 'A faire',
              style: AppFonts.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.muted2,
              ).copyWith(fontStyle: FontStyle.italic),
            ),
          if (_isDone && niveauObtenu != null) ...[
            const SizedBox(width: 8),
            LevelPill(level: niveauObtenu!, small: true),
          ],
        ],
      ),
    );
  }
}
