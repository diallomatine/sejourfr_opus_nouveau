"use client";

import Link from "next/link";
import { useState } from "react";
import type { FormEvent, ReactNode } from "react";
import { AlertCircle, CheckCircle2, ChevronLeft, ChevronRight, Eye, EyeOff, Loader2 } from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { COMPTE_GATE_CTA, COMPTE_GATE_TEXT, COMPTE_PASSWORD_HIDE, COMPTE_PASSWORD_SHOW } from "@/lib/compte";
import type { AuthenticatedUser } from "@/lib/types";
import { useAppBarBack } from "../AppBarTitle";
import s from "./compte.module.css";

/**
 * Les briques des écrans du compte : le Profil (`/profil`), « Mes
 * informations » et ses trois pages d'édition, et le centre d'aide (`/aide`).
 *
 * 🛑 **Une ligne de compte = `CompteRow`**, partout : le Profil, le hub
 * « Mes informations » et le centre d'aide posent la même ligne (pastille
 * d'icône, titre, sous-titre, chevron). Miroir mobile : `ListGroup` /
 * `ListRow` (`core/widgets/list_group.dart`).
 */

export type CompteTone = "blue" | "green" | "red" | "muted";

function cx(...parts: Array<string | false | null | undefined>): string {
  return parts.filter(Boolean).join(" ");
}

// ── Page ────────────────────────────────────────────────────────────────
export function CompteShell({
  backHref,
  backLabel,
  title,
  lead,
  children,
}: {
  backHref?: string | null;
  backLabel?: string;
  title: string;
  lead?: string;
  children: ReactNode;
}) {
  // Sous 900 px (shell connecté), la flèche de la barre du haut remplace le
  // lien de retour — l'écran de compte Flutter n'a que celle de son en-tête.
  const backInBar = useAppBarBack(backHref ? { fallbackHref: backHref } : null);
  return (
    <main className={s.page}>
      <div className={s.inner}>
        <div className={cx(s.topbar, backInBar && "in-bar-back")}>
          {backHref ? (
            <Link href={backHref} className={s.back}>
              <ChevronLeft size={18} aria-hidden />
              <span>{backLabel}</span>
            </Link>
          ) : null}
        </div>
        <header className={s.head}>
          <h1 className={s.title}>{title}</h1>
          {lead ? <p className={s.lead}>{lead}</p> : null}
        </header>
        <div className={s.body}>{children}</div>
      </div>
    </main>
  );
}

export function CompteGate({ next }: { next: string }) {
  return (
    <main className={s.gate}>
      <p>{COMPTE_GATE_TEXT}</p>
      <Link href={`/connexion?next=${encodeURIComponent(next)}`} className={s.gateCta}>
        {COMPTE_GATE_CTA} →
      </Link>
    </main>
  );
}

export function CompteLoading() {
  return <div className={s.loading} aria-hidden />;
}

/** Les pages du compte exigent une session : squelette, puis porte de connexion. */
export function CompteAuth({
  next,
  children,
}: {
  next: string;
  children: (user: AuthenticatedUser) => ReactNode;
}) {
  const { user, status } = useAuth();
  if (status === "loading") return <CompteLoading />;
  if (!user) return <CompteGate next={next} />;
  return <>{children(user)}</>;
}

/** Le bandeau d'accroche du centre d'aide. Miroir mobile : `_HelpHero`. */
export function CompteHero({ icon, title, text }: { icon: ReactNode; title: string; text: string }) {
  return (
    <div className={s.hero}>
      <span className={s.heroIco} aria-hidden>{icon}</span>
      <div>
        <p className={s.heroTitle}>{title}</p>
        <p className={s.heroText}>{text}</p>
      </div>
    </div>
  );
}

// ── Cartes et lignes ────────────────────────────────────────────────────
export function CompteCard({
  title,
  className,
  children,
}: {
  title?: string;
  className?: string;
  children: ReactNode;
}) {
  return (
    <section className={cx(s.card, className)}>
      {title ? <h2 className={s.cardTitle}>{title}</h2> : null}
      {children}
    </section>
  );
}

export function CompteIcon({ tone = "blue", children }: { tone?: CompteTone; children: ReactNode }) {
  return <span className={cx(s.icon, s[`tone_${tone}`])} aria-hidden>{children}</span>;
}

/**
 * Une ligne de compte. `href` ⇒ lien, `onClick` ⇒ bouton, ni l'un ni
 * l'autre ⇒ ligne de **lecture** (sans chevron — rien ne s'ouvre).
 */
export function CompteRow({
  href,
  onClick,
  icon,
  tone,
  title,
  sub,
  danger,
  chevron,
}: {
  href?: string;
  onClick?: () => void;
  icon: ReactNode;
  tone?: CompteTone;
  title: ReactNode;
  sub?: ReactNode;
  danger?: boolean;
  /** Défaut : un chevron dès que la ligne s'ouvre. */
  chevron?: boolean;
}) {
  const interactive = Boolean(href || onClick);
  const showChevron = chevron ?? interactive;
  const content = (
    <>
      <CompteIcon tone={tone}>{icon}</CompteIcon>
      <span className={s.rowMain}>
        <span className={s.rowTitle}>{title}</span>
        {sub ? <span className={s.rowSub}>{sub}</span> : null}
      </span>
      {showChevron ? <ChevronRight className={s.arrow} size={22} aria-hidden /> : null}
    </>
  );
  const className = cx(s.row, interactive && s.rowAction, danger && s.rowDanger);
  if (href) {
    return (
      <Link href={href} className={className}>
        {content}
      </Link>
    );
  }
  if (onClick) {
    return (
      <button type="button" className={className} onClick={onClick}>
        {content}
      </button>
    );
  }
  return <div className={className}>{content}</div>;
}

