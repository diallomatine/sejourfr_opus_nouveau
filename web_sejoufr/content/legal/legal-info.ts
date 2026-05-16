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
  trialQuestionsPerCategory: number;
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
    companyName: "SéjourFR",
    legalName: null, // TODO : prénom + nom de l'entrepreneur individuel
    capital: null, // EI : pas de capital social
    address: null, // TODO : adresse complète (numéro, rue, code postal, ville)
    siret: null, // TODO : 14 chiffres
    siren: null, // TODO : 9 chiffres
    rcs: null, // EI non commerçant : null. Sinon : "RCS [Ville] [Numéro]"
    vatNumber: null, // TODO : "FR..." ou null si franchise en base de TVA
    email: "contact@sejourfr.fr",
    phone: null, // TODO : numéro de téléphone (facultatif si email suffit)
    publicationDirector: null, // TODO : pour un EI, c'est généralement vous
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
    email: "support@sejourfr.fr",
  } satisfies LegalDpo,

  subscription: {
    annualPriceTTC: "29,90 €",
    annualPriceHT: null, // À calculer si l'éditeur est assujetti à la TVA
    vatRate: "20 %",
    trialQuestionsPerCategory: 5,
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
    // TODO : ajouter le fournisseur d'envoi d'emails (Brevo / SendGrid / Resend / IONOS Mail) selon ce qui est branché en prod.
  ] satisfies LegalSubProcessor[],

  mediator: {
    name: null, // TODO : ex. "SAS Médiation Solution"
    address: null,
    website: null, // ex. "https://sasmediationsolution-conso.fr"
  } satisfies LegalMediator,

  /** Date de dernière mise à jour des documents légaux (ISO YYYY-MM-DD). */
  lastUpdated: "2026-05-09",
  effectiveDate: "2026-05-09",
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
