"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ApiException, fullTcfExamApi } from "@/lib/api";
import s from "./tcfFullExam.module.css";

const EPREUVES = [
  { icon: "🎧", label: "Compréhension orale", duration: "20 min", questions: "25 questions" },
  { icon: "📖", label: "Compréhension écrite", duration: "30 min", questions: "25 questions" },
  { icon: "✍️", label: "Expression écrite", duration: "30 min", questions: "3 tâches" },
  { icon: "🎙️", label: "Expression orale", duration: "10 min", questions: "3 tâches" },
];

const A_SAVOIR = [
  "Aucune correction entre les épreuves — le chrono global continue.",
  "Les épreuves CO et CE ne peuvent pas être reprises en arrière.",
  "Les productions EE et EO sont évaluées par l'IA en arrière-plan.",
  "Le niveau final est le plancher de vos 4 épreuves (règle TCF IRN).",
];

interface Props {
  slotNumber: number;
  onClose: () => void;
  /** Compte sans abonnement TCF : on rappelle que l'EE/EO n'est offerte qu'une fois. */
  isFreeAccount?: boolean;
  /** Appelé si le backend refuse (403, abonnement Intégral requis). */
  onNeedsPremium?: () => void;
}

export function TcfFullExamBriefingSheet({ slotNumber, onClose, isFreeAccount, onNeedsPremium }: Props) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function launch() {
    if (loading) return;
    setLoading(true);
    setError(null);
    try {
      const exam = await fullTcfExamApi.start(slotNumber);
      router.push(`/examens-blancs/tcf/${exam.id}`);
    } catch (e) {
      if (e instanceof ApiException && e.status === 403 && onNeedsPremium) {
        onNeedsPremium();
        return;
      }
      setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
      setLoading(false);
    }
  }

  return (
    <>
      <div className={s.backdrop} onClick={onClose} />
      <div className={s.sheet} role="dialog" aria-modal aria-label="Lancer l'examen blanc TCF complet">
        <div className={s.sheetHandle} />

        <div className={s.sheetEyebrow}>
          <span>EXAMEN BLANC #{slotNumber}</span>
          <span className={s.sheetDurationBadge}>90 min</span>
        </div>
        <div className={s.sheetTitle}>TCF IRN en conditions réelles</div>

        <div className={s.deroulement}>
          {EPREUVES.map((e) => (
            <div key={e.label} className={s.deroulementRow}>
              <span className={s.deroulementIcon}>{e.icon}</span>
              <span className={s.deroulementLabel}>
                {e.label}
                <span style={{ display: "block", fontSize: "0.72rem", color: "var(--color-muted)", marginTop: 1 }}>
                  {e.questions}
                </span>
              </span>
              <span className={s.deroulementDuration}>{e.duration}</span>
            </div>
          ))}
        </div>

        <div className={s.aSavoir}>
          <div className={s.aSavoirTitle}>À savoir</div>
          <ul className={s.aSavoirList}>
            {A_SAVOIR.map((tip) => (
              <li key={tip}>{tip}</li>
            ))}
          </ul>
        </div>

        {isFreeAccount && (
          <div className={s.freeNote}>
            <strong>Compte gratuit :</strong>{" "}
            l&apos;expression écrite et orale (EE + EO),
            évaluées par l&apos;IA, vous sont offertes <strong>une seule fois</strong>. Vous
            pourrez ensuite refaire cet examen en compréhension (CO + CE) ; l&apos;EE et l&apos;EO
            passeront en abonnement Intégral.
          </div>
        )}

        {error && <div className={s.error}>{error}</div>}

        <div className={s.sheetActions}>
          <button
            type="button"
            className="btn btn-red btn-lg"
            onClick={launch}
            disabled={loading}
          >
            {loading ? "Démarrage…" : "Lancer l'examen blanc"}
          </button>
          <button type="button" className="btn btn-ghost" onClick={onClose} disabled={loading}>
            Annuler
          </button>
        </div>
      </div>
    </>
  );
}
