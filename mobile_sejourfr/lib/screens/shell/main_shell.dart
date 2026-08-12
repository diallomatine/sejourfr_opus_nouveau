import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Shell de la refonte 2026 : bottom nav 5 onglets
/// Accueil · Réviser · Examens · Plan · Profil (cf. `MTabBar` maquette).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;

    final currentIndex = switch (loc) {
      AppRoutes.home => 0,
      AppRoutes.reviser => 1,
      AppRoutes.examens => 2,
      AppRoutes.plan => 3,
      AppRoutes.profile => 4,
      _ => -1,
    };

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

/// Exposé pour garantir par test que l'ancien écran Progrès reste secondaire
/// et que le quatrième onglet ouvre bien le plan serveur.
const mainShellDestinations = <MainShellDestination>[
  (icon: LucideIcons.house, label: 'Accueil', route: AppRoutes.home),
  (icon: LucideIcons.layoutGrid, label: 'Réviser', route: AppRoutes.reviser),
  (icon: LucideIcons.target, label: 'Examens', route: AppRoutes.examens),
  (icon: LucideIcons.map, label: 'Plan', route: AppRoutes.plan),
  (
    icon: LucideIcons.graduationCap,
    label: 'Profil',
    route: AppRoutes.profile,
  ),
];
