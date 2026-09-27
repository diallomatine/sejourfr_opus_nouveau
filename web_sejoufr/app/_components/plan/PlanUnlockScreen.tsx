"use client";

/**
 * **L'écran de transition « Débloquer mon plan »** — entre le Plan et la page
 * de choix du pass (maquettes du propriétaire, 2026-09-20).
 *
 * 🛑 **UN SEUL composant pour les deux modules.** Les deux maquettes partagent
 * l'anatomie et ne diffèrent que par leur matière : deux écrans divergeraient au
 * premier correctif (D-50 / A86).
 *
 * 🛑 **Le héros dit ce que les réponses ont montré** : un ancien résultat de
 * diagnostic 4 épreuves s'il existe, sinon le Plan (le cas ordinaire).
 *
 * 🛑 **« Vos priorités » est rangé COMME LE PLAN** (demande du propriétaire,
 * 2026-09-26) : un encart rétractable par épreuve TCF (`plan.domaines`) ou par
 * thème civique (le regroupement du cycle civique), avec au plus
 * `PLAN_UNLOCK_MAX_PAR_GROUPE` lignes chacun — un plafond d'**affichage** ;
 * le sous-titre annonce le total **servi**. Une épreuve ou un thème **non
 * évalué** (fait servi : `evaluated`, `NON_EVALUE`) garde son encart, sans
 * liste : *null = inconnu, jamais mauvais*.
 *
 * 🛑 **Aucun état n'est dérivé d'un nombre.** Côté civique la pastille est
 * l'`etat` SERVI du thème (`CivicThemeState`) ; côté TCF c'est la `nature`
 * servie de chaque action et l'urgence servie de chaque épreuve
 * (`PlanDomainPriority`). Aucun front ne classe ici un score ni un palier.
 *
 * 🛑 **Aucun prix écrit.** Le montant est le **minimum servi** des pass du
 * module (`passFromPrice`). Catalogue injoignable ⇒ pas de ligne de prix.
 *
 * 🛑 **Sans diagnostic terminé, cet écran ne s'affiche pas** : il remplace sa
 * route par la page de choix du pass. Un écran de transition qui n'a rien à
 * raconter n'a pas à retarder un achat — et il n'invente aucune liste.
 *
 * 🛑 **Aucun CSS d'écran** : tout passe par `SejourKit`.
 */

