"use client";

import {useEffect, useState} from "react";
import {ArrowRight, BookOpen, Check, Clock3, FilePenLine, Headphones, Mic} from "lucide-react";
import {diagnosticApi} from "@/lib/api";
import {
  type DiagnosticExerciseContent,
  type DiagnosticExerciseMeasure,
  diagnosticExpressionMinutes,
  diagnosticOralMeasureLabel,
  diagnosticWrittenMeasureLabel,
} from "@/lib/diagnostic";
import type {PublicDiagnosticResponse} from "@/lib/types";
import styles from "./diagnostic.module.css";

/**
 * Le parcours choisi à l'entrée du diagnostic.
 *
 * 🛑 **Il n'est PERSISTÉ NULLE PART** — ni en base, ni sur l'appareil, ni dans
 * l'URL. Le backend a tranché : le profil réel se lit sur les **domaines
 * mesurés** (`LearningPlanDto.cycle` + `domainesAEvaluer`), jamais sur une
 * intention ; et au moment du choix le candidat est encore invité, il n'existe
 * aucune ligne pour la porter.
 *
 * Concrètement, `RAPIDE` et `COMPLET` sont **le même parcours d'écrans** :
 * expression écrite, puis expression orale, puis le compte, puis l'analyse. La
 * variante ne décide que de **ce que le front enchaîne après le rapport** —
 * proposer immédiatement de mesurer CO puis CE, ou renvoyer au Plan.
 *
 * Elle vit donc en mémoire, portée par `DiagnosticView` (au-dessus de la
 * bascule invité ⇄ connecté, pour survivre à l'inscription en place et au
 * sign-in Google, qui s'ouvre en popup). Un rechargement de page la ramène à
 * `RAPIDE` : sans conséquence, le rapport propose de toute façon de compléter
 * le profil à partir de `domainesAEvaluer`.
 */
/**
 * Ce que la présentation dit des deux épreuves de COMPRÉHENSION, qui ne sont
 * pas dans le diagnostic rapide.
 *
 * 🛑 **Jamais « un examen blanc »** — c'était le mot employé ici, et
 * `docs/regles/diagnostic-tcf-4-epreuves.md` l'interdit (`10_SEJOURFR_TCF.md`
 * §4.1 : « Nommage imposé : *Diagnostic TCF — 4 épreuves*. Interdit d'appeler
 * cela un examen blanc »). Les deux objets ne se ressemblent même pas : le
 * diagnostic réduit CO et CE à 15 items pour situer le candidat, l'examen blanc
 * intégral les joue au format réel. Le nommer correctement est aussi ce qui
 * rend la promesse tenable : ce qui suit le rapport, c'est le diagnostic
 * complet.
 */
const DIAGNOSTIC_LATER_NOTE = "Dans le diagnostic complet, après votre compte.";

const FOOT_NOTE =
  "Votre diagnostic reste accessible ensuite : vous pouvez compléter les épreuves manquantes quand vous voulez.";

/**
 * Les deux sujets vus par l'écran de présentation. Un compte qui n'a pas encore
 * de session (`NOT_STARTED`) n'en reçoit aucun : le serveur ne les attache qu'à
 * partir de `POST /api/diagnostics`. On relit alors le **catalogue public**, la
 * seule route qui sert les sujets sans session — sinon le visiteur lirait ses
 * mesures et le compte connecté n'en verrait aucune.
 */
function useIntroMeasures(
  written: DiagnosticExerciseContent | null | undefined,
  oral: DiagnosticExerciseContent | null | undefined,
): {written: DiagnosticExerciseMeasure | null; oral: DiagnosticExerciseMeasure | null} {
  const [fallback, setFallback] = useState<PublicDiagnosticResponse | null>(null);
  // 🛑 Seul l'ÉCRIT manquant déclenche le repli. Depuis L3, un oral nul est une
  // FORME légitime (le diagnostic rapide n'en a pas) : le tester ici ferait
  // partir un appel réseau à chaque affichage, pour rapporter le même `null`.
  const missing = written == null;

  useEffect(() => {
    if (!missing || fallback) return;
    let alive = true;
    // Confort d'affichage : un échec laisse simplement la présentation sans
    // chiffre, il ne doit jamais empêcher de commencer.
    diagnosticApi
      .publicCurrent()
      .then((subjects) => {
        if (alive) setFallback(subjects);
      })
      .catch(() => undefined);
    return () => {
      alive = false;
    };
  }, [missing, fallback]);

  return {
    written: written ?? fallback?.written ?? null,
    oral: oral ?? fallback?.oral ?? null,
  };
}

function minutesLabel(minutes: number | null): string | null {
  return minutes == null ? null : `≈ ${minutes} min`;
}

