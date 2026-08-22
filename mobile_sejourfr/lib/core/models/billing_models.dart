/// Modèles DTO miroirs des endpoints `/api/billing/*` côté backend.
///
/// Restent alignés à la main avec les classes Java :
/// - `PlanPublicResponse.java`
/// - `SubscriptionStatusResponse.java`
/// - `VerifyReceiptRequest.java`
library;

import 'enums.dart';

// ============================================================================
// Enums miroirs
// ============================================================================

enum BillingCycle { none, monthly, quarterly, semestrial, yearly }

extension BillingCycleParse on BillingCycle {
  static BillingCycle fromString(String? raw) {
    switch (raw) {
      case 'MONTHLY':
        return BillingCycle.monthly;
      case 'THREE_MONTHS':
        return BillingCycle.quarterly;
      case 'SIX_MONTHS':
        return BillingCycle.semestrial;
      case 'YEARLY':
        return BillingCycle.yearly;
      default:
        return BillingCycle.none;
    }
  }
}

enum PlanPurchaseType { subscription, oneTime }

extension PlanPurchaseTypeParse on PlanPurchaseType {
  static PlanPurchaseType fromString(String? raw) {
    return raw == 'ONE_TIME'
        ? PlanPurchaseType.oneTime
        : PlanPurchaseType.subscription;
  }
}

/// Libellé court de la durée d'un pass one-time (durationDays → « 7 jours »,
/// « 1 mois », « 2 mois », « 1 an »). Tolérant aux valeurs proches.
///
/// Une semaine seule s'annonce **en jours** : c'est ainsi que le pass d'essai
/// est vendu, et la règle plurielle rendait « 1 semaines ». Miroir mot pour mot
/// de `durationLabel` / `passDurationLabel` côté web.
String passDurationLabel(int days) {
  if (days <= 0) return '';
  if (days % 365 == 0) {
    final y = days ~/ 365;
    return y == 1 ? '1 an' : '$y ans';
  }
  if (days >= 30 && days % 30 == 0) {
    return '${days ~/ 30} mois';
  }
  if (days % 7 == 0) {
    return days == 7 ? '7 jours' : '${days ~/ 7} semaines';
  }
  return '$days jours';
}

enum ModuleAccess { none, civique, tcf, integral }

extension ModuleAccessParse on ModuleAccess {
  static ModuleAccess fromString(String? raw) {
    switch (raw) {
      case 'CIVIQUE':
        return ModuleAccess.civique;
      case 'TCF':
        return ModuleAccess.tcf;
      case 'INTEGRAL':
        return ModuleAccess.integral;
      default:
        return ModuleAccess.none;
    }
  }
}

enum SubscriptionSource { stripe, apple, google }

extension SubscriptionSourceX on SubscriptionSource {
  String get backendName => switch (this) {
        SubscriptionSource.stripe => 'STRIPE',
        SubscriptionSource.apple => 'APPLE',
        SubscriptionSource.google => 'GOOGLE',
      };

  static SubscriptionSource? tryParse(String? raw) {
    switch (raw) {
      case 'STRIPE':
        return SubscriptionSource.stripe;
      case 'APPLE':
        return SubscriptionSource.apple;
      case 'GOOGLE':
        return SubscriptionSource.google;
      default:
        return null;
    }
  }
}

enum SubscriptionStatus {
  active,
  trial,
  inGrace,
  pending,
  canceled,
  expired,
  refunded,
}

extension SubscriptionStatusParse on SubscriptionStatus {
  static SubscriptionStatus? tryParse(String? raw) {
    switch (raw) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'TRIAL':
        return SubscriptionStatus.trial;
      case 'IN_GRACE':
        return SubscriptionStatus.inGrace;
      case 'PENDING':
        return SubscriptionStatus.pending;
      case 'CANCELED':
        return SubscriptionStatus.canceled;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      case 'REFUNDED':
        return SubscriptionStatus.refunded;
      default:
        return null;
    }
  }
}

// ============================================================================
// Helpers UI : périodicité × module → code Plan backend
// ============================================================================

enum PlanPeriodicity { monthly, quarterly, yearly }

extension PlanPeriodicityX on PlanPeriodicity {
  String get label => switch (this) {
        PlanPeriodicity.monthly => 'Mensuel',
        PlanPeriodicity.quarterly => 'Trimestriel',
        PlanPeriodicity.yearly => 'Annuel',
      };

  String get suffix => switch (this) {
        PlanPeriodicity.monthly => '/ mois',
        PlanPeriodicity.quarterly => '/ 3 mois',
        PlanPeriodicity.yearly => '/ an',
      };

  /// Convertit un [BillingCycle] backend en périodicité UI quand c'est
  /// possible. Null pour les cycles non-vendables (none, semestrial).
  static PlanPeriodicity? fromBillingCycle(BillingCycle cycle) {
    return switch (cycle) {
      BillingCycle.monthly => PlanPeriodicity.monthly,
      BillingCycle.quarterly => PlanPeriodicity.quarterly,
      BillingCycle.yearly => PlanPeriodicity.yearly,
      _ => null,
    };
  }
}

