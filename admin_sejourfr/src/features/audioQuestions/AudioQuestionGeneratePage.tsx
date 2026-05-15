import { useState } from "react";
import { useForm } from "react-hook-form";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { audioQuestionsApi } from "../../api/audioQuestionsApi";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel, EmptyState } from "../../components/ui/Panel";
import { Button } from "../../components/ui/Button";
import { FormRow, Select, Textarea } from "../../components/ui/Form";
import { Tag } from "../../components/ui/Tag";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import type {
  GenerateAudioQuestionRequest,
  QuestionPreviewDto,
} from "../../types/api";
import {
  COMPETENCE_OPTIONS,
  LEVEL_OPTIONS,
  THEME_OPTIONS,
  TYPE_OPTIONS,
  competenceLabel,
  formatDuration,
  formatEur,
  formatSeconds,
  themeLabel,
} from "./audioHelpers";
import styles from "./AudioQuestionGeneratePage.module.css";

interface FormValues {
  niveau: "A2" | "B1" | "B2" | "";
  theme: string;
  typeSouhaite: string;
  competenceVisee: string;
  consignesSpecifiques: string;
}

const defaultValues: FormValues = {
  niveau: "B1",
  theme: "",
  typeSouhaite: "",
  competenceVisee: "",
  consignesSpecifiques: "",
};

