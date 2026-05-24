import Link from "next/link";
import {
  ArrowRight,
  BarChart3,
  BookOpen,
  Brain,
  Building2,
  Check,
  Clock,
  FileText,
  GraduationCap,
  Headphones,
  Info,
  Mic,
  PenLine,
  Smartphone,
} from "lucide-react";
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
   Hero
   ------------------------------------------------------------------------- */
const HERO_BADGES = [
  "Conditions réelles d'examen",
  "Correction par IA",
  "Niveau estimé A2 · B1 · B2",
];

export function Hero() {
  return (
    <section className={styles.hero}>
      <div className={styles.heroBg} aria-hidden />
      <div className={`container-x ${styles.heroInner}`}>
        <div className={styles.heroText}>
          <span className={styles.heroBrand}>
            <span className="cocarde lg" aria-hidden />
            <span className={styles.heroWordmark}>
              Sejour<em>FR</em>
            </span>
          </span>

          <span className={styles.heroEyebrow}>Obligatoire depuis janvier 2026</span>

          <h1 className={styles.heroTitle}>
            Réussissez votre <em>TCF IRN</em> et votre examen civique
          </h1>

          <p className={styles.heroSub}>
            Entraînez-vous dans des conditions réelles d&apos;examen.
            Compréhension et expression écrite et orale, structure de la langue —
            tout est analysé par IA pour vous situer précisément.
          </p>

          <div className={styles.heroCtas}>
            <Link href="/inscription" className="btn btn-red btn-lg">
              Commencer gratuitement
              <ArrowRight size={18} className="arrow" aria-hidden />
            </Link>
            <a href="#examens" className="btn btn-ghost btn-lg">
              Découvrir les examens
            </a>
          </div>

          <ul className={styles.heroBadges}>
            {HERO_BADGES.map((b) => (
              <li key={b} className={styles.heroBadge}>
                <Check size={16} className={styles.badgeCheck} aria-hidden />
                {b}
              </li>
            ))}
          </ul>
        </div>

        {/* Visuel attractif (desktop) : carte "niveau estimé" + chips flottantes */}
        <div className={styles.heroVisual} aria-hidden>
          <div className={styles.heroCard}>
            <div className={styles.heroCardTop}>
              <span className={styles.heroCardEyebrow}>Résultat · TCF IRN</span>
              <span className={styles.heroCardTag}>Analysé par IA</span>
            </div>
            <div className={styles.heroCardLevel}>B1</div>
            <div className={styles.heroCardLabel}>Niveau estimé · CECRL</div>
            <div className={styles.heroCardBar}>
              <span style={{ width: "72%" }} />
            </div>
            <div className={styles.heroCardStats}>
              <div>
                <strong>76%</strong>
                <span>Score moyen</span>
              </div>
              <div>
                <strong>4</strong>
                <span>Compétences</span>
              </div>
              <div>
                <strong>12</strong>
                <span>Examens blancs</span>
              </div>
            </div>
          </div>
          <span className={`${styles.heroFloat} ${styles.heroFloatA}`}>
            <Check size={14} className={styles.badgeCheck} aria-hidden /> Conditions réelles
          </span>
          <span className={`${styles.heroFloat} ${styles.heroFloatB}`}>🎯 Objectif B2</span>
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
    badge: "Examen officiel",
    desc: "Préparez l'épreuve sur les valeurs de la République française, l'organisation politique et la vie quotidienne en France.",
    features: [
      "Valeurs de la République",
      "Organisation politique française",
      "Vie quotidienne en France",
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
