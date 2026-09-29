import type { Metadata } from "next";
import { ContactHero } from "@/components/contact/ContactHero";
import { ContactForm } from "@/components/contact/ContactForm";
import { ContactInfoSidebar } from "@/components/contact/ContactInfoSidebar";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Contact — SejourFR",
  description:
    "Une question sur l'examen civique, votre titre de séjour ou votre naturalisation ? Notre équipe répond sous 24 h ouvrées.",
  alternates: { canonical: "/contact" },
  openGraph: {
    title: "Contact — SejourFR",
    description:
      "Notre équipe répond à toutes vos demandes sous 24 h ouvrées.",
    type: "website",
    url: `${SITE.url}/contact`,
  },
};

export default function ContactPage() {
  return (
    <>
      <main className="container-x contact-page">
        <div className="contact-grid">
          <div className="contact-main">
            <ContactHero />
            <ContactForm />
          </div>
          <ContactInfoSidebar />
        </div>

        <style>{`
          .contact-page {
            padding-top: 36px;
            padding-bottom: 56px;
            max-width: 1140px;
          }
          .contact-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 32px;
          }
          .contact-main {
            min-width: 0;
          }
          @media (min-width: 1024px) {
            .contact-page { padding-top: 48px; padding-bottom: 72px; }
            .contact-grid {
              grid-template-columns: 1fr 340px;
              gap: 48px;
            }
          }
        `}</style>
      </main>
    </>
  );
}
