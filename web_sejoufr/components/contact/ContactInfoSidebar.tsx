import Link from "next/link";
import { ArrowRight, Clock, HelpCircle, Mail } from "lucide-react";
import type { LucideIcon } from "lucide-react";

export function ContactInfoSidebar() {
  return (
    <aside className="contact-side">
      <Block icon={Clock} title="Délais de réponse">
        <p className="contact-side-text">
          <strong>24 heures ouvrées</strong> en moyenne, du lundi au vendredi
          (hors jours fériés).
        </p>
      </Block>

      <Block icon={Mail} title="Vous préférez écrire directement ?">
        <a href="mailto:support@sejourfr.fr" className="contact-side-mail">
          support@sejourfr.fr
        </a>
        <p className="contact-side-meta">
          Vos messages arrivent directement dans la boîte de l&apos;équipe.
        </p>
      </Block>

      <Block
        icon={HelpCircle}
        title="80 % des questions trouvent leur réponse dans la FAQ"
      >
        <p className="contact-side-text">
          Examen civique, naturalisation, démarches, tarifs : 38 questions
          déjà documentées.
        </p>
        <Link href="/faq" className="contact-side-link">
          Consulter la FAQ
          <ArrowRight />
        </Link>
      </Block>

      <style>{`
        .contact-side {
          display: flex;
          flex-direction: column;
          gap: 16px;
        }
        .contact-side-text {
          margin: 0;
          color: var(--color-muted);
          font-size: 14.5px;
          line-height: 1.55;
        }
        .contact-side-text strong { color: var(--color-ink); font-weight: 600; }
        .contact-side-mail {
          display: inline-block;
          color: var(--color-blue);
          font-weight: 600;
          font-size: 14.5px;
          word-break: break-all;
        }
        .contact-side-mail:hover { text-decoration: underline; }
        .contact-side-meta {
          margin: 8px 0 0;
          color: var(--color-muted-2);
          font-size: 12.5px;
          line-height: 1.5;
        }
        .contact-side-link {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          margin-top: 12px;
          color: var(--color-blue);
          font-weight: 600;
          font-size: 14px;
        }
        .contact-side-link:hover { text-decoration: underline; }
        .contact-side-link svg { width: 14px; height: 14px; }
        @media (min-width: 1024px) {
          .contact-side { position: sticky; top: 96px; }
        }
      `}</style>
    </aside>
  );
}

function Block({
  icon: Icon,
  title,
  children,
}: {
  icon: LucideIcon;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div className="contact-side-block">
      <div className="contact-side-head">
        <span className="contact-side-icon">
          <Icon />
        </span>
        <h3 className="contact-side-title">{title}</h3>
      </div>
      {children}

      <style>{`
        .contact-side-block {
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 16px;
          padding: 20px;
        }
        .contact-side-head {
          display: flex;
          align-items: center;
          gap: 10px;
          margin-bottom: 12px;
        }
        .contact-side-icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 36px;
          height: 36px;
          border-radius: 10px;
          background: var(--color-blue-light);
          color: var(--color-blue);
          flex-shrink: 0;
        }
        .contact-side-icon svg { width: 16px; height: 16px; }
        .contact-side-title {
          margin: 0;
          font-family: var(--font-display);
          font-weight: 600;
          font-size: 15.5px;
          line-height: 1.3;
          color: var(--color-ink);
        }
      `}</style>
    </div>
  );
}
