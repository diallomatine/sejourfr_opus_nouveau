export const SITE = {
  name: "SejourFR",
  description:
    "Préparez votre examen civique pour le titre de séjour et votre naturalisation française avec des QCM, examens blancs et un suivi de progression.",
  url: process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000",
  premiumPriceLabel: "14,90 € / 3 mois",
  freemiumQuestions: 40,
  /** Questions visibles par catégorie pour un user gratuit (doit matcher backend). */
  freeQuestionsPerCategory: 5,
};
