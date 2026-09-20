/**
 * Les **mots** du plan civique (L10, `20_` §6) — **purs**, déclarés une fois
 * pour tout le web.
 *
 * 🛑 **Le serveur n'expose que des faits** : un état de maîtrise, une boîte, une
 * échéance, un compte d'erreurs. Les phrases vivent ici, et sont des **miroirs
 * mot pour mot** de `mobile_sejourfr/lib/screens/plan/civic_plan_labels.dart` :
 * un libellé qui bouge, ce sont deux fichiers dans la même passe.
 *
 * ✅ **L'asymétrie d'inventaire de P8.7 est REFERMÉE** (2026-09-20, second
 * arbitrage du propriétaire : « pour la partie Examen civique du plan, pour un
 * non abonné, il faut aussi la même chose qu'un abonné, sauf qu'il peut pas
 * travailler dessus »). A84 avait laissé trois helpers côté Dart seulement,
 * parce que l'écran **gratuit** civique gardait son anatomie propre. Les deux
 * anatomies gratuites ayant disparu, la divergence tombe d'elle-même :
 * `civicPlanAutresLabel` part avec sa section, `civicCibleTone` **reste** (dix
 * lecteurs, dont l'écran Progrès), et `kCivicPlanLockedCta` est **promu** ici
 * sous le nom {@link CIVIC_PLAN_LOCKED_CTA} — il a maintenant un lecteur des
 * deux côtés. ⚠️ **A89 est donc révoquée** : ce que D-50 arbitrait pour le plan
 * d'un abonné vaut désormais pour les deux.
 *
 * ⚠️ `20_` §10 prévoyait un `civic_plan_item.reason_text` calculé serveur. Il
 * n'existe pas, et c'est délibéré : un texte composé côté serveur ne se relit
 * pas dans deux mises en page différentes, et se dupliquerait de toute façon dès
 * qu'un écran voudrait le dire autrement.
 *
 * 🛑 Ce fichier ne **dérive** aucun état pédagogique : `maitrise` et `aRevoir`
 * arrivent servis. Il ne fait que les mettre en mots.
 */
import type {PlanNowGeste} from "./plan-domain";
import {
    JOURNEY_LOCKED_BADGE,
    journeyEtapeASeries,
    journeyEtapeHref,
    journeyStepSubtitle,
    journeyStepTitle,
} from "./journey";
import {
    CIVIC_MAITRISE_LABEL,
    type CivicPlanCibleDto,
    type CivicPlanDto,
    type CivicPlanGrainDto,
    type JourneyDto,
} from "./types";

/**
 * L'en-tête de l'écran. 🛑 **Deux eyebrows, un seul titre** : le parcours ne
 * change pas selon l'accès, seule la phrase qui le présente le fait — c'est la
 * forme du Plan TCF (`planTopKicker` / `kPlanTopKickerFree`).
 *
 * ⚠️ Ces trois chaînes étaient écrites **en dur** dans `CivicPlanPanel` alors
 * que le mobile les déclarait déjà (`kCivicPlanTopKicker*`,
 * `kCivicPlanScreenTitle`) : même famille que `DETTE-P1`, refermée ici.
 */
export const CIVIC_PLAN_TOP_KICKER = "Votre préparation personnalisée à l'Examen civique";
export const CIVIC_PLAN_TOP_KICKER_FREE = "Créé à partir de votre diagnostic";
export const CIVIC_PLAN_SCREEN_TITLE = "Mon plan du jour";

/** Bloc 2 — à faire maintenant. */
export const CIVIC_PLAN_NOW_TITLE = "À faire maintenant";

/**
 * Le libellé de l'encart bleu de la carte d'action.
 *
 * ⚠️ « Objectif de cette séance » de la maquette n'est **pas servi** (aucun
 * `reason_text`) : on nomme ce qu'on sait dire, c'est-à-dire **pourquoi** cette
 * cible passe maintenant.
 */
export const CIVIC_PLAN_NOW_WHY = "Pourquoi maintenant";

/**
 * Le geste d'une action **fermée** — la série, pas le plan entier.
 *
 * 🛑 **Aucune chaîne neuve n'est gelée** : elle existait déjà côté Dart
 * (`kCivicPlanLockedCta`) et n'avait jamais eu de lecteur web. Elle en a un des
 * deux côtés depuis que le Plan civique gratuit porte l'anatomie de l'abonné.
 *
 * ⚠️ **Distincte de `JOURNEY_STEP_UNLOCK_LINK`** (« Débloquer mon plan → »),
 * qui est le geste d'une **ligne du cycle** : là on parle du plan entier, ici
 * d'**une** série. Même raison qu'`PLAN_NOW_CTA_LOCKED` côté TCF (A114).
 */
