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
import {useSearchParams} from "next/navigation";
import {Landmark} from "lucide-react";
import {ModuleToggle, SejourApp, TopSlot} from "@/app/_components/sejour/SejourKit";
import {userContentApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {moduleParDefaut, planIndisponible} from "@/lib/preparation";
import {canAccessModule, type PreparationDto} from "@/lib/types";
import {LearningPlanView} from "./LearningPlanView";
import {CivicPlanPanel} from "./CivicPlanPanel";
import {PlanGate} from "./PlanGate";

type ParcoursModule = "TCF" | "CIVIQUE";

export function PlanModules() {
    const search = useSearchParams();
    const {user} = useAuth();
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

    /* 🛑 L'état du module affiché, tel que le serveur le sert. La porte
       d'entrée en a besoin en entier : l'étape dit lequel des trois écrans
       rendre, et `sessionId` désigne le diagnostic rapide à relire. */
    const moduleprep = prep ? (module === "TCF" ? prep.tcf : prep.civique) : null;
    const indisponible = moduleprep ? planIndisponible(moduleprep, module) : null;

    /* La barre d'action collée en bas n'existe que sur les écrans gratuits :
       elle porte le CTA de déblocage. Sa réserve de place se pose ici, seul
       endroit qui connaît à la fois le module affiché et l'accès du compte.
       🛑 L'accès se **lit** (`canAccessModule`), il ne se devine pas. */
    const sticky = Boolean(!indisponible && !canAccessModule(user, module));

    /* 🛑 Le toggle du kit, partagé par les 7 écrans de parcours : une seconde
       implémentation du même contrôle finirait par diverger.

       🛑 **Il se pose SOUS l'en-tête de page** (eyebrow + titre), pas au-dessus
       — l'écran s'annonce, puis on choisit son parcours. Comme l'en-tête
       appartient à l'état affiché (le titre et l'eyebrow changent avec lui), le
       toggle descend par `TopSlot` : c'est `Top` qui le place, dans les sept
       variantes à la fois, sans qu'aucune ne le recopie. */
    const toggle = (
        <ModuleToggle
            current={module === "TCF" ? "tcf" : "civique"}
            onSelect={(m) => {
                setChoisi(true);
                setModule(m === "tcf" ? "TCF" : "CIVIQUE");
            }}
        />
    );

    return (
        <SejourApp sticky={sticky}>
            <TopSlot node={toggle}>
                {indisponible ? (
                    <PlanGate
                        gate={indisponible}
                        prep={moduleprep}
                        kicker={
                            module === "TCF"
                                ? "Votre parcours personnalisé"
                                : "Votre préparation personnalisée à l'Examen civique"
                        }
                        icon={module === "CIVIQUE" ? Landmark : undefined}
                    />
                ) : module === "TCF" ? (
                    /* 🛑 `prep` descend jusqu'ici : la carte « Affiner votre
                       Plan » se pose APRÈS le contenu du Plan, et elle lit les
                       faits servis (épreuves terminées, prochaine épreuve).
                       Un second appel à `preparation()` plus bas aurait pu
                       répondre autre chose que celui qui a ouvert l'écran. */
                    <LearningPlanView prep={moduleprep} />
                ) : (
                    /* 🛑 Le plan civique lit SA propre source (`/api/me/civic-plan`,
                       L10) : c'est un moteur, plus un écho du diagnostic. */
                    <CivicPlanPanel />
                )}
            </TopSlot>
        </SejourApp>
    );
}
