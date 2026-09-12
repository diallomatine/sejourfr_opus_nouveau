import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Shell de la refonte 2026 : bottom nav 5 onglets
/// **Accueil · Plan · Réviser · Examens · Profil**.
///
/// ⚠️ **Ordre changé le 2026-09-12** (demande du propriétaire) : le Plan passe
/// en 2ᵉ, juste après l'Accueil, parce que c'est là que l'Accueil renvoie —
/// « Continuer mon plan », « Voir mon Plan » et les deux lignes de « Vos
/// parcours » y mènent toutes. Il était en 4ᵉ, après deux onglets de
/// catalogue.
///
/// ⚠️ **Mobile seulement pour l'instant** (demande explicite) : la barre
/// latérale du web garde son ordre — `Parcours` (TCF, civique, examens) puis
/// `Suivi` (Plan, résultats, recommandations). Écart de parité **assumé**, pas
/// un oubli.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;

    // 🛑 **Le rang se lit sur la liste**, il ne se recopie pas : un `switch`
    // route → index vivait à côté de [mainShellDestinations] et devait être
    // tenu à jour en même temps qu'elle — réordonner la barre y aurait
    // surligné le mauvais onglet en silence.
    final currentIndex =
        mainShellDestinations.indexWhere((item) => item.route == loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(currentIndex: currentIndex),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(mainShellDestinations.length, (i) {
                  final item = mainShellDestinations[i];
                  final selected = i == currentIndex;
                  final color = selected ? AppColors.blue : AppColors.inkFaint;
                  return Expanded(
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 23, color: color),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: AppFonts.ui(
                              size: 10.5,
                              color: color,
                              weight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef MainShellDestination = ({
  IconData icon,
  String label,
  String route,
});

/// Les cinq onglets, **dans l'ordre d'affichage**. C'est la seule autorité de
/// cet ordre : le surlignage en dérive ([MainShell.build]).
///
/// Exposé pour garantir par test que l'ancien écran Progrès reste secondaire et
/// que le Plan a bien son onglet.
const mainShellDestinations = <MainShellDestination>[
  (icon: LucideIcons.house, label: 'Accueil', route: AppRoutes.home),
  (icon: LucideIcons.map, label: 'Plan', route: AppRoutes.plan),
  (icon: LucideIcons.layoutGrid, label: 'Réviser', route: AppRoutes.reviser),
  (icon: LucideIcons.target, label: 'Examens', route: AppRoutes.examens),
  (
    icon: LucideIcons.graduationCap,
    label: 'Profil',
    route: AppRoutes.profile,
  ),
];
