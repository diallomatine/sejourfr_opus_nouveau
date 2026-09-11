import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/preparation_labels.dart';
import '../providers/preparation_provider.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// **Ma préparation** — l'état des deux modules, côte à côte.
///
/// 🛑 **C'est la PREMIÈRE des trois portes** vers un diagnostic inachevé
/// (Accueil, Plan, Examens). Elle lit `preparation()`, le **même** état que les
/// deux autres : c'est ce qui garantit que le candidat ne se voit pas proposer
/// trois choses différentes selon l'écran où il arrive.
///
/// 🛑 **Les deux modules avancent indépendamment.** Un candidat ne prépare pas
/// forcément les deux, et l'un ne dit rien de l'autre.
class PreparationCard extends ConsumerWidget {
  const PreparationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Best-effort : chargement ou échec ⇒ la carte est simplement absente.
    // L'accueil ne doit pas afficher une erreur pour un bloc de navigation.
    final prep = ref.watch(preparationProvider).valueOrNull;
    if (prep == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kPreparationTitle,
            style: AppFonts.display(size: 20, color: AppColors.ink)),
        const SizedBox(height: 10),
        _ModuleLigne(label: kTcfLabel, action: tcfAction(prep.tcf)),
        const SizedBox(height: 10),
        _ModuleLigne(label: kCiviqueLabel, action: civiqueAction(prep.civique)),
      ],
    );
  }
}

class _ModuleLigne extends StatelessWidget {
  const _ModuleLigne({required this.label, required this.action});

  final String label;
  final PreparationAction action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppFonts.label(size: 11, color: AppColors.inkFaint)),
          const SizedBox(height: 4),
          Text(action.statut,
              style: AppFonts.ui(size: 15, color: AppColors.ink)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => context.push(action.route),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action.cta,
                    style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.blue)),
                const SizedBox(width: 5),
                const Icon(LucideIcons.arrowRight,
                    size: 15, color: AppColors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
