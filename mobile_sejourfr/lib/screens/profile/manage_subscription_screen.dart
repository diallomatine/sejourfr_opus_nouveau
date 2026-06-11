import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/billing_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_date.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/screen_header.dart';

/// Écran « Mon pass » (passes one-time, lot 5) — refonte 2026 (cf. `MPass`
/// maquette) : carte gradient premium avec jours restants, détails encartés,
/// inclusions, et prolongation / changement d'offre via le paywall. Pas de
/// résiliation — un pass est payé une fois, il n'y a rien à annuler.
final _subscriptionStatusProvider =
    FutureProvider.autoDispose<SubscriptionStatusResponse>((ref) {
  return ref.watch(billingRepositoryProvider).getSubscriptionStatus();
});

/// Plans actifs — sert à retrouver la durée du pass courant (barre des jours
/// restants) et son libellé commercial depuis le productId du statut.
final _plansProvider =
    FutureProvider.autoDispose<List<PlanPublicResponse>>((ref) {
  return ref.watch(billingRepositoryProvider).listPlans();
});

class ManageSubscriptionScreen extends ConsumerWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(_subscriptionStatusProvider);
    final plans = ref.watch(_plansProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Mon pass',
              sub: 'Paiement unique · sans renouvellement automatique',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: statusAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
                error: (e, _) => _ErrorView(
                  message: ApiClient.toApiException(e).message,
                  onRetry: () => ref.invalidate(_subscriptionStatusProvider),
                ),
                data: (status) => status.isPremium
                    ? _PremiumView(
                        status: status,
                        plan: _planFor(status, plans),
                        onExtend: () =>
                            _openPaywall(context, ref, _targetFor(status)),
                        onChangeOffer: () => _openPaywall(
                            context, ref, PlanModuleTarget.integral),
                      )
                    : _NotPremiumView(
                        onUnlock: () => _openPaywall(context, ref, null),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PlanPublicResponse? _planFor(
      SubscriptionStatusResponse s, List<PlanPublicResponse> plans) {
    final id = s.productId;
    if (id == null) return null;
    for (final p in plans) {
      if (p.code == id || p.appleProductId == id || p.googleProductId == id) {
        return p;
      }
    }
    return null;
  }

  PlanModuleTarget _targetFor(SubscriptionStatusResponse s) =>
      s.moduleAccess == ModuleAccess.integral
          ? PlanModuleTarget.integral
          : PlanModuleTarget.civique;

  /// Ouvre le paywall puis rafraîchit le statut au retour (la date
  /// d'expiration peut avoir bougé après un achat).
  Future<void> _openPaywall(
      BuildContext context, WidgetRef ref, PlanModuleTarget? target) async {
    await showPaywallSheet(context, initialTarget: target);
    ref.invalidate(_subscriptionStatusProvider);
  }
}

// ---------------------------------------------------------------------------
// Vue premium : carte pass + détails + inclusions + actions
// ---------------------------------------------------------------------------

class _PremiumView extends StatelessWidget {
  const _PremiumView({
    required this.status,
    required this.plan,
    required this.onExtend,
    required this.onChangeOffer,
  });

  final SubscriptionStatusResponse status;
  final PlanPublicResponse? plan;
  final VoidCallback onExtend;
  final VoidCallback onChangeOffer;

  bool get _isIntegral => status.moduleAccess == ModuleAccess.integral;

  static const _civiqueFeatures = [
    'Les 5 catégories civiques',
    "Séries d'entraînement illimitées",
    'Examens blancs par thème',
    'Examens blancs complets',
    'Suivi, rapports & recommandations',
  ];

  static const _integralFeatures = [
    'Tout le Pass Civique inclus',
    'Les 5 épreuves du TCF IRN',
    'Compréhension orale & écrite, structure',
    'Expression écrite & orale + analyse IA',
    'Examens blancs complets des deux parcours',
    'Niveau CECRL estimé & plan de révision',
  ];

  @override
  Widget build(BuildContext context) {
    final ends = status.expiresAt;
    final remaining = ends?.difference(DateTime.now()).inDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _PassHeroCard(
          name: _isIntegral ? 'Pass Intégral' : 'Pass Civique',
          accent: AppColors.blue,
          accentDeep: AppColors.blueDark,
          planLabel: plan?.name,
          ends: ends,
          remaining: remaining,
          totalDays: plan?.durationDays,
        ),
        const SizedBox(height: 16),
        if (_isIntegral)
          AppButton(
            label: 'Prolonger mon pass',
            icon: LucideIcons.refreshCw,
            onPressed: onExtend,
          )
        else ...[
          AppButton(
            label: 'Prolonger mon Pass Civique',
            icon: LucideIcons.refreshCw,
            onPressed: onExtend,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Passer au Pass Intégral',
            icon: LucideIcons.zap,
            variant: AppButtonVariant.accent,
            onPressed: onChangeOffer,
          ),
        ],
        const SizedBox(height: 20),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _DetailRow(label: 'Formule', value: plan?.name ?? '—'),
              const Divider(height: 1),
              _DetailRow(
                label: 'Périmètre',
                value: _isIntegral
                    ? 'Accès complet à tout SejourFR'
                    : 'Accès complet au parcours Civique',
              ),
              const Divider(height: 1),
              _DetailRow(label: 'Géré par', value: _sourceLabel(status.source)),
              const Divider(height: 1),
              _DetailRow(
                label: 'Expire le',
                value: ends == null ? '—' : formatLongDate(ends),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle(title: 'Inclus dans votre pass'),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              for (final (i, feature) in (_isIntegral
                      ? _integralFeatures
                      : _civiqueFeatures)
                  .indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check,
                          size: 13, color: AppColors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(feature, style: AppFonts.ui(size: 13.5)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Text(
            "Un pass s'achète une seule fois, sans renouvellement "
            'automatique. Prolongez-le quand vous le souhaitez — les durées '
            'se cumulent.',
            style:
                AppFonts.ui(size: 12.5, color: AppColors.inkSoft, height: 1.55),
          ),
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
}

/// Carte « pass » premium (cf. maquette) : gradient de la famille, liseré
/// tricolore vertical, statut, barre des jours restants.
class _PassHeroCard extends StatelessWidget {
  const _PassHeroCard({
    required this.name,
    required this.accent,
    required this.accentDeep,
    required this.planLabel,
    required this.ends,
    required this.remaining,
    required this.totalDays,
  });

  final String name;
  final Color accent;
  final Color accentDeep;
  final String? planLabel;
  final DateTime? ends;
  final int? remaining;
  final int? totalDays;

  @override
  Widget build(BuildContext context) {
    final double? fraction =
        (remaining != null && totalDays != null && totalDays! > 0)
            ? (remaining! / totalDays!).clamp(0.0, 1.0)
            : null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accentDeep],
        ),
        boxShadow: AppShadows.md,
      ),
      child: Stack(
        children: [
          // Liseré tricolore sur la tranche droite.
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 8,
            child: Column(
              children: [
                Expanded(
                    child: Container(
                        color: AppColors.white.withValues(alpha: 0.85))),
                Expanded(
                    child: Container(
                        color: AppColors.white.withValues(alpha: 0.3))),
                Expanded(child: Container(color: AppColors.red)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SEJOURFR · PASS ACTIF',
                      style: AppFonts.ui(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: AppColors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Actif',
                            style: AppFonts.ui(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(name,
                    style:
                        AppFonts.display(size: 27, color: AppColors.white)),
                const SizedBox(height: 2),
                Text(
                  planLabel != null
                      ? 'Formule $planLabel · payé une fois'
                      : 'Payé une fois, sans abonnement',
                  style: AppFonts.ui(
                    size: 13,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                if (fraction != null) ...[
                  Container(
                    height: 7,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fraction,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.all(
                              Radius.circular(AppRadii.pill)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remaining != null && remaining! >= 0
                          ? '$remaining jour${remaining! > 1 ? 's' : ''} restant${remaining! > 1 ? 's' : ''}'
                          : 'Accès actif',
                      style: AppFonts.ui(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    if (ends != null)
                      Text(
                        'Expire le ${formatLongDate(ends!)}',
                        style: AppFonts.ui(
                          size: 12,
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            label,
            style: AppFonts.ui(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppFonts.ui(size: 13.5, weight: FontWeight.w600),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(LucideIcons.lock,
                size: 26, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          Text('Aucun pass actif', style: AppFonts.display(size: 20)),
          const SizedBox(height: 6),
          Text(
            "Vous êtes sur le plan gratuit. Débloquez l'accès complet avec "
            'un pass à durée fixe, payé une seule fois.',
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: "Découvrir les pass",
            icon: LucideIcons.zap,
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
            const Icon(LucideIcons.cloudOff, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.ui(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.outline,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
