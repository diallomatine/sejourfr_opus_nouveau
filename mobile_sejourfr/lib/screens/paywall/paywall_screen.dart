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

    // Ferme automatiquement le paywall après une vérif d'achat réussie qui
    // ouvre l'accès. On se base sur l'ARRIVÉE d'une nouvelle vérification
    // (instance de lastVerification différente) et non sur une transition
    // non-premium→premium : le BillingController n'est pas autoDispose, donc
    // lastVerification persiste entre deux ouvertures du paywall. Une
    // prolongation (déjà premium), un 2e achat, ou une transaction rejouée à
    // l'ouverture ne produisaient aucune transition → l'écran ne se fermait
    // jamais (spinner qui s'arrête sans fermeture).
    ref.listen<BillingState>(billingControllerProvider, (prev, next) {
      final verified = next.lastVerification;
      final isFreshVerification =
          verified != null && !identical(prev?.lastVerification, verified);
      if (isFreshVerification && verified.isPremium && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            content: Text(
              _welcomeMessage(verified),
              style: AppFonts.jakarta(color: AppColors.white, size: 13),
            ),
          ),
        );
        // rootNavigator: true — le paywall est poussé sur le navigator racine
        // par showPaywallSheet ; on pop le MÊME pour revenir à la page d'où
        // l'utilisateur venait (ex. l'examen qui avait déclenché le paywall).
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });

    return PopScope(
      // Pendant la validation d'un achat (spinner), on bloque toute fermeture
      // (geste retour / bouton système) : aucune interaction tant que le
      // backend n'a pas confirmé. La fermeture se fait automatiquement au
      // succès (ref.listen ci-dessus) ou redevient possible en cas d'erreur.
      canPop: !state.purchaseInProgress,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.ink),
            onPressed: state.purchaseInProgress
                ? null
                : () => Navigator.of(context, rootNavigator: true).maybePop(),
          ),
          actions: [
            TextButton(
              onPressed: state.purchaseInProgress
                  ? null
                  : () => ref
                      .read(billingControllerProvider.notifier)
                      .restorePurchases(),
              child: (state.purchaseInProgress && state.purchasingSku == null)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.muted),
                      ),
                    )
                  : Text(
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
      ),
    );
  }

  /// Message de confirmation post-achat, adapté au module débloqué et à la
  /// nature (pass one-time vs abonnement).
  String _welcomeMessage(SubscriptionStatusResponse status) {
    final module = switch (status.moduleAccess) {
      ModuleAccess.integral => 'Intégral',
      ModuleAccess.civique => 'Civique',
      _ => null,
    };
    final prefix = status.oneTime ? 'Accès activé' : 'Abonnement activé';
    return module != null
        ? '$prefix · Bienvenue dans $module !'
        : '$prefix. Bienvenue !';
  }

  Widget _buildContent(BuildContext context, BillingState state) {
    // Mode passes one-time (lot 5) : pas de toggle de périodicité, on rend une
    // carte par module avec ses passes (durée + prix). Le mode abonnement
    // (toggle + 2 cartes) reste disponible si le backend renvoie des plans
    // récurrents.
    final oneTime =
        state.products.isNotEmpty && state.products.every((p) => p.isOneTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            oneTime ? 'Accès' : 'Abonnement',
            style: AppFonts.mono(size: 11, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            oneTime ? 'Débloquez votre accès' : 'Choisissez votre formule',
            textAlign: TextAlign.center,
            style: AppFonts.fraunces(size: 28, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            oneTime
                ? 'Paiement unique, sans abonnement ni reconduction. '
                    'Vous payez une fois et accédez à l\'app pour toute la durée choisie.'
                : 'Mensuel, trimestriel ou annuel — annulable à tout moment depuis '
                    'les Réglages de votre appareil.',
            textAlign: TextAlign.center,
            style: AppFonts.jakarta(
              size: 13,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          if (!oneTime) ...[
            _PeriodicityToggle(
              value: _periodicity,
              onChanged: (v) => setState(() => _periodicity = v),
            ),
            const SizedBox(height: 22),
          ],
          if (state.error != null) ...[
            _ErrorBanner(message: state.error!),
            const SizedBox(height: 16),
          ],
          ...(oneTime ? _buildOneTimeCards(state) : _buildPlanCards(state)),
          const SizedBox(height: 24),
          _TrustRow(),
          const SizedBox(height: 14),
          _LegalLinks(oneTime: oneTime),
        ],
      ),
    );
  }

  /// Cartes des passes one-time, groupées par module (Civique : 2 passes,
  /// Intégral : 3). Chaque pass = durée + prix + bouton d'achat.
  List<Widget> _buildOneTimeCards(BillingState state) {
    final modulesToShow = widget.initialTarget != null
        ? <PlanModuleTarget>{widget.initialTarget!, PlanModuleTarget.integral}
        : PlanModuleTarget.values.toSet();

    final cards = <Widget>[];
    for (final module in modulesToShow) {
      final passes = state.products.where((p) => p.module == module).toList()
        ..sort((a, b) => a.plan.durationDays.compareTo(b.plan.durationDays));
      if (passes.isEmpty) continue;
      cards.add(_OneTimeModuleCard(
        module: module,
        passes: passes,
        disabled: state.purchaseInProgress || state.actionBlocked,
        purchasingSku: state.purchasingSku,
        onPurchase: (p) =>
            ref.read(billingControllerProvider.notifier).startPurchase(p),
      ));
      cards.add(const SizedBox(height: 14));
    }
    if (cards.isNotEmpty) cards.removeLast();
    return cards;
  }

  List<Widget> _buildPlanCards(BillingState state) {
    final modulesToShow = widget.initialTarget != null
        ? <PlanModuleTarget>{widget.initialTarget!, PlanModuleTarget.integral}
        : PlanModuleTarget.values.toSet();

    final cards = <Widget>[];
    for (final module in modulesToShow) {
      final product = _findProduct(state.products, module, _periodicity);
      final loading = state.purchaseInProgress &&
          product != null &&
          state.purchasingSku == product.plan.code;
      cards.add(_PlanCard(
        module: module,
        product: product,
        periodicity: _periodicity,
        disabled: state.purchaseInProgress || state.actionBlocked,
        loading: loading,
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
    required this.loading,
    required this.onPurchase,
  });

  final PlanModuleTarget module;
  final IapProduct? product;
  final PlanPeriodicity periodicity;
  final bool disabled;
  final bool loading;
  final VoidCallback? onPurchase;

  Color get _accent =>
      module == PlanModuleTarget.civique ? AppColors.blue : AppColors.red;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            isLoading: loading,
            variant: module == PlanModuleTarget.civique
                ? AppButtonVariant.primary
                : AppButtonVariant.danger,
          ),
        ],
      ),
    );
  }
}

