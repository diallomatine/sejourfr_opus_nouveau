import { Modal } from "../../../components/ui/Modal";
import type {
  HumanCalibrationNoteDto,
  ProductionSubmissionDto,
  ProductionTaskDto,
} from "../../../types/api";
import { EPREUVE_LABEL, formatDateTime } from "../calibrationHelpers";
import { EvaluationReport } from "./EvaluationReport";
import { HumanNoteForm } from "./HumanNoteForm";
import { ProductionView } from "./ProductionView";
import styles from "./SubmissionDetailModal.module.css";

interface SubmissionDetailModalProps {
  submission: ProductionSubmissionDto | null;
  task?: ProductionTaskDto;
  seuilHorsCible: number;
  sessionNote: HumanCalibrationNoteDto | null;
  previouslyAnnotated: boolean;
  onSaved: (note: HumanCalibrationNoteDto) => void;
  onClose: () => void;
}

export function SubmissionDetailModal({
  submission,
  task,
  seuilHorsCible,
  sessionNote,
  previouslyAnnotated,
  onSaved,
  onClose,
}: SubmissionDetailModalProps) {
  if (!submission) return null;

  const epreuve = task ? EPREUVE_LABEL[task.epreuve] : "Épreuve inconnue";
  const tache = submission.tacheNumero ?? task?.tacheNumero;

  return (
    <Modal
      open
      onClose={onClose}
      size="lg"
      eyebrow={`${epreuve}${tache ? ` · tâche ${tache}` : ""}`}
      title="Annoter cette production"
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
          <EvaluationReport evaluation={submission.evaluation} />
        ) : (
          <p className={styles.noEval}>
            Aucune évaluation IA rattachée à cette soumission — rien à comparer.
          </p>
        )}

        <HumanNoteForm
          submissionId={submission.id}
          noteIa={submission.evaluation?.noteSurVingt ?? null}
          seuilHorsCible={seuilHorsCible}
          sessionNote={sessionNote}
          previouslyAnnotated={previouslyAnnotated}
          onSaved={onSaved}
        />
      </div>
    </Modal>
  );
}
