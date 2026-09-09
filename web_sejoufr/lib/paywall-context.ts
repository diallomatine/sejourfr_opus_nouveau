/**
 * La contextualisation du paywall (`10_` §5) — règles **pures**, déclarées une
 * fois pour tout le web.
 *
 * > « Personnalisation obligatoire : niveau actuel, niveau cible, les 3
 * > priorités réelles, et la date d'examen si renseignée. **Un paywall sans ces
 * > éléments est un bug.** »
 *
 * 🛑 **Mais un paywall qui MENT est pire qu'un paywall générique.** Chaque
 * élément est donc facultatif et se calcule sur ce que le serveur a réellement
 * servi : pas de Plan en cache ⇒ pas de niveau ; aucune priorité ⇒ aucune liste ;
 * pas de date d'examen ⇒ pas de compte à rebours. On dégrade vers le message
 * générique, jamais vers une valeur inventée.
 *
 * 🛑 **Rien n'est dérivé ici.** Les niveaux, l'objectif et l'ordre des priorités
 * arrivent servis ; ce fichier ne fait que les mettre en mots.
 *
 * Miroir de `mobile_sejourfr/lib/core/widgets/paywall_context.dart`.
 */
import type {
    AuthenticatedUser,
    LearningPlanDto,
    LearningPlanPriorityDto,
    NiveauCecrl,
    PlanPublicResponse,
    TargetLevel,
} from "./types";
import {passDurationLabel} from "./passes";

/** Plafond d'affichage des priorités sur le paywall (`10_` §5). */
export const PAYWALL_MAX_PRIORITIES = 3;

export interface PaywallContext {
    /** Palier mesuré aujourd'hui. `null` = pas encore mesuré. */
    currentLevel: NiveauCecrl | null;
    /** Palier visé. `null` = démarche non déclarée. */
    objectiveLevel: TargetLevel | null;
    /** Les priorités réelles, dans l'ordre servi. Jamais retriées. */
    priorities: LearningPlanPriorityDto[];
    /** Jour de l'examen déclaré. `null` = pas de date, réponse pleine. */
    examDate: string | null;
}

/**
 * Assemble le contexte à partir de ce qui est **déjà chargé**.
 *
 * `plan` vient du cache : le paywall ne déclenche aucun appel réseau, et son
 * absence est un cas normal (l'écran qui l'ouvre n'a pas forcément lu le Plan).
 */
export function paywallContext(
    plan: LearningPlanDto | null | undefined,
    user: Pick<AuthenticatedUser, "examDate"> | null | undefined,
): PaywallContext {
    return {
        currentLevel: plan?.cycle?.startingLevel ?? null,
        objectiveLevel: plan?.cycle?.objectiveLevel ?? null,
        // 🛑 L'ordre vient du serveur : la priorité courante d'abord, puis les
        // suivantes telles qu'il les a classées. Le front ne retrie jamais.
        priorities: [
            ...(plan?.currentPriority ? [plan.currentPriority] : []),
            ...(plan?.nextPriorities ?? []),
        ].slice(0, PAYWALL_MAX_PRIORITIES),
        examDate: user?.examDate ?? null,
    };
}

/** Le paywall a-t-il de quoi être personnalisé ? Sinon, message générique. */
export function isContextualised(ctx: PaywallContext): boolean {
    return (
        ctx.currentLevel !== null ||
        ctx.objectiveLevel !== null ||
        ctx.priorities.length > 0
    );
}

/**
 * « Vous êtes actuellement estimé B1. SejourFR a identifié les priorités à
 * travailler pour vous rapprocher de B2. »
 *
 * Dégrade proprement : sans niveau mesuré on ne l'annonce pas, sans objectif on
 * ne promet pas de palier.
 */
export function paywallPitch(ctx: PaywallContext): string | null {
    const {currentLevel, objectiveLevel} = ctx;
    if (currentLevel && objectiveLevel) {
        return `Vous êtes actuellement estimé ${currentLevel}. SejourFR a identifié les priorités à travailler pour vous rapprocher de ${objectiveLevel}.`;
    }
    if (objectiveLevel) {
        return `SejourFR a identifié les priorités à travailler pour vous rapprocher de ${objectiveLevel}.`;
    }
    if (currentLevel) {
        return `Vous êtes actuellement estimé ${currentLevel}. SejourFR a identifié vos priorités.`;
    }
    return null;
}

/** « Votre plan B2 est prêt » — ou sans palier quand la démarche est inconnue. */
export function paywallTitle(ctx: PaywallContext): string {
    return ctx.objectiveLevel
        ? `Votre plan ${ctx.objectiveLevel} est prêt`
        : "Votre plan est prêt";
}

/** Jours restants avant l'examen. Négatif ⇒ `null` : la date est passée. */
export function joursAvantExamen(
    examDate: string | null,
    now: Date = new Date(),
): number | null {
    if (!examDate) return null;
    const jour = new Date(`${examDate}T00:00:00`);
    if (Number.isNaN(jour.getTime())) return null;
    const jours = Math.ceil(
        (jour.getTime() - now.getTime()) / (24 * 60 * 60 * 1000),
    );
    return jours >= 0 ? jours : null;
}

/** « Objectif B2 avant le 18 octobre — il vous reste 39 jours. » */
export function echeanceLine(
    ctx: PaywallContext,
    now: Date = new Date(),
): string | null {
    const jours = joursAvantExamen(ctx.examDate, now);
    if (jours === null) return null;
    const date = formatJour(ctx.examDate!);
    const objectif = ctx.objectiveLevel ? `Objectif ${ctx.objectiveLevel} avant` : "Examen";
    const reste =
        jours === 0
            ? "c'est aujourd'hui."
            : `il vous reste ${jours} jour${jours > 1 ? "s" : ""}.`;
    return `${objectif} le ${date} — ${reste}`;
}

/**
 * Le levier propre aux pass (`50_` §3.4) : **aligner la durée sur l'échéance**.
 *
 * « Votre examen est le 18 octobre. Le pass 2 mois couvre toute votre
 * préparation. »
 *
 * 🛑 On ne recommande **que** ce que le catalogue propose réellement, et
 * seulement un pass qui **couvre** l'échéance : promettre une couverture qu'un
 * pass ne tient pas serait pire que se taire. Aucun pass assez long ⇒ `null`.
 */
export function passRecommande(
    ctx: PaywallContext,
    plans: PlanPublicResponse[] | null | undefined,
    now: Date = new Date(),
): {plan: PlanPublicResponse; phrase: string} | null {
    const jours = joursAvantExamen(ctx.examDate, now);
    if (jours === null || !plans?.length) return null;

    // Le plus COURT des pass qui couvrent l'échéance : on ne pousse pas au plus
    // cher, on répond au besoin.
    const couvrants = plans
        .filter((p) => p.purchaseType === "ONE_TIME" && p.durationDays >= jours)
        .sort((a, b) => a.durationDays - b.durationDays);

    const choisi = couvrants[0];
    if (!choisi) return null;

    return {
        plan: choisi,
        phrase: `Votre examen est le ${formatJour(ctx.examDate!)}. Le pass ${passDurationLabel(
            choisi.durationDays,
        )} couvre toute votre préparation.`,
    };
}

/** « 18 octobre ». Le jour tel qu'il a été déclaré, sans fuseau appliqué. */
function formatJour(iso: string): string {
    const [, mois, jour] = iso.split("-");
    const nom = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre",
    ][Number(mois) - 1];
    return nom ? `${Number(jour)} ${nom}` : iso;
}
