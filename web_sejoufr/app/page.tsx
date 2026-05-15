import { TopNav } from "./_components/TopNav";
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

export default function HomePage() {
  return (
    <>
      <TopNav />
      <main>
        <HeroSection />
        <TrustStrip />
        <ProblemSection />
        <ExamsSection />
        <HowItWorksSection />
        <PricingSection />
        <TestimonialsSection />
        <FaqSection />
        <FinalCtaSection />
      </main>
      <Footer />
    </>
  );
}
