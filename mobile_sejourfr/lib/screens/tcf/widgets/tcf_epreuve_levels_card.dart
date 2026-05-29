import 'package:flutter/material.dart';

import '../../../core/api/user_content_repository.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Carte « Niveau par épreuve » du hub TCF : le dernier passage de chacune des
/// 4 épreuves (CO / CE / EE / EO) avec son niveau CECRL et un détail de score
/// (calibré 100-499 pour les QCM, note /20 pour les productions).
///
/// Le niveau global affiché ailleurs (CecrlProgressCard) est le **plancher** de
/// ces 4 niveaux — jamais une moyenne. Couleurs via `NiveauCecrl.color`
/// (ambre / bleu / vert, jamais de rouge pour un niveau faible).
class TcfEpreuveLevelsCard extends StatelessWidget {
  const TcfEpreuveLevelsCard({super.key, required this.profile});

  final TcfLevelProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NIVEAU PAR ÉPREUVE',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.muted,
              letterSpacing: 1.4,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          _EpreuveRow(label: 'Compréhension orale', data: profile.co),
          _EpreuveRow(label: 'Compréhension écrite', data: profile.ce),
          _EpreuveRow(label: 'Expression écrite', data: profile.ee),
          _EpreuveRow(label: 'Expression orale', data: profile.eo),
        ],
      ),
    );
  }
}

class _EpreuveRow extends StatelessWidget {
  const _EpreuveRow({required this.label, required this.data});

  final String label;
  final TcfEpreuveLevel data;

  @override
  Widget build(BuildContext context) {
    final level = data.level;
    final detail = _detail(data);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppFonts.jakarta(size: 13.5, weight: FontWeight.w600),
            ),
          ),
          if (detail != null) ...[
            Text(
              detail,
              style: AppFonts.mono(size: 10.5, color: AppColors.muted),
            ),
            const SizedBox(width: 10),
          ],
          _LevelPill(level: level),
        ],
      ),
    );
  }

  /// Détail de score : calibré X/499 pour les QCM, note Y/20 pour EE/EO.
  /// Null si l'épreuve n'a pas encore été passée.
  static String? _detail(TcfEpreuveLevel d) {
    if (!d.attempted) return null;
    if (d.calibratedScore != null) return '${d.calibratedScore} / 499';
    if (d.note20 != null) {
      final n = d.note20!;
      final txt = n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
      return '$txt / 20';
    }
    return null;
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final NiveauCecrl? level;

  @override
  Widget build(BuildContext context) {
    if (level == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.line2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '—',
          style: AppFonts.mono(
            size: 11,
            color: AppColors.muted2,
            weight: FontWeight.w700,
          ),
        ),
      );
    }
    final color = level!.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level!.displayName,
        style: AppFonts.mono(size: 11, color: color, weight: FontWeight.w700),
      ),
    );
  }
}