import {useCallback, useEffect, useMemo, useState} from "react";
import {useRouter} from "next/navigation";
import {AlertCircle} from "lucide-react";
import {
    billingApi,
    civicDiagnosticApi,
    journeyApi,
    learningPlanApi,
    tcfDiagnosticApi,
} from "@/lib/api";
import {track} from "@/lib/analytics";
import {retourOuRepli, withRetour} from "@/lib/retour";
import {withPurchaseOrigin} from "@/lib/purchase-origin";
import {passFrom} from "@/lib/passes";
import {useAuth} from "@/lib/auth-context";
import {canAccessModule, niveauCecrlShort} from "@/lib/types";
import {
    PLAN_UNLOCK_CHECKS_CIVIQUE,
    PLAN_UNLOCK_CTA,
    PLAN_UNLOCK_DOMAIN_TONE,
    PLAN_UNLOCK_MAX_PAR_GROUPE,
    PLAN_UNLOCK_NON_EVALUE,
    PLAN_UNLOCK_NON_EVALUE_META,
    PLAN_UNLOCK_NON_EVALUE_NOTE,
    PLAN_UNLOCK_EYEBROW,
    PLAN_UNLOCK_HERO_LABEL,
    PLAN_UNLOCK_LEVEL_UNKNOWN,
    PLAN_UNLOCK_LIST_TITLE,
    PLAN_UNLOCK_PRICE_NOTE,
    PLAN_UNLOCK_SKIP,
    PLAN_UNLOCK_TITLE,
    planRetourHref,
    PLAN_UNLOCK_NATURE_TONE,
    planUnlockChecksTcf,
    planUnlockGoalPill,
    planUnlockLead,
    planUnlockAccessModule,
    planUnlockAutres,
    planUnlockGroupeMeta,
    planUnlockPassModule,
    planUnlockPaywallHref,
    planUnlockPriceLine,
    planUnlockSeuilPill,
    type PlanUnlockModule,
} from "@/lib/plan-unlock";
import {
    civicEcartLine,
    civicScoreLabel,
    civicScoreRatio,
    civicSituationsNote,
    civicSituationsTitre,
    kitTone,
} from "@/lib/civic-diagnostic";
import {levelTrackPosition} from "@/lib/tcf-diagnostic";
import {planDomainLabel, planDomainShort} from "@/lib/plan-domain";
import {journeyStepTitle} from "@/lib/journey";
import {
    BlocAccordion,
    Card,
    CheckList,
    Cta,
    GoalHero,
    MiniPlan,
    NoteCard,
    Pad,
    PanelHead,
    Section,
    SejourApp,
    SheetHead,
    Stack,
    Sticky,
    sejourStyles as s,
    type Tone,
} from "@/app/_components/sejour/SejourKit";
import {
    CIVIC_THEME_STATE_LABEL,
    PLAN_ACTION_NATURE_LABEL,
    PLAN_DOMAIN_PRIORITY_LABEL,
} from "@/lib/types";
import type {
    CivicDiagnosticResultDto,
    JourneyDto,
    LearningPlanDto,
    PlanDomainSkillDto,
    PlanPublicResponse,
    TcfDiagnosticResultDto,
} from "@/lib/types";

/** Une ligne numérotée, déjà composée : libellé + pastille servie (ou aucune). */
type LignePriorite = {label: string; pill?: string; tone?: Tone};

/**
 * **Un encart** : une épreuve du TCF, ou un thème civique — le même
 * regroupement que le cycle du Plan.
 *
 * 🛑 `evalue` est **servi** (`PlanDomainDto.evaluated`, `CivicThemeState`),
 * jamais déduit d'une liste vide. `lignes: null` = on ne sait pas ce que le
 * Plan y demande (parcours civique illisible) : on n'affirme alors rien.
 */
type Groupe = {
    key: string;
    mark: string;
    title: string;
    meta: string;
    status: {label: string; tone: Tone};
    evalue: boolean;
    lignes: LignePriorite[] | null;
    /** Ce que le plafond d'affichage a coupé, déjà mis en mots. */
    autres: string | null;
};

/** Ce que l'écran a besoin de savoir, quel que soit le module. */
type Matiere = {
    heroValue: string;
    heroPill: string | null;
    heroRatio: number | null;
    heroMeta: string | null;
    groupes: Groupe[];
    /** Le TOTAL servi que le sous-titre annonce — jamais le nombre affiché. */
    total: number;
    /** L'encart propre au module. `null` ⇒ aucun encart. */
    encart: {titre: string; note: string | null} | null;
    checks: string[];
};

/** Le héros : palier de départ face à l'objectif, sur le rail du kit. */
type Heros = Pick<Matiere, "heroValue" | "heroPill" | "heroRatio" | "heroMeta">;

/**
 * Le héros TCF, lu **sur le résultat du diagnostic 4 épreuves** quand un
 * ancien résultat existe (le parcours est retiré des fronts depuis le
 * 2026-09-26, ses résultats restent lus).
 *
 * 🛑 Le rail est celui du kit (`levelTrackPosition`, A2 · B1 · B2) : c'est la
 * seule échelle affichée du dépôt, et en inventer une seconde ici ferait deux
 * positions différentes pour le même palier.
 */
