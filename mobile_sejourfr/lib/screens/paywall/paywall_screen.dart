import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/billing/billing_controller.dart';
import '../../core/billing/iap_service.dart';
import '../../core/models/billing_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

/// Écran paywall plein écran. Affiche un toggle mensuel/trimestriel/annuel et
/// deux cards Civique + Intégral avec les prix réels du store (devise locale).
///
/// Conforme aux guidelines Apple/Google : le paiement se fait par IAP natif,
/// pas par redirection externe. Bouton « Restaurer mes achats » obligatoire
/// pour passage en review Apple.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.initialTarget});

  /// Module pré-sélectionné (utilisé quand un paywall pop sur un module TCF
  /// → on focus sur Intégral). Null = on montre les deux cards.
  final PlanModuleTarget? initialTarget;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PlanPeriodicity _periodicity = PlanPeriodicity.quarterly;

  @override
  void initState() {
    super.initState();
    // Premier chargement async — les prix arrivent du store.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingControllerProvider);

    // Ferme automatiquement le paywall quand on devient Premium.
    ref.listen<BillingState>(billingControllerProvider, (prev, next) {
      final justWentPremium = next.lastVerification?.isPremium == true &&
          (prev?.lastVerification?.isPremium != true);
      if (justWentPremium && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Abonnement activé. Bienvenue !',
              style: AppFonts.jakarta(color: AppColors.white, size: 13),
            ),
          ),
        );
        Navigator.of(context).maybePop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          TextButton(
            onPressed: state.purchaseInProgress
                ? null
                : () => ref.read(billingControllerProvider.notifier).restorePurchases(),
            child: Text(
              'Restaurer',
              style: AppFonts.jakarta(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BillingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Abonnement',
            style: AppFonts.mono(size: 11, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez votre formule',
            textAlign: TextAlign.center,
            style: AppFonts.fraunces(size: 28, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            'Mensuel, trimestriel ou annuel — annulable à tout moment depuis '
            'les Réglages de votre appareil.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),

          _PeriodicityToggle(
            value: _periodicity,
            onChanged: (v) => setState(() => _periodicity = v),
          ),
          const SizedBox(height: 22),

          if (state.error != null) ...[
            _ErrorBanner(message: state.error!),
            const SizedBox(height: 16),
          ],

          ..._buildPlanCards(state),

          const SizedBox(height: 24),
          _TrustRow(),
          const SizedBox(height: 14),
          _LegalLinks(),
        ],
      ),
    );
  }

  List<Widget> _buildPlanCards(BillingState state) {
    final modulesToShow = widget.initialTarget != null
        ? <PlanModuleTarget>{widget.initialTarget!, PlanModuleTarget.integral}
        : PlanModuleTarget.values.toSet();

    final cards = <Widget>[];
    for (final module in modulesToShow) {
      final product = _findProduct(state.products, module, _periodicity);
      cards.add(_PlanCard(
        module: module,
        product: product,
        periodicity: _periodicity,
        disabled: state.purchaseInProgress,
        onPurchase: product == null
            ? null
            : () => ref
                .read(billingControllerProvider.notifier)
                .startPurchase(product),
      ));
      cards.add(const SizedBox(height: 14));
    }
    if (cards.isNotEmpty) cards.removeLast();
    return cards;
  }

  IapProduct? _findProduct(
    List<IapProduct> products,
    PlanModuleTarget module,
    PlanPeriodicity periodicity,
  ) {
    for (final p in products) {
      if (p.module == module && p.periodicity == periodicity) return p;
    }
    return null;
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _PeriodicityToggle extends StatelessWidget {
  const _PeriodicityToggle({required this.value, required this.onChanged});
  final PlanPeriodicity value;
  final ValueChanged<PlanPeriodicity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.line2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: PlanPeriodicity.values.map((p) {
          final active = p == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  p.label,
                  style: AppFonts.jakarta(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: active ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.module,
    required this.product,
    required this.periodicity,
    required this.disabled,
    required this.onPurchase,
  });

  final PlanModuleTarget module;
  final IapProduct? product;
  final PlanPeriodicity periodicity;
  final bool disabled;
  final VoidCallback? onPurchase;

  Color get _accent => module == PlanModuleTarget.civique
      ? AppColors.blue
      : AppColors.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accent.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  module == PlanModuleTarget.civique
                      ? 'CSP · CR · NAT'
                      : 'CIVIQUE + TCF',
                  style: AppFonts.mono(size: 10, color: AppColors.white),
                ),
              ),
              if (module == PlanModuleTarget.integral)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'COMPLET',
                    style: AppFonts.mono(size: 9.5, color: AppColors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            module.label,
            style: AppFonts.fraunces(size: 24, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            module == PlanModuleTarget.civique
                ? 'Accès complet au module civique pour préparer votre démarche.'
                : 'Civique + TCF IRN avec EE/EO évalués par IA.',
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _PriceBlock(product: product, periodicity: periodicity),
          const SizedBox(height: 16),
          _FeatureList(module: module),
          const SizedBox(height: 18),
          AppButton(
            label: product == null
                ? 'Indisponible sur cette plateforme'
                : 'Souscrire ${module.label}',
            onPressed: (disabled || onPurchase == null) ? null : onPurchase,
            variant: module == PlanModuleTarget.civique
                ? AppButtonVariant.primary
                : AppButtonVariant.danger,
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product, required this.periodicity});
  final IapProduct? product;
  final PlanPeriodicity periodicity;

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Text(
        'Produit non encore configuré.',
        style: AppFonts.jakarta(size: 13, color: AppColors.muted),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          product!.localizedPrice,
          style: AppFonts.fraunces(size: 32, weight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            periodicity.suffix,
            style: AppFonts.mono(size: 11, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.module});
  final PlanModuleTarget module;

  @override
  Widget build(BuildContext context) {
    final features = module == PlanModuleTarget.civique
        ? const [
            'Banque complète civique',
            'Examens blancs civiques illimités',
            'Entraînement par thème',
            'Révision des erreurs et favoris',
          ]
        : const [
            'Tout le Civique inclus',
            'Module TCF complet (CO + CE + Structure)',
            'Expression écrite + orale évaluée par IA',
            'Diagnostic CECRL (A2 / B1 / B2)',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 16, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: AppFonts.jakarta(
                          size: 13.5,
                          color: AppColors.ink2,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _TrustRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_rounded, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          'Paiement sécurisé via App Store / Google Play',
          style: AppFonts.jakarta(size: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _LegalLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'L\'abonnement est géré par le store. Gérez le renouvellement et '
      'annulez à tout moment dans Réglages > Apple ID / Google Play.',
      textAlign: TextAlign.center,
      style: AppFonts.jakarta(size: 11, color: AppColors.muted, height: 1.5),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppFonts.jakarta(
                size: 12.5,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
