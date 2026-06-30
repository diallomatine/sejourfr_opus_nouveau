import { useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { audioDraftsApi } from "../../api/audioDraftsApi";
import { sanitizeSvg } from "../../lib/sanitizeSvg";
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
  AudioLevel,
  BatchGenerationResultDto,
} from "../../types/api";
import styles from "./AudioDraftReviewPage.module.css";

const PAGE_SIZE = 10;
const LEVELS: AudioLevel[] = ["A2", "B1", "B2"];

export function AudioDraftReviewPage() {
  const [page, setPage] = useState(0);
  // null = tous niveaux. Cadre à la fois les drafts listés (à valider) et le
  // batch de génération (on ne génère que les TEXT_VALIDATED du niveau choisi).
  const [level, setLevel] = useState<AudioLevel | null>(null);
  const [rejectTarget, setRejectTarget] = useState<AudioDraftDto | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const queryClient = useQueryClient();
  const toast = useToast();

  function selectLevel(next: AudioLevel | null) {
    setLevel(next);
    setPage(0);
  }

  const listQuery = useQuery({
    queryKey: ["audioDrafts", "pendingReview", level, page],
    queryFn: () =>
      audioDraftsApi.pendingReview({ page, size: PAGE_SIZE, difficulty: level ?? undefined }),
  });

  const countQuery = useQuery({
    queryKey: ["audioDrafts", "pendingReview", "count", level],
    queryFn: () => audioDraftsApi.pendingReviewCount(level ?? undefined),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const batchMutation = useMutation({
    mutationFn: () => audioDraftsApi.batchGenerate(level ?? undefined),
    onSuccess: (result: BatchGenerationResultDto) => {
      queryClient.invalidateQueries({ queryKey: ["audioDrafts"] });
      if (result.requested === 0) {
        toast.show(
          level
            ? `Aucun draft ${level} TEXT_VALIDATED disponible.`
            : "Aucun draft TEXT_VALIDATED disponible.",
          "info",
        );
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
          <div className={styles.headerActions}>
            <div
              className={styles.levelFilter}
              role="group"
              aria-label="Filtrer par niveau"
            >
              <button
                type="button"
                className={`${styles.levelChip} ${level === null ? styles.levelChipActive : ""}`}
                onClick={() => selectLevel(null)}
              >
                Tous
              </button>
              {LEVELS.map((lvl) => (
                <button
                  key={lvl}
                  type="button"
                  className={`${styles.levelChip} ${level === lvl ? styles.levelChipActive : ""}`}
                  onClick={() => selectLevel(lvl)}
                >
                  {lvl}
                </button>
              ))}
            </div>
            <Button
              variant="primary"
              onClick={() => batchMutation.mutate()}
              disabled={batchMutation.isPending}
            >
              {batchMutation.isPending
                ? "Generation en cours..."
                : level
                  ? `Generer 10 audios (${level})`
                  : "Generer 10 audios"}
            </Button>
          </div>
        }
      />

      <Panel
        title="A relire"
        sub={
          pendingCount > 0
            ? `${pendingCount} draft${pendingCount > 1 ? "s" : ""}${level ? ` ${level}` : ""} en attente d'ecoute`
            : level
              ? `Aucun draft ${level} en attente. Lance un batch ${level} pour en generer.`
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

const ACCEPTED_IMAGE_TYPES = "image/jpeg,image/png,image/webp";

function DraftCard({ draft, onValidate, onReject, validating }: DraftCardProps) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [current, setCurrent] = useState<AudioDraftDto>(draft);
  const [imageReplaced, setImageReplaced] = useState(false);

  const imageMutation = useMutation({
    mutationFn: (file: File) => audioDraftsApi.replaceImage(current.id, file),
    onSuccess: (updated: AudioDraftDto) => {
      setCurrent(updated);
      setImageReplaced(true);
      queryClient.invalidateQueries({ queryKey: ["audioDrafts"] });
      toast.show("Image remplacee.", "success");
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur upload image", "error"),
  });

  const hasImage = current.imageUrl !== null || current.inlineSvg !== null;

  function onPickFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (file) {
      setImageReplaced(false);
      imageMutation.mutate(file);
    }
  }

  return (
    <article className={styles.card}>
      <header className={styles.cardHeader}>
        <div className={styles.cardMeta}>
          {current.difficulty && (
            <Tag tone={current.difficulty.toLowerCase() as "a2" | "b1" | "b2"}>
              {current.difficulty}
            </Tag>
          )}
          {current.competenceCode && <Tag tone="co">{current.competenceCode}</Tag>}
          {current.themeName && <Tag tone="muted">{current.themeName}</Tag>}
          {current.audioVoiceUsed && (
            <span className={styles.voiceTech}>{current.audioVoiceUsed}</span>
          )}
          {current.audioDurationSec !== null && (
            <span className={styles.voiceTech}>
              ~{current.audioDurationSec}s
            </span>
          )}
        </div>
      </header>

      {current.audioUrl && (
        <audio
          controls
          src={current.audioUrl}
          className={styles.audio}
          preload="none"
        />
      )}

      {hasImage && (
        <section className={styles.imageBlock}>
          <div className={styles.imageHeader}>
            <span className={styles.smallLabel}>Image support</span>
            <span className={styles.imageSource}>
              {current.imageUrl
                ? "Image personnalisee (R2)"
                : "SVG genere"}
            </span>
          </div>

          <div className={styles.imagePreview}>
            {current.imageUrl ? (
              <img
                src={current.imageUrl}
                alt={current.imageAltText ?? ""}
                className={styles.image}
              />
            ) : (
              <div
                className={styles.image}
                role="img"
                aria-label={current.imageAltText ?? "Image support"}
                dangerouslySetInnerHTML={{ __html: sanitizeSvg(current.inlineSvg) }}
              />
            )}
          </div>

          {imageReplaced && (
            <p className={styles.imageSuccess}>Nouvelle image enregistree.</p>
          )}

          <input
            ref={fileInputRef}
            type="file"
            accept={ACCEPTED_IMAGE_TYPES}
            className={styles.fileInput}
            onChange={onPickFile}
          />
          <Button
            variant="ghost"
            size="sm"
            onClick={() => fileInputRef.current?.click()}
            disabled={imageMutation.isPending}
          >
            {imageMutation.isPending ? "Upload..." : "Remplacer l'image"}
          </Button>
        </section>
      )}

      <div className={styles.grid}>
        <section className={styles.transcript}>
          <div className={styles.smallLabel}>Transcript</div>
          <p>{current.transcriptText}</p>
        </section>

        <section className={styles.questionBlock}>
          <div className={styles.smallLabel}>Question</div>
          <p className={styles.statement}>{current.statement}</p>
          <ol className={styles.choices}>
            {current.choices.map((c, idx) => (
              <li
                key={idx}
                className={`${styles.choice} ${c.isCorrect ? styles.choiceCorrect : ""}`}
              >
                <span className={styles.choiceOrder}>
                  {String.fromCharCode(65 + c.displayOrder)}
                </span>
                <span className={styles.choiceLabel}>{c.label}</span>
                {c.isCorrect && <Tag tone="active">correct</Tag>}
              </li>
            ))}
          </ol>

          {current.explanation && (
            <>
              <div className={styles.smallLabel}>Explication</div>
              <p className={styles.explanation}>{current.explanation}</p>
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
