// Conduite de l'examinateur temps réel : les 9 cas du §4.4 de
// `docs/examinateur-ia/spec-corrections-examinateur-ia.md`, sans réseau, sur une
// horloge simulée. Exception à « aucun nouveau test front » accordée par le
// propriétaire pour ce chantier (DECISIONS D-02). Miroir cas pour cas :
// `web_sejoufr/lib/realtime-conduct.test.ts`.
import 'package:flutter_test/flutter_test.dart';
import 'package:sejourfr_mobile/core/models/realtime_models.dart';
import 'package:sejourfr_mobile/core/realtime/realtime_conduct.dart';

const _c = RealtimeConductConfig.fallback;

class _FakeClock implements ConductClock {
  int now = 0;
  int _seq = 0;
  final Map<int, ({int at, void Function() fn})> timers = {};

  @override
  int nowMs() => now;

  @override
  Object setTimeout(void Function() fn, int ms) {
    final id = ++_seq;
    timers[id] = (at: now + ms, fn: fn);
    return id;
  }

  @override
  void clearTimeout(Object handle) => timers.remove(handle);

  void advance(int ms) {
    final end = now + ms;
    while (true) {
      MapEntry<int, ({int at, void Function() fn})>? next;
      for (final e in timers.entries) {
        if (e.value.at <= end && (next == null || e.value.at < next.value.at)) {
          next = e;
        }
      }
      if (next == null) break;
      timers.remove(next.key);
      now = next.value.at;
      next.value.fn();
    }
    now = end;
  }
}

class _Harness {
  _Harness({int targetSec = 180}) {
    c = ConductController(
      conduct: _c,
      clock: clock,
      actions: ConductActions(
        sendText: (text) => sent.add((t: clock.now, text: text)),
        muteCandidate: () => muted = clock.now,
        close: () => closed = clock.now,
        recordEvent: events.add,
      ),
      targetSec: targetSec,
      elapsedMs: () => clock.now,
      candidateEnergyNow: () => energy,
    );
  }

  final clock = _FakeClock();
  late final ConductController c;
  final sent = <({int t, String text})>[];
  final events = <RealtimeConductEvent>[];
  int muted = -1;
  int closed = -1;
  bool energy = false;

  void advance(int ms) => clock.advance(ms);
  int count(String text) => sent.where((s) => s.text == text).length;
}

