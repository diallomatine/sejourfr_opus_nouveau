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
///
/// [civique] borne la carte au parcours affiché — l'Accueil est scopé depuis le
/// 2026-09-12, et l'autre module y est à un appui de bascule. Sans valeur, les
/// deux lignes sont rendues : c'est le comportement d'origine, conservé pour
/// tout écran qui veut la vue d'ensemble. Miroir de la prop `module` du web.
class PreparationCard extends ConsumerWidget {
  const PreparationCard({super.key, this.civique, this.titre = true});

  /// `true` = civique seul, `false` = TCF seul, `null` = les deux.
  final bool? civique;

  /// `false` quand l'hôte porte déjà le titre de section (l'Accueil, dont les
  /// sections viennent du kit).
  final bool titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Best-effort : chargement ou échec ⇒ la carte est simplement absente.
    // L'accueil ne doit pas afficher une erreur pour un bloc de navigation.
    final prep = ref.watch(preparationProvider).valueOrNull;
    if (prep == null) return const SizedBox.shrink();

    final tcf = civique != true;
    final civ = civique != false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titre) ...[
          Text(kPreparationTitle,
              style: AppFonts.display(size: 20, color: AppColors.ink)),
          const SizedBox(height: 10),
        ],
        if (tcf) _ModuleLigne(label: kTcfLabel, action: tcfAction(prep.tcf)),
        if (tcf && civ) const SizedBox(height: 10),
        if (civ)
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
