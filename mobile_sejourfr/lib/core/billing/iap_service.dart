import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/billing_models.dart';

/// Wrapper sur `in_app_purchase` (Apple StoreKit + Google Play Billing).
/// Expose une API simple consommée par [BillingController].
///
/// - [init] : connecte au store (mais le `purchaseStream` du package est
///   global, donc on n'a rien à wire ici, juste à exposer un `isAvailable`).
/// - [loadProducts] : récupère les détails (prix, titre, devise) pour les SKUs
///   demandés. Les SKUs viennent de [PlanPublicResponse.apple/googleProductId]
///   côté backend, qui matche ce qu'on a déclaré dans App Store Connect / Play
///   Console.
/// - [purchase] : déclenche l'UI native d'achat (sheet Apple ou bottom Google).
/// - [restorePurchases] : re-livre tous les achats existants via
///   `purchaseStream` — utilisé par le bouton « Restaurer mes achats ».
/// - [completePurchase] : acquitte la transaction côté store APRÈS validation
///   serveur. Obligatoire sinon le store retentera de livrer en boucle.
///
/// Source détectée : iOS → Apple, Android → Google. Pas d'autre support.
class IapService {
  IapService([InAppPurchase? instance])
      : _iap = instance ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  /// La source IAP courante d'après la plateforme runtime. Lève si on
  /// tourne sur web/desktop (où le package n'est pas supporté).
  static SubscriptionSource get currentSource {
    if (Platform.isIOS || Platform.isMacOS) return SubscriptionSource.apple;
    if (Platform.isAndroid) return SubscriptionSource.google;
    throw UnsupportedError('IAP non supporté sur cette plateforme.');
  }

  /// Stream des changements de transactions (livré par le store, géré
  /// nativement par le package). Le [BillingController] s'y abonne dans son
  /// init et y dispatche verify-receipt + completePurchase.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// True si le store est joignable (sandbox iOS / test track Android OK).
  /// False sur les builds où l'utilisateur a bloqué les achats in-app dans
  /// les Réglages système (cas rare mais réel).
  Future<bool> isAvailable() => _iap.isAvailable();

  /// Récupère les détails (prix local, devise, titre, description) des SKUs
  /// passés en paramètre. Les SKUs absents du store ne lèvent pas, ils
  /// arrivent dans [ProductDetailsResponse.notFoundIDs] — l'appelant doit
  /// vérifier que tous les SKUs attendus sont là.
  Future<ProductDetailsResponse> loadProducts(Set<String> skuIds) {
    return _iap.queryProductDetails(skuIds);
  }

