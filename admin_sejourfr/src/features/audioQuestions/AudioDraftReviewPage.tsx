import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { audioDraftsApi } from "../../api/audioDraftsApi";
import { Button } from "../../components/ui/Button";
import { Modal } from "../../components/ui/Modal";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel, EmptyState } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { Textarea } from "../../components/ui/Form";
import { useToast } from "../../components/ui/Toast";
import type {
  AudioDraftDto,
  BatchGenerationResultDto,
} from "../../types/api";
import styles from "./AudioDraftReviewPage.module.css";

const PAGE_SIZE = 10;

export function AudioDraftReviewPage() {
  const [page, setPage] = useState(0);
  const [rejectTarget, setRejectTarget] = useState<AudioDraftDto | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const queryClient = useQueryClient();
  const toast = useToast();

  const listQuery = useQuery({
    queryKey: ["audioDrafts", "pendingReview", page],
    queryFn: () => audioDraftsApi.pendingReview({ page, size: PAGE_SIZE }),
  });

  const countQuery = useQuery({
    queryKey: ["audioDrafts", "pendingReview", "count"],
    queryFn: () => audioDraftsApi.pendingReviewCount(),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const batchMutation = useMutation({
    mutationFn: () => audioDraftsApi.batchGenerate(),
    onSuccess: (result: BatchGenerationResultDto) => {
      queryClient.invalidateQueries({ queryKey: ["audioDrafts"] });
      if (result.requested === 0) {
        toast.show("Aucun draft TEXT_VALIDATED disponible.", "info");
      } else {
        toast.show(
          `Batch lance : ${result.succeeded} succes, ${result.failed} echec(s).`,
          result.failed === 0 ? "success" : "info",
        );
      }
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur batch", "error"),
  });

  const validateMutation = useMutation({
    mutationFn: (id: string) => audioDraftsApi.validate(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["audioDrafts"] });
      queryClient.invalidateQueries({ queryKey: ["questions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      toast.show("Question publiee dans le catalogue TCF.", "success");
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur", "error"),
  });

  const rejectMutation = useMutation({
    mutationFn: (vars: { id: string; reason: string }) =>
      audioDraftsApi.reject(vars.id, vars.reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["audioDrafts"] });
      setRejectTarget(null);
      setRejectReason("");
      toast.show("Draft rejete.", "info");
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur", "error"),
  });

  const data = listQuery.data;
  const pendingCount = countQuery.data?.count ?? 0;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow="Generation IA"
        title="Audio"
        emphasis="a valider"
        actions={
          <Button
            variant="primary"
            onClick={() => batchMutation.mutate()}
            disabled={batchMutation.isPending}
          >
            {batchMutation.isPending ? "Generation en cours..." : "Generer 10 audios"}
          </Button>
        }
      />

      <Panel
        title="A relire"
        sub={
          pendingCount > 0
            ? `${pendingCount} draft${pendingCount > 1 ? "s" : ""} en attente d'ecoute`
            : "Aucun draft en attente. Lance un batch pour en generer."
        }
      >
        {listQuery.isLoading && (
          <div className={styles.spinnerWrap}>
            <Spinner />
          </div>
        )}

        {listQuery.isError && (
          <EmptyState
            title="Erreur de chargement"
            description={
              listQuery.error instanceof Error
                ? listQuery.error.message
                : "Reessaie dans un instant."
            }
          />
        )}

        {data && data.content.length === 0 && (
          <EmptyState
            title="Rien a ecouter pour le moment"
            description="Les drafts apparaissent ici une fois l'audio genere."
          />
        )}

        {data && data.content.length > 0 && (
          <div className={styles.list}>
            {data.content.map((draft) => (
              <DraftCard
                key={draft.id}
                draft={draft}
                onValidate={() => validateMutation.mutate(draft.id)}
                onReject={() => setRejectTarget(draft)}
                validating={
                  validateMutation.isPending &&
                  validateMutation.variables === draft.id
                }
              />
            ))}
          </div>
        )}

        {data && data.totalPages > 1 && (
          <div className={styles.pagination}>
            <Button
              variant="ghost"
              size="sm"
              disabled={data.first}
              onClick={() => setPage((p) => Math.max(0, p - 1))}
            >
              ← Precedent
            </Button>
            <span className={styles.pageInfo}>
              Page {data.page + 1} / {data.totalPages}
            </span>
            <Button
              variant="ghost"
              size="sm"
              disabled={data.last}
              onClick={() => setPage((p) => p + 1)}
            >
              Suivant →
            </Button>
          </div>
        )}
      </Panel>

      <Modal
        open={rejectTarget !== null}
        onClose={() => {
          if (!rejectMutation.isPending) {
            setRejectTarget(null);
            setRejectReason("");
          }
        }}
        eyebrow="Rejet definitif"
        title="Pourquoi rejeter ce draft ?"
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => {
                setRejectTarget(null);
                setRejectReason("");
              }}
              disabled={rejectMutation.isPending}
            >
              Annuler
            </Button>
            <Button
              variant="red"
              disabled={!rejectReason.trim() || rejectMutation.isPending}
              onClick={() => {
                if (rejectTarget && rejectReason.trim()) {
                  rejectMutation.mutate({
                    id: rejectTarget.id,
                    reason: rejectReason.trim(),
                  });
                }
              }}
            >
              {rejectMutation.isPending ? "Rejet..." : "Confirmer le rejet"}
            </Button>
          </>
        }
      >
        <Textarea
          rows={5}
          placeholder="Ex : voix robotique, transcript incomprehensible, doublon..."
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
          autoFocus
        />
      </Modal>
    </div>
  );
}

interface DraftCardProps {
  draft: AudioDraftDto;
  onValidate: () => void;
  onReject: () => void;
  validating: boolean;
}

function DraftCard({ draft, onValidate, onReject, validating }: DraftCardProps) {
  return (
    <article className={styles.card}>
      <header className={styles.cardHeader}>
        <div className={styles.cardMeta}>
          {draft.difficulty && <Tag>{draft.difficulty}</Tag>}
          {draft.competenceCode && <Tag>{draft.competenceCode}</Tag>}
          {draft.themeName && <Tag>{draft.themeName}</Tag>}
          {draft.audioVoiceUsed && (
            <span className={styles.voiceTech}>{draft.audioVoiceUsed}</span>
          )}
          {draft.audioDurationSec !== null && (
            <span className={styles.voiceTech}>
              ~{draft.audioDurationSec}s
            </span>
          )}
        </div>
      </header>

      {draft.audioUrl && (
        <audio
          controls
          src={draft.audioUrl}
          className={styles.audio}
          preload="none"
        />
      )}

      <div className={styles.grid}>
        <section className={styles.transcript}>
          <div className={styles.smallLabel}>Transcript</div>
          <p>{draft.transcriptText}</p>
        </section>

        <section className={styles.questionBlock}>
          <div className={styles.smallLabel}>Question</div>
          <p className={styles.statement}>{draft.statement}</p>
          <ol className={styles.choices}>
            {draft.choices.map((c, idx) => (
              <li
                key={idx}
                className={`${styles.choice} ${c.isCorrect ? styles.choiceCorrect : ""}`}
              >
                <span className={styles.choiceOrder}>
                  {String.fromCharCode(65 + c.displayOrder)}
                </span>
                <span className={styles.choiceLabel}>{c.label}</span>
                {c.isCorrect && <Tag>correct</Tag>}
              </li>
            ))}
          </ol>

          {draft.explanation && (
            <>
              <div className={styles.smallLabel}>Explication</div>
              <p className={styles.explanation}>{draft.explanation}</p>
            </>
          )}
        </section>
      </div>

      <footer className={styles.actions}>
        <Button
          variant="primary"
          onClick={onValidate}
          disabled={validating}
        >
          {validating ? "Publication..." : "Valider"}
        </Button>
        <Button variant="red" onClick={onReject}>
          Rejeter
        </Button>
      </footer>
    </article>
  );
}
