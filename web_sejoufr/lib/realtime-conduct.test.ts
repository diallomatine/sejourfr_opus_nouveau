// Conduite de l'examinateur temps réel : les 9 cas du §4.4 de
// `docs/examinateur-ia/spec-corrections-examinateur-ia.md`, sans réseau, sur une
// horloge simulée. Exception à « aucun nouveau test front » accordée par le
// propriétaire pour ce chantier (DECISIONS D-02). Miroir cas pour cas :
// `mobile_sejourfr/test/realtime_conduct_test.dart`.
import assert from "node:assert/strict";
import test from "node:test";
import {ConductController, resumePrimer} from "./realtime/conduct.ts";
import {FALLBACK_CONDUCT as C} from "./realtime/conduct-config.ts";
import type {RealtimeConductEvent} from "./types.ts";

function harness(targetSec = 180) {
    let now = 0;
    let seq = 0;
    let energy = false;
    const timers = new Map<number, {at: number; fn: () => void}>();
    const sent: {t: number; text: string}[] = [];
    const events: RealtimeConductEvent[] = [];
    const state = {muted: -1, closed: -1};
    const clock = {
        now: () => now,
        setTimeout: (fn: () => void, ms: number) => {
            const id = ++seq;
            timers.set(id, {at: now + ms, fn});
            return id;
        },
        clearTimeout: (handle: unknown) => {
            timers.delete(handle as number);
        },
    };
    const c = new ConductController(
        C,
        clock,
        {
            sendText: (text) => sent.push({t: now, text}),
            muteCandidate: () => {
                state.muted = now;
            },
            close: () => {
                state.closed = now;
            },
            recordEvent: (e) => events.push(e),
        },
        targetSec,
        () => now,
        () => energy,
    );
    function advance(ms: number) {
        const end = now + ms;
        for (;;) {
            let next: [number, {at: number; fn: () => void}] | null = null;
            for (const e of timers) if (e[1].at <= end && (!next || e[1].at < next[1].at)) next = e;
            if (!next) break;
            timers.delete(next[0]);
            now = next[1].at;
            next[1].fn();
        }
        now = end;
    }
    return {
        c,
        sent,
        events,
        state,
        advance,
        setEnergy: (v: boolean) => {
            energy = v;
        },
    };
}

test("1. échéance, candidat silencieux : [FIN] immédiat, puis clôture TIME_UP", () => {
    const h = harness();
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(3000);
    h.c.timeUp();
    assert.deepEqual(h.sent, [{t: 3000, text: "[FIN]"}]);
    assert.equal(h.state.muted, 3000);
    h.c.examinerSpeakingChanged(true);
    h.advance(2000);
    h.c.examinerSpeakingChanged(false);
    h.advance(1200);
    assert.equal(h.state.closed, 6200);
});

test("2. échéance, le candidat parle et finit en 4 s : micro ouvert 4 s, puis [FIN]", () => {
    const h = harness();
    h.c.candidateVoiceChanged(true);
    h.c.timeUp();
    assert.equal(h.sent.length, 0);
    assert.equal(h.state.muted, -1);
    h.advance(4000);
    h.c.candidateVoiceChanged(false);
    assert.deepEqual(h.sent, [{t: 4000, text: "[FIN]"}]);
    assert.equal(h.state.muted, 4000);
    assert.deepEqual(h.events.map((e) => [e.type, e.valueMs]), [["TIMEUP_GRACE", 4000]]);
});

test("3. échéance, le candidat parle plus de 10 s : coupure à 10 s, puis [FIN]", () => {
    const h = harness();
    h.c.candidateVoiceChanged(true);
    h.c.timeUp();
    h.advance(15000);
    assert.deepEqual(h.sent, [{t: 10000, text: "[FIN]"}]);
    assert.equal(h.state.muted, 10000);
    assert.equal(h.events[0].valueMs, 10000);
});

