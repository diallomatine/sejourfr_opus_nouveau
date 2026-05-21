import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;

    final currentIndex = switch (loc) {
      AppRoutes.home => 0,
      AppRoutes.civique => 1,
      AppRoutes.tcf => 2,
      AppRoutes.progress => 3,
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

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil', route: AppRoutes.home),
    (
      icon: Icons.account_balance_outlined,
      activeIcon: Icons.account_balance,
      label: 'Civique',
      route: AppRoutes.civique,
    ),
    (icon: Icons.language_outlined, activeIcon: Icons.language, label: 'TCF', route: AppRoutes.tcf),
    (icon: Icons.insights_outlined, activeIcon: Icons.insights, label: 'Progression', route: AppRoutes.progress),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', route: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 22,
                        color: selected ? AppColors.blue : AppColors.muted2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppFonts.jakarta(
                          size: 10.5,
                          color: selected ? AppColors.blue : AppColors.muted2,
                          weight: selected ? FontWeight.w700 : FontWeight.w500,
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
    );
  }
}
