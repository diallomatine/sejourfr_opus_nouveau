import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/repositories.dart';
import '../models/preparation_labels.dart';
import '../models/preparation_models.dart';
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
class PreparationCard extends ConsumerStatefulWidget {
  const PreparationCard({super.key});

  @override
  ConsumerState<PreparationCard> createState() => _PreparationCardState();
}

class _PreparationCardState extends ConsumerState<PreparationCard> {
  PreparationDto? _prep;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prep = await ref.read(userContentRepositoryProvider).preparation();
      if (mounted) setState(() => _prep = prep);
    } catch (_) {
      // Best-effort : un échec laisse la carte absente. L'accueil ne doit pas
      // afficher une erreur pour un bloc de navigation.
    }
  }

  @override
  Widget build(BuildContext context) {
    final prep = _prep;
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
