import {
  Competences,
  Examens,
  FinalCta,
  Hero,
  Niveau,
  Simulation,
} from "./_components/landing/Landing";
import { MobileAppSection } from "./_components/MobileAppPromo";

export default function HomePage() {
  return (
    <main>
      <Hero />
      <Examens />
      <Competences />
      <Simulation />
      <Niveau />
      <MobileAppSection />
      <FinalCta />
    </main>
  );
}