export function AudioQuestionGeneratePage() {
  const [preview, setPreview] = useState<QuestionPreviewDto | null>(null);
  const queryClient = useQueryClient();
  const toast = useToast();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormValues>({ defaultValues });

  const generateMutation = useMutation({
    mutationFn: (req: GenerateAudioQuestionRequest) => audioQuestionsApi.generate(req),
    onSuccess: (data) => {
      setPreview(data);
      queryClient.invalidateQueries({ queryKey: ["audioQuestions"] });
      toast.show("Question générée, à toi de valider.", "success");
    },
    onError: (err: unknown) => {
      const message = err instanceof Error ? err.message : "Erreur inconnue";
      toast.show(message, "error");
    },
  });

  const validateMutation = useMutation({
    mutationFn: (id: string) => audioQuestionsApi.validate(id),
    onSuccess: () => {
      setPreview(null);
      reset(defaultValues);
      queryClient.invalidateQueries({ queryKey: ["audioQuestions"] });
      queryClient.invalidateQueries({ queryKey: ["questions"] });
      toast.show("Question activée. Elle apparaît dans le catalogue TCF.", "success");
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur", "error"),
  });

  const rejectMutation = useMutation({
    mutationFn: (id: string) => audioQuestionsApi.reject(id),
    onSuccess: () => {
      setPreview(null);
      queryClient.invalidateQueries({ queryKey: ["audioQuestions"] });
      toast.show("Question rejetée et fichier audio supprimé.", "info");
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur", "error"),
  });

  const onSubmit = handleSubmit((values) => {
    if (!values.niveau) return;
    const req: GenerateAudioQuestionRequest = { niveau: values.niveau };
    if (values.theme) req.theme = values.theme as GenerateAudioQuestionRequest["theme"];
    if (values.typeSouhaite)
      req.typeSouhaite = values.typeSouhaite as GenerateAudioQuestionRequest["typeSouhaite"];
    if (values.competenceVisee)
      req.competenceVisee =
        values.competenceVisee as GenerateAudioQuestionRequest["competenceVisee"];
    if (values.consignesSpecifiques.trim())
      req.consignesSpecifiques = values.consignesSpecifiques.trim();
    generateMutation.mutate(req);
  });

  if (preview) {
    return (
      <PreviewView
        preview={preview}
        onValidate={() => validateMutation.mutate(preview.questionId)}
        onReject={() => rejectMutation.mutate(preview.questionId)}
        onRegenerate={() => setPreview(null)}
        validating={validateMutation.isPending}
        rejecting={rejectMutation.isPending}
      />
    );
  }

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow="TCF · Compréhension orale"
        title="Générer une question"
        emphasis="audio"
      />

      <Panel
        title="Paramètres de génération"
        sub="L'IA produit un transcript, un SSML, une question et 4 choix. Tu valides ensuite avant publication."
      >
        <form onSubmit={onSubmit} className={styles.form}>
          <div className={styles.grid2}>
            <FormRow
              label="Niveau"
              htmlFor="niveau"
              error={errors.niveau?.message}
            >
              <Select
                id="niveau"
                {...register("niveau", { required: "Le niveau est requis" })}
              >
                {LEVEL_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </Select>
            </FormRow>

            <FormRow label="Thème (optionnel)" htmlFor="theme">
              <Select id="theme" {...register("theme")}>
                <option value="">— laisser l'IA choisir —</option>
                {THEME_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </Select>
            </FormRow>
          </div>

          <div className={styles.grid2}>
            <FormRow label="Type de support (optionnel)" htmlFor="typeSouhaite">
              <Select id="typeSouhaite" {...register("typeSouhaite")}>
                <option value="">— laisser l'IA choisir —</option>
                {TYPE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </Select>
            </FormRow>

            <FormRow
              label="Compétence visée (optionnel)"
              htmlFor="competenceVisee"
            >
              <Select id="competenceVisee" {...register("competenceVisee")}>
                <option value="">— laisser l'IA choisir —</option>
                {COMPETENCE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </Select>
            </FormRow>
          </div>

          <FormRow
            label="Consignes spécifiques (optionnel, 500 caractères max)"
            htmlFor="consignesSpecifiques"
            error={errors.consignesSpecifiques?.message}
          >
            <Textarea
              id="consignesSpecifiques"
              rows={3}
              placeholder="Ex : conversation entre une étudiante étrangère et un agent du service client d'un opérateur téléphonique."
              {...register("consignesSpecifiques", {
                maxLength: { value: 500, message: "500 caractères maximum" },
              })}
            />
          </FormRow>

          <div className={styles.formActions}>
            <Button
              type="submit"
              variant="primary"
              disabled={generateMutation.isPending}
            >
              {generateMutation.isPending ? "Génération…" : "Générer la question"}
            </Button>
            <span className={styles.hint}>
              La génération mobilise Claude + Azure Speech + Cloudflare R2.
              Compte 15 à 45 secondes.
            </span>
          </div>
        </form>

        {generateMutation.isPending && (
          <div className={styles.loadingOverlay}>
            <Spinner label="Génération en cours… Claude rédige, Azure synthétise la voix." />
          </div>
        )}
      </Panel>

      <Panel
        title="Audit des générations"
        sub="Voir l'historique, les coûts et les échecs récents."
      >
        <EmptyState
          title="Audit dispo dans le sous-menu"
          description="Onglet ↳ Audit générations dans la sidebar."
        />
      </Panel>
    </div>
  );
}

interface PreviewViewProps {
  preview: QuestionPreviewDto;
  onValidate: () => void;
  onReject: () => void;
  onRegenerate: () => void;
  validating: boolean;
  rejecting: boolean;
}

function PreviewView({
  preview,
  onValidate,
  onReject,
  onRegenerate,
  validating,
  rejecting,
}: PreviewViewProps) {
  const { audio, question, choices, metadata } = preview;
  const sortedChoices = [...choices].sort((a, b) => a.displayOrder - b.displayOrder);

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow="Prévisualisation · DRAFT"
        title="Vérifie avant publication"
        emphasis={question.difficulty}
        actions={
          <div className={styles.headerActions}>
            <Button variant="ghost" onClick={onRegenerate}>
              Régénérer
            </Button>
            <Button variant="red" onClick={onReject} disabled={rejecting}>
              {rejecting ? "Suppression…" : "Rejeter"}
            </Button>
            <Button variant="primary" onClick={onValidate} disabled={validating}>
              {validating ? "Activation…" : "Valider et activer"}
            </Button>
          </div>
        }
      />

      <div className={styles.previewMeta}>
        <Tag tone="draft">DRAFT</Tag>
        <Tag tone={question.difficulty === "A2" ? "a2" : question.difficulty === "B1" ? "b1" : "b2"}>
          {question.difficulty}
        </Tag>
        <Tag tone="co">CO</Tag>
        <span className={styles.metaSpan}>Thème : {themeLabel(question.theme)}</span>
        <span className={styles.metaSpan}>Compétence : {competenceLabel(question.competenceCode)}</span>
        <span className={styles.metaSpan}>Durée : {formatSeconds(audio.durationSec)}</span>
      </div>

      <Panel title="Audio" sub={audio.contextDescription ?? undefined}>
        <audio controls src={audio.url} className={styles.audioPlayer} preload="metadata" />
        {audio.voices.length > 0 && (
          <div className={styles.voices}>
            {audio.voices.map((v, i) => (
              <span key={i} className={styles.voicePill}>
                <strong>{v.role}</strong>
                <span className={styles.voiceTech}>
                  {v.azureVoice} · {v.gender === "F" ? "Femme" : "Homme"}
                </span>
              </span>
            ))}
          </div>
        )}
        <div className={styles.transcript}>
          <div className={styles.transcriptLabel}>Transcript</div>
          <p>{audio.transcript}</p>
        </div>
      </Panel>

      <Panel title="Question">
        <p className={styles.statement}>{question.statement}</p>
        <ul className={styles.choicesList}>
          {sortedChoices.map((c) => (
            <li
              key={c.id}
              className={`${styles.choice} ${c.isCorrect ? styles.choiceCorrect : ""}`}
            >
              <span className={styles.choiceOrder}>{c.displayOrder}.</span>
              <span className={styles.choiceLabel}>{c.label}</span>
              {c.isCorrect && <Tag tone="active">Bonne réponse</Tag>}
            </li>
          ))}
        </ul>
      </Panel>

      <Panel title="Explication">
        <p className={styles.explanation}>{question.explanation}</p>
      </Panel>

      <Panel title="Métriques">
        <dl className={styles.metricsGrid}>
          <div>
            <dt>Coût total</dt>
            <dd>{formatEur(metadata.costEur)}</dd>
          </div>
          <div>
            <dt>Durée pipeline</dt>
            <dd>{formatDuration(metadata.generationDurationMs)}</dd>
          </div>
          <div>
            <dt>Tokens Anthropic</dt>
            <dd>
              {metadata.anthropicInputTokens ?? "—"} in /{" "}
              {metadata.anthropicOutputTokens ?? "—"} out
              {metadata.anthropicCacheReadTokens != null &&
                metadata.anthropicCacheReadTokens > 0 && (
                  <span className={styles.cacheHint}>
                    {" "}
                    · {metadata.anthropicCacheReadTokens} cache hit
                  </span>
                )}
            </dd>
          </div>
          <div>
            <dt>Caractères Azure</dt>
            <dd>{metadata.azureCharactersCount ?? "—"}</dd>
          </div>
        </dl>
      </Panel>
    </div>
  );
}
