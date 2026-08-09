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
  detectTrafficSource,
  trackAudienceEvent,
  trackPageView,
  withTrafficSource,
  type TrafficSource,
} from "@/lib/audience";
import { diagnosticApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { SOCIAL_ACCOUNTS, STORE_LINKS } from "@/lib/site";
import type { PlanPublicResponse } from "@/lib/types";
import styles from "./reussir.module.css";

/**
 * Landing de bio réseaux (`/reussir`) — page autoportante, un seul objectif :
 * envoyer le visiteur sur le diagnostic gratuit, puis sur son Plan et un pass.
 *
 * Le trafic vient de TikTok, Instagram, WhatsApp, Facebook ou d'un partage
 * direct : le titre reste neutre et c'est un badge qui fait le « message
 * match » en nommant la provenance détectée (utm_source, puis referrer).
 */

type Parcours = "tcf" | "civique";

/** Chemin mesuré côté backend (liste blanche `PageViewService.TRACKED_PATHS`). */
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
      <Hero />
      <AiSection />
      <LevelsSection />
      <EpreuvesSection />
      <MockExamSection />
      <MobileSection />
      <ProofSection />
      <PricingSection plans={plans} />
      <FinalSection />
      <StickyCta />
    </div>
  );
}

// ============================================================================
// ① HERO
// ============================================================================

function Hero() {
  const origin = useOrigin();

  return (
    <section className={`${styles.sec} ${styles.ink} ${styles.hero}`}>
      <span className={styles.glow} aria-hidden />
      <span className={styles.grain} aria-hidden />

      <div className={styles.wrap}>
        <div className={styles.brandbar}>
          <span className={styles.brand}>
            <span className={styles.cocarde} aria-hidden />
            Sejour<span className={styles.fr}>FR</span>
          </span>
          <span className={styles.kicker}>TCF&nbsp;IRN · Examen civique</span>
        </div>

        <div className={styles.heroGrid}>
          <div>
            <p className={styles.origin} data-rv>
              <span className={styles.originNet} aria-hidden>
                {origin ? NETWORKS[origin].icon : <SparkIcon />}
              </span>
              <span className={styles.originTxt}>
                {origin ? (
                  <>
                    Tu arrives de <b>{NETWORKS[origin].label}</b>
                  </>
                ) : (
                  <>
                    Bienvenue sur <b>SejourFR</b>
                  </>
                )}
              </span>
            </p>

            <h1 className={styles.h1} data-rv>
              Tu prépares le TCF&nbsp;? Découvre d&apos;abord <em>ce qui te bloque</em>.
            </h1>

            <p className={styles.lead} data-rv>
              Fais <strong>1 exercice écrit et 1 oral</strong>. SejourFR analyse tes
              réponses, estime ton niveau de production et te montre les compétences à
              travailler en priorité.
            </p>

            <ul className={styles.levelChips} data-rv>
              <li className={styles.levelChip}>
                <b>A2</b> Carte pluriannuelle
              </li>
              <li className={styles.levelChip}>
                <b>B1</b> Carte de résident
              </li>
              <li className={styles.levelChip} data-hi>
                <b>B2</b> Naturalisation
              </li>
            </ul>

            <div className={styles.ctaRow} data-rv>
              <DiagnosticCta />
            </div>

            <ul className={styles.trust} data-rv>
              <li>
                <CheckDot /> 2 exercices
              </li>
              <li>
                <CheckDot /> Sans carte bancaire
              </li>
              <li>
                <CheckDot /> ≈ 8 à 10 min
              </li>
            </ul>
          </div>

          <DiagnosticPreviewCard />
        </div>
      </div>
    </section>
  );
}

/**
 * Le CTA diagnostic, partagé par le hero, le bloc final et la barre collante.
 * Passer par un composant unique garantit que les trois points d'entrée sont
 * mesurés de la même façon — un bouton ajouté ailleurs sans lui serait un trou
 * silencieux dans le taux de conversion.
 */
function DiagnosticCta({ compact = false }: { compact?: boolean }) {
  const {status, user} = useAuth();
  const origin = useOrigin();
  const [completedForUserId, setCompletedForUserId] = useState<string | null>(null);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    diagnosticApi.currentCached().then((diagnostic) => {
      if (!cancelled) {
        setCompletedForUserId(diagnostic.status === "COMPLETED" ? user.id : null);
      }
    }).catch(() => undefined);
    return () => { cancelled = true; };
  }, [status, user]);

  const completed = Boolean(user && completedForUserId === user.id);
  const diagnosticDestination = withTrafficSource("/diagnostic", origin);
  const planDestination = withTrafficSource("/plan", origin);
  const destination = completed
    ? planDestination
    : status === "authenticated" && user
      ? diagnosticDestination
      : `/inscription?next=${encodeURIComponent(diagnosticDestination)}`;
  const label = completed
    ? "Voir mon plan"
    : compact
      ? "Faire mon diagnostic"
      : "Faire mon diagnostic gratuit";

  return (
    <Link
      href={destination}
      className={styles.btn}
      onClick={() => trackAudienceEvent("/reussir", "SOCIAL_LANDING_DIAGNOSTIC_CLICKED")}
    >
      {label}
      <ArrowIcon />
    </Link>
  );
}

