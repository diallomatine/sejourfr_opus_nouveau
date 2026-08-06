/// Issue d'une session EO temps réel, du point de vue du CANDIDAT.
///
/// Pourquoi ce fichier existe : la clôture (`POST /api/realtime/eo/sessions/
/// {id}/finish`) était appelée dans un `try/catch` qui, en cas d'échec,
/// laissait le drapeau « évalué » à `true`. Un envoi raté devenait
/// indistinguable d'un succès : l'examen enchaînait la tâche suivante et la
/// production du candidat disparaissait sans trace. Ici on refuse ce mensonge —
/// l'état rendu dit exactement ce qui s'est passé, y compris quand c'est une
/// mauvaise nouvelle.
///
/// Ce qu'il faut savoir du backend pour lire les règles ci-dessous
/// (`RealtimeSessionService`, lu dans le code) :
///   - le transcript est accumulé côté serveur au fil des `POST …/transcript` ;
///   - `finish` est IDEMPOTENT : rappelé sur une session encore ACTIVE, il
///     clôture et déclenche la notation normalement. Un échec réseau de la
///     clôture est donc RATTRAPABLE — à condition qu'au moins un tour candidat
///     soit arrivé jusqu'au serveur ;
///   - `evaluated=false` signifie « aucune submission créée » : côté serveur le
///     transcript ne contient aucun tour « Candidat : … ».
///
/// Miroir web : `web_sejoufr/lib/realtime-finish.ts` (mêmes règles, mêmes
/// libellés, verrouillés par un test de chaque côté).
library;

/// - [evaluated] : une submission existe, il y a un résultat à afficher.
/// - [noSpeech] : le candidat n'a rien dit — rien à évaluer, et c'est exact.
/// - [lost] : le candidat a parlé mais sa parole n'est jamais arrivée au
///   serveur. Rien à relancer : il faut le dire, pas le maquiller.
/// - [retryable] : la clôture a échoué alors que l'échange est bien côté
///   serveur. Une relance de `finish` suffit, sans refaire l'oral.
enum RealtimeFinishKind { evaluated, noSpeech, lost, retryable }

class RealtimeFinishResult {
  const RealtimeFinishResult({required this.kind, this.droppedTurns = 0});

  final RealtimeFinishKind kind;

  /// Tours de dialogue perdus par le relais best-effort (jamais arrivés).
  final int droppedTurns;

  bool get isEvaluated => kind == RealtimeFinishKind.evaluated;

  @override
  bool operator ==(Object other) =>
      other is RealtimeFinishResult &&
      other.kind == kind &&
      other.droppedTurns == droppedTurns;

  @override
  int get hashCode => Object.hash(kind, droppedTurns);

  @override
  String toString() => 'RealtimeFinishResult($kind, dropped: $droppedTurns)';
}

/// Traduit la fin d'une session en une issue honnête.
///
/// Le cas qui compte : [finishOk] faux. On ne suppose plus « évalué » — on
/// regarde si quelque chose du candidat est arrivé au serveur. Si oui la
/// clôture est rejouable ; si non, la production est perdue et on l'annonce.
RealtimeFinishResult resolveRealtimeFinish({
  required bool finishOk,
  required bool serverEvaluated,
  required int candidateTurnsSpoken,
  required int candidateTurnsRelayed,
  required int droppedTurns,
}) {
  final dropped = droppedTurns < 0 ? 0 : droppedTurns;
  if (finishOk) {
    if (serverEvaluated) {
      return RealtimeFinishResult(
          kind: RealtimeFinishKind.evaluated, droppedTurns: dropped);
    }
    // Le serveur n'a vu aucun tour candidat. Deux histoires très différentes :
    // le candidat s'est tu (exact), ou sa parole s'est perdue en route (il ne
    // faut surtout pas lui dire qu'il s'est tu).
    return RealtimeFinishResult(
      kind: candidateTurnsSpoken > 0
          ? RealtimeFinishKind.lost
          : RealtimeFinishKind.noSpeech,
      droppedTurns: dropped,
    );
  }
  if (candidateTurnsRelayed > 0) {
    return RealtimeFinishResult(
        kind: RealtimeFinishKind.retryable, droppedTurns: dropped);
  }
  return RealtimeFinishResult(
    kind: candidateTurnsSpoken > 0
        ? RealtimeFinishKind.lost
        : RealtimeFinishKind.noSpeech,
    droppedTurns: dropped,
  );
}

/// L'issue demande-t-elle une décision explicite du candidat avant de quitter
/// l'écran ? Vrai quand il y a une relance à proposer, une perte à annoncer, ou
/// une transmission partielle à signaler — jamais pour un déroulé nominal.
bool needsRealtimeAcknowledgement(RealtimeFinishResult r) {
  if (r.kind == RealtimeFinishKind.retryable ||
      r.kind == RealtimeFinishKind.lost) {
    return true;
  }
  return r.kind == RealtimeFinishKind.evaluated && r.droppedTurns > 0;
}

// Libellés — contrat gelé, recopié à l'identique côté web (même règle que les
// libellés de compétences : la chaîne ne transite pas par le réseau, donc seul
// un test par couche empêche les deux fronts de diverger).
const String kRtFinishRetryableTitle = 'Envoi impossible';
const String kRtFinishRetryableMessage =
    "Votre échange n'a pas pu être envoyé à l'évaluation. Il est conservé sur "
    "nos serveurs : réessayez, vous n'avez pas à refaire l'oral.";
const String kRtFinishLostTitle = 'Réponse non transmise';
const String kRtFinishLostMessage =
    "Votre échange n'est pas arrivé jusqu'à nous : il n'y a rien à évaluer, et "
    "il ne peut pas être récupéré. Refaites l'oral quand vous êtes prêt·e.";
const String kRtFinishPartialTitle = 'Transmission partielle';
const String kRtFinishPartialMessage =
    "Une partie de votre échange n'a pas pu être transmise. Votre évaluation "
    "portera uniquement sur ce qui nous est parvenu.";
const String kRtFinishRetryAction = "Réessayer l'envoi";
const String kRtFinishGiveUpAction = 'Continuer sans cette réponse';
const String kRtFinishSeeResultAction = 'Voir mon évaluation';

/// Titre + message du panneau à afficher pour une issue à acquitter.
({String title, String message}) realtimeFinishNotice(RealtimeFinishResult r) {
  switch (r.kind) {
    case RealtimeFinishKind.retryable:
      return (title: kRtFinishRetryableTitle, message: kRtFinishRetryableMessage);
    case RealtimeFinishKind.lost:
      return (title: kRtFinishLostTitle, message: kRtFinishLostMessage);
    case RealtimeFinishKind.evaluated:
    case RealtimeFinishKind.noSpeech:
      return (title: kRtFinishPartialTitle, message: kRtFinishPartialMessage);
  }
}
