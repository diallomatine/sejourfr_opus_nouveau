import Link from "next/link";
import {
  ArrowRight,
  BarChart3,
  BookOpen,
  Brain,
  Building2,
  Check,
  CheckCircle2,
  ClipboardCheck,
  Clock,
  FileText,
  GraduationCap,
  Headphones,
  Info,
  Mic,
  PenLine,
  Quote,
  Smartphone,
  Sparkles,
  Star,
} from "lucide-react";
import { PricingPlans } from "@/components/pricing/PricingPlans";
import type { PlanPublicResponse } from "@/lib/types";
import { StoreBadge } from "../MobileAppPromo";
import styles from "./landing.module.css";

/* ---------------------------------------------------------------------------
   Primitive : en-tête de section
   ------------------------------------------------------------------------- */
function SectionHead({
  label,
  title,
  description,
  dark,
}: {
  label: string;
  title: React.ReactNode;
  description?: string;
  dark?: boolean;
}) {
  return (
    <div className={styles.head}>
      <span className={styles.headLabel}>{label}</span>
      <h2
        className={styles.headTitle}
        style={dark ? { color: "#fff" } : undefined}
      >
        {title}
      </h2>
      {description && (
        <p
          className={styles.headDesc}
          style={dark ? { color: "rgba(255,255,255,0.75)" } : undefined}
        >
          {description}
        </p>
      )}
    </div>
  );
}

/* ---------------------------------------------------------------------------
   Hero — copy à gauche, aperçu « examen blanc » + carte IA à droite.
   ------------------------------------------------------------------------- */
const HERO_PILLARS = [
  { Icon: Clock, label: "Examens blancs chronométrés — format & seuil officiels" },
  { Icon: Sparkles, label: "Correction IA de l'oral & de l'écrit (EO · EE)" },
  { Icon: BarChart3, label: "Estimation de niveau · A2 · B1 · B2" },
];

const HERO_TRUST = [
  "100 % gratuit pour démarrer",
  "Sans abonnement",
  "Web & mobile",
];

export function Hero() {
  return (
    <section className={styles.hero}>
      <div className={styles.heroBg} aria-hidden />
      <div className={`container-x ${styles.heroGrid}`}>
        <div className={styles.heroCopy}>
          <span className={styles.heroPill}>
            <span aria-hidden>🇫🇷</span> Obligatoire depuis janvier 2026
          </span>

          <h1 className={styles.heroTitle}>
            Réussissez votre <em>TCF IRN</em> et votre examen civique
          </h1>

          <p className={styles.heroDefine}>
            <strong>TCF IRN</strong> — le test de français pour l&apos;Intégration,
            la Résidence et la Nationalité.
          </p>

          <p className={styles.heroSub}>
            Entraînez-vous dans les conditions du <strong>jour J</strong>. Examens
            blancs chronométrés, correction IA de vos expressions et estimation de
            votre niveau — à l&apos;écrit comme à l&apos;oral.
          </p>

          <ul className={styles.heroPillars}>
            {HERO_PILLARS.map(({ Icon, label }) => (
              <li key={label} className={styles.heroPillar}>
                <span className={styles.heroPillarIco} aria-hidden>
                  <Icon size={19} strokeWidth={2} />
                </span>
                {label}
              </li>
            ))}
          </ul>

          <div className={styles.heroCtas}>
            <Link href="/entrainement?module=TCF" className="btn btn-lg">
              Commencer gratuitement
              <ArrowRight size={18} className="arrow" aria-hidden />
            </Link>
            <Link href="/examens-blancs" className="btn btn-ghost btn-lg">
              Passer un examen blanc
            </Link>
          </div>

          <ul className={styles.heroTrust}>
            {HERO_TRUST.map((t) => (
              <li key={t} className={styles.heroTrustItem}>
                <Check size={16} className={styles.badgeCheck} aria-hidden />
                {t}
              </li>
            ))}
          </ul>

          <div className={styles.heroStores}>
            <span className={styles.heroStoresLabel}>↳ Aussi sur l&apos;app</span>
            <div className={styles.heroStoresBadges}>
              <StoreBadge variant="ios" />
              <StoreBadge variant="android" />
            </div>
          </div>
        </div>

        <div className={styles.heroVisual}>
          <HeroExamPreview />
        </div>
      </div>
    </section>
  );
}

