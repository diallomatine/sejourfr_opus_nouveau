import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { passagesApi } from "../../api/passagesApi";
import { questionsApi } from "../../api/questionsApi";
import { Button } from "../../components/ui/Button";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { PageHeader } from "../../components/ui/PageHeader";
import { MediaPreview } from "../../components/ui/MediaPreview";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import type { Module, PassageType } from "../../types/api";
import { QuestionFormModal } from "./QuestionFormModal";
import {
  QUESTION_TYPE_LABELS,
  tagToneForLevel,
  tagToneForType,
} from "./questionHelpers";
import styles from "./QuestionDetailPage.module.css";

const PASSAGE_TYPE_LABEL: Record<PassageType, string> = {
  TEXTE: "Texte",
  AUDIO: "Audio",
  DIALOGUE: "Dialogue",
};

export function QuestionDetailPage() {
  const params = useParams<{ module: string; id: string }>();
  const module: Module = params.module === "tcf" ? "TCF" : "CIVIQUE";
  const id = params.id!;

  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const toast = useToast();
  const [editing, setEditing] = useState(false);

  const questionQuery = useQuery({
    queryKey: ["questions", "detail", id],
    queryFn: () => questionsApi.getById(id),
  });

  const passageId = questionQuery.data?.passageId ?? null;
  const passageQuery = useQuery({
    queryKey: ["passages", "detail", passageId],
    queryFn: () => passagesApi.getById(passageId!),
    enabled: Boolean(passageId),
  });

  const toggleMutation = useMutation({
    mutationFn: (active: boolean) => questionsApi.setActive(id, active),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["questions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      toast.show("Statut mis à jour", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const deleteMutation = useMutation({
    mutationFn: () => questionsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["questions"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      toast.show("Question supprimée", "success");
      navigate(`/questions/${module.toLowerCase()}`);
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const handleDelete = () => {
    if (!questionQuery.data) return;
    if (
      window.confirm(
        `Supprimer la question ?\n\n"${questionQuery.data.statement.slice(0, 120)}${
          questionQuery.data.statement.length > 120 ? "..." : ""
        }"`,
      )
    ) {
      deleteMutation.mutate();
    }
  };

  const moduleLabel = module === "CIVIQUE" ? "Examen civique" : "TCF";

  if (questionQuery.isLoading) {
    return (
      <div className={styles.loading}>
        <Spinner label="Chargement…" />
      </div>
    );
  }

  if (questionQuery.isError || !questionQuery.data) {
    return (
      <>
        <PageHeader
          eyebrow="§ 02 — Catalogue de questions"
          title="Question ·"
          emphasis={moduleLabel}
        />
        <Panel>
          <EmptyState
            title="Introuvable"
            description={
              questionQuery.error
                ? (questionQuery.error as Error).message
                : "Cette question n'existe plus ou a été supprimée."
            }
          />
          <div className={styles.backRow}>
            <Button
              variant="ghost"
              onClick={() => navigate(`/questions/${module.toLowerCase()}`)}
            >
              ← Retour à la liste
            </Button>
          </div>
        </Panel>
      </>
    );
  }

  const q = questionQuery.data;

  return (
    <>
      <PageHeader
        eyebrow={`§ 02 — ${moduleLabel}`}
        title="Détail de la question"
        actions={
          <div className={styles.headerActions}>
            <Button
              variant="ghost"
              onClick={() => navigate(`/questions/${module.toLowerCase()}`)}
            >
              ← Liste
            </Button>
            <Button variant="primary" onClick={() => setEditing(true)}>
              ✎ Modifier
            </Button>
            <Button
              variant={q.active ? "ghost" : "primary"}
              onClick={() => toggleMutation.mutate(!q.active)}
              disabled={toggleMutation.isPending}
            >
              {q.active ? "Désactiver" : "Activer"}
            </Button>
            <Button
              variant="danger"
              onClick={handleDelete}
              disabled={deleteMutation.isPending}
            >
              Supprimer
            </Button>
          </div>
        }
      />

      <div className={styles.layout}>
        <Panel>
          <div className={styles.tagsRow}>
            <Tag tone={tagToneForLevel(q.difficulty)}>{q.difficulty}</Tag>
            <Tag tone={tagToneForType(q.questionType)}>
              {QUESTION_TYPE_LABELS[q.questionType]}
            </Tag>
            <Tag tone={q.active ? "active" : "draft"}>
              {q.active ? "Active" : "Inactive"}
            </Tag>
            <span className={styles.themePill}>{q.themeName}</span>
          </div>

          {q.passageId && (
            <div className={styles.passageBlock}>
              <div className={styles.passageHeader}>
                <span className={styles.passageBadge}>
                  Passage · {PASSAGE_TYPE_LABEL[q.passageType ?? "TEXTE"]}
                </span>
              </div>
              {passageQuery.data?.content && (
                <p className={styles.passageContent}>
                  {passageQuery.data.content}
                </p>
              )}
              {!passageQuery.data && q.passagePreview && (
                <p className={styles.passageContent}>{q.passagePreview}</p>
              )}
              {passageQuery.data?.mediaUrl && passageQuery.data.mediaType && (
                <MediaPreview
                  url={passageQuery.data.mediaUrl}
                  type={passageQuery.data.mediaType}
                  compact
                />
              )}
            </div>
          )}

          <h2 className={styles.statement}>{q.statement}</h2>

          {module === "TCF" && q.mediaType && (q.mediaUrl || q.mediaInlineSvg) && (
            <div className={styles.mediaBlock}>
              <MediaPreview
                url={q.mediaUrl ?? ""}
                type={q.mediaType}
                inlineSvg={q.mediaInlineSvg}
              />
            </div>
          )}

          <div className={styles.section}>
            <div className={styles.sectionHeader}>
              <span className={styles.sectionLabel}>Choix de réponse</span>
              <span className={styles.sectionMeta}>
                {q.choices.length} choix · {q.choices.filter((c) => c.correct).length} correct
                {q.choices.filter((c) => c.correct).length > 1 ? "s" : ""}
              </span>
            </div>
            <ol className={styles.choices}>
              {[...q.choices]
                .sort((a, b) => a.displayOrder - b.displayOrder)
                .map((c) => (
                  <li
                    key={c.id}
                    className={`${styles.choice} ${c.correct ? styles.choiceCorrect : ""}`}
                  >
                    <span className={styles.choiceMark}>
                      {c.correct ? "✓" : ""}
                    </span>
                    <span className={styles.choiceLabel}>{c.label}</span>
                  </li>
                ))}
            </ol>
          </div>

          {q.explanation && (
            <div className={styles.section}>
              <span className={styles.sectionLabel}>Explication</span>
              <p className={styles.explanation}>{q.explanation}</p>
            </div>
          )}
        </Panel>

        <Panel>
          <span className={styles.sectionLabel}>Métadonnées</span>
          <dl className={styles.meta}>
            <div className={styles.metaRow}>
              <dt>Identifiant</dt>
              <dd className={styles.mono}>{q.id}</dd>
            </div>
            <div className={styles.metaRow}>
              <dt>Module</dt>
              <dd>{moduleLabel}</dd>
            </div>
            <div className={styles.metaRow}>
              <dt>Thématique</dt>
              <dd>{q.themeName}</dd>
            </div>
            {module === "TCF" && (
              <div className={styles.metaRow}>
                <dt>Média</dt>
                <dd>
                  {q.mediaType ? `${q.mediaType.toLowerCase()}` : "—"}
                </dd>
              </div>
            )}
            {module === "TCF" && (
              <div className={styles.metaRow}>
                <dt>Passage</dt>
                <dd>
                  {q.passageId
                    ? `${PASSAGE_TYPE_LABEL[q.passageType ?? "TEXTE"]}`
                    : "—"}
                </dd>
              </div>
            )}
            <div className={styles.metaRow}>
              <dt>Créée le</dt>
              <dd>{new Date(q.createdAt).toLocaleString("fr-FR")}</dd>
            </div>
            {q.updatedAt && (
              <div className={styles.metaRow}>
                <dt>Mise à jour</dt>
                <dd>{new Date(q.updatedAt).toLocaleString("fr-FR")}</dd>
              </div>
            )}
          </dl>
        </Panel>
      </div>

      <QuestionFormModal
        open={editing}
        onClose={() => setEditing(false)}
        module={module}
        question={q}
      />
    </>
  );
}
