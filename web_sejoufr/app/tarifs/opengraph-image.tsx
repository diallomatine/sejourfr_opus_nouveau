import { ImageResponse } from "next/og";

// Image produit réelle et unique, rendue côté serveur. Sert à la fois de
// `image` du Product JSON-LD (/tarifs) et d'og:image de la page (Next câble
// automatiquement ce fichier sur la metadata de /tarifs). Aux couleurs du
// design system (Bleu France / Rouge France).
export const alt = "SejourFR — Accès Intégral : examen civique et TCF IRN";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const BLUE = "#1E3A8C";
const RED = "#E1372F";
const INK = "#0F1839";
const MUTED = "#6B7299";
const PAPER = "#FAFAF7";
const LINE = "#E4E7F2";

export default function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "72px 80px",
          background: PAPER,
        }}
      >
        {/* Cocarde + wordmark */}
        <div style={{ display: "flex", alignItems: "center", gap: 24 }}>
          <div
            style={{
              width: 96,
              height: 96,
              borderRadius: 9999,
              background: BLUE,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <div
              style={{
                width: 62,
                height: 62,
                borderRadius: 9999,
                background: "#FFFFFF",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <div
                style={{
                  width: 30,
                  height: 30,
                  borderRadius: 9999,
                  background: RED,
                }}
              />
            </div>
          </div>
          <div style={{ display: "flex", fontSize: 48, fontWeight: 800 }}>
            <span style={{ color: BLUE }}>Sejour</span>
            <span style={{ color: RED }}>FR</span>
          </div>
        </div>

        {/* Titre */}
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div
            style={{
              display: "flex",
              fontSize: 30,
              letterSpacing: 4,
              textTransform: "uppercase",
              color: MUTED,
              fontWeight: 700,
            }}
          >
            Accès Intégral
          </div>
          <div
            style={{
              display: "flex",
              fontSize: 76,
              lineHeight: 1.05,
              color: INK,
              fontWeight: 800,
            }}
          >
            Examen civique
          </div>
          <div
            style={{
              display: "flex",
              fontSize: 76,
              lineHeight: 1.05,
              fontWeight: 800,
            }}
          >
            <span style={{ color: INK }}>&amp;&nbsp;</span>
            <span style={{ color: BLUE }}>TCF IRN</span>
          </div>
        </div>

        {/* Pied : promesse produit */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 16,
            borderTop: `2px solid ${LINE}`,
            paddingTop: 28,
            fontSize: 30,
            color: MUTED,
          }}
        >
          QCM type examen · Examens blancs · Corrections expliquées
        </div>
      </div>
    ),
    { ...size },
  );
}
