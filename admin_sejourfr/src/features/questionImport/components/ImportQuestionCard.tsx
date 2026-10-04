import { Tag } from "../../../components/ui/Tag";
import type { TagTone } from "../../../components/ui/Tag";
import type { CoImageImportQuestionReport } from "../../../types/api";
import { ImportErrorList } from "./ImportErrorList";
import { formatBytes, type LocalImage } from "../localImages";
import styles from "./ImportReport.module.css";

const LEVEL_TONE: Record<string, TagTone> = { A2: "a2", B1: "b1", B2: "b2" };

interface ImportQuestionCardProps {
  question: CoImageImportQuestionReport;
  localImage: LocalImage | null;
}

export function ImportQuestionCard({ question: q, localImage }: ImportQuestionCardProps) {
  const imageSrc = localImage?.url ?? q.imageUrl;
  const imageFacts = [
    q.imageFormat?.toUpperCase(),
    q.imageWidth !== null && q.imageHeight !== null ? `${q.imageWidth} × ${q.imageHeight}` : null,
    q.imageSizeBytes !== null ? formatBytes(q.imageSizeBytes) : null,
  ].filter(Boolean);

  return (
    <article className={`${styles.card} ${q.ok ? "" : styles.cardKo}`}>
      <header className={styles.cardHeader}>
        <span className={styles.cardIndex}>#{q.index + 1}</span>
        <span className={styles.mono}>{q.externalId ?? "sans identifiant"}</span>
        {q.level && <Tag tone={LEVEL_TONE[q.level] ?? "neutral"}>{q.level}</Tag>}
        {(q.themeName ?? q.themeCode) && <Tag tone="muted">{q.themeName ?? q.themeCode}</Tag>}
        <span className={styles.cardStatus}>
          <Tag tone={q.ok ? "success" : "danger"} dot>
            {q.ok ? "Prête" : `${q.errors.length} erreur${q.errors.length > 1 ? "s" : ""}`}
          </Tag>
        </span>
      </header>

      <div className={styles.cardBody}>
        <figure className={styles.figure}>
          {imageSrc ? (
            <img src={imageSrc} alt={q.sceneDescription ?? ""} className={styles.preview} />
          ) : (
            <div className={styles.previewMissing}>Image absente</div>
          )}
          <figcaption className={styles.figcaption}>
            <span className={styles.mono}>{q.image ?? "—"}</span>
            {imageFacts.length > 0 && <span className={styles.muted}>{imageFacts.join(" · ")}</span>}
          </figcaption>
        </figure>

        <div className={styles.cardContent}>
          {q.sceneDescription && (
            <div>
              <div className={styles.smallLabel}>Description de la scène</div>
              <p className={styles.text}>{q.sceneDescription}</p>
            </div>
          )}

          {q.choices.length > 0 && (
            <div>
              <div className={styles.smallLabel}>Propositions lues</div>
              <ol className={styles.choices}>
                {q.choices.map((c, i) => (
                  <li
                    key={`${c.letter ?? "?"}-${i}`}
                    className={`${styles.choice} ${c.correct ? styles.choiceCorrect : ""}`}
                  >
                    <span className={styles.choiceLetter}>{c.letter ?? "?"}</span>
                    <span className={styles.choiceText}>{c.text ?? "—"}</span>
                    {c.correct && <span className={styles.correctMark}>✓ bonne réponse</span>}
                  </li>
                ))}
              </ol>
            </div>
          )}

          {q.explanation && (
            <div>
              <div className={styles.smallLabel}>Explication</div>
              <p className={styles.text}>{q.explanation}</p>
            </div>
          )}

          {q.transcriptText && (
            <details className={styles.transcript}>
              <summary>Transcription de l'audio</summary>
              <p className={styles.text}>{q.transcriptText}</p>
            </details>
          )}

          {q.errors.length > 0 && <ImportErrorList errors={q.errors} />}
        </div>
      </div>
    </article>
  );
}
