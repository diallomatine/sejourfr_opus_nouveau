import {HeroSection} from "./_components/HeroSection";
import {
  ExamsSection,
  FinalCtaSection,
  HowItWorksSection,
  PricingSection,
  ProblemSection,
  TestimonialsSection,
  TrustStrip,
} from "./_components/LandingSections";
import {MobileAppSection} from "./_components/MobileAppPromo";

export default function HomePage() {
    return (
        <>
            <main>
                <HeroSection/>
                <TrustStrip/>
                <ExamsSection/>
                <ProblemSection/>
                <HowItWorksSection/>
                <PricingSection/>
                <TestimonialsSection/>
                <MobileAppSection/>
                <FinalCtaSection/>
            </main>
        </>
    );
}