function herosDuDiagnostic(r: TcfDiagnosticResultDto): Heros {
    const position = levelTrackPosition(r.niveauGlobal, r.cible);
    return {
        heroValue: r.niveauGlobal ? niveauCecrlShort(r.niveauGlobal) : PLAN_UNLOCK_LEVEL_UNKNOWN,
        heroPill: planUnlockGoalPill(r.cible),
        heroRatio:
            position && position.levels.length > 1
                ? position.currentIndex / (position.levels.length - 1)
                : null,
        heroMeta: position ? position.levels.join(" · ") : null,
    };
}

/**
 * Le héros TCF **lu sur le PLAN** — le cas ordinaire : le Plan existe pour
 * tout compte (D-69).
 */
function herosDuPlan(plan: LearningPlanDto): Heros {
    /* 🛑 **L'objectif DÉCLARÉ, jamais le palier en construction.**
       `targetLevel` est le palier que le cycle bâtit ; l'annoncer « Objectif
       B2 » à un candidat qui n'a pas déclaré sa démarche lui promettrait une
       cible qu'il n'a pas choisie. `null` ⇒ ni pastille, ni rail — le palier
       de départ se lit quand même. */
    const cible = plan.cycle.objectiveLevel;
    const position = levelTrackPosition(plan.cycle.startingLevel, cible);
    return {
        /* 🛑 Jamais le code brut : `A1_NON_ATTEINT` (Plan par défaut D-69) se
           rend « <A1 » par l'autorité du libellé, miroir de `shortName`. */
        heroValue: plan.cycle.startingLevel
            ? niveauCecrlShort(plan.cycle.startingLevel)
            : PLAN_UNLOCK_LEVEL_UNKNOWN,
        heroPill: planUnlockGoalPill(cible),
        heroRatio:
            position && position.levels.length > 1
                ? position.currentIndex / (position.levels.length - 1)
                : null,
        heroMeta: position ? position.levels.join(" · ") : null,
    };
}

/**
 * **Les priorités TCF, épreuve par épreuve** — lues sur `plan.domaines`, les
 * quatre épreuves du Plan (jamais `TCF_STRUCTURE`), dans l'ordre d'urgence
 * **servi**.
 *
 * 🛑 **Jamais sur `currentPriority` + `nextPriorities`** : ces deux champs sont
 * une vue bornée à cinq lignes pour tout le Plan, et une carte d'épreuve ne
 * dérive jamais d'une liste déjà tronquée. `domaines[].skills` porte, lui,
 * **toutes** les actions du pool (`nature` non nulle), et `priorityRank` leur
 * place dans le classement complet : l'encart les montre dans l'ordre du Plan.
 *
 * 🛑 La pastille d'une ligne dit la **nature servie** : une compétence *à
 * acquérir* n'a rien d'observé et ne se lit jamais « à renforcer ».
 */
function groupesTcf(plan: LearningPlanDto): {groupes: Groupe[]; total: number} {
    let total = 0;
    const groupes = plan.domaines.map((d): Groupe => {
        const base = {
            key: d.epreuve,
            mark: planDomainShort(d.epreuve),
            title: planDomainLabel(d.epreuve),
            evalue: d.evaluated,
        };
        if (!d.evaluated) {
            return {
                ...base,
                meta: PLAN_UNLOCK_NON_EVALUE_META.TCF,
                status: {label: PLAN_UNLOCK_NON_EVALUE.TCF, tone: "muted"},
                lignes: [],
                autres: null,
            };
        }
        /* L'ordre du classement servi ; un backend antérieur au rang garde
           l'ordre du référentiel (tri stable). */
        const actions = (d.skills ?? [])
            .filter((sk): sk is PlanDomainSkillDto & {nature: NonNullable<PlanDomainSkillDto["nature"]>} =>
                sk.nature !== null)
            .sort((a, b) =>
                (a.priorityRank ?? Number.MAX_SAFE_INTEGER) - (b.priorityRank ?? Number.MAX_SAFE_INTEGER));
        total += actions.length;
        const montrees = actions.slice(0, PLAN_UNLOCK_MAX_PAR_GROUPE);
        return {
            ...base,
            meta: planUnlockGroupeMeta("TCF", actions.length),
            status: {
                label: PLAN_DOMAIN_PRIORITY_LABEL[d.priority],
                tone: PLAN_UNLOCK_DOMAIN_TONE[d.priority],
            },
            lignes: montrees.map((sk) => ({
                label: sk.title,
                pill: PLAN_ACTION_NATURE_LABEL[sk.nature],
                tone: PLAN_UNLOCK_NATURE_TONE[sk.nature] as Tone,
            })),
            autres: planUnlockAutres("TCF", actions.length - montrees.length),
        };
    });
    return {groupes, total};
}