export const CIVIC_PLAN_LOCKED_CTA = "Débloquer cette série";

export const CIVIC_PLAN_LOCKED_NOTE =
    "Les séries ciblées font partie de l'abonnement. Votre plan, lui, reste entier.";

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

/* ------------------------------------------- « À faire maintenant » civique */

/**
 * **Le geste d'une CIBLE du plan dérivé** — la seule autorité civique sur « que
 * se passe-t-il quand on la touche ».
 *
 * 🛑 **Un écran ne redéduit jamais ce geste d'un `locked` ni d'un statut
 * d'abonnement.** C'est la transposition exacte de `planNowCard` (A114) : le
 * drapeau `free` **court-circuite avant** le verrou servi, donc aucun écran ne
 * peut faire partir une série pour un compte sans accès — et c'est le seul
 * endroit à relire pour s'en assurer (D-33, que `CivicPlanService` oppose déjà
 * en 403).
 *
 * ⚠️ Miroir mot pour mot du mobile (`civicCibleGeste`, `civic_plan_labels.dart`).
 */
export function civicCibleGeste(
    cible: CivicPlanCibleDto,
    {free = false}: {free?: boolean} = {},
): PlanNowGeste {
    return free || cible.locked ? "DEBLOQUER" : "LANCER";
}

/** Ce que la carte « À faire maintenant » civique **lance**. */
export type CivicNowSource =
    /** Une **unité officielle** du cycle (D-48) — `useCivicUniteSerie`. */
    | {kind: "UNITE"; code: string}
    /** Une **cible** du plan dérivé (une notion, ou un thème en mode dégradé) —
     *  `useCivicSerie`. */
    | {kind: "CIBLE"; cible: CivicPlanCibleDto};

/** L'identité **complète** de la carte : ce qu'elle montre, et ce qu'elle lance. */
export interface CivicNowVue {
    /** 🛑 **Ce que le geste fait**, décidé ici et nulle part ailleurs. */
    geste: PlanNowGeste;
    /**
     * **Où mène le geste `OUVRIR_ETAPE`** — servi avec lui, `null` partout
     * ailleurs. 🛑 Un écran ne recompose jamais cette adresse.
     */
    etapeHref: string | null;
    /** `null` quand rien ne se résout — la carte nomme l'étape et s'arrête là. */
    source: CivicNowSource | null;
    title: string;
    subtitle: string | null;
    badge: string | null;
    objectiveLabel: string | null;
    objective: string | null;
    /** La ligne de méta, sans son icône : celle-ci appartient à l'écran. */
    meta: string | null;
    cta: string;
    /** Le verrou **lu**, jamais déduit d'un rang ni d'un abonnement. */
    locked: boolean;
}

/**
 * **« À faire maintenant », côté civique** — l'autorité unique des deux écrans
 * (abonné et sans accès) et des deux fronts.
 *
 * 🛑 **Le CYCLE décide quelle étape** (D-50 §2) : `journey.current` passe
 * **avant** le plan dérivé, et c'est lui qui a supprimé, le 2026-09-16, la
 * contradiction où l'Accueil annonçait une action et le Plan une autre au même
 * instant.
 *
 * 🛑 **Le repli sur `plan.prochaine` est la MÊME forme que `planNowCard`**
 * (`duParcours ?? plan.currentPriority`), et il n'est pas décoratif : dès que le
 * serveur verrouillera les étapes d'entraînement civiques d'un compte sans accès
 * (cf. la moitié backend de cette passe), `JourneyReadService.elire` les sautera
 * et `journey.current` vaudra `null` — exactement ce qui arrive déjà au TCF
 * gratuit. Sans repli, la carte **disparaîtrait** le jour où le verrou est servi,
 * et l'écran gratuit perdrait ce que le propriétaire demande d'y voir.
 *
 * 🛑 **`free` ne décide QUE du geste** (A114, transposée) : un compte sans accès
 * reçoit **exactement** la carte d'un abonné — titre, bloc, méta, constat du
 * correcteur — et son bouton ouvre l'**offre** au lieu de lancer. La
 * contradiction #1 reste fermée : on floute l'action, jamais le résultat mesuré.
 *
 * ⚠️ Miroir mot pour mot du mobile (`civicNowCard`, `civic_plan_labels.dart`).
 */