test("4. échéance pendant que l'examinateur parle : [FIN] après la fin de sa lecture", () => {
    const h = harness();
    h.c.examinerSpeakingChanged(true);
    h.c.timeUp();
    h.advance(3000);
    assert.equal(h.sent.length, 0);
    h.c.examinerSpeakingChanged(false);
    assert.deepEqual(h.sent, [{t: 3000, text: "[FIN]"}]);
});

test("5. 7 s de silence après l'examinateur : une relance [SILENCE]", () => {
    const h = harness();
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(7000);
    assert.deepEqual(h.sent, [{t: 7000, text: "[SILENCE]"}]);
    assert.deepEqual(h.events.map((e) => e.type), ["SILENCE_RELANCE"]);
});

test("6. silence prolongé : deux relances au maximum, le compteur repart après une prise de parole", () => {
    const h = harness();
    for (let i = 0; i < 4; i++) {
        h.c.examinerSpeakingChanged(true);
        h.advance(2000);
        h.c.examinerSpeakingChanged(false);
        h.advance(8000);
    }
    assert.equal(h.sent.filter((s) => s.text === "[SILENCE]").length, 2);
    h.c.candidateVoiceChanged(true);
    h.c.candidateVoiceChanged(false);
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(7000);
    assert.equal(h.sent.filter((s) => s.text === "[SILENCE]").length, 3);
});

test("7. le candidat parle à 6,9 s : aucune relance (ni quand l'énergie monte au moment de l'expiration)", () => {
    const h = harness();
    h.c.examinerSpeakingChanged(true);
    h.c.examinerSpeakingChanged(false);
    h.advance(6900);
    h.c.candidateVoiceChanged(true);
    h.advance(5000);
    assert.equal(h.sent.length, 0);

    const course = harness();
    course.c.examinerSpeakingChanged(true);
    course.c.examinerSpeakingChanged(false);
    course.advance(6950);
    course.setEnergy(true);
    course.advance(100);
    assert.equal(course.sent.length, 0);
});

test("8. silence dans les 15 dernières secondes : aucune relance", () => {
    const tombeDedans = harness();
    tombeDedans.c.tick(20);
    tombeDedans.c.examinerSpeakingChanged(true);
    tombeDedans.c.examinerSpeakingChanged(false);
    tombeDedans.advance(10000);
    assert.equal(tombeDedans.sent.length, 0, "la relance tomberait à 13 s de la fin");

    const dejaDedans = harness();
    dejaDedans.c.tick(14);
    dejaDedans.c.examinerSpeakingChanged(true);
    dejaDedans.c.examinerSpeakingChanged(false);
    dejaDedans.advance(10000);
    assert.equal(dejaDedans.sent.length, 0);

    const temoin = harness();
    temoin.c.tick(30);
    temoin.c.examinerSpeakingChanged(true);
    temoin.c.examinerSpeakingChanged(false);
    temoin.advance(7000);
    assert.equal(temoin.sent.length, 1, "à 23 s de la fin, la relance part");
});

test("9. reconnexion sans handle : [REPRISE] + 3 derniers tours, pas d'ouverture", () => {
    const lines = [
        {speaker: "EXAMINER" as const, text: "Bonjour. Nous commençons la première partie. Pouvez-vous vous présenter, s'il vous plaît ?"},
        {speaker: "CANDIDATE" as const, text: "Je m'appelle Karim."},
        {speaker: "EXAMINER" as const, text: "D'accord. Vous travaillez ?"},
        {speaker: "CANDIDATE" as const, text: "Oui, à Lille."},
    ];
    const primer = resumePrimer(C, lines);
    assert.equal(
        primer,
        "[REPRISE]\nCandidat : Je m'appelle Karim.\nExaminateur : D'accord. Vous travaillez ?\nCandidat : Oui, à Lille.",
    );
    assert.ok(!primer.includes("Nous commençons"));
    assert.equal(resumePrimer({...C, resume: {message: "", contextTurns: 0}}, lines), "");
});