/** Exemple clairement présenté comme tel : il visualise la valeur livrée par
 *  le diagnostic, sans se substituer au résultat réel calculé par le backend. */
function DiagnosticPreviewCard() {
  return (
    <div className={`${styles.cardInk} ${styles.diagnosticPreview}`} data-rv>
      <div className={styles.sessHead}>
        <span className={styles.live}>Votre diagnostic</span>
        <span className={styles.clock}>Exemple de résultat</span>
      </div>
      <div className={styles.diagnosticLevels}>
        <span><small>Expression écrite</small><b>B1</b></span>
        <span><small>Expression orale</small><b>B1</b></span>
        <span><small>Objectif</small><b>B2</b></span>
      </div>
      <div className={styles.diagnosticPriorities}>
        <span className={styles.who}><SparkIcon /> Vos priorités</span>
        <ol>
          <li><i>1</i><span>Développer un argument</span></li>
          <li><i>2</i><span>Structurer votre prise de parole</span></li>
          <li><i>3</i><span>Stabiliser les temps du récit</span></li>
        </ol>
      </div>
      <p className={styles.diagnosticPlan}><CheckDot /> Une action concrète dans votre Plan</p>
    </div>
  );
}

// ============================================================================
// ② L'EXAMINATEUR IA
// ============================================================================

// Critères réellement notés à l'oral. La prononciation n'en fait pas partie :
// l'évaluation part de la transcription (cf. docs/notation-ia-eo-ee.md §9), et
// l'annoncer ici promettait ce que le produit refuse explicitement de faire.
const CRITERIA: { label: string; note: string; width: number; amber?: boolean }[] = [
  { label: "Lexique", note: "17,0", width: 86 },
  { label: "Grammaire", note: "14,5", width: 72, amber: true },
  { label: "Cohérence du discours", note: "18,0", width: 90 },
  { label: "Développement des arguments", note: "15,5", width: 79 },
];

