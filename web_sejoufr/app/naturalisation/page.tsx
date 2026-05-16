"use client";

import { ModuleLanding } from "@/features/modules/ModuleLanding";

export default function NaturalisationPage() {
  return (
    <ModuleLanding
      moduleType="NATURALISATION"
      basePath="/naturalisation"
      title="Naturalisation française"
      subtitle="Maîtrisez l'examen civique de naturalisation : valeurs et principes, institutions, droits et devoirs, histoire et culture, vie en société."
      context="Pour la demande de nationalité française"
      accent="red"
    />
  );
}
