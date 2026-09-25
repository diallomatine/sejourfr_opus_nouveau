import { ArrowRight, Check, ShieldCheck } from "lucide-react";
import Link from "next/link";
import type { ReactNode } from "react";
import type { AuthPanel } from "./auth-panels";
import styles from "./auth.module.css";

interface AuthShellProps {
  kicker: string;
  title: ReactNode;
  subtitle: ReactNode;
  panel: AuthPanel;
  /** Au-dessus de la carte, à la largeur de la grille (ex. le fil du diagnostic). */
  header?: ReactNode;
  /** Le formulaire et tout ce qui suit (submit, Google, lien de bascule). */
  children: ReactNode;
}

/**
 * Coquille des écrans d'auth, dans le langage de l'accueil : carte formulaire +
 * panneau d'argumentaire (`auth-panels.ts`). ≥ 980 px, deux colonnes ; en
 * dessous, le panneau passe sous le formulaire en version résumée. La logique
 * du formulaire vit dans `RegisterForm` / `LoginForm`, passés en `children`.
 *
 * Montée par `/inscription`, `/connexion`, les écrans de mot de passe ET les
 * deux écrans de compte des diagnostics invités — un seul rendu pour un seul
 * geste.
 */
export function AuthShell({ kicker, title, subtitle, panel, header, children }: AuthShellProps) {
  return (
    <div className={styles.page}>
      {header ? <div className={styles.shellTop}>{header}</div> : null}
      <div className={styles.grid}>
        <section className={styles.card} aria-labelledby="auth-title">
          <span className={styles.kicker}>{kicker}</span>
          <h1 id="auth-title" className={styles.h1}>
            {title}
          </h1>
          <p className={styles.sub}>{subtitle}</p>

          {children}

          <p className={styles.legal}>
            <ShieldCheck size={14} aria-hidden />
            <span>
              Hébergement en France · Aucune donnée vendue ·{" "}
              <Link href="/confidentialite">Confidentialité</Link>
            </span>
          </p>
        </section>

        <AuthPanelView panel={panel} />
      </div>
    </div>
  );
}

function AuthPanelView({ panel }: { panel: AuthPanel }) {
  return (
    <aside className={styles.panel} aria-labelledby="auth-panel-title">
      <div className={styles.panelCard}>
        <span className={styles.kicker}>{panel.kicker}</span>
        <h2 id="auth-panel-title" className={styles.panelTitle}>
          {panel.title.lead} <em>{panel.title.em}</em>
          {panel.title.tail ? ` ${panel.title.tail}` : null}
        </h2>

        <ol className={styles.points}>
          {panel.items.map(({ title, text, Icon }, i) => (
            <li key={title} className={styles.point}>
              <span className={styles.pointBadge} aria-hidden>
                {Icon ? <Icon size={18} /> : String(i + 1).padStart(2, "0")}
              </span>
              <div className={styles.pointCopy}>
                <strong>{title}</strong>
                {text ? <span>{text}</span> : null}
              </div>
            </li>
          ))}
        </ol>

        {panel.trust ? (
          <ul className={styles.trust}>
            {panel.trust.map((t) => (
              <li key={t}>
                <span className={styles.trustIcon} aria-hidden>
                  <Check size={11} strokeWidth={3} />
                </span>
                {t}
              </li>
            ))}
          </ul>
        ) : null}

        {panel.note ? <p className={styles.panelNote}>{panel.note}</p> : null}

        {panel.link ? (
          <Link href={panel.link.href} className={styles.panelLink}>
            {panel.link.label}
            <ArrowRight size={15} aria-hidden />
          </Link>
        ) : null}
      </div>
    </aside>
  );
}
