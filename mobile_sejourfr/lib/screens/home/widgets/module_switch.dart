import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/selected_module.dart';

class ModuleSwitch extends ConsumerWidget {
  const ModuleSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(selectedModuleProvider);
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
            active: current == AppModule.tcf,
            onTap: () => ref.read(selectedModuleProvider.notifier).state =
                AppModule.tcf,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: Text(
            label,
            style: AppFonts.jakarta(
              size: 13,
              weight: FontWeight.w700,
              color: active ? AppColors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
