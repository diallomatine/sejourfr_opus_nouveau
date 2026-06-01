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
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
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
}
