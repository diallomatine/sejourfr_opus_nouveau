import Link from "next/link";
import styles from "./auth.module.css";

const STATS = [
  { num: "2 500+", label: "Questions calibrées" },
  { num: "94 %", label: "Taux de réussite" },
  { num: "8 200+", label: "Candidats inscrits" },
  { num: "4,8 /5", label: "Note utilisateurs" },
];

interface Visual {
  tag: string;
  quote: string;
  authorInitials: string;
  authorName: string;
  authorMeta: string;
  avatarTone: "blue" | "red";
}

interface AuthShellProps {
  eyebrow: string;
  eyebrowTone: "blue" | "green";
  title: React.ReactNode;
  subtitle: React.ReactNode;
  /** Le <form> et tout ce qui suit (submit, Google, lien de bascule). */
  children: React.ReactNode;
  visual: Visual;
}

/**
 * Shell partagé des pages d'auth : colonne formulaire (gauche) + panneau visuel
 * témoignage (droite, masqué sous 980px). Mobile-first. Toute la logique de
 * formulaire vit dans la page appelante, passée en `children`.
 */
export function AuthShell({
  eyebrow,
  eyebrowTone,
  title,
  subtitle,
  children,
  visual,
}: AuthShellProps) {
  return (
    <div className={styles.wrap}>
      {/* ----- Colonne formulaire ----- */}
      <div className={styles.formSide}>
        <Link href="/" className={styles.brand} aria-label="Retour à l'accueil SejourFR">
          <span className="cocarde" aria-hidden />
          <span className={styles.brandWordmark}>
            Sejour<em>FR</em>
          </span>
        </Link>

        <div className={styles.inner}>
          <span
            className={`${styles.eyebrow} ${
              eyebrowTone === "green" ? styles.eyebrowGreen : styles.eyebrowBlue
            }`}
          >
            <span className={styles.eyebrowDot} aria-hidden />
            {eyebrow}
          </span>
          <h1 className={styles.h1}>{title}</h1>
          <p className={styles.sub}>{subtitle}</p>

          {children}

          <p className={styles.legal}>
            <ShieldIcon /> Données hébergées en France · Conforme RGPD · Aucun
            partage avec des tiers.
          </p>
        </div>
      </div>

      {/* ----- Panneau visuel ----- */}
      <aside className={styles.visualSide} aria-hidden>
        <div className={styles.visualBg} />
        <div className={styles.visualContent}>
          <div className={styles.visualTop}>
            <span className={styles.visualTopBar} />
            {visual.tag}
          </div>

          <blockquote className={styles.quote}>
            <div className={styles.quoteMark}>&ldquo;</div>
            <p className={styles.quoteText}>{visual.quote}</p>
            <footer className={styles.author}>
              <div
                className={`${styles.avatar} ${
                  visual.avatarTone === "red" ? styles.avatarRed : styles.avatarBlue
                }`}
              >
                {visual.authorInitials}
              </div>
              <div>
                <div className={styles.authorName}>{visual.authorName}</div>
                <div className={styles.authorMeta}>{visual.authorMeta}</div>
              </div>
            </footer>
          </blockquote>

          <div className={styles.stats}>
            {STATS.map((s) => (
              <div key={s.label}>
                <div className={styles.statNum}>{s.num}</div>
                <div className={styles.statLabel}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </aside>
    </div>
  );
}

const ShieldIcon = () => (
  <svg
    width="13"
    height="13"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    aria-hidden
  >
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </svg>
);
