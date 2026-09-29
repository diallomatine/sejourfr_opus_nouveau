import type { Metadata } from "next";
import { FAQContent } from "@/components/faq/FAQContent";
import {
  FAQ_DATA,
  answerToPlainText,
  getAllFaqItems,
} from "@/content/faq/faq-data";
import { SITE } from "@/lib/site";
import { safeJsonLd } from "@/lib/security";

export const metadata: Metadata = {
  title: "FAQ — Examen civique, naturalisation et titre de séjour | SejourFR",
  description:
    "Toutes les réponses à vos questions sur l'examen civique, l'entretien de naturalisation, les coûts, les délais et la procédure complète en 2026.",
  alternates: { canonical: "/faq" },
  openGraph: {
    title: "FAQ SejourFR — Examen civique et naturalisation",
    description:
      "38 questions/réponses sur l'examen civique 2026, l'entretien de naturalisation, les démarches et les coûts.",
    type: "website",
    url: `${SITE.url}/faq`,
  },
  twitter: {
    card: "summary_large_image",
    title: "FAQ SejourFR — Examen civique et naturalisation",
    description:
      "38 questions/réponses sourcées sur les démarches d'examen civique, naturalisation et titre de séjour.",
  },
};

export default function FAQPage() {
  const items = getAllFaqItems();

  // JSON-LD FAQPage : Google s'en sert pour le rich snippet (HUGE pour le CTR).
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    inLanguage: "fr-FR",
    mainEntity: items.map((it) => ({
      "@type": "Question",
      name: it.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: answerToPlainText(it.answer),
      },
    })),
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: safeJsonLd(jsonLd) }}
      />
      <main>
        <FAQContent />
      </main>
      {/* On pré-compte aussi pour la Search Console : le total est lisible côté HTML */}
      <meta name="x-faq-count" content={String(items.length)} />
      <meta name="x-faq-categories" content={String(FAQ_DATA.length)} />
    </>
  );
}
