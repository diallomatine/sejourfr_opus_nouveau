import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/diagnostic_models.dart';

/// **Ce que le candidat a déjà fait de sa séance, dans cette session d'app.**
///
/// 🛑 Ce n'est **pas** une source de vérité, et le serveur n'en connaît rien :
/// il compose la séance à partir des faits (étapes, maîtrise, jalons) et
/// **aucune date n'intervient nulle part** — « aujourd'hui » est une
/// présentation. Ce marqueur ne sert qu'à cocher visuellement une ligne qu'on
/// vient d'ouvrir, et il disparaît au redémarrage de l'app.
///
/// Il ne décide **jamais** de ce que la séance contient, ni de ce qui est
/// verrouillé, ni d'un compteur d'étape : ces trois-là restent servis.
final planSeanceDoneProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// Le verrou d'un item de séance, **lu**, jamais décidé.
///
/// ⚠ Le serveur publie `locked` à trois endroits — sur l'item, sur l'exercice
/// recommandé et sur le jalon. La ligne est verrouillée dès que l'un des trois
/// le dit ; le rang de l'item n'entre **jamais** dans le calcul. Ne pas
/// réintroduire un « à partir du 2ᵉ, cadenas » côté client : la maquette le
/// dessine comme ça parce que son bouchon n'a pas de serveur, pas parce que
/// c'est la règle.
bool planSeanceItemLocked(PlanSeanceItem item) =>
    item.locked ||
    (item.exercise?.locked ?? false) ||
    (item.milestone?.locked ?? false);

/// La clé d'un item, **stable à travers un recalcul du Plan**.
///
/// On prend la **compétence**, pas le sujet : quand le candidat termine un
/// petit sujet, le serveur désigne le suivant dans la même compétence — la clé
/// du sujet changerait et la coche disparaîtrait juste après avoir été posée.
/// Un jalon, lui, n'a pas de compétence : il s'identifie par son épreuve et son
/// slot de grille.
String planSeanceItemKey(PlanSeanceItem item) {
  final skillId = item.skillId ?? item.exercise?.skillId;
  if (skillId != null && skillId.isNotEmpty) return 'skill:$skillId';
  final milestone = item.milestone;
  if (milestone != null) {
    return 'exam:${milestone.epreuve.wire}:${milestone.slotNumber}';
  }
  return 'kind:${item.kind.wire}';
}
