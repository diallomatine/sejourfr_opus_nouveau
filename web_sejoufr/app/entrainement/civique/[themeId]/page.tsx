"use client";

import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { ApiException, attemptApi, lotApi, themeApi, userContentApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { canAccessModule } from "@/lib/types";
import type {
  AttemptSummaryResponse,
  LotDto,
  QuestionReviewResponse,
} from "@/lib/types";
import { DualChromeShell } from "@/app/_components/DualChromeShell";
import { QuestionDetailModal } from "@/app/_components/QuestionDetailModal";
import { PaywallSheet } from "@/app/_components/PaywallSheet";

type Tab = "lots" | "examens" | "erreurs";
const EXAM_SLOTS = 10;

export default function CiviqueThemeDetailPage() {
  const params = useParams<{ themeId: string }>();
  const themeId = params?.themeId ?? "";
  const router = useRouter();
  const { user, status } = useAuth();

  const [tab, setTab] = useState<Tab>("lots");
  const [themeName, setThemeName] = useState("Thème civique");
  const [lots, setLots] = useState<LotDto[]>([]);
  const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
  const [errors, setErrors] = useState<QuestionReviewResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedQuestion, setSelectedQuestion] = useState<QuestionReviewResponse | null>(null);
  const [paywallOpen, setPaywallOpen] = useState(false);

  const isPremium = user ? canAccessModule(user, "CIVIQUE") : false;

  useEffect(() => {
    if (status !== "authenticated" || !themeId) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    Promise.allSettled([
      themeApi.list("CIVIQUE"),
      lotApi.listCivique(themeId),
      attemptApi.listMine({ type: "MOCK_EXAM", module: "CIVIQUE", themeId, limit: 30 }),
      userContentApi.wrong("CIVIQUE", themeId),
    ]).then(([t, l, e, w]) => {
      if (cancelled) return;
      if (t.status === "fulfilled") {
        const found = t.value.find((x) => x.id === themeId);
        if (found) setThemeName(found.name);
      }
      if (l.status === "fulfilled") setLots(l.value);
      if (e.status === "fulfilled") {
        setExams(
          e.value
            .filter((a) => a.finishedAt)
            .sort((a, b) => a.startedAt.localeCompare(b.startedAt)),
        );
      }
      if (w.status === "fulfilled") setErrors(w.value);
      setLoading(false);
    });
    return () => {
      cancelled = true;
    };
  }, [status, themeId]);

  async function startLot(lot: LotDto) {
    if (starting) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "TRAINING",
        module: "CIVIQUE",
        themeId,
        lotNumero: lot.numero,
      });
      router.push(`/sessions/${a.id}?lot=${lot.numero}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer le lot.");
      setStarting(false);
    }
  }

  async function startThemeExam() {
    if (starting) return;
    setError(null);
    setStarting(true);
    try {
      const a = await attemptApi.start({
        type: "MOCK_EXAM",
        module: "CIVIQUE",
        themeId,
      });
      router.push(`/sessions/${a.id}`);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setStarting(false);
    }
  }

  const examSlots = useMemo(
    () => Array.from({ length: EXAM_SLOTS }, (_, i) => exams[i] ?? null),
    [exams],
  );

  if (status === "loading") return <div className="ctd-gate" />;
  if (!user) {
    return (
      <main className="ctd-gate">
        <p>Connectez-vous pour accéder à ce thème.</p>
        <Link href={`/connexion?next=/entrainement/civique/${themeId}`} className="ctd-gate-cta">
          Se connecter →
        </Link>
        <style>{styles}</style>
      </main>
    );
  }

  return (
    <DualChromeShell>
    <main className="ctd">
      <div className="ctd-breadcrumb">
        <Link href="/entrainement?module=CIVIQUE">Entraînement</Link>
        <span className="sep">/</span> Examen civique <span className="sep">/</span>{" "}
        <strong>{themeName}</strong>
      </div>

      <header className="ctd-hero">
        <span className="ctd-eyebrow">Thème civique</span>
        <h1>{themeName}</h1>
        <p>Travaille ce thème par lots, passe des examens ciblés et revois tes erreurs.</p>
      </header>

      <div className="ctd-tabs" role="tablist">
        <button type="button" role="tab" aria-selected={tab === "lots"} className={`ctd-tab ${tab === "lots" ? "is-active" : ""}`} onClick={() => setTab("lots")}>Lots</button>
        <button type="button" role="tab" aria-selected={tab === "examens"} className={`ctd-tab ${tab === "examens" ? "is-active" : ""}`} onClick={() => setTab("examens")}>Examens</button>
        <button type="button" role="tab" aria-selected={tab === "erreurs"} className={`ctd-tab ${tab === "erreurs" ? "is-active" : ""}`} onClick={() => setTab("erreurs")}>
          Erreurs{errors.length > 0 ? ` (${errors.length})` : ""}
        </button>
      </div>

      {error && <div className="form-error ctd-error">{error}</div>}

      {/* ---- LOTS ---- */}
      {tab === "lots" && (
        loading ? (
          <SkeletonGrid />
        ) : lots.length === 0 ? (
          <p className="ctd-empty">Aucun lot disponible pour ce thème pour l&apos;instant.</p>
        ) : (
          <section className="ctd-grid">
            {lots.map((lot) => (
              <button
                type="button"
                key={lot.numero}
                className={`ctd-lot ${lot.lastScore != null ? "is-done" : ""}`}
                onClick={() => startLot(lot)}
                disabled={starting}
              >
                <div className="ctd-lot-head">
                  <span className="ctd-lot-num">Lot {lot.numero}</span>
                  {lot.lastScore != null && (
                    <span className="ctd-lot-score">{lot.lastScore}/{lot.totalQuestions}</span>
                  )}
                </div>
                <p className="ctd-lot-meta">{lot.totalQuestions} questions</p>
                <span className="ctd-lot-cta">
                  {starting ? "…" : lot.lastScore != null ? "Refaire →" : "Commencer →"}
                </span>
              </button>
            ))}
          </section>
        )
      )}

      {/* ---- EXAMENS ---- */}
      {tab === "examens" && (
        <section>
          <p className="ctd-intro">
            Examen ciblé sur ce thème : <strong>20 questions</strong> · 20 min · seuil de réussite 16/20.
          </p>
          {loading ? (
            <SkeletonGrid />
          ) : (
            <div className="ctd-grid">
              {examSlots.map((ex, i) => {
                const slot = i + 1;
                if (ex) {
                  const ok = ex.passThreshold != null && (ex.score ?? 0) >= ex.passThreshold;
                  return (
                    <Link key={ex.id} href={`/sessions/${ex.id}`} className="ctd-exam is-done">
                      <div className="ctd-exam-head">
                        <span className="ctd-lot-num">Examen {slot}</span>
                        <span className={`ctd-exam-badge ${ok ? "ok" : "ko"}`}>
                          {ex.score ?? 0}/{ex.totalQuestions ?? 20}
                        </span>
                      </div>
                      <p className="ctd-lot-meta">{ok ? "Réussi" : "Sous le seuil"}</p>
                      <span className="ctd-lot-cta">Voir →</span>
                    </Link>
                  );
                }
                // Parité Flutter : un abonné peut lancer n'importe quel slot
                // vide ; en gratuit seul le slot 1 est ouvert (2+ → paywall).
                const locked = !isPremium && slot > 1;
                return (
                  <button
                    type="button"
                    key={`slot-${slot}`}
                    className={`ctd-exam ${locked ? "is-locked" : "is-next"}`}
                    onClick={locked ? () => setPaywallOpen(true) : startThemeExam}
                    disabled={locked ? false : starting}
                  >
                    <div className="ctd-exam-head">
                      <span className="ctd-lot-num">Examen {slot}</span>
                      {locked && <span className="ctd-lock-chip">Premium</span>}
                    </div>
                    <p className="ctd-lot-meta">{locked ? "Réservé aux abonnés" : "À passer"}</p>
                    <span className="ctd-lot-cta">
                      {locked ? "Débloquer →" : starting ? "…" : "Commencer →"}
                    </span>
                  </button>
                );
              })}
            </div>
          )}
        </section>
      )}

      {/* ---- ERREURS ---- */}
      {tab === "erreurs" && (
        loading ? (
          <SkeletonGrid />
        ) : errors.length === 0 ? (
          <p className="ctd-empty">Aucune erreur sur ce thème — beau parcours&nbsp;!</p>
        ) : (
          <section className="ctd-errlist">
            {errors.map((q) => (
              <button
                type="button"
                key={q.id}
                className="ctd-err"
                onClick={() => setSelectedQuestion(q)}
              >
                <span className="ctd-err-chip">{q.difficulty}</span>
                <p>{q.statement}</p>
                <span className="ctd-err-arrow" aria-hidden>›</span>
              </button>
            ))}
            <Link href="/revision?tab=erreurs" className="ctd-err-cta">
              Retravailler mes erreurs →
            </Link>
          </section>
        )
      )}

      {selectedQuestion && (
        <QuestionDetailModal
          question={selectedQuestion}
          onClose={() => setSelectedQuestion(null)}
        />
      )}
      <PaywallSheet
        open={paywallOpen}
        onClose={() => setPaywallOpen(false)}
        module="CIVIQUE"
      />

      <style>{styles}</style>
    </main>
    </DualChromeShell>
  );
}

function SkeletonGrid() {
  return (
    <div className="ctd-grid">
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <div key={i} className="ctd-skel" />
      ))}
      <style>{`
        .ctd-skel { height: 110px; border-radius: 14px;
          background: linear-gradient(90deg, #EEF0F8 25%, #F6F7FB 50%, #EEF0F8 75%);
          background-size: 200% 100%; animation: ctd-sh 1.3s ease-in-out infinite; }
        @keyframes ctd-sh { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }
      `}</style>
    </div>
  );
}

const styles = `
  .ctd { padding: 24px 36px 64px; max-width: 1100px; margin: 0 auto; }
  @media (max-width: 760px) { .ctd { padding: 20px 16px 56px; } }
  .ctd-gate {
    min-height: 60vh; display: flex; flex-direction: column; align-items: center;
    justify-content: center; gap: 14px; color: var(--color-muted); padding: 36px;
  }
  .ctd-gate-cta { color: var(--color-blue); font-weight: 700; }

  .ctd-breadcrumb {
    font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.1em;
    text-transform: uppercase; color: var(--color-muted); margin-bottom: 16px;
  }
  .ctd-breadcrumb a { color: var(--color-blue); }
  .ctd-breadcrumb .sep { margin: 0 6px; opacity: 0.5; }
  .ctd-breadcrumb strong { color: var(--color-ink); }

  .ctd-hero {
    background: linear-gradient(135deg, var(--color-blue) 0%, #3355B5 100%);
    color: #fff; border-radius: 20px; padding: 28px; margin-bottom: 22px;
  }
  .ctd-eyebrow { font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; color: rgba(255,255,255,0.7); }
  .ctd-hero h1 { font-family: var(--font-display); font-weight: 600; font-size: clamp(24px,4vw,32px); letter-spacing: -0.02em; margin: 8px 0 0; }
  .ctd-hero p { color: rgba(255,255,255,0.82); font-size: 14.5px; line-height: 1.55; margin: 10px 0 0; max-width: 540px; }

  .ctd-tabs { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; margin-bottom: 18px; }
  .ctd-tab {
    border: 1px solid var(--color-line); background: #fff; padding: 12px;
    border-radius: 12px; font-family: var(--font-sans); font-size: 14px; font-weight: 600;
    color: var(--color-muted); cursor: pointer; text-align: center;
    transition: background 0.15s, color 0.15s, border-color 0.15s;
  }
  .ctd-tab:hover { border-color: var(--color-blue); color: var(--color-blue); }
  .ctd-tab.is-active { background: var(--color-blue-soft); color: var(--color-blue); border-color: var(--color-blue); }

  .ctd-error { margin-bottom: 16px; }
  .ctd-empty { color: var(--color-muted); font-size: 14.5px; padding: 24px 0; }
  .ctd-intro { color: var(--color-muted); font-size: 14px; margin: 0 0 16px; }
  .ctd-intro strong { color: var(--color-ink); }

  .ctd-grid { display: grid; grid-template-columns: 1fr; gap: 12px; }

  .ctd-lot, .ctd-exam {
    text-align: left; background: #fff; border: 1px solid var(--color-line);
    border-radius: 14px; padding: 16px; cursor: pointer; text-decoration: none;
    font-family: inherit; display: flex; flex-direction: column; gap: 6px;
    transition: transform 0.18s, box-shadow 0.18s, border-color 0.18s;
  }
  .ctd-lot:hover:not(:disabled), .ctd-exam.is-next:hover, .ctd-exam.is-done:hover {
    transform: translateY(-2px); border-color: var(--color-blue);
    box-shadow: 0 14px 32px -20px rgba(30,58,140,0.3);
  }
  .ctd-lot:disabled { opacity: 0.6; cursor: not-allowed; }
  .ctd-lot.is-done { background: var(--color-blue-soft); }
  .ctd-lot-head, .ctd-exam-head { display: flex; align-items: center; justify-content: space-between; }
  .ctd-lot-num { font-family: var(--font-sans); font-weight: 700; font-size: 15px; color: var(--color-ink); }
  .ctd-lot-score, .ctd-exam-badge {
    font-family: var(--font-mono); font-size: 12px; font-weight: 700;
    padding: 3px 9px; border-radius: 100px;
  }
  .ctd-lot-score { background: var(--color-blue-light); color: var(--color-blue-dark); }
  .ctd-exam-badge.ok { background: rgba(22,143,91,0.14); color: var(--color-green); }
  .ctd-exam-badge.ko { background: var(--color-red-light); color: var(--color-red); }
  .ctd-lot-meta { font-size: 13px; color: var(--color-muted); margin: 0; }
  .ctd-lot-cta { font-size: 13px; font-weight: 700; color: var(--color-blue); }

  .ctd-exam.is-locked { border-style: dashed; }
  .ctd-exam.is-next { border-color: var(--color-blue); border-style: dashed; }
  .ctd-lock-chip {
    font-family: var(--font-mono); font-size: 9.5px; font-weight: 700;
    letter-spacing: 0.1em; text-transform: uppercase;
    padding: 3px 8px; border-radius: 100px;
    background: var(--color-red-light); color: var(--color-red);
  }

  .ctd-errlist { display: flex; flex-direction: column; gap: 10px; }
  .ctd-err {
    display: flex; gap: 12px; align-items: center; background: #fff;
    border: 1px solid var(--color-line); border-radius: 12px; padding: 14px;
    width: 100%; text-align: left; cursor: pointer; font-family: inherit;
    transition: transform 0.15s, border-color 0.15s, box-shadow 0.15s;
  }
  .ctd-err:hover {
    transform: translateY(-2px); border-color: var(--color-blue);
    box-shadow: 0 12px 28px -20px rgba(30,58,140,0.3);
  }
  .ctd-err-chip {
    flex-shrink: 0; font-family: var(--font-mono); font-size: 10px; font-weight: 700;
    padding: 3px 8px; border-radius: 6px; background: var(--color-paper-2); color: var(--color-muted);
  }
  .ctd-err p { margin: 0; flex: 1; min-width: 0; font-size: 14px; color: var(--color-ink-2); line-height: 1.45; }
  .ctd-err-arrow { flex-shrink: 0; color: var(--color-muted-2); font-size: 20px; }
  .ctd-err-cta { align-self: flex-start; margin-top: 6px; color: var(--color-blue); font-weight: 700; font-size: 14px; }

  @media (min-width: 620px) { .ctd-grid { grid-template-columns: 1fr 1fr; } }
  @media (min-width: 960px) { .ctd-grid { grid-template-columns: repeat(3, 1fr); } }
`;
