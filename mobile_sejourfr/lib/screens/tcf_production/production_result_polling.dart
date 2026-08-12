import '../../core/models/enums.dart';
import '../../core/models/production_models.dart';
import 'widgets/action_plan.dart';

/// Cadence et budget du polling d'un resultat de production (EE comme EO).
///
/// Les deux ecrans de resultat les recopiaient a l'identique ; ils vivent ici
/// avec la regle qui decide quand un tirage de plus est justifie, pour que
/// l'ecrit et l'oral ne puissent pas diverger.
const Duration kProductionPollInterval = Duration(seconds: 3);

/// Borne **dure** : protege d'une evaluation bloquee cote serveur. Le sursis
/// accorde au plan d'action s'y ajoute, il ne la remplace pas.
const Duration kProductionPollMaxDuration = Duration(seconds: 90);

/// Decide, tirage apres tirage, si le polling d'une soumission continue — et
/// s'il faut annoncer au candidat que son plan d'action arrive.
///
/// Deux raisons de continuer, dans cet ordre :
/// 1. la correction n'est pas finie (`SUBMITTED` / `TRANSCRIBING` /
///    `EVALUATING`) — le comportement historique, inchange ;
/// 2. elle vient de finir **sous les yeux du candidat** et son plan d'action
///    (`version_ciblee`, ou son cas exclusif `niveau_vise_atteint`) n'est pas
///    encore la. Ce bloc vient d'un SECOND appel LLM, lance par le serveur
///    apres que la correction est persistee : s'arreter net sur `EVALUATED`
///    affichait un rapport sans plan alors qu'il arrivait dix a quinze secondes
///    plus tard, et le candidat devait sortir puis revenir. On prolonge donc de
///    [kActionPlanGrace], a la meme cadence.
///
/// ⚠️ [_observedInFlight] est ce qui interdit d'attendre — et d'afficher
/// [ActionPlanPending] — sur un rapport **rouvert plus tard** : la, plus rien
/// ne tourne cote serveur, le plan est deja persiste ou definitivement absent.
/// Une correction de trois jours ne doit ni poller, ni annoncer des conseils
/// qui ne viendront pas.
///
/// L'absence de plan a la fin du sursis est un cas **normal** (objectif deja
/// atteint, oral degrade, second appel muet) : l'ecran se rend tel quel, sans
/// message et sans erreur.
class ProductionResultPollGuard {
  final DateTime _startedAt = DateTime.now();

  DateTime? _actionPlanDeadline;
  bool _observedInFlight = false;
  bool _awaitsActionPlan = false;

  /// `true` tant que le sursis court : la place du plan porte son indicateur.
  bool get awaitsActionPlan => _awaitsActionPlan;

  /// `true` quand un tirage de plus est justifie. Met a jour
  /// [awaitsActionPlan] au passage — un seul appel par tirage.
  bool shouldPoll(ProductionSubmissionDto? submission) {
    if (DateTime.now().difference(_startedAt) > kProductionPollMaxDuration) {
      _awaitsActionPlan = false;
      return false;
    }
    if (submission == null) return true;
    if (!submission.statut.isFinal) {
      _observedInFlight = true;
      _awaitsActionPlan = false;
      return true;
    }
    final planMayArrive = _planMayStillArrive(submission);
    final changeMayArrive = _planChangeMayStillArrive(submission);
    if (!planMayArrive && !changeMayArrive) {
      _awaitsActionPlan = false;
      return false;
    }
    final deadline =
        _actionPlanDeadline ??= DateTime.now().add(kActionPlanGrace);
    final withinGrace = DateTime.now().isBefore(deadline);
    // L'indicateur d'attente ne concerne QUE le plan d'action : un Plan
    // inchange est un cas normal, il n'y a rien a annoncer au candidat.
    _awaitsActionPlan = planMayArrive && withinGrace;
    return withinGrace;
  }

  /// Ce que la production change dans le Plan vient d'un appel encore PLUS
  /// TARDIF que le plan d'action (les observations sont ecrites apres lui). On
  /// le laisse arriver **dans le sursis deja accorde** — meme echeance, donc
  /// pas une seconde de polling de plus qu'avant — et **sans indicateur
  /// d'attente** : un Plan inchange ne se signale pas.
  bool _planChangeMayStillArrive(ProductionSubmissionDto submission) =>
      _observedInFlight &&
      submission.statut == SubmissionStatut.evaluated &&
      submission.planChange == null;

  /// La correction s'est achevee sous les yeux du candidat et ni le plan ni son
  /// cas exclusif ne sont arrives : le second appel peut encore aboutir.
  bool _planMayStillArrive(ProductionSubmissionDto submission) {
    final feedback = submission.evaluation?.feedback;
    return _observedInFlight &&
        submission.statut == SubmissionStatut.evaluated &&
        feedback != null &&
        feedback.versionCiblee == null &&
        feedback.niveauViseAtteint == null;
  }
}