void main() {
  test(
      '1. échéance, candidat silencieux : [FIN] immédiat, puis clôture TIME_UP',
      () {
    final h = _Harness();
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(3000);
    h.c.timeUp();
    expect(h.sent, [(t: 3000, text: '[FIN]')]);
    expect(h.muted, 3000);
    h.c.examinerSpeakingChanged(true);
    h.advance(2000);
    h.c.examinerSpeakingChanged(false);
    h.advance(1200);
    expect(h.closed, 6200);
  });

  test(
      '2. échéance, le candidat parle et finit en 4 s : micro ouvert 4 s, puis [FIN]',
      () {
    final h = _Harness();
    h.c.candidateVoiceChanged(true);
    h.c.timeUp();
    expect(h.sent, isEmpty);
    expect(h.muted, -1);
    h.advance(4000);
    h.c.candidateVoiceChanged(false);
    expect(h.sent, [(t: 4000, text: '[FIN]')]);
    expect(h.muted, 4000);
    expect(h.events.single.type, RealtimeConductEventType.timeUpGrace);
    expect(h.events.single.valueMs, 4000);
  });

  test(
      '3. échéance, le candidat parle plus de 10 s : coupure à 10 s, puis [FIN]',
      () {
    final h = _Harness();
    h.c.candidateVoiceChanged(true);
    h.c.timeUp();
    h.advance(15000);
    expect(h.sent, [(t: 10000, text: '[FIN]')]);
    expect(h.muted, 10000);
    expect(h.events.first.valueMs, 10000);
  });

  test(
      "4. échéance pendant que l'examinateur parle : [FIN] après la fin de sa lecture",
      () {
    final h = _Harness();
    h.c.examinerSpeakingChanged(true);
    h.c.timeUp();
    h.advance(3000);
    expect(h.sent, isEmpty);
    h.c.examinerSpeakingChanged(false);
    expect(h.sent, [(t: 3000, text: '[FIN]')]);
  });

  test("5. 7 s de silence après l'examinateur : une relance [SILENCE]", () {
    final h = _Harness();
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(7000);
    expect(h.sent, [(t: 7000, text: '[SILENCE]')]);
    expect(
        h.events.map((e) => e.type), [RealtimeConductEventType.silenceRelance]);
  });

  test(
      '6. silence prolongé : deux relances au maximum, le compteur repart après une prise de parole',
      () {
    final h = _Harness();
    for (var i = 0; i < 4; i++) {
      h.c.examinerSpeakingChanged(true);
      h.advance(2000);
      h.c.examinerSpeakingChanged(false);
      h.advance(8000);
    }
    expect(h.count('[SILENCE]'), 2);
    h.c.candidateVoiceChanged(true);
    h.c.candidateVoiceChanged(false);
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(7000);
    expect(h.count('[SILENCE]'), 3);
  });

  test(
      "7. le candidat parle à 6,9 s : aucune relance (ni quand l'énergie monte au moment de l'expiration)",
      () {
    final h = _Harness();
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(6900);
    h.c.candidateVoiceChanged(true);
    h.advance(5000);
    expect(h.sent, isEmpty);

    final course = _Harness();
    course.c.examinerSpeakingChanged(true);
    course.c.examinerSpeakingChanged(false);
    course.advance(6950);
    course.energy = true;
    course.advance(100);
    expect(course.sent, isEmpty);
  });

  test('8. silence dans les 15 dernières secondes : aucune relance', () {
    final tombeDedans = _Harness();
    tombeDedans.c.tick(20);
    tombeDedans.c.examinerSpeakingChanged(true);
    tombeDedans.c.examinerSpeakingChanged(false);
    tombeDedans.advance(10000);
    expect(tombeDedans.sent, isEmpty,
        reason: 'la relance tomberait à 13 s de la fin');

    final dejaDedans = _Harness();
    dejaDedans.c.tick(14);
    dejaDedans.c.examinerSpeakingChanged(true);
    dejaDedans.c.examinerSpeakingChanged(false);
    dejaDedans.advance(10000);
    expect(dejaDedans.sent, isEmpty);

    final temoin = _Harness();
    temoin.c.tick(30);
    temoin.c.examinerSpeakingChanged(true);
    temoin.c.examinerSpeakingChanged(false);
    temoin.advance(7000);
    expect(temoin.sent, hasLength(1),
        reason: 'à 23 s de la fin, la relance part');
  });

  test(
      "9. reconnexion sans handle : [REPRISE] + 3 derniers tours, pas d'ouverture",
      () {
    const lines = [
      (
        speaker: RealtimeSpeaker.examiner,
        text:
            "Bonjour. Nous commençons la première partie. Pouvez-vous vous présenter, s'il vous plaît ?",
      ),
      (speaker: RealtimeSpeaker.candidate, text: "Je m'appelle Karim."),
      (speaker: RealtimeSpeaker.examiner, text: "D'accord. Vous travaillez ?"),
      (speaker: RealtimeSpeaker.candidate, text: 'Oui, à Lille.'),
    ];
    final primer = resumePrimer(_c, lines);
    expect(
      primer,
      "[REPRISE]\nCandidat : Je m'appelle Karim.\nExaminateur : D'accord. Vous travaillez ?\nCandidat : Oui, à Lille.",
    );
    expect(primer.contains('Nous commençons'), isFalse);
    final sansReprise = RealtimeConductConfig.fromJson(const {
      'resume': {'message': '', 'contextTurns': 0}
    });
    expect(resumePrimer(sansReprise, lines), '');
  });
}
