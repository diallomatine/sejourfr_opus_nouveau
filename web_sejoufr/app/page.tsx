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
        <ProblemSection />
        <ExamsSection />
        <HowItWorksSection />
        <MobileAppSection />
        <PricingSection />
        <TestimonialsSection />
        <FaqSection />
        <FinalCtaSection />
      </main>
      <Footer />
    </>
  );
}