/* Aperçu « examen blanc en cours » + carte de correction IA flottante. */
function HeroExamPreview() {
  const choices = [
    { label: "Liberté, Fraternité, Solidarité", ok: false },
    { label: "Liberté, Égalité, Fraternité", ok: true },
    { label: "Unité, Travail, Patrie", ok: false },
    { label: "Liberté, Justice, Paix", ok: false },
  ];
  return (
    <div className={styles.heroPreview} aria-hidden>
      <div className={styles.exam}>
        <div className={styles.examHead}>
          <span className={styles.examTag}>↳ Examen blanc · Civique</span>
          <span className={styles.examTimer}>
            <span className={styles.examTimerDot} />
            42:18
          </span>
        </div>
        <div className={styles.examBar}>
          <span className={styles.examBarFill} />
        </div>
        <span className={styles.examQcount}>Question 12 / 40</span>
        <p className={styles.examQ}>
          Quelle est la devise de la République française ?
        </p>
        <div className={styles.examChoices}>
          {choices.map((c) => (
            <div
              key={c.label}
              className={`${styles.examChoice} ${c.ok ? styles.examChoiceOk : ""}`}
            >
              <span className={styles.examRing}>
                {c.ok && <Check size={12} strokeWidth={3} />}
              </span>
              {c.label}
            </div>
          ))}
        </div>
        <div className={styles.examExplain}>
          <CheckCircle2 size={17} className={styles.examExplainIco} aria-hidden />
          <p>
            <strong>Bonne réponse.</strong> La devise figure à l&apos;article 2 de
            la Constitution.
          </p>
        </div>
      </div>

      <div className={styles.examAi}>
        <span className={styles.examAiTag}>
          <Sparkles size={13} aria-hidden />
          Correction IA
        </span>
        <span className={styles.examAiLab}>Niveau estimé</span>
        <div className={styles.examAiLevels}>
          {["A2", "B1", "B2"].map((lv) => (
            <span
              key={lv}
              className={`${styles.examAiLevel} ${lv === "B1" ? styles.examAiLevelOn : ""}`}
            >
              {lv}
            </span>
          ))}
        </div>
        <div className={styles.examAiScore}>
          <span>Expression écrite</span>
          <strong>15 / 20</strong>
        </div>
      </div>
    </div>
  );
}

/* ---------------------------------------------------------------------------
   Parcours — « Par où commencer ? » : 3 cartes-CTA vers les parcours réels.
   ------------------------------------------------------------------------- */
type PathCard = {
  Icon: typeof GraduationCap;
  tag: string;
  title: string;
  desc: string;
  points: string[];
  cta: string;
  href: string;
  red?: boolean;
};

const PATHS: PathCard[] = [
  {
    Icon: GraduationCap,
    tag: "Gratuit",
    title: "S'entraîner au TCF IRN",
    desc: "Compréhension et expression, à l'écrit comme à l'oral, au format officiel.",
    points: ["Compréhension orale & écrite", "Coach IA pour l'oral & l'écrit"],
    cta: "Commencer le TCF",
    href: "/entrainement?module=TCF",
  },
  {
    Icon: Building2,
    tag: "Gratuit",
    title: "S'entraîner au civique",
    desc: "Valeurs de la République, institutions, droits et devoirs, histoire et vie en France.",
    points: ["5 thèmes officiels", "Séries corrigées immédiatement"],
    cta: "Commencer le civique",
    href: "/entrainement?module=CIVIQUE",
  },
  {
    Icon: ClipboardCheck,
    tag: "Conditions réelles",
    title: "Tester votre niveau",
    desc: "Passez un examen blanc chronométré et obtenez votre niveau estimé.",
    points: ["Chronomètre & format officiel", "Niveau estimé A2 · B1 · B2"],
    cta: "Passer un examen blanc",
    href: "/examens-blancs",
    red: true,
  },
];

