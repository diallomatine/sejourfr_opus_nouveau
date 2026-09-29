import '../models/attempt_models.dart';
import '../models/civic_plan_models.dart';
import 'api_client.dart';

/// **Le plan civique** (L10, `20_` §6).
///
/// 🛑 **Il n'y a pas de « recompute ».** Le plan est un dérivé relu à chaque
/// appel côté serveur : recalculer, c'est relire. Aucune table de progression
/// n'existe, et c'est ce qui rend le tagging rétroactif.
abstract interface class CivicPlanGateway {
  Future<CivicPlan> plan();

  /// Ouvre la **série ciblée** d'une cible. 🛑 **403 sans abonnement**.
  Future<Attempt> serie(String cibleId, CivicPlanGrain grain);

  /// Ouvre la série d'une **unité officielle**, par son code.
  Future<Attempt> serieSurUnite(String uniteCode);
}

class CivicPlanRepository implements CivicPlanGateway {
  CivicPlanRepository(this._client);

  final ApiClient _client;

  /// 🛑 **Jamais `null`** : sans diagnostic terminé, la réponse porte
  /// `disponible: false`. L'écran a besoin de savoir *pourquoi* il n'a rien à
  /// montrer pour ouvrir la porte qui débloque.
  @override
  Future<CivicPlan> plan() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/api/me/civic-plan');
    return CivicPlan.fromJson(res.data!);
  }

  /// C'est un `TRAINING` ordinaire : le front l'ouvre dans le runner existant.
  ///
  /// 🛑 Le **403** est la même règle que le `locked` servi, cette fois
  /// opposable : à router vers l'offre par `showPaywallOrError`, jamais à
  /// afficher en erreur technique.
  @override
  Future<Attempt> serie(String cibleId, CivicPlanGrain grain) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/me/civic-plan/cibles/$cibleId/serie',
      queryParameters: {'grain': grain.wire},
    );
    return Attempt.fromJson(res.data!);
  }

  /// Ouvre la série d'une **UNITÉ OFFICIELLE** — l'action d'une étape du
  /// **cycle** civique (D-48, P8.7).
  ///
  /// 🛑 **Par CODE** (`P2_LAICITE`), l'identifiant stable du référentiel, celui
  /// que le contrat sert déjà dans `JourneyUniteRef`. Deux grains, deux routes :
  /// une cible du plan dérivé est une **notion**, une étape du cycle est une
  /// **unité de l'arrêté**.
  ///
  /// 🛑 **403 sans abonnement** (D-33), à router vers l'offre.
  @override
  Future<Attempt> serieSurUnite(String uniteCode) async {
    final res = await _client.dio.post<Map<String, dynamic>>(
      '/api/me/civic-plan/unites/$uniteCode/serie',
    );
    return Attempt.fromJson(res.data!);
  }
}
