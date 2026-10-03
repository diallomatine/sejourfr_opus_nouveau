import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/router/shell_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../module/module_labels.dart';

/// **Le shell de Navigation v2** (2026-10-03) : bottom nav à 4 onglets
/// **Accueil · TCF · Civique · Profil**, une pile par onglet
/// (`StatefulShellRoute.indexedStack`).
///
/// - Onglet actif en **bleu**, sauf l'onglet **Civique**, actif en **rouge** —
///   les couleurs de module ([AppColors.module]).
/// - Changer d'onglet conserve la pile, le segment et le défilement de chacun.
/// - **Retour Android** : la pile de l'onglet dépile d'abord ; à sa racine,
///   un onglet ≠ Accueil ramène à l'Accueil. Un écran seul dans sa pile
///   (atteint par `go`, p. ex. une Progression ouverte depuis l'Accueil)
///   ramène à l'écran de son module, sur son dernier segment.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _ouvrirOnglet(BuildContext context, WidgetRef ref, ShellBranch branche) {
    if (branche.index != navigationShell.currentIndex) {
      navigationShell.goBranch(branche.index);
      return;
    }
    // Onglet déjà actif : on remonte à sa racine, segment conservé.
    final racine = _racine(ref, branche);
    if (racine == null) {
      navigationShell.goBranch(branche.index, initialLocation: true);
    } else {
      GoRouter.of(context).go(racine);
    }
  }

  /// La racine d'un onglet de module, sur son dernier segment ; `null` pour
  /// l'Accueil et le Profil, dont la racine est l'emplacement initial.
  String? _racine(WidgetRef ref, ShellBranch branche) => switch (branche) {
        ShellBranch.tcf => racineDuModule(ref, civique: false),
        ShellBranch.civique => racineDuModule(ref, civique: true),
        ShellBranch.accueil || ShellBranch.profil => null,
      };

  void _retour(BuildContext context, WidgetRef ref) {
    final branche = ShellBranch.values[navigationShell.currentIndex];
    if (branche == ShellBranch.accueil) return;
    final ici = GoRouter.of(context).state.uri.path;
    final racine = _racine(ref, branche);
    final aLaRacine = racine == null ||
        ModuleSegment.values
            .any((s) => s.path(civique: branche == ShellBranch.civique) == ici);
    if (aLaRacine) {
      navigationShell.goBranch(ShellBranch.accueil.index);
    } else {
      GoRouter.of(context).go(racine);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    return PopScope(
      canPop: index == ShellBranch.accueil.index,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _retour(context, ref);
      },
      child: ShellBrancheCourante(
        index: index,
        child: Scaffold(
          body: navigationShell,
          bottomNavigationBar: _BottomNav(
            currentIndex: index,
            onTap: (branche) => _ouvrirOnglet(context, ref, branche),
          ),
        ),
      ),
    );
  }
}

/// **L'onglet affiché**, pour un écran de branche qui doit savoir quand il
/// redevient visible (l'`IndexedStack` le garde monté hors champ) — p. ex.
/// l'écran de module, qui trace `PLAN_OPENED` à chaque affichage du Plan.
class ShellBrancheCourante extends InheritedWidget {
  const ShellBrancheCourante({
    super.key,
    required this.index,
    required super.child,
  });

  final int index;

  static int? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellBrancheCourante>()?.index;

  @override
  bool updateShouldNotify(ShellBrancheCourante oldWidget) =>
      index != oldWidget.index;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<ShellBranch> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.97),
            border: const Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (final item in mainShellDestinations)
                    Expanded(child: _tab(item)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(MainShellDestination item) {
    final selected = item.branche.index == currentIndex;
    final color = selected
        ? (item.branche == ShellBranch.civique
            ? AppColors.moduleCivique
            : AppColors.moduleTcf)
        : AppColors.inkFaint;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onTap(item.branche),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppFonts.ui(
                size: 11,
                color: color,
                weight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef MainShellDestination = ({
  IconData icon,
  String label,
  ShellBranch branche,
  String route,
});

/// Les quatre onglets, **dans l'ordre d'affichage** — la seule autorité de cet
/// ordre (il suit [ShellBranch]). [route] est l'emplacement initial de
/// l'onglet. Pictogrammes Lucide équivalents à la maquette (trait).
const mainShellDestinations = <MainShellDestination>[
  (
    icon: LucideIcons.house,
    label: kTabAccueil,
    branche: ShellBranch.accueil,
    route: AppRoutes.home,
  ),
  (
    icon: LucideIcons.map,
    label: kTabTcf,
    branche: ShellBranch.tcf,
    route: AppRoutes.tcfPlan,
  ),
  (
    icon: LucideIcons.shieldCheck,
    label: kTabCivique,
    branche: ShellBranch.civique,
    route: AppRoutes.civiquePlan,
  ),
  (
    icon: LucideIcons.user,
    label: kTabProfil,
    branche: ShellBranch.profil,
    route: AppRoutes.profile,
  ),
];
