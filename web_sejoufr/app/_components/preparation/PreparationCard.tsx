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
 */
import {useEffect, useState} from "react";
import Link from "next/link";
import {ArrowRight} from "lucide-react";
import {userContentApi} from "@/lib/api";
import {
    CIVIQUE_LABEL,
    PREPARATION_TITLE,
    TCF_LABEL,
    civiqueAction,
    tcfAction,
    type PreparationAction,
} from "@/lib/preparation";
import type {PreparationDto} from "@/lib/types";

export function PreparationCard() {
    const [prep, setPrep] = useState<PreparationDto | null>(null);

    useEffect(() => {
        let vivant = true;
        // Best-effort : un échec laisse simplement la carte absente. L'accueil
        // ne doit pas afficher une erreur pour un bloc de navigation.
        userContentApi
            .preparation()
            .then((p) => {
                if (vivant) setPrep(p);
            })
            .catch(() => undefined);
        return () => {
            vivant = false;
        };
    }, []);

    if (!prep) return null;

    return (
        <section className="prep" aria-labelledby="prep-title">
            <h2 id="prep-title">{PREPARATION_TITLE}</h2>
            <ModuleLigne label={TCF_LABEL} action={tcfAction(prep.tcf)} />
            <ModuleLigne label={CIVIQUE_LABEL} action={civiqueAction(prep.civique)} />
            <Styles />
        </section>
    );
}

function ModuleLigne({label, action}: {label: string; action: PreparationAction}) {
    return (
        <div className="prep-module">
            <p className="prep-module-label">{label}</p>
            <p className="prep-module-statut">{action.statut}</p>
            <Link href={action.href} className="prep-cta">
                {action.cta} <ArrowRight size={15} strokeWidth={2.4} aria-hidden />
            </Link>
        </div>
    );
}

function Styles() {
    return (
        <style jsx>{`
            .prep {
                display: flex;
                flex-direction: column;
                gap: 12px;
            }
            .prep h2 {
                font-family: var(--font-display);
                font-size: 20px;
                color: var(--color-ink);
                margin: 0;
            }
            .prep-module {
                border: 1px solid var(--color-line);
                border-radius: 16px;
                padding: 16px;
                display: flex;
                flex-direction: column;
                gap: 4px;
            }
            .prep-module-label {
                margin: 0;
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.06em;
                text-transform: uppercase;
                color: var(--color-muted-2);
            }
            .prep-module-statut {
                margin: 0;
                font-size: 15px;
                color: var(--color-ink);
            }
            .prep-cta {
                margin-top: 8px;
                align-self: flex-start;
                display: inline-flex;
                align-items: center;
                gap: 6px;
                font-size: 14px;
                font-weight: 600;
                color: var(--color-blue);
                text-decoration: none;
            }
        `}</style>
    );
}
