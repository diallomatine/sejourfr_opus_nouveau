import type { Metadata, Viewport } from "next";
import { Fraunces, Plus_Jakarta_Sans, JetBrains_Mono } from "next/font/google";
import { AuthProvider } from "@/lib/auth-context";
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
  title: "SejourFR — Préparez l'examen civique et le TCF en confiance",
  description:
    "Plateforme d'entraînement aux examens civique (CSP, CR, naturalisation) et TCF IRN. QCM, examens blancs en conditions réelles, suivi de progression sur l'app mobile.",
  icons: {
    icon: "/favicon.svg",
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
