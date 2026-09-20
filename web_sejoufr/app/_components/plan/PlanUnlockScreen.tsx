"use client";

/**
 * **L'écran de transition « Débloquer mon plan »** — entre le Plan et la page
 * de choix du pass (maquettes du propriétaire, 2026-09-20).
 *
 * 🛑 **UN SEUL composant pour les deux modules.** Les deux maquettes partagent
 * l'anatomie et ne diffèrent que par leur matière : deux écrans divergeraient au
 * premier correctif (D-50 / A86).
 *
 * 🛑 **Tout vient du DIAGNOSTIC** (demande du propriétaire : « et ces priorités
 * viennent du diagnostic »). Le héros, la liste et les pastilles se lisent sur
 * le **résultat du diagnostic** du module — jamais sur le Plan, jamais sur le
 * parcours : l'écran dit ce que les réponses ont montré, pas où en est le plan
 * aujourd'hui. Deux sources sur le même écran finiraient par se contredire.
 *
 * 🛑 **Aucun état n'est dérivé d'un nombre.** Côté civique la pastille est
 * l'`etat` SERVI du thème (`CivicThemeState`) ; côté TCF c'est
 * `prioritePastille`, l'autorité que le rapport de diagnostic emploie déjà
 * pour la même liste. Aucun front ne classe ici un score ni un palier.
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
import {billingApi, civicDiagnosticApi, learningPlanApi, tcfDiagnosticApi} from "@/lib/api";
import {track} from "@/lib/analytics";
import {retourOuRepli} from "@/lib/retour";
import {passFromPrice} from "@/lib/passes";
import {useAuth} from "@/lib/auth-context";
import {canAccessModule} from "@/lib/types";
import {
    PLAN_UNLOCK_CHECKS_CIVIQUE,
    PLAN_UNLOCK_CTA,
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
import {
    levelTrackPosition,
    prioriteLibelle,
    prioritePastille,
} from "@/lib/tcf-diagnostic";
import {EPREUVE_PRESENTATION} from "@/lib/exam-durations";
import {
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
import {CIVIC_THEME_STATE_LABEL, PLAN_ACTION_NATURE_LABEL} from "@/lib/types";
import type {
    CivicDiagnosticResultDto,
    LearningPlanDto,
    LearningPlanPriorityDto,
    PlanPublicResponse,
    TcfDiagnosticResultDto,
} from "@/lib/types";

/** Une ligne de la liste numérotée, déjà composée : libellé + pastille servie. */
type LignePriorite = {label: string; pill: string; tone: Tone};

/** Ce que l'écran a besoin de savoir, quel que soit le module. */
type Matiere = {
    heroValue: string;
    heroPill: string | null;
    heroRatio: number | null;
    heroMeta: string | null;
    lignes: LignePriorite[];
    /** L'encart propre au module. `null` ⇒ aucun encart. */
    encart: {titre: string; note: string | null} | null;
    checks: string[];
};

function epreuveLabel(epreuve: string): string {
    return (
        EPREUVE_PRESENTATION[epreuve as keyof typeof EPREUVE_PRESENTATION]?.label ?? epreuve
    );
}

/**
 * La matière TCF, lue **sur le résultat du diagnostic 4 épreuves**.
 *
 * 🛑 Le rail est celui du kit (`levelTrackPosition`, A2 · B1 · B2) : c'est la
 * seule échelle affichée du dépôt, et en inventer une seconde ici ferait deux
 * positions différentes pour le même palier.
 */
function matiereTcf(r: TcfDiagnosticResultDto): Matiere {
    const position = levelTrackPosition(r.niveauGlobal, r.cible);
    return {
        heroValue: r.niveauGlobal ?? PLAN_UNLOCK_LEVEL_UNKNOWN,
        heroPill: planUnlockGoalPill(r.cible),
        heroRatio:
            position && position.levels.length > 1
                ? position.currentIndex / (position.levels.length - 1)
                : null,
        heroMeta: position ? position.levels.join(" · ") : null,
        lignes: r.priorites.map((p) => {
            const pastille = prioritePastille(p.rang);
            return {
                /* « Expression orale — Tâche 3 » : la TÂCHE officielle est
                   nommée, jamais la personne. Même composition que la carte de
                   priorité du rapport de diagnostic. */
                label: prioriteLibelle(epreuveLabel(p.epreuve), p.taskCode),
                pill: pastille.label,
                tone: pastille.tone as Tone,
            };
        }),
        encart: null,
        checks: planUnlockChecksTcf(r.priorites.length),
    };
}

/**
 * La matière TCF **lue sur le PLAN** — le repli quand le diagnostic 4 épreuves
 * n'existe pas.
 *
 * 🛑 **C'est le cas NORMAL, pas un cas limite.** Le Plan existe dès que le
 * diagnostic **rapide** est clos (`prep.planDisponible`) ; le diagnostic
 * 4 épreuves, lui, est un geste distinct que la plupart des candidats n'ont
 * pas fait. Sans ce repli, l'écran n'avait rien à raconter et se retirait
 * aussitôt — le candidat retombait sur le paywall direct, exactement ce que
 * cet écran existe pour éviter (A145).
 *
 * Ce qu'on montre ne change pas : le palier de départ face à l'objectif, et
 * les priorités. Seule la **source** change — et c'est celle que le Plan
 * affiche déjà, donc l'écran de vente ne peut pas nommer autre chose que le
 * Plan qu'on vend.
 */