/** La matière TCF : le héros d'une source, les encarts du Plan. */
function matiereTcf(heros: Heros, plan: LearningPlanDto): Matiere {
    const {groupes, total} = groupesTcf(plan);
    return {
        ...heros,
        groupes,
        total,
        encart: null,
        checks: planUnlockChecksTcf(total),
    };
}

/**
 * **Les thèmes civiques**, le regroupement du cycle civique du Plan.
 *
 * - l'encart et son **état** viennent du diagnostic (`themes`, les cinq,
 *   `etat` servi — `NON_EVALUE` compris) ;
 * - ses **lignes** sont les unités officielles que le cycle civique garde
 *   ouvertes dans ce thème (`JourneyBlocDto.steps`, non bornées), dans
 *   l'ordre de la file.
 *
 * 🛑 **Aucune pastille par unité** : l'état servi du diagnostic civique est au
 * grain du THÈME (`20_` §3.4). Il est dans l'en-tête ; en fabriquer un par
 * unité serait l'inventer.
 */
function groupesCivique(r: CivicDiagnosticResultDto, journey: JourneyDto | null): Groupe[] {
    return r.themes.map((t): Groupe => {
        const status = {label: CIVIC_THEME_STATE_LABEL[t.etat], tone: kitTone(t.etat)};
        if (t.etat === "NON_EVALUE") {
            return {
                key: t.code,
                mark: "",
                title: t.label,
                meta: PLAN_UNLOCK_NON_EVALUE_META.CIVIQUE,
                /* `CIVIC_THEME_STATE_LABEL.NON_EVALUE` vaut déjà « Non évalué ». */
                status,
                evalue: false,
                lignes: [],
                autres: null,
            };
        }
        const bloc = journey?.blocs.find((b) => b.bloc.code === t.code) ?? null;
        const ouvertes = bloc
            ? bloc.steps.filter((st) => st.status === "UPCOMING" || st.status === "CURRENT")
            : null;
        const montrees = ouvertes?.slice(0, PLAN_UNLOCK_MAX_PAR_GROUPE) ?? null;
        return {
            key: t.code,
            mark: "",
            title: t.label,
            meta: ouvertes ? planUnlockGroupeMeta("CIVIQUE", ouvertes.length) : "",
            status,
            evalue: true,
            lignes: montrees?.map((st) => ({label: journeyStepTitle(st)})) ?? null,
            autres: ouvertes && montrees
                ? planUnlockAutres("CIVIQUE", ouvertes.length - montrees.length)
                : null,
        };
    });
}

/** La matière civique, lue **sur le résultat du diagnostic civique**. */
function matiereCivique(r: CivicDiagnosticResultDto, journey: JourneyDto | null): Matiere {
    const titre = civicSituationsTitre(r);
    return {
        heroValue: civicScoreLabel(r) ?? PLAN_UNLOCK_LEVEL_UNKNOWN,
        heroPill: planUnlockSeuilPill(r.seuilReussite, r.formatQuestions),
        heroRatio: civicScoreRatio(r),
        heroMeta: civicEcartLine(r),
        groupes: groupesCivique(r, journey),
        /* Le sous-titre civique compte les thématiques que le diagnostic
           classe — inchangé. */
        total: r.priorites.length,
        encart: titre ? {titre, note: civicSituationsNote(r)} : null,
        checks: PLAN_UNLOCK_CHECKS_CIVIQUE,
    };
}

