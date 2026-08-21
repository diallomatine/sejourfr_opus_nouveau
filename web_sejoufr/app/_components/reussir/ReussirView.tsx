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
  CircleHelp,
  FileText,
  Gavel,
  Globe,
  Headphones,
  Landmark,
  Lock,
  Mail,
  Mic,
  PenLine,
  Scale,
  Sparkles,
  Users,
} from "lucide-react";
import {
  detectTrafficSource,
  trackAudienceEvent,
  trackPageView,
  withTrafficSource,
  type TrafficSource,
} from "@/lib/audience";
import { diagnosticApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { EPREUVE_PLANNED_SEC, minutesLabel } from "@/lib/exam-durations";
import {
  formatPassPrice,
  passCheckoutHref,
  passDurationLabel,
  passMonthlyLabel,
  popularPassCodeOf,
  passSessionsLabel,
} from "@/lib/passes";
import { SOCIAL_ACCOUNTS, STORE_LINKS } from "@/lib/site";
import { type PlanPublicResponse } from "@/lib/types";
import styles from "./reussir.module.css";

/**
 * Landing autoportante (`/reussir`) — lien de bio réseaux et pages de campagne.
 *
 * Elle raconte DEUX fils distincts, et ne les mélange jamais :
 *
 *  1. le **TCF IRN** — diagnostic de production → priorités → plan adaptatif →
 *     compétences → examen blanc qui confirme un palier ;
 *  2. l'**examen civique** — un QCM sur les 5 thèmes officiels, avec des séries
 *     de 20 questions et un examen blanc à seuil.
 *
 * ⚠️ Le fil TCF ne s'applique PAS au civique : celui-ci n'a ni production, ni
 * niveau CECRL, ni compétences. Greffer l'un sur l'autre produirait des
 * promesses fausses. Le civique a donc sa propre section (`#civique`), son
 * propre déroulé et ses propres chiffres.
 *
 * ⚠️ Chaque chiffre affiché ici vient du dépôt, jamais d'une estimation :
 *  · 5 thèmes civiques et leurs libellés → `V101__ref_themes.sql`
 *  · examen blanc civique 40 questions / 45 min / 32 sur 40
 *    → `V110__ref_exam_templates.sql` (`duration_seconds`, `total_questions`,
 *      `passing_score`), y compris le gabarit gratuit `civique-decouverte`
 *  · série d'entraînement = 20 questions → `docs/lots-entrainement.md`
 *  · CSP → A2, CR → B1, NAT → B2 → `TCF_LEVEL_BY_PROCEDURE` (`lib/types.ts`)
 *  · durées d'épreuve TCF → `DureeEpreuve` côté serveur
 *  · une étape du Plan = 5 petits sujets → `LearningPlanStep.PROMPTS_PAR_ETAPE`
 *
 * ⚠️ MESURE D'AUDIENCE : `/reussir` n'admet que `VIEW`, `CTA`,
 * `SOCIAL_LANDING_DIAGNOSTIC_CLICKED` et `SOCIAL_LANDING_CIVIQUE_CLICKED`
 * (`AUDIENCE_EVENTS_BY_PATH`, doublée côté serveur par
 * `PageViewService.EVENTS_BY_PATH`). Un événement inventé ici serait rejeté en
 * silence : ne rien ajouter sans toucher les deux listes. Les deux portes
 * d'entrée se comptent **séparément** — le civique n'a ni production, ni niveau
 * CECRL, ni diagnostic.
 */

type Parcours = "tcf" | "civique";

/** Chemin mesuré côté backend (liste blanche `PageViewService`). */
const TRACKED_PATH = "/reussir";

/** Réseaux reconnus pour le badge de provenance. */
const NETWORKS: Record<string, { label: string; icon: ReactElement }> = {
  tiktok: { label: "TikTok", icon: <TikTokIcon /> },
  instagram: { label: "Instagram", icon: <InstagramIcon /> },
  whatsapp: { label: "WhatsApp", icon: <WhatsAppIcon /> },
  facebook: { label: "Facebook", icon: <FacebookIcon /> },
  youtube: { label: "YouTube", icon: <YouTubeIcon /> },
};

export function ReussirView({ plans }: { plans: PlanPublicResponse[] }) {
  const rootRef = useRef<HTMLDivElement | null>(null);
  useReveal(rootRef);

  useEffect(() => trackPageView(TRACKED_PATH), []);

  return (
    <div className={styles.page} ref={rootRef}>
      <Nav />
      <Hero />
      <MethodeSection />
      <DiagnosticSection />
      <RapportSection />
      <PlanSection />
      <CompetenceSection />
      <ComprehensionSection />
      <ConfirmationSection />
      <CiviqueSection />
      <EpreuvesSection />
      <ComparaisonSection />
      <PricingSection plans={plans} />
      <FinalSection />
      <FaqSection />
      <PageFooter />
      <StickyCta />
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
        <span className={styles.brand}>
          <span className={styles.cocarde} aria-hidden />
          Sejour<span className={styles.brandFr}>FR</span>
        </span>
        <span className={styles.navSpace} />
        <a href="#offres" className={styles.navGhost}>
          Offres
        </a>
        <DiagnosticCta variant="nav" />
      </div>
    </div>
  );
}

// ============================================================================
// ① HERO
// ============================================================================

function Hero() {
  const origin = useOrigin();

  return (
    <section className={`${styles.sec} ${styles.hero}`}>
      <div className={`${styles.wrap} ${styles.two}`}>
        <div>
          <span className={styles.heroBadge} data-rv>
            {origin ? NETWORKS[origin].icon : <Sparkles aria-hidden />}
            {origin ? (
              <>
                Tu arrives de <b>{NETWORKS[origin].label}</b>
              </>
            ) : (
              <>TCF IRN &amp; examen civique</>
            )}
          </span>

          <h1 className={`${styles.h1} ${styles.editorial}`} data-rv>
            Atteins ton niveau TCF avec un plan qui <em>s&apos;adapte à toi</em>.
          </h1>

          <p className={styles.lead} data-rv>
            Fais ton diagnostic&nbsp;: SejourFR détecte ce qui te bloque réellement et te
            montre quoi travailler aujourd&apos;hui pour progresser vers A2, B1 ou B2. Et
            l&apos;examen civique se prépare au même endroit.
          </p>

          <HeroModules />

          <div className={`${styles.ctas} ${styles.heroCtas}`} data-rv>
            <DiagnosticCta />
            <span className={styles.ctaNote}>≈ 8 min · Sans carte bancaire</span>
          </div>

          <ul className={styles.heroTrust} data-rv>
            <li>
              <Check aria-hidden /> 1 écrit + 1 oral
            </li>
            <li>
              <Check aria-hidden /> Résultat immédiat
            </li>
            <li>
              <Check aria-hidden /> Web et mobile
            </li>
          </ul>
        </div>

        <PlanShot />
      </div>
    </section>
  );
}

/**
 * Les deux examens obligatoires, côte à côte et à poids égal — c'est le premier
 * endroit où le visiteur apprend qu'il y en a **deux**, et il doit le
 * comprendre sans lire : quatre pictogrammes d'un côté (les épreuves du TCF),
 * cinq numéros de l'autre (les thèmes du livret citoyen).
 */
function HeroModules() {
  return (
    <div className={styles.modules} data-rv>
      <div className={styles.modBox}>
        <span className={styles.modName}>TCF IRN</span>
        <span className={styles.modIcons} aria-hidden>
          <i>
            <Headphones />
          </i>
          <i>
            <BookOpen />
          </i>
          <i>
            <PenLine />
          </i>
          <i>
            <Mic />
          </i>
        </span>
        <span className={styles.modFoot}>4 épreuves · A2 · B1 · B2</span>
      </div>

      <div className={styles.modBox} data-accent="red">
        <span className={styles.modName}>Examen civique</span>
        <span className={styles.modIcons} aria-hidden>
          {[1, 2, 3, 4, 5].map((n) => (
            <i key={n}>{n}</i>
          ))}
        </span>
        <span className={styles.modFoot}>5 thèmes · CSP · CR · NAT</span>
      </div>
    </div>
  );
}

/** Capture du Plan, en CSS pur : rien à maintenir, rien à re-shooter. */
function PlanShot() {
  return (
    <div className={styles.shot} data-rv>
      <div className={styles.shotTop}>
        <div className={styles.shotLab}>Ton niveau estimé</div>
        <div className={styles.shotLevels}>
          <span className={styles.shotNow}>A2</span>
          <span className={styles.shotDiv} aria-hidden />
          <span>
            <span className={styles.shotGoalLab}>Objectif</span>
            <span className={styles.shotGoal}>B2</span>
          </span>
        </div>
        <div className={styles.rail} aria-hidden>
          <span data-on="">A2</span>
          <i data-on="" />
          <span>B1</span>
          <i />
          <span>B2</span>
        </div>
      </div>

      <div className={`${styles.shotSec} ${styles.shotWash}`}>
        <span className={styles.eyebrow}>Priorité actuelle</span>
        <div className={styles.shotTitle}>Développer une réponse avec une précision</div>
        <p className={styles.mini}>Expression orale · Tâche 1</p>
        <div className={styles.dots} aria-hidden>
          <i data-on="" />
          <i />
          <i />
          <i />
          <i />
        </div>
      </div>

      <div className={styles.sep} />

      <div className={styles.shotSec}>
        <span className={styles.label}>Aujourd&apos;hui · 3 entraînements · 22 min</span>
        <div className={styles.shotList}>
          {[
            { mod: "EO", tone: styles.mRed, title: "Petit sujet : mes activités du week-end", meta: "Tâche 1 · 3 min" },
            { mod: "EE", tone: styles.mRed, title: "Raconter les actions dans l'ordre", meta: "Tâche 2 · 4 min" },
            { mod: "CO", tone: styles.mBlue, title: "Série ciblée · informations implicites", meta: "Niveau B1 · 8 min" },
          ].map((row) => (
            <div key={row.title} className={styles.rowI}>
              <span className={`${styles.mod} ${row.tone}`}>{row.mod}</span>
              <span className={styles.flex1}>
                <span className={styles.shotItem}>
                  <b>{row.title}</b>
                  <small>{row.meta}</small>
                </span>
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// ② LA MÉTHODE
// ============================================================================

const METHODE: { title: string; meta: string }[] = [
  { title: "Diagnostic", meta: "Ta capacité réelle à produire du français" },
  { title: "Tes priorités", meta: "Les compétences qui te bloquent" },
  { title: "Ton plan", meta: "Ce que tu travailles aujourd'hui" },
  { title: "Tes progrès", meta: "Mesurés sur chaque compétence" },
  { title: "Examen blanc", meta: "Pour confirmer ton nouveau niveau" },
];

function MethodeSection() {
  return (
    <section className={`${styles.sec} ${styles.white}`} id="methode">
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} data-rv>
          <h2 className={styles.h2}>
            Tu peux faire 500 exercices et continuer à travailler les mauvaises choses.
          </h2>
          <p className={styles.lead} style={{ marginTop: 16 }}>
            SejourFR ne se contente pas de compter tes bonnes réponses. Il construit ton
            profil compétence par compétence, et décide ce que tu dois travailler ensuite.
          </p>
        </div>

        <ol className={styles.flow}>
          {METHODE.map((step, i) => (
            <li key={step.title} data-rv>
              <span className={styles.flowNum}>{i + 1}</span>
              <span>
                <b>{step.title}</b>
                <small>{step.meta}</small>
              </span>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}

// ============================================================================
// ③ PAR OÙ COMMENCER — c'est ici que les deux examens se séparent
// ============================================================================

/**
 * Le temps de la **compréhension** annoncé par la carte « Diagnostic complet ».
 *
 * ⚠️ Recalculé depuis `lib/exam-durations.ts` — la seule table de durées du web,
 * miroir de `DureeEpreuve` — et **jamais écrit en dur** : raccourcir une épreuve
 * raccourcit la promesse. La maquette annonçait « ≈ 22 min » pour le parcours
 * complet ; la CO et la CE valent à elles seules 20 + 35 min.
 *
 * Aucun **total** n'est annoncé : les deux productions se mesurent sur les
 * bornes des sujets servis (`diagnosticWrittenMinutes` / `diagnosticOralMinutes`,
 * écran `DiagnosticIntro`), et aucun DTO n'est disponible sur une landing —
 * additionner ici reviendrait à fabriquer un chiffre.
 */
const DIAGNOSTIC_COMPREHENSION_LABEL = minutesLabel(
  EPREUVE_PLANNED_SEC.TCF_CO + EPREUVE_PLANNED_SEC.TCF_CE,
);

function DiagnosticSection() {
  const origin = useOrigin();

  return (
    <section className={`${styles.sec} ${styles.paper}`} id="diagnostic">
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} data-rv>
          <span className={styles.eyebrow}>Étape 1</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Commence par savoir où tu en es.
          </h2>
          <p className={styles.lead} style={{ marginTop: 14 }}>
            Pas un QCM de plus&nbsp;: tu produis du français, et l&apos;analyse porte sur
            ce que tu sais réellement faire. Deux formats, gratuits tous les deux.
          </p>
        </div>

        <div className={`${styles.grid} ${styles.g2}`} style={{ marginTop: 32, alignItems: "start" }}>
          <div className={`${styles.card} ${styles.cardHi}`} data-rv>
            <div className={`${styles.pad} ${styles.shotWash}`}>
              <div className={styles.rowI} style={{ flexWrap: "wrap", gap: 10 }}>
                <h3 className={styles.h3} style={{ fontSize: 21 }}>
                  Diagnostic rapide
                </h3>
                <span className={`${styles.pill} ${styles.pReco}`}>Recommandé</span>
              </div>
              <p className={styles.label} style={{ marginTop: 7 }}>
                Expression écrite + expression orale · ≈ 8 min
              </p>
              <p className={styles.leadSm} style={{ marginTop: 14 }}>
                Une estimation de ton niveau de production, et tes premières compétences à
                travailler. Sans compte pour commencer.
              </p>
              <DiagnosticCta variant="card" />
            </div>
          </div>

          <div className={styles.card} data-rv>
            <div className={styles.pad}>
              <h3 className={styles.h3} style={{ fontSize: 21 }}>
                Diagnostic complet
              </h3>
              <p className={styles.label} style={{ marginTop: 7 }}>
                EE + EO, puis CO + CE · {DIAGNOSTIC_COMPREHENSION_LABEL} de compréhension
              </p>
              <p className={styles.leadSm} style={{ marginTop: 14 }}>
                Ton profil sur les quatre épreuves du TCF. Tu commences par les mêmes
                exercices&nbsp;; la compréhension se joue juste après la création de ton
                compte, pour que ses résultats te restent.
              </p>
              <DiagnosticCta variant="cardAlt" />
            </div>
          </div>
        </div>

        <p className={styles.mini} style={{ textAlign: "center", marginTop: 16 }}>
          Tu peux commencer par l&apos;écrit et l&apos;oral, puis compléter la
          compréhension quand tu veux.
        </p>

        {/* L'examen civique n'est PAS un diagnostic : il n'a ni production, ni
            palier CECRL, ni compétences. Il a donc sa propre entrée, séparée des
            deux cartes ci-dessus — et sa propre mesure d'audience, sans quoi on
            savait combien de visiteurs voient cette offre, jamais combien y
            entrent. */}
        <div className={`${styles.card} ${styles.band}`} style={{ marginTop: 28 }} data-rv>
          <div className={`${styles.pad} ${styles.bandInner}`}>
            <span className={styles.bandBody}>
              <span className={styles.label}>Tu prépares aussi l&apos;examen civique&nbsp;?</span>
              <b className={styles.bandTitle}>Examen civique blanc</b>
              <span className={styles.mini}>
                40 questions · 45 min · les 5 thèmes. Le format réel de l&apos;épreuve, avec
                ton score et les thèmes qui te coûtent des points.
              </span>
            </span>
            <Link
              href={withTrafficSource("/examens-blancs/civique-decouverte", origin)}
              className={`${styles.btn} ${styles.btnO}`}
              onClick={() => trackAudienceEvent(TRACKED_PATH, "SOCIAL_LANDING_CIVIQUE_CLICKED")}
            >
              Passer l&apos;examen découverte
              <ArrowRight aria-hidden />
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ④ LE RAPPORT DE DIAGNOSTIC
// ============================================================================

const PRIORITES_VISIBLES: { mod: string; tone: string; title: string; meta: string; pill: string; pillTone: string }[] = [
  {
    mod: "EO",
    tone: "mOn",
    title: "Développer une réponse avec une précision",
    meta: "Expression orale · Tâche 1",
    pill: "Priorité",
    pillTone: "pPrio",
  },
  {
    mod: "EE",
    tone: "mRed",
    title: "Raconter les actions dans l'ordre",
    meta: "Expression écrite · Tâche 2",
    pill: "À renforcer",
    pillTone: "pRenf",
  },
  {
    mod: "EO",
    tone: "mRed",
    title: "Poser une question de suivi",
    meta: "Expression orale · Tâche 2",
    pill: "À renforcer",
    pillTone: "pRenf",
  },
];

const PRIORITES_FLOUTEES: { mod: string; title: string; meta: string }[] = [
  { mod: "EE", title: "Utiliser les temps du passé", meta: "Expression écrite · Tâche 2" },
  { mod: "EO", title: "Réagir à une relance", meta: "Expression orale · Tâche 1" },
];

function RapportSection() {
  return (
    <section className={`${styles.sec} ${styles.white}`}>
      <div className={`${styles.wrap} ${styles.twoT}`}>
        <div>
          <span className={styles.eyebrow} data-rv>
            Étape 2
          </span>
          <h2 className={styles.h2} style={{ marginTop: 14 }} data-rv>
            SejourFR ne te dit pas seulement que tu es A2. Il sait pourquoi.
          </h2>
          <p className={styles.lead} style={{ marginTop: 16 }} data-rv>
            À la fin du diagnostic, tu reçois un rapport&nbsp;: ton niveau estimé, tes
            points forts, et les compétences précises qui t&apos;empêchent d&apos;atteindre
            ton objectif.
          </p>
          <div className={styles.ctas} style={{ marginTop: 24 }} data-rv>
            <DiagnosticCta />
            <span className={styles.ctaNote}>≈ 8 min · Sans carte bancaire</span>
          </div>
        </div>

        <div className={styles.card} style={{ overflow: "hidden" }} data-rv>
          <div className={styles.pad} style={{ paddingBottom: 14 }}>
            <span className={styles.label}>Tes principales priorités</span>
          </div>
          <div className={styles.sep} />

          {PRIORITES_VISIBLES.map((p) => (
            <div key={p.title}>
              <div className={`${styles.pad} ${styles.rowI}`} style={{ padding: "14px 20px" }}>
                <span className={`${styles.mod} ${styles[p.tone]}`}>{p.mod}</span>
                <span className={styles.flex1}>
                  <span className={styles.shotItem}>
                    <b>{p.title}</b>
                    <small>{p.meta}</small>
                  </span>
                </span>
                <span className={`${styles.pill} ${styles[p.pillTone]}`}>{p.pill}</span>
              </div>
              <div className={styles.sep} />
            </div>
          ))}

          <div className={styles.blur} aria-hidden>
            {PRIORITES_FLOUTEES.map((p) => (
              <div key={p.title} className={`${styles.pad} ${styles.rowI}`} style={{ padding: "14px 20px" }}>
                <span className={`${styles.mod} ${styles.mRed}`}>{p.mod}</span>
                <span className={styles.flex1}>
                  <span className={styles.shotItem}>
                    <b>{p.title}</b>
                    <small>{p.meta}</small>
                  </span>
                </span>
              </div>
            ))}
          </div>

          <div className={styles.lockbar}>
            <Lock aria-hidden />+ 5 autres priorités détectées
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑤ LE PLAN
// ============================================================================

const PLAN_POINTS: string[] = [
  "Jamais 7 priorités identiques : une seule chose à faire maintenant",
  "Chaque exercice est relié à une compétence, jamais à un numéro de série",
  "Après une réussite, tu vois ce qui change dans ton plan",
];

/** Une étape du Plan vaut 5 petits sujets (`LearningPlanStep.PROMPTS_PAR_ETAPE`). */
const PLAN_ROWS: { mod: string; tone: string; title: string; pill: string; pillTone: string; done: number | null; note: string }[] = [
  {
    mod: "EO",
    tone: "mRed",
    title: "Développer une réponse avec une précision",
    pill: "Priorité",
    pillTone: "pPrio",
    done: 1,
    note: "1 / 5 petits sujets traités",
  },
  {
    mod: "EE",
    tone: "mRed",
    title: "Raconter les actions dans l'ordre",
    pill: "À renforcer",
    pillTone: "pRenf",
    done: 2,
    note: "2 / 5 petits sujets traités",
  },
  {
    mod: "CO",
    tone: "mBlue",
    title: "Informations implicites · B1",
    pill: "À évaluer",
    pillTone: "pNeu",
    done: null,
    note: "Une série de 20 questions complétera ton profil",
  },
];

function PlanSection() {
  return (
    <section className={`${styles.sec} ${styles.paper}`}>
      <div className={`${styles.wrap} ${styles.twoT}`}>
        <div>
          <span className={styles.eyebrow} data-rv>
            Étape 3
          </span>
          <h2 className={styles.h2} style={{ marginTop: 14 }} data-rv>
            Et ensuite, SejourFR te dit exactement quoi travailler.
          </h2>
          <p className={styles.lead} style={{ marginTop: 16 }} data-rv>
            Une priorité principale, une séance courte, et des petits sujets ciblés. Ton
            plan évolue après chaque entraînement&nbsp;: une difficulté reste dans ta
            séance jusqu&apos;à ce qu&apos;elle soit réellement maîtrisée.
          </p>
          <ul className={styles.stack} style={{ marginTop: 22 }} data-rv>
            {PLAN_POINTS.map((point) => (
              <li key={point} className={styles.rowI}>
                <Check className={styles.tick} aria-hidden />
                <span style={{ fontSize: 15 }}>{point}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className={styles.card} style={{ overflow: "hidden" }} data-rv>
          <div className={`${styles.pad} ${styles.shotWash}`}>
            <span className={styles.eyebrow}>Priorité actuelle</span>
            <div className={styles.shotTitle} style={{ fontSize: 19 }}>
              Développer une réponse avec une précision
            </div>
            <p className={styles.mini} style={{ marginTop: 6 }}>
              Tes réponses sont compréhensibles mais encore trop courtes. Objectif&nbsp;:
              ajouter naturellement une précision.
            </p>
          </div>
          <div className={styles.sep} />
          <div className={styles.pad}>
            <span className={styles.label}>Mes priorités</span>
            <div className={styles.stack} style={{ marginTop: 14 }}>
              {PLAN_ROWS.map((row) => (
                <div key={row.title}>
                  <div className={styles.rowI}>
                    <span className={`${styles.mod} ${styles[row.tone]}`}>{row.mod}</span>
                    <span className={styles.flex1} style={{ fontSize: 14.5, fontWeight: 600 }}>
                      {row.title}
                    </span>
                    <span className={`${styles.pill} ${styles[row.pillTone]}`}>{row.pill}</span>
                  </div>
                  {row.done !== null && (
                    <div className={styles.dots} style={{ marginLeft: 46 }} aria-hidden>
                      {[0, 1, 2, 3, 4].map((i) => (
                        <i key={i} data-on={i < row.done! ? "" : undefined} />
                      ))}
                    </div>
                  )}
                  <p className={styles.mini} style={{ marginLeft: 46, marginTop: 5 }}>
                    {row.note}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑥ COMPÉTENCE → VALIDATION
// ============================================================================

const COMPETENCE_FLOW: { title: string; meta: string }[] = [
  { title: "Une compétence", meta: "Ex. développer une réponse" },
  { title: "5 petits sujets", meta: "3 à 4 min chacun" },
  { title: "Correction IA", meta: "Ce qui marche, ce qui bloque" },
  { title: "Version au niveau visé", meta: "Ta réponse, réécrite en B1" },
  { title: "Tâche complète", meta: "La compétence est validée" },
];

function CompetenceSection() {
  return (
    <section className={`${styles.sec} ${styles.white}`}>
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} data-rv>
          <span className={styles.eyebrow}>Expression écrite &amp; orale</span>
          <h2 className={styles.h2} style={{ marginTop: 14 }}>
            Tu ne t&apos;entraînes pas «&nbsp;sur la tâche 2&nbsp;». Tu travailles une
            difficulté précise.
          </h2>
          <p className={styles.lead} style={{ marginTop: 14 }}>
            Chaque compétence se travaille sur de petits sujets courts. La correction IA te
            montre ce qui manque, puis la même réponse écrite au niveau que tu vises.
          </p>
        </div>

        <ol className={styles.flow}>
          {COMPETENCE_FLOW.map((step, i) => (
            <li key={step.title} data-rv>
              <span className={styles.flowNum}>{i + 1}</span>
              <span>
                <b>{step.title}</b>
                <small>{step.meta}</small>
              </span>
            </li>
          ))}
        </ol>

        <div className={`${styles.card} ${styles.rewrite}`} data-rv>
          <div className={styles.pad} style={{ paddingBottom: 0 }}>
            <span className={styles.label}>Ta réponse · niveau A2</span>
            <p className={styles.quoteBefore}>
              Je travaille dans une entreprise. C&apos;est bien.
            </p>
          </div>
          <div className={styles.pad}>
            <span className={`${styles.label} ${styles.labelBrand}`}>La même réponse en B1</span>
            <p className={styles.quoteAfter}>
              Je travaille comme technicien de maintenance dans une entreprise de Lyon,{" "}
              <mark>depuis bientôt deux ans</mark>. Ce que j&apos;aime le plus, c&apos;est{" "}
              <mark>de résoudre une panne que personne n&apos;avait comprise</mark>.
            </p>
            <div className={styles.gains}>
              <span className={`${styles.pill} ${styles.pNeu}`}>+ une précision de durée</span>
              <span className={`${styles.pill} ${styles.pNeu}`}>+ un exemple concret</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑦ COMPRÉHENSION ORALE & ÉCRITE
// ============================================================================

const COMPREHENSION: { level: string; title: string; meta: string; pill: string; pillTone: string; hi?: boolean }[] = [
  {
    level: "A2",
    title: "Information explicite",
    meta: "Ce qui est dit clairement",
    pill: "Solide",
    pillTone: "pSol",
  },
  {
    level: "B1",
    title: "Sens global et intention",
    meta: "Message plus long, moins direct",
    pill: "En cours",
    pillTone: "pRenf",
    hi: true,
  },
  {
    level: "B2",
    title: "Implicite et nuances",
    meta: "Réponses proches, sous-entendus",
    pill: "À venir",
    pillTone: "pNeu",
  },
];

function ComprehensionSection() {
  return (
    <section className={`${styles.sec} ${styles.paper}`}>
      <div className={`${styles.wrap} ${styles.twoT}`}>
        <div>
          <span className={styles.eyebrow} data-rv>
            Compréhension orale &amp; écrite
          </span>
          <h2 className={styles.h2} style={{ marginTop: 14 }} data-rv>
            Des séries ciblées sur le niveau qui te bloque.
          </h2>
          <p className={styles.lead} style={{ marginTop: 16 }} data-rv>
            Pas 20 questions au hasard&nbsp;: des séries de 20 questions choisies sur le
            palier où tu perds encore des points, puis un palier au-dessus quand celui-ci
            devient stable.
          </p>
        </div>

        <ul className={styles.ladder}>
          {COMPREHENSION.map((l) => (
            <li key={l.level} data-hi={l.hi ? "" : undefined} data-rv>
              <span className={styles.ladderLv}>{l.level}</span>
              <span className={styles.flex1}>
                <b>{l.title}</b>
                <small>{l.meta}</small>
              </span>
              <span className={`${styles.pill} ${styles[l.pillTone]}`}>{l.pill}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}

// ============================================================================
// ⑧ CONFIRMATION DU NIVEAU
// ============================================================================

const CONFIRMATION_ROWS: { mod: string; tone: string; label: string }[] = [
  { mod: "CO", tone: "mBlue", label: "Compréhension orale" },
  { mod: "CE", tone: "mBlue", label: "Compréhension écrite" },
  { mod: "EO", tone: "mRed", label: "Expression orale" },
  { mod: "EE", tone: "mRed", label: "Expression écrite" },
];

function ConfirmationSection() {
  return (
    <section className={`${styles.sec} ${styles.white}`}>
      <div className={`${styles.wrap} ${styles.twoT}`}>
        <div>
          <span className={styles.eyebrow} data-rv>
            Étape 4
          </span>
          <h2 className={styles.h2} style={{ marginTop: 14 }} data-rv>
            Pas de faux badge B1 après quelques exercices.
          </h2>
          <p className={styles.lead} style={{ marginTop: 16 }} data-rv>
            Quand les compétences que tu devais travailler deviennent solides, SejourFR te
            propose un examen blanc complet. C&apos;est lui qui confirme ton nouveau niveau
            estimé — puis un nouveau plan démarre vers le palier suivant.
          </p>
          <p className={styles.mini} style={{ marginTop: 18 }} data-rv>
            Estimation d&apos;entraînement SejourFR, non officielle. Elle ne remplace pas le
            résultat du TCF.
          </p>
        </div>

        <div className={`${styles.card} ${styles.pad}`} data-rv>
          <div className={styles.stack}>
            {CONFIRMATION_ROWS.map((row, i) => (
              <div key={row.mod}>
                <div className={styles.rowI}>
                  <span className={`${styles.mod} ${styles[row.tone]}`}>{row.mod}</span>
                  <span className={styles.flex1} style={{ fontSize: 15, fontWeight: 600 }}>
                    {row.label}
                  </span>
                  <span className={`${styles.pill} ${styles.pSol}`}>Solide</span>
                </div>
                {i < CONFIRMATION_ROWS.length - 1 && (
                  <div className={styles.sep} style={{ marginTop: 14 }} />
                )}
              </div>
            ))}
          </div>

          <div className={styles.verdict}>
            <div className={styles.verdictLab}>Après l&apos;examen blanc</div>
            <div className={styles.verdictLvl}>Niveau estimé B1 confirmé</div>
            <div className={styles.verdictNote}>Ton plan repart vers le B2.</div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑨ EXAMEN CIVIQUE — son propre fil, court et honnête
// ============================================================================

/**
 * Les 5 thèmes officiels, dans l'ordre `display_order` de la base
 * (`V101__ref_themes.sql`). Libellés et descriptions repris **mot pour mot**
 * du seed : c'est le contenu qui fait foi, pas une reformulation marketing.
 * Le slug de route est dérivé du code comme le fait `lib/themes.ts`.
 */
const CIVIQUE_THEMES: { slug: string; name: string; desc: string; icon: ReactElement }[] = [
  {
    slug: "principes",
    name: "Principes et valeurs de la République",
    desc: "Devise, symboles, laïcité, liberté, égalité, fraternité",
    icon: <Scale aria-hidden />,
  },
  {
    slug: "institutions",
    name: "Système institutionnel et politique",
    desc: "Constitution, président, parlement, séparation des pouvoirs",
    icon: <Landmark aria-hidden />,
  },
  {
    slug: "droits-devoirs",
    name: "Droits et devoirs",
    desc: "Charte des droits et devoirs du citoyen français",
    icon: <Gavel aria-hidden />,
  },
  {
    slug: "histoire-geo",
    name: "Histoire, géographie et culture",
    desc: "Repères historiques, géographie, patrimoine culturel",
    icon: <Globe aria-hidden />,
  },
  {
    slug: "societe",
    name: "Vivre dans la société française",
    desc: "Vie quotidienne, services publics, vivre-ensemble",
    icon: <Users aria-hidden />,
  },
];

/** Chiffres du gabarit d'examen civique (`V110__ref_exam_templates.sql`). */
const CIVIQUE_FACTS: { n: string; label: string }[] = [
  { n: "20", label: "questions par série d'entraînement, correction expliquée après chaque réponse" },
  { n: "40", label: "questions par examen blanc, 8 par thème, en 45 minutes" },
  { n: "32", label: "bonnes réponses sur 40 attendues pour valider, soit 80 %" },
];

/**
 * Les 3 démarches. C'est le seul endroit de la page où les deux examens se
 * rejoignent : une démarche exige **à la fois** la mention civique et un palier
 * TCF (`TCF_LEVEL_BY_PROCEDURE`, seuils du 1ᵉʳ janvier 2026).
 */
const DEMARCHES: { level: string; procedure: string; mention: string; hi?: boolean }[] = [
  { level: "A2", procedure: "Titre de séjour pluriannuel", mention: "Examen civique · mention CSP" },
  { level: "B1", procedure: "Carte de résident", mention: "Examen civique · mention CR" },
  { level: "B2", procedure: "Naturalisation française", mention: "Examen civique · mention NAT", hi: true },
];

function CiviqueSection() {
  const origin = useOrigin();

  return (
    <section className={`${styles.sec} ${styles.paper}`} id="civique">
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} data-rv>
          <span className={styles.eyebrow}>Le second examen obligatoire</span>
          <h2 className={`${styles.h2} ${styles.editorial}`} style={{ marginTop: 14 }}>
            L&apos;<em>examen civique</em> ne se prépare pas comme le TCF.
          </h2>
          <p className={styles.lead} style={{ marginTop: 14 }}>
            Ici, pas de production ni de niveau CECRL&nbsp;: c&apos;est un QCM sur cinq
            thèmes officiels, et ce qui compte est de reconnaître la bonne réponse. On te
            l&apos;entraîne donc autrement — par séries courtes, thème par thème, jusqu&apos;au
            format réel de l&apos;épreuve.
          </p>
        </div>

        <div className={styles.civGrid}>
          <div>
            <span className={styles.label} data-rv>
              Les 5 thèmes officiels
            </span>
            <div className={styles.civCats} style={{ marginTop: 12 }}>
              {CIVIQUE_THEMES.map((theme, i) => (
                <Link
                  key={theme.slug}
                  href={withTrafficSource(`/entrainement/civique/${theme.slug}`, origin)}
                  className={styles.civCat}
                  data-rv
                >
                  <span className={styles.civNum} aria-hidden>
                    {i + 1}
                  </span>
                  <span className={styles.flex1}>
                    <b>{theme.name}</b>
                    <small className={styles.mini}>{theme.desc}</small>
                  </span>
                  <span className={styles.eprIco} aria-hidden>
                    {theme.icon}
                  </span>
                </Link>
              ))}
            </div>
          </div>

          <div className={styles.civSide}>
            <div>
              <span className={styles.label} data-rv>
                Comment on t&apos;y entraîne
              </span>
              <div className={styles.civFacts} style={{ marginTop: 12 }}>
                {CIVIQUE_FACTS.map((fact) => (
                  <div key={fact.n} className={styles.civFact} data-rv>
                    <span className={styles.civFactN}>{fact.n}</span>
                    <span>{fact.label}</span>
                  </div>
                ))}
              </div>
              <p className={styles.mini} style={{ marginTop: 12 }} data-rv>
                Deux formats de question, comme à l&apos;examen&nbsp;: Connaissance et Mise
                en situation.
              </p>
            </div>

            <div data-rv>
              <span className={styles.label}>Ta démarche exige les deux</span>
              <ul className={styles.ladder} style={{ marginTop: 12 }}>
                {DEMARCHES.map((d) => (
                  <li key={d.level} data-hi={d.hi ? "" : undefined}>
                    <span className={styles.ladderLv}>{d.level}</span>
                    <span className={styles.flex1}>
                      <b>{d.procedure}</b>
                      <small>{d.mention}</small>
                    </span>
                  </li>
                ))}
              </ul>
              <p className={styles.mini} style={{ marginTop: 12 }}>
                Le palier TCF est exigé dans les 4 épreuves, et la mention civique
                correspond à ta démarche.
              </p>
            </div>
          </div>
        </div>

        <div className={`${styles.card} ${styles.pad} ${styles.eprWide}`} data-rv>
          <div>
            <h3 className={styles.h3}>Le pass Civique ouvre les 5 thèmes</h3>
            <p className={styles.mini} style={{ marginTop: 5 }}>
              Séries illimitées et examens blancs. Le pass Intégral les contient aussi.
            </p>
          </div>
          <a href="#offres" className={`${styles.btn} ${styles.btnO} ${styles.btnSm}`}>
            Voir les offres
            <ArrowRight aria-hidden />
          </a>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑩ LES ÉPREUVES DU TCF
// ============================================================================

/** Durées réelles d'épreuve (`DureeEpreuve` côté serveur). Le chrono global de
 *  90 min n'existe plus : chaque épreuve porte le sien, et l'oral se chronomètre
 *  par tâche. Ne pas réintroduire de total opposable. */
const EPREUVES: { href: string; title: string; tag: string; icon: ReactElement; red?: boolean }[] = [
  {
    href: "/entrainement/tcf/co",
    title: "Compréhension orale",
    tag: "Séries ciblées par palier · 20 min",
    icon: <Headphones aria-hidden />,
  },
  {
    href: "/entrainement/tcf/ce",
    title: "Compréhension écrite",
    tag: "Documents courts puis complexes · 35 min",
    icon: <BookOpen aria-hidden />,
  },
  {
    href: "/entrainement/tcf/ee",
    title: "Expression écrite",
    tag: "Les 3 tâches, corrigées et réécrites · 30 min",
    icon: <PenLine aria-hidden />,
    red: true,
  },
  {
    href: "/entrainement/tcf/eo",
    title: "Expression orale",
    tag: "Les 3 tâches, enregistrées et analysées",
    icon: <Mic aria-hidden />,
    red: true,
  },
];

function EpreuvesSection() {
  const origin = useOrigin();

  return (
    <section className={`${styles.sec} ${styles.white}`}>
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} data-rv>
          <h2 className={styles.h2}>Les 4 épreuves, et l&apos;examen en conditions réelles.</h2>
        </div>

        <div className={`${styles.grid} ${styles.g4}`} style={{ marginTop: 28 }}>
          {EPREUVES.map((e) => (
            <Link
              key={e.title}
              href={withTrafficSource(e.href, origin)}
              className={`${styles.card} ${styles.pad}`}
              data-rv
            >
              <span className={styles.eprIco} data-accent={e.red ? "red" : undefined}>
                {e.icon}
              </span>
              <h3 className={styles.h3} style={{ marginTop: 12 }}>
                {e.title}
              </h3>
              <p className={styles.mini} style={{ marginTop: 6 }}>
                {e.tag}
              </p>
            </Link>
          ))}
        </div>

        <div className={`${styles.card} ${styles.pad} ${styles.eprWide}`} data-rv>
          <div>
            <h3 className={styles.h3}>Examens blancs complets</h3>
            <p className={styles.mini} style={{ marginTop: 5 }}>
              Dans les conditions du TCF, quand ton plan estime que tu es prêt. Le premier
              est offert, sur le TCF comme sur le civique.
            </p>
          </div>
          <Link
            href={withTrafficSource("/examens-blancs", origin)}
            className={`${styles.btn} ${styles.btnO} ${styles.btnSm}`}
          >
            Voir les examens blancs
            <ArrowRight aria-hidden />
          </Link>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑪ COMPARAISON
// ============================================================================

const SEUL: string[] = [
  "Choisir des exercices au hasard",
  "Connaître seulement son score",
  "Ne pas savoir quoi travailler ensuite",
  "Répéter les mêmes erreurs",
];

const AVEC: string[] = [
  "Savoir où tu en es, épreuve par épreuve",
  "Identifier les compétences qui bloquent",
  "Travailler 20 min sur ce qui compte",
  "Vérifier son niveau en examen blanc",
];

function ComparaisonSection() {
  return (
    <section className={`${styles.sec} ${styles.paper}`}>
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} data-rv>
          <h2 className={styles.h2}>
            La différence tient en une chose&nbsp;: savoir quoi travailler.
          </h2>
        </div>

        <div className={styles.cmp}>
          <div className={`${styles.card} ${styles.pad}`} data-rv>
            <h3 className={styles.h3}>S&apos;entraîner seul</h3>
            <ul>
              {SEUL.map((item) => (
                <li key={item}>
                  <span className={styles.cross} aria-hidden>
                    ✕
                  </span>
                  {item}
                </li>
              ))}
            </ul>
          </div>

          <div className={`${styles.card} ${styles.pad} ${styles.cmpHi}`} data-rv>
            <h3 className={styles.h3}>Avec SejourFR</h3>
            <ul>
              {AVEC.map((item) => (
                <li key={item}>
                  <Check className={styles.tick} aria-hidden />
                  {item}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑫ TARIFS
// ============================================================================

function PricingSection({ plans }: { plans: PlanPublicResponse[] }) {
  const [parcours, setParcours] = useState<Parcours>("tcf");
  const { status, user } = useAuth();
  const isAuth = status === "authenticated" && user !== null;
  // La provenance suit le visiteur jusqu'à la porte du compte : sans elle, une
  // inscription venue de TikTok devient indistinguable d'un accès direct.
  const origin = useOrigin();

  const byParcours = useMemo(() => {
    const passes = plans.filter((p) => p.purchaseType === "ONE_TIME" && p.price > 0);
    const sort = (list: PlanPublicResponse[]) =>
      [...list].sort((a, b) => a.durationDays - b.durationDays);
    return {
      tcf: sort(passes.filter((p) => p.moduleAccess === "INTEGRAL")),
      civique: sort(passes.filter((p) => p.moduleAccess === "CIVIQUE")),
    };
  }, [plans]);

  const visible = byParcours[parcours];
  if (byParcours.tcf.length === 0 && byParcours.civique.length === 0) return null;

  const popular = popularPassCodeOf(visible);

  return (
    <section className={`${styles.sec} ${styles.white}`} id="offres">
      <div className={styles.wrap}>
        <div className={`${styles.narrow} ${styles.center}`} data-rv>
          <h2 className={`${styles.h2} ${styles.editorial}`}>
            Le diagnostic est gratuit. Tu paies <em>une fois</em>, sans abonnement.
          </h2>
          <p className={styles.lead} style={{ marginTop: 14 }}>
            Tu débloques ton plan personnalisé, tous tes petits sujets, les corrections IA
            et les examens blancs.
          </p>
        </div>

        <div style={{ marginTop: 28 }}>
          <div className={styles.switch} role="group" aria-label="Choisir son parcours" data-rv>
            <button
              type="button"
              data-parcours="tcf"
              aria-pressed={parcours === "tcf"}
              onClick={() => setParcours("tcf")}
            >
              TCF IRN + civique
            </button>
            <button
              type="button"
              data-parcours="civique"
              aria-pressed={parcours === "civique"}
              onClick={() => setParcours("civique")}
            >
              Examen civique seul
            </button>
          </div>
        </div>

        <div className={styles.plans} data-accent={parcours} data-count={visible.length}>
          {visible.map((plan) => (
            <PlanCard
              key={plan.code}
              plan={plan}
              popular={plan.code === popular}
              isAuth={isAuth}
              origin={origin}
            />
          ))}
        </div>

        <ul className={styles.noabo} data-rv>
          <li>Sans reconduction</li>
          <li>Durées cumulables</li>
          <li>Web &amp; mobile</li>
          <li>Paiement Stripe</li>
        </ul>

        <p className={styles.plansNote} data-rv>
          {parcours === "tcf" ? (
            <>Les pass Intégral contiennent aussi tout l&apos;examen civique.</>
          ) : (
            <>
              Tu passes aussi le TCF&nbsp;IRN&nbsp;?{" "}
              <button type="button" onClick={() => setParcours("tcf")}>
                Voir les pass Intégral
              </button>
              .
            </>
          )}
        </p>

        <Link href={withTrafficSource("/tarifs", origin)} className={styles.linkArrow} data-rv>
          Comparer toutes les formules
          <ArrowRight aria-hidden />
        </Link>
      </div>
    </section>
  );
}

function PlanCard({
  plan,
  popular,
  isAuth,
  origin,
}: {
  plan: PlanPublicResponse;
  popular: boolean;
  isAuth: boolean;
  origin: TrafficSource | null;
}) {
  const hasOral = plan.moduleAccess === "INTEGRAL";
  const monthly = passMonthlyLabel(plan);
  // Un clic sur un prix mène au RÉCAPITULATIF du pass cliqué — même geste, même
  // destination que sur /tarifs (`lib/passes.ts`). Non connecté : on passe par
  // l'inscription en gardant la destination, le nouvel inscrit retombe sur le
  // pass qu'il vient de choisir et non au dashboard.
  const href = passCheckoutHref(plan.code, isAuth, origin);

  return (
    <article className={`${styles.plan} ${popular ? styles.planHi : ""}`} data-rv>
      {popular && <span className={styles.planTag}>Le plus choisi</span>}
      <span className={styles.planName}>{planShortName(plan)}</span>
      <span className={styles.planPrice}>
        <b>{formatPassPrice(plan.price)}&nbsp;€</b>
        <span>payés une fois</span>
      </span>
      <span className={styles.planDur}>
        {passDurationLabel(plan.durationDays)} d&apos;accès
        {monthly !== null ? ` · ${monthly}` : ""}
      </span>

      <span className={styles.planSessions} data-none={hasOral ? undefined : ""}>
        {sessionsLabel(plan)}
      </span>

      <ul className={styles.planFeatures}>
        {featuresOf(plan).map((f) => (
          <li key={f}>
            <Check aria-hidden />
            {f}
          </li>
        ))}
      </ul>

      <Link href={href} className={styles.planGo}>
        Choisir ce pass
      </Link>
    </article>
  );
}

// ============================================================================
// ⑬ BLOC FINAL
// ============================================================================

function FinalSection() {
  return (
    <section className={`${styles.sec} ${styles.paper} ${styles.tight}`}>
      <div className={styles.wrap}>
        <div className={styles.final} data-rv>
          <div>
            <h2 className={styles.h2}>Arrête de deviner ce que tu dois travailler.</h2>
            <p className={styles.finalLead}>
              Fais ton diagnostic, et laisse SejourFR construire ton chemin jusqu&apos;au
              niveau dont tu as besoin — TCF et examen civique compris.
            </p>
          </div>
          <div className={styles.finalCtas}>
            <DiagnosticCta variant="onBrand" />
            <span className={styles.ctaNote}>≈ 8 min · Sans carte bancaire</span>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑭ FAQ
// ============================================================================

const FAQ: { q: string; a: string; open?: boolean }[] = [
  {
    q: "Le diagnostic est-il vraiment gratuit ?",
    a: "Oui. Tu fais le diagnostic et tu reçois ton rapport sans carte bancaire. Le plan personnalisé complet fait partie du pass.",
    open: true,
  },
  {
    q: "Combien de temps prend-il ?",
    a: "Environ 8 minutes : un exercice d'expression écrite, puis un oral enregistré. L'analyse arrive juste après.",
  },
  {
    q: "SejourFR prépare-t-il aussi l'examen civique ?",
    a: "Oui, et c'est un parcours distinct : les 5 thèmes officiels, des séries de 20 questions avec correction expliquée, et des examens blancs au format réel. Le pass Intégral contient le TCF et le civique ; le pass Civique ne contient que le civique.",
  },
  {
    q: "À quoi ressemble l'examen civique blanc ?",
    a: "40 questions en 45 minutes, réparties sur les 5 thèmes officiels, avec des questions de connaissance et des mises en situation. Il faut 32 bonnes réponses sur 40 pour le valider, soit 80 %. Le premier examen blanc est gratuit.",
  },
  {
    q: "Quel niveau et quelle mention me faut-il ?",
    a: "Cela dépend de ta démarche : titre de séjour pluriannuel (A2 et mention CSP), carte de résident (B1 et mention CR), naturalisation (B2 et mention NAT). Le palier TCF est exigé dans les 4 épreuves.",
  },
  {
    q: "SejourFR prépare-t-il les 4 épreuves du TCF ?",
    a: "Oui : compréhension orale, compréhension écrite, expression écrite et expression orale, avec des examens blancs complets.",
  },
  {
    q: "Comment sont corrigés l'écrit et l'oral ?",
    a: "Par une IA, sur une grille SejourFR alignée sur les dimensions évaluées au TCF. Elle te rend un niveau, ce qui marche, ce qui bloque, et ta réponse réécrite au niveau que tu vises. À l'oral, l'analyse porte sur la transcription : la prononciation n'est jamais notée.",
  },
  {
    q: "Est-ce que ça marche sur mobile ?",
    a: "SejourFR est conçu mobile d'abord, et fonctionne aussi sur ordinateur avec le même compte, le même plan et la même progression.",
  },
  {
    q: "SejourFR garantit-il un résultat à l'examen ?",
    a: "Non. SejourFR estime ton niveau d'entraînement et t'aide à le préparer, mais ne garantit pas le résultat officiel du TCF ni de l'examen civique, et n'est affilié à aucune administration.",
  },
];

function FaqSection() {
  return (
    <section className={`${styles.sec} ${styles.paper} ${styles.tight}`}>
      <div className={`${styles.wrap} ${styles.narrow}`}>
        <h2 className={styles.h2} data-rv>
          Questions fréquentes
        </h2>
        <div className={styles.faq} data-rv>
          {FAQ.map((item) => (
            <details key={item.q} open={item.open}>
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
// ⑮ PIED DE PAGE AUTOPORTANT
// ============================================================================

function PageFooter() {
  const socials = SOCIAL_ACCOUNTS.filter((s) => s.url !== null);

  return (
    <footer className={`${styles.sec} ${styles.foot} ${styles.tight}`}>
      <div className={`${styles.wrap} ${styles.footGrid}`}>
        <div data-rv>
          <span className={styles.brand}>
            <span className={styles.cocarde} aria-hidden />
            Sejour<span className={styles.brandFr}>FR</span>
          </span>
          <p className={styles.footNote}>
            Préparation au TCF IRN et à l&apos;examen civique d&apos;intégration
            républicaine. Estimation d&apos;entraînement, non officielle. SejourFR
            n&apos;est affilié à aucune administration française.
          </p>

          <div className={styles.stores}>
            <a className={styles.store} href={STORE_LINKS.ios} target="_blank" rel="noopener noreferrer">
              <AppleIcon />
              <span>
                <small>Télécharger sur</small>
                <b>App Store</b>
              </span>
            </a>
            <a className={styles.store} href={STORE_LINKS.android} target="_blank" rel="noopener noreferrer">
              <PlayIcon />
              <span>
                <small>Disponible sur</small>
                <b>Google Play</b>
              </span>
            </a>
          </div>

          <ul className={styles.legal}>
            <li>
              <Link href="/mentions-legales">Mentions légales</Link>
            </li>
            <li>
              <Link href="/cgu">CGU</Link>
            </li>
            <li>
              <Link href="/confidentialite">Confidentialité</Link>
            </li>
            <li>
              <Link href="/a-propos">Non affilié à l&apos;État français</Link>
            </li>
          </ul>
        </div>

        <div className={styles.biolinks} data-rv>
          <Link href="/blog" className={styles.biolink}>
            <span className={styles.biolinkIco}>
              <FileText aria-hidden />
            </span>
            <span>
              <b>Conseils TCF &amp; examen civique</b>
              <small>Le blog — articles gratuits</small>
            </span>
            <span className={styles.biolinkGo} aria-hidden>
              →
            </span>
          </Link>

          {socials.map((s) => (
            <a
              key={s.key}
              href={s.url ?? "#"}
              target="_blank"
              rel="noopener noreferrer"
              className={styles.biolink}
            >
              <span className={styles.biolinkIco}>{NETWORKS[s.key]?.icon}</span>
              <span>
                <b>{s.label}</b>
                <small>{s.handle}</small>
              </span>
              <span className={styles.biolinkGo} aria-hidden>
                →
              </span>
            </a>
          ))}

          <Link href="/faq" className={styles.biolink}>
            <span className={styles.biolinkIco}>
              <CircleHelp aria-hidden />
            </span>
            <span>
              <b>Questions fréquentes</b>
              <small>TCF IRN, civique, niveaux exigés</small>
            </span>
            <span className={styles.biolinkGo} aria-hidden>
              →
            </span>
          </Link>

          <Link href="/contact" className={styles.biolink}>
            <span className={styles.biolinkIco}>
              <Mail aria-hidden />
            </span>
            <span>
              <b>Une question&nbsp;?</b>
              <small>Écris-nous, on répond</small>
            </span>
            <span className={styles.biolinkGo} aria-hidden>
              →
            </span>
          </Link>
        </div>
      </div>
    </footer>
  );
}

// ============================================================================
// CTA DIAGNOSTIC (unique point de mesure) + STICKY
// ============================================================================

/**
 * Le CTA diagnostic, partagé par la nav, le hero, le rapport, le bloc final et
 * la barre collante. Passer par un composant unique garantit que tous les
 * points d'entrée sont mesurés de la même façon — un bouton ajouté ailleurs
 * sans lui serait un trou silencieux dans le taux de conversion.
 */
function DiagnosticCta({
  variant = "hero",
}: {
  /** `cardAlt` = la seconde carte de `#diagnostic` (« Diagnostic complet ») :
   *  même destination et **même événement** que `card`, bouton secondaire.
   *  ⚠️ La variante choisie à l'entrée du diagnostic n'est **persistée nulle
   *  part** (le candidat y est encore invité) : il n'existe aucun paramètre
   *  d'URL à passer, c'est `DiagnosticIntro` qui porte le choix. */
  variant?: "hero" | "nav" | "card" | "cardAlt" | "sticky" | "onBrand";
}) {
  const { status, user } = useAuth();
  const origin = useOrigin();
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
  // Un visiteur va **directement** sur le diagnostic : depuis le 2026-08-10 il
  // fait ses deux productions avant qu'on lui demande un compte. Le passer par
  // /inscription reviendrait à remettre le mur avant la valeur.
  const destination = withTrafficSource(completed ? "/plan" : "/diagnostic", origin);

  const label = completed
    ? // Un diagnostic terminé ne se refait pas : la carte « complet » renvoie
      // vers le Plan, qui porte justement l'invitation à compléter le profil.
      variant === "cardAlt"
      ? "Compléter mon profil"
      : "Voir mon plan"
    : variant === "nav" || variant === "sticky"
      ? "Diagnostic gratuit"
      : variant === "card"
        ? "Commencer gratuitement"
        : variant === "cardAlt"
          ? "Faire le diagnostic complet"
          : "Faire mon diagnostic gratuit";

  const className = [
    styles.btn,
    variant === "cardAlt" ? styles.btnO : styles.btnP,
    variant === "nav" || variant === "sticky" ? styles.btnSm : "",
    variant === "card" || variant === "cardAlt" || variant === "onBrand" ? styles.btnFull : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <Link
      href={destination}
      className={className}
      style={variant === "card" || variant === "cardAlt" ? { marginTop: 18 } : undefined}
      onClick={() => trackAudienceEvent(TRACKED_PATH, "SOCIAL_LANDING_DIAGNOSTIC_CLICKED")}
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
    const anchor = document.getElementById("methode");
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
      <div className={styles.stickyInner}>
        <span className={styles.stickyTxt}>
          2 exercices
          <br />≈ 8 min
        </span>
        <DiagnosticCta variant="sticky" />
      </div>
    </div>
  );
}

// ============================================================================
// HELPERS DONNÉES
// ============================================================================

function planShortName(plan: PlanPublicResponse): string {
  const family = plan.moduleAccess === "INTEGRAL" ? "Intégral" : "Examen civique";
  return `${family} · ${passDurationLabel(plan.durationDays)}`;
}

/**
 * Libellé des simulations orales d'un pass, en **puce de liste** : ici la ligne
 * doit exister même quand il n'y en a aucune, d'où le repli sur le « sans » —
 * que `passSessionsLabel` ne rend jamais de lui-même (un pass Intégral servi
 * par un backend antérieur au champ dirait une contrevérité sur l'argument
 * principal du produit). Seul le module, source sûre, l'autorise.
 */
function sessionsLabel(plan: PlanPublicResponse): string {
  return passSessionsLabel(plan) ?? "Sans simulation orale (réservée au TCF)";
}

function featuresOf(plan: PlanPublicResponse): string[] {
  if (plan.moduleAccess === "INTEGRAL") {
    return [
      "Les 4 épreuves du TCF IRN",
      "Examen civique inclus",
      "Examens blancs chronométrés",
      "Correction IA illimitée",
    ];
  }
  return ["Les 5 thèmes du livret citoyen", "Examens blancs illimités", "CSP · CR · NAT"];
}

// ============================================================================
// HOOKS
// ============================================================================

/**
 * Révèle en cascade tous les `[data-rv]` du sous-arbre au passage du scroll.
 *
 * ⚠️ Le sous-arbre n'est PAS figé : plusieurs sections en remontent une partie
 * après le montage (le sélecteur de parcours des tarifs remplace ses cartes de
 * pass, et chaque bascule crée des nœuds neufs). Comme `[data-rv]` vaut
 * `opacity: 0` tant que `data-in` n'est pas posé, un nœud ajouté après coup et
 * jamais observé reste **définitivement invisible** — c'est ainsi que les prix
 * disparaissaient dès qu'on passait sur « examen civique seul », et ne
 * revenaient pas en repassant sur « TCF IRN ». Un `MutationObserver` prend donc
 * en charge les arrivées tardives : toute brique de cette page peut être rendue
 * conditionnellement sans avoir à connaître ce mécanisme.
 */
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
      // Même sans animation, un nœud tardif doit être rendu visible.
      const mo = new MutationObserver(() => showAll(root));
      mo.observe(root, { childList: true, subtree: true });
      return () => mo.disconnect();
    }

    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry, i) => {
          if (!entry.isIntersecting) return;
          const el = entry.target as HTMLElement;
          window.setTimeout(() => reveal(el), i * 65);
          io.unobserve(el);
        });
      },
      { rootMargin: "0px 0px -10% 0px", threshold: 0.1 },
    );

    // `data-in` sert de marqueur « déjà pris en charge » : un nœud remonté à
    // l'identique n'est jamais observé deux fois, et l'observation est
    // idempotente côté navigateur de toute façon.
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

/**
 * Provenance affichée par le badge du hero. Même détection que la mesure
 * d'audience (`lib/audience.ts`) : un seul endroit qui décide « ce visiteur
 * vient de TikTok », sinon le badge et les chiffres divergeraient.
 *
 * Lu via `useSyncExternalStore` : le rendu serveur reste neutre, le badge se
 * précise au montage, sans mismatch d'hydratation.
 */
function subscribeOrigin() {
  return () => {};
}

function useOrigin(): TrafficSource | null {
  return useSyncExternalStore(subscribeOrigin, detectTrafficSource, () => null);
}

// ============================================================================
// ICÔNES DE MARQUE
// ----------------------------------------------------------------------------
// Seuls les logos de plateformes restent écrits à la main : `lucide-react` ne
// fournit pas d'icônes de marque. Toutes les icônes d'interface viennent de
// lucide, en haut de ce fichier.
// ============================================================================

function TikTokIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M16 3v3.2a5 5 0 0 0 4 4.3v3a8 8 0 0 1-4-1.4v5.2A6 6 0 1 1 10 11v3a3 3 0 1 0 3 3V3z" />
    </svg>
  );
}

function InstagramIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 2.2c3.2 0 3.6 0 4.9.07 1.2.05 1.8.25 2.2.42.6.22 1 .48 1.4.9.4.4.7.8.9 1.4.2.4.4 1 .4 2.2.1 1.3.1 1.7.1 4.9s0 3.6-.1 4.9c0 1.2-.2 1.8-.4 2.2-.2.6-.5 1-.9 1.4-.4.4-.8.7-1.4.9-.4.2-1 .4-2.2.4-1.3.1-1.7.1-4.9.1s-3.6 0-4.9-.1c-1.2 0-1.8-.2-2.2-.4-.6-.2-1-.5-1.4-.9-.4-.4-.7-.8-.9-1.4-.2-.4-.4-1-.4-2.2C2.2 15.6 2.2 15.2 2.2 12s0-3.6.1-4.9c0-1.2.2-1.8.4-2.2.2-.6.5-1 .9-1.4.4-.4.8-.7 1.4-.9.4-.2 1-.4 2.2-.4C8.4 2.2 8.8 2.2 12 2.2zm0 3.2A6.6 6.6 0 1 0 18.6 12 6.6 6.6 0 0 0 12 5.4zm0 10.9A4.3 4.3 0 1 1 16.3 12 4.3 4.3 0 0 1 12 16.3zm6.9-11.1a1.55 1.55 0 1 1-1.55-1.55A1.55 1.55 0 0 1 18.9 5.2z" />
    </svg>
  );
}

function WhatsAppIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 2a9.9 9.9 0 0 0-8.5 15L2 22l5.2-1.4A9.9 9.9 0 1 0 12 2zm5.6 14c-.24.66-1.4 1.28-1.9 1.32-.5.05-.97.23-3.3-.69-2.78-1.1-4.53-3.94-4.67-4.13-.13-.19-1.1-1.47-1.1-2.8 0-1.33.7-1.98.94-2.25a1 1 0 0 1 .72-.34h.52c.17 0 .4-.06.62.47.24.57.8 1.98.87 2.12.07.14.11.3.02.49-.1.19-.14.3-.28.47-.14.16-.3.36-.42.49-.14.14-.29.29-.12.57.16.28.73 1.2 1.57 1.95 1.08.96 1.99 1.26 2.27 1.4.28.14.44.12.6-.07.17-.19.7-.81.88-1.09.19-.28.37-.23.62-.14.25.09 1.6.76 1.87.9.28.14.46.21.53.32.07.12.07.66-.17 1.31z" />
    </svg>
  );
}

function FacebookIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M22 12a10 10 0 1 0-11.6 9.9v-7H7.9V12h2.5V9.8c0-2.5 1.5-3.9 3.8-3.9 1.1 0 2.2.2 2.2.2v2.5h-1.2c-1.2 0-1.6.75-1.6 1.5V12h2.7l-.43 2.9h-2.3v7A10 10 0 0 0 22 12z" />
    </svg>
  );
}

function YouTubeIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M22.5 7.2a2.7 2.7 0 0 0-1.9-1.9C18.9 4.8 12 4.8 12 4.8s-6.9 0-8.6.5A2.7 2.7 0 0 0 1.5 7.2 28 28 0 0 0 1 12a28 28 0 0 0 .5 4.8 2.7 2.7 0 0 0 1.9 1.9c1.7.5 8.6.5 8.6.5s6.9 0 8.6-.5a2.7 2.7 0 0 0 1.9-1.9A28 28 0 0 0 23 12a28 28 0 0 0-.5-4.8zM9.8 15.3V8.7l5.7 3.3z" />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M17.05 12.54c-.02-2.06 1.68-3.05 1.76-3.1-.96-1.4-2.45-1.6-2.98-1.62-1.27-.13-2.48.75-3.12.75-.64 0-1.64-.73-2.7-.71-1.39.02-2.67.81-3.38 2.05-1.44 2.5-.37 6.2 1.03 8.23.69.99 1.51 2.11 2.58 2.07 1.03-.04 1.42-.67 2.67-.67 1.25 0 1.6.67 2.69.65 1.11-.02 1.82-1.01 2.5-2.01.79-1.15 1.11-2.27 1.13-2.33-.02-.01-2.17-.83-2.19-3.3zM15 6.24c.57-.69.95-1.65.85-2.61-.82.03-1.81.55-2.4 1.24-.53.6-.99 1.58-.87 2.51.91.07 1.85-.46 2.42-1.14z" />
    </svg>
  );
}

function PlayIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M3.6 2.32a1.02 1.02 0 0 0-.35.79v17.78c0 .33.13.61.36.79l.1.06 9.96-9.96v-.24L3.7 2.26l-.1.06zm13.4 6.4L14.7 6.9 4.86 1.28c-.28-.16-.55-.18-.78-.06l9.96 9.97 3.96-2.47zm3.16 1.9-2.4-1.5-3.3 2.88 3.3 3.3 2.4-1.5c.7-.44.7-1.24 0-1.68zM4.08 22.78c.23.12.5.1.78-.06l9.84-5.62-3.4-3.4-9.96 9.97.74-.89z" />
    </svg>
  );
}
