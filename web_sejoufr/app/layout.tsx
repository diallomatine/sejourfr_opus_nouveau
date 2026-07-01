import type { Metadata, Viewport } from "next";
import { Fraunces, Plus_Jakarta_Sans, JetBrains_Mono } from "next/font/google";
import { AuthProvider } from "@/lib/auth-context";
import { SITE } from "@/lib/site";
import { MobileAppBanner } from "./_components/MobileAppPromo";
import { SiteHeader } from "./_components/SiteHeader";
import { Footer } from "./_components/Footer";
import "./globals.css";

const jakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-jakarta",
  weight: ["400", "500", "600", "700", "800"],
  display: "swap",
});

const fraunces = Fraunces({
  subsets: ["latin"],
  variable: "--font-fraunces",
  weight: ["400", "500", "600", "700"],
  style: ["normal", "italic"],
  display: "swap",
});

const jetbrains = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-jetbrains",
  weight: ["400", "500"],
  display: "swap",
});

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
};

export const metadata: Metadata = {
  // Base absolue : résout les URLs relatives (og-image, canoniques) et les
  // balises sociales pour toutes les pages qui héritent de ce layout.
  metadataBase: new URL(SITE.url),
  applicationName: SITE.name,
  title: "SejourFR — Préparation TCF IRN & Examen civique",
  description:
    "Plateforme d'entraînement aux examens civique (CSP, CR, naturalisation) et TCF IRN. QCM, examens blancs en conditions réelles, suivi de progression sur l'app mobile.",
  // Défauts sociaux de marque, hérités par les sous-pages (elles surchargent
  // seulement title/description/url/canonical). L'image OG vient du fichier
  // app/opengraph-image.tsx (générée en 1200×630).
  openGraph: {
    siteName: SITE.name,
    type: "website",
    locale: "fr_FR",
    url: SITE.url,
    title: "SejourFR — Préparation TCF IRN & Examen civique",
    description:
      "Entraînez-vous au TCF IRN et à l'examen civique : examens blancs, correction IA de l'oral et de l'écrit, estimation de niveau A2, B1 ou B2.",
  },
  twitter: {
    card: "summary_large_image",
    title: "SejourFR — Préparation TCF IRN & Examen civique",
    description:
      "Examens blancs, correction IA et estimation de niveau pour préparer le TCF IRN et l'examen civique.",
  },
  icons: {
    icon: "/logo_sejourFR.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="fr"
      className={`${jakarta.variable} ${fraunces.variable} ${jetbrains.variable}`}
      suppressHydrationWarning
      data-scroll-behavior="smooth"
    >
      <body suppressHydrationWarning>
        <AuthProvider>
          <MobileAppBanner />
          <SiteHeader />
          {children}
          <Footer />
        </AuthProvider>
      </body>
    </html>
  );
}
