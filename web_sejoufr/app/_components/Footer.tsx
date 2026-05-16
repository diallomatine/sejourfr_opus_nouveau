import Link from "next/link";
import { Brand } from "./Brand";

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="container-x">
        <div className="footer-grid">
          <div className="footer-about">
            <Brand />
            <p>
              L&apos;app de référence pour préparer l&apos;examen civique et le
              TCF en vue de votre titre de séjour ou de votre naturalisation.
            </p>
          </div>

          <div className="footer-col">
            <h5>EXAMENS</h5>
            <ul>
              <li><Link href="/examens-blancs">Examen civique</Link></li>
              <li><Link href="/examens-blancs">TCF IRN — A2</Link></li>
              <li><Link href="/examens-blancs">TCF IRN — B1</Link></li>
              <li><Link href="/examens-blancs">TCF IRN — B2</Link></li>
            </ul>
          </div>

          <div className="footer-col">
            <h5>RESSOURCES</h5>
            <ul>
              <li><Link href="/#fonctionnalites">Méthode</Link></li>
              <li><Link href="/#temoignages">Témoignages</Link></li>
              <li><Link href="/#tarifs">Tarifs</Link></li>
              <li><Link href="/#faq">FAQ</Link></li>
            </ul>
          </div>

          <div className="footer-col">
            <h5>LÉGAL</h5>
            <ul>
              <li><Link href="#">Conditions d&apos;utilisation</Link></li>
              <li><Link href="#">Confidentialité</Link></li>
              <li><Link href="#">Mentions légales</Link></li>
              <li><Link href="#">Cookies</Link></li>
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <span>© 2026 SejourFR · Indépendant — non affilié à l&apos;administration française.</span>
          <span className="footer-tag">v1.0 · MADE IN FR</span>
        </div>
      </div>

      <style>{`
        .site-footer {
          border-top: 1px solid var(--color-line);
          padding: 56px 0 28px;
          background: #fff;
          color: var(--color-ink-2);
        }
        .footer-grid {
          display: grid;
          grid-template-columns: 1.6fr 1fr 1fr 1fr;
          gap: 40px;
          margin-bottom: 40px;
        }
        .footer-about p {
          font-size: 13.5px;
          color: var(--color-muted);
          margin: 14px 0 0;
          max-width: 300px;
          line-height: 1.6;
        }
        .footer-col h5 {
          font-family: var(--font-mono);
          font-size: 11px;
          color: var(--color-muted);
          letter-spacing: 0.15em;
          margin: 0 0 16px;
          font-weight: 600;
        }
        .footer-col ul {
          list-style: none;
          padding: 0; margin: 0;
        }
        .footer-col li {
          padding: 6px 0;
          font-size: 14px;
        }
        .footer-col a {
          color: var(--color-ink-2);
          text-decoration: none;
          transition: color 0.15s;
        }
        .footer-col a:hover { color: var(--color-blue); }
        .footer-bottom {
          border-top: 1px solid var(--color-line);
          padding-top: 24px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 16px;
          font-size: 13px;
          color: var(--color-muted);
        }
        .footer-tag {
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.1em;
        }
        @media (max-width: 900px) {
          .footer-grid { grid-template-columns: 1fr 1fr; gap: 32px; }
        }
        @media (max-width: 560px) {
          .footer-grid { grid-template-columns: 1fr; }
          .footer-bottom { flex-direction: column; align-items: flex-start; gap: 8px; }
        }
      `}</style>
    </footer>
  );
}
