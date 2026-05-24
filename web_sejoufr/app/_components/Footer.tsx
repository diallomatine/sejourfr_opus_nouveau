"use client";

import Link from "next/link";
import {usePathname} from "next/navigation";
import {useState} from "react";
import {Heart, Mail, Send} from "lucide-react";
import {ApiException, newsletterApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {shouldHideGlobalChrome} from "@/lib/chrome-routes";

// lucide-react ne distribue plus les icônes de marques (politique de trademark) :
// on définit nos propres SVG pour Twitter/Instagram/LinkedIn/YouTube/GitHub.
type IconProps = { className?: string };
const Twitter = ({className}: IconProps) => (
    <svg viewBox="0 0 24 24" className={className} fill="currentColor" aria-hidden focusable="false">
        <path
            d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
);
const Instagram = ({className}: IconProps) => (
    <svg viewBox="0 0 24 24" className={className} fill="none" stroke="currentColor" strokeWidth="2"
         strokeLinecap="round" strokeLinejoin="round" aria-hidden focusable="false">
        <rect x="2" y="2" width="20" height="20" rx="5" ry="5"/>
        <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/>
        <line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/>
    </svg>
);
const Linkedin = ({className}: IconProps) => (
    <svg viewBox="0 0 24 24" className={className} fill="none" stroke="currentColor" strokeWidth="2"
         strokeLinecap="round" strokeLinejoin="round" aria-hidden focusable="false">
        <path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-4 0v7h-4v-7a6 6 0 0 1 6-6z"/>
        <rect x="2" y="9" width="4" height="12"/>
        <circle cx="4" cy="4" r="2"/>
    </svg>
);
const Youtube = ({className}: IconProps) => (
    <svg viewBox="0 0 24 24" className={className} fill="none" stroke="currentColor" strokeWidth="2"
         strokeLinecap="round" strokeLinejoin="round" aria-hidden focusable="false">
        <path
            d="M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19.1c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 0 0 0 1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.33z"/>
        <polygon points="9.75 15.02 15.5 11.75 9.75 8.48 9.75 15.02" fill="currentColor" stroke="none"/>
    </svg>
);
const Github = ({className}: IconProps) => (
    <svg viewBox="0 0 24 24" className={className} fill="currentColor" aria-hidden focusable="false">
        <path
            d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.4 3-.405 1.02.005 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>
    </svg>
);

const productLinks = [
    {href: "/entrainement?module=CIVIQUE", label: "Module civique"},
    {href: "/entrainement?module=TCF", label: "Module TCF"},
    {href: "/tarifs", label: "Tarifs"},
];

const resourceLinks = [
    {href: "/blog", label: "Blog"},
    {href: "/faq", label: "FAQ"},
    {href: "/blog/demande-naturalisation-francaise-guide-complet", label: "Guide naturalisation"},
];

const legalLinks = [
    {href: "/cgu", label: "CGU"},
    {href: "/mentions-legales", label: "Mentions légales"},
    {href: "/confidentialite", label: "Confidentialité"},
    {href: "/confidentialite#article-8", label: "Cookies"},
    {href: "/contact", label: "Contact"},
];

const socials = [
    {href: "https://twitter.com", label: "Twitter / X", Icon: Twitter},
    {href: "https://instagram.com", label: "Instagram", Icon: Instagram},
    {href: "https://linkedin.com", label: "LinkedIn", Icon: Linkedin},
    {href: "https://youtube.com", label: "YouTube", Icon: Youtube},
    {href: "https://github.com", label: "GitHub", Icon: Github},
];

export function Footer() {
    const pathname = usePathname();
    const {status, user} = useAuth();
    const isAuth = status === "authenticated" && user !== null;
    if (shouldHideGlobalChrome(pathname, isAuth)) return null;

    return (
        <footer className="site-footer">
            <div className="footer-blob footer-blob-blue" aria-hidden/>
            <div className="footer-blob footer-blob-red" aria-hidden/>

            <div className="container-x footer-inner">
                <NewsletterBlock/>

                <div className="footer-grid">
                    <div className="footer-brand-col">
                        <Link href="/" className="footer-brand">
                            <FooterLogo/>
                            <span className="footer-brand-name">SejourFR</span>
                        </Link>
                        <p className="footer-pitch">
                            Préparez sereinement votre examen civique pour le titre de séjour
                            et votre entretien de naturalisation.
                        </p>
                        <div className="footer-flag" role="img" aria-label="Drapeau français">
                            <span className="flag-band flag-blue"/>
                            <span className="flag-band flag-white"/>
                            <span className="flag-band flag-red"/>
                        </div>
                    </div>

                    <FooterColumn title="Produit" links={productLinks}/>
                    <FooterColumn title="Ressources" links={resourceLinks}/>
                    <FooterColumn title="Légal" links={legalLinks}/>
                </div>

                <div className="footer-socials">
                    {socials.map(({href, label, Icon}) => (
                        <a
                            key={label}
                            href={href}
                            target="_blank"
                            rel="noopener noreferrer"
                            aria-label={label}
                            className="footer-social"
                        >
                            <Icon className="footer-social-icon"/>
                        </a>
                    ))}
                </div>
            </div>

            <div className="footer-bar">
                <div className="container-x footer-bar-inner">
          <span>
            © {new Date().getFullYear()} SejourFR. Tous droits réservés.
          </span>
                    <span className="footer-made">
            Made with
            <Heart className="footer-heart"/>
            in France
          </span>
                    <LanguageSelector/>
                </div>
            </div>

            <style>{`
        .site-footer {
          position: relative;
          background: var(--color-blue);
          color: #fff;
          font-weight: 400;
          margin-top: 64px; 
          overflow: hidden;
        }
        .footer-blob {
          position: absolute;
          pointer-events: none;
          width: 288px;
          height: 288px;
          border-radius: 9999px;
          filter: blur(64px);
        }
        .footer-blob-blue {
          top: -128px;
          left: -128px;
          background: rgba(30, 58, 140, 0.30);
        }
        .footer-blob-red {
          bottom: -128px;
          right: -128px;
          background: rgba(225, 55, 47, 0.20);
        }
        .footer-inner {
          position: relative;
          /* padding-top seul : on garde le padding horizontal de .container-x
             (sinon la shorthand 'padding' écrase tout et le contenu colle
             aux bords du viewport sur mobile). */
          padding-top: 64px;
        }

        .footer-grid {
          display: grid;
          grid-template-columns: repeat(4, minmax(0, 1fr));
          gap: 40px;
          margin-top: 56px;
        }
        .footer-brand {
          display: inline-flex;
          align-items: center;
          gap: 10px;
          text-decoration: none;
        }
        .footer-brand:hover .footer-logo {
          transform: rotate(18deg);
        }
        .footer-logo {
          width: 32px;
          height: 32px;
          flex-shrink: 0;
          transition: transform 0.3s ease;
        }
        .footer-brand-name {
          font-family: var(--font-sans);
          font-weight: 800;
          font-size: 18px;
          letter-spacing: -0.015em;
          color: #fff;
        }
        .footer-pitch {
          font-size: 14px;
          line-height: 1.6;
          color: #fff;
          font-weight: 500;
          margin: 16px 0 0;
          max-width: 300px;
        }
        .footer-flag {
          display: flex;
          align-items: center;
          margin-top: 20px;
          width: 64px;
          height: 24px;
          border-radius: 6px;
          overflow: hidden;
          box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.10);
        }
        .flag-band { height: 100%; width: 33.333%; }
        .flag-blue { background: var(--color-blue); }
        .flag-white { background: #fff; }
        .flag-red { background: var(--color-red); }

        .footer-col-title {
          font-size: 13px;
          font-weight: 600;
          color: #fff;
          margin: 0 0 16px;
          text-transform: uppercase;
          letter-spacing: 0.08em;
          font-family: var(--font-mono);
        }
        .footer-col-list {
          list-style: none;
          padding: 0;
          margin: 0;
          display: flex;
          flex-direction: column;
          gap: 10px;
        }
        .footer-col-link {
          font-size: 14px;
          color: #fff;
          font-weight: 500;
          text-decoration: none;
          transition: opacity 0.2s ease;
        }
        .footer-col-link:hover { opacity: 0.75; }

        .footer-socials {
          display: flex;
          align-items: center;
          gap: 12px;
          margin: 56px 0 0;
          padding-bottom: 64px;
        }
        .footer-social {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 40px;
          height: 40px;
          border-radius: 9999px;
          background: rgba(255, 255, 255, 0.05);
          color: #94A3B8;
          box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.10);
          transition: all 0.2s ease;
        }
        .footer-social:hover {
          background: rgba(255, 255, 255, 0.10);
          color: #fff;
          box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.20);
        }
        .footer-social-icon { width: 16px; height: 16px; }

        .footer-bar {
          position: relative;
          border-top: 1px solid rgba(255, 255, 255, 0.10);
        }
        .footer-bar-inner {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          justify-content: space-between;
          gap: 16px;
          /* idem footer-inner : on préserve le padding horizontal de .container-x */
          padding-top: 24px;
          padding-bottom: 24px;
          font-size: 12px;
          color: #fff;
          font-weight: 500;
        }
        .footer-made {
          display: inline-flex;
          align-items: center;
          gap: 6px;
        }
        .footer-heart {
          width: 14px;
          height: 14px;
          color: var(--color-red);
          fill: var(--color-red);
        }

        @media (max-width: 900px) {
          .footer-grid {
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 32px;
          }
          .footer-brand-col { grid-column: span 2; }
        }
        @media (max-width: 640px) {
          .footer-inner { padding-top: 48px; }
          .footer-grid { margin-top: 40px; gap: 28px; }
          .footer-socials { margin-top: 40px; padding-bottom: 48px; gap: 10px; }
          .footer-social { width: 38px; height: 38px; }
          .footer-bar-inner {
            justify-content: flex-start;
            padding-top: 20px;
            padding-bottom: 20px;
            gap: 12px;
          }
        }
        @media (max-width: 480px) {
          .footer-grid { grid-template-columns: 1fr; gap: 24px; }
          .footer-brand-col { grid-column: auto; }
          .footer-pitch { max-width: none; }
        }
      `}</style>
        </footer>
    );
}

function FooterColumn({
                          title,
                          links,
                      }: {
    title: string;
    links: { href: string; label: string }[];
}) {
    return (
        <div>
            <h3 className="footer-col-title">{title}</h3>
            <ul className="footer-col-list">
                {links.map((l) => (
                    <li key={l.label}>
                        <Link href={l.href} className="footer-col-link">
                            {l.label}
                        </Link>
                    </li>
                ))}
            </ul>
        </div>
    );
}

type FeedbackKind = "success" | "info" | "error";

interface Feedback {
    kind: FeedbackKind;
    message: string;
}

function NewsletterBlock() {
    const [email, setEmail] = useState("");
    const [loading, setLoading] = useState(false);
    const [feedback, setFeedback] = useState<Feedback | null>(null);

    const onSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        const trimmed = email.trim();
        if (!trimmed) return;
        setLoading(true);
        setFeedback(null);
        try {
            const data = await newsletterApi.subscribe(trimmed, "footer");
            setEmail("");
            setFeedback(
                data.alreadySubscribed
                    ? {kind: "info", message: "Vous êtes déjà inscrit·e à la newsletter."}
                    : {kind: "success", message: "Merci ! Vous êtes inscrit·e à la newsletter."}
            );
        } catch (err) {
            const msg =
                err instanceof ApiException && err.status === 404
                    ? "Service bientôt disponible — réessayez plus tard."
                    : "Impossible d'enregistrer votre inscription pour le moment.";
            setFeedback({kind: "error", message: msg});
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="newsletter">
            <div>
                <h2 className="newsletter-title">
                    Conseils, mises à jour, nouvelles questions.
                </h2>
                <p className="newsletter-lede">
                    Rejoignez la newsletter pour recevoir nos meilleurs conseils pour
                    réussir l&apos;examen civique et votre naturalisation.
                </p>
            </div>
            <div className="newsletter-right">
                {/* suppressHydrationWarning : neutralise les attributs injectés par les
            extensions navigateur (Grammarly, etc.) sur form / input qui sinon
            génèrent un hydration mismatch côté React. */}
                <form
                    onSubmit={onSubmit}
                    className="newsletter-form"
                    suppressHydrationWarning
                >
                    <label className="newsletter-input-wrap">
                        <span className="sr-only">Adresse email</span>
                        <Mail className="newsletter-input-icon" aria-hidden/>
                        <input
                            type="email"
                            required
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="vous@exemple.fr"
                            className="newsletter-input"
                            suppressHydrationWarning
                        />
                    </label>
                    <button type="submit" disabled={loading} className="newsletter-submit">
                        <Send className="newsletter-submit-icon"/>
                        {loading ? "..." : "S'abonner"}
                    </button>
                </form>
                {feedback && (
                    <p
                        className={`newsletter-feedback newsletter-feedback-${feedback.kind}`}
                        role="status"
                    >
                        {feedback.message}
                    </p>
                )}
            </div>

            <style>{`
        .newsletter {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 32px;
          align-items: center;
          padding-bottom: 40px;
          border-bottom: 1px solid rgba(255, 255, 255, 0.10);
        }
        .newsletter-title {
          font-family: var(--font-sans);
          font-size: 24px;
          font-weight: 700;
          color: #fff;
          letter-spacing: -0.015em;
          margin: 0;
        }
        .newsletter-lede {
          font-size: 14px;
          line-height: 1.6;
          color: #fff;
          font-weight: 500;
          margin: 8px 0 0;
        }
        .newsletter-right { display: flex; flex-direction: column; gap: 10px; }
        .newsletter-form {
          display: flex;
          flex-direction: row;
          gap: 8px;
        }
        .newsletter-input-wrap {
          position: relative;
          flex: 1;
          display: block;
        }
        .newsletter-input-icon {
          pointer-events: none;
          position: absolute;
          left: 12px;
          top: 50%;
          transform: translateY(-50%);
          width: 16px;
          height: 16px;
          color: #64748B;
        }
        .newsletter-input {
          width: 100%;
          height: 44px;
          padding: 0 12px 0 36px;
          border-radius: 12px;
          background: rgba(255, 255, 255, 0.05);
          border: 1px solid rgba(255, 255, 255, 0.10);
          font-family: var(--font-sans);
          font-size: 14px;
          color: #fff;
          transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .newsletter-input::placeholder { color: #64748B; }
        .newsletter-input:focus {
          outline: none;
          border-color: rgba(255, 255, 255, 0.20);
          box-shadow: 0 0 0 2px rgba(30, 58, 140, 0.40);
        }
        .newsletter-submit {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          height: 44px;
          padding: 0 20px;
          border-radius: 12px;
          background: #fff;
          color: #0F172A;
          font-family: var(--font-sans);
          font-size: 14px;
          font-weight: 500;
          border: none;
          cursor: pointer;
          transition: background-color 0.15s ease;
        }
        .newsletter-submit:hover:not(:disabled) { background: #F1F5F9; }
        .newsletter-submit:disabled { opacity: 0.6; cursor: not-allowed; }
        .newsletter-submit-icon { width: 16px; height: 16px; }
        .newsletter-feedback {
          margin: 0;
          font-size: 13px;
          line-height: 1.4;
        }
        .newsletter-feedback-success { color: #4ADE80; }
        .newsletter-feedback-info { color: #94A3B8; }
        .newsletter-feedback-error { color: #FCA5A5; }

        .sr-only {
          position: absolute;
          width: 1px; height: 1px;
          padding: 0; margin: -1px;
          overflow: hidden; clip: rect(0,0,0,0);
          white-space: nowrap; border: 0;
        }

        @media (max-width: 720px) {
          .newsletter { grid-template-columns: 1fr; gap: 24px; padding-bottom: 32px; }
          .newsletter-form { flex-direction: column; }
        }
        @media (max-width: 480px) {
          .newsletter-title { font-size: 20px; line-height: 1.25; }
          .newsletter-lede { font-size: 13.5px; }
          .newsletter-submit { width: 100%; }
        }
      `}</style>
        </div>
    );
}

function LanguageSelector() {
    return (
        <div className="lang-switch">
            <button type="button" className="lang-btn lang-active" aria-current="true">
                FR
            </button>
            <button
                type="button"
                disabled
                className="lang-btn lang-disabled"
                title="Bientôt disponible"
            >
                EN · bientôt
            </button>

            <style>{`
        .lang-switch {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          padding: 2px;
          border-radius: 9999px;
          background: rgba(255, 255, 255, 0.05);
          box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.10);
        }
        .lang-btn {
          height: 28px;
          padding: 0 12px;
          border-radius: 9999px;
          font-family: var(--font-sans);
          font-size: 12px;
          font-weight: 500;
          border: none;
          background: transparent;
          cursor: pointer;
        }
        .lang-active {
          background: #fff;
          color: #0F172A;
        }
        .lang-disabled {
          color: #64748B;
          cursor: not-allowed;
        }
      `}</style>
        </div>
    );
}

function FooterLogo() {
    return (
        <svg viewBox="0 0 32 32" className="footer-logo" aria-hidden focusable="false">
            <defs>
                <linearGradient id="footer-logo-rim" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0%" stopColor="#0F2C66"/>
                    <stop offset="100%" stopColor="#1E40AF"/>
                </linearGradient>
            </defs>
            <circle cx="16" cy="16" r="15" fill="url(#footer-logo-rim)"/>
            <circle cx="16" cy="16" r="10" fill="#FFFFFF"/>
            <circle cx="16" cy="16" r="5" fill="#E1373B"/>
        </svg>
    );
}
