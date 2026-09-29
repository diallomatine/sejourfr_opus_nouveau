"use client";

import { useEffect, useRef, useState } from "react";
import { Bell } from "lucide-react";
import { accountApi } from "@/lib/api";
import {
  COMPTE_BACK_PROFIL,
  COMPTE_NOTIF_ENGAGEMENT_LABEL,
  COMPTE_NOTIF_ENGAGEMENT_SUB,
  COMPTE_NOTIF_FOOTNOTE,
  COMPTE_NOTIF_LEAD,
  COMPTE_NOTIF_LOAD_FAILED,
  COMPTE_NOTIF_SAVE_FAILED,
  COMPTE_NOTIF_SAVED,
  COMPTE_NOTIF_TITLE,
  COMPTE_NOTIFICATIONS_HREF,
  COMPTE_PROFIL_HREF,
} from "@/lib/compte";
import {
  loadEmailPreferences,
  NOTIF_INITIAL_STATE,
  NOTIF_SAVED_DISMISS_MS,
  toggleEngagement,
  type NotifState,
} from "@/lib/notifications";
import {
  CompteAlert,
  CompteAuth,
  CompteCard,
  CompteFootnote,
  CompteLoading,
  CompteShell,
  CompteToggleRow,
} from "./CompteParts";

/**
 * « Notifications par e-mail » (`/profil/notifications`) —
 * `GET|PATCH /api/me/email-preferences`. Un seul interrupteur en V1 :
 * les e-mails d'accompagnement. Bascule optimiste, annulée si l'envoi échoue.
 * Miroir mobile : `NotificationsScreen`.
 */
export function NotificationsView() {
  return (
    <CompteAuth next={COMPTE_NOTIFICATIONS_HREF}>
      {() => (
        <CompteShell
          backHref={COMPTE_PROFIL_HREF}
          backLabel={COMPTE_BACK_PROFIL}
          title={COMPTE_NOTIF_TITLE}
          lead={COMPTE_NOTIF_LEAD}
        >
          <NotificationsBody />
        </CompteShell>
      )}
    </CompteAuth>
  );
}

function NotificationsBody() {
  const [state, setState] = useState<NotifState>(NOTIF_INITIAL_STATE);
  const savedTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    let alive = true;
    loadEmailPreferences(() => accountApi.getEmailPreferences()).then((loaded) => {
      if (alive) setState(loaded);
    });
    return () => {
      alive = false;
      if (savedTimer.current) clearTimeout(savedTimer.current);
    };
  }, []);

  const { load, saving, feedback } = state;
  if (load.state === "loading") return <CompteLoading />;
  if (load.state === "error") return <CompteAlert tone="error">{COMPTE_NOTIF_LOAD_FAILED}</CompteAlert>;

  const previous = load.prefs;

  async function toggle(next: boolean) {
    if (savedTimer.current) clearTimeout(savedTimer.current);
    const final = await toggleEngagement(
      previous,
      next,
      (patch) => accountApi.updateEmailPreferences(patch),
      setState,
    );
    setState(final);
    if (final.feedback === "saved") {
      savedTimer.current = setTimeout(
        () => setState((s) => ({ ...s, feedback: null })),
        NOTIF_SAVED_DISMISS_MS,
      );
    }
  }

  return (
    <>
      <CompteCard>
        <CompteToggleRow
          id="compte-notif-engagement"
          icon={<Bell size={20} />}
          title={COMPTE_NOTIF_ENGAGEMENT_LABEL}
          sub={COMPTE_NOTIF_ENGAGEMENT_SUB}
          checked={load.prefs.engagementEnabled}
          busy={saving}
          onChange={toggle}
        />
      </CompteCard>
      {feedback === "failed" ? <CompteAlert tone="error">{COMPTE_NOTIF_SAVE_FAILED}</CompteAlert> : null}
      {feedback === "saved" ? <CompteAlert tone="ok">{COMPTE_NOTIF_SAVED}</CompteAlert> : null}
      <CompteFootnote>{COMPTE_NOTIF_FOOTNOTE}</CompteFootnote>
    </>
  );
}
