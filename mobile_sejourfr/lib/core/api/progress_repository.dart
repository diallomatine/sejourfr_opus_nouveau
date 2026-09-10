import '../models/progress_models.dart';
import 'api_client.dart';

/// **Progrès** (T28, `30_` §7) — « montrer le mouvement, pas un tableau de
/// bord ».
///
/// 🛑 **Rien n'est calculé côté app** : les paliers, les sens d'évolution, les
/// états de maîtrise et les compteurs arrivent servis.
abstract interface class ProgressGateway {
  Future<Progress> progres();
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
}
