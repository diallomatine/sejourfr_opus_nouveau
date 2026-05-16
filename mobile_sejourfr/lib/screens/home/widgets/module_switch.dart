import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/selected_module.dart';
import '../../../core/widgets/tcf_paywall.dart';

class ModuleSwitch extends ConsumerWidget {
  const ModuleSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(selectedModuleProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    // TCF est verrouillé si l'utilisateur n'a pas l'accès Intégral.
    // Les admins ont accès à tout.
    final tcfLocked = user != null && !user.canAccessModule(AppModule.tcf);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Civique',
            active: current == AppModule.civique,
            onTap: () => ref.read(selectedModuleProvider.notifier).state =
                AppModule.civique,
          ),
          _Tab(
            label: 'TCF',
            active: current == AppModule.tcf && !tcfLocked,
            locked: tcfLocked,
            onTap: () {
              if (tcfLocked) {
                showTcfPaywallSheet(context);
              } else {
                ref.read(selectedModuleProvider.notifier).state =
                    AppModule.tcf;
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = active
        ? AppColors.white
        : (locked ? AppColors.muted2 : AppColors.muted);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppFonts.jakarta(
                  size: 13,
                  weight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: textColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
