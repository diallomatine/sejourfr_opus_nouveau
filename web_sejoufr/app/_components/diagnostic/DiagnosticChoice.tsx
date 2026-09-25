"use client";

import Link from "next/link";
import {ArrowLeft, ArrowRight, Landmark, Languages} from "lucide-react";
import {
  type DiagnosticExerciseMeasure,
  diagnosticExpressionMinutes,
} from "@/lib/diagnostic";
import {CIVIC_DIAGNOSTIC_HUB_HREF, CIVIC_EXAM_QUESTIONS} from "@/lib/civic-diagnostic";
import {DIAGNOSTIC_DISCLAIMER, DIAGNOSTIC_OUTCOMES} from "./diagnostic-outcomes";
import styles from "./diagnostic-choice.module.css";

/**
 * Entrée du diagnostic pour un **visiteur** : il y choisit un EXAMEN, TCF IRN
 * ou examen civique. C'est là qu'arrive « Tester mon niveau » du header.
 *
 * 🛑 **Les deux se passent SANS COMPTE** (`V053`, arbitrage du propriétaire du
 * 2026-09-10) : le TCF garde ses productions sur l'appareil, le civique joue un
 * attempt invité qu'une inscription *adopte*. Le compte n'arrive qu'au moment
 * de VOIR le résultat — d'où le badge sur les deux cartes, jamais sur une
 * seule (une seule carte « Sans compte » laisse croire que l'autre en exige
 * un).
 *
 * 🛑 **Aucun chiffre écrit ici.** La durée et le nombre de productions TCF se
 * dérivent des sujets servis par `GET /api/public/diagnostics/current` (le diagnostic
 * rapide n'a pas d'oral depuis V050 : `oral === null`) ; les 40 questions
 * civiques sont `CIVIC_EXAM_QUESTIONS`, miroir de `CivicExamFormat`.
 *
 * Miroir mobile : `widgets/diagnostic_choice.dart`, texte pour texte.
 */
export function DiagnosticChoice({
  written,
  oral,
  error,
  onStartTcf,
}: {
  written: DiagnosticExerciseMeasure;
  oral: DiagnosticExerciseMeasure | null;
  error: string | null;
  /** Lance le diagnostic **TCF** sur place. Le civique, lui, est un lien. */
  onStartTcf: () => void;
}) {
  const minutes = diagnosticExpressionMinutes(written, oral);
  // Le rapide ne porte qu'une production écrite ; un sujet oral servi en ajoute
  // une seconde. Le compte se lit sur le contenu servi, jamais sur un réglage.
  const tcfPills = [
    minutes == null ? null : `≈ ${minutes} min`,
    oral ? "2 productions" : "1 production écrite",
    "Résultat personnalisé",
  ].filter((pill): pill is string => pill != null);
  const civicPills = [`${CIVIC_EXAM_QUESTIONS} questions`, "Format de l'examen", "Résultat clair"];

  return (
    <main className={styles.page}>
      <Link href="/" className={styles.back}>
        <ArrowLeft size={16} aria-hidden /> Accueil
      </Link>

      <header className={styles.hero}>
        <p className={styles.eyebrow}>Diagnostic gratuit</p>
        <h1>Que préparez-vous&nbsp;?</h1>
        <p>Choisissez votre examen. Vous commencez immédiatement, sans compte.</p>
      </header>

      {error && <p className={styles.error} role="alert">{error}</p>}

      <section className={styles.choices} aria-label="Choisir un diagnostic">
        <article className={`${styles.card} ${styles.cardPrimary}`}>
          <div className={styles.cardTop}>
            <span className={styles.icon} aria-hidden>
              <Languages size={23} />
            </span>
            <span className={styles.badge}>Sans compte</span>
          </div>
          <h2>TCF IRN</h2>
          <p className={styles.desc}>
            {oral
              ? "Évaluez rapidement votre niveau à partir d’une production écrite et d’un court enregistrement oral."
              : "Évaluez rapidement votre niveau à partir d’une courte production écrite."}
          </p>
          <ul className={styles.meta}>
            {tcfPills.map((pill) => (
              <li key={pill}>{pill}</li>
            ))}
          </ul>
          <button className={`${styles.cta} ${styles.ctaPrimary}`} type="button" onClick={onStartTcf}>
            <span>Commencer le diagnostic</span>
            <ArrowRight size={18} aria-hidden />
          </button>
        </article>

        <article className={styles.card}>
          <div className={styles.cardTop}>
            <span className={styles.icon} aria-hidden>
              <Landmark size={23} />
            </span>
            <span className={styles.badge}>Sans compte</span>
          </div>
          <h2>Examen civique</h2>
          <p className={styles.desc}>
            Testez vos connaissances avec un questionnaire au format de l’examen.
          </p>
          <ul className={styles.meta}>
            {civicPills.map((pill) => (
              <li key={pill}>{pill}</li>
            ))}
          </ul>
          <Link className={`${styles.cta} ${styles.ctaSecondary}`} href={CIVIC_DIAGNOSTIC_HUB_HREF}>
            <span>Commencer le diagnostic</span>
            <ArrowRight size={18} aria-hidden />
          </Link>
        </article>
      </section>

      {/* 🛑 Le compte sert à VOIR le résultat, pas seulement à le conserver :
          l'analyse TCF ne part qu'après l'inscription, et le résultat civique
          ne s'affiche qu'au compte (V053). */}
      <p className={styles.note}>
        <span className={styles.dot} aria-hidden />
        <span>
          Le compte n’est demandé qu’à la fin, pour voir votre résultat et conserver
          votre plan.
        </span>
      </p>

      <section className={styles.strip} aria-label="Ce que vous obtenez">
        {DIAGNOSTIC_OUTCOMES.map((outcome) => (
          <div key={outcome.title}>
            <strong>{outcome.title}</strong>
            <span>{outcome.text}</span>
          </div>
        ))}
      </section>

      <p className={styles.disclaimer}>{DIAGNOSTIC_DISCLAIMER}</p>
    </main>
  );
}
