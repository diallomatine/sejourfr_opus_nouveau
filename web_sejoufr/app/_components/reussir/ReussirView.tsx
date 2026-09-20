"use client";

import Link from "next/link";
import {
  useEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
  type ReactElement,
} from "react";
import {
  ArrowRight,
  BookOpen,
  Check,
  Clock,
  ClipboardCheck,
  Headphones,
  Layers,
  Mic,
  PenLine,
  TrendingUp,
} from "lucide-react";
import { Cocarde, Wordmark } from "../Brand";
import { track, type AnalyticsCtaLocation } from "@/lib/analytics";
import {
  detectTrafficSource,
  withTrafficSource,
  type TrafficSource,
} from "@/lib/traffic-source";
import { diagnosticApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import {
  formatPassPrice,
  oneTimePassesOf,
  passCheckoutHref,
  passDurationLabel,
  passSessionsLabel,
  popularPassCodeOf,
  type PassModule,
} from "@/lib/passes";
import { type PlanPublicResponse } from "@/lib/types";
import styles from "./reussir.module.css";

/**
 * Landing autoportante (`/reussir`) — lien de bio réseaux et pages de campagne.
 *
 * 🛑 Portage 1:1 de la maquette de référence fournie par le propriétaire
 * (`sejourfr-landing-optimisee-conversion.html`) : structure, contenu texte,
 * ordre des sections et style visuel. La refonte du 2026-08-17 (page
 * « sans texte », un seul `.lead`) est **révoquée pour cette page** — la
 * maquette est la source de vérité du contenu, comme demandé.
 *
 * Ce qui NE change PAS, parce que ce sont des règles produit qui priment sur
 * une maquette statique :
 *  · aucun prix n'est écrit en dur — les 2 pass viennent de
 *    `GET /api/billing/plans` (`lib/passes.ts`) ;
 *  · le TCF et l'examen civique ne sont JAMAIS mélangés dans un même CTA — la
 *    maquette a un CTA générique « /test » commun aux deux diagnostics, ici il
 *    y en a deux, un par examen, chacun vers sa vraie route
 *    (`/diagnostic`, `/diagnostic-civique`) ;
 *  · chaque lien `/test` de la maquette est résolu vers sa route réelle.
 *
 * Chiffres du format d'examen, jamais une estimation :
 *  · 5 thèmes civiques → `V101__ref_themes.sql`
 *  · examen civique 40 questions / 45 min / 32 sur 40, 28 connaissance +
 *    12 mises en situation → `V110__ref_exam_templates.sql`
 *  · CSP → A2, CR → B1, NAT → B2 → `TCF_LEVEL_BY_PROCEDURE` (`lib/types.ts`)
 *  · durées d'épreuve TCF (20/35/30 min, ≈10 min EO) → `DureeEpreuve` serveur
 *
 * Mesure d'audience (`lib/analytics.ts`) : `LANDING_VIEWED` au montage,
 * `DIAGNOSTIC_CTA_CLICKED` (TCF), `CIVIQUE_CTA_CLICKED` (civique),
 * `PRICING_CTA_CLICKED` / `PREMIUM_CTA_CLICKED` (tarifs) — allowlist fermée
 * doublée côté serveur.
 */

export function ReussirView({ plans }: { plans: PlanPublicResponse[] }) {
  const rootRef = useRef<HTMLDivElement | null>(null);
  useReveal(rootRef);

  useEffect(() => {
    track("LANDING_VIEWED", { landingPath: "/reussir" }, { once: true });
  }, []);

  return (
    <div className={styles.page} ref={rootRef}>
      <TopBar />
      <Nav />
      <main>
        <Hero />
        <SocialStrip />
        <SituationSection />
        <ApresLeTestSection />
        <ApercuSection />
        <TcfSection />
        <CiviqueSection />
        <PourquoiSection />
        <PricingSection plans={plans} />
        <FaqSection />
        <FinalSection />
      </main>
      <PageFooter />
      <StickyCta />
    </div>
  );
}

// ============================================================================
// LES 3 DÉMARCHES — partagées entre le hero et « Votre situation »
// ============================================================================

const DEMARCHES: {
  emoji: string;
  titre: string;
  sub: string;
  desc: string;
  niveau: string;
}[] = [
  {
    emoji: "🇫🇷",
    titre: "Naturalisation",
    sub: "Français B2 + examen civique",
    desc: "Préparez le niveau de français demandé et l'examen civique.",
    niveau: "TCF IRN · B2",
  },
  {
    emoji: "🪪",
    titre: "Carte de résident",
    sub: "Français B1 + examen civique",
    desc: "Travaillez le français et les connaissances demandées pour l'examen civique.",
    niveau: "TCF IRN · B1",
  },
  {
    emoji: "📄",
    titre: "Carte de séjour pluriannuelle",
    sub: "Français A2 + examen civique",
    desc: "Préparez le niveau de français attendu et l'examen civique selon votre situation.",
    niveau: "TCF IRN · A2",
  },
];

// ============================================================================
// BANDEAU DE CONTEXTE
// ============================================================================

function TopBar() {
  return (
    <div className={styles.topbar}>
      Naturalisation · Carte de résident · Carte de séjour
      <span> — TCF IRN + examen civique</span>
    </div>
  );
}

// ============================================================================
// NAV
// ============================================================================

function Nav() {
  return (
    <div className={styles.nav}>
      <div className={`${styles.wrap} ${styles.navRow}`}>
        <a aria-label="SejourFR accueil" className={styles.brand} href="#top">
          <Cocarde />
          <Wordmark />
        </a>
        <span className={styles.navSpace} />
        <nav aria-label="Navigation principale" className={styles.navLinks}>
          <a href="#tcf">TCF IRN</a>
          <a href="#civique">Examen civique</a>
          <a href="#tarifs">Tarifs</a>
        </nav>
        <DiagnosticCta variant="nav" label="Test gratuit" />
      </div>
    </div>
  );
}

// ============================================================================
// ① HERO
// ============================================================================

function Hero() {
  return (
    <section className={`${styles.sec} ${styles.hero}`} id="top">
      <div className={`${styles.wrap} ${styles.two}`}>
        <div className={styles.heroCopy}>
          <span className={styles.eyebrow} data-rv>
            TCF IRN · Examen civique · Naturalisation · Carte de séjour
          </span>

          <h1 className={`${styles.h1} ${styles.editorial}`} data-rv>
            Vous préparez le TCF IRN ou l&apos;examen civique pour votre{" "}
            <em>naturalisation ou votre carte de séjour&nbsp;?</em>
          </h1>

          <p className={styles.lead} data-rv>
            <strong>Pas besoin de savoir par où commencer.</strong> Faites un test
            gratuit&nbsp;: SejourFR vous montre votre niveau, ce qu&apos;il faut
            améliorer et quoi réviser ensuite.
          </p>

          <div className={`${styles.heroActions}`} data-rv>
            <DiagnosticCta variant="hero" label="Faire le test gratuit" />
            <a href="#apercu" className={`${styles.btn} ${styles.btnO} ${styles.btnLg}`}>
              Voir SejourFR
            </a>
          </div>

          <p className={styles.trustNote} data-rv>
            Gratuit · Sans carte bancaire · Résultat immédiat
          </p>

          <div aria-label="Démarches préparées" className={styles.goalGrid} data-rv>
            {DEMARCHES.map((d) => (
              <div key={d.titre} className={styles.goal}>
                <strong>
                  {d.emoji} {d.titre}
                </strong>
                <span>{d.sub}</span>
              </div>
            ))}
          </div>
        </div>

        <aside aria-label="Comment fonctionne SejourFR" className={styles.heroCard} data-rv>
          <span className={`${styles.eyebrow} ${styles.eyebrowRed}`}>Simple</span>
          <h3>Vous savez quoi faire ensuite.</h3>
          <p className={styles.mini} style={{ fontSize: 13.5 }}>
            SejourFR vous aide à passer de « je ne sais pas quoi réviser » à un
            entraînement clair.
          </p>
          <div className={styles.priorityList}>
            <div className={styles.priority}>
              <span className={styles.priorityNum}>1</span>
              <div>
                <strong>Testez votre niveau</strong>
                <small>TCF IRN ou examen civique.</small>
              </div>
            </div>
            <div className={styles.priority}>
              <span className={styles.priorityNum}>2</span>
              <div>
                <strong>Voyez ce qui vous manque</strong>
                <small>Niveau de français ou thèmes à revoir.</small>
              </div>
            </div>
            <div className={styles.priority}>
              <span className={styles.priorityNum}>3</span>
              <div>
                <strong>Entraînez-vous au bon endroit</strong>
                <small>Exercices, corrections et examens blancs.</small>
              </div>
            </div>
          </div>
          <div className={styles.heroScore}>
            <div>
              <small>Avec SejourFR</small>
              <strong>Test → Résultat → Révision</strong>
            </div>
          </div>
        </aside>
      </div>
    </section>
  );
}

// ============================================================================
// BANDE DE CONFIANCE
// ============================================================================

const TRUST_ITEMS = [
  "TCF IRN complet",
  "Examen civique",
  "Oral et écrit corrigés",
  "Examens blancs",
  "Paiement unique",
];

function SocialStrip() {
  return (
    <div className={styles.socialStrip}>
      <div className={`${styles.wrap} ${styles.socialInner}`}>
        {TRUST_ITEMS.map((item) => (
          <span key={item}>
            <Check aria-hidden />
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}

// ============================================================================
// ② VOTRE SITUATION
// ============================================================================

function SituationSection() {
  return (
    <section className={`${styles.sec} ${styles.paper}`} id="parcours">
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} style={{ marginInline: "auto" }} data-rv>
          <span className={styles.eyebrow}>Votre situation</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Préparez ce qui correspond à votre demande.
          </h2>
          <p className={styles.lead} style={{ marginTop: 12 }}>
            Naturalisation, carte de résident ou carte de séjour pluriannuelle&nbsp;:
            SejourFR regroupe la préparation utile au même endroit.
          </p>
        </div>

        <div className={styles.journeyCards}>
          {DEMARCHES.map((d) => (
            <article key={d.titre} className={styles.journey} data-rv>
              <div className={styles.journeyEmoji} aria-hidden>
                {d.emoji}
              </div>
              <h3>{d.titre}</h3>
              <p>{d.desc}</p>
              <div className={styles.reqRow}>
                <span className={styles.req}>{d.niveau}</span>
                <span className={styles.req}>Examen civique</span>
              </div>
            </article>
          ))}
        </div>

        <p className={`${styles.mini} ${styles.center}`} style={{ marginTop: 24 }} data-rv>
          Certaines situations peuvent être différentes ou bénéficier d&apos;une
          dispense. Vérifiez toujours les règles applicables à votre dossier.
        </p>
      </div>
    </section>
  );
}

// ============================================================================
// ③ APRÈS LE TEST
// ============================================================================

function ApresLeTestSection() {
  return (
    <section className={styles.sec}>
      <div className={`${styles.wrap} ${styles.twoT}`}>
        <div data-rv>
          <span className={`${styles.eyebrow} ${styles.eyebrowRed}`}>Après le test</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Vous voyez immédiatement ce qu&apos;il faut améliorer.
          </h2>
          <p className={styles.lead} style={{ marginTop: 12 }}>
            Le résultat ne donne pas seulement une note. Il vous montre où vous en
            êtes et le prochain travail utile.
          </p>

          <div className={styles.diagGrid}>
            <div className={styles.diagChoice}>
              <div className={styles.diagChoiceHead}>
                <span className={styles.pill}>TCF IRN</span>
              </div>
              <h3>Pour le français</h3>
              <p>
                Voyez votre niveau par épreuve et les compétences qui vous empêchent
                d&apos;atteindre votre objectif.
              </p>
              <ul className={styles.diagMiniList}>
                <li>
                  <Check aria-hidden />
                  Niveau estimé par épreuve
                </li>
                <li>
                  <Check aria-hidden />
                  Points à améliorer
                </li>
                <li>
                  <Check aria-hidden />
                  Prochain entraînement conseillé
                </li>
              </ul>
              <DiagnosticCta variant="card" label="Essayer gratuitement" />
            </div>

            <div className={styles.diagChoice}>
              <div className={styles.diagChoiceHead}>
                <span className={`${styles.pill} ${styles.pillRed}`}>Examen civique</span>
              </div>
              <h3>Pour l&apos;examen civique</h3>
              <p>
                Voyez les thèmes que vous maîtrisez déjà et ceux que vous devez
                encore revoir.
              </p>
              <ul className={styles.diagMiniList}>
                <li>
                  <Check aria-hidden />
                  Score par thème
                </li>
                <li>
                  <Check aria-hidden />
                  Thèmes les plus faibles
                </li>
                <li>
                  <Check aria-hidden />
                  Révisions conseillées
                </li>
              </ul>
              <CiviqueDiagnosticCta label="Essayer gratuitement" />
            </div>
          </div>
        </div>

        <div className={styles.diagBox} data-rv>
          <div className={styles.diagTop}>
            <div>
              <span className={styles.eyebrow}>Exemple de résultat</span>
              <h3>Votre préparation devient claire</h3>
              <span className={styles.mini}>Vous voyez où concentrer votre temps.</span>
            </div>
            <div className={styles.levelBubble}>B1</div>
          </div>

          <div className={styles.meterBlock}>
            <span className={styles.meterBlockTitle}>TCF IRN</span>
            <div className={styles.meterRow}>
              <span>Expression orale</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "58%" }} />
              </div>
              <b>B1</b>
            </div>
            <div className={styles.meterRow}>
              <span>Expression écrite</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "78%" }} />
              </div>
              <b>B2</b>
            </div>
          </div>

          <div className={`${styles.meterBlock} ${styles.meterBlockRed}`}>
            <span className={styles.meterBlockTitle}>Examen civique</span>
            <div className={styles.meterRow}>
              <span>Institutions</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "54%" }} />
              </div>
              <b>54%</b>
            </div>
            <div className={styles.meterRow}>
              <span>Droits &amp; devoirs</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "72%" }} />
              </div>
              <b>72%</b>
            </div>
          </div>

          <div className={styles.priorityList}>
            <div className={styles.priority}>
              <span className={styles.priorityNum}>1</span>
              <div>
                <strong>À travailler maintenant</strong>
                <small>Le point qui vous fera progresser en premier.</small>
              </div>
            </div>
            <div className={styles.priority}>
              <span className={styles.priorityNum}>2</span>
              <div>
                <strong>Entraînement ciblé</strong>
                <small>Des exercices sur ce point précis.</small>
              </div>
            </div>
            <div className={styles.priority}>
              <span className={styles.priorityNum}>3</span>
              <div>
                <strong>Nouvelle vérification</strong>
                <small>Vous voyez ensuite si vous avez progressé.</small>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ④ SEJOURFR, EN VRAI (aperçu produit — CSS pur, aucune capture à maintenir)
