"use client";

import Link from "next/link";
import {usePathname} from "next/navigation";
import {useState} from "react";
import {Heart, Mail, Send} from "lucide-react";
import {ApiException, newsletterApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {shouldHideGlobalChrome} from "@/lib/chrome-routes";

// La présence officielle de SejourFR = ses apps sur les stores (pas de comptes
// réseaux sociaux à ce jour). On rend les logos App Store / Google Play plutôt
// que des liens génériques vers twitter.com/instagram.com, etc.
type IconProps = { className?: string };
const AppStore = ({className}: IconProps) => (
    <svg viewBox="0 0 24 24" className={className} fill="currentColor" aria-hidden focusable="false">
        <path
            d="M17.05 12.54c-.02-2.06 1.68-3.05 1.76-3.1-.96-1.4-2.45-1.6-2.98-1.62-1.27-.13-2.48.75-3.12.75-.64 0-1.64-.73-2.7-.71-1.39.02-2.67.81-3.38 2.05-1.44 2.5-.37 6.2 1.03 8.23.69.99 1.51 2.11 2.58 2.07 1.03-.04 1.42-.67 2.67-.67 1.25 0 1.6.67 2.69.65 1.11-.02 1.82-1.01 2.5-2.01.79-1.15 1.11-2.27 1.13-2.33-.02-.01-2.17-.83-2.19-3.3zM15 6.24c.57-.69.95-1.65.85-2.61-.82.03-1.81.55-2.4 1.24-.53.6-.99 1.58-.87 2.51.91.07 1.85-.46 2.42-1.14z"/>
    </svg>
);
const PlayStore = ({className}: IconProps) => (
    <svg viewBox="0 0 24 24" className={className} fill="currentColor" aria-hidden focusable="false">
        <path
            d="M3.6 2.32a1.02 1.02 0 0 0-.35.79v17.78c0 .33.13.61.36.79l.1.06 9.96-9.96v-.24L3.7 2.26l-.1.06zm13.4 6.4L14.7 6.9 4.86 1.28c-.28-.16-.55-.18-.78-.06l9.96 9.97 3.96-2.47zm3.16 1.9-2.4-1.5-3.3 2.88 3.3 3.3 2.4-1.5c.7-.44.7-1.24 0-1.68zM4.08 22.78c.23.12.5.1.78-.06l9.84-5.62-3.4-3.4-9.96 9.97.74-.89z"/>
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
    {href: "/a-propos", label: "À propos"},
    {href: "/cgu", label: "CGU"},
    {href: "/mentions-legales", label: "Mentions légales"},
    {href: "/confidentialite", label: "Confidentialité"},
    {href: "/confidentialite#article-8", label: "Cookies"},
    {href: "/contact", label: "Contact"},
];

const socials = [
    {
        href: "https://apps.apple.com/fr/app/sejourfr/id6771509569",
        label: "SejourFR sur l'App Store",
        Icon: AppStore,
    },
    {
        href: "https://play.google.com/store/apps/details?id=com.sejourfr.app&hl=fr",
        label: "SejourFR sur Google Play",
        Icon: PlayStore,
    },
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
                <div className="container-x">
                    <p className="footer-disclaimer">
                        SejourFR est un outil d&apos;entraînement indépendant, non affilié au
                        gouvernement français, à l&apos;OFII, au ministère de l&apos;Intérieur ni à
                        France Éducation International.{" "}
                        <Link href="/a-propos" className="footer-disclaimer-link">
                            En savoir plus
                        </Link>
                    </p>
                </div>
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
        .footer-disclaimer {
          margin: 0;
          padding-top: 20px;
          font-size: 12px;
          line-height: 1.6;
          color: rgba(255, 255, 255, 0.75);
          font-weight: 500;
        }
        .footer-disclaimer-link {
          color: #fff;
          font-weight: 600;
          text-decoration: underline;
          text-underline-offset: 2px;
          transition: opacity 0.2s ease;
        }
        .footer-disclaimer-link:hover { opacity: 0.8; }
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
          /* 16px : évite le zoom iOS au focus (et donc le scroll horizontal). */
          font-size: 16px;
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
