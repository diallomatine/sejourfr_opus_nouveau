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
import type { EmailPreferences } from "@/lib/types";
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

type Load = { state: "loading" } | { state: "error" } | { state: "ready"; prefs: EmailPreferences };

function NotificationsBody() {
  const [load, setLoad] = useState<Load>({ state: "loading" });
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState<"saved" | "failed" | null>(null);
  const savedTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    let alive = true;
    accountApi
      .getEmailPreferences()
      .then((prefs) => {
        if (alive) setLoad({ state: "ready", prefs });
      })
      .catch(() => {
        if (alive) setLoad({ state: "error" });
      });
    return () => {
      alive = false;
      if (savedTimer.current) clearTimeout(savedTimer.current);
    };
  }, []);

  if (load.state === "loading") return <CompteLoading />;
  if (load.state === "error") return <CompteAlert tone="error">{COMPTE_NOTIF_LOAD_FAILED}</CompteAlert>;

  const previous = load.prefs;

  async function toggle(next: boolean) {
    if (savedTimer.current) clearTimeout(savedTimer.current);
    setFeedback(null);
    setSaving(true);
    setLoad({ state: "ready", prefs: { ...previous, engagementEnabled: next } });
    try {
      const prefs = await accountApi.updateEmailPreferences({ engagementEnabled: next });
      setLoad({ state: "ready", prefs });
      setFeedback("saved");
      savedTimer.current = setTimeout(() => setFeedback(null), 3000);
    } catch {
      setLoad({ state: "ready", prefs: previous });
      setFeedback("failed");
    } finally {
      setSaving(false);
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
