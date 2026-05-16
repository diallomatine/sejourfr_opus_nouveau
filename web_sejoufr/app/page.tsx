import { Footer } from "./_components/Footer";
import { HeroSection } from "./_components/HeroSection";
import {
  TrustStrip,
  ProblemSection,
  ExamsSection,
  HowItWorksSection,
  PricingSection,
  TestimonialsSection,
  FaqSection,
  FinalCtaSection,
} from "./_components/LandingSections";
import { MobileAppSection } from "./_components/MobileAppPromo";

export default function HomePage() {
  return (
    <>
      <main>
        <HeroSection />
        <TrustStrip />
        <ExamsSection />
        <ProblemSection />
        <HowItWorksSection />
        <PricingSection />
        <TestimonialsSection />
        <MobileAppSection />
        <FaqSection />
        <FinalCtaSection />
      </main>
      <Footer />
    </>
  );
}
