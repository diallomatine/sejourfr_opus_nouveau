import type { ProductionSubmissionDto } from "../../../types/api";
import {
  formatDuration,
  isDialogue,
  parseTranscript,
} from "../calibrationHelpers";
import type { TranscriptTurn } from "../calibrationHelpers";
import styles from "./ProductionView.module.css";

const SPEAKER_LABEL: Record<TranscriptTurn["speaker"], string> = {
  EXAMINER: "Examinateur",
  CANDIDATE: "Candidat",
  UNKNOWN: "",
};

export function ProductionView({
  submission,
}: {
  submission: ProductionSubmissionDto;
}) {
  const turns = submission.transcription
    ? parseTranscript(submission.transcription)
    : [];
  const dialogue = isDialogue(turns);

  return (
    <section className={styles.wrap}>
      <div className={styles.head}>
        <h3 className={styles.title}>Production du candidat</h3>
        <span className={styles.meta}>
          {submission.motsCount !== null && `${submission.motsCount} mots`}
          {submission.motsCount !== null &&
            submission.mediaDurationSec !== null &&
            " · "}
          {submission.mediaDurationSec !== null &&
            formatDuration(submission.mediaDurationSec)}
        </span>
      </div>

      {submission.mediaUrl && (
        <audio className={styles.audio} controls src={submission.mediaUrl} />
      )}

      {submission.transcription && (
        <>
          <div className={styles.sourceTag}>
            {dialogue
              ? "Transcription de l'échange oral"
              : "Transcription de l'oral"}
          </div>
          {dialogue ? (
            <ol className={styles.turns}>
              {turns.map((turn, index) => (
                <li
                  key={`${index}-${turn.speaker}`}
                  className={`${styles.turn} ${turn.speaker === "CANDIDATE" ? styles.turnCandidate : styles.turnExaminer}`}
                >
                  {turn.speaker !== "UNKNOWN" && (
                    <span className={styles.speaker}>
                      {SPEAKER_LABEL[turn.speaker]}
                    </span>
                  )}
                  <p className={styles.turnText}>{turn.text}</p>
                </li>
              ))}
            </ol>
          ) : (
            <PlainText text={submission.transcription} />
          )}
        </>
      )}

      {submission.texteSoumis && (
        <>
          <div className={styles.sourceTag}>Texte remis par le candidat</div>
          <PlainText text={submission.texteSoumis} />
        </>
      )}

      {!submission.transcription && !submission.texteSoumis && (
        <p className={styles.none}>
          Aucun texte ni transcription rattaché à cette soumission.
          {submission.mediaUrl
            ? " Seul l'enregistrement est disponible."
            : " Rien à lire pour le correcteur."}
        </p>
      )}
    </section>
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