/**
 * Présentation du diagnostic TCF pour un **compte connecté**.
 *
 * 🛑 **Le visiteur ne passe plus par ici** (2026-09-26) : son entrée est le
 * choix d'examen TCF ⇄ civique, `DiagnosticChoice`. Un compte connecté a déjà
 * choisi son parcours — il arrive depuis le Plan TCF ou l'Accueil TCF (souvent
 * avec `?demarrer=1`, qui saute cet écran) : on ne lui rouvre pas le choix, et
 * le diagnostic civique garde ses propres portes (`planIndisponible`, Accueil
 * et Plan civiques). Miroir mobile : `DiagnosticIntro` / `DiagnosticChoice`.
 */
export function DiagnosticIntro({
  error,
  submitting,
  written,
  oral,
  onStart,
}: {
  error: string | null;
  submitting: boolean;
  written?: DiagnosticExerciseContent | null;
  oral?: DiagnosticExerciseContent | null;
  onStart: () => void;
}) {
  const measures = useIntroMeasures(written, oral);
  const express = diagnosticExpressionMinutes(measures.written, measures.oral);

  return (
    <section className={styles.intro}>
      <p className={styles.eyebrow}>Diagnostic</p>
      <h1>Quel examen préparez-vous&nbsp;?</h1>
      <p className={styles.lead}>
        Les deux diagnostics sont gratuits. Choisissez celui qui correspond à
        votre démarche&nbsp;; vous pourrez faire l&apos;autre plus tard.
      </p>

      {error && <p className={styles.error} role="alert">{error}</p>}

      <div className={styles.choice}>
        <article className={`${styles.choiceCard} ${styles.choiceCardReco}`}>
          <div className={styles.choiceHead}>
            <h2>
              <span aria-hidden>🇫🇷</span> TCF IRN
            </h2>
            <span className={styles.choiceBadge}>Sans compte</span>
          </div>
          <p className={styles.choiceMeta}>
            <span>
              {measures.oral
                ? "Expression écrite + expression orale"
                : "Une production écrite"}
            </span>
            {minutesLabel(express) && (
              <span>
                <Clock3 size={14} aria-hidden /> {minutesLabel(express)}
              </span>
            )}
          </p>
          <ul className={styles.choiceList}>
            <li>
              <Check size={15} strokeWidth={2.8} aria-hidden /> Une estimation de
              votre niveau, sur ce que vous savez réellement produire
            </li>
            <li>
              <Check size={15} strokeWidth={2.8} aria-hidden /> Ce qu&apos;il faut
              travailler pour atteindre votre objectif
            </li>
            <li>
              <Check size={15} strokeWidth={2.8} aria-hidden /> Vous commencez à
              écrire tout de suite
            </li>
          </ul>
          <button
            className={styles.primaryButton}
            type="button"
            disabled={submitting}
            onClick={onStart}
          >
            {submitting ? "Préparation…" : "Commencer le diagnostic TCF"}
            {!submitting && <ArrowRight size={17} aria-hidden />}
          </button>
        </article>

      </div>

      <p className={styles.introBandTitle}>Ce que contient le diagnostic TCF</p>
      <ul className={styles.introList}>
        <li>
          <span className={styles.introIcon} aria-hidden>
            <FilePenLine size={18} />
          </span>
          <div>
            <p className={styles.introHead}>
              <b>Écrit</b>
              <span>{diagnosticWrittenMeasureLabel(measures.written) ?? "un court texte"}</span>
            </p>
            <p className={styles.introNote}>Vous rédigez un court texte.</p>
          </div>
        </li>
        {/* 🛑 L'étape orale n'est annoncée que si elle existe : promettre un
            enregistrement qui n'arrivera pas fausse l'engagement du candidat
            dès la première seconde. */}
        {measures.oral && (
          <li>
            <span className={styles.introIcon} aria-hidden>
              <Mic size={18} />
            </span>
            <div>
              <p className={styles.introHead}>
                <b>Oral</b>
                <span>
                  {diagnosticOralMeasureLabel(measures.oral) ?? "un court enregistrement"}
                </span>
              </p>
              <p className={styles.introNote}>
                Vous vous enregistrez, sans conversation en direct.
              </p>
            </div>
          </li>
        )}
        <li className={styles.introListLater}>
          <span className={styles.introIcon} aria-hidden>
            <Headphones size={18} />
          </span>
          <div>
            <p className={styles.introHead}>
              <b>Compréhension orale</b>
              <span>parcours complet</span>
            </p>
            <p className={styles.introNote}>{DIAGNOSTIC_LATER_NOTE}</p>
          </div>
        </li>
        <li className={styles.introListLater}>
          <span className={styles.introIcon} aria-hidden>
            <BookOpen size={18} />
          </span>
          <div>
            <p className={styles.introHead}>
              <b>Compréhension écrite</b>
              <span>parcours complet</span>
            </p>
            <p className={styles.introNote}>{DIAGNOSTIC_LATER_NOTE}</p>
          </div>
        </li>
      </ul>

      <p className={styles.introReassurance}>
        Pas besoin d&apos;être parfait. Répondez naturellement : l&apos;objectif est simplement
        d&apos;estimer votre niveau et de construire votre plan.
      </p>
      <p className={styles.disclaimer}>
        {FOOT_NOTE} Estimation d&apos;entraînement, non officielle.
      </p>
    </section>
  );
}
