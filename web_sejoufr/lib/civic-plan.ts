/**
 * Les **mots** du plan civique (L10, `20_` §6) — **purs**, déclarés une fois
 * pour tout le web.
 *
 * 🛑 **Le serveur n'expose que des faits** : un état de maîtrise, une boîte, une
 * échéance, un compte d'erreurs. Les phrases vivent ici, et sont des **miroirs
 * mot pour mot** de `mobile_sejourfr/lib/screens/plan/civic_plan_labels.dart` :
 * un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * ⚠️ **Le miroir porte sur le TEXTE, pas sur l'inventaire** (P8.7, 2026-09-20).
 * La refonte du plan civique abonné (D-50) a vidé cet écran de ses sections
 * dérivées, et chaque front a supprimé **ce que lui ne lit plus** : l'écran
 * gratuit du mobile garde deux helpers que le web n'a jamais montrés
 * (`civicPlanAutresLabel`, `kCivicPlanLockedCta`, `civicCibleTone`), ils vivent
 * donc désormais côté Dart seulement. Ce n'est pas un oubli de parité : c'est
 * une divergence de l'écran **gratuit**, antérieure à cette passe, et aucun
 * libellé partagé n'a bougé.
 *
 * ⚠️ `20_` §10 prévoyait un `civic_plan_item.reason_text` calculé serveur. Il
 * n'existe pas, et c'est délibéré : un texte composé côté serveur ne se relit
 * pas dans deux mises en page différentes, et se dupliquerait de toute façon dès
 * qu'un écran voudrait le dire autrement.
 *
 * 🛑 Ce fichier ne **dérive** aucun état pédagogique : `maitrise` et `aRevoir`
 * arrivent servis. Il ne fait que les mettre en mots.
 */
import type {CivicPlanCibleDto, CivicPlanGrainDto} from "./types";

/** Bloc 1 — l'objectif. */
export const CIVIC_PLAN_RESULT_TITLE = "Votre résultat au diagnostic";
export const CIVIC_PLAN_RESULT_SEUIL = "Seuil de réussite";

/** Bloc 2 — à faire maintenant. */
export const CIVIC_PLAN_NOW_TITLE = "À faire maintenant";
export const CIVIC_PLAN_NOW_CTA = "Commencer";
export const CIVIC_PLAN_LOCKED_NOTE =
    "Les séries ciblées font partie de l'abonnement. Votre plan, lui, reste entier.";

/** Bloc 4 — les priorités. 🛑 Ne subsiste que sur l'écran **gratuit** : le plan
 *  d'un abonné lit le cycle (D-50 §2), qui est l'autorité de l'ordre. */
export const CIVIC_PLAN_PRIORITIES_TITLE = "Vos priorités";
export const CIVIC_PLAN_WORK_CTA = "Travailler";

/** Bloc 5 — révision d'entretien. 🛑 Jamais présentée comme une alerte, et seul
 *  affichage du Leitner : le cycle ne le porte pas (D-49). */
export const CIVIC_PLAN_REVIEW_TITLE = "À revoir bientôt";

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

/* ⚠️ **SUPPRIMÉS par la refonte du plan civique abonné** (P8.7, D-50,
   2026-09-20), avec leur dernier lecteur — « refonte = suppression immédiate de
   l'ancien » :

   - `CIVIC_PATH_LABELS` / `CIVIC_PATH_TITLE` / `civicPath` / `civicPathCounter`
     — le « parcours de la notion ». Il illustrait la cible du plan **dérivé**,
     et « À faire maintenant » lit désormais le **cycle** : les cinq étapes du
     Leitner n'ont plus d'écran où se poser.
   - `CIVIC_CHANGES_TITLE` / `civicTransitionLabel` / `civicNextStepLabel` /
     `civicChangesWindowLabel` — « Progression détectée ». Le TCF l'a retirée le
     2026-09-19 : elle redisait les blocs du cycle en moins précis.
   - `civicPlanAutresLabel`, `CIVIC_PLAN_LOCKED_CTA`, `civicCibleTone`,
     `CIVIC_PLAN_TITLE`, `CIVIC_PLAN_LEAD`, `CIVIC_PLAN_SOLID_TITLE`,
     `CIVIC_PLAN_ALL_GOOD_TITLE` / `_TEXT`, `CIVIC_PLAN_EXAM_HREF` — sans
     lecteur web. Les trois premiers vivent encore côté Dart, où l'écran
     **gratuit** les lit (cf. l'avertissement de tête).

   🛑 `CivicPlanDto.changements` et `Cible.parcours` restent **servis** et
   restent dans `lib/types.ts` : c'est l'affichage qui part, pas le contrat. */
