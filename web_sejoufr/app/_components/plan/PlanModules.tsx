"use client";

/**
 * **Le Plan, avec ses deux modules** : TCF IRN | Examen civique.
 *
 * 🛑 **Le Plan existe pour tout compte** (D-69, 2026-09-28) : plus aucune
 * porte « diagnostic obligatoire ». L'état servi (`userContentApi.preparation()`)
 * choisit le module affiché par défaut, et dit si le diagnostic du module est
 * fait (`diagnosticFait`) — la ligne « Mon diagnostic » n'existe qu'alors.
 *
 * 🛑 **La carte « Affinez votre plan avec le diagnostic » n'est PAS sur le
 * Plan** (2026-09-28) : elle ne vit que sur l'Accueil. Le Plan montre « À faire
 * maintenant », le jalon éventuel et le cycle.
 *
 * ## Le module sélectionné vit dans l'URL, et nulle part ailleurs
 *
 * La barre latérale (Navigation v2, 2026-10-03) porte deux entrées de Plan,
 * `/plan?module=TCF` et `/plan?module=CIVIQUE` : l'écran n'a plus de bascule
 * (X14 / « supprimer les bascules devenues inutiles »), le module vient de
 * l'URL.
 *
 * - l'URL le dit ⇒ c'est lui, quel que soit l'état serveur ;
 * - l'URL se tait ⇒ on affiche le module **servi** par `moduleParDefaut(prep)`,
 *   puis on **inscrit** cette résolution dans l'URL (`router.replace`), pour que
 *   la barre latérale sache quelle entrée marquer active. Sans ça, elle devrait
 *   refaire ce choix de son côté — une deuxième autorité sur le même fait.
 */
import {useEffect, useState} from "react";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {SejourApp} from "@/app/_components/sejour/SejourKit";
import {userContentApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {moduleDeLUrl, type ParcoursModule} from "@/lib/module-switch";
import {diagnosticFait, moduleParDefaut} from "@/lib/preparation";
import {canAccessModule, type PreparationDto} from "@/lib/types";
import {LearningPlanView} from "./LearningPlanView";
import {CivicPlanPanel} from "./CivicPlanPanel";

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
    /** L'état servi : le module par défaut, et si le diagnostic du module est
     *  fait (la ligne « Mon diagnostic » n'existe qu'à cette condition). */
    const [prep, setPrep] = useState<PreparationDto | null>(null);
    /**
     * Le module **servi** par défaut, quand l'URL ne dit rien. `null` tant que
     * `preparation()` n'a pas répondu : l'écran ouvre alors le TCF, et il sera
     * corrigé dès que l'état arrive.
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
                // 🛑 L'échec ne masque rien : le plan TCF reste affiché, et les
                // deux Plans restent atteignables par la barre latérale.
            });
        return () => {
            vivant = false;
        };
    }, []);

    /* L'URL devient canonique dès que le défaut servi est connu : la barre
       latérale lit `?module=` pour savoir quelle entrée marquer active, et elle
       n'a pas à refaire ce choix. Les autres paramètres sont **conservés** —
       `/plan` porte parfois une provenance (`withTrafficSource`). */
    useEffect(() => {
        if (demande !== null || defaut === null || pathname === null) return;
        const params = new URLSearchParams(search?.toString() ?? "");
        params.set("module", defaut);
        router.replace(`${pathname}?${params.toString()}`, {scroll: false});
    }, [demande, defaut, pathname, router, search]);

    /* La **nature** de l'écran décide de la largeur de colonne au palier
       desktop, et c'est ici qu'elle se connaît — seul endroit qui a à la fois le
       module affiché et l'accès du compte. 🛑 L'accès se **lit**
       (`canAccessModule`), il ne se devine pas.

       - compte gratuit ⇒ `sticky`, la barre d'action porte le déblocage (980) ;
       - abonné ⇒ `wide`, le Plan est un **tableau de bord** (1080). */
    const abonne = canAccessModule(user, affiche);

    return (
        <SejourApp sticky={!abonne} wide={abonne}>
            {affiche === "TCF" ? (
                <LearningPlanView diagnosticFait={diagnosticFait(prep?.tcf ?? null, "TCF")} />
            ) : (
                /* 🛑 Le plan civique lit SA propre source (`/api/me/civic-plan`,
                   L10) : c'est un moteur, plus un écho du diagnostic. */
                <CivicPlanPanel diagnosticFait={diagnosticFait(prep?.civique ?? null, "CIVIQUE")} />
            )}
        </SejourApp>
    );
}
