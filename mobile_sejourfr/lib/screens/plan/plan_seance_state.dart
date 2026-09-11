import '../../core/models/diagnostic_models.dart';

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
