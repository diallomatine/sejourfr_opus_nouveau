"use client";

import {useEffect, useState} from "react";
import {ArrowRight, Check, Clock3, FilePenLine, Mic} from "lucide-react";
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
 * 🛑 **Aucune promesse de « diagnostic complet »** : ce parcours est retiré des
 * fronts depuis le 2026-09-26. Les épreuves que ce diagnostic ne mesure pas se
 * mesurent ensuite par l'examen blanc que propose le Plan. Miroir mot pour mot
 * du pied de `diagnostic_intro.dart`.
 */
const FOOT_NOTE =
  "Votre plan vous proposera ensuite un examen blanc pour mesurer les autres épreuves.";

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
 * le diagnostic civique garde ses propres entrées (`/diagnostic-civique`,
 * lien « Mon diagnostic » du Plan civique). Miroir mobile : `DiagnosticIntro` / `DiagnosticChoice`.
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
