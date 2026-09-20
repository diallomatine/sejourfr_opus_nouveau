/**
 * Ce que l'offre sait de l'échéance du candidat — règles **pures**, déclarées
 * une fois pour tout le web.
 *
 * 🛑 **L'en-tête personnalisé a été SUPPRIMÉ** (demande du propriétaire,
 * 2026-09-20). « Votre plan B2 est prêt », le pitch, les trois priorités
 * réelles, les bénéfices du plan et `PaywallOrigin` — qui ne servait qu'à
 * décider de leur affichage — sont partis **avec leur seul lecteur** : la
 * promesse est désormais dite **une fois**, sur l'écran de transition
 * `/plan/debloquer`, et la répéter sur la page suivante la disait deux fois de
 * suite. Ne pas les réintroduire ici.
 *
 * Ce qui reste ne parle **pas du plan** : la date d'examen déclarée et le pass
 * le plus court qui la couvre. Ce sont les deux faits qui aident à **choisir
 * une durée**, et c'est bien le rôle d'une page d'offre.
 *
 * 🛑 **Rien n'est dérivé ici.** L'objectif arrive servi ; ce fichier ne fait que
 * le mettre en mots.
 *
 * Miroir de `mobile_sejourfr/lib/core/widgets/paywall_context.dart`.
 */
import type {
    AuthenticatedUser,
    LearningPlanDto,
    PlanPublicResponse,
    TargetLevel,
} from "./types";
import {passDurationLabel} from "./passes";

export interface PaywallContext {
    /** Palier visé. `null` = démarche non déclarée. */
    objectiveLevel: TargetLevel | null;
    /** Jour de l'examen déclaré. `null` = pas de date, réponse pleine. */
    examDate: string | null;
}

/**
 * Assemble le contexte à partir de ce qui est **déjà chargé**.
 *
 * `plan` vient du cache : l'offre ne déclenche aucun appel réseau de plus, et
 * son absence est un cas normal (l'écran qui l'ouvre n'a pas forcément lu le
 * Plan).
 */
export function paywallContext(
    plan: LearningPlanDto | null | undefined,
    user: Pick<AuthenticatedUser, "examDate"> | null | undefined,
): PaywallContext {
    return {
        objectiveLevel: plan?.cycle?.objectiveLevel ?? null,
        examDate: user?.examDate ?? null,
    };
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
