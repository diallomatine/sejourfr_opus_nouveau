"use client";

import { ModuleLanding } from "@/features/modules/ModuleLanding";

export default function CiviquePage() {
  return (
    <ModuleLanding
      moduleType="CIVIQUE"
      basePath="/civique"
      title="Examen civique"
      subtitle="Préparez l'examen civique exigé pour le titre de séjour pluriannuel : valeurs républicaines, institutions, histoire et citoyenneté."
      context="Pour le titre de séjour pluriannuel"
      accent="blue"
    />
  );
}
