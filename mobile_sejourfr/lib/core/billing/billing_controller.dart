import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/billing_repository.dart';
import '../api/repositories.dart';
import '../auth/auth_controller.dart';
import '../models/billing_models.dart';
import 'iap_service.dart';

// ============================================================================
// État
// ============================================================================

@immutable
class BillingState {
  const BillingState({
    this.isLoading = true,
    this.error,
    this.products = const [],
    this.lastVerification,
    this.purchaseInProgress = false,
  });

  /// Chargement initial des plans + des produits du store.
  final bool isLoading;

  /// Erreur de chargement ou de vérif backend (pas une erreur d'achat user-
  /// canceled, qui est juste un retour à l'état précédent).
  final String? error;

  /// Liste des [IapProduct] vendables : intersection des Plans actifs du
  /// backend avec leur SKU configuré ET disponible côté store.
  final List<IapProduct> products;

  /// Dernier statut Premium reçu après vérif backend. Sert à l'UI à
  /// afficher un message de confirmation et à fermer le paywall.
  final SubscriptionStatusResponse? lastVerification;

  /// True pendant que l'UI native d'achat est ouverte ou que le backend
  /// valide un reçu. Permet de désactiver les boutons.
  final bool purchaseInProgress;

  BillingState copyWith({
    bool? isLoading,
    String? error,
    List<IapProduct>? products,
    SubscriptionStatusResponse? lastVerification,
    bool? purchaseInProgress,
    bool clearError = false,
  }) {
    return BillingState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      products: products ?? this.products,
      lastVerification: lastVerification ?? this.lastVerification,
      purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
    );
  }
}

// ============================================================================
// Controller
// ============================================================================

class BillingController extends StateNotifier<BillingState> {
  BillingController({
    required Ref ref,
    required IapService iapService,
    required BillingRepository repository,
  })  : _ref = ref,
        _iap = iapService,
        _repo = repository,
        super(const BillingState()) {
    _subscribePurchaseStream();
    // Pas de load() automatique au boot — l'app peut tourner longtemps sans
    // jamais ouvrir le paywall. C'est l'écran paywall qui appellera load().
  }