enum PlanModuleTarget { civique, integral }

extension PlanModuleTargetX on PlanModuleTarget {
  String get backendName => switch (this) {
        PlanModuleTarget.civique => 'CIVIQUE',
        PlanModuleTarget.integral => 'INTEGRAL',
      };

  String get label => switch (this) {
        PlanModuleTarget.civique => 'Civique',
        PlanModuleTarget.integral => 'Intégral',
      };
}

/// Dérive le `planCode` backend à partir d'un module + d'une périodicité.
/// Doit rester aligné avec la table `plans` côté backend (migration V106).
String planCodeFor(PlanModuleTarget module, PlanPeriodicity periodicity) {
  final mod = module.backendName;
  final per = switch (periodicity) {
    PlanPeriodicity.monthly => 'MONTHLY',
    PlanPeriodicity.quarterly => 'QUARTERLY',
    PlanPeriodicity.yearly => 'YEARLY',
  };
  return '${mod}_$per';
}

// ============================================================================
// DTOs
// ============================================================================

/// Plan public exposé par `/api/billing/plans`. Inclut les Product IDs store
/// ([appleProductId] / [googleProductId]) : le mobile les passe tels quels à
/// StoreKit / Play Billing comme SKU (cf. [BillingController]). Ils peuvent
/// diverger de [code] (ex. produit Apple recréé avec un ID neuf) et sont null
/// pour les plans web-only.
class PlanPublicResponse {
  PlanPublicResponse({
    required this.code,
    required this.name,
    required this.billingCycle,
    required this.price,
    required this.originalPrice,
    required this.moduleAccess,
    required this.durationDays,
    required this.realtimeEoSessions,
    required this.purchaseType,
    required this.appleProductId,
    required this.googleProductId,
  });

  final String code;
  final String name;
  final BillingCycle billingCycle;
  final double price;
  final double? originalPrice;
  final ModuleAccess moduleAccess;
  final int durationDays;

  /// Simulations orales en temps réel (examinateur vocal IA) ouvertes par ce
  /// pass. 0 = non éligible (Civique, Free) — à afficher comme tel.
  final int realtimeEoSessions;
  final PlanPurchaseType purchaseType;
  final String? appleProductId;
  final String? googleProductId;

  factory PlanPublicResponse.fromJson(Map<String, dynamic> json) {
    return PlanPublicResponse(
      code: json['code'] as String,
      name: json['name'] as String,
      billingCycle: BillingCycleParse.fromString(json['billingCycle'] as String?),
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      moduleAccess: ModuleAccessParse.fromString(json['moduleAccess'] as String?),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      realtimeEoSessions: (json['realtimeEoSessions'] as num?)?.toInt() ?? 0,
      purchaseType: PlanPurchaseTypeParse.fromString(json['purchaseType'] as String?),
      appleProductId: json['appleProductId'] as String?,
      googleProductId: json['googleProductId'] as String?,
    );
  }

  bool get isOneTime => purchaseType == PlanPurchaseType.oneTime;

  /// Ce que ce pass ouvre en **simulations orales en direct** (examinateur
  /// vocal), la seule ressource dont le volume change d'un pass Intégral à
  /// l'autre : catalogue, examens blancs et corrections IA sont identiques
  /// partout, seules la durée et ce quota progressent. Sans cette ligne, deux
  /// passes ne se distinguaient que par leur prix.
  ///
  /// `null` = rien à annoncer (Civique, plan gratuit) — l'appelant décide s'il
  /// affiche autre chose à la place.
  ///
  /// ⚠️ On ne dit **jamais** « sans simulation orale » pour un pass Intégral :
  /// un backend antérieur à `realtimeEoSessions` renvoie le champ absent (donc
  /// 0), et l'affirmation serait fausse sur l'argument principal du produit.
  ///
  /// Miroir mot pour mot de `realtimeSessionsLabel` côté web (`lib/types.ts`).
  String? get realtimeSessionsLabel {
    if (realtimeEoSessions > 0) {
      return realtimeEoSessions == 1
          ? '1 simulation orale en direct'
          : '$realtimeEoSessions simulations orales en direct';
    }
    if (moduleAccess == ModuleAccess.integral) {
      return 'Simulations orales en direct incluses';
    }
    return null;
  }

  /// Libellé de durée pour un pass one-time (« 6 semaines », « 3 mois »…).
  String get durationLabel => passDurationLabel(durationDays);

  PlanModuleTarget? get target {
    if (moduleAccess == ModuleAccess.civique) return PlanModuleTarget.civique;
    if (moduleAccess == ModuleAccess.integral) return PlanModuleTarget.integral;
    return null;
  }

  PlanPeriodicity? get periodicity =>
      PlanPeriodicityX.fromBillingCycle(billingCycle);
}

