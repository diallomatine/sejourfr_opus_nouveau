import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/api/realtime_repository.dart';
import 'package:sejourfr_mobile/core/models/enums.dart';
import 'package:sejourfr_mobile/core/models/production_models.dart';
import 'package:sejourfr_mobile/core/models/realtime_models.dart';
import 'package:sejourfr_mobile/screens/tcf_production/realtime/realtime_eo_controller.dart';
import 'package:sejourfr_mobile/screens/tcf_production/realtime/realtime_finish.dart';

/// Le défaut corrigé ici : un échec de `POST …/finish` était avalé et l'état
/// restait « évalué ». Un envoi raté devenait indistinguable d'un succès —
/// l'examen enchaînait la tâche suivante et la production disparaissait sans
/// trace. Ces tests verrouillent l'inverse : l'état dit ce qui s'est passé.
void main() {
  group('resolveRealtimeFinish', () {
    test('clôture OK et notée → résultat à afficher', () {
      final r = resolveRealtimeFinish(
        finishOk: true,
        serverEvaluated: true,
        candidateTurnsSpoken: 4,
        candidateTurnsRelayed: 4,
        droppedTurns: 0,
      );
      expect(r.kind, RealtimeFinishKind.evaluated);
      expect(needsRealtimeAcknowledgement(r), isFalse);
    });

    test('clôture OK, candidat muet → « rien à évaluer », et c\'est exact', () {
      final r = resolveRealtimeFinish(
        finishOk: true,
        serverEvaluated: false,
        candidateTurnsSpoken: 0,
        candidateTurnsRelayed: 0,
        droppedTurns: 0,
      );
      expect(r.kind, RealtimeFinishKind.noSpeech);
      expect(needsRealtimeAcknowledgement(r), isFalse);
    });

    test(
        'clôture OK mais le candidat AVAIT parlé → perdue, jamais « vous n\'avez rien dit »',
        () {
      final r = resolveRealtimeFinish(
        finishOk: true,
        serverEvaluated: false,
        candidateTurnsSpoken: 3,
        candidateTurnsRelayed: 0,
        droppedTurns: 3,
      );
      expect(r.kind, RealtimeFinishKind.lost);
      expect(needsRealtimeAcknowledgement(r), isTrue);
    });

    test('clôture en échec mais parole arrivée au serveur → relançable', () {
      final r = resolveRealtimeFinish(
        finishOk: false,
        serverEvaluated: false,
        candidateTurnsSpoken: 5,
        candidateTurnsRelayed: 5,
        droppedTurns: 0,
      );
      expect(r.kind, RealtimeFinishKind.retryable);
      expect(needsRealtimeAcknowledgement(r), isTrue);
    });

    test('clôture en échec et rien n\'est arrivé → perdue, pas de faux espoir',
        () {
      final r = resolveRealtimeFinish(
        finishOk: false,
        serverEvaluated: false,
        candidateTurnsSpoken: 2,
        candidateTurnsRelayed: 0,
        droppedTurns: 2,
      );
      expect(r.kind, RealtimeFinishKind.lost);
    });

    test('clôture en échec sans aucune prise de parole → rien à récupérer', () {
      final r = resolveRealtimeFinish(
        finishOk: false,
        serverEvaluated: false,
        candidateTurnsSpoken: 0,
        candidateTurnsRelayed: 0,
        droppedTurns: 0,
      );
      expect(r.kind, RealtimeFinishKind.noSpeech);
      expect(needsRealtimeAcknowledgement(r), isFalse);
    });

    test('notée mais transmission partielle → le candidat doit le savoir', () {
      final r = resolveRealtimeFinish(
        finishOk: true,
        serverEvaluated: true,
        candidateTurnsSpoken: 6,
        candidateTurnsRelayed: 4,
        droppedTurns: 2,
      );
      expect(r.kind, RealtimeFinishKind.evaluated);
      expect(r.droppedTurns, 2);
      expect(needsRealtimeAcknowledgement(r), isTrue);
      expect(realtimeFinishNotice(r).title, kRtFinishPartialTitle);
    });
  });

  group('libellés — contrat gelé, miroir de web_sejoufr/lib/realtime-finish.ts',
      () {
    test('les chaînes ne bougent pas sans changer les deux fronts', () {
      expect(kRtFinishRetryableTitle, 'Envoi impossible');
      expect(
        kRtFinishRetryableMessage,
        "Votre échange n'a pas pu être envoyé à l'évaluation. Il est conservé "
        "sur nos serveurs : réessayez, vous n'avez pas à refaire l'oral.",
      );
      expect(kRtFinishLostTitle, 'Réponse non transmise');
      expect(
        kRtFinishLostMessage,
        "Votre échange n'est pas arrivé jusqu'à nous : il n'y a rien à évaluer, "
        "et il ne peut pas être récupéré. Refaites l'oral quand vous êtes prêt·e.",
      );
      expect(kRtFinishPartialTitle, 'Transmission partielle');
      expect(
        kRtFinishPartialMessage,
        "Une partie de votre échange n'a pas pu être transmise. Votre "
        "évaluation portera uniquement sur ce qui nous est parvenu.",
      );
      expect(kRtFinishRetryAction, "Réessayer l'envoi");
      expect(kRtFinishGiveUpAction, 'Continuer sans cette réponse');
      expect(kRtFinishSeeResultAction, 'Voir mon évaluation');
    });
  });

  group('RealtimeEoController.finish', () {
    RealtimeEoController build(_FakeRealtimeRepository repo) =>
        RealtimeEoController(repo, _args());

    test('un finish raté N\'EST PLUS pris pour un succès', () async {
      final repo = _FakeRealtimeRepository(finishThrows: true);
      final c = build(repo);
      c.debugEnqueueTurn(RealtimeSpeaker.candidate, 'Bonjour, je m\'appelle…');
      await c.finish();

      expect(c.state.phase, RealtimePhase.done);
      expect(c.state.finishResult?.kind, RealtimeFinishKind.retryable);
      // Deux appels : la clôture est rejouée une fois automatiquement.
      expect(repo.finishCalls, 2);
      c.dispose();
    });

    test('la relance repasse la clôture et débloque le résultat', () async {
      final repo = _FakeRealtimeRepository(finishThrows: true);
      final c = build(repo);
      c.debugEnqueueTurn(RealtimeSpeaker.candidate, 'Bonjour.');
      await c.finish();
      expect(c.state.finishResult?.kind, RealtimeFinishKind.retryable);

      repo.finishThrows = false;
      await c.retryFinish();
      expect(c.state.finishResult?.kind, RealtimeFinishKind.evaluated);
      expect(c.state.retryingFinish, isFalse);
      c.dispose();
    });

    test('transcript jamais relayé + finish raté → perte annoncée, pas relance',
        () async {
      final repo =
          _FakeRealtimeRepository(finishThrows: true, appendThrows: true);
      final c = build(repo);
      c.debugEnqueueTurn(RealtimeSpeaker.candidate, 'Je travaille à Lyon.');
      await c.finish();

      expect(c.state.finishResult?.kind, RealtimeFinishKind.lost);
      c.dispose();
    });

    test('un fragment perdu rend la transmission partielle DÉTECTABLE',
        () async {
      // 3 segments (candidat / examinateur / candidat) : le 3ᵉ envoi échoue.
      // La session est bien notée, mais sur un échange amputé — et ça se dit.
      final repo = _FakeRealtimeRepository(appendFailAt: 3);
      final c = build(repo);
      c.debugEnqueueTurn(RealtimeSpeaker.candidate, 'Premier tour.');
      c.debugEnqueueTurn(RealtimeSpeaker.examiner, 'Et ensuite ?');
      c.debugEnqueueTurn(RealtimeSpeaker.candidate, 'Second tour.');
      await c.finish();

      final r = c.state.finishResult!;
      expect(r.kind, RealtimeFinishKind.evaluated);
      expect(r.droppedTurns, 1);
      expect(needsRealtimeAcknowledgement(r), isTrue);
      c.dispose();
    });

    test('candidat muet et clôture OK → aucun panneau, comportement inchangé',
        () async {
      final repo = _FakeRealtimeRepository(evaluated: false);
      final c = build(repo);
      c.debugEnqueueTurn(RealtimeSpeaker.examiner, 'Bonjour, présentez-vous.');
      await c.finish();

      expect(c.state.finishResult?.kind, RealtimeFinishKind.noSpeech);
      expect(needsRealtimeAcknowledgement(c.state.finishResult!), isFalse);
      c.dispose();
    });
  });
}

