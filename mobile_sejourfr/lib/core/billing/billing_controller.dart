import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/api_client.dart';
import '../api/billing_repository.dart';
import '../api/repositories.dart';
import '../auth/auth_controller.dart';
import '../models/auth_models.dart';
import '../models/billing_models.dart';
import 'iap_service.dart';

// ============================================================================
// État
// ============================================================================

/// Issue d'une vérification d'achat réussie, déduite en comparant l'état
/// Premium du user AVANT le refresh avec le statut renvoyé par le backend.
/// Pilote le message de confirmation du paywall (bienvenue vs prolongation
/// vs changement d'offre vs simple restauration).
enum PurchaseOutcome {
  /// N'était pas Premium → premier accès ouvert.
  activated,

  /// Était sur Civique seul → passe en Intégral.
  upgraded,

  /// Même module, date de fin repoussée (rachat d'un pass = durées cumulées).
  extended,

  /// Rien n'a changé : restauration multi-appareil ou transaction rejouée.
  alreadyActive,
}

@immutable
class BillingState {
  const BillingState({
    this.isLoading = true,
    this.error,
    this.products = const [],
    this.lastVerification,
    this.lastVerificationOutcome,
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

  /// Issue de la dernière vérification (toujours posée avec
  /// [lastVerification]) — cf. [PurchaseOutcome].
  final PurchaseOutcome? lastVerificationOutcome;

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
    PurchaseOutcome? lastVerificationOutcome,
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
      lastVerificationOutcome:
          lastVerificationOutcome ?? this.lastVerificationOutcome,
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

  /// Garde-fou anti-spinner-infini de la restauration : si le store n'a rien à
  /// restaurer, il n'émet AUCUN event sur [IapService.purchaseStream] → sans ce
  /// timeout, [purchaseInProgress] resterait true indéfiniment. Armé dans
  /// [restorePurchases], annulé dès qu'un event arrive (restauration réelle).
  Timer? _restoreTimeout;
  bool _restoreInFlight = false;
  static const _restoreTimeoutDuration = Duration(seconds: 8);

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
        // côté App Store Connect / Play Console. Gardé en debug uniquement
        // (pas de bruit dans les logs release / idevicesyslog).
        if (kDebugMode) {
          debugPrint('IAP: SKUs introuvables côté store: ${response.notFoundIDs}');
        }
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
    // Le SKU vient du backend (table plans, posé par l'admin dans /admin/plans).
    // On lit directement appleProductId / googleProductId : ils peuvent diverger
    // du `code` (ex. produit Apple recréé avec un ID neuf — un Product ID
    // supprimé n'est jamais réutilisable côté Apple). Si l'ID store n'est pas
    // renseigné pour cette plateforme, on filtre (le plan ne sera pas vendable
    // ici, ex. plan FREE ou web-only Stripe).
    if (plan.target == null || plan.price <= 0) {
      return null;
    }
    // Abonnement récurrent : périodicité requise. Pass one-time : pas de
    // périodicité (la durée vit dans durationDays).
    if (!plan.isOneTime && plan.periodicity == null) {
      return null;
    }
    final sku = source == SubscriptionSource.google
        ? plan.googleProductId
        : plan.appleProductId;
    if (sku == null || sku.isEmpty) {
      return null;
    }
    return sku;
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
      // L'accès Premium vit côté BACKEND (user_subscriptions), pas dans le
      // store : pour un pass one-time, la durée est posée par le backend, le
      // consommable est « brûlé » à l'achat. Le vrai « restore » d'un compte
      // qui a déjà payé (réinstallation, nouvel appareil, pass en cours) est
      // donc une RELECTURE du statut serveur — on la fait toujours.
      final authState = _ref.read(authControllerProvider);
      final prevUser = authState is AuthAuthenticated ? authState.user : null;

      final status = await _repo.getSubscriptionStatus();
      await _ref
          .read(authControllerProvider.notifier)
          .refreshSubscriptionStatus(status);

      // Mode passes one-time (catalogue 100 % consommable) : on NE déclenche
      // PAS de sync StoreKit. Apple ne « restaure » jamais un consommable, et
      // StoreKit 2 re-livre des transactions consommables périmées en boucle
      // en `restored` (flutter/flutter#180046) → c'est exactement ce qui
      // faisait remonter « Achat validé côté store, mais… » à la restauration.
      // Le statut backend ci-dessus suffit. En mode abonnement (dormant), on a
      // en revanche besoin de re-livrer les transactions du store.
      final oneTimeMode = state.products.isNotEmpty &&
          state.products.every((p) => p.isOneTime);

      if (!oneTimeMode) {
        _restoreInFlight = true;
        await _iap.restorePurchases();
        // Les achats restaurés arrivent via purchaseStream →
        // _onPurchasesUpdated qui les renvoie au backend. On ne reset pas
        // purchaseInProgress ici, c'est le handler stream qui le fera. Si le
        // store n'a RIEN à restaurer, aucun event n'arrive : on arme un timeout
        // qui débloque l'UI avec un message clair.
        _restoreTimeout?.cancel();
        _restoreTimeout = Timer(_restoreTimeoutDuration, _onRestoreTimeout);
        return;
      }

      // One-time : terminé sans passer par le store. On réutilise le chemin
      // d'affichage de l'achat (snackbar d'issue + fermeture si Premium).
      if (status.isPremium) {
        state = state.copyWith(
          purchaseInProgress: false,
          lastVerification: status,
          lastVerificationOutcome: _outcomeFor(prevUser, status),
          clearError: true,
          clearPurchasingSku: true,
        );
      } else {
        // Jamais payé sur ce compte → rien à restaurer, message non bloquant.
        state = state.copyWith(
          purchaseInProgress: false,
          clearPurchasingSku: true,
          error: 'Aucun achat à restaurer pour ce compte.',
        );
      }
    } catch (e) {
      _endRestore();
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

  /// Aucun achat restauré dans le délai imparti → rien à restaurer. On débloque
  /// l'UI (boutons re-cliquables) et on informe l'utilisateur.
  void _onRestoreTimeout() {
    if (!_restoreInFlight) return;
    _restoreInFlight = false;
    if (!mounted) return;
    state = state.copyWith(
      purchaseInProgress: false,
      clearPurchasingSku: true,
      error: 'Aucun achat à restaurer pour ce compte.',
    );
  }

  void _endRestore() {
    _restoreInFlight = false;
    _restoreTimeout?.cancel();
    _restoreTimeout = null;
  }

  // --------------------------------------------------------------------------
  // Réception des events du store
  // --------------------------------------------------------------------------

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    // Un event arrive (achat OU restauration réelle) → on désarme le timeout de
    // restauration : le flux normal ci-dessous gère désormais purchaseInProgress.
    if (purchases.isNotEmpty) _endRestore();
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
          await _iap.completePurchase(purchase);
          break;

        case PurchaseStatus.canceled:
          state = state.copyWith(
            purchaseInProgress: false,
            clearError: true,
            clearPurchasingSku: true,
          );
          await _iap.completePurchase(purchase);
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

      // Snapshot de l'état Premium AVANT le refresh : c'est la comparaison
      // avant/après qui permet de qualifier l'issue (bienvenue, prolongation,
      // passage en Intégral, ou simple restauration sans changement).
      final authState = _ref.read(authControllerProvider);
      final prevUser = authState is AuthAuthenticated ? authState.user : null;

      // Le prix affiché par le store est le seul qui dise ce qui a réellement
      // été encaissé, et dans quelle devise. On le joint au reçu : c'est le
      // seul moment où on le connaît.
      final priced = _pricedProduct(purchase.productID);

      final status = await _repo.verifyReceipt(VerifyReceiptRequest(
        source: source,
        receipt: receipt,
        productId: purchase.productID,
        amountCents: priced == null
            ? null
            : (priced.rawPrice * 100).round(),
        currency: priced?.currencyCode,
      ));
      final outcome = _outcomeFor(prevUser, status);

      // Rafraîchit l'utilisateur authentifié — hasCivique / hasTcf /
      // premiumEndsAt doivent refléter le nouvel état immédiatement.
      await _ref
          .read(authControllerProvider.notifier)
          .refreshSubscriptionStatus(status);

      // Acquittement côté store : OBLIGATOIRE après validation serveur, sinon
      // le store retentera de livrer l'achat indéfiniment. Le service force
      // l'acquittement sur iOS même si pendingCompletePurchase est false
      // (bug StoreKit 2, cf. IapService.completePurchase).
      await _iap.completePurchase(purchase);

      state = state.copyWith(
        purchaseInProgress: false,
        lastVerification: status,
        lastVerificationOutcome: outcome,
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
        await _iap.completePurchase(purchase);
        // Hors d'un achat actif (boot / restauration), on évite juste de
        // laisser le spinner global coincé. Pendant un achat actif
        // (purchasingSku != null), on ne touche à rien : c'est l'event de
        // succès du vrai achat qui réinitialisera l'état.
        if (state.purchasingSku == null) {
          state = state.copyWith(purchaseInProgress: false);
        }
        return;
      }

      // Transaction RESTAURÉE qui échoue à la vérif : ne JAMAIS afficher
      // d'erreur bloquante. L'utilisateur ne l'a pas déclenchée — c'est presque
      // toujours un consommable périmé re-livré par StoreKit 2 en `restored`
      // (flutter/flutter#180046) au boot / à l'ouverture du paywall. Son accès
      // réel vit côté backend (un pass consommable n'est pas « restauré » par
      // le store). On l'acquitte donc silencieusement pour le purger de la file
      // et on débloque l'UI, sans bannière d'erreur.
      if (purchase.status == PurchaseStatus.restored) {
        await _iap.completePurchase(purchase);
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
      if (blocking) {
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

  /// Le produit du store correspondant à une transaction, s'il a été chargé.
  ///
  /// `null` est un cas **normal** : une transaction rejouée au lancement
  /// (StoreKit re-livre en `restored`) arrive avant tout `load()`. On préfère
  /// alors ne rien affirmer sur le montant plutôt que de le déduire du prix du
  /// plan, qui est libellé en euros et modifiable en console — il ne dit rien
  /// de ce que l'utilisateur a payé.
  ProductDetails? _pricedProduct(String productId) {
    for (final product in state.products) {
      if (product.productDetails.id == productId) return product.productDetails;
    }
    return null;
  }

  /// Compare l'état Premium d'avant l'achat avec le statut fraîchement
  /// vérifié. `hasCivique`/`hasTcf` sont tous deux true pour un Intégral
  /// (cf. SubscriptionStatusResponse.hasCivique).
  PurchaseOutcome _outcomeFor(AuthUser? prev, SubscriptionStatusResponse next) {
    final prevHadCivique = prev?.hasCivique ?? false;
    final prevHadTcf = prev?.hasTcf ?? false;
    if (!prevHadCivique && !prevHadTcf) return PurchaseOutcome.activated;
    if (next.moduleAccess == ModuleAccess.integral && !prevHadTcf) {
      return PurchaseOutcome.upgraded;
    }
    final prevEnd = prev?.premiumEndsAt;
    final nextEnd = next.expiresAt;
    if (nextEnd != null && (prevEnd == null || nextEnd.isAfter(prevEnd))) {
      return PurchaseOutcome.extended;
    }
    return PurchaseOutcome.alreadyActive;
  }

  @override
  void dispose() {
    _restoreTimeout?.cancel();
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