/// Statut Premium agrégé toutes sources (Stripe + Apple + Google). Source de
/// vérité unique côté backend — l'app NE décide PAS du statut.
class SubscriptionStatusResponse {
  SubscriptionStatusResponse({
    required this.isPremium,
    this.source,
    this.productId,
    this.expiresAt,
    this.status,
    required this.moduleAccess,
    required this.autoRenew,
    this.oneTime = false,
    this.realtimeSessionsRemaining,
  });

  final bool isPremium;
  final SubscriptionSource? source;
  final String? productId;
  final DateTime? expiresAt;
  final SubscriptionStatus? status;
  final ModuleAccess moduleAccess;
  final bool autoRenew;

  /// Accès issu d'un pass one-time (lot 5) : « Mon accès » sans résiliation.
  final bool oneTime;

  /// Sessions d'expression orale TEMPS RÉEL restantes sur le pass courant
  /// (examinateur IA, T1/T2). Null si non concerné (compte gratuit ou pass sans
  /// accès TCF) — le front n'affiche le compteur que si la valeur est présente.
  final int? realtimeSessionsRemaining;

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      isPremium: json['isPremium'] as bool? ?? false,
      source: SubscriptionSourceX.tryParse(json['source'] as String?),
      productId: json['productId'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      status: SubscriptionStatusParse.tryParse(json['status'] as String?),
      moduleAccess: ModuleAccessParse.fromString(json['moduleAccess'] as String?),
      autoRenew: json['autoRenew'] as bool? ?? false,
      oneTime: json['oneTime'] as bool? ?? false,
      realtimeSessionsRemaining:
          (json['realtimeSessionsRemaining'] as num?)?.toInt(),
    );
  }

  bool get hasCivique =>
      moduleAccess == ModuleAccess.civique || moduleAccess == ModuleAccess.integral;
  bool get hasTcf => moduleAccess == ModuleAccess.integral;
}

/// Reçu envoyé au backend après un achat IAP réussi. Le backend re-valide
/// auprès du store (jamais confiance au client). [receipt] :
/// - Apple : `signedTransactionInfo` (JWS) renvoyé par StoreKit.
/// - Google : `purchaseToken` du PurchaseDetails.
class VerifyReceiptRequest {
  VerifyReceiptRequest({
    required this.source,
    required this.receipt,
    required this.productId,
    this.amountCents,
    this.currency,
  });

  final SubscriptionSource source;
  final String receipt;
  final String productId;

  /// **Le montant réellement débité**, dans la devise du store, en plus petite
  /// unité (centimes). Les stores encaissent en devise locale — CAD, USD,
  /// EUR… — et le backend ne l'a jamais su : il ne pouvait que multiplier par
  /// le prix du plan, qui est mutable en console et libellé en euros.
  ///
  /// `null` est un cas **normal** et le champ est facultatif côté serveur :
  /// une transaction rejouée au démarrage arrive avant que les produits du
  /// store soient chargés. *Montant inconnu*, jamais un montant inventé.
  final int? amountCents;

  /// Code ISO 4217 rendu par le store. Toujours posé **avec** [amountCents] :
  /// un montant sans devise ne veut rien dire.
  final String? currency;

  Map<String, dynamic> toJson() => {
        'source': source.backendName,
        'receipt': receipt,
        'productId': productId,
        if (amountCents != null && currency != null) ...{
          'amountCents': amountCents,
          'currency': currency,
        },
      };
}

/// Réponse de `POST /api/billing/cancel`. Deux variantes :
/// - `done` : Stripe a enregistré la résiliation côté serveur. L'app affiche
///   [message] et rafraîchit le statut. Premium reste ouvert jusqu'à `endsAt`.
/// - `redirect` : Apple/Google n'autorisent pas l'annulation serveur. L'app
///   ouvre [redirectUrl] (page de gestion d'abonnement du store) et le statut
///   ne change pas tant que l'user n'a pas confirmé côté store (le webhook
///   du store mettra à jour ensuite).
class CancelSubscriptionResponse {
  CancelSubscriptionResponse({
    required this.action,
    required this.message,
    this.redirectUrl,
  });

  /// `DONE` ou `REDIRECT`.
  final String action;
  final String message;
  final String? redirectUrl;

  bool get isDone => action == 'DONE';
  bool get isRedirect => action == 'REDIRECT';

  factory CancelSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return CancelSubscriptionResponse(
      action: json['action'] as String,
      message: json['message'] as String? ?? '',
      redirectUrl: json['redirectUrl'] as String?,
    );
  }
}

/// Mapping helper : depuis un AppModule UI → PlanModuleTarget pour le paywall.
extension AppModulePaywall on AppModule {
  PlanModuleTarget get paywallTarget => switch (this) {
        AppModule.civique => PlanModuleTarget.civique,
        AppModule.tcf => PlanModuleTarget.integral,
      };
}