  /// Lance l'achat natif. Le package gère en interne le routage vers
  /// StoreKit ou Play Billing. Pour les abonnements, on passe par
  /// [buyNonConsumable] (le package classe les subs comme "non-consommables"
  /// — c'est-à-dire que la plateforme garde la trace de l'achat).
  Future<bool> purchase(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Achat d'un PASS one-time (lot 5). Les passes sont des produits
  /// **consommables** sur les deux stores → `buyConsumable` avec
  /// `autoConsume: true` pour qu'ils soient ré-achetables après expiration.
  /// La durée d'accès réelle est posée par le backend (plan.durationDays),
  /// pas par le store.
  Future<bool> purchaseConsumable(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  /// Déclenche la re-livraison de tous les achats existants. Les events
  /// arrivent ensuite dans [purchaseStream] avec `status = PurchaseStatus.restored`.
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Acquitte la transaction côté store. À appeler APRÈS que le backend a
  /// validé le reçu. Sans ça, le store retentera de livrer l'achat.
  ///
  /// iOS / StoreKit 2 : `pendingCompletePurchase` revient faussement `false`
  /// sur certaines transactions livrées (consommables surtout —
  /// flutter/flutter#182739). S'y fier laisse la transaction unfinished, et
  /// elle est re-livrée en `restored` à chaque abonnement au purchaseStream
  /// (symptôme : le paywall se referme sur « Bienvenue… » à chaque ouverture).
  /// On acquitte donc SANS condition les transactions livrées côté Apple.
  /// Et comme le `finish()` natif ne répond jamais quand la transaction est
  /// déjà finie (flutter/flutter#160148), l'attente est bornée.
  Future<void> completePurchase(PurchaseDetails purchase) async {
    final delivered = purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
    final forceApple = delivered && (Platform.isIOS || Platform.isMacOS);
    if (!purchase.pendingCompletePurchase && !forceApple) return;
    try {
      await _iap.completePurchase(purchase).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Transaction déjà finie côté store : rien à acquitter.
    }
  }

  /// Récupère la chaîne à envoyer au backend dans [VerifyReceiptRequest.receipt]
  /// pour ce détail d'achat.
  ///
  /// - Apple (StoreKit 2 via in_app_purchase 3.x) : on envoie le JWS
  ///   `signedTransactionInfo`, exposé dans `verificationData.serverVerificationData`.
  /// - Google (Play Billing) : on envoie le `purchaseToken`, extrait du
  ///   `GooglePlayPurchaseDetails.billingClientPurchase`.
  static String receiptFor(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseToken;
    }
    // iOS / macOS / fallback : la `serverVerificationData` est le bon contenu
    // (JWS signedTransactionInfo en StoreKit 2).
    return purchase.verificationData.serverVerificationData;
  }

  /// Petit utilitaire de debug — log lisible d'un PurchaseDetails.
  static String describe(PurchaseDetails p) {
    return 'productId=${p.productID} status=${p.status} '
        'pending=${p.pendingCompletePurchase} '
        'transactionDate=${p.transactionDate}';
  }
}

/// Représentation simplifiée d'un produit IAP avec son SKU, son label store
/// et son [PlanPublicResponse] backend correspondant. Le [BillingController]
/// construit cette liste après le join `listPlans()` × `loadProducts()`.
@immutable
class IapProduct {
  const IapProduct({
    required this.plan,
    required this.productDetails,
    required this.module,
    required this.periodicity,
  });

  final PlanPublicResponse plan;
  final ProductDetails productDetails;
  final PlanModuleTarget module;

  /// Périodicité d'un abonnement récurrent ; **null pour un pass one-time**
  /// (la durée s'y lit via [plan.durationLabel]).
  final PlanPeriodicity? periodicity;

  bool get isOneTime => plan.isOneTime;
  String get durationLabel => plan.durationLabel;

  /// Prix local formaté tel que retourné par le store (ex: "9,99 €",
  /// "$9.99"). On l'affiche tel quel — Apple et Google calculent eux-mêmes
  /// la devise et le format selon la région de l'utilisateur.
  String get localizedPrice => productDetails.price;

  /// Nombre de mois « équivalents » servant à ramener le prix au mois :
  /// pour un pass, dérivé de la durée (1 an → 12, 3 mois → 3, 6 sem → 1,5 en
  /// comptant un mois = 4 semaines) ; pour un abonnement, depuis la périodicité.
  double get _equivalentMonths {
    if (isOneTime) {
      final d = plan.durationDays;
      if (d <= 0) return 1;
      if (d % 365 == 0) return (d ~/ 365) * 12;
      if (d % 30 == 0) return d / 30;
      if (d % 7 == 0) return (d ~/ 7) / 4;
      return d / 30;
    }
    return switch (periodicity) {
      PlanPeriodicity.monthly => 1,
      PlanPeriodicity.quarterly => 3,
      PlanPeriodicity.yearly => 12,
      null => 1,
    };
  }

  /// Prix mensuel équivalent, formaté dans la devise du store (ex: "6,66 €").
  /// On le met en avant pour réduire la friction perçue, tout en gardant le
  /// total réellement débité ([localizedPrice]) en sous-texte. Null quand la
  /// durée est ≤ 1 mois (le prix affiché est déjà mensuel).
  String? get monthlyEquivalentLabel {
    final months = _equivalentMonths;
    if (months <= 1) return null;
    final monthly = productDetails.rawPrice / months;
    final amount = monthly.toStringAsFixed(2).replaceAll('.', ',');
    return '$amount ${productDetails.currencySymbol}';
  }
}
