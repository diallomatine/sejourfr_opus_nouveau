import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/api_client.dart';
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
    this.purchasingSku,
    this.actionBlocked = false,
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

  /// Code du Plan en cours d'achat (= SKU). Permet à l'UI de n'afficher le
  /// spinner que sur la card concernée. Null pendant une restauration (qui
  /// ne cible pas une card précise).
  final String? purchasingSku;

  /// True quand l'erreur courante est définitive et que réessayer depuis le
  /// paywall ne servira à rien (ex: 409 compte store déjà lié, produit non
  /// configuré). L'UI grise alors les boutons d'achat. Toujours remis à false
  /// quand l'erreur est effacée (clearError).
  final bool actionBlocked;

  BillingState copyWith({
    bool? isLoading,
    String? error,
    List<IapProduct>? products,
    SubscriptionStatusResponse? lastVerification,
    bool? purchaseInProgress,
    String? purchasingSku,
    bool? actionBlocked,
    bool clearError = false,
    bool clearPurchasingSku = false,
  }) {
    return BillingState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      products: products ?? this.products,
      lastVerification: lastVerification ?? this.lastVerification,
      purchaseInProgress: purchaseInProgress ?? this.purchaseInProgress,
      purchasingSku:
          clearPurchasingSku ? null : (purchasingSku ?? this.purchasingSku),
      actionBlocked: clearError ? false : (actionBlocked ?? this.actionBlocked),
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
          error: 'La communication avec le store a échoué. Réessayez dans un '
              'instant.',
          purchaseInProgress: false,
          clearPurchasingSku: true,
        );
      },
    );
  }

  /// Nom du store selon la plateforme courante, pour des messages adaptés
  /// (« App Store » sur iOS, « Google Play » sur Android).
  static String get _storeName =>
      IapService.currentSource == SubscriptionSource.apple
          ? 'App Store'
          : 'Google Play';

  /// Traduit une exception réseau/store en message court et lisible pour
  /// l'utilisateur — jamais de stack trace ni de DioException brute à l'écran.
  /// [blocking] = true quand réessayer est inutile (action à mener hors de ce
  /// paywall) → l'UI grise alors les boutons d'achat.
  /// [fallback] couvre les cas non mappés (ex: erreur de chargement vs achat).
  ({String message, bool blocking}) _describeError(
    Object e, {
    required String fallback,
  }) {
    final api = ApiClient.toApiException(e);
    switch (api.statusCode) {
      case 409:
        return (
          message: 'Votre compte $_storeName est déjà associé à un abonnement '
              'SejourFR actif sur un autre compte. Connectez-vous à ce compte '
              'pour y accéder, ou utilisez un autre compte $_storeName.',
          blocking: true,
        );
      case 400:
      case 422:
        return (
          message: 'Cet abonnement n\'est pas disponible à l\'achat pour le '
              'moment. Réessayez plus tard.',
          blocking: true,
        );
      case 401:
        return (
          message: 'Votre session a expiré. Reconnectez-vous puis réessayez.',
          blocking: false,
        );
      case 503:
        return (
          message: 'Le service de paiement est momentanément indisponible. '
              'Réessayez dans quelques instants.',
          blocking: false,
        );
      case 0:
        // Message déjà propre côté ApiClient (« Connexion impossible… »).
        return (message: api.message, blocking: false);
    }
    if (api.statusCode >= 500) {
      return (
        message: 'Une erreur est survenue de notre côté. Réessayez dans un '
            'instant.',
        blocking: false,
      );
    }
    return (message: fallback, blocking: false);
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
        if (target == null) continue;
        // Abonnement : périodicité requise. Pass one-time : pas de périodicité
        // (la durée vient de durationDays).
        if (!plan.isOneTime && plan.periodicity == null) continue;
        products.add(IapProduct(
          plan: plan,
          productDetails: pd,
          module: target,
          periodicity: plan.periodicity,
        ));
      }

      state = state.copyWith(
        isLoading: false,
        products: products,
        clearError: true,
      );
    } catch (e) {
      final d = _describeError(e,
          fallback: 'Impossible de charger les abonnements pour le moment. '
              'Réessayez plus tard.');
      state = state.copyWith(
        isLoading: false,
        error: d.message,
        actionBlocked: d.blocking,
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
    if (plan.target == null || plan.price <= 0) {
      return null;
    }
    // Abonnement récurrent : périodicité requise. Pass one-time : pas de
    // périodicité (la durée vit dans durationDays).
    if (!plan.isOneTime && plan.periodicity == null) {
      return null;
    }
    // Google Play impose des Product IDs en MINUSCULES (Apple/Stripe tolèrent
    // les majuscules). Le code Plan canonique est en MAJ (CIVIQUE_MONTHLY) → on
    // le minuscule pour Google. Conséquence : `plans.google_product_id` en base
    // ET les Product IDs créés dans la Play Console doivent être en minuscules
    // (civique_monthly, …), sinon le SKU revient en notFoundIDs.
    if (source == SubscriptionSource.google) {
      return plan.code.toLowerCase();
    }
    return plan.code;
  }

  // --------------------------------------------------------------------------
  // Déclenchement de l'achat natif
  // --------------------------------------------------------------------------

  Future<void> startPurchase(IapProduct product) async {
    state = state.copyWith(
      purchaseInProgress: true,
      purchasingSku: product.plan.code,
      clearError: true,
    );
    try {
      // Pass one-time = produit consommable (ré-achetable) ; abonnement =
      // non-consommable. Cf. IapService.
      final ok = product.plan.isOneTime
          ? await _iap.purchaseConsumable(product.productDetails)
          : await _iap.purchase(product.productDetails);
      if (!ok) {
        // Le store a refusé d'ouvrir l'UI d'achat (déjà en cours, restrictions
        // parentales, etc.). L'erreur réelle remontera via purchaseStream s'il
        // y en a une.
        state = state.copyWith(
          purchaseInProgress: false,
          clearPurchasingSku: true,
          error: 'Le store n\'a pas pu ouvrir la fenêtre d\'achat. Réessayez.',
        );
      }
    } catch (e) {
      final d = _describeError(e,
          fallback: 'Impossible de démarrer l\'achat. Réessayez.');
      state = state.copyWith(
        purchaseInProgress: false,
        clearPurchasingSku: true,
        error: d.message,
        actionBlocked: d.blocking,
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
      purchaseInProgress: true,
      clearError: true,
      clearPurchasingSku: true,
    );
    try {
      await _iap.restorePurchases();
      // Les achats restaurés arrivent via purchaseStream → _onPurchasesUpdated
      // qui les renvoie au backend pour rattachement. On ne reset pas
      // purchaseInProgress ici, c'est le handler stream qui le fera quand
      // tous les events seront passés.
    } catch (e) {
      final d = _describeError(e,
          fallback: 'Impossible de restaurer vos achats. Réessayez.');
      state = state.copyWith(
        purchaseInProgress: false,
        clearPurchasingSku: true,
        error: d.message,
        actionBlocked: d.blocking,
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
          // `purchase.error.message` vient du store (souvent technique en
          // anglais) — on ne l'affiche pas brut.
          state = state.copyWith(
            purchaseInProgress: false,
            clearPurchasingSku: true,
            error: 'L\'achat n\'a pas pu aboutir côté store. Aucun montant '
                'n\'a été débité. Réessayez.',
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          state = state.copyWith(
            purchaseInProgress: false,
            clearError: true,
            clearPurchasingSku: true,
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
        clearPurchasingSku: true,
      );
    } catch (e) {
      final api = ApiClient.toApiException(e);

      // 409 = ce reçu store appartient à un AUTRE compte SejourFR (rejeu d'un
      // vieil achat ou d'une restauration en arrière-plan). En mode pass
      // one-time (consommables), un achat réellement neuf a toujours une
      // transaction neuve → il ne tombe JAMAIS en 409. Un 409 est donc
      // toujours un reçu étranger que l'utilisateur courant ne peut pas
      // résoudre, et qui ne doit pas masquer son achat légitime en cours. On
      // le purge SILENCIEUSEMENT de la file (sinon le store le re-livre en
      // boucle à chaque lancement) sans afficher d'erreur bloquante.
      if (api.statusCode == 409) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        // Hors d'un achat actif (boot / restauration), on évite juste de
        // laisser le spinner global coincé. Pendant un achat actif
        // (purchasingSku != null), on ne touche à rien : c'est l'event de
        // succès du vrai achat qui réinitialisera l'état.
        if (state.purchasingSku == null) {
          state = state.copyWith(purchaseInProgress: false);
        }
        return;
      }

      final String message;
      final bool blocking;
      if (api.statusCode == 400 || api.statusCode == 422) {
        message = 'Achat validé côté store, mais nous n\'avons pas pu activer '
            'votre accès. Contactez le support si le problème persiste.';
        blocking = true;
      } else {
        // Transitoire (réseau, 5xx) : la validation sera rejouée
        // automatiquement, sans nouveau débit.
        message = 'Achat validé côté store, mais la confirmation chez SejourFR '
            'n\'a pas encore abouti. Votre accès sera activé automatiquement '
            'sous peu — vous ne serez pas débité deux fois.';
        blocking = false;
      }

      // Échec PERMANENT (blocking) → on acquitte quand même la transaction.
      // Sinon le store la re-livre à chaque lancement / tentative d'achat
      // (transaction « empoisonnée ») : l'erreur revient en boucle et grise
      // les boutons, l'utilisateur ne peut plus rien acheter. On ne laisse en
      // suspens QUE les échecs transitoires, pour lesquels rejouer a un sens.
      if (blocking && purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      state = state.copyWith(
        purchaseInProgress: false,
        clearPurchasingSku: true,
        error: message,
        actionBlocked: blocking,
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
