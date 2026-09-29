import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { exampleAudioApi } from "../../api/exampleAudioApi";
import { Button } from "../../components/ui/Button";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel, EmptyState } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { useToast } from "../../components/ui/Toast";
import type { ExampleAudioBatchResultDto, ExampleAudioDto } from "../../types/api";
import styles from "./ExampleAudioReviewPage.module.css";

/** Voix Azure proposées pour la régénération (sous-ensemble whitelisté backend). */
const VOICE_OPTIONS: { value: string; label: string }[] = [
  { value: "", label: "Voix auto" },
  { value: "fr-FR-DeniseNeural", label: "Denise (F)" },
  { value: "fr-FR-HenriNeural", label: "Henri (H)" },
  { value: "fr-FR-EloiseNeural", label: "Éloïse (F)" },
  { value: "fr-FR-JeromeNeural", label: "Jérôme (H)" },
  { value: "fr-FR-VivienneNeural", label: "Vivienne (F)" },
  { value: "fr-FR-AlainNeural", label: "Alain (H)" },
];

export function ExampleAudioReviewPage() {
  const queryClient = useQueryClient();
  const toast = useToast();

  const listQuery = useQuery({
    queryKey: ["exampleAudio", "toReview"],
    queryFn: () => exampleAudioApi.toReview(),
  });

  const countQuery = useQuery({
    queryKey: ["exampleAudio", "pending", "count"],
    queryFn: () => exampleAudioApi.pendingCount(),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const batchMutation = useMutation({
    mutationFn: () => exampleAudioApi.batchGenerate(10),
    onSuccess: (result: ExampleAudioBatchResultDto) => {
      queryClient.invalidateQueries({ queryKey: ["exampleAudio"] });
      if (result.requested === 0) {
        toast.show("Aucun exemple EO sans audio.", "info");
      } else {
        toast.show(
          `Batch lancé : ${result.succeeded} succès, ${result.failed} échec(s).`,
          result.failed === 0 ? "success" : "info",
        );
      }
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur batch", "error"),
  });

  const publishMutation = useMutation({
    mutationFn: (id: string) => exampleAudioApi.publish(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["exampleAudio"] });
      toast.show("Audio publié : il devient audible dans l'app.", "success");
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur", "error"),
  });

  const regenerateMutation = useMutation({
    mutationFn: (vars: { id: string; voice: string }) =>
      exampleAudioApi.regenerate(vars.id, vars.voice || undefined),
    onSuccess: (result: ExampleAudioDto) => {
      queryClient.invalidateQueries({ queryKey: ["exampleAudio"] });
      if (result.audioStatus === "ERROR") {
        toast.show(`Régénération échouée : ${result.audioError ?? ""}`, "error");
      } else {
        toast.show("Audio régénéré.", "success");
      }
    },
    onError: (err: unknown) =>
      toast.show(err instanceof Error ? err.message : "Erreur", "error"),
  });

  const examples = listQuery.data ?? [];
  const pendingCount = countQuery.data?.count ?? 0;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow="Generation IA"
        title="Audios des exemples"
        emphasis="EO"
        actions={
          <Button
            variant="primary"
            onClick={() => batchMutation.mutate()}
            disabled={batchMutation.isPending}
          >
            {batchMutation.isPending ? "Génération en cours..." : "Générer 10 audios"}
          </Button>
        }
      />

      <Panel
        title="À valider"
        sub={
          pendingCount > 0
            ? `${pendingCount} exemple${pendingCount > 1 ? "s" : ""} EO sans audio`
            : "Tous les exemples EO ont un audio généré."
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
                : "Réessaie dans un instant."
            }
          />
        )}

        {listQuery.data && examples.length === 0 && (
          <EmptyState
            title="Rien à valider pour le moment"
            description="Les audios générés apparaissent ici, prêts à être écoutés puis publiés."
          />
        )}

        {examples.length > 0 && (
          <div className={styles.list}>
            {examples.map((ex) => (
              <ExampleCard
                key={ex.id}
                example={ex}
                onPublish={() => publishMutation.mutate(ex.id)}
                onRegenerate={(voice) => regenerateMutation.mutate({ id: ex.id, voice })}
                publishing={publishMutation.isPending && publishMutation.variables === ex.id}
                regenerating={
                  regenerateMutation.isPending && regenerateMutation.variables?.id === ex.id
                }
              />
            ))}
          </div>
        )}
      </Panel>
    </div>
  );
}

interface ExampleCardProps {
  example: ExampleAudioDto;
  onPublish: () => void;
  onRegenerate: (voice: string) => void;
  publishing: boolean;
  regenerating: boolean;
}

function ExampleCard({
  example,
  onPublish,
  onRegenerate,
  publishing,
  regenerating,
}: ExampleCardProps) {
  const [voice, setVoice] = useState("");

  return (
    <article className={styles.card}>
      <header className={styles.cardHeader}>
        <div className={styles.cardMeta}>
          <span className={styles.title}>{example.titre}</span>
          {example.audioVoice && <span className={styles.voiceTech}>{example.audioVoice}</span>}
          {example.audioDurationSec !== null && (
            <span className={styles.voiceTech}>~{example.audioDurationSec}s</span>
          )}
        </div>
      </header>

      {example.audioUrl && (
        <audio controls src={example.audioUrl} className={styles.audio} preload="none" />
      )}

      <section className={styles.extrait}>
        <div className={styles.smallLabel}>Texte du modèle</div>
        <p>{example.contenu}</p>
      </section>

      <footer className={styles.actions}>
        <Button variant="primary" onClick={onPublish} disabled={publishing || regenerating}>
          {publishing ? "Publication..." : "Publier"}
        </Button>
        <div className={styles.regenGroup}>
          <select
            className={styles.voiceSelect}
            value={voice}
            onChange={(e) => setVoice(e.target.value)}
            disabled={regenerating}
          >
            {VOICE_OPTIONS.map((v) => (
              <option key={v.value} value={v.value}>
                {v.label}
              </option>
            ))}
          </select>
          <Button
            variant="ghost"
            onClick={() => onRegenerate(voice)}
            disabled={regenerating || publishing}
          >
            {regenerating ? "Régénération..." : "Régénérer"}
          </Button>
        </div>
      </footer>
    </article>
  );
}