function matiereTcfDuPlan(plan: LearningPlanDto): Matiere {
    /* 🛑 **L'objectif DÉCLARÉ, jamais le palier en construction.**
       `targetLevel` est le palier que le cycle bâtit ; l'annoncer « Objectif
       B2 » à un candidat qui n'a pas déclaré sa démarche lui promettrait une
       cible qu'il n'a pas choisie. `null` ⇒ ni pastille, ni rail — le palier
       de départ se lit quand même. */
    const cible = plan.cycle.objectiveLevel;
    const position = levelTrackPosition(plan.cycle.startingLevel, cible);
    const priorites = [plan.currentPriority, ...plan.nextPriorities].filter(
        (p): p is LearningPlanPriorityDto => p !== null,
    );
    return {
        heroValue: plan.cycle.startingLevel ?? PLAN_UNLOCK_LEVEL_UNKNOWN,
        heroPill: planUnlockGoalPill(cible),
        heroRatio:
            position && position.levels.length > 1
                ? position.currentIndex / (position.levels.length - 1)
                : null,
        heroMeta: position ? position.levels.join(" · ") : null,
        /* 🛑 La pastille dit la **nature servie** de l'action, jamais un rang :
           une compétence *à acquérir* n'a rien d'observé et ne peut pas se
           lire « à renforcer ». */
        lignes: priorites.map((p) => ({
            label: p.title,
            pill: PLAN_ACTION_NATURE_LABEL[p.nature],
            tone: PLAN_UNLOCK_NATURE_TONE[p.nature] as Tone,
        })),
        encart: null,
        checks: planUnlockChecksTcf(priorites.length),
    };
}

/** La matière civique, lue **sur le résultat du diagnostic civique**. */
function matiereCivique(r: CivicDiagnosticResultDto): Matiere {
    const titre = civicSituationsTitre(r);
    return {
        heroValue: civicScoreLabel(r) ?? PLAN_UNLOCK_LEVEL_UNKNOWN,
        heroPill: planUnlockSeuilPill(r.seuilReussite, r.formatQuestions),
        heroRatio: civicScoreRatio(r),
        heroMeta: civicEcartLine(r),
        lignes: r.priorites.map((p) => ({
            label: p.label,
            /* 🛑 L'état est SERVI (`CivicThemeState`), pas déduit du rang. */
            pill: CIVIC_THEME_STATE_LABEL[p.etat],
            tone: kitTone(p.etat),
        })),
        encart: titre ? {titre, note: civicSituationsNote(r)} : null,
        checks: PLAN_UNLOCK_CHECKS_CIVIQUE,
    };
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
    const [plans, setPlans] = useState<PlanPublicResponse[] | null>(null);

    const paywallHref = planUnlockPaywallHref(module);

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
                    if (!annule) setEtat({kind: "pret", matiere: matiereCivique(r)});
                    return;
                }
                /* Le diagnostic 4 épreuves d'abord — c'est la matière la
                   plus riche (un palier par épreuve, la tâche officielle
                   nommée). Il est **rarement là** : c'est un geste à part. */
                const session = await tcfDiagnosticApi.current();
                if (session && session.status === "COMPLETED") {
                    const r = await tcfDiagnosticApi.readResult(session.sessionId);
                    /* Un diagnostic clos sans aucune priorité n'a pas de liste
                       à montrer : on retombe sur le Plan plutôt que de
                       fabriquer un écran vide. */
                    if (r.priorites.length > 0) {
                        if (!annule) setEtat({kind: "pret", matiere: matiereTcf(r)});
                        return;
                    }
                }
                /* 🛑 **Le repli est le chemin ORDINAIRE.** Lecture en cache :
                   le Plan est déjà chargé par l'écran qui a poussé celui-ci. */
                const plan = await learningPlanApi.getCached();
                const aDesPriorites =
                    plan.currentPriority !== null || plan.nextPriorities.length > 0;
                if (!annule) {
                    setEtat(
                        aDesPriorites
                            ? {kind: "pret", matiere: matiereTcfDuPlan(plan)}
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

    const priceLine = useMemo(() => {
        if (!plans) return null;
        return planUnlockPriceLine(passFromPrice(plans, planUnlockPassModule(module)));
    }, [plans, module]);

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
                    sub={planUnlockLead(module, m.lignes.length)}
                />
            </Section>

            {/* 3 — la liste numérotée, dans l'ordre SERVI. */}
            <Section title={PLAN_UNLOCK_LIST_TITLE[module]} flush>
                <Card padding="tight">
                    <MiniPlan rows={m.lignes} />
                </Card>
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
                        onClick={() =>
                            track("PREMIUM_CTA_CLICKED", {
                                ctaLocation: "LOCKED_PLAN",
                                screen: "plan_debloquer",
                            })
                        }
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
