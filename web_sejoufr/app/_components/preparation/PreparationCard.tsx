"use client";

/**
 * **Ma préparation** — l'état des deux modules, côte à côte.
 *
 * 🛑 **C'est la PREMIÈRE des trois portes** vers un diagnostic inachevé
 * (Accueil, Plan, Examens). Elle lit `userContentApi.preparation()`, le même
 * état que les deux autres : c'est ce qui garantit que le candidat ne se voit
 * pas proposer trois choses différentes selon l'écran où il arrive.
 *
 * 🛑 **Les deux modules avancent indépendamment.** Un candidat ne prépare pas
 * forcément les deux, et l'un ne dit rien de l'autre.
 *
 * `module` borne la carte au parcours affiché — l'Accueil est scopé depuis le
 * 2026-09-12. Sans prop, les deux lignes sont rendues : c'est le comportement
 * d'origine, conservé pour tout écran qui veut la vue d'ensemble.
 *
 * Elle assemble les primitives du KIT (`Card`, `Stack`, `sejourStyles`) depuis
 * que l'Accueil est un écran du KIT : elle n'a plus de feuille à elle.
 */
import Link from "next/link";
import {ArrowRight} from "lucide-react";
import {Card, Stack, sejourStyles} from "../sejour/SejourKit";
import {
    CIVIQUE_LABEL,
    TCF_LABEL,
    civiqueAction,
    tcfAction,
    type PreparationAction,
} from "@/lib/preparation";
import type {PreparationDto} from "@/lib/types";
import type {ParcoursModule} from "@/lib/module-switch";

/**
 * 🛑 **L'état est reçu, plus rechargé ici.** L'Accueil le lit une fois et le
 * partage avec la carte « Continuez votre diagnostic complet » : deux appels à
 * `preparation()` sur le même écran auraient pu répondre deux états différents,
 * et donc proposer deux prochaines actions. `null` = pas encore chargé ou échec
 * best-effort : la carte est simplement absente, jamais une erreur.
 */
export function PreparationCard({prep, module}: {
    prep: PreparationDto | null;
    module?: ParcoursModule;
}) {
    if (!prep) return null;

    const tcf = module !== "CIVIQUE";
    const civique = module !== "TCF";
    return (
        <Stack>
            {tcf && <ModuleLigne label={TCF_LABEL} action={tcfAction(prep.tcf)} />}
            {civique && <ModuleLigne label={CIVIQUE_LABEL} action={civiqueAction(prep.civique)} />}
        </Stack>
    );
}

function ModuleLigne({label, action}: {label: string; action: PreparationAction}) {
    return (
        <Card padding="rows">
            <p className={sejourStyles.label}>{label}</p>
            <p className={sejourStyles.sub} style={{marginTop: 0}}>
                {action.statut}
            </p>
            <Link href={action.href} className={sejourStyles.link}>
                {action.cta} <ArrowRight size={16} strokeWidth={2.4} aria-hidden />
            </Link>
        </Card>
    );
}