RealtimeRunnerArgs _args() => RealtimeRunnerArgs(
      descriptor: RealtimeSessionDescriptor(
        mode: RealtimeMode.realtime,
        tacheNumero: 1,
        sessionsRemaining: 4,
        sessionId: 'session-1',
        targetDurationSec: 200,
      ),
      task: ProductionTaskDto(
        id: 'task-1',
        epreuve: EpreuveType.tcfEo,
        tacheNumero: 1,
        niveauCible: 'B1',
        consigne: 'Présentez-vous.',
      ),
      attemptId: 'attempt-1',
    );

class _FakeRealtimeRepository implements RealtimeRepository {
  _FakeRealtimeRepository({
    this.finishThrows = false,
    this.appendThrows = false,
    this.appendFailAt = -1,
    this.evaluated = true,
  });

  bool finishThrows;
  bool appendThrows;

  /// Index (1-based) de l'envoi de transcript qui échoue. -1 = aucun.
  final int appendFailAt;
  bool evaluated;
  int finishCalls = 0;
  int appendCalls = 0;

  @override
  Future<void> appendTranscript({
    required String sessionId,
    required RealtimeSpeaker speaker,
    required String text,
  }) async {
    appendCalls++;
    if (appendThrows || appendCalls == appendFailAt) {
      throw Exception('relais indisponible');
    }
  }

  @override
  Future<RealtimeSessionStateResponse> finishSession(String sessionId) async {
    finishCalls++;
    if (finishThrows) throw Exception('réseau coupé');
    return RealtimeSessionStateResponse(
      sessionId: sessionId,
      status: 'COMPLETED',
      tacheNumero: 1,
      sessionsRemaining: 3,
      evaluated: evaluated,
    );
  }

  @override
  Future<RealtimeQuota> getQuota() async =>
      RealtimeQuota(remaining: 3, cap: 25);

  @override
  Future<RealtimeSessionDescriptor> startSession({
    required String productionTaskId,
    String? attemptId,
  }) async =>
      throw UnimplementedError();
}
