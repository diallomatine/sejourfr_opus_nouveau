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
 *
 * ## Le module sélectionné vit dans l'URL, et nulle part ailleurs (2026-09-12)
 *
 * Arbitrage du propriétaire : la bascule de la **barre latérale** navigue entre
 * les deux modules du Plan quand on est sur le Plan, et la bascule **de
 * l'écran** disparaît en desktop pour ne pas faire doublon. Les deux contrôles
 * doivent donc s'entendre sur « quel module est affiché » — d'où **un seul
 * mécanisme de sélection** : le paramètre `?module=`.
 *
 * - l'URL le dit ⇒ c'est lui, quel que soit l'état serveur ;
 * - l'URL se tait ⇒ on affiche le module **servi** par `moduleParDefaut(prep)`,
 *   puis on **inscrit** cette résolution dans l'URL (`router.replace`), pour que
 *   la barre latérale sache quel côté marquer actif. Sans ça, elle devrait
 *   refaire ce choix de son côté — une deuxième autorité sur le même fait.
 *
 * Conséquence : la bascule de l'écran est un **lien**, pas un état local. Elle
 * fait ce que fait celle du rail, elle n'a plus son propre `useState`.
 */
import {useEffect, useState} from "react";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Landmark} from "lucide-react";
import {ModuleToggle, SejourApp, TopSlot} from "@/app/_components/sejour/SejourKit";
import {userContentApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {moduleDeLUrl, planHref, type ParcoursModule} from "@/lib/module-switch";
import {moduleParDefaut, planIndisponible} from "@/lib/preparation";
import {canAccessModule, type PreparationDto} from "@/lib/types";
import {LearningPlanView} from "./LearningPlanView";
import {CivicPlanPanel} from "./CivicPlanPanel";
import {PlanGate} from "./PlanGate";

export function PlanModules() {
    /* 🛑 **Changer d'écran ou de parcours ne coûte AUCUN appel** (2026-09-12).
       Les deux panneaux lisent leur plan **en cache** (`getCached`) : la
       bascule démonte l'un et monte l'autre, et chaque montage rappelait son
       endpoint — pour une réponse identique, puisque ni le plan TCF ni le plan
       civique ne dépendent de l'onglet ouvert.

       ⚠️ **Révoque** « `/plan` lit directement le serveur pour ne pas figer une
       analyse asynchrone » : la fraîcheur ne se joue plus à l'arrivée sur
       l'écran mais aux **écritures**, dans `invalidateDiagnosticAndPlan`
       (`lib/api.ts`), qui vide diagnostic, plans, préparation et progrès
       ensemble — à la fin d'une analyse de diagnostic, d'une production, d'une
       tentative de compétence et au lancement d'une série civique. Une passe
       intermédiaire vidait les caches à chaque montage de cet écran : elle
       rendait la bascule gratuite mais laissait un appel par visite. */

    const search = useSearchParams();
    const pathname = usePathname();
    const router = useRouter();
    const {user} = useAuth();
    const [prep, setPrep] = useState<PreparationDto | null>(null);
    /**
     * Le module **servi** par défaut, quand l'URL ne dit rien. `null` tant que
     * `preparation()` n'a pas répondu.
     *
     * 🛑 **Le toggle ne se fait jamais attendre** : en attendant cette réponse
     * l'écran ouvre le TCF, et il sera corrigé dès que l'état arrive. Rendre
     * `null` le temps du chargement laissait la page sans aucune porte vers le
     * civique : c'est une navigation, pas un résultat.
     */
    const [defaut, setDefaut] = useState<ParcoursModule | null>(null);

    const demande = moduleDeLUrl(search);
    const affiche: ParcoursModule = demande ?? defaut ?? "TCF";

    useEffect(() => {
        let vivant = true;
        userContentApi
            .preparation()
            .then((p) => {
                if (!vivant) return;
                setPrep(p);
                setDefaut(moduleParDefaut(p));
            })
            .catch(() => {
                // 🛑 L'échec ne masque rien : les deux onglets restent là, et le
                // plan TCF reste atteignable — il existait avant cet onglet.
            });
        return () => {
            vivant = false;
        };
    }, []);

    /* L'URL devient canonique dès que le défaut servi est connu : la barre
       latérale lit `?module=` pour savoir quel côté marquer actif, et elle n'a
       pas à refaire ce choix. Les autres paramètres sont **conservés** —
       `/plan` porte parfois une provenance (`withTrafficSource`). */
    useEffect(() => {
        if (demande !== null || defaut === null || pathname === null) return;
        const params = new URLSearchParams(search?.toString() ?? "");
        params.set("module", defaut);
        router.replace(`${pathname}?${params.toString()}`, {scroll: false});
    }, [demande, defaut, pathname, router, search]);

    /* 🛑 L'état du module affiché, tel que le serveur le sert. La porte
       d'entrée en a besoin en entier : l'étape dit lequel des trois écrans
       rendre, et `sessionId` désigne le diagnostic rapide à relire. */
    const moduleprep = prep ? (affiche === "TCF" ? prep.tcf : prep.civique) : null;
    const indisponible = moduleprep ? planIndisponible(moduleprep, affiche) : null;

    /* La **nature** de l'écran décide de la largeur de colonne au palier
       desktop, et c'est ici qu'elle se connaît — seul endroit qui a à la fois le
       module affiché et l'accès du compte. 🛑 L'accès se **lit**
       (`canAccessModule`), il ne se devine pas.

       - porte d'entrée ⇒ `report` : conteneur de 980 px, texte à 720 px. Elle
         encastre le RAPPORT du diagnostic rapide, avec ses deux grilles — elle
         doit donc lui offrir exactement la largeur que `/diagnostic` lui
         offre, sinon le même rapport se range de deux façons selon la porte par
         laquelle le candidat arrive. Sa forme minimale (l'explication et son
         geste, sans rapport) ne porte aucune grille : tout y reste plafonné à
         720 px, donc elle se rend comme avant ;
       - compte gratuit ⇒ `sticky`, la barre d'action porte le déblocage (980) ;
       - abonné ⇒ `wide`, le Plan est un **tableau de bord** (1080). */
    const abonne = canAccessModule(user, affiche);
    const sticky = Boolean(!indisponible && !abonne);
    const wide = Boolean(!indisponible && abonne);
    const report = Boolean(indisponible);

    /* 🛑 Le toggle du kit, partagé par les 7 écrans de parcours : une seconde
       implémentation du même contrôle finirait par diverger.

       🛑 **Il se pose SOUS l'en-tête de page** (eyebrow + titre), pas au-dessus
       — l'écran s'annonce, puis on choisit son parcours. Comme l'en-tête
       appartient à l'état affiché (le titre et l'eyebrow changent avec lui), le
       toggle descend par `TopSlot` : c'est `Top` qui le place, dans les sept
       variantes à la fois, sans qu'aucune ne le recopie.

       🛑 **Des liens, pas un état local** : c'est la même destination que la
       bascule du rail, donc le même mécanisme. Le kit masque ce toggle dès que
       le rail est visible (≥ 901 px) — une seule bascule à l'écran. */
    const toggle = (
        <ModuleToggle
            current={affiche === "TCF" ? "tcf" : "civique"}
            tcfHref={planHref("TCF")}
            civicHref={planHref("CIVIQUE")}
        />
    );

    return (
        <SejourApp sticky={sticky} wide={wide} report={report}>
            <TopSlot node={toggle}>
                {indisponible ? (
                    <PlanGate
                        gate={indisponible}
                        prep={moduleprep}
                        kicker={
                            affiche === "TCF"
                                ? "Votre parcours personnalisé"
                                : "Votre préparation personnalisée à l'Examen civique"
                        }
                        icon={affiche === "CIVIQUE" ? Landmark : undefined}
                    />
                ) : affiche === "TCF" ? (
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
