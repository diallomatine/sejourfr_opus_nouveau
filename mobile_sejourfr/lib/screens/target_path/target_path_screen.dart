import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/eyebrow.dart';

/// Écran d'onboarding (ou édition depuis le profil) du parcours administratif :
/// CSP, CR ou NAT. Une fois rempli, l'utilisateur n'a plus à choisir le niveau
/// à chaque entraînement ou examen blanc.
class TargetPathScreen extends ConsumerStatefulWidget {
  const TargetPathScreen({super.key});

  @override
  ConsumerState<TargetPathScreen> createState() => _TargetPathScreenState();
}

class _TargetPathScreenState extends ConsumerState<TargetPathScreen> {
  TargetProcedure? _selected;
  bool _saving = false;
  String? _error;

  /// Route d'origine, lue dans le query param `?from=...`. Vide si l'écran
  /// est ouvert en mode onboarding (juste après création de compte).
  String? _fromRoute;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated) {
      _selected = auth.user.targetProcedure;
    }
  }

  Future<void> _submit() async {
    final choice = _selected;
    if (choice == null) return;
    final from = _fromRoute;
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(userContentRepositoryProvider).updateTargetPath(choice);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      // Navigation explicite via `go` : plus fiable que `pop` après un
      // refresh du state d'auth (qui peut perturber la back stack).
      context.go(from ?? AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiClient.toApiException(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Capture une seule fois la route d'origine passée par le call-site.
    _fromRoute ??= GoRouterState.of(context).uri.queryParameters['from'];
    final canPop = _fromRoute != null;

    return Scaffold(
      appBar: canPop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                onPressed: () => context.go(_fromRoute!),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            const Eyebrow('§ Onboarding — Parcours'),
            const SizedBox(height: 8),
            Text(
              'Quelle démarche préparez-vous ?',
              style: AppFonts.display(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Nous adapterons votre entraînement en fonction de votre objectif. '
              'Vous pourrez toujours modifier ce choix depuis votre profil.',
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            for (final p in TargetProcedure.values) ...[
              _PathCard(
                procedure: p,
                selected: _selected == p,
                onTap: () => setState(() => _selected = p),
              ),
              const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  border:
                      Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: AppFonts.ui(color: AppColors.red, size: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Continuer',
              onPressed: _selected == null || _saving ? null : _submit,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.procedure,
    required this.selected,
    required this.onTap,
  });

  final TargetProcedure procedure;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: selected ? AppColors.blue : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
      color: selected ? AppColors.blueSoft : AppColors.white,
      child: Row(
        children: [
          AppTag(label: procedure.wire, tone: TagTone.blue),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  procedure.fullLabel,
                  style: AppFonts.ui(
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Niveau TCF requis : ${procedure.tcfLevel}',
                  style: AppFonts.ui(
                    size: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (selected)
            const Icon(LucideIcons.circleCheck, color: AppColors.blue, size: 24)
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line2, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}
