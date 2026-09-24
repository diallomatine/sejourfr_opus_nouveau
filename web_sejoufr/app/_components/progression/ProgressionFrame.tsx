"use client";

import {useState, type ReactNode} from "react";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {
    Card,
    Pad,
    PanelHead,
    ProgressIntro,
    ProgressTopbar,
    SejourApp,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {
    PROGRESSION_EYEBROW,
    PROGRESSION_LOADING,
    PROGRESSION_RETRY,
} from "@/lib/progression";

/**
 * Le cadre commun des quatre écrans de progression : colonne du kit, barre
 * haute (retour + CTA), intro, et la feuille de paywall du CTA.
 *
 * 🛑 **Le cadenas du CTA est SERVI** (`cta.locked`, D20) : tous les résultats
 * restent visibles, seul le bouton vers un nouvel examen peut ouvrir le paywall.
 * Rien n'est déduit ici d'un rang, d'un quota ou d'un abonnement.
 */
export function ProgressionFrame({
    backHref,
    backLabel,
    cta,
    title,
    lead,
    paywallModule,
    screen,
    children,
}: {
    backHref: string;
    backLabel: string;
    /** `null` tant que le serveur n'a pas répondu : pas de CTA sans son verrou. */
    cta: {label: string; href: string; locked: boolean} | null;
    title: string;
    lead?: string | null;
    paywallModule: "CIVIQUE" | "INTEGRAL";
    screen: string;
    children: ReactNode;
}) {
    const [paywall, setPaywall] = useState(false);
    return (
        <SejourApp wide>
            <Pad>
                <div className={sejourStyles.pScreen}>
                    <ProgressTopbar
                        backHref={backHref}
                        backLabel={backLabel}
                        cta={cta}
                        onLocked={() => setPaywall(true)}
                    />
                    <ProgressIntro eyebrow={PROGRESSION_EYEBROW} title={title} lead={lead}/>
                    {children}
                </div>
            </Pad>
            <PaywallSheet
                open={paywall}
                onClose={() => setPaywall(false)}
                module={paywallModule}
                ctaLocation="MOCK_EXAM"
                screen={screen}
            />
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
