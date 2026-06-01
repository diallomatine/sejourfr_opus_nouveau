import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/billing_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_date.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/paywall_sheet.dart';

/// Écran « Mon accès » (passes one-time, lot 5) : plan courant + date
/// d'expiration, avec prolongation et changement d'offre. Pas de résiliation —
/// un pass est payé une fois, il n'y a rien à annuler.
final _subscriptionStatusProvider =
    FutureProvider.autoDispose<SubscriptionStatusResponse>((ref) {
  return ref.watch(billingRepositoryProvider).getSubscriptionStatus();
});

class ManageSubscriptionScreen extends ConsumerWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(_subscriptionStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.ink, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mon accès',
          style: AppFonts.jakarta(
              size: 16, weight: FontWeight.w800, color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: ApiClient.toApiException(e).message,
            onRetry: () => ref.invalidate(_subscriptionStatusProvider),
          ),
          data: (status) => status.isPremium
              ? _PremiumView(
                  status: status,
                  onExtend: () =>
                      _openPaywall(context, ref, _targetFor(status)),
                  onChangeOffer: () =>
                      _openPaywall(context, ref, PlanModuleTarget.integral),
                )
              : _NotPremiumView(
                  onUnlock: () => _openPaywall(context, ref, null),
                ),
        ),
      ),
    );
  }

  PlanModuleTarget _targetFor(SubscriptionStatusResponse s) =>
      s.moduleAccess == ModuleAccess.integral
          ? PlanModuleTarget.integral
          : PlanModuleTarget.civique;

  /// Ouvre le paywall puis rafraîchit le statut au retour (la date d'expiration
  /// peut avoir bougé après un achat).
  Future<void> _openPaywall(
      BuildContext context, WidgetRef ref, PlanModuleTarget? target) async {
    await showPaywallSheet(context, initialTarget: target);
    ref.invalidate(_subscriptionStatusProvider);
  }
}

// ---------------------------------------------------------------------------
// Vue premium : plan + date + actions
// ---------------------------------------------------------------------------

class _PremiumView extends StatelessWidget {
  const _PremiumView({
    required this.status,
    required this.onExtend,
    required this.onChangeOffer,
  });

  final SubscriptionStatusResponse status;
  final VoidCallback onExtend;
  final VoidCallback onChangeOffer;

  @override
  Widget build(BuildContext context) {
    final isIntegral = status.moduleAccess == ModuleAccess.integral;
    final ends = status.expiresAt;
    final remaining = ends?.difference(DateTime.now()).inDays;
    final expiresSoon = remaining != null && remaining <= 14;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        _Hero(
          planLabel: isIntegral ? 'Intégral · Civique + TCF' : 'Civique',
          ends: ends,
          remaining: remaining,
          expiresSoon: expiresSoon,
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '§ DÉTAILS',
                style: AppFonts.mono(
                    size: 9.5,
                    color: AppColors.muted,
                    letterSpacing: 1.8,
                    weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _Row(
                label: 'Géré par',
                value: _sourceLabel(status.source),
                icon: _sourceIcon(status.source),
              ),
              _Row(
                label: 'Accès jusqu\'au',
                value: ends == null ? '—' : formatLongDate(ends),
                icon: Icons.event_rounded,
              ),
              if (status.productId != null)
                _Row(
                  label: 'Formule',
                  value: status.productId!,
                  icon: Icons.confirmation_number_outlined,
                  monospace: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Prolonger mon accès',
          icon: Icons.add_rounded,
          onPressed: onExtend,
        ),
        if (!isIntegral) ...[
          const SizedBox(height: 10),
          AppButton(
            label: 'Passer à l\'Intégral',
            variant: AppButtonVariant.secondary,
            icon: Icons.auto_awesome_rounded,
            onPressed: onChangeOffer,
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Achat unique, sans abonnement. Prolongez quand '
          'vous le souhaitez, les durées se cumulent.',
          textAlign: TextAlign.center,
          style:
              AppFonts.jakarta(size: 12, color: AppColors.muted, height: 1.5),
        ),
      ],
    );
  }

  static String _sourceLabel(SubscriptionSource? s) => switch (s) {
        SubscriptionSource.stripe => 'Carte bancaire (Stripe)',
        SubscriptionSource.apple => 'App Store (Apple)',
        SubscriptionSource.google => 'Google Play',
        _ => '—',
      };

  static IconData _sourceIcon(SubscriptionSource? s) => switch (s) {
        SubscriptionSource.stripe => Icons.credit_card_rounded,
        SubscriptionSource.apple => Icons.apple_rounded,
        SubscriptionSource.google => Icons.shop_rounded,
        _ => Icons.help_outline_rounded,
      };
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.planLabel,
    required this.ends,
    required this.remaining,
    required this.expiresSoon,
  });

  final String planLabel;
  final DateTime? ends;
  final int? remaining;
  final bool expiresSoon;

  @override
  Widget build(BuildContext context) {
    final accent = expiresSoon ? AppColors.amber : AppColors.blue;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: expiresSoon
              ? const [AppColors.amber, AppColors.redDark]
              : const [AppColors.blue, AppColors.blueDark],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'MON ACCÈS',
                style: AppFonts.mono(
                    size: 10,
                    color: AppColors.white.withValues(alpha: 0.78),
                    letterSpacing: 1.8,
                    weight: FontWeight.w700),
              ),
              const Spacer(),
              AppTag(
                label: expiresSoon ? 'Bientôt terminé' : 'Actif',
                tone: expiresSoon ? TagTone.amber : TagTone.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            planLabel,
            style: AppFonts.fraunces(
                size: 26, weight: FontWeight.w600, color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            ends == null
                ? 'Accès actif.'
                : 'Accès jusqu\'au ${formatLongDate(ends!)}'
                    '${remaining != null && remaining! >= 0 ? ' · encore $remaining jour${remaining! > 1 ? 's' : ''}' : ''}',
            style: AppFonts.jakarta(
                size: 13, color: AppColors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.icon,
    this.monospace = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppFonts.jakarta(size: 13, color: AppColors.muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: monospace
                  ? AppFonts.mono(
                      size: 11.5, color: AppColors.ink, weight: FontWeight.w600)
                  : AppFonts.jakarta(
                      size: 13.5,
                      color: AppColors.ink,
                      weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// États dégradés
// ---------------------------------------------------------------------------

class _NotPremiumView extends StatelessWidget {
  const _NotPremiumView({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 36, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'Aucun accès actif',
            style: AppFonts.fraunces(size: 20, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Vous êtes sur le plan gratuit. Débloquez l\'accès complet avec un '
            'pass à durée fixe, sans abonnement.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(size: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Débloquer l\'accès',
            icon: Icons.lock_open_rounded,
            fullWidth: false,
            onPressed: onUnlock,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.jakarta(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.secondary,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
