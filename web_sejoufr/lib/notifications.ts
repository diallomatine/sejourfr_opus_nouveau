// État de la page « Notifications par e-mail » (`/profil/notifications`),
// sans React : `NotificationsView.tsx` l'affiche, `notifications.test.ts` le
// vérifie. Les appels API sont injectés. Miroir mobile :
// `EmailPreferencesNotifier` + `_NotificationsScreenState`.

import type {EmailPreferences, UpdateEmailPreferencesRequest} from "./types";

export type NotifLoad =
    | { state: "loading" }
    | { state: "error" }
    | { state: "ready"; prefs: EmailPreferences };

export type NotifFeedback = "saved" | "failed" | null;

export interface NotifState {
    load: NotifLoad;
    saving: boolean;
    feedback: NotifFeedback;
}

/** Durée d'affichage de l'alerte verte « enregistré ». */
export const NOTIF_SAVED_DISMISS_MS = 3000;

export const NOTIF_INITIAL_STATE: NotifState = {load: {state: "loading"}, saving: false, feedback: null};

export async function loadEmailPreferences(
    get: () => Promise<EmailPreferences>,
): Promise<NotifState> {
    try {
        return {load: {state: "ready", prefs: await get()}, saving: false, feedback: null};
    } catch {
        return {load: {state: "error"}, saving: false, feedback: null};
    }
}

/**
 * Bascule optimiste de `engagementEnabled` : `onOptimistic` reçoit tout de
 * suite l'état basculé (envoi en cours), la promesse rend l'état final —
 * préférences du serveur + « saved », ou préférences d'avant + « failed ».
 */
export async function toggleEngagement(
    previous: EmailPreferences,
    next: boolean,
    update: (patch: UpdateEmailPreferencesRequest) => Promise<EmailPreferences>,
    onOptimistic: (state: NotifState) => void,
): Promise<NotifState> {
    onOptimistic({
        load: {state: "ready", prefs: {...previous, engagementEnabled: next}},
        saving: true,
        feedback: null,
    });
    try {
        const prefs = await update({engagementEnabled: next});
        return {load: {state: "ready", prefs}, saving: false, feedback: "saved"};
    } catch {
        return {load: {state: "ready", prefs: previous}, saving: false, feedback: "failed"};
    }
}
