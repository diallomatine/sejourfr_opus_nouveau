"use client";

import Link from "next/link";
import { Suspense, useEffect, useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import type { AuthenticatedUser } from "@/lib/types";

export default function PaiementSuccesPage() {
  return (
    <Suspense fallback={null}>
      <SuccesInner />
    </Suspense>
  );
}

type SyncState = "syncing" | "ready" | "timeout";

/**
 * Page de retour Stripe après checkout one-shot.
 *
 * Le user revient ici (configuration "After payment → redirect" du Payment
 * Link côté dashboard Stripe). Le webhook `checkout.session.completed` est
 * envoyé en parallèle au backend, qui met à jour `hasCivique`/`hasTcf` et
 * `premiumEndsAt` sur l'utilisateur.
 *
 * Côté front, le contexte d'auth a une version périmée du user au moment du
 * retour. On déclenche un `refreshUser()` au mount, puis on poll (toutes les
 * 1,5 s, max 8 tentatives = 12 s) tant que le statut premium n'est pas
 * détecté. Si après ce délai le webhook n'est pas arrivé, on affiche un
 * message "ça arrive sous peu" — l'utilisateur peut quand même naviguer,
 * son accès sera actif au prochain reload.
 */
function SuccesInner() {
  const sp = useSearchParams();
  const { user, status, refreshUser } = useAuth();
  const sessionId = sp.get("session_id");
  // Stripe peut renseigner `plan` si on l'a mis dans le success_url du Payment
  // Link côté dashboard. Sinon on dérive du statut user après refresh.
  const planParam = sp.get("plan");

  // `timedOut` est le seul state interne — `syncState` est dérivé de
  // `isPremium(user)` + `timedOut` pour rester en sync avec le contexte
  // d'auth sans cascading renders (cf react-hooks/set-state-in-effect).
  const [timedOut, setTimedOut] = useState(false);
  const synced = isPremium(user);
  const syncState: SyncState = synced ? "ready" : timedOut ? "timeout" : "syncing";
  const attemptsRef = useRef(0);

  // Boucle de polling : on refresh tant que le statut premium n'est pas
  // détecté, max 8 tentatives × 1,5 s = 12 s avant d'afficher le message
  // "ça arrivera dans la minute".
  useEffect(() => {
    if (status !== "authenticated") return;
    if (synced) return; // déjà premium, plus rien à faire

    let stopped = false;
    const MAX_ATTEMPTS = 8;
    const INTERVAL_MS = 1500;

    const tick = async () => {
      if (stopped) return;
      attemptsRef.current += 1;
      try {
        await refreshUser();
      } catch {
        // ignore : le polling continue tant que MAX_ATTEMPTS n'est pas atteint
      }
    };

    void tick();

    const id = window.setInterval(() => {
      if (attemptsRef.current >= MAX_ATTEMPTS) {
        window.clearInterval(id);
        if (!stopped) setTimedOut(true);
        return;
      }
      void tick();
    }, INTERVAL_MS);

    return () => {
      stopped = true;
      window.clearInterval(id);
    };
  }, [status, refreshUser, synced]);

  if (status === "loading") {
    return <div className="succes-loading" />;
  }

  if (!user) {
    return (
      <main className="succes">
        <div className="succes-card">
          <h1>Votre paiement a été reçu</h1>
          <p className="succes-sub">
            Connectez-vous pour finaliser l&apos;activation de votre abonnement.
          </p>
          <Link href="/connexion?next=/paiement/succes" className="btn btn-blue">
            Se connecter
          </Link>
        </div>
        <style>{styles}</style>
      </main>
    );
  }

  const planLabel = derivePlanLabel(user, planParam);
  const showSyncing = syncState === "syncing";
  const showTimeout = syncState === "timeout" && !isPremium(user);

  return (
    <main className="succes">
      <div className="succes-card">
        <div className={`succes-icon ${showSyncing ? "is-syncing" : ""}`} aria-hidden>
          {showSyncing ? (
            <span className="succes-spinner" />
          ) : (
            <svg viewBox="0 0 24 24" fill="none">
              <path
                d="M20 6 9 17l-5-5"
                stroke="currentColor"
                strokeWidth="3"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          )}
        </div>

        <span className="eyebrow">
          {showSyncing ? "Activation en cours" : "Paiement confirmé"}
        </span>
        <h1>
          {showSyncing ? (
            <>Activation de votre <em>{planLabel}</em>…</>
          ) : showTimeout ? (
            <>Paiement reçu — <em>activation en cours</em></>
          ) : (
            <>Bienvenue dans <em>{planLabel}</em>.</>
          )}
        </h1>
        <p className="succes-sub">
          {showSyncing
            ? "Stripe nous notifie l'activation, ça prend quelques secondes. Ne fermez pas cette page."
            : showTimeout
              ? "Votre paiement est validé côté Stripe. La synchronisation côté SejourFR peut prendre une ou deux minutes — votre accès s'ouvrira automatiquement. Vous pouvez naviguer ou revenir sur cette page plus tard."
              : `${user.firstName ? `${user.firstName}, votre` : "Votre"} abonnement est actif. Vous avez maintenant accès à ${
                  user.hasTcf
                    ? "tout le contenu : Civique + TCF IRN, examens blancs illimités, révision des erreurs"
                    : "tout le contenu civique : 1 200+ questions, examens blancs illimités, révision des erreurs"
                }.`}
        </p>

        {!showSyncing && !showTimeout && (
          <div className="succes-next">
            <h2>Et maintenant ?</h2>
            <ol>
              <li>
                <strong>Lancez votre premier entraînement complet</strong>
                {" "}— maintenant que vous êtes abonné, l&apos;entraînement est
                illimité par thème.
              </li>
              <li>
                <strong>Passez un examen blanc en conditions réelles</strong>
                {" "}— chronomètre, pas de correction live, score officiel à la fin.
              </li>
              <li>
                <strong>Suivez votre progression</strong> sur{" "}
                <Link href="/statistiques">/statistiques</Link> et révisez vos
                erreurs sur <Link href="/revision">/revision</Link>.
              </li>
            </ol>
          </div>
        )}

        <div className="succes-actions">
          {!showSyncing && (
            <>
              <Link href="/entrainement" className="btn btn-red btn-lg">
                Lancer un entraînement
              </Link>
              <Link href="/dashboard" className="btn btn-ghost">
                Tableau de bord
              </Link>
            </>
          )}
        </div>

        {(sessionId || planParam) && (
          <p className="succes-meta">
            {sessionId && (
              <>Référence transaction&nbsp;: <code>{sessionId}</code></>
            )}
          </p>
        )}
      </div>

      <style>{styles}</style>
    </main>
  );
}

function isPremium(user: AuthenticatedUser | null): boolean {
  if (!user) return false;
  return Boolean(user.hasCivique || user.hasTcf);
}

/**
 * Libellé du plan acquis : on privilégie le query param Stripe (`plan=...`)
 * s'il est passé dans le success_url, sinon on dérive du statut user actuel.
 */
function derivePlanLabel(user: AuthenticatedUser, planParam: string | null): string {
  if (planParam === "INTEGRAL_3MOIS") return "Intégral";
  if (planParam === "CIVIQUE_3MOIS") return "Civique";
  if (user.hasTcf) return "Intégral";
  if (user.hasCivique) return "Civique";
  return "Premium";
}

const styles = `
  .succes-loading { min-height: 60vh; }

  .succes {
    max-width: 720px; margin: 0 auto;
    padding: 64px 28px 80px;
  }
  .succes-card {
    background: #fff; border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 48px 44px 40px;
    text-align: center;
    box-shadow: 0 30px 70px -30px rgba(15, 24, 57, 0.18);
  }
  .succes-icon {
    width: 64px; height: 64px;
    border-radius: 50%;
    background: rgba(22, 143, 91, 0.12);
    color: var(--color-green);
    display: flex; align-items: center; justify-content: center;
    margin: 0 auto 18px;
    transition: background 0.3s, color 0.3s;
  }
  .succes-icon.is-syncing {
    background: var(--color-blue-light);
    color: var(--color-blue);
  }
  .succes-icon svg { width: 30px; height: 30px; }
  .succes-spinner {
    width: 28px; height: 28px;
    border: 3px solid rgba(30, 58, 140, 0.18);
    border-top-color: var(--color-blue);
    border-radius: 50%;
    animation: succes-spin 0.9s linear infinite;
  }
  @keyframes succes-spin { to { transform: rotate(360deg); } }

  .succes h1 {
    font-family: var(--font-display); font-weight: 500; font-size: clamp(28px, 4vw, 40px);
    line-height: 1.05; letter-spacing: -0.025em;
    margin: 12px 0 14px;
  }
  .succes h1 em { font-style: italic; color: var(--color-red); }

  .succes-sub {
    color: var(--color-muted); font-size: 16px;
    margin: 0 auto 32px; max-width: 520px;
    line-height: 1.55;
  }

  .succes-next {
    background: var(--color-paper); border-radius: 14px;
    padding: 28px 32px; text-align: left;
    margin-bottom: 28px;
  }
  .succes-next h2 {
    font-family: var(--font-sans); font-weight: 700; font-size: 13px;
    letter-spacing: 0.08em; text-transform: uppercase;
    color: var(--color-muted);
    margin: 0 0 16px;
  }
  .succes-next ol {
    list-style: none; padding: 0; margin: 0;
    counter-reset: succes-step;
  }
  .succes-next li {
    counter-increment: succes-step;
    padding: 14px 0 16px 44px;
    border-bottom: 1px solid var(--color-line-2);
    position: relative;
    font-size: 14.5px; line-height: 1.55; color: var(--color-ink-2);
  }
  .succes-next li:last-child { border-bottom: none; }
  .succes-next li::before {
    content: counter(succes-step);
    position: absolute; left: 0; top: 12px;
    width: 28px; height: 28px;
    background: var(--color-blue); color: #fff;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: 13px; font-weight: 700;
  }
  .succes-next li strong { color: var(--color-ink); font-weight: 600; }
  .succes-next li a {
    color: var(--color-blue); text-decoration: none;
    font-family: var(--font-mono); font-size: 13px;
  }
  .succes-next li a:hover { text-decoration: underline; }

  .succes-actions {
    display: flex; gap: 10px; justify-content: center; flex-wrap: wrap;
    margin-bottom: 20px;
    min-height: 4px;
  }
  .succes-meta {
    font-family: var(--font-mono); font-size: 11px;
    letter-spacing: 0.08em; color: var(--color-muted);
    margin: 0;
  }
  .succes-meta code {
    background: var(--color-paper);
    padding: 2px 6px; border-radius: 4px;
    color: var(--color-ink-2);
  }

  @media (max-width: 560px) {
    .succes { padding: 28px 16px 60px; }
    .succes-card { padding: 32px 24px 28px; }
    .succes-next { padding: 22px 20px; }
    .succes-next li { padding-left: 38px; }
  }
`;
