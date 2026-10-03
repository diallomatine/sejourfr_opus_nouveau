import {ClipboardCheck, TrendingUp} from "lucide-react";
import {InfoCard, Pad, Stack} from "@/app/_components/sejour/SejourKit";
import {
    JOURNEY_HISTORY_TITLE,
    PLAN_DIAGNOSTIC_SUB,
    PLAN_DIAGNOSTIC_TITLE,
    journeyHistoryHref,
    journeyHistorySub,
} from "@/lib/journey";
import type {ParcoursModule} from "@/lib/module-switch";

/**
 * Les deux accès du Plan, TCF comme civique : « Mes cycles » et « Mon
 * diagnostic », en `InfoCard` de la maquette (icône, titre, sous-titre,
 * chevron — Navigation v2).
 * Miroir mobile : le `ListGroup` de `_links` (`plan_tcf_view.dart`,
 * `civic_plan_view.dart`).
 *
 * 🛑 **Deux accès, et deux seulement** (arbitrage du propriétaire,
 * 2026-09-19) : « Toutes mes compétences » et « Mes examens blancs » ont été
 * retirés. Ne pas les réintroduire.
 *
 * 🛑 **« Mon diagnostic » n'existe que si le diagnostic est FAIT** (2026-09-28) :
 * `diagnosticHref === null` ⇒ ligne masquée. L'appelant le décide sur
 * `diagnosticFait` (`lib/preparation.ts`), jamais ici.
 */
export function PlanLinks({module, diagnosticHref}: {module: ParcoursModule; diagnosticHref: string | null}) {
    const tone = module === "CIVIQUE" ? "civique" : "tcf";
    return (
        <Pad>
            <Stack>
                <InfoCard
                    module={tone}
                    href={journeyHistoryHref(module)}
                    icon={<TrendingUp/>}
                    title={JOURNEY_HISTORY_TITLE}
                    meta={journeyHistorySub(module)}
                    trailing="chevron"
                />
                {diagnosticHref !== null && (
                    <InfoCard
                        module={tone}
                        href={diagnosticHref}
                        icon={<ClipboardCheck/>}
                        title={PLAN_DIAGNOSTIC_TITLE}
                        meta={PLAN_DIAGNOSTIC_SUB}
                        trailing="chevron"
                    />
                )}
            </Stack>
        </Pad>
    );
}