// ============================================================================

const SHOWCASE: { icon: ReactElement; title: string; desc: string }[] = [
  {
    icon: <Layers aria-hidden />,
    title: "TCF IRN + examen civique",
    desc: "Les deux préparations réunies au même endroit.",
  },
  {
    icon: <Clock aria-hidden />,
    title: "Entraînement chronométré",
    desc: "QCM, temps limité et correction expliquée.",
  },
  {
    icon: <TrendingUp aria-hidden />,
    title: "Niveau estimé",
    desc: "Score, niveau CECRL et critères détaillés.",
  },
  {
    icon: <ClipboardCheck aria-hidden />,
    title: "Corrections utiles",
    desc: "Vos points forts, vos erreurs et comment progresser.",
  },
];

function ApercuSection() {
  return (
    <section className={`${styles.sec} ${styles.paper}`} id="apercu">
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} style={{ marginInline: "auto" }} data-rv>
          <span className={styles.eyebrow}>SejourFR, en vrai</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Voici ce que vous allez utiliser.
          </h2>
          <p className={styles.lead} style={{ marginTop: 12 }}>
            Entraînez-vous, faites-vous corriger et suivez votre progression depuis
            la même application.
          </p>
        </div>

        <div className={styles.showcaseGrid}>
          {SHOWCASE.map((s) => (
            <article key={s.title} className={styles.showcaseCard} data-rv>
              <div className={styles.showcasePreview}>
                <span className={styles.showcaseIcon}>{s.icon}</span>
              </div>
              <div className={styles.showcaseBody}>
                <h3>{s.title}</h3>
                <p>{s.desc}</p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑤ LES 4 ÉPREUVES DU TCF IRN
// ============================================================================

const EPREUVES: { href: string; icon: ReactElement; title: string; desc: string }[] = [
  {
    href: "/entrainement/tcf/co",
    icon: <Headphones aria-hidden />,
    title: "Compréhension orale",
    desc: "25 questions · 20 minutes · entraînement audio chronométré.",
  },
  {
    href: "/entrainement/tcf/ce",
    icon: <BookOpen aria-hidden />,
    title: "Compréhension écrite",
    desc: "25 questions · 35 minutes · textes et situations proches du format attendu.",
  },
  {
    href: "/entrainement/tcf/ee",
    icon: <PenLine aria-hidden />,
    title: "Expression écrite",
    desc: "3 exercices · 30 minutes · correction IA et niveau estimé.",
  },
  {
    href: "/entrainement/tcf/eo",
    icon: <Mic aria-hidden />,
    title: "Expression orale",
    desc: "3 exercices · 10 minutes · entraînement et évaluation de votre production.",
  },
];

function TcfSection() {
  const origin = useOrigin();

  return (
    <section className={styles.sec} id="tcf">
      <div className={styles.wrap}>
        <div data-rv>
          <span className={`${styles.eyebrow} ${styles.eyebrowRed}`}>TCF IRN</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Préparez les 4 épreuves du TCF IRN.
          </h2>
          <p className={styles.lead} style={{ marginTop: 12 }}>
            Travaillez chaque épreuve séparément, puis faites des examens blancs
            complets pour vous habituer au rythme du jour J.
          </p>
        </div>

        <div className={styles.examGrid}>
          {EPREUVES.map((e) => (
            <Link
              key={e.title}
              href={withTrafficSource(e.href, origin)}
              className={styles.examCard}
              data-rv
            >
              <span className={styles.examIcon}>{e.icon}</span>
              <h3>{e.title}</h3>
              <p>{e.desc}</p>
            </Link>
          ))}
        </div>

        <div className={styles.banner} data-rv>
          <div>
            <strong>Examen blanc TCF IRN · 1 h 35</strong>
            <p>
              Enchaînez les 4 épreuves pour apprendre aussi à gérer votre temps et
              votre concentration.
            </p>
          </div>
          <DiagnosticCta variant="cardAlt" label="Commencer gratuitement" />
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑥ EXAMEN CIVIQUE
// ============================================================================

const CIVIQUE_THEMES = [
  "🏛️ Principes et valeurs de la République",
  "⚖️ Système institutionnel et politique",
  "🛡️ Droits et devoirs",
  "📚 Histoire, géographie et culture",
  "🤝 Vivre dans la société française",
];

function CiviqueSection() {
  return (
    <section className={`${styles.sec} ${styles.blueBg} ${styles.onBrand}`} id="civique">
      <div className={`${styles.wrap} ${styles.civGrid}`}>
        <div data-rv>
          <span className={`${styles.eyebrow} ${styles.eyebrowOnBrand}`}>Examen civique</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Préparez-vous au vrai format de l&apos;examen civique.
          </h2>
          <p className={styles.lead} style={{ marginTop: 12, color: "var(--on-brand-muted)" }}>
            Travaillez les 5 thèmes, les questions de connaissance et les mises en
            situation avant de passer aux examens blancs.
          </p>

          <div className={styles.statRow}>
            <div className={styles.stat}>
              <strong>40</strong>
              <span>questions</span>
            </div>
            <div className={styles.stat}>
              <strong>45 min</strong>
              <span>durée</span>
            </div>
            <div className={styles.stat}>
              <strong>32 / 40</strong>
              <span>minimum pour réussir</span>
            </div>
          </div>

          <div className={styles.civInfo}>
            <strong>28 questions de connaissance + 12 mises en situation</strong>
            <span>
              Le contenu attendu dépend de votre demande&nbsp;: carte de séjour
              pluriannuelle, carte de résident ou naturalisation.
            </span>
          </div>

          <div className={styles.themeList}>
            {CIVIQUE_THEMES.map((t) => (
              <div key={t}>{t}</div>
            ))}
          </div>

          <CiviqueDiagnosticCta
            label="S'entraîner à l'examen civique"
            style={{ marginTop: 26 }}
          />
        </div>

        <div className={styles.civPreview} data-rv>
          <div className={styles.civPreviewTop}>
            <div>
              <span className={styles.label}>Exemple de résultat</span>
              <h3 className={styles.h3} style={{ marginTop: 8 }}>
                Votre score par thème
              </h3>
            </div>
            <span className={styles.civPreviewScore}>28/40</span>
          </div>
          <div className={styles.civPreviewThemes}>
            <div className={styles.meterRow}>
              <span>Principes et valeurs</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "82%" }} />
              </div>
              <b>82%</b>
            </div>
            <div className={styles.meterRow}>
              <span>Institutions</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "54%" }} />
              </div>
              <b>54%</b>
            </div>
            <div className={styles.meterRow}>
              <span>Droits et devoirs</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "72%" }} />
              </div>
              <b>72%</b>
            </div>
            <div className={styles.meterRow}>
              <span>Histoire et culture</span>
              <div className={styles.bar}>
                <i className={styles.barFill} style={{ width: "61%" }} />
              </div>
              <b>61%</b>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑦ POURQUOI SEJOURFR
// ============================================================================

const WHY: { num: string; title: string; desc: string }[] = [
  {
    num: "01",
    title: "Entraînez-vous dans le bon format",
    desc: "QCM, chronomètre, tâches d'expression et examens blancs.",
  },
  {
    num: "02",
    title: "Faites corriger votre oral et votre écrit",
    desc: "Obtenez un niveau estimé, vos erreurs et des conseils concrets pour progresser.",
  },
  {
    num: "03",
    title: "Concentrez-vous sur ce qui vous manque",
    desc: "Évitez de perdre du temps sur les points que vous maîtrisez déjà.",
  },
];

function PourquoiSection() {
  return (
    <section className={styles.sec}>
      <div className={styles.wrap}>
        <div data-rv>
          <span className={`${styles.eyebrow} ${styles.eyebrowRed}`}>Pourquoi SejourFR</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Une préparation faite pour le jour de l&apos;examen.
          </h2>
          <p className={styles.lead} style={{ marginTop: 12 }}>
            Pas seulement des fiches à lire&nbsp;: vous pratiquez ce que l&apos;examen
            vous demandera réellement.
          </p>
        </div>

        <div className={styles.whyGrid}>
          {WHY.map((w) => (
            <div key={w.num} className={styles.why} data-rv>
              <div className={styles.whyNum}>{w.num}</div>
              <div>
                <h3>{w.title}</h3>
                <p>{w.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑧ TARIFS — 2 pass, prix servis par le backend
// ============================================================================

/** Notes éditoriales par rang de durée (position dans la liste triée, pas une
 *  donnée serveur) — reprises mot pour mot de la maquette. Le nombre de
 *  simulations orales, lui, vient toujours de `plan.realtimeEoSessions`. */
const CIVIQUE_ROW_NOTES = ["Pour préparer sereinement", "Pour garder l'accès longtemps"];
const INTEGRAL_ROW_NOTES = ["Examen très proche", "Préparation intensive", "Le plus populaire"];

const CIVIQUE_FEATURES = [
  "Révision des 5 thèmes",
  "Entraînement aux questions de l'examen",
  "Révision ciblée par thème",
  "Examens blancs civiques illimités",
  "Statistiques et explications",
];

const INTEGRAL_FEATURES = [
  "Tout le Pass Examen civique",
  "Compréhension orale et écrite",
  "Expression écrite corrigée par IA",
  "Expression orale évaluée par IA",
  "Examens blancs TCF IRN complets",
  "Simulations orales selon la durée choisie",
];

function PricingSection({ plans }: { plans: PlanPublicResponse[] }) {
  const { status, user } = useAuth();
  const isAuth = status === "authenticated" && user !== null;
  const origin = useOrigin();

  const civique = useMemo(
    () => oneTimePassesOf(plans, "CIVIQUE").filter((p) => p.price > 0),
    [plans],
  );
  const integral = useMemo(
    () => oneTimePassesOf(plans, "INTEGRAL").filter((p) => p.price > 0),
    [plans],
  );

  if (civique.length === 0 && integral.length === 0) return null;

  return (
    <section className={styles.sec} id="tarifs">
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} style={{ marginInline: "auto" }} data-rv>
          <span className={`${styles.eyebrow} ${styles.eyebrowRed}`}>2 pass seulement</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Choisissez selon l&apos;examen que vous préparez.
          </h2>
          <p className={styles.lead} style={{ marginTop: 12 }}>
            Seulement l&apos;examen civique&nbsp;? Prenez le Pass Examen civique. Vous
            préparez aussi le TCF IRN&nbsp;? Prenez le Pass Intégral.
          </p>
        </div>

        <div className={styles.pricingGrid}>
          {civique.length > 0 && (
            <PriceCard module="CIVIQUE" plans={civique} isAuth={isAuth} origin={origin} />
          )}
          {integral.length > 0 && (
            <PriceCard module="INTEGRAL" plans={integral} isAuth={isAuth} origin={origin} featured />
          )}
        </div>

        <p className={`${styles.mini} ${styles.center}`} style={{ marginTop: 24 }} data-rv>
          Vous pouvez découvrir SejourFR gratuitement avant de choisir un pass.
        </p>
      </div>
    </section>
  );
}

function PriceCard({
  module,
  plans,
  isAuth,
  origin,
  featured = false,
}: {
  module: PassModule;
  plans: PlanPublicResponse[];
  isAuth: boolean;
  origin: TrafficSource | null;
  featured?: boolean;
}) {
  const popularCode = popularPassCodeOf(plans);
  const notes = module === "CIVIQUE" ? CIVIQUE_ROW_NOTES : INTEGRAL_ROW_NOTES;
  const ctaPlan = plans.find((p) => p.code === popularCode) ?? plans[0];
  const ctaHref = passCheckoutHref(ctaPlan.code, isAuth, origin);

  return (
    <article
      className={`${styles.priceCard} ${featured ? styles.priceFeatured : ""}`}
      data-rv
    >
      {featured && <span className={styles.popularTag}>Le plus complet</span>}
      <span className={`${styles.offerKicker} ${featured ? styles.offerKickerRed : ""}`}>
        {module === "CIVIQUE" ? "Examen civique uniquement" : "TCF IRN + examen civique"}
      </span>
      <h3>{module === "CIVIQUE" ? "Pass Examen civique" : "Pass Intégral"}</h3>
      <p className={styles.offerDesc}>
        {module === "CIVIQUE"
          ? "Pour réviser les connaissances demandées et vous entraîner avec des examens blancs."
          : "Toute la préparation de l'examen civique, plus les 4 épreuves du TCF IRN."}
      </p>

      <div className={styles.durationList}>
        {plans.map((plan, i) => {
          const selected = plan.code === popularCode;
          const sessions = module === "INTEGRAL" ? passSessionsLabel(plan) : null;
          const note = [notes[i], sessions].filter(Boolean).join(" · ");
          return (
            <Link
              key={plan.code}
              href={passCheckoutHref(plan.code, isAuth, origin)}
              className={`${styles.durationRow} ${selected ? styles.durationRowSelected : ""}`}
              onClick={() => trackPassChosen(plan.code)}
            >
              <div>
                <span className={styles.durationName}>{passDurationLabel(plan.durationDays)}</span>
                {note ? <span className={styles.durationNote}>{note}</span> : null}
              </div>
              <div className={styles.durationPrice}>{formatPassPrice(plan.price)}&nbsp;€</div>
            </Link>
          );
        })}
      </div>

      <ul className={styles.featuresList}>
        {(module === "CIVIQUE" ? CIVIQUE_FEATURES : INTEGRAL_FEATURES).map((f) => (
          <li key={f}>
            <Check aria-hidden />
            {f}
          </li>
        ))}
      </ul>

      <Link
        href={ctaHref}
        className={`${styles.btn} ${featured ? styles.btnP : styles.btnBlue} ${styles.btnFull}`}
        onClick={() => trackPassChosen(ctaPlan.code)}
      >
        {module === "CIVIQUE" ? "Préparer l'examen civique" : "Préparer TCF IRN + examen civique"}
        <ArrowRight aria-hidden />
      </Link>
      <p className={styles.trustNote}>Paiement unique · aucune reconduction</p>
    </article>
  );
}

/**
 * Un pass choisi depuis la landing dit **deux** choses différentes : « cet
 * écran a déclenché une intention d'achat » et « c'est ce pass-là qui a été
 * choisi ». Les deux événements du registre existent pour ça.
 */
function trackPassChosen(planCode: string): void {
  track("PREMIUM_CTA_CLICKED", { ctaLocation: "PRICING", planCode, screen: "reussir_offres" });
  track("PRICING_CTA_CLICKED", { planCode });
}

// ============================================================================
// ⑨ FAQ
// ============================================================================

const FAQ: { q: string; a: string }[] = [
  {
    q: "Quel pass choisir ?",
    a: "Si vous préparez seulement l'examen civique, choisissez le Pass Examen civique. Si vous préparez aussi le TCF IRN, choisissez le Pass Intégral.",
  },
  {
    q: "Quel niveau de français dois-je viser ?",
    a: "Pour les démarches visées sur cette page : A2 pour la carte de séjour pluriannuelle, B1 pour la carte de résident et B2 pour la naturalisation. Votre situation personnelle peut toutefois être différente.",
  },
  {
    q: "Quelle différence entre le TCF IRN et l'examen civique ?",
    a: "Le TCF IRN évalue votre français : compréhension orale, compréhension écrite, expression écrite et expression orale. L'examen civique évalue vos connaissances sur la République française et la vie en France.",
  },
  {
    q: "L'examen civique est-il le même pour toutes les demandes ?",
    a: "Non. Le niveau et le contenu attendu dépendent notamment de la demande préparée : carte de séjour pluriannuelle, carte de résident ou naturalisation.",
  },
  {
    q: "Comment fonctionne la correction IA ?",
    a: "Pour l'écrit et l'oral, SejourFR analyse votre production, estime un niveau et vous indique les points à améliorer. Cette évaluation reste une estimation d'entraînement.",
  },
  {
    q: "SejourFR est-il un organisme officiel ?",
    a: "Non. SejourFR est une plateforme indépendante de préparation. Elle n'est pas affiliée à l'État français ni à France Éducation international.",
  },
];

function FaqSection() {
  return (
    <section className={`${styles.sec} ${styles.paper}`}>
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} style={{ marginInline: "auto" }} data-rv>
          <span className={styles.eyebrow}>Questions fréquentes</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Avant de commencer.
          </h2>
        </div>
        <div className={styles.faq} data-rv>
          {FAQ.map((item) => (
            <details key={item.q}>
              <summary>{item.q}</summary>
              <p>{item.a}</p>
            </details>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑩ BLOC FINAL
// ============================================================================

function FinalSection() {
  return (
    <section className={styles.sec}>
      <div className={styles.wrap}>
        <div className={`${styles.final} ${styles.editorial}`} data-rv>
          <span className={`${styles.eyebrow} ${styles.eyebrowRed}`}>Commencez gratuitement</span>
          <h2 className={styles.h2} style={{ marginTop: 16 }}>
            Vous voulez savoir où vous en êtes&nbsp;?
          </h2>
          <p className={styles.lead}>
            Faites le test TCF IRN ou examen civique et découvrez les points à
            travailler avant votre examen.
          </p>
          <DiagnosticCta variant="hero" label="Faire le test gratuit" />
          <p className={styles.trustNote}>Sans carte bancaire · Résultat immédiat</p>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// PIED DE PAGE
// ============================================================================

function PageFooter() {
  return (
    <footer className={styles.foot}>
      <div className={`${styles.wrap} ${styles.footInner}`}>
        <div>
          <div className={styles.brand}>
            <Cocarde />
            <Wordmark />
          </div>
          <p className={styles.footNote}>
            Plateforme indépendante de préparation au TCF IRN et à l&apos;examen
            civique.
          </p>
        </div>
        <ul className={styles.footLinks}>
          <li>
            <Link href="/mentions-legales">Mentions légales</Link>
          </li>
          <li>
            <Link href="/confidentialite">Confidentialité</Link>
          </li>
          <li>
            {/* La maquette nomme « CGV » ; le site n'a que des CGU (pas de vente
                directe hors Stripe Checkout) — même document, bon intitulé. */}
            <Link href="/cgu">CGU</Link>
          </li>
          <li>
            <Link href="/contact">Contact</Link>
          </li>
        </ul>
      </div>
    </footer>
  );
}

// ============================================================================
// CTA DIAGNOSTIC (unique point de mesure) + CTA CIVIQUE + STICKY
// ============================================================================

const CTA_ANALYTICS: Record<"hero" | "nav" | "card" | "cardAlt", AnalyticsCtaLocation> = {
  nav: "HERO",
  hero: "HERO",
  card: "MIDDLE",
  cardAlt: "MIDDLE",
};

/**
 * CTA du diagnostic **TCF**. Toujours vers `/diagnostic` — sauf pour un
 * compte dont le diagnostic est déjà terminé, qui n'a plus rien à y refaire
 * et part directement sur `/plan` (même règle que le reste du site : « Faire
 * mon diagnostic » LANCE le diagnostic, il ne montre pas une page qui
 * redemande de le lancer).
 */
function DiagnosticCta({
  variant,
  label,
}: {
  variant: "hero" | "nav" | "card" | "cardAlt";
  label: string;
}) {
  const origin = useOrigin();
  const { status, user } = useAuth();
  const [completedForUserId, setCompletedForUserId] = useState<string | null>(null);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    diagnosticApi
      .currentCached()
      .then((diagnostic) => {
        if (!cancelled) {
          setCompletedForUserId(diagnostic.status === "COMPLETED" ? user.id : null);
        }
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  const completed = Boolean(user && completedForUserId === user.id);
  const destination = withTrafficSource(completed ? "/plan" : "/diagnostic", origin);
  const finalLabel = completed ? "Voir mon plan" : label;

  const className = [
    styles.btn,
    variant === "cardAlt" ? styles.btnO : styles.btnP,
    variant === "nav" ? styles.btnSm : styles.btnLg,
    variant === "card" || variant === "cardAlt" ? styles.btnFull : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <Link
      href={destination}
      className={className}
      onClick={() =>
        track("DIAGNOSTIC_CTA_CLICKED", {
          ctaLocation: CTA_ANALYTICS[variant],
          diagnosticType: "UNKNOWN",
        })
      }
    >
      {finalLabel}
      <ArrowRight aria-hidden />
    </Link>
  );
}

/**
 * CTA du diagnostic **civique**, vers `/diagnostic-civique`. 🛑 Ne réutilise
 * jamais l'événement/la destination du diagnostic TCF — les deux examens ne
 * se mélangent jamais (cf. CLAUDE.md racine, vocabulaire TCF vs CIVIQUE).
 */
function CiviqueDiagnosticCta({
  label,
  style,
}: {
  label: string;
  style?: React.CSSProperties;
}) {
  const origin = useOrigin();
  const destination = withTrafficSource("/diagnostic-civique", origin);

  return (
    <Link
      href={destination}
      className={`${styles.btn} ${styles.btnO} ${styles.btnLg}`}
      style={style}
      onClick={() => track("CIVIQUE_CTA_CLICKED", { ctaLocation: "MIDDLE" })}
    >
      {label}
      <ArrowRight aria-hidden />
    </Link>
  );
}

/** Barre d'action persistante mobile, révélée une fois le hero dépassé. */
function StickyCta() {
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const anchor = document.getElementById("parcours");
    if (!anchor) return;
    const io = new IntersectionObserver(
      ([entry]) => setShown(entry.isIntersecting || entry.boundingClientRect.top < 0),
      { threshold: 0 },
    );
    io.observe(anchor);
    return () => io.disconnect();
  }, []);

  return (
    <div className={`${styles.sticky} ${shown ? styles.stickyOn : ""}`}>
      <DiagnosticCta variant="card" label="Faire le test gratuit" />
    </div>
  );
}

// ============================================================================
// HOOKS
// ============================================================================

/** Révèle en cascade tous les `[data-rv]` du sous-arbre au passage du scroll.
 *  Un `MutationObserver` prend en charge les nœuds ajoutés après le montage
 *  (grille de tarifs qui arrive après le premier rendu, etc.). */
function useReveal(rootRef: React.RefObject<HTMLElement | null>) {
  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const reveal = (el: HTMLElement) => el.setAttribute("data-in", "");

    if (reduced) {
      const showAll = (scope: ParentNode) =>
        scope.querySelectorAll<HTMLElement>("[data-rv]").forEach(reveal);
      showAll(root);
      const mo = new MutationObserver(() => showAll(root));
      mo.observe(root, { childList: true, subtree: true });
      return () => mo.disconnect();
    }

    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry, i) => {
          if (!entry.isIntersecting) return;
          const el = entry.target as HTMLElement;
          window.setTimeout(() => reveal(el), i * 55);
          io.unobserve(el);
        });
      },
      { rootMargin: "0px 0px -10% 0px", threshold: 0.1 },
    );

    const observeAll = (scope: ParentNode) =>
      scope
        .querySelectorAll<HTMLElement>("[data-rv]:not([data-in])")
        .forEach((el) => io.observe(el));

    observeAll(root);
    const mo = new MutationObserver((records) => {
      for (const record of records) {
        for (const node of record.addedNodes) {
          if (!(node instanceof HTMLElement)) continue;
          if (node.matches("[data-rv]:not([data-in])")) io.observe(node);
          observeAll(node);
        }
      }
    });
    mo.observe(root, { childList: true, subtree: true });

    return () => {
      mo.disconnect();
      io.disconnect();
    };
  }, [rootRef]);
}

/** Provenance transportée dans les liens (`?src=`), pour que l'inscription qui
 *  suit un clic reste rattachée au réseau d'origine. Pas de badge personnalisé
 *  sur cette page — la maquette de référence n'en a pas. */
function subscribeOrigin() {
  return () => {};
}

function useOrigin(): TrafficSource | null {
  return useSyncExternalStore(subscribeOrigin, detectTrafficSource, () => null);
}