export function Parcours() {
  return (
    <section id="parcours" className={styles.paths}>
      <div className="container-x">
        <p className={styles.pathsEyebrow}>↳ Par où commencer ?</p>
        <h2 className={styles.pathsTitle}>
          Choisissez votre <em>parcours</em>
        </h2>

        <div className={styles.pathsGrid}>
          {PATHS.map(({ Icon, tag, title, desc, points, cta, href, red }) => (
            <article
              key={title}
              className={`${styles.pcard} ${red ? styles.pcardAccent : ""}`}
            >
              <div className={styles.pcTop}>
                <span className={styles.pcIco} aria-hidden>
                  <Icon size={22} strokeWidth={1.8} />
                </span>
                <span className={`${styles.pcTag} ${red ? styles.pcTagReal : styles.pcTagFree}`}>
                  {tag}
                </span>
              </div>
              <h3 className={styles.pcTitle}>{title}</h3>
              <p className={styles.pcDesc}>{desc}</p>
              <ul className={styles.pcList}>
                {points.map((p) => (
                  <li key={p}>
                    <Check size={15} strokeWidth={2.6} aria-hidden />
                    {p}
                  </li>
                ))}
              </ul>
              <Link
                href={href}
                className={`btn ${red ? "btn-red" : ""} ${styles.pcCta}`}
              >
                {cta}
                <ArrowRight size={17} className="arrow" aria-hidden />
              </Link>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------------------
   Examens (2 cartes)
   ------------------------------------------------------------------------- */
const EXAMENS = [
  {
    Icon: GraduationCap,
    title: "TCF IRN",
    badge: "4 compétences",
    desc: "Test de Connaissance du Français pour l'Intégration, la Résidence et la Nationalité. Entraînez-vous sur les 4 compétences, dans un format identique à l'examen officiel.",
    features: [
      "Compréhension orale",
      "Compréhension écrite",
      "Expression orale (analysée par IA)",
      "Expression écrite (analysée par IA)",
    ],
  },
  {
    Icon: Building2,
    title: "Examen civique",
    badge: "5 thèmes officiels",
    desc: "Préparez l'épreuve sur les valeurs de la République, les institutions, vos droits et devoirs, l'histoire-géographie et la vie quotidienne en France.",
    features: [
      "Principes et valeurs de la République",
      "Système institutionnel et politique",
      "Droits et devoirs du citoyen",
      "Histoire, géographie et culture",
      "Vivre dans la société française",
    ],
  },
];

export function Examens() {
  return (
    <section id="examens" className={styles.section}>
      <div className="container-x">
        <SectionHead
          label="Ce que nous proposons"
          title="Préparez-vous aux examens officiels"
          description="Deux examens obligatoires pour votre titre de séjour, un seul espace d'entraînement complet."
        />
        <div className={`${styles.grid} ${styles.examGrid}`}>
          {EXAMENS.map(({ Icon, title, badge, desc, features }) => (
            <article key={title} className={styles.examCard}>
              <span className={styles.examBadge}>{badge}</span>
              <Icon size={44} strokeWidth={1.5} className={styles.examIcon} aria-hidden />
              <h3 className={styles.examTitle}>{title}</h3>
              <p className={styles.examDesc}>{desc}</p>
              <ul className={styles.featList}>
                {features.map((f) => (
                  <li key={f} className={styles.featItem}>
                    <Check size={18} className={styles.badgeCheck} aria-hidden />
                    {f}
                  </li>
                ))}
              </ul>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------------------
   Compétences (4 cartes)
   ------------------------------------------------------------------------- */
const COMPETENCES = [
  {
    Icon: Headphones,
    title: "Compréhension orale",
    desc: "Dialogues, interviews et annonces. Répondez dans le temps imparti, comme à l'examen réel.",
    ai: false,
  },
  {
    Icon: BookOpen,
    title: "Compréhension écrite",
    desc: "Articles, e-mails et documents variés. Comprenez le sens global et les détails.",
    ai: false,
  },
  {
    Icon: Mic,
    title: "Expression orale",
    desc: "Répondez à des questions enregistrées. L'IA analyse prononciation, fluidité et lexique.",
    ai: true,
  },
  {
    Icon: PenLine,
    title: "Expression écrite",
    desc: "Rédigez vos réponses. L'IA évalue grammaire, orthographe et cohérence du texte.",
    ai: true,
  },
];

export function Competences() {
  return (
    <section id="competences" className={`${styles.section} ${styles.sectionPaper}`}>
      <div className="container-x">
        <SectionHead
          label="Compétences testées"
          title="Maîtrisez toutes les épreuves"
          description="L'ensemble des compétences évaluées au TCF IRN, avec une analyse IA pour les productions orales et écrites."
        />
        <div className={`${styles.grid} ${styles.compGrid}`}>
          {COMPETENCES.map(({ Icon, title, desc, ai }) => (
            <article key={title} className={styles.compCard}>
              <span className={styles.compIcon} aria-hidden>
                <Icon size={24} strokeWidth={1.5} />
              </span>
              <h3 className={styles.compTitle}>{title}</h3>
              <p className={styles.compDesc}>{desc}</p>
              <span
                className={`${styles.compTag} ${ai ? styles.compTagAi : styles.compTagQcm}`}
              >
                {ai ? "Analysé par IA" : "QCM"}
              </span>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------------------
   Simulation (2 colonnes : texte + mock interface)
   ------------------------------------------------------------------------- */
const SIM_FEATURES = [
  {
    Icon: Clock,
    title: "Chronomètre intégré",
    desc: "Respectez les temps impartis pour chaque épreuve, comme le jour J.",
  },
  {
    Icon: FileText,
    title: "Format identique à l'examen",
    desc: "Même structure, mêmes types de questions, même déroulement.",
  },
  {
    Icon: Brain,
    title: "Analyse IA complète",
    desc: "Pour l'expression orale et écrite, une évaluation détaillée de vos réponses.",
  },
  {
    Icon: BarChart3,
    title: "Suivi de vos progrès",
    desc: "Visualisez votre évolution et repérez vos points à renforcer.",
  },
];

export function Simulation() {
  return (
    <section id="simulation" className={styles.section}>
      <div className={`container-x ${styles.simInner}`}>
        <div>
          <div className={`${styles.head} ${styles.simHead}`}>
            <span className={styles.headLabel}>Simulation réaliste</span>
            <h2 className={styles.headTitle} style={{ marginInline: 0 }}>
              Entraînez-vous en <em>conditions réelles</em>
            </h2>
            <p className={styles.headDesc} style={{ marginInline: 0 }}>
              Pas de cours théoriques : seulement des mises en situation fidèles
              aux examens officiels, pour être prêt le jour J.
            </p>
          </div>

          <ul className={styles.simList}>
            {SIM_FEATURES.map(({ Icon, title, desc }) => (
              <li key={title} className={styles.simItem}>
                <span className={styles.simItemIcon} aria-hidden>
                  <Icon size={22} strokeWidth={1.5} />
                </span>
                <div>
                  <h3 className={styles.simItemTitle}>{title}</h3>
                  <p className={styles.simItemDesc}>{desc}</p>
                </div>
              </li>
            ))}
          </ul>
        </div>

        <div className={styles.simVisual}>
          <ExamMock />
        </div>
      </div>
    </section>
  );
}

function ExamMock() {
  const options = [
    { k: "A", label: "Liberté, Égalité, Fraternité", ok: true },
    { k: "B", label: "Liberté, Égalité, Solidarité", ok: false },
    { k: "C", label: "Unité, Égalité, Fraternité", ok: false },
  ];
  return (
    <div className={styles.examMock} aria-hidden>
      <div className={styles.examMockBar}>
        <span className={styles.examMockDot} />
        <span className={styles.examMockDot} />
        <span className={styles.examMockDot} />
        <span className={styles.examMockTimer}>⏱ 12:48</span>
      </div>
      <div className={styles.examMockBody}>
        <span className={styles.examMockEyebrow}>CIVIQUE · QUESTION 7 / 20</span>
        <p className={styles.examMockQ}>
          Quelle est la devise de la République française ?
        </p>
        <div className={styles.examMockOpts}>
          {options.map((o) => (
            <div
              key={o.k}
              className={`${styles.examMockOpt} ${o.ok ? styles.examMockOptOk : ""}`}
            >
              <span className={styles.examMockBullet}>{o.k}</span>
              {o.label}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ---------------------------------------------------------------------------
   Niveau (section sombre)
   ------------------------------------------------------------------------- */
const LEVELS = [
  {
    level: "A2",
    title: "Niveau A2",
    desc: "Utilisateur élémentaire : vous comprenez des phrases isolées et des expressions fréquentes.",
  },
  {
    level: "B1",
    title: "Niveau B1",
    desc: "Utilisateur seuil : vous comprenez l'essentiel d'un langage clair et standard.",
  },
  {
    level: "B2",
    title: "Niveau B2",
    desc: "Utilisateur avancé : vous comprenez un texte complexe et communiquez avec fluidité.",
  },
];

export function Niveau() {
  return (
    <section id="niveau" className={styles.niveau}>
      <div className={`container-x ${styles.niveauNarrow}`}>
        <SectionHead
          dark
          label="Votre niveau"
          title="Un niveau estimé à la fin de chaque examen"
          description="À l'issue de votre session, l'application vous situe selon le Cadre Européen Commun de Référence (CECRL)."
        />
        <div className={`${styles.grid} ${styles.levelGrid}`}>
          {LEVELS.map(({ level, title, desc }) => (
            <article key={level} className={styles.levelCard}>
              <span className={styles.levelCircle}>{level}</span>
              <h3 className={styles.levelTitle}>{title}</h3>
              <p className={styles.levelDesc}>{desc}</p>
            </article>
          ))}
        </div>
        <p className={styles.niveauDisclaimer}>
          <Info size={16} aria-hidden />
          Ce niveau est une estimation indicative et ne constitue pas un
          résultat officiel. Seuls les examens agréés par France Éducation
          international délivrent une certification reconnue.
        </p>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------------------
   Témoignages
   NOTE : contenu illustratif (placeholder). À remplacer par de vrais avis
   vérifiés avant la mise en production — exigence « Misleading Claims » des
   stores et honnêteté de la vitrine.
   ------------------------------------------------------------------------- */
const TEMOIGNAGES = [
  {
    text: "Les examens blancs en conditions réelles m'ont mis en confiance. Le jour J, je connaissais déjà le format — plus de stress sur le chrono.",
    name: "Aïcha B.",
    role: "Naturalisation · objectif B2",
  },
  {
    text: "La correction de l'expression écrite par l'IA est précise : elle pointe les fautes récurrentes et explique. J'ai vraiment progressé semaine après semaine.",
    name: "Mehdi T.",
    role: "Carte de résident · TCF IRN",
  },
  {
    text: "Pouvoir réviser le civique sur le téléphone dans les transports a tout changé. 10 questions par jour, et la progression suit entre le web et l'app.",
    name: "Lina K.",
    role: "Première carte de séjour",
  },
];

export function Temoignages() {
  return (
    <section id="temoignages" className={styles.section}>
      <div className="container-x">
        <SectionHead
          label="Ils se préparent avec SejourFR"
          title={
            <>
              Abordez le jour J en <em>confiance</em>
            </>
          }
          description="Un entraînement régulier, des examens blancs fidèles et un suivi de votre niveau : de quoi arriver serein à l'examen."
        />
        <div className={`${styles.grid} ${styles.testiGrid}`}>
          {TEMOIGNAGES.map((t) => (
            <article key={t.name} className={styles.testiCard}>
              <Quote size={26} className={styles.testiQuote} aria-hidden />
              <div className={styles.testiStars} aria-label="5 sur 5">
                {Array.from({ length: 5 }).map((_, i) => (
                  <Star key={i} size={15} fill="currentColor" strokeWidth={0} aria-hidden />
                ))}
              </div>
              <p className={styles.testiText}>{t.text}</p>
              <div className={styles.testiFoot}>
                <span className={styles.testiAvatar} aria-hidden>
                  {t.name.charAt(0)}
                </span>
                <div>
                  <div className={styles.testiName}>{t.name}</div>
                  <div className={styles.testiRole}>{t.role}</div>
                </div>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------------------
   Tarifs (réutilise PricingPlans, alimenté par les plans actifs du backend)
   ------------------------------------------------------------------------- */
export function Tarifs({ plans }: { plans: PlanPublicResponse[] }) {
  return (
    <section id="tarifs" className={`${styles.section} ${styles.sectionPaper}`}>
      <div className="container-x">
        <SectionHead
          label="Tarifs"
          title={
            <>
              Commencez gratuitement, <em>débloquez quand vous voulez</em>
            </>
          }
          description="Un premier examen blanc et des séries offerts pour découvrir. L'accès complet est un paiement unique, sans renouvellement automatique."
        />
        <div className={styles.pricingWrap}>
          <PricingPlans plans={plans} variant="compact" />
        </div>
        <p className={styles.pricingFoot}>
          <Link href="/tarifs" className={styles.pricingLink}>
            Voir le détail des offres et la comparaison
            <ArrowRight size={15} aria-hidden />
          </Link>
        </p>
      </div>
    </section>
  );
}

/* ---------------------------------------------------------------------------
   CTA final
   ------------------------------------------------------------------------- */
export function FinalCta() {
  return (
    <section id="cta" className={styles.ctaSection}>
      <div className="container-x">
        <div className={styles.ctaCard}>
          <h2 className={styles.ctaTitle}>
            Prêt à réussir votre <em>examen</em> ?
          </h2>
          <p className={styles.ctaDesc}>
            Commencez votre entraînement gratuit dès maintenant. Aucune carte
            bancaire requise.
          </p>
          <div className={styles.ctaActions}>
            <Link href="/inscription" className="btn btn-red btn-lg">
              Commencer l&apos;entraînement
              <ArrowRight size={18} className="arrow" aria-hidden />
            </Link>
            <span className={styles.ctaNote}>
              <Smartphone size={16} aria-hidden />
              Sur le web et sur mobile
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}
