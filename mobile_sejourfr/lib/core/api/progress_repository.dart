import '../models/enums.dart';
import '../models/epreuve_historique_models.dart';
import '../models/progress_models.dart';
import 'api_client.dart';

/// **Progrès** (T28, `30_` §7) — « montrer le mouvement, pas un tableau de
/// bord ».
///
/// 🛑 **Rien n'est calculé côté app** : les paliers, les sens d'évolution, les
/// états de maîtrise et les compteurs arrivent servis.
abstract interface class ProgressGateway {
  Future<Progress> progres();

  Future<EpreuveHistorique> historique(EpreuveType epreuve);
}

class ProgressRepository implements ProgressGateway {
  ProgressRepository(this._client);

  final ApiClient _client;

  /// 🛑 **Jamais `null`** : un candidat sans diagnostic reçoit
  /// `disponible: false` sur chaque moitié. L'écran a besoin de savoir
  /// *pourquoi* il n'a rien à montrer.
  @override
  Future<Progress> progres() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/api/me/progress');
    return Progress.fromJson(res.data!);
  }

  /// « D'où sort mon niveau ? » — les dernières évaluations **qualifiantes**
  /// d'une épreuve.
  ///
  /// 🛑 **Un appel à la demande**, quand le candidat ouvre une carte : il ne
  /// part pas avec l'Accueil, qui garde son appel unique.
  ///
  /// 🛑 **Jamais 404 pour une épreuve jamais mesurée** : la liste est vide.
  @override
  Future<EpreuveHistorique> historique(EpreuveType epreuve) async {
    final res = await _client.dio.get<Map<String, dynamic>>(
        '/api/me/progress/tcf/${epreuve.wire}/historique');
    return EpreuveHistorique.fromJson(res.data!);
  }
}
