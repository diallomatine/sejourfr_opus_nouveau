import type { AdminProductionReponse, EpreuveType } from "../../../types/api";
import { isDialogue, parseTranscript } from "../../../lib/evaluation";
import type { TranscriptTurn } from "../../../lib/evaluation";
import { formatInteger, formatMicroUsd, formatRatio, formatSeconds } from "../productionLabels";
import { Facts, NotAvailable, SectionLabel } from "./Facts";
import styles from "./ReponseBlock.module.css";

const SPEAKER_LABEL: Record<TranscriptTurn["speaker"], string> = {
  EXAMINER: "Examinateur",
  CANDIDATE: "Candidat",
  UNKNOWN: "",
};

/**
 * EE : le texte remis et son nombre de mots. EO : la transcription automatique
 * (celle que le correcteur a lue) — aucun audio n'est conservé, il n'y a donc
 * jamais de lecteur.
 */
export function ReponseBlock({
  reponse,
  epreuve,
}: {
  reponse: AdminProductionReponse;
  epreuve: EpreuveType;
}) {
  if (epreuve !== "TCF_EO") {
    return (
      <div className={styles.wrap}>
        {reponse.texte ? <PlainText text={reponse.texte} /> : <NotAvailable>Aucun texte enregistré</NotAvailable>}
        <p className={styles.count}>
          {reponse.motsCount === null ? <NotAvailable>Nombre de mots non disponible</NotAvailable> : `${formatInteger(reponse.motsCount)} mots`}
        </p>
      </div>
    );
  }

  const info = reponse.transcriptionInfo;
  const turns = reponse.transcription ? parseTranscript(reponse.transcription) : [];
  const dialogue = isDialogue(turns);

  return (
    <div className={styles.wrap}>
      <p className={styles.audioNote}>
        Audio non conservé{reponse.audioMotif ? ` — ${reponse.audioMotif}` : ""} · durée{" "}
        {reponse.dureeSec === null ? "non disponible" : formatSeconds(reponse.dureeSec)}
      </p>

      <SectionLabel>Transcription automatique</SectionLabel>
      {!reponse.transcription && <NotAvailable>Aucune transcription enregistrée</NotAvailable>}
      {reponse.transcription && dialogue && (
        <ol className={styles.turns}>
          {turns.map((turn, index) => (
            <li
              key={`${index}-${turn.speaker}`}
              className={`${styles.turn} ${turn.speaker === "CANDIDATE" ? styles.turnCandidate : styles.turnExaminer}`}
            >
              {turn.speaker !== "UNKNOWN" && <span className={styles.speaker}>{SPEAKER_LABEL[turn.speaker]}</span>}
              <p className={styles.turnText}>{turn.text}</p>
            </li>
          ))}
        </ol>
      )}
      {reponse.transcription && !dialogue && <PlainText text={reponse.transcription} />}

      {info && (
        <div className={styles.info}>
          <Facts
            columns={4}
            items={[
              { label: "Outil", value: info.outil, mono: true },
              { label: "Langue détectée", value: info.langueDetectee, mono: true },
              {
                label: "Durée audio",
                value: info.dureeAudioSec === null ? null : formatSeconds(info.dureeAudioSec),
              },
              {
                label: "Qualité",
                value:
                  info.qualiteDegradee === null ? null : info.qualiteDegradee ? "Dégradée" : "Normale",
              },
              {
                label: "Part de formes suspectes",
                value: info.tauxFormesSuspectes === null ? null : formatRatio(info.tauxFormesSuspectes),
              },
              { label: "Part de collages", value: info.tauxCollages === null ? null : formatRatio(info.tauxCollages) },
              { label: "Coût transcription", value: info.coutMicroUsd === null ? null : formatMicroUsd(info.coutMicroUsd) },
            ]}
          />
        </div>
      )}
    </div>
  );
}

function PlainText({ text }: { text: string }) {
  const paragraphs = text
    .split(/\n\s*\n|\r?\n/)
    .map((p) => p.trim())
    .filter(Boolean);
  return (
    <div className={styles.plain}>
      {paragraphs.map((p, index) => (
        <p key={index}>{p}</p>
      ))}
    </div>
  );
}
