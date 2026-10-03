"use client";

import type {ReactNode} from "react";
import {useAppBarBack} from "@/app/_components/AppBarTitle";
import {
    Card,
    Pad,
    PanelHead,
    ProgressIntro,
    SejourApp,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {
    PROGRESSION_EYEBROW,
    PROGRESSION_LOADING,
    PROGRESSION_RETRY,
} from "@/lib/progression";

/**
 * Le cadre commun des quatre écrans de progression : colonne du kit et intro.
 *
 * 🛑 **Le retour vit dans la barre du haut**, à côté du burger qui reste
 * toujours là (demande du propriétaire, 2026-09-28) : plus de rangée « retour
 * + examen blanc » dans la page. La flèche remonte l'historique
 * (`retourOuRepli`, dans `AppTopBar`) — l'écran d'où l'on vient —, et
 * `backHref` seulement quand il n'y en a pas (lien direct, nouvel onglet).
 *
 * 🛑 **Plus de bascule TCF IRN / Examen civique** (X14, Navigation v2,
 * 2026-10-03) : la barre latérale porte une entrée « Progression » par module,
 * et l'adresse (`/progression/tcf` ⇄ `/progression/civique`) reste l'unique
 * autorité du module affiché.
 */
export function ProgressionFrame({
    backHref,
    title,
    lead,
    children,
}: {
    backHref: string;
    title: string;
    lead?: string | null;
    children: ReactNode;
}) {
    useAppBarBack({fallbackHref: backHref});
    return (
        <SejourApp wide>
            <Pad>
                <div className={sejourStyles.pScreen}>
                    <ProgressIntro eyebrow={PROGRESSION_EYEBROW} title={title} lead={lead}/>
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
