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

/// Plan public exposé par `/api/billing/plans` (sans store IDs ni id interne).
class PlanPublicResponse {
  PlanPublicResponse({
    required this.code,
    required this.name,
    required this.billingCycle,
    required this.price,
    required this.originalPrice,
    required this.moduleAccess,
    required this.durationDays,
  });

  final String code;
  final String name;
  final BillingCycle billingCycle;
  final double price;
  final double? originalPrice;
  final ModuleAccess moduleAccess;
  final int durationDays;

  factory PlanPublicResponse.fromJson(Map<String, dynamic> json) {
    return PlanPublicResponse(
      code: json['code'] as String,
      name: json['name'] as String,
      billingCycle: BillingCycleParse.fromString(json['billingCycle'] as String?),
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      moduleAccess: ModuleAccessParse.fromString(json['moduleAccess'] as String?),
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
    );
  }

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
  });

  final bool isPremium;
  final SubscriptionSource? source;
  final String? productId;
  final DateTime? expiresAt;
  final SubscriptionStatus? status;
  final ModuleAccess moduleAccess;
  final bool autoRenew;

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
  });

  final SubscriptionSource source;
  final String receipt;
  final String productId;

  Map<String, dynamic> toJson() => {
        'source': source.backendName,
        'receipt': receipt,
        'productId': productId,
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
