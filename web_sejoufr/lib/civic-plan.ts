/**
 * Les **mots** du plan civique (L10, `20_` §6) — **purs**, déclarés une fois
 * pour tout le web.
 *
 * 🛑 **Le serveur n'expose que des faits** : un état de maîtrise, une boîte, une
 * échéance, un compte d'erreurs. Les phrases vivent ici, et sont des **miroirs
 * mot pour mot** de `mobile_sejourfr/lib/screens/plan/civic_plan_labels.dart` :
 * un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * ⚠️ `20_` §10 prévoyait un `civic_plan_item.reason_text` calculé serveur. Il
 * n'existe pas, et c'est délibéré : un texte composé côté serveur ne se relit
 * pas dans deux mises en page différentes, et se dupliquerait de toute façon dès
 * qu'un écran voudrait le dire autrement.
 *
 * 🛑 Ce fichier ne **dérive** aucun état pédagogique : `maitrise` et `aRevoir`
 * arrivent servis. Il ne fait que les mettre en mots.
 */
import {
    CIVIC_MAITRISE_LABEL,
    PLAN_RECENT_CHANGES_WINDOW_LABEL,
    type CivicPlanCibleDto,
    type CivicPlanCibleRefDto,
    type CivicPlanChangementsDto,
    type CivicPlanDto,
    type CivicPlanGrainDto,
    type CivicPlanTransitionDto,
} from "./types";

export const CIVIC_PLAN_TITLE = "Mon plan — Examen civique";
export const CIVIC_PLAN_LEAD = "Votre préparation personnalisée à l'Examen civique.";

/** Bloc 1 — l'objectif. */
export const CIVIC_PLAN_RESULT_TITLE = "Votre résultat au diagnostic";
export const CIVIC_PLAN_RESULT_SEUIL = "Seuil de réussite";

/** Bloc 2 — à faire maintenant. */
export const CIVIC_PLAN_NOW_TITLE = "À faire maintenant";
export const CIVIC_PLAN_NOW_CTA = "Commencer";
/** 🛑 Le verrou porte sur l'action, et le CTA le dit sans détour. */
export const CIVIC_PLAN_LOCKED_CTA = "Débloquer cette série";
export const CIVIC_PLAN_LOCKED_NOTE =
    "Les séries ciblées font partie de l'abonnement. Votre plan, lui, reste entier.";

/** Bloc 4 — les priorités. */
export const CIVIC_PLAN_PRIORITIES_TITLE = "Vos priorités";
export const CIVIC_PLAN_WORK_CTA = "Travailler";

/** Bloc 5 — révision d'entretien. 🛑 Jamais présentée comme une alerte. */
export const CIVIC_PLAN_REVIEW_TITLE = "À revoir bientôt";

/** Bloc 6 — ce qui est acquis. */
export const CIVIC_PLAN_SOLID_TITLE = "Déjà solide";

/** Aucune priorité : ce n'est pas un vide, c'est un état. */
export const CIVIC_PLAN_ALL_GOOD_TITLE = "Rien ne ressort comme prioritaire";
export const CIVIC_PLAN_ALL_GOOD_TEXT =
    "Enchaînez sur un examen blanc pour vous mettre en conditions réelles.";

/**
 * La note de grain — elle **dit** à quel niveau le plan travaille.
 *
 * 🛑 Le plan ne fait pas semblant d'être plus précis qu'il ne l'est. Tant que
 * les questions ne sont pas taguées, il travaille thème par thème (`20_` §3.3,
 * phase 1) et l'écrit. `null` une fois que tout a basculé : il n'y a plus rien
 * à expliquer.
 */
export function civicPlanGrainNote(grain: CivicPlanGrainDto): string | null {
    if (grain.courant === "NOTION") return null;
    return "Votre plan travaille thème par thème. Il deviendra plus précis, notion "
        + "par notion, à mesure que le référentiel civique se complète.";
}

/**
 * Ce que la liste ne montre pas. `null` quand elle montre tout — « + 0 autres »
 * est une phrase qui ne dit rien.
 */
export function civicPlanAutresLabel(plan: CivicPlanDto): string | null {
    const reste = plan.autresPriorites;
    if (reste <= 0) return null;
    const nom = plan.grain.courant === "NOTION" ? "notion" : "thème";
    return `+ ${reste} autre${reste > 1 ? "s" : ""} ${nom}${reste > 1 ? "s" : ""} `
        + "à consolider";
}

/**
 * L'ordre de grandeur d'une série. **Dérivé** de ce que le serveur sert :
 * raccourcir la série raccourcit la promesse, sans toucher un écran.
 *
 * 🛑 Ordre de grandeur, jamais un chrono — rien ne chronomètre le candidat
 * dessus.
 */
export function civicSerieLabel(cible: CivicPlanCibleDto): string {
    const minutes = Math.max(1, Math.round(cible.dureeEstimeeSec / 60));
    return `${cible.questionsSerie} questions ciblées · ~${minutes} min`;
}

/**
 * **Pourquoi cette cible est là.** Une phrase, tirée des faits servis.
 *
 * L'ordre des cas suit celui du score : ce qui vient d'échouer passe devant ce
 * qui échoue de façon répétée, qui passe devant l'oubli, qui passe devant ce
 * qui n'a jamais été mesuré.
 *
 * 🛑 **Jamais un reproche sur une absence de mesure.** Une cible que le
 * candidat n'a jamais touchée n'a rien raté : elle est « pas encore
 * travaillée », et ce n'est pas la même chose.
 */
