import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { passagesApi } from "../../api/passagesApi";
import { HttpError } from "../../api/http";
import type {
  PassageDto,
  PassageType,
  PassageWriteRequest,
} from "../../types/api";
import { Button } from "./Button";
import { MediaPicker } from "./MediaPicker";
import { MediaPreview } from "./MediaPreview";
import styles from "./PassagePicker.module.css";

interface Props {
  /** Identifiant du passage actuellement attaché. */
  value: string | null;
  /** Thématique de la question, sert à filtrer + à pré-remplir lors d'une création. */
  themeId: string | null;
  onChange: (passageId: string | null) => void;
}

const TYPE_LABEL: Record<PassageType, string> = {
  TEXTE: "Texte",
  AUDIO: "Audio",
  DIALOGUE: "Dialogue",
};

export function PassagePicker({ value, themeId, onChange }: Props) {
  const queryClient = useQueryClient();
  const [mode, setMode] = useState<"existing" | "new">("existing");
  const [search, setSearch] = useState("");
  const [newType, setNewType] = useState<PassageType>("TEXTE");
  const [newContent, setNewContent] = useState("");
  const [newMediaId, setNewMediaId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const passagesQuery = useQuery({
    queryKey: ["passages", { themeId: themeId ?? "all" }],
    queryFn: () => passagesApi.list(themeId ?? undefined),
  });

  const currentPassage = useMemo(() => {
    if (!value || !passagesQuery.data) return null;
    return passagesQuery.data.find((p) => p.id === value) ?? null;
  }, [value, passagesQuery.data]);

  // Recharge le passage isolément si non trouvé dans la liste (ex: thème changé)
  const standaloneQuery = useQuery({
    queryKey: ["passages", "detail", value],
    queryFn: () => passagesApi.getById(value!),
    enabled: Boolean(value) && !currentPassage,
  });

  const displayedPassage = currentPassage ?? standaloneQuery.data ?? null;

  const filteredPassages = useMemo(() => {
    const list = passagesQuery.data ?? [];
    if (!search.trim()) return list;
    const q = search.trim().toLowerCase();
    return list.filter(
      (p) =>
        (p.content && p.content.toLowerCase().includes(q)) ||
        p.id.toLowerCase().includes(q),
    );
  }, [passagesQuery.data, search]);

  useEffect(() => {
    // Quand on attache un passage, on revient en mode "existing" pour voir la sélection
    if (value) setMode("existing");
  }, [value]);

  const createMutation = useMutation({
    mutationFn: (req: PassageWriteRequest) => passagesApi.create(req),
    onSuccess: (p: PassageDto) => {
      queryClient.invalidateQueries({ queryKey: ["passages"] });
      onChange(p.id);
      setNewContent("");
      setNewMediaId(null);
      setError(null);
      setMode("existing");
    },
    onError: (err) => {
      setError(err instanceof HttpError ? err.message : (err as Error).message);
    },
  });

  const handleCreate = () => {
    if (!themeId) {
      setError("Choisissez d'abord une thématique pour la question.");
      return;
    }
    if (newType === "TEXTE" && !newContent.trim()) {
      setError("Le contenu du passage est requis.");
      return;
    }
    if (newType === "AUDIO" && !newMediaId) {
      setError("Sélectionnez un média audio pour ce passage.");
      return;
    }
    setError(null);
    createMutation.mutate({
      type: newType,
      content: newContent.trim() || undefined,
      themeId,
      mediaId: newMediaId ?? undefined,
    });
  };

  return (
    <div className={styles.picker}>
      {displayedPassage && (
        <div className={styles.currentBlock}>
          <div className={styles.currentHeader}>
            <span className={styles.currentBadge}>
              Passage · {TYPE_LABEL[displayedPassage.type]}
            </span>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => onChange(null)}
            >
              Détacher
            </Button>
          </div>
          {displayedPassage.content && (
            <p className={styles.currentContent}>{displayedPassage.content}</p>
          )}
          {displayedPassage.mediaUrl && displayedPassage.mediaType && (
            <MediaPreview
              url={displayedPassage.mediaUrl}
              type={displayedPassage.mediaType}
              compact
            />
          )}
        </div>
      )}

      <div className={styles.modeRow}>
        <button
          type="button"
          className={`${styles.modeBtn} ${mode === "existing" ? styles.modeBtnActive : ""}`}
          onClick={() => setMode("existing")}
        >
          Passage existant
        </button>
        <button
          type="button"
          className={`${styles.modeBtn} ${mode === "new" ? styles.modeBtnActive : ""}`}
          onClick={() => setMode("new")}
        >
          Créer un passage
        </button>
      </div>

      {mode === "existing" && (
        <div className={styles.existing}>
          <input
            type="text"
            className={styles.search}
            placeholder={
              themeId
                ? "Rechercher dans les passages de la thématique…"
                : "Rechercher dans tous les passages…"
            }
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          {passagesQuery.isLoading && (
            <div className={styles.hint}>Chargement des passages…</div>
          )}
          {passagesQuery.isError && (
            <div className={styles.error}>
              {(passagesQuery.error as Error).message}
            </div>
          )}
          {passagesQuery.data && filteredPassages.length === 0 && (
            <div className={styles.empty}>Aucun passage trouvé.</div>
          )}
          {filteredPassages.length > 0 && (
            <ul className={styles.list}>
              {filteredPassages.map((p) => (
                <li key={p.id}>
                  <button
                    type="button"
                    className={`${styles.item} ${p.id === value ? styles.itemActive : ""}`}
                    onClick={() => onChange(p.id)}
                  >
                    <div className={styles.itemHeader}>
                      <span className={styles.itemBadge}>{TYPE_LABEL[p.type]}</span>
                      <span className={styles.itemCount}>
                        {p.questionCount} question{p.questionCount > 1 ? "s" : ""}
                      </span>
                    </div>
                    <div className={styles.itemPreview}>
                      {p.content
                        ? p.content.length > 160
                          ? `${p.content.slice(0, 160).trim()}…`
                          : p.content
                        : "(passage sans texte)"}
                    </div>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      {mode === "new" && (
        <div className={styles.newForm}>
          <div className={styles.typeRow}>
            <span className={styles.label}>Type</span>
            <div className={styles.typeBtns}>
              {(["TEXTE", "AUDIO", "DIALOGUE"] as PassageType[]).map((t) => (
                <button
                  key={t}
                  type="button"
                  className={`${styles.typeBtn} ${t === newType ? styles.typeBtnActive : ""}`}
                  onClick={() => setNewType(t)}
                >
                  {TYPE_LABEL[t]}
                </button>
              ))}
            </div>
          </div>

          {newType !== "AUDIO" && (
            <textarea
              className={styles.textarea}
              rows={5}
              placeholder={
                newType === "TEXTE"
                  ? "Texte support du passage (article, e-mail, etc.)…"
                  : "Transcription du dialogue (optionnelle si média joint)…"
              }
              value={newContent}
              onChange={(e) => setNewContent(e.target.value)}
            />
          )}

          {(newType === "AUDIO" || newType === "DIALOGUE") && (
            <div className={styles.mediaWrap}>
              <span className={styles.label}>Média joint</span>
              <MediaPicker
                value={newMediaId}
                allowedTypes={newType === "AUDIO" ? ["AUDIO"] : ["AUDIO", "VIDEO"]}
                onChange={setNewMediaId}
              />
            </div>
          )}

          {error && <div className={styles.error}>{error}</div>}

          <div className={styles.newActions}>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setMode("existing")}
              disabled={createMutation.isPending}
            >
              Annuler
            </Button>
            <Button
              type="button"
              variant="primary"
              size="sm"
              onClick={handleCreate}
              disabled={createMutation.isPending || !themeId}
            >
              {createMutation.isPending ? "Création…" : "Créer et attacher"}
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
