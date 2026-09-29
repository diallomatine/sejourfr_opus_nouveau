"use client";

import {useCallback, useState} from "react";
import {journeyApi} from "@/lib/api";
import type {ParcoursModule} from "@/lib/module-switch";
import {
    JOURNEY_JALON_BUSY,
    JOURNEY_JALON_CONFIRM_CANCEL,
    JOURNEY_JALON_CONFIRM_CTA,
    JOURNEY_JALON_CONFIRM_TITLE,
    JOURNEY_JALON_CTA,
    JOURNEY_JALON_ERROR,
    JOURNEY_JALON_TITLE,
    journeyJalonConfirmMessage,
    journeyJalonText,
} from "@/lib/journey";
import type {JourneyDto} from "@/lib/types";
import {ConfirmSheet} from "@/app/_components/hub/ConfirmSheet";
import {Card, Cta, Pad, Section, Stack, sejourStyles} from "@/app/_components/sejour/SejourKit";

/**
 * **Le jalon « Faire un examen blanc complet »** (2026-09-27, D-68) — sous la
 * carte « À faire maintenant », au-dessus du cycle.
 *
 * 🛑 **Rien n'est décidé ici** : le jalon n'apparaît que si le serveur le SERT
 * (`journey.examenComplet`), et sa phrase se lit sur la raison servie. Le geste
 * (`journeyApi.measurementCycle`) est refusé en 409 par la même autorité.
 *
 * 🛑 **Une confirmation d'abord** : le geste met de côté le cycle en cours
 * (« interrompu » dans « Mes cycles »). Puis `measurementCycle` range le cycle
 * d'examens et fait relire l'écran — le Plan affiche aussitôt ses examens.
 *
 * Composé des briques du kit (`Section`, `Card`, `Cta`), miroir de
 * `ExamenCompletJalon` côté mobile (`widgets/examen_complet_jalon.dart`).
 */
export function ExamenCompletJalon({journey, module}: {
    journey: JourneyDto | null;
    module: ParcoursModule;
}) {
    const [confirming, setConfirming] = useState(false);
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const lancer = useCallback(async () => {
        setConfirming(false);
        setError(null);
        setBusy(true);
        try {
            await journeyApi.measurementCycle(module);
        } catch {
            setError(JOURNEY_JALON_ERROR);
        } finally {
            setBusy(false);
        }
    }, [module]);

    const jalon = journey?.examenComplet ?? null;
    if (!jalon) return null;

    return (
        <Section title={JOURNEY_JALON_TITLE}>
            <Pad>
                <Card variant="soft">
                    <Stack>
                        <p className={sejourStyles.sub}>{journeyJalonText(jalon, module)}</p>
                        <Cta variant="blue" disabled={busy} onClick={() => setConfirming(true)}>
                            {busy ? JOURNEY_JALON_BUSY : JOURNEY_JALON_CTA}
                        </Cta>
                        {error && (
                            <p className={sejourStyles.tiny} role="alert">
                                {error}
                            </p>
                        )}
                    </Stack>
                </Card>
            </Pad>
            <ConfirmSheet
                open={confirming}
                tone="info"
                title={JOURNEY_JALON_CONFIRM_TITLE}
                message={journeyJalonConfirmMessage(journey?.cycle?.complete ?? false, module)}
                confirmLabel={JOURNEY_JALON_CONFIRM_CTA}
                cancelLabel={JOURNEY_JALON_CONFIRM_CANCEL}
                onConfirm={() => void lancer()}
                onClose={() => setConfirming(false)}
            />
        </Section>
    );
}