export function civicPlanRaison(cible: CivicPlanCibleDto): string {
    if (cible.erreursRecentes > 0) {
        return `${cible.erreursRecentes} erreur${cible.erreursRecentes > 1 ? "s" : ""} `
            + "récente" + (cible.erreursRecentes > 1 ? "s" : "");
    }
    if (cible.aRevoir) return "À revoir pour ne pas l'oublier";
    if (cible.reponses === 0) return "Pas encore travaillé";
    if (cible.maitrise === "A_TRAVAILLER") return "Fragile à la dernière tentative";
    return "En cours d'acquisition";
}

/**
 * Le ton d'une cible. 🛑 `NON_EVALUEE` n'a **pas** de couleur d'alerte : c'est
 * une absence de mesure, pas un échec.
 */
export function civicCibleTone(
    cible: CivicPlanCibleDto,
): "hot" | "warn" | "ok" | "muted" {
    switch (cible.maitrise) {
        case "A_TRAVAILLER":
            return cible.erreursRecentes > 0 ? "hot" : "warn";
        case "EN_PROGRESSION":
            return "warn";
        case "MAITRISEE":
            return "ok";
        case "NON_EVALUEE":
            return "muted";
    }
}

/**
 * « à revoir dans 2 jours ». `null` quand l'échéance est déjà franchie (la
 * cible est alors dans les priorités, pas dans les révisions) ou absente.
 */
export function civicRevueLabel(cible: CivicPlanCibleDto, maintenant: Date): string | null {
    if (!cible.prochaineRevue) return null;
    const jours = Math.ceil(
        (new Date(cible.prochaineRevue).getTime() - maintenant.getTime()) / 86_400_000,
    );
    if (jours <= 0) return "à revoir maintenant";
    return `à revoir dans ${jours} jour${jours > 1 ? "s" : ""}`;
}

/** Où travailler une cible sans passer par la série (bibliothèque ouverte). */
export const CIVIC_PLAN_EXAM_HREF = "/examens-blancs?module=CIVIQUE";

/* ------------------------------------------------- Le parcours d'une cible */

/**
 * **Les 5 étapes d'une notion**, du premier contact à la maîtrise tenue.
 *
 * 🛑 Ce sont des **libellés gelés** : le serveur sert l'ÉTAT de chaque étape
 * (`Cible.parcours`), jamais sa phrase. Miroir mot pour mot de
 * `kCivicPathLabels` (`mobile_sejourfr/lib/screens/plan/civic_plan_labels.dart`).
 */
export const CIVIC_PATH_LABELS = [
    "Comprendre l'essentiel",
    "Première série ciblée",
    "Corriger vos confusions",
    "Série de validation",
    "Vérifier la maîtrise",
] as const;

export const CIVIC_PATH_TITLE = "Votre parcours";

/**
 * Le parcours d'une cible : l'état **servi** de chaque étape, habillé du
 * libellé gelé de son rang.
 *
 * 🛑 **Rien n'est dérivé ici.** Une première version calculait ces états depuis
 * `boite` — un front qui classe un nombre en état pédagogique, ce que le dépôt
 * interdit. Le serveur les sert (`CivicLeitner.parcours`), l'écran les affiche.
 *
 * Une étape servie sans libellé connu est **ignorée** : on n'invente pas un
 * nom d'étape parce que le serveur en a ajouté une.
 */
export function civicPath(
    cible: CivicPlanCibleDto,
): {label: string; state: "done" | "now" | "todo"}[] {
    return cible.parcours
        .slice(0, CIVIC_PATH_LABELS.length)
        .map((etat, i) => ({
            label: CIVIC_PATH_LABELS[i],
            state:
                etat === "FRANCHIE" ? ("done" as const)
                    : etat === "EN_COURS" ? ("now" as const)
                        : ("todo" as const),
        }));
}

/** « Étape 3 / 5 » — le rang de l'étape en cours, lu sur ce qui est servi. */
export function civicPathCounter(cible: CivicPlanCibleDto): string {
    const total = Math.min(cible.parcours.length, CIVIC_PATH_LABELS.length);
    const rang = cible.parcours.findIndex((e) => e === "EN_COURS") + 1;
    // Aucune étape en cours = tout est franchi : on annonce la fin du parcours.
    return `Étape ${rang > 0 ? rang : total} / ${total}`;
}

/* ------------------------------------------- « Progression détectée » */

export const CIVIC_CHANGES_TITLE = "Progression détectée";

/**
 * Ce qu'une transition **servie** raconte : « Le Parlement passe à En
 * progression ».
 *
 * 🛑 Le verdict vient du serveur (`avant`, `apres`, `progres`) : cette fonction
 * ne compare rien, elle met en mots. Le libellé d'état est celui, gelé, de
 * `CIVIC_MAITRISE_LABEL` — jamais une chaîne réécrite ici.
 */
export function civicTransitionLabel(t: CivicPlanTransitionDto): string {
    return `${t.label} passe à ${CIVIC_MAITRISE_LABEL[t.apres]}`;
}

/** « Votre prochaine étape : Le Gouvernement ». */
export function civicNextStepLabel(ref: CivicPlanCibleRefDto): string {
    return `Votre prochaine étape : ${ref.label}`;
}

/**
 * La période du bloc, **servie** (`fenetre`) et rendue avec le libellé gelé
 * partagé avec le TCF — une seule autorité sur ces trois périodes.
 */
export function civicChangesWindowLabel(c: CivicPlanChangementsDto): string {
    return PLAN_RECENT_CHANGES_WINDOW_LABEL[c.fenetre];
}