/// Carte d'un module en mode passes one-time : en-tête + features + la liste
/// des passes (durée + prix), chacun achetable. Réutilise [_FeatureList].
class _OneTimeModuleCard extends StatelessWidget {
  const _OneTimeModuleCard({
    required this.module,
    required this.passes,
    required this.disabled,
    required this.purchasingSku,
    required this.onPurchase,
  });

  final PlanModuleTarget module;
  final List<IapProduct> passes;
  final bool disabled;
  final String? purchasingSku;
  final void Function(IapProduct) onPurchase;

  Color get _accent =>
      module == PlanModuleTarget.civique ? AppColors.blue : AppColors.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.25), width: 1.5),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('COMPLET',
                      style: AppFonts.mono(size: 9.5, color: AppColors.white)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(module.label,
              style: AppFonts.fraunces(size: 24, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            module == PlanModuleTarget.civique
                ? 'Accès complet au module civique pour préparer votre démarche.'
                : 'Civique + TCF IRN avec EE/EO évalués par IA.',
            style:
                AppFonts.jakarta(size: 13, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          _FeatureList(module: module),
          const SizedBox(height: 18),
          for (final pass in passes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PassRow(
                pass: pass,
                accent: _accent,
                disabled: disabled,
                loading: purchasingSku == pass.plan.code,
                onTap: () => onPurchase(pass),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ligne d'un pass achetable : durée (« 3 mois ») + prix store + flèche.
/// Pass mis en avant comme « le plus populaire » (cohérent web + mobile).
const String _popularPassCode = 'INTEGRAL_PASS_3M';

class _PassRow extends StatelessWidget {
  const _PassRow({
    required this.pass,
    required this.accent,
    required this.disabled,
    required this.loading,
    required this.onTap,
  });

  final IapProduct pass;
  final Color accent;
  final bool disabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final popular = pass.plan.code == _popularPassCode;
    // Le pass populaire est mis en avant en rouge (CTA/urgence assumé ici).
    final c = popular ? AppColors.red : accent;
    return Material(
      color: c.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: c.withValues(alpha: popular ? 0.6 : 0.25),
              width: popular ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (popular)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'LE PLUS POPULAIRE',
                            style: AppFonts.mono(
                              size: 8.5,
                              color: AppColors.white,
                              letterSpacing: 1.0,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      pass.durationLabel,
                      style:
                          AppFonts.jakarta(size: 15, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Text(
                pass.localizedPrice,
                style: AppFonts.fraunces(
                    size: 20, weight: FontWeight.w700, color: c),
              ),
              const SizedBox(width: 10),
              loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(c),
                      ),
                    )
                  : Icon(Icons.arrow_forward_rounded, size: 18, color: c),
            ],
          ),
        ),
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
    // Pour Civique, on montre explicitement ce qui n'est PAS couvert (le TCF
    // IRN) afin de lever toute ambiguïté avec l'offre Intégral. Vide pour
    // Intégral, qui couvre tout.
    final excluded = module == PlanModuleTarget.civique
        ? const [
            'Module TCF IRN (CO, CE, Structure)',
            'Expression écrite + orale évaluée par IA',
            'Diagnostic CECRL (A2 / B1 / B2)',
          ]
        : const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...features.map((f) => _FeatureRow(label: f, included: true)),
        if (excluded.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'NON INCLUS',
            style: AppFonts.mono(
              size: 9.5,
              color: AppColors.red,
              letterSpacing: 1.2,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ...excluded.map((f) => _FeatureRow(label: f, included: false)),
        ],
      ],
    );
  }
}

/// Une ligne de feature : coche verte si incluse, croix grise + texte estompé
/// barré si non incluse (utilisé pour clarifier la couverture de Civique).
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.included});

  final String label;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: included ? AppColors.green : AppColors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppFonts.jakarta(
                size: 13.5,
                color: included ? AppColors.ink2 : AppColors.red,
                height: 1.4,
              ).copyWith(
                decoration: included ? null : TextDecoration.lineThrough,
                decorationColor: AppColors.red.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
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
  const _LegalLinks({this.oneTime = false});

  final bool oneTime;

  @override
  Widget build(BuildContext context) {
    return Text(
      oneTime
          ? 'Achat unique, sans abonnement : aucun renouvellement automatique. '
              'L\'accès expire à la fin de la durée choisie.'
          : 'L\'abonnement est géré par le store. Gérez le renouvellement et '
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
