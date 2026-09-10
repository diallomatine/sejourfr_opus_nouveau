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
import {ModuleToggle, type ParcoursModule} from "@/app/_components/ModuleToggle";
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

export function PlanModules() {
    const search = useSearchParams();
    const [prep, setPrep] = useState<PreparationDto | null>(null);
    /**
     * 🛑 **Le toggle ne se fait jamais attendre.** L'onglet ouvert par défaut
     * vient de l'URL quand elle le dit, sinon du TCF — et il sera corrigé dès
     * que l'état arrive. Le rendre `null` le temps du chargement laissait la
     * page sans aucune porte vers le civique : c'est une navigation, pas un
     * résultat.
     */
    const [module, setModule] = useState<ParcoursModule>(() => {
        const demande = search.get("module");
        return demande === "CIVIQUE" ? "CIVIQUE" : "TCF";
    });
    /** L'utilisateur a cliqué : son choix l'emporte sur le module par défaut. */
    const [choisi, setChoisi] = useState(false);

    useEffect(() => {
        let vivant = true;
        userContentApi
            .preparation()
            .then((p) => {
                if (!vivant) return;
                setPrep(p);
                // L'URL et un clic l'emportent tous deux sur le défaut : on ne
                // déplace jamais un onglet sous les doigts du candidat.
                const demande = search.get("module");
                if (choisi || demande === "CIVIQUE" || demande === "TCF") return;
                setModule(moduleParDefaut(p));
            })
            .catch(() => {
                // 🛑 L'échec ne masque rien : les deux onglets restent là, et le
                // plan TCF reste atteignable — il existait avant cet onglet.
            });
        return () => {
            vivant = false;
        };
    }, [search, choisi]);

    const indisponible =
        prep && module === "TCF"
            ? planIndisponible(prep.tcf, "TCF")
            : prep && module === "CIVIQUE"
              ? planIndisponible(prep.civique, "CIVIQUE")
              : null;

    return (
        <>
            {/* 🛑 **Le MÊME toggle que `/examens-blancs`**, et pas une copie :
                le composant est partagé. Deux implémentations du même contrôle
                finiraient par diverger — c'est le défaut le plus cher de ce
                dépôt. Les deux couleurs (rouge = TCF, bleu = civique) sont
                celles du produit : un candidat reconnaît son parcours à la
                couleur avant de lire le mot. */}
            <div className="plm-tabs">
                <ModuleToggle
                    active={module}
                    onChange={(m) => {
                        setChoisi(true);
                        setModule(m);
                    }}
                />
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
                /* 🛑 Le plan civique lit SA propre source (`/api/me/civic-plan`,
                   L10) : c'est un moteur, plus un echo du diagnostic. Il n'a
                   donc plus besoin du `sessionId` que cet onglet lui passait —
                   et il se tait de lui-meme tant qu'aucun diagnostic n'est
                   termine (`disponible: false`). */
                <CivicPlanPanel />
            )}

            <Styles />
        </>
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`, et ce n'est pas un oubli.**
 *
 * styled-jsx scope ses règles aux éléments rendus par **le même** composant :
 * dans un `Styles()` qui ne rend que la balise, aucun élément ne reçoit la
 * classe de scope, et **aucune règle ne s'applique**. C'est ce qui a rendu ces
 * écrans invisiblement nus — le toggle du Plan y compris.
 *
 * Le reste du dépôt utilise `<style>` global : on s'y aligne, et toutes les
 * classes sont préfixées pour qu'il n'y ait aucune collision.
 */
function Styles() {
    return (
        <style>{`
            /* La gouttiere du toggle. Le toggle lui-meme porte ses propres
               styles : il est partage avec la page des examens blancs. */
            .plm-tabs {
                width: min(100%, 1180px);
                margin: 0 auto;
                padding: 24px 28px 0;
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
