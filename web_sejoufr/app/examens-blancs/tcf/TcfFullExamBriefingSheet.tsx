"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { fullTcfExamApi } from "@/lib/api";
import { handleStartFailure } from "@/lib/start-failure";
import {
  EPREUVE_PRESENTATION,
  FULL_TCF_EXAM_INDICATIVE_SEC,
  minutesLabel,
  plannedEpreuveLabel,
} from "@/lib/exam-durations";
import { FULL_TCF_EXAM_EPREUVES } from "@/lib/types";
import s from "./tcfFullExam.module.css";

// L'examen n'existe pas encore à ce stade : aucune donnée serveur n'est
// disponible, on lit la table de référence partagée (`lib/exam-durations.ts`)
// plutôt que de réécrire des minutes ici.
const EPREUVES = FULL_TCF_EXAM_EPREUVES.map((epreuve) => ({
  ...EPREUVE_PRESENTATION[epreuve],
  duration: plannedEpreuveLabel(epreuve),
}));

const A_SAVOIR = [
  "Chaque épreuve a son propre chrono : le temps d'une épreuve ne se reporte jamais sur la suivante.",
  "Vous pouvez vous arrêter entre deux épreuves et reprendre plus tard.",
  "Le chrono d'une épreuve lancée continue de courir même si vous quittez la page.",
  "En expression orale, le temps ne part qu'au moment où vous lancez une tâche.",
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
      let handedToPaywall = false;
      handleStartFailure(e, {
        onPaywall: () => {
          if (onNeedsPremium) {
            onNeedsPremium();
            handedToPaywall = true;
          } else {
            setError("Cet examen blanc est réservé aux abonnés Intégral.");
          }
        },
        onMessage: setError,
        fallbackMessage: "Impossible de démarrer l'examen.",
      });
      if (!handedToPaywall) setLoading(false);
    }
  }

  return (
    <>
      <div className={s.backdrop} onClick={onClose} />
      <div className={s.sheet} role="dialog" aria-modal aria-label="Lancer l'examen blanc TCF complet">
        <div className={s.sheetHandle} />

        <div className={s.sheetEyebrow}>
          <span>EXAMEN BLANC #{slotNumber}</span>
          <span className={s.sheetDurationBadge}>
            ≈ {minutesLabel(FULL_TCF_EXAM_INDICATIVE_SEC)}
          </span>
        </div>
        <div className={s.sheetTitle}>TCF IRN en conditions réelles</div>

        <div className={s.deroulement}>
          {EPREUVES.map((e) => (
            <div key={e.label} className={s.deroulementRow}>
              <span className={s.deroulementIcon}>{e.icon}</span>
              <span className={s.deroulementLabel}>
                {e.label}
                <span style={{ display: "block", fontSize: "0.72rem", color: "var(--color-muted)", marginTop: 1 }}>
                  {e.volume}
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
