"use client";

import Link from "next/link";
import {useEffect, useState} from "react";
import {ArrowRight, BookOpen, Check, Clock3, FilePenLine, Headphones, Mic} from "lucide-react";
import {diagnosticApi} from "@/lib/api";
import {
  type DiagnosticExerciseContent,
  type DiagnosticExerciseMeasure,
  diagnosticOralMeasureLabel,
  diagnosticOralMinutes,
  diagnosticWrittenMeasureLabel,
  diagnosticWrittenMinutes,
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
 * Le format du diagnostic civique, tel que cet écran l'annonce.
 *
 * 🛑 **40, comme l'épreuve** : c'est ce qui rend le résultat directement
 * comparable au seuil, sans projection. Recopié ici parce que l'écran est rendu
 * avant tout appel civique — mais il ne doit jamais diverger de la
 * configuration serveur (`sejourfr.civic-diagnostic`).
 */
const CIVIQUE_DIAGNOSTIC_QUESTIONS = 40;
const CIVIQUE_DIAGNOSTIC_HREF = "/diagnostic-civique";

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

/** Le temps des deux productions, dérivé des sujets servis. `null` quand la
 *  base ne porte aucune borne : on n'invente pas une durée. */
function expressionMinutes(
  written: DiagnosticExerciseMeasure | null,
  oral: DiagnosticExerciseMeasure | null,
): number | null {
  const total = (diagnosticWrittenMinutes(written) ?? 0) + (diagnosticOralMinutes(oral) ?? 0);
  return total > 0 ? total : null;
}

function minutesLabel(minutes: number | null): string | null {
  return minutes == null ? null : `≈ ${minutes} min`;
}

/**
 * Écran d'entrée du diagnostic, **identique pour un visiteur et pour un
 * compte** : c'est le même parcours, seul le moment où l'on demande le compte
 * change.
 *
 * Deux cartes, comme la maquette. Elles ne mènent pas à deux tunnels : elles
 * annoncent deux ambitions, et c'est l'après-rapport qui diffère.
 */
/**
 * Écran d'entrée du diagnostic, **identique pour un visiteur et pour un
 * compte** : c'est le même parcours, seul le moment où l'on demande le compte
 * change.
 *
 * 🛑 **On choisit un EXAMEN, pas une profondeur de diagnostic.** Cet écran a
 * longtemps proposé « rapide » et « complet » — deux ambitions du seul TCF,
 * alors que le candidat prépare **deux examens obligatoires** et sait lequel il
 * passe. La profondeur du parcours TCF (rapide puis complet) se découvre
 * ensuite, sur le rapport, quand elle a un sens.
 *
 * 🛑 **Les deux se passent SANS COMPTE** (`V053`, arbitrage du propriétaire du
 * 2026-09-10) : « l'utilisateur doit pouvoir passer le diagnostic avant de créer
 * son compte, il saisit le texte ou répond au QCM et seulement après on lui
 * demande de créer son compte pour voir le résultat. » La mécanique diffère —
 * le TCF garde ses productions sur l'appareil (`50_` §3.1), le civique joue un
 * attempt invité (user NULL + IP, comme la démo) qu'une inscription *adopte* —
 * mais **la promesse faite ici est la même des deux côtés**, et les deux cartes
 * la portent.
 */
export function DiagnosticIntro({
  error,
  submitting,
  guest = false,
  written,
  oral,
  onStart,
}: {
  error: string | null;
  submitting: boolean;
  guest?: boolean;
  written?: DiagnosticExerciseContent | null;
  oral?: DiagnosticExerciseContent | null;
  /** Lance le diagnostic **TCF**. Le civique, lui, est un lien. */
  onStart: () => void;
}) {
  const measures = useIntroMeasures(written, oral);
  const express = expressionMinutes(measures.written, measures.oral);

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

        <article className={styles.choiceCard}>
          <div className={styles.choiceHead}>
            <h2>
              <span aria-hidden>🏛️</span> Examen civique
            </h2>
            {/* 🛑 « Sans compte » des DEUX côtés depuis V053. Le badge sur la
                seule carte TCF laissait croire que le civique se paie d'une
                inscription à l'entrée — ce n'est plus vrai. */}
            <span className={styles.choiceBadge}>Sans compte</span>
          </div>
          <p className={styles.choiceMeta}>
            <span>{CIVIQUE_DIAGNOSTIC_QUESTIONS} questions, le format de l&apos;examen</span>
          </p>
          <ul className={styles.choiceList}>
            <li>
              <Check size={15} strokeWidth={2.8} aria-hidden /> Les thèmes et notions
              à renforcer avant l&apos;examen
            </li>
            <li>
              <Check size={15} strokeWidth={2.8} aria-hidden /> Un résultat qui se lit
              directement sur l&apos;échelle de l&apos;épreuve
            </li>
          </ul>
          {/* 🛑 Le compte n'arrive qu'AU RÉSULTAT (V053, arbitrage du
              propriétaire du 2026-09-10) — même promesse que le TCF, et on la
              dit avant le clic. ⚠️ Cette carte a annoncé l'inverse (« Ce
              diagnostic demande un compte ») et envoyait sur
              `/inscription?next=…` : le motif invoqué — un QCM est rattaché à
              un attempt, donc à un utilisateur — était faux, l'attempt invité
              existant déjà pour la démo. Ne pas remettre le détour. */}
          <p className={styles.choiceNote}>
            Vous répondez tout de suite&nbsp;; le compte n&apos;arrive qu&apos;au
            moment de voir votre résultat.
          </p>
          <Link className={styles.secondaryButton} href={CIVIQUE_DIAGNOSTIC_HREF}>
            Commencer le diagnostic civique
            <ArrowRight size={17} aria-hidden />
          </Link>
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
            <p className={styles.introNote}>Un examen blanc, après votre compte.</p>
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
            <p className={styles.introNote}>Un examen blanc, après votre compte.</p>
          </div>
        </li>
      </ul>

      <p className={styles.introReassurance}>
        Pas besoin d&apos;être parfait. Répondez naturellement : l&apos;objectif est simplement
        d&apos;estimer votre niveau et de construire votre plan.
      </p>
      <p className={styles.disclaimer}>
        {guest
          ? `${FOOT_NOTE} Le compte ne vous sera demandé qu'au moment de l'analyse. Estimation d'entraînement, non officielle.`
          : `${FOOT_NOTE} Estimation d'entraînement, non officielle.`}
      </p>
    </section>
  );
}
