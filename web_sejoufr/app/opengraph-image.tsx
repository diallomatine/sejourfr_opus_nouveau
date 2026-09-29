import { ImageResponse } from "next/og";

// Image Open Graph générée à la volée en 1200×630 (Next 16, next/og). Évite de
// committer un binaire et reste synchro avec l'identité de marque : cocarde,
// wordmark « SejourFR » (Sejour bleu / FR rouge), bande drapeau.
export const runtime = "nodejs";
export const alt = "SejourFR — Préparation TCF IRN et examen civique";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

const BLUE = "#1E3A8C";
const RED = "#E1372F";
const PAPER = "#FAFAF7";
const INK = "#0F1839";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: PAPER,
          padding: "72px 80px",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 28 }}>
          {/* Cocarde : 3 cercles concentriques bleu / blanc / rouge */}
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
                width: 60,
                height: 60,
                borderRadius: 9999,
                background: "#fff",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <div
                style={{
                  width: 26,
                  height: 26,
                  borderRadius: 9999,
                  background: RED,
                }}
              />
            </div>
          </div>
          <div style={{ display: "flex", fontSize: 64, fontWeight: 800 }}>
            <span style={{ color: BLUE }}>Sejour</span>
            <span style={{ color: RED }}>FR</span>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <div
            style={{
              fontSize: 68,
              fontWeight: 800,
              color: INK,
              lineHeight: 1.1,
              letterSpacing: -1,
            }}
          >
            Préparation TCF IRN & Examen civique
          </div>
          <div style={{ fontSize: 34, color: "#6B7299" }}>
            Examens blancs · correction IA de l&apos;oral et de l&apos;écrit ·
            estimation de niveau A2, B1, B2
          </div>
        </div>

        {/* Bande drapeau français */}
        <div style={{ display: "flex", height: 14, borderRadius: 9999, overflow: "hidden" }}>
          <div style={{ flex: 1, background: BLUE }} />
          <div style={{ flex: 1, background: "#fff" }} />
          <div style={{ flex: 1, background: RED }} />
        </div>
      </div>
    ),
    size,
  );
}