/**
 * **L'encart ouvert à l'arrivée** : le premier, dans l'ordre servi, qui a des
 * priorités à montrer.
 *
 * Le cycle du Plan déplie son premier bloc ; ici le premier peut être une
 * épreuve non évaluée — sans liste —, et l'ouvrir montrerait un encart vide
 * au moment où l'écran doit dire ce que le plan contient. L'ordre TCF est
 * déjà celui de l'urgence (`domaines`), donc c'est l'épreuve la plus urgente
 * qui a du travail. Aucun ⇒ tout reste replié.
 */
function groupeOuvertParDefaut(groupes: Groupe[]): string | null {
    return groupes.find((g) => g.lignes !== null && g.lignes.length > 0)?.key ?? null;
}

type Etat =
    | {kind: "chargement"}
    | {kind: "pret"; matiere: Matiere}
    /** Rien à raconter : on laisse la place à la page de choix du pass. */
    | {kind: "sansDiagnostic"};

export function PlanUnlockScreen({module}: {module: PlanUnlockModule}) {
    const router = useRouter();
    const {user} = useAuth();
    const [etat, setEtat] = useState<Etat>({kind: "chargement"});
    const [choix, setChoix] = useState<{key: string | null} | null>(null);
    const [plans, setPlans] = useState<PlanPublicResponse[] | null>(null);
    /** Le parcours affiché (`plan_id`, Q8) : il suit l'achat jusqu'à
     *  l'intention, et le serveur en déduit la run fondatrice. `null` =
     *  inconnu, l'achat part quand même. */
    const [journeyId, setJourneyId] = useState<string | null>(null);

    /* 🛑 **C'est ICI que le chemin de retour est POSÉ** : l'écran de transition
       est le seul point du parcours d'achat qui sache d'où le candidat vient —
       `planRetourHref` est déjà l'autorité de « où l'on revient », et elle
       revient au Plan, jamais à un écran intermédiaire. Le chemin voyage
       ensuite jusqu'à Stripe (`?retour=` sur `payment-link`, validé serveur) et
       ramène le candidat sur son Plan une fois l'accès confirmé, au lieu de le
       laisser planté sur la page de succès. */
    /* Et le CTA du Plan (`LOCKED_PLAN`, D32) voyage avec lui : c'est ce qui
       range l'achat dans le tunnel du diagnostic. */
    const paywallHref = withPurchaseOrigin(
        withRetour(planUnlockPaywallHref(module), planRetourHref(module)),
        {ctaLocation: "LOCKED_PLAN", journeyId},
    );

    useEffect(() => {
        let annule = false;
        journeyApi.getCached(planUnlockAccessModule(module)).then(
            (j) => { if (!annule) setJourneyId(j.journeyId ?? null); },
            () => { /* sans parcours lisible, l'achat reste possible */ },
        );
        return () => { annule = true; };
    }, [module]);

    /* Le catalogue est un CONFORT : son échec retire la ligne de prix, il
       n'empêche jamais d'acheter. */
    useEffect(() => {
        let annule = false;
        billingApi.listPlans().then(
            (list) => { if (!annule) setPlans(list); },
            () => { /* pas de ligne de prix, jamais de montant de repli */ },
        );
        return () => { annule = true; };
    }, []);

    useEffect(() => {
        let annule = false;
        void (async () => {
            try {
                if (module === "CIVIQUE") {
                    const session = await civicDiagnosticApi.current();
                    if (!session || session.status !== "COMPLETED") {
                        if (!annule) setEtat({kind: "sansDiagnostic"});
                        return;
                    }
                    /* 🛑 `readResult` (GET) et non `result` (POST) : cet écran
                       LIT un diagnostic déjà clos, il n'en clôture aucun. */
                    const r = await civicDiagnosticApi.readResult(session.sessionId);
                    /* Le cycle civique donne les lignes de chaque thème. Il est
                       déjà en cache (le Plan l'a lu) ; illisible, les encarts
                       restent — sans lignes, et sans rien affirmer. */
                    const journey = await journeyApi.getCached("CIVIQUE").catch(() => null);
                    if (!annule) setEtat({kind: "pret", matiere: matiereCivique(r, journey)});
                    return;
                }
                /* 🛑 **Les encarts viennent TOUJOURS du Plan** — c'est le Plan
                   qu'on vend, et ses domaines portent toutes les actions de
                   chaque épreuve. Lecture en cache : le Plan est déjà chargé
                   par l'écran qui a poussé celui-ci. */
                const plan = await learningPlanApi.getCached();
                /* Le héros : un ancien diagnostic 4 épreuves s'il existe (un
                   palier global mesuré sur les quatre), sinon le Plan. */
                const session = await tcfDiagnosticApi.current().catch(() => null);
                const heros = session && session.status === "COMPLETED"
                    ? herosDuDiagnostic(await tcfDiagnosticApi.readResult(session.sessionId))
                    : herosDuPlan(plan);
                const matiere = matiereTcf(heros, plan);
                /* Aucune action servie nulle part : rien à raconter. */
                if (!annule) {
                    setEtat(
                        matiere.total > 0
                            ? {kind: "pret", matiere}
                            : {kind: "sansDiagnostic"},
                    );
                }
            } catch {
                if (!annule) setEtat({kind: "sansDiagnostic"});
            }
        })();
        return () => { annule = true; };
    }, [module]);

    /* 🛑 `replace` : l'écran qu'on n'a pas montré ne doit pas rester dans
       l'historique, sinon le retour depuis le paywall y revient en boucle. */
    useEffect(() => {
        if (etat.kind === "sansDiagnostic") router.replace(paywallHref);
    }, [etat.kind, paywallHref, router]);

    /* 🛑 **CET ÉCRAN N'EXISTE QUE TANT QUE L'ACCÈS MANQUE.** Dès qu'il arrive —
       un paiement revenu de Stripe, un pass restauré, un accès lu à froid — il
       n'a plus rien à proposer : il s'efface au profit du Plan, qui est
       désormais ouvert. Sans ça, revenir ici après avoir payé y retrouve
       « Débloquer mon plan ».

       `replace`, jamais `push` : on ne laisse pas dans l'historique un écran
       qui se refermerait aussitôt. Miroir mobile : le `ref.listen` sur
       `accesModuleProvider` de `plan_unlock_screen.dart`. */
    const ouvert = canAccessModule(user, planUnlockAccessModule(module));
    useEffect(() => {
        if (ouvert) router.replace(planRetourHref(module));
    }, [ouvert, module, router]);

    /* 🛑 **Jamais un `back()` nu** : cet écran s'ouvre depuis le Plan, mais un
       lien partagé ou un nouvel onglet n'a pas d'historique — la croix ne
       répondrait plus. `retourOuRepli` remonte si elle peut, sinon elle rejoint
       le Plan, où le candidat serait arrivé en remontant. Miroir du
       `retourOuRepli` mobile. */
    const retour = useCallback(() => {
        retourOuRepli(router, planRetourHref(module));
    }, [module, router]);

    const entryPass = useMemo(
        () => (plans ? passFrom(plans, planUnlockPassModule(module)) : null),
        [plans, module],
    );
    const priceLine = plans ? planUnlockPriceLine(entryPass?.price ?? null) : null;

    /* Étape 6 du tunnel « Suivi » : ce que le candidat avait sous les yeux,
       jamais ce qu'il paiera. Catalogue muet ⇒ ni code ni prix. */
    const trackUnlock = useCallback(() => {
        track("PREMIUM_CTA_CLICKED", {ctaLocation: "LOCKED_PLAN", screen: "plan_debloquer"});
        track(
            "PLAN_UNLOCK_CLICKED",
            {
                ctaLocation: "LOCKED_PLAN",
                planCode: entryPass?.code,
                displayedPriceCents: entryPass ? Math.round(entryPass.price * 100) : undefined,
            },
            {context: {journeyId}},
        );
    }, [entryPass, journeyId]);

    if (etat.kind !== "pret") {
        return (
            <SejourApp sticky>
                <SheetHead eyebrow={PLAN_UNLOCK_EYEBROW[module]} onClose={retour} />
                <Pad>
                    <p className={s.sub} aria-busy="true">Chargement…</p>
                </Pad>
            </SejourApp>
        );
    }

    const m = etat.matiere;
    /* `null` = le candidat n'a rien touché : on suit l'encart par défaut. Une
       fois un en-tête touché, c'est **son** choix qui vaut — « tout replié »
       compris. Même geste que le cycle du Plan. */
    const groupeOuvert = choix ? choix.key : groupeOuvertParDefaut(m.groupes);

    return (
        <SejourApp sticky>
            <SheetHead eyebrow={PLAN_UNLOCK_EYEBROW[module]} onClose={retour} />

            {/* 1 — l'écart, en un coup d'œil. Palier ou score : deux faits
                servis, posés dans la même brique. */}
            <Pad>
                <GoalHero
                    label={PLAN_UNLOCK_HERO_LABEL[module]}
                    value={m.heroValue}
                    pill={m.heroPill}
                    ratio={m.heroRatio}
                    metaLabel={m.heroMeta}
                />
            </Pad>

            {/* 2 — ce que le plan promet, et sur quoi il s'appuie. */}
            <Section flush>
                <PanelHead
                    lead
                    title={PLAN_UNLOCK_TITLE[module]}
                    sub={planUnlockLead(module, m.total)}
                />
            </Section>

            {/* 3 — les priorités, épreuve par épreuve (ou thème par thème) :
                le regroupement du cycle du Plan, dans l'ordre SERVI. */}
            <Section title={PLAN_UNLOCK_LIST_TITLE[module]} flush>
                <Stack>
                    {m.groupes.map((g) => (
                        <BlocAccordion
                            key={g.key}
                            mark={g.mark}
                            title={g.title}
                            meta={g.meta}
                            status={g.status}
                            open={groupeOuvert === g.key}
                            onToggle={() => setChoix({key: groupeOuvert === g.key ? null : g.key})}
                        >
                            {!g.evalue ? (
                                <p className={s.tiny}>{PLAN_UNLOCK_NON_EVALUE_NOTE[module]}</p>
                            ) : g.lignes && g.lignes.length > 0 ? (
                                <>
                                    <MiniPlan rows={g.lignes} />
                                    {g.autres && <p className={s.tiny}>{g.autres}</p>}
                                </>
                            ) : g.lignes ? (
                                <p className={s.tiny}>{g.meta}</p>
                            ) : null}
                        </BlocAccordion>
                    ))}
                </Stack>
            </Section>

            {/* 4 — le bloc propre au module : l'encart des mises en situation
                côté civique, rien côté TCF. */}
            {m.encart && (
                <Section flush>
                    <NoteCard variant="warn" icon={AlertCircle} title={m.encart.titre}>
                        {m.encart.note && <p className={s.tiny}>{m.encart.note}</p>}
                    </NoteCard>
                </Section>
            )}

            {/* 5 — ce que le pass ouvre. */}
            <Section flush>
                <Card variant="soft">
                    <CheckList items={m.checks} />
                </Card>
            </Section>

            <Sticky>
                <Stack>
                    <Cta
                        href={paywallHref}
                        lead={priceLine}
                        caption={PLAN_UNLOCK_PRICE_NOTE}
                        onClick={trackUnlock}
                    >
                        {PLAN_UNLOCK_CTA}
                    </Cta>
                    <button type="button" className={s.link} onClick={retour}>
                        {PLAN_UNLOCK_SKIP}
                    </button>
                </Stack>
            </Sticky>
        </SejourApp>
    );
}
