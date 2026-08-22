import '../../core/models/diagnostic_models.dart';
import '../../core/utils/paris_day.dart';

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

/// **Cette ligne de la séance est-elle faite ?**
///
/// Deux faits **servis**, aucun marqueur local : l'étape est bouclée
/// (`stepCompleted` sur ses cinq sujets), **ou** la dernière activité sur la
/// compétence tombe aujourd'hui (**Europe/Paris**).
///
/// 🛑 C'est le front qui compare, jamais le serveur : la séance ne dépend
/// d'aucune date, et un booléen figé à la lecture serait faux le lendemain.
/// Mais la **donnée** vient du compte — la coche survit donc au redémarrage de
/// l'app et se retrouve à l'identique sur le web (`planSeanceItemDone`, même
/// règle, même ordre). Le marqueur local d'avant faisait l'inverse : il
/// s'évaporait, et le même candidat voyait deux séances différentes selon
/// l'appareil.
bool planSeanceItemDone(PlanSeanceItem item, [DateTime? now]) {
  if (item.stepPromptCount > 0 && item.stepCompleted) return true;
  final activity = item.lastActivityAt;
  if (activity == null) return false;
  return sameParisDay(activity, now ?? DateTime.now());
}