export function civicNowCard(
    plan: CivicPlanDto,
    {journey = null, free = false}: {journey?: JourneyDto | null; free?: boolean} = {},
): CivicNowVue | null {
    const etape = journey?.current ?? null;
    if (etape) {
        const unite = etape.unite;
        /* 🛑 Un examen de bloc ne se lance pas d'ICI : il a son encart dans le
           cycle. Rien ne se résout ⇒ aucun geste (garde-fou du 2026-09-17). */
        const resoluble = unite !== null && etape.type === "TRAIN_SKILL";
        const verrou = free || etape.locked;
        /* 🛑 **UNE UNITÉ CIVIQUE OUVRE SON ÉCRAN, elle ne lance plus sa série**
           (demande du propriétaire, 2026-09-20) — la même règle et le **même
           prédicat** que le TCF (`journeyEtapeASeries`, `lib/journey.ts`), lus
           ici pour que le bouton « Travailler » aboutisse au même écran que la
           ligne du cycle. `DEBLOQUER` reste prioritaire. */
        const serie = journeyEtapeASeries(etape);
        return {
            geste: verrou
                ? "DEBLOQUER"
                : serie
                    ? "OUVRIR_ETAPE"
                    : resoluble ? "LANCER" : "AUCUN",
            etapeHref: serie ? journeyEtapeHref(etape.id, "CIVIQUE") : null,
            source: resoluble ? {kind: "UNITE", code: unite.code} : null,
            title: journeyStepTitle(etape),
            subtitle: etape.bloc?.label ?? null,
            badge: etape.locked ? JOURNEY_LOCKED_BADGE : null,
            objectiveLabel: null,
            objective: null,
            /* `journeyStepSubtitle` peut ne rien avoir à dire : on n'affiche
               alors aucune méta plutôt qu'une ligne vide. */
            meta: journeyStepSubtitle(etape) ?? null,
            cta: verrou ? CIVIC_PLAN_LOCKED_CTA : CIVIC_PLAN_WORK_CTA,
            locked: etape.locked,
        };
    }

    const cible = plan.prochaine;
    /* 🛑 `null` est un cas NORMAL : plus rien à faire. La carte disparaît, elle
       n'affiche jamais un squelette. */
    if (!cible) return null;
    const geste = civicCibleGeste(cible, {free});
    return {
        geste,
        /* Une cible du plan **dérivé** n'est pas une étape du cycle : elle n'a
           pas d'écran d'étape, et son geste reste le lanceur de série. */
        etapeHref: null,
        source: {kind: "CIBLE", cible},
        title: cible.label,
        subtitle: cible.label === cible.themeLabel ? null : cible.themeLabel,
        badge: cible.locked ? JOURNEY_LOCKED_BADGE : null,
        objectiveLabel: CIVIC_PLAN_NOW_WHY,
        objective: `${CIVIC_MAITRISE_LABEL[cible.maitrise]} · ${civicPlanRaison(cible)}`,
        meta: civicSerieLabel(cible),
        cta: geste === "DEBLOQUER" ? CIVIC_PLAN_LOCKED_CTA : CIVIC_PLAN_WORK_CTA,
        locked: cible.locked,
    };
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
   - `civicPlanAutresLabel`, `civicCibleTone`, `CIVIC_PLAN_TITLE`,
     `CIVIC_PLAN_LEAD`, `CIVIC_PLAN_SOLID_TITLE`, `CIVIC_PLAN_ALL_GOOD_TITLE` /
     `_TEXT`, `CIVIC_PLAN_EXAM_HREF` — sans lecteur web.

   ⚠️ **SUPPRIMÉS à leur tour par l'anatomie unique du 2026-09-20** (l'écran
   gratuit reçoit celle de l'abonné), avec leur dernier lecteur :
   `CIVIC_PLAN_RESULT_TITLE` / `_SEUIL` (la carte de score du diagnostic — elle
   se lit sur le rapport de diagnostic et sur « Où vous en êtes »),
   `CIVIC_PLAN_PRIORITIES_TITLE` (« Vos priorités », que le cycle dit mieux) et
   `CIVIC_PLAN_NOW_CTA` (« Commencer » — la carte d'action porte désormais le
   même `CIVIC_PLAN_WORK_CTA` que l'abonné).

   🛑 `CivicPlanDto.changements` et `Cible.parcours` restent **servis** et
   restent dans `lib/types.ts` : c'est l'affichage qui part, pas le contrat. */