  final Ref _ref;
  final IapService _iap;
  final BillingRepository _repo;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  void _subscribePurchaseStream() {
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchasesUpdated,
      onError: (Object error, StackTrace _) {
        state = state.copyWith(
          error: 'Erreur de communication avec le store : $error',
          purchaseInProgress: false,
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Chargement des produits (plans backend × SKUs store)
  // --------------------------------------------------------------------------

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        state = state.copyWith(
          isLoading: false,
          error: 'Les achats in-app ne sont pas disponibles sur cet appareil. '
              'Vérifiez vos restrictions Réglages > Temps d\'écran > '
              'Restrictions liées au contenu.',
        );
        return;
      }

      final plans = await _repo.listPlans();
      final source = IapService.currentSource;

      // SKUs à demander au store, indexés sur le Plan backend correspondant.
      final skuToPlan = <String, PlanPublicResponse>{};
      for (final plan in plans) {
        final sku = _skuFor(plan, source);
        if (sku != null && sku.isNotEmpty) {
          skuToPlan[sku] = plan;
        }
      }

      if (skuToPlan.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Aucun produit configuré pour cette plateforme. '
              'Réessayez plus tard.',
        );
        return;
      }

      final response = await _iap.loadProducts(skuToPlan.keys.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        // Log non-bloquant : on continue avec les produits trouvés. Cas
        // courant pendant le setup quand les SKUs ne sont pas encore validés
        // côté App Store Connect / Play Console.
        // ignore: avoid_print
        print('IAP: SKUs introuvables côté store: ${response.notFoundIDs}');
      }

      final products = <IapProduct>[];
      for (final pd in response.productDetails) {
        final plan = skuToPlan[pd.id];
        if (plan == null) continue;
        final target = plan.target;
        final periodicity = plan.periodicity;
        if (target == null || periodicity == null) continue;
        products.add(IapProduct(
          plan: plan,
          productDetails: pd,
          module: target,
          periodicity: periodicity,
        ));
      }

      state = state.copyWith(
        isLoading: false,
        products: products,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les abonnements : $e',
      );
    }
  }

  String? _skuFor(PlanPublicResponse plan, SubscriptionSource source) {
    // On lit le SKU côté backend (table plans). C'est l'admin qui le pose
    // dans /admin/plans. Si non renseigné → SKU absent ici, on filtre.
    // Note : le DTO public n'expose pas appleProductId / googleProductId
    // pour éviter de leaker les SKUs dans la landing. Workaround : on
    // utilise le `code` du Plan comme convention SKU (CIVIQUE_MONTHLY etc.)
    // et le backend / l'admin doit s'assurer que c'est aligné avec App Store
    // Connect / Play Console.
    // Le plan FREE (pas de module ciblé / pas de périodicité / prix nul) n'a
    // aucun SKU côté store → on l'écarte pour ne pas l'envoyer à loadProducts
    // (sinon il revient en notFoundIDs).
    if (plan.target == null || plan.periodicity == null || plan.price <= 0) {
      return null;
    }
    return plan.code;
  }

  // --------------------------------------------------------------------------
  // Déclenchement de l'achat natif
  // --------------------------------------------------------------------------

  Future<void> startPurchase(IapProduct product) async {
    state = state.copyWith(purchaseInProgress: true, clearError: true);
    try {
      final ok = await _iap.purchase(product.productDetails);
      if (!ok) {
        // Le store a refusé d'ouvrir l'UI d'achat (déjà en cours, restrictions
        // parentales, etc.). L'erreur réelle remontera via purchaseStream s'il
        // y en a une.
        state = state.copyWith(
          purchaseInProgress: false,
          error: 'Le store n\'a pas accepté la demande d\'achat. Réessayez.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        purchaseInProgress: false,
        error: 'Erreur au déclenchement de l\'achat : $e',
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(purchaseInProgress: true, clearError: true);
    try {
      await _iap.restorePurchases();
      // Les achats restaurés arrivent via purchaseStream → _onPurchasesUpdated
      // qui les renvoie au backend pour rattachement. On ne reset pas
      // purchaseInProgress ici, c'est le handler stream qui le fera quand
      // tous les events seront passés.
    } catch (e) {
      state = state.copyWith(
        purchaseInProgress: false,
        error: 'Impossible de restaurer vos achats : $e',
      );
    }
  }

  // --------------------------------------------------------------------------
  // Réception des events du store
  // --------------------------------------------------------------------------

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // L'utilisateur a confirmé, on attend le traitement (carte 3DS,
          // validation parentale Apple « Ask to Buy », etc.).
          state = state.copyWith(purchaseInProgress: true);
          break;

        case PurchaseStatus.error:
          state = state.copyWith(
            purchaseInProgress: false,
            error: purchase.error?.message ?? 'Erreur du store.',
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          state = state.copyWith(
            purchaseInProgress: false,
            clearError: true,
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndAcknowledge(purchase);
          break;
      }
    }
  }

  Future<void> _verifyAndAcknowledge(PurchaseDetails purchase) async {
    try {
      final source = IapService.currentSource;
      final receipt = IapService.receiptFor(purchase);
      final status = await _repo.verifyReceipt(VerifyReceiptRequest(
        source: source,
        receipt: receipt,
        productId: purchase.productID,
      ));

      // Rafraîchit l'utilisateur authentifié — hasCivique / hasTcf /
      // premiumEndsAt doivent refléter le nouvel état immédiatement.
      await _ref
          .read(authControllerProvider.notifier)
          .refreshSubscriptionStatus(status);

      // Acquittement côté store : OBLIGATOIRE après validation serveur, sinon
      // le store retentera de livrer l'achat indéfiniment.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      state = state.copyWith(
        purchaseInProgress: false,
        lastVerification: status,
        clearError: true,
      );
    } catch (e) {
      // On NE complete PAS l'achat ici : si le backend a échoué (network,
      // 502...), le store va re-livrer l'achat au prochain démarrage et on
      // re-tentera la validation. Le user reste « pending » côté UI mais
      // ne perd pas son achat.
      state = state.copyWith(
        purchaseInProgress: false,
        error: 'Achat validé côté store mais la confirmation chez SejourFR '
            'a échoué. Vous garderez votre accès — nous rejouerons '
            'automatiquement la validation. ($e)',
      );
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================================
// Providers
// ============================================================================

final iapServiceProvider = Provider<IapService>((ref) => IapService());

final billingControllerProvider =
    StateNotifierProvider<BillingController, BillingState>((ref) {
  return BillingController(
    ref: ref,
    iapService: ref.watch(iapServiceProvider),
    repository: ref.watch(billingRepositoryProvider),
  );
});
