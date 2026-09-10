"use client";

/**
 * **Le Plan, avec ses deux modules** : TCF IRN | Examen civique.
 *
 * 🛑 **C'est la DEUXIÈME des trois portes** vers un diagnostic inachevé
 * (Accueil, Plan, Examens). Elle lit `userContentApi.preparation()`, le **même**
 * état que les deux autres — c'est ce qui garantit que le candidat ne se voit
 * pas proposer trois choses différentes selon l'écran où il arrive.
 *
 * 🛑 **Le contenu d'un onglet dépend de l'état de SON module.** Tant que le
 * diagnostic qui construit le plan n'est pas fait, l'onglet explique pourquoi
 * et ouvre la seule porte qui débloque — jamais un plan vide, jamais un plan
 * bâti sur une mesure qui n'existe pas.
 *
 * 🛑 **Asymétrie assumée** : le plan TCF attend le diagnostic *complet* (le
 * rapide n'observe qu'une production écrite) ; le plan civique attend son
 * diagnostic unique.
 */
import {useEffect, useState} from "react";
import Link from "next/link";
import {useSearchParams} from "next/navigation";
import {ArrowRight} from "lucide-react";
import {userContentApi} from "@/lib/api";
import {
    CIVIQUE_LABEL,
    TCF_LABEL,
    moduleParDefaut,
    planIndisponible,
} from "@/lib/preparation";
import type {PreparationDto} from "@/lib/types";
import {LearningPlanView} from "./LearningPlanView";
import {CivicPlanPanel} from "./CivicPlanPanel";

type ModuleKey = "TCF" | "CIVIQUE";

export function PlanModules() {
    const search = useSearchParams();
    const [prep, setPrep] = useState<PreparationDto | null>(null);
    const [module, setModule] = useState<ModuleKey | null>(null);

    useEffect(() => {
        let vivant = true;
        userContentApi
            .preparation()
            .then((p) => {
                if (!vivant) return;
                setPrep(p);
                // L'URL l'emporte (le résultat du diagnostic civique y renvoie),
                // sinon on ouvre sur le module qui a quelque chose à dire.
                const demande = search.get("module");
                setModule(
                    demande === "CIVIQUE" || demande === "TCF"
                        ? demande
                        : moduleParDefaut(p),
                );
            })
            .catch(() => {
                // 🛑 L'échec ne masque pas le plan TCF : il existait avant cet
                // onglet et doit rester atteignable.
                if (vivant) setModule("TCF");
            });
        return () => {
            vivant = false;
        };
    }, [search]);

    if (module === null) return null;

    const indisponible =
        prep && module === "TCF"
            ? planIndisponible(prep.tcf, "TCF")
            : prep && module === "CIVIQUE"
              ? planIndisponible(prep.civique, "CIVIQUE")
              : null;

    return (
        <>
            <div className="plm-tabs" role="tablist" aria-label="Module de préparation">
                <button
                    type="button"
                    role="tab"
                    aria-selected={module === "TCF"}
                    className={module === "TCF" ? "plm-tab-on" : "plm-tab"}
                    onClick={() => setModule("TCF")}
                >
                    {TCF_LABEL}
                </button>
                <button
                    type="button"
                    role="tab"
                    aria-selected={module === "CIVIQUE"}
                    className={module === "CIVIQUE" ? "plm-tab-on" : "plm-tab"}
                    onClick={() => setModule("CIVIQUE")}
                >
                    {CIVIQUE_LABEL}
                </button>
            </div>

            {indisponible ? (
                <section className="plm-vide">
                    <h2>{indisponible.titre}</h2>
                    <p>{indisponible.texte}</p>
                    <Link href={indisponible.href} className="btn btn-lg">
                        {indisponible.cta} <ArrowRight size={16} aria-hidden />
                    </Link>
                </section>
            ) : module === "TCF" ? (
                <LearningPlanView />
            ) : (
                <CivicPlanPanel />
            )}

            <Styles />
        </>
    );
}

function Styles() {
    return (
        <style jsx>{`
            .plm-tabs {
                display: flex;
                gap: 8px;
                max-width: 560px;
                margin: 0 auto 16px;
                padding: 0 16px;
            }
            .plm-tab,
            .plm-tab-on {
                flex: 1;
                border: 1px solid var(--color-line);
                background: transparent;
                border-radius: 999px;
                padding: 9px 14px;
                font-size: 14px;
                font-weight: 600;
                color: var(--color-muted);
                cursor: pointer;
            }
            .plm-tab-on {
                border-color: var(--color-blue);
                color: var(--color-blue);
                background: var(--color-blue-light);
            }
            .plm-vide {
                max-width: 480px;
                margin: 0 auto;
                padding: 8px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 12px;
                text-align: center;
            }
            .plm-vide h2 {
                font-family: var(--font-display);
                font-size: 22px;
                color: var(--color-ink);
                margin: 0;
            }
            .plm-vide p {
                margin: 0;
                font-size: 14px;
                line-height: 1.55;
                color: var(--color-muted);
            }
        `}</style>
    );
}