function AiSection() {
  const cardRef = useRef<HTMLDivElement | null>(null);
  const seen = useInView(cardRef);
  const score = useCountUp(seen, 16.5, 1);

  return (
    <section className={`${styles.sec} ${styles.ink}`} id="ia">
      <span className={styles.grain} aria-hidden />
      <div className={styles.wrap}>
        <div className={styles.aiGrid}>
          <div className={styles.aiCopy}>
            <span className={styles.eyebrow} data-rv>
              Ce que personne d&apos;autre ne fait
            </span>
            <h2 className={styles.h2} data-rv>
              Un examinateur <em>IA</em> qui te parle. En vrai.
            </h2>
            <p className={styles.lead} data-rv>
              Tu lances une simulation, l&apos;IA te pose ses questions à voix haute,
              écoute ta réponse, relance&nbsp;— puis te note comme le ferait un
              examinateur du TCF, critère par critère.
            </p>

            <div className={styles.limitNote} data-rv>
              <span className={styles.limitHead}>
                <InfoIcon />{" "}
                Ce qui est compté, ce qui ne l&apos;est pas
              </span>
              <p>
                <b>Simulations orales en direct&nbsp;:</b>{" "}
                au forfait — le nombre inclus
                est indiqué sur chaque pass ci-dessous. Une simulation, c&apos;est un
                entretien complet avec l&apos;examinateur.
              </p>
              <p>
                <b>Correction IA de tes écrits et de tes enregistrements&nbsp;:</b>{" "}
                illimitée pendant toute la durée de ton pass.
              </p>
              <p>
                Les pass <b>Examen civique</b>{" "}
                ne donnent pas accès aux simulations
                orales&nbsp;— l&apos;oral, c&apos;est du TCF.
              </p>
            </div>
          </div>

          <div>
            <div className={`${styles.cardInk} ${styles.eval}`} ref={cardRef} data-rv>
              <span className={`${styles.who} ${styles.whoBlue}`}>
                <SparkIcon /> Évaluation IA · Expression orale
              </span>

              <div className={styles.scoreRow}>
                <span className={styles.score}>
                  {score.toFixed(1).replace(".", ",")}
                  <small>/20</small>
                </span>
                <span className={styles.cecrl}>Niveau&nbsp;B2</span>
              </div>

              <div className={styles.crit}>
                {CRITERIA.map((c) => (
                  <div key={c.label} className={styles.critRow} data-tone={c.amber ? "amber" : undefined}>
                    <span className={styles.critTop}>
                      <span>{c.label}</span>
                      <b>{c.note}</b>
                    </span>
                    <span className={styles.bar}>
                      <i style={{ width: seen ? `${c.width}%` : 0 }} />
                    </span>
                  </div>
                ))}
              </div>

              <p className={styles.feedback}>
                <b>Ce qui marche&nbsp;:</b>{" "}
                vous argumentez sans hésiter et votre projet
                est clair, c&apos;est du niveau&nbsp;B2. <b>À travailler&nbsp;:</b>{" "}
                les
                temps du passé («&nbsp;j&apos;ai venu&nbsp;» → «&nbsp;je suis
                venu&nbsp;») et les connecteurs pour lier vos idées.
              </p>
            </div>

            <p className={styles.lead} style={{ marginTop: 24 }} data-rv>
              Tu parles, l&apos;IA te répond, te note sur&nbsp;20 et te dit{" "}
              <strong>exactement quoi corriger</strong>&nbsp;— sans rendez-vous et sans
              professeur.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ③ NIVEAUX
// ============================================================================

const LEVELS: {
  level: string;
  procedure: string;
  pitch: string;
  foot: string;
  hi?: boolean;
}[] = [
  {
    level: "A2",
    procedure: "Carte de séjour pluriannuelle",
    pitch:
      "Le premier renouvellement après le visa long séjour. Le palier le plus accessible des trois.",
    foot: "Examen civique mention CSP · validité 2 à 4 ans",
  },
  {
    level: "B1",
    procedure: "Carte de résident",
    pitch:
      "Dix ans de validité, travail facilité, démarches allégées. Le palier intermédiaire.",
    foot: "Examen civique mention CR · validité 10 ans",
  },
  {
    level: "B2",
    procedure: "Naturalisation française",
    pitch:
      "Devenir français. Le niveau de langue le plus haut : à l'oral, il faut argumenter, nuancer, réagir. C'est là que la préparation compte le plus.",
    foot: "Examen civique mention Naturalisation · nationalité + droits civiques",
    hi: true,
  },
];

function LevelsSection() {
  return (
    <section className={`${styles.sec} ${styles.paper}`}>
      <div className={styles.wrap}>
        <header className={styles.headBlock} data-rv>
          <span className={styles.eyebrow}>Trouve ton palier</span>
          <h2 className={styles.h2}>Quel niveau te faut-il, exactement&nbsp;?</h2>
          <p className={`${styles.lead} ${styles.measure}`}>
            Ce n&apos;est pas le même examen selon ce que tu demandes à la préfecture.
            L&apos;app se règle sur ton parcours dès l&apos;inscription.
          </p>
        </header>

        <div className={styles.levels}>
          {LEVELS.map((l) => (
            <article key={l.level} className={styles.level} data-hi={l.hi ? "" : undefined} data-rv>
              <span className={styles.levelBadge}>{l.level}</span>
              <h3 className={styles.levelProc}>{l.procedure}</h3>
              <p>{l.pitch}</p>
              <p className={styles.levelFoot}>{l.foot}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ④ LES ÉPREUVES
// ============================================================================

const EPREUVES: {
  href: string;
  title: string;
  pitch: string;
  tag?: string;
  icon: ReactElement;
  red?: boolean;
}[] = [
  {
    href: "/entrainement/tcf/co",
    title: "Compréhension orale",
    pitch: "Audios en voix professionnelles, écoute unique comme au vrai test.",
    icon: <HeadphonesIcon />,
  },
  {
    href: "/entrainement/tcf/ce",
    title: "Compréhension écrite",
    pitch: "Annonces, mails, articles : les supports réellement utilisés au TCF IRN.",
    icon: <BookIcon />,
  },
  {
    href: "/entrainement/tcf/ee",
    title: "Expression écrite",
    pitch: "Tu rédiges, l'IA corrige et note chaque critère.",
    tag: "Corrigé par IA · illimité",
    icon: <PenIcon />,
    red: true,
  },
  {
    href: "/entrainement/tcf/eo",
    title: "Expression orale",
    pitch: "Enregistrements notés en illimité, plus les simulations en direct au forfait.",
    tag: "Examinateur IA",
    icon: <MicIcon />,
    red: true,
  },
];

function EpreuvesSection() {
  return (
    <section className={`${styles.sec} ${styles.paper2}`}>
      <div className={styles.wrap}>
        <header className={styles.headBlock} data-rv>
          <span className={styles.eyebrow}>Ce qu&apos;il y a dans l&apos;app</span>
          <h2 className={styles.h2}>
            Les 4 épreuves du TCF. Et l&apos;<em>examen civique</em>.
          </h2>
          <p className={`${styles.lead} ${styles.measure}`}>
            Le même découpage que le jour de l&apos;examen, rien de plus, rien de moins.
          </p>
        </header>

        <div className={styles.eprs}>
          {EPREUVES.map((e) => (
            <Link
              key={e.title}
              href={e.href}
              className={styles.epr}
              data-accent={e.red ? "red" : undefined}
              data-rv
            >
              <span className={styles.eprIco}>{e.icon}</span>
              <h3>{e.title}</h3>
              <p>{e.pitch}</p>
              {e.tag && <span className={styles.eprTag}>{e.tag}</span>}
            </Link>
          ))}
        </div>

        <Link href="/entrainement?module=CIVIQUE" className={styles.eprWide} data-rv>
          <span className={`${styles.cocarde} ${styles.cocardeLg}`} aria-hidden />
          <span className={styles.eprWideTxt}>
            <h3>Examen civique</h3>
            <p>
              CSP, carte de résident, naturalisation&nbsp;— 5 thèmes du livret citoyen,
              mises en situation incluses, adaptés à ton parcours.
            </p>
          </span>
          <span className={styles.eprWideGo} aria-hidden>
            →
          </span>
        </Link>
      </div>
    </section>
  );
}

// ============================================================================
// ⑤ EXAMEN BLANC COMPLET
// ============================================================================

function MockExamSection() {
  const cardRef = useRef<HTMLDivElement | null>(null);
  const seen = useInView(cardRef);
  const calibrated = useCountUp(seen, 448, 0);

  return (
    <section className={`${styles.sec} ${styles.paper}`}>
      <div className={styles.wrap}>
        <div className={styles.examGrid}>
          <div className={styles.mock} ref={cardRef} data-rv>
            <div className={styles.mockHead}>
              <span>Examen blanc complet</span>
              <span className={styles.mockTimer}>89:47</span>
            </div>

            <div className={styles.steps}>
              {["CO", "CE", "EE", "EO"].map((s) => (
                <span key={s} className={styles.step}>
                  <b>{s}</b>
                  <i>✓</i>
                </span>
              ))}
            </div>

            <div className={styles.result}>
              <div>
                <span className={styles.resultLbl}>Score calibré</span>
                <span className={styles.resultBig}>
                  {Math.round(calibrated)}
                  <small>&nbsp;/&nbsp;499</small>
                </span>
              </div>
              <div style={{ textAlign: "right" }}>
                <span className={styles.resultLbl}>Niveau obtenu</span>
                <span className={styles.resultLvl}>B2</span>
              </div>
            </div>

            <div className={styles.perEpr}>
              <span>
                CO&nbsp;<b>B2</b>
              </span>
              <span>
                CE&nbsp;<b>B2</b>
              </span>
              <span data-floor>
                EE&nbsp;<b>B2</b>
              </span>
              <span>
                EO&nbsp;<b>B2</b>
              </span>
            </div>
          </div>

          <div>
            <header className={styles.headBlock} style={{ marginBottom: 0 }} data-rv>
              <span className={styles.eyebrow}>Conditions réelles</span>
              <h2 className={styles.h2}>
                90&nbsp;minutes. 4&nbsp;épreuves. Un <em>niveau</em>.
              </h2>
              <p className={styles.lead}>
                Compréhension orale, compréhension écrite, expression écrite, expression
                orale&nbsp;— enchaînées et chronométrées comme au centre d&apos;examen.
              </p>
            </header>

            <p className={styles.rule} data-rv>
              Ton niveau final, c&apos;est <b>le plus faible de tes quatre épreuves</b>
              &nbsp;: la règle du TCF&nbsp;IRN. Viser B2 pour la naturalisation, c&apos;est
              donc l&apos;avoir <b>partout</b>, y compris à l&apos;oral. L&apos;app te
              montre exactement où ça bloque, avant le jour&nbsp;J.
            </p>

            <Link href="/examens-blancs" className={styles.linkArrow} data-rv>
              Voir les examens blancs
              <ArrowIcon />
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

// ============================================================================
// ⑥ APP MOBILE
// ============================================================================

const MOBILE_POINTS: { title: string; text: string }[] = [
  {
    title: "Le même compte, la même progression",
    text: "Tu passes un examen blanc sur ordinateur, tu revois tes erreurs dans le métro. Rien à resynchroniser.",
  },
  {
    title: "Tout est là, y compris l'examinateur IA",
    text: "Les 4 épreuves du TCF, l'examen civique, les examens blancs chronométrés et les simulations orales.",
  },
  {
    title: "Des séries courtes, tous les jours",
    text: "20 questions, correction expliquée juste après. C'est le format qui fait progresser sans y passer la soirée.",
  },
];

function MobileSection() {
  return (
    <section className={`${styles.sec} ${styles.ink}`}>
      <span className={styles.grain} aria-hidden />
      <div className={styles.wrap}>
        <div className={styles.mobileGrid}>
          <div>
            <span className={styles.eyebrow} data-rv>
              iOS et Android
            </span>
            <h2 className={styles.h2} data-rv style={{ margin: "15px 0 15px" }}>
              Ta préparation tient aussi dans ta <em>poche</em>.
            </h2>
            <p className={styles.lead} data-rv>
              L&apos;app SejourFR est disponible sur l&apos;App Store et Google Play. C&apos;est
              la même préparation que sur le site, avec le même compte&nbsp;— pensée pour
              t&apos;entraîner un peu chaque jour.
            </p>

            <ul className={styles.mobilePoints} data-rv>
              {MOBILE_POINTS.map((pt) => (
                <li key={pt.title}>
                  <CheckDot />
                  <span>
                    <b>{pt.title}</b>
                    <small>{pt.text}</small>
                  </span>
                </li>
              ))}
            </ul>

            <div className={styles.stores} data-rv>
              <a
                className={styles.store}
                href={STORE_LINKS.ios}
                target="_blank"
                rel="noopener noreferrer"
              >
                <AppleIcon />
                <span>
                  <small>Télécharger sur</small>
                  <b>App Store</b>
                </span>
              </a>
              <a
                className={styles.store}
                href={STORE_LINKS.android}
                target="_blank"
                rel="noopener noreferrer"
              >
                <PlayIcon />
                <span>
                  <small>Disponible sur</small>
                  <b>Google Play</b>
                </span>
              </a>
            </div>
          </div>

          <PhoneMockup />
        </div>
      </div>
    </section>
  );
}

/** Aperçu de l'app : cadre de téléphone en CSS, pas de capture d'écran à maintenir. */
function PhoneMockup() {
  return (
    <div className={styles.phoneWrap} data-rv aria-hidden>
      <div className={styles.phone}>
        <span className={styles.phoneNotch} />
        <div className={styles.phoneScreen}>
          <span className={styles.phoneEyebrow}>Aujourd&apos;hui</span>
          <p className={styles.phoneHello}>Bonjour Fatou</p>

          <div className={styles.phoneStreak}>
            <b>12</b>
            <span>jours de suite</span>
          </div>

          <span className={styles.phoneLabel}>Ta série du jour</span>
          <div className={styles.phoneCard}>
            <span className={styles.phoneCardIco}>
              <HeadphonesIcon />
            </span>
            <span>
              <b>Compréhension orale</b>
              <small>20 questions · niveau B2</small>
            </span>
          </div>

          <div className={styles.phoneCard} data-accent="red">
            <span className={styles.phoneCardIco}>
              <MicIcon />
            </span>
            <span>
              <b>Simulation orale</b>
              <small>Examinateur IA · 12 min</small>
            </span>
          </div>

          <div className={styles.phoneBars}>
            <span>
              <i style={{ width: "78%" }} />
            </span>
            <span>
              <i style={{ width: "54%" }} />
            </span>
            <span>
              <i style={{ width: "91%" }} />
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

// ============================================================================
// ⑦ PREUVE
// ============================================================================

function ProofSection() {
  return (
    <section className={`${styles.sec} ${styles.paper2}`}>
      <div className={styles.wrap}>
        <header className={styles.headBlock} data-rv>
          <span className={styles.eyebrow}>Pourquoi tu peux y aller</span>
          <h2 className={styles.h2}>
            Fait pour l&apos;examen, pas pour «&nbsp;apprendre le français&nbsp;».
          </h2>
        </header>

        <div className={styles.facts} data-rv>
          <div className={styles.fact}>
            <b>4</b>
            <span>Épreuves TCF couvertes</span>
          </div>
          <div className={styles.fact}>
            <b>5</b>
            <span>Thèmes de l&apos;examen civique</span>
          </div>
          <div className={styles.fact}>
            <b>2026</b>
            <span>Programme à jour</span>
          </div>
        </div>

        <p className={styles.proofFoot} data-rv>
          Besoin d&apos;y voir plus clair sur ta démarche&nbsp;?{" "}
          <Link href="/blog">30 articles gratuits sur le TCF et la naturalisation</Link>.
        </p>
      </div>
    </section>
  );
}

// ============================================================================
// ⑧ TARIFS
// ============================================================================

function PricingSection({ plans }: { plans: PlanPublicResponse[] }) {
  const [parcours, setParcours] = useState<Parcours>("tcf");
  const { status, user } = useAuth();
  const isAuth = status === "authenticated" && user !== null;

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

  const popular = popularCodeOf(visible);

  return (
    <section className={`${styles.sec} ${styles.paper}`} id="tarifs">
      <div className={styles.wrap}>
        <header className={styles.headBlock} data-rv>
          <span className={styles.eyebrow}>Le prix</span>
          <h2 className={styles.h2}>
            Pas d&apos;abonnement. Tu paies <em>une fois</em>.
          </h2>
          <p className={`${styles.lead} ${styles.measure}`}>
            Aucune reconduction automatique, rien à résilier. Si tu rachètes, les durées
            s&apos;additionnent.
          </p>
        </header>

        <div className={styles.switch} role="group" aria-label="Choisir son parcours" data-rv>
          <button
            type="button"
            data-parcours="tcf"
            aria-pressed={parcours === "tcf"}
            onClick={() => setParcours("tcf")}
          >
            Je prépare le TCF IRN
          </button>
          <button
            type="button"
            data-parcours="civique"
            aria-pressed={parcours === "civique"}
            onClick={() => setParcours("civique")}
          >
            Je prépare l&apos;examen civique seul
          </button>
        </div>

        <div className={styles.plans} data-accent={parcours} data-count={visible.length}>
          {visible.map((plan) => (
            <PlanCard
              key={plan.code}
              plan={plan}
              popular={plan.code === popular}
              isAuth={isAuth}
            />
          ))}
        </div>

        <p className={styles.plansNote} data-rv>
          {parcours === "tcf" ? (
            <>
              Les pass Intégral contiennent aussi tout l&apos;examen civique&nbsp;— il
              n&apos;y a rien à ajouter.
            </>
          ) : (
            <>
              Tu passes aussi le TCF&nbsp;IRN&nbsp;?{" "}
              <button type="button" onClick={() => setParcours("tcf")}>
                Voir les pass Intégral
              </button>
              , qui contiennent déjà tout l&apos;examen civique.
            </>
          )}
        </p>

        <ul className={styles.noabo} data-rv>
          <li>Sans reconduction</li>
          <li>Durées cumulables</li>
          <li>Web &amp; mobile</li>
          <li>Paiement Stripe</li>
        </ul>

        <Link href="/tarifs" className={styles.linkArrow} data-rv>
          Comparer toutes les formules
          <ArrowIcon />
        </Link>
      </div>
    </section>
  );
}

function PlanCard({
  plan,
  popular,
  isAuth,
}: {
  plan: PlanPublicResponse;
  popular: boolean;
  isAuth: boolean;
}) {
  const target = plan.moduleAccess === "INTEGRAL" ? "INTEGRAL" : "CIVIQUE";
  const hasOral = target === "INTEGRAL";
  const checkout = `/paiement?module=${target}&plan=${encodeURIComponent(plan.code)}`;
  // Non connecté : on passe par l'inscription en gardant la destination — le
  // nouvel inscrit retombe sur le pass qu'il vient de choisir, pas au dashboard.
  const href = isAuth ? checkout : `/inscription?next=${encodeURIComponent(checkout)}`;

  return (
    <article className={`${styles.plan} ${popular ? styles.planHi : ""}`} data-rv>
      {popular && <span className={styles.planTag}>Le plus choisi</span>}
      <span className={styles.planName}>{planShortName(plan)}</span>
      <span className={styles.planPrice}>
        <b>{formatPrice(plan.price)}&nbsp;€</b>
        <span>payés une fois</span>
      </span>
      <span className={styles.planDur}>
        {durationLabel(plan.durationDays)} d&apos;accès{monthlyLabel(plan)}
      </span>

      <span className={styles.planSessions} data-none={hasOral ? undefined : ""}>
        {sessionsLabel(plan)}
      </span>

      <ul className={styles.planFeatures}>
        {featuresOf(plan).map((f) => (
          <li key={f}>
            <CheckIcon />
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
// ⑨ FINAL + LIENS
// ============================================================================

function FinalSection() {
  const socials = SOCIAL_ACCOUNTS.filter((s) => s.url !== null);

  return (
    <section className={`${styles.sec} ${styles.ink} ${styles.final}`}>
      <span className={styles.glow} aria-hidden />
      <span className={styles.grain} aria-hidden />
      <div className={styles.wrap}>
        <div className={styles.finalGrid}>
          <div>
            <h2 className={styles.h2} data-rv>
              Commence par ton <em>diagnostic gratuit</em>. Maintenant.
            </h2>
            <div className={styles.ctaRow} data-rv>
              <DiagnosticCta />
            </div>
            <div className={styles.stores} data-rv>
              <a
                className={styles.store}
                href={STORE_LINKS.ios}
                target="_blank"
                rel="noopener noreferrer"
              >
                <AppleIcon />
                <span>
                  <small>Télécharger sur</small>
                  <b>App Store</b>
                </span>
              </a>
              <a
                className={styles.store}
                href={STORE_LINKS.android}
                target="_blank"
                rel="noopener noreferrer"
              >
                <PlayIcon />
                <span>
                  <small>Disponible sur</small>
                  <b>Google Play</b>
                </span>
              </a>
            </div>
          </div>

          <div>
            <p className={styles.sep} data-rv>
              Aussi
            </p>
            <div className={styles.biolinks} data-rv>
              <Link href="/blog" className={styles.biolink}>
                <span className={styles.biolinkIco}>
                  <ArticleIcon />
                </span>
                <span>
                  <b>Conseils TCF &amp; examen civique</b>
                  <small>Le blog — 30 articles gratuits</small>
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
                  <HelpIcon />
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
                  <MailIcon />
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

            <ul className={styles.legal} data-rv>
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
        </div>
      </div>
    </section>
  );
}

/** Barre d'action persistante mobile, révélée une fois le hero dépassé. */
function StickyCta() {
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const anchor = document.getElementById("ia");
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
          <br />
          ≈ 8 à 10 min
        </span>
        <DiagnosticCta compact />
      </div>
    </div>
  );
}

// ============================================================================
// HELPERS DONNÉES
// ============================================================================

function formatPrice(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(2).replace(".", ",");
}

function durationLabel(days: number): string {
  if (days <= 0) return "";
  if (days % 365 === 0) {
    const y = days / 365;
    return y === 1 ? "12 mois" : `${y} ans`;
  }
  if (days >= 30 && days % 30 === 0) return `${days / 30} mois`;
  if (days % 7 === 0) return `${days / 7} semaines`;
  return `${days} jours`;
}

/** Nom court affichable : « Intégral · 3 mois » plutôt que le libellé DB complet. */
function planShortName(plan: PlanPublicResponse): string {
  const family = plan.moduleAccess === "INTEGRAL" ? "Intégral" : "Examen civique";
  return `${family} · ${durationLabel(plan.durationDays)}`;
}

/**
 * Pass mis en avant : celui de 3 mois s'il existe (le plus vendu, cohérent avec
 * `POPULAR_PASS_CODE` de /paiement), sinon celui du milieu de la grille.
 */
function popularCodeOf(list: PlanPublicResponse[]): string | null {
  if (list.length === 0) return null;
  const quarter = list.find((p) => p.durationDays === 90);
  if (quarter) return quarter.code;
  return list[Math.floor((list.length - 1) / 2)].code;
}

/**
 * Équivalent mensuel affiché en sous-texte (« soit 13,33 €/mois »). Le montant
 * réellement débité reste le prix principal — un pass se paie une fois, mettre
 * un « /mois » en avant laisserait croire à un abonnement. Null sous un mois
 * d'accès, où le prix affiché est déjà mensuel. Parité : /paiement, /tarifs et
 * le paywall mobile suivent la même hiérarchie.
 */
function monthlyLabel(plan: PlanPublicResponse): string {
  const days = plan.durationDays;
  const months =
    days <= 0
      ? 0
      : days % 365 === 0
        ? (days / 365) * 12
        : days % 30 === 0
          ? days / 30
          : days % 7 === 0
            ? days / 7 / 4
            : days / 30;
  if (months <= 1) return "";
  return ` · soit ${formatPrice(Number((plan.price / months).toFixed(2)))} €/mois`;
}

/**
 * Libellé des simulations orales d'un pass.
 *
 * On ne dit JAMAIS « sans simulation orale » pour un pass Intégral : si le
 * backend déployé est antérieur à l'ajout de `realtimeEoSessions`, le champ
 * arrive absent (donc falsy) et l'affirmation serait fausse sur l'argument
 * principal du produit. Dans ce cas on retombe sur un libellé vrai mais sans
 * chiffre. Seul le module (source sûre) autorise le « sans ».
 */
function sessionsLabel(plan: PlanPublicResponse): string {
  const sessions = plan.realtimeEoSessions;
  if (typeof sessions === "number" && sessions > 0) {
    return `${sessions} simulations orales en direct`;
  }
  if (plan.moduleAccess === "INTEGRAL") return "Simulations orales en direct incluses";
  return "Sans simulation orale (réservée au TCF)";
}

function featuresOf(plan: PlanPublicResponse): string[] {
  if (plan.moduleAccess === "INTEGRAL") {
    return [
      "Les 4 épreuves du TCF IRN",
      "Examen civique inclus",
      "Examens blancs complets chronométrés",
      "Correction IA illimitée à l'écrit et à l'oral",
    ];
  }
  return [
    "Les 5 thèmes du livret citoyen",
    "Examens blancs illimités",
    "Adapté à CSP, carte de résident ou naturalisation",
  ];
}

// ============================================================================
// HOOKS
// ============================================================================

const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)";

function subscribeReducedMotion(onChange: () => void) {
  const mq = window.matchMedia(REDUCED_MOTION_QUERY);
  mq.addEventListener("change", onChange);
  return () => mq.removeEventListener("change", onChange);
}

function usePrefersReducedMotion(): boolean {
  return useSyncExternalStore(
    subscribeReducedMotion,
    () => window.matchMedia(REDUCED_MOTION_QUERY).matches,
    () => false,
  );
}

/** Révèle en cascade tous les `[data-rv]` du sous-arbre au passage du scroll. */
function useReveal(rootRef: React.RefObject<HTMLElement | null>) {
  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;
    const targets = Array.from(root.querySelectorAll<HTMLElement>("[data-rv]"));
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      targets.forEach((el) => el.setAttribute("data-in", ""));
      return;
    }
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry, i) => {
          if (!entry.isIntersecting) return;
          const el = entry.target as HTMLElement;
          window.setTimeout(() => el.setAttribute("data-in", ""), i * 65);
          io.unobserve(el);
        });
      },
      { rootMargin: "0px 0px -10% 0px", threshold: 0.1 },
    );
    targets.forEach((el) => io.observe(el));
    return () => io.disconnect();
  }, [rootRef]);
}

/** true dès que l'élément a été vu une fois (les démos ne se rejouent pas). */
function useInView(ref: React.RefObject<Element | null>): boolean {
  const [seen, setSeen] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el || seen) return;
    const io = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) return;
        setSeen(true);
        io.disconnect();
      },
      { threshold: 0.3 },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [ref, seen]);
  return seen;
}

function useCountUp(start: boolean, target: number, decimals: number): number {
  const [value, setValue] = useState(0);
  const reduced = usePrefersReducedMotion();

  useEffect(() => {
    if (!start || reduced) return;
    let raf = 0;
    let t0 = 0;
    const step = (ts: number) => {
      if (!t0) t0 = ts;
      const p = Math.min((ts - t0) / 1400, 1);
      const eased = 1 - Math.pow(1 - p, 3);
      setValue(Number((target * eased).toFixed(decimals)));
      if (p < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [start, target, decimals, reduced]);

  return reduced ? target : value;
}

/**
 * Provenance affichée par le badge du hero. Même détection que la mesure
 * d'audience (`lib/audience.ts`) : un seul endroit qui décide « ce visiteur
 * vient de TikTok », sinon le badge et les chiffres divergeraient.
 *
 * Lu via `useSyncExternalStore` : le rendu serveur reste neutre
 * (« Bienvenue »), le badge se précise au montage, sans mismatch d'hydratation.
 */
function subscribeOrigin() {
  return () => {};
}

function useOrigin(): TrafficSource | null {
  return useSyncExternalStore(subscribeOrigin, detectTrafficSource, () => null);
}

// ============================================================================
// ICÔNES
// ============================================================================

function ArrowIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M4 12l6 6L20 6" />
    </svg>
  );
}

function CheckDot() {
  return (
    <span className={styles.tick} aria-hidden>
      <svg viewBox="0 0 24 24" fill="none" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round">
        <path d="M4 12l6 6L20 6" />
      </svg>
    </span>
  );
}

function MicIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M12 2a3 3 0 0 1 3 3v6a3 3 0 0 1-6 0V5a3 3 0 0 1 3-3z" />
      <path d="M19 10v1a7 7 0 0 1-14 0v-1M12 18v4" />
    </svg>
  );
}

function HeadphonesIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M3 14v-3a9 9 0 0 1 18 0v3" />
      <path d="M21 16a2 2 0 0 1-2 2h-1v-6h1a2 2 0 0 1 2 2v2zM3 16a2 2 0 0 0 2 2h1v-6H5a2 2 0 0 0-2 2v2z" />
    </svg>
  );
}

function BookIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M4 5h7a2 2 0 0 1 2 2v12a2 2 0 0 0-2-2H4z" />
      <path d="M20 5h-7a2 2 0 0 0-2 2v12a2 2 0 0 1 2-2h7z" />
    </svg>
  );
}

function PenIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M12 20h9" />
      <path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z" />
    </svg>
  );
}

function SparkIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9L12 3z" />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 8v5M12 16.5v.01" />
    </svg>
  );
}

function ArticleIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M4 5h16v14H4zM8 9h8M8 13h8M8 17h5" />
    </svg>
  );
}

function HelpIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <circle cx="12" cy="12" r="9" />
      <path d="M9.5 9a2.5 2.5 0 1 1 3.3 2.4c-.5.2-.8.7-.8 1.2v.4M12 16.5v.01" />
    </svg>
  );
}

function MailIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <path d="M4 5h16v14H4z" />
      <path d="M4 6l8 6 8-6" />
    </svg>
  );
}

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
