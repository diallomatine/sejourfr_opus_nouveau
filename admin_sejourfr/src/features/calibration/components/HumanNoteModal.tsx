import { useQuery } from "@tanstack/react-query";
import { calibrationApi } from "../../../api/calibrationApi";
import { Button } from "../../../components/ui/Button";
import { Modal } from "../../../components/ui/Modal";
import { HumanNoteForm } from "./HumanNoteForm";

/** Repli quand /stats n'a pas encore répondu : le seuil réel vient du serveur. */
const SEUIL_PAR_DEFAUT = 3;

interface HumanNoteModalProps {
  submissionId: string;
  noteIa: number | null;
  /** Ligne d'appoint (épreuve, tâche) : la production reste visible derrière la modale. */
  description?: string;
  onClose: () => void;
}

/**
 * Annotation humaine de calibration, ouverte depuis la fiche « Productions IA »
 * (F-1) : relit la dernière note (`GET …/human-note`, 404 ⇒ jamais annotée) et
 * le seuil hors cible de `/stats`.
 */
export function HumanNoteModal({ submissionId, noteIa, description, onClose }: HumanNoteModalProps) {
  const statsQuery = useQuery({
    queryKey: ["calibration", "stats"],
    queryFn: () => calibrationApi.stats(),
  });

  const humanNoteQuery = useQuery({
    queryKey: ["calibration", "humanNote", submissionId],
    queryFn: () => calibrationApi.humanNote(submissionId),
  });

  return (
    <Modal
      open
      onClose={onClose}
      size="lg"
      eyebrow="Calibration de la notation"
      title="Annoter cette production"
      description={description}
      footer={
        <Button variant="ghost" type="button" onClick={onClose}>
          Fermer
        </Button>
      }
    >
      <HumanNoteForm
        key={submissionId}
        submissionId={submissionId}
        noteIa={noteIa}
        seuilHorsCible={statsQuery.data?.seuilHorsCible ?? SEUIL_PAR_DEFAUT}
        existingNote={humanNoteQuery.data ?? null}
        isLoadingNote={humanNoteQuery.isLoading}
      />
    </Modal>
  );
}