// ── Formulaires ─────────────────────────────────────────────────────────
export function CompteForm({
  onSubmit,
  children,
}: {
  onSubmit: () => void;
  children: ReactNode;
}) {
  function handle(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    onSubmit();
  }
  return (
    <form className={s.form} onSubmit={handle} noValidate>
      {children}
    </form>
  );
}

export function CompteField({
  id,
  label,
  value,
  onChange,
  error,
  hint,
  type = "text",
  autoComplete,
  placeholder,
  disabled,
}: {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  error?: string;
  hint?: string;
  type?: "text" | "email" | "password";
  autoComplete?: string;
  placeholder?: string;
  disabled?: boolean;
}) {
  const [revealed, setRevealed] = useState(false);
  const isPassword = type === "password";
  const describedBy = error ? `${id}-error` : hint ? `${id}-hint` : undefined;
  return (
    <div className={s.field}>
      <label htmlFor={id} className={s.label}>{label}</label>
      <div className={s.inputWrap}>
        <input
          id={id}
          className={cx(s.input, isPassword && s.inputWithToggle, error && s.inputError)}
          type={isPassword && revealed ? "text" : type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          autoComplete={autoComplete}
          placeholder={placeholder}
          disabled={disabled}
          aria-invalid={error ? true : undefined}
          aria-describedby={describedBy}
          autoCapitalize={type === "text" ? "words" : "none"}
          spellCheck={false}
        />
        {isPassword ? (
          <button
            type="button"
            className={s.reveal}
            onClick={() => setRevealed((v) => !v)}
            aria-label={revealed ? COMPTE_PASSWORD_HIDE : COMPTE_PASSWORD_SHOW}
            aria-pressed={revealed}
          >
            {revealed ? <EyeOff size={18} aria-hidden /> : <Eye size={18} aria-hidden />}
          </button>
        ) : null}
      </div>
      {error ? (
        <p id={`${id}-error`} className={s.fieldError}>{error}</p>
      ) : hint ? (
        <p id={`${id}-hint`} className={s.fieldHint}>{hint}</p>
      ) : null}
    </div>
  );
}

/** Une précision discrète sous une carte (compte Google / Apple). */
export function CompteFootnote({ children }: { children: ReactNode }) {
  return <p className={s.footnote}>{children}</p>;
}

/** Une valeur en lecture seule, présentée comme un champ. */
export function CompteReadonly({ label, value }: { label: string; value: string }) {
  return (
    <div className={s.field}>
      <span className={s.label}>{label}</span>
      <span className={cx(s.input, s.readonly)}>{value}</span>
    </div>
  );
}

export function CompteAlert({ tone, children }: { tone: "error" | "ok"; children: ReactNode }) {
  const ok = tone === "ok";
  return (
    <div className={cx(s.alert, ok ? s.alertOk : s.alertError)} role={ok ? "status" : "alert"}>
      {ok ? <CheckCircle2 size={18} aria-hidden /> : <AlertCircle size={18} aria-hidden />}
      <span>{children}</span>
    </div>
  );
}

export function CompteSubmit({
  loading,
  label,
  loadingLabel,
}: {
  loading: boolean;
  label: string;
  loadingLabel: string;
}) {
  return (
    <button type="submit" className={s.submit} disabled={loading} aria-busy={loading}>
      {loading ? <Loader2 className={s.spin} size={18} aria-hidden /> : null}
      <span>{loading ? loadingLabel : label}</span>
    </button>
  );
}

/** L'état final d'un flux : ce qui s'est passé, et le chemin du retour. */
export function CompteDone({
  title,
  body,
  actionHref,
  actionLabel,
}: {
  title: string;
  body: string;
  actionHref: string;
  actionLabel: string;
}) {
  return (
    <div className={s.done} role="status">
      <span className={s.doneIco} aria-hidden>
        <CheckCircle2 size={26} />
      </span>
      <h2 className={s.doneTitle}>{title}</h2>
      <p className={s.doneBody}>{body}</p>
      <Link href={actionHref} className={s.doneAction}>
        {actionLabel}
      </Link>
    </div>
  );
}

/** Un compte Google / Apple sur une page qu'il ne peut pas utiliser. */
export function CompteProviderNote({
  note,
  actionHref,
  actionLabel,
}: {
  note: string;
  actionHref: string;
  actionLabel: string;
}) {
  return (
    <div className={s.note}>
      <p>{note}</p>
      <Link href={actionHref} className={s.doneAction}>
        {actionLabel}
      </Link>
    </div>
  );
}
