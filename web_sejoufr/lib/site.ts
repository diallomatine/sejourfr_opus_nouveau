const siteUrl = process.env.NEXT_PUBLIC_SITE_URL;
if (!siteUrl) {
    // Crash explicite au build / boot si la var manque. Mieux qu'un fallback
    // localhost silencieux qui finit dans les balises canoniques en prod.
    throw new Error(
        "NEXT_PUBLIC_SITE_URL est requis. Définir la variable dans .env / .env.production.",
    );
}

export const SITE = {
    name: "SejourFR",
    description:
        "Préparez votre examen civique pour le titre de séjour et votre naturalisation française avec des QCM, examens blancs et un suivi de progression.",
    url: siteUrl,
    premiumPriceLabel: "14,90 € / 3 mois",
    freemiumQuestions: 40,
    /** Questions visibles par catégorie pour un user gratuit (doit matcher backend). */
    freeQuestionsPerCategory: 5,
};
