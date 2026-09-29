"use client";

import type {ReactNode} from "react";
import {useAppBarBack} from "@/app/_components/AppBarTitle";
import {
    Card,
    ModuleToggle,
    Pad,
    PanelHead,
    ProgressIntro,
    SejourApp,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import type {ParcoursModule} from "@/lib/module-switch";
import {
    PROGRESSION_EYEBROW,
    PROGRESSION_LOADING,
    PROGRESSION_RETRY,
    progressionHref,
} from "@/lib/progression";

/**
 * Le cadre commun des quatre écrans de progression : colonne du kit, intro,
 * et la bascule de module des écrans globaux.
 *
 * 🛑 **Le retour vit dans la barre du haut**, à côté du burger qui reste
 * toujours là (demande du propriétaire, 2026-09-28) : plus de rangée « retour
 * + examen blanc » dans la page. La flèche remonte l'historique
 * (`retourOuRepli`, dans `AppTopBar`) — l'écran d'où l'on vient —, et
 * `backHref` seulement quand il n'y en a pas (lien direct, nouvel onglet).
 *
 * [module] : présent sur les deux écrans GLOBAUX seulement, il pose la bascule
 * TCF IRN / Examen civique du kit sous l'intro, comme le Plan et l'Accueil.
 * 🛑 **Des liens, pas un état local** : l'adresse (`/progression/tcf` ⇄
 * `/progression/civique`) reste l'unique autorité du choix, et `?tous=true`
 * tombe à la bascule. Les écrans d'épreuve et de thème ne la portent pas.
 */
export function ProgressionFrame({
    backHref,
    title,
    lead,
    module,
    children,
}: {
    backHref: string;
    title: string;
    lead?: string | null;
    module?: ParcoursModule;
    children: ReactNode;
}) {
    useAppBarBack({fallbackHref: backHref});
    return (
        <SejourApp wide>
            <Pad>
                <div className={sejourStyles.pScreen}>
                    <ProgressIntro eyebrow={PROGRESSION_EYEBROW} title={title} lead={lead}/>
                    {module ? (
                        <ModuleToggle
                            current={module === "CIVIQUE" ? "civique" : "tcf"}
                            tcfHref={progressionHref("TCF")}
                            civicHref={progressionHref("CIVIQUE")}
                        />
                    ) : null}
                    {children}
                </div>
            </Pad>
        </SejourApp>
    );
}

/**
 * Chargement ou échec. 🛑 **Un échec se DIT** : sans lui, une panne réseau se
 * lirait « aucun examen », c'est-à-dire un mensonge sur l'historique.
 */
export function ProgressionEtat({
    error,
    onRetry,
}: {
    error: string | null;
    /** Absent : l'échec est définitif (adresse inconnue), rien à relancer. */
    onRetry?: () => void;
}) {
    return (
        <Card className={sejourStyles.pCard}>
            {error ? (
                <>
                    <p className={sejourStyles.tiny} role="alert">{error}</p>
                    {onRetry ? (
                        <button type="button" className={sejourStyles.link} onClick={onRetry}>
                            {PROGRESSION_RETRY}
                        </button>
                    ) : null}
                </>
            ) : (
                <p className={sejourStyles.tiny}>{PROGRESSION_LOADING}</p>
            )}
        </Card>
    );
}

/** Un titre de section hors carte (« Progression par épreuve »). */
export function ProgressionSectionHead({title, sub}: {title: string; sub?: string | null}) {
    return (
        <div className={sejourStyles.pSectionHead}>
            <PanelHead title={title} sub={sub}/>
        </div>
    );
}
