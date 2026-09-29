import {ClipboardCheck, TrendingUp} from "lucide-react";
import {CompteCard, CompteRow} from "@/app/_components/compte/CompteParts";
import {Pad} from "@/app/_components/sejour/SejourKit";
import {
    JOURNEY_HISTORY_TITLE,
    PLAN_DIAGNOSTIC_SUB,
    PLAN_DIAGNOSTIC_TITLE,
    journeyHistoryHref,
    journeyHistorySub,
} from "@/lib/journey";
import type {ParcoursModule} from "@/lib/module-switch";

/**
 * Les deux accès sous le cycle du Plan, TCF comme civique : « Mes cycles » et
 * « Mon diagnostic », en lignes icône + titre + sous-titre + chevron.
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
    return (
        <Pad>
            <CompteCard>
                <CompteRow
                    href={journeyHistoryHref(module)}
                    icon={<TrendingUp size={20}/>}
                    tone="muted"
                    title={JOURNEY_HISTORY_TITLE}
                    sub={journeyHistorySub(module)}
                />
                {diagnosticHref !== null && (
                    <CompteRow
                        href={diagnosticHref}
                        icon={<ClipboardCheck size={20}/>}
                        tone="muted"
                        title={PLAN_DIAGNOSTIC_TITLE}
                        sub={PLAN_DIAGNOSTIC_SUB}
                    />
                )}
            </CompteCard>
        </Pad>
    );
}
