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

export const STORE_LINKS = {
    ios: "https://apps.apple.com/fr/app/sejourfr/id6771509569",
    android: "https://play.google.com/store/apps/details?id=com.sejourfr.app&hl=fr",
};

/**
 * Comptes réseaux de SejourFR. Une entrée à `url: null` n'est pas rendue —
 * on ne publie jamais un lien vers un compte qui n'existe pas. Renseigner
 * l'URL ici suffit à faire apparaître la ligne sur `/reussir`.
 */
export const SOCIAL_ACCOUNTS: {
    key: "tiktok" | "instagram" | "facebook" | "youtube";
    label: string;
    handle: string;
    url: string | null;
}[] = [
    {
        key: "tiktok",
        label: "TikTok",
        handle: "@sejourfrofficiel",
        url: "https://www.tiktok.com/@sejourfrofficiel",
    },
    {key: "instagram", label: "Instagram", handle: "@sejourfr", url: null},
];
