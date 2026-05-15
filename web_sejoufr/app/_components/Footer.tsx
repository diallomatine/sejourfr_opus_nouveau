import Link from "next/link";
import { Brand } from "./Brand";

const footerStyles: React.CSSProperties = {
  background: "var(--color-ink)",
  color: "rgba(255,255,255,0.7)",
  padding: "64px 0 28px",
  fontSize: 14,
};

const gridStyles: React.CSSProperties = {
  display: "grid",
  gridTemplateColumns: "1.4fr 1fr 1fr 1fr",
  gap: 40,
  marginBottom: 48,
};

const bottomStyles: React.CSSProperties = {
  borderTop: "1px solid rgba(255,255,255,0.1)",
  paddingTop: 24,
  display: "flex",
  justifyContent: "space-between",
  alignItems: "center",
  gap: 16,
  fontSize: 12.5,
  color: "rgba(255,255,255,0.4)",
  fontFamily: "var(--font-mono)",
  letterSpacing: "0.05em",
};

const colHead: React.CSSProperties = {
  fontFamily: "var(--font-mono)",
  fontSize: 11,
  letterSpacing: "0.15em",
  textTransform: "uppercase",
  color: "rgba(255,255,255,0.45)",
  margin: "0 0 16px",
  fontWeight: 500,
};

const linkList: React.CSSProperties = {
  listStyle: "none",
  padding: 0,
  margin: 0,
  display: "flex",
  flexDirection: "column",
  gap: 10,
};

export function Footer() {
  return (
    <footer style={footerStyles}>
      <div className="container-x">
        <div style={gridStyles} className="footer-grid-mobile">
          <div>
            <div style={{ marginBottom: 14, display: "flex" }}>
              <Brand />
            </div>
            <p
              style={{
                color: "rgba(255,255,255,0.5)",
                fontSize: 13.5,
                lineHeight: 1.5,
                maxWidth: 280,
                margin: 0,
              }}
            >
              La plateforme d'entraînement aux examens civique et TCF pour les
              démarches de titre de séjour, carte de résident et naturalisation.
            </p>
          </div>

          <div>
            <h5 style={colHead}>Produit</h5>
            <ul style={linkList}>
              <li>
                <Link href="/#examens">Examen civique</Link>
              </li>
              <li>
                <Link href="/#examens">TCF IRN</Link>
              </li>
              <li>
                <Link href="/#tarifs">Tarifs</Link>
              </li>
              <li>
                <Link href="/examen-blanc">Examen blanc</Link>
              </li>
            </ul>
          </div>

          <div>
            <h5 style={colHead}>Entreprise</h5>
            <ul style={linkList}>
              <li>
                <Link href="#">À propos</Link>
              </li>
              <li>
                <Link href="/#temoignages">Témoignages</Link>
              </li>
              <li>
                <Link href="#">Blog</Link>
              </li>
              <li>
                <Link href="#">Contact</Link>
              </li>
            </ul>
          </div>

          <div>
            <h5 style={colHead}>Légal</h5>
            <ul style={linkList}>
              <li>
                <Link href="#">Mentions légales</Link>
              </li>
              <li>
                <Link href="#">CGU · CGV</Link>
              </li>
              <li>
                <Link href="#">Confidentialité</Link>
              </li>
              <li>
                <Link href="#">Cookies</Link>
              </li>
            </ul>
          </div>
        </div>

        <div style={bottomStyles}>
          <span>© 2026 SejourFR — Tous droits réservés</span>
          <span>Conçu en France · Hébergé en UE</span>
        </div>
      </div>

      <style>{`
        @media (max-width: 960px) {
          .footer-grid-mobile { grid-template-columns: 1fr 1fr !important; gap: 32px !important; }
        }
        @media (max-width: 560px) {
          .footer-grid-mobile { grid-template-columns: 1fr !important; }
        }
      `}</style>
    </footer>
  );
}
