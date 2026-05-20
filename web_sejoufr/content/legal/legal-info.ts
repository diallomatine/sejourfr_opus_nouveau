/**
 * Données entreprise centralisées pour les 3 pages légales.
 *
 * Toute valeur `null` est rendue par le composant <Placeholder /> en rouge ambré
 * pour qu'on voit immédiatement ce qui manque avant la mise en prod.
 *
 * À chaque modification ici, vérifier que les pages /mentions-legales, /cgu,
 * /confidentialite restent cohérentes (ex: changement d'adresse → impacte les 3).
 */

export type LegalForm = "EI" | "SAS" | "SARL" | "EURL" | "AUTRE";

export interface LegalEditor {
    legalForm: LegalForm;
    /** Nom commercial / nom du site. */
    companyName: string;
    /** Raison sociale officielle (pour EI : prénom + nom). */
    legalName: string | null;
    /** Capital social. `null` pour les EI. */
    capital: string | null;
    /** Adresse complète sur une ligne. */
    address: string | null;
    /** 14 chiffres. */
    siret: string | null;
    /** 9 chiffres. */
    siren: string | null;
    /** Mention RCS complète. `null` pour les EI non commerçants. */
    rcs: string | null;
    /** Numéro de TVA intracommunautaire. `null` si non assujetti (franchise en base). */
    vatNumber: string | null;
    email: string;
    phone: string | null;
    /** Nom du directeur de la publication (pour EI : généralement le même que `legalName`). */
    publicationDirector: string | null;
}

export interface LegalHost {
    name: string;
    address: string;
    phone: string | null;
    website: string;
}

export interface LegalDpo {
    designated: boolean;
    name: string;
    email: string;
}

export interface LegalSubscription {
    annualPriceTTC: string;
    annualPriceHT: string | null;
    vatRate: string;
    /**
     * Nombre de questions d'entraînement offertes gratuitement par module
     * (CIVIQUE et TCF sont gatés indépendamment).
     */
    trialQuestionsPerModule: number;
    /** Nombre d'examens blancs offerts gratuitement par module. */
    trialSimulations: number;
}

export interface LegalSubProcessor {
    name: string;
    purpose: string;
    country: string;
}

export interface LegalMediator {
    name: string | null;
    address: string | null;
    website: string | null;
}

export interface LegalInfo {
    editor: LegalEditor;
    host: LegalHost;
    dpo: LegalDpo;
    subscription: LegalSubscription;
    subProcessors: LegalSubProcessor[];
    mediator: LegalMediator;
    lastUpdated: string;
    effectiveDate: string;
}

export const LEGAL_INFO: LegalInfo = {
    editor: {
        legalForm: "EI",
        companyName: "SejourFR",
        legalName: "Abdoul Matine Diallo", // TODO : prénom + nom de l'entrepreneur individuel
        capital: null, // EI : pas de capital social
        address: "10 Rue des gélinières, 95400 Villiers-Le-Bel", // TODO : adresse complète (numéro, rue, code postal, ville)
        siret: "92794330800019", // TODO : 14 chiffres
        siren: "927943308", // TODO : 9 chiffres
        rcs: null, // EI non commerçant : null. Sinon : "RCS [Ville] [Numéro]"
        vatNumber: null, // TODO : "FR..." ou null si franchise en base de TVA
        // `editor.email` est l'adresse de contact officielle utilisée uniformément
        // sur les 3 pages légales (mentions, CGU, confidentialité). On retient
        // `contact@sejourfr.fr` pour TOUS les contacts publics (questions
        // générales, RGPD, rétractation, etc.) afin de n'avoir qu'une seule
        // adresse à publier — le routage interne (support produit vs RGPD) se
        // fait ensuite côté boîte mail.
        email: "support@sejourfr.fr",
        phone: "07 58 63 87 01", // TODO : numéro de téléphone (facultatif si email suffit)
        publicationDirector: "Abdoul Matine Diallo", // TODO : pour un EI, c'est généralement vous
    } satisfies LegalEditor,

    host: {
        name: "IONOS SARL",
        address: "7 place de la Gare, BP 70109, 57200 Sarreguemines Cedex, France",
        phone: "0 970 808 911",
        website: "https://www.ionos.fr",
    } satisfies LegalHost,

    dpo: {
        designated: false,
        name: "",
        // On aligne sur `editor.email` (adresse de contact unique).
        email: "support@sejourfr.fr",
    } satisfies LegalDpo,

    subscription: {
        annualPriceTTC: "29,90 €",
        annualPriceHT: null, // À calculer si l'éditeur est assujetti à la TVA
        vatRate: "20 %",
        // Règle métier 2026-05 : 20 questions + 1 examen blanc gratuits PAR MODULE
        // (civique ET TCF sont gatés indépendamment). Voir `canAccessModule`.
        trialQuestionsPerModule: 20,
        trialSimulations: 1,
    } satisfies LegalSubscription,

    subProcessors: [
        {
            name: "IONOS SARL",
            purpose: "Hébergement de l'infrastructure et de la base de données",
            country: "France (UE)",
        },
        {
            name: "Stripe Payments Europe Ltd.",
            purpose: "Traitement des paiements par carte bancaire",
            country: "Irlande (UE)",
        },
        // TODO [À VÉRIFIER avec l'éditeur] : ajouter le fournisseur d'envoi
        // d'emails transactionnels (Brevo / SendGrid / Resend / IONOS Mail…)
        // une fois la stack mail réellement branchée en prod.
    ] satisfies LegalSubProcessor[],

    mediator: {
        name: null, // TODO : ex. "SAS Médiation Solution"
        address: null,
        website: null, // ex. "https://sasmediationsolution-conso.fr"
    } satisfies LegalMediator,

    /** Date de dernière mise à jour des documents légaux (ISO YYYY-MM-DD). */
    lastUpdated: "2026-05-17",
    effectiveDate: "2026-05-17",
};

/* --------------------- Helpers ----------------------------------------- */

export function formatLegalDate(iso: string): string {
    return new Date(iso).toLocaleDateString("fr-FR", {
        day: "numeric",
        month: "long",
        year: "numeric",
    });
}

/**
 * Légende textuelle "Personne physique" / "Société" pour le paragraphe éditeur.
 */
export function isCompany(form: LegalForm): boolean {
    return form !== "EI";
}
