import { Button } from "../../../components/ui/Button";
import { Modal } from "../../../components/ui/Modal";
import type {
  CalibrationSubmissionDto,
  HumanCalibrationNoteDto,
  ProductionTaskDto,
} from "../../../types/api";
import { EPREUVE_LABEL, formatDateTime } from "../calibrationHelpers";
import { EvaluationReport } from "./EvaluationReport";
import { HumanNoteForm } from "./HumanNoteForm";
import { ProductionView } from "./ProductionView";
import styles from "./SubmissionDetailModal.module.css";

interface SubmissionDetailModalProps {
  entry: CalibrationSubmissionDto | null;
  task?: ProductionTaskDto;
  seuilHorsCible: number;
  existingNote: HumanCalibrationNoteDto | null;
  isLoadingNote: boolean;
  onClose: () => void;
}

export function SubmissionDetailModal({
  entry,
  task,
  seuilHorsCible,
  existingNote,
  isLoadingNote,
  onClose,
}: SubmissionDetailModalProps) {
  if (!entry) return null;

  const submission = entry.submission;
  const epreuve = task ? EPREUVE_LABEL[task.epreuve] : "Épreuve inconnue";
  const tache = submission.tacheNumero ?? task?.tacheNumero;

  return (
    <Modal
      open
      onClose={onClose}
      size="lg"
      eyebrow={`${epreuve}${tache ? ` · tâche ${tache}` : ""}`}
      title="Annoter cette production"
      footer={
        <Button variant="ghost" type="button" onClick={onClose}>
          Fermer
        </Button>
      }
    >
      <div className={styles.body}>
        <div className={styles.meta}>
          <span>Soumise le {formatDateTime(submission.submittedAt)}</span>
          <span className={styles.metaId}>{submission.id}</span>
        </div>

        {task ? (
          <section className={styles.consigne}>
            <div className={styles.consigneLabel}>
              Consigne du sujet
              {task.niveauCible && ` · niveau visé ${task.niveauCible}`}
            </div>
            {task.contexte && <p className={styles.contexte}>{task.contexte}</p>}
            <p className={styles.consigneText}>{task.consigne}</p>
          </section>
        ) : (
          <p className={styles.noTask}>
            Le sujet rattaché à cette soumission n&apos;est plus au catalogue des
            sujets actifs : sa consigne n&apos;est pas affichable.
          </p>
        )}

        <ProductionView submission={submission} />

        {submission.evaluation ? (
          <EvaluationReport
            evaluation={submission.evaluation}
            rubricsVersion={entry.rubricsVersion}
            promptVersion={entry.promptVersion}
          />
        ) : (
          <p className={styles.noEval}>
            Aucune évaluation IA rattachée à cette soumission — rien à comparer.
          </p>
        )}

        <HumanNoteForm
          key={submission.id}
          submissionId={submission.id}
          noteIa={submission.evaluation?.noteSurVingt ?? null}
          seuilHorsCible={seuilHorsCible}
          existingNote={existingNote}
          isLoadingNote={isLoadingNote}
        />
      </div>
    </Modal>
  );
}
