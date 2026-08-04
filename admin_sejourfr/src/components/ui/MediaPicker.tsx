import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { mediaApi } from "../../api/mediaApi";
import { HttpError } from "../../api/http";
import type { MediaDto, MediaType } from "../../types/api";
import { Button } from "./Button";
import { MediaPreview } from "./MediaPreview";
import styles from "./MediaPicker.module.css";

interface Props {
  /** Identifiant du média actuellement attaché (côté backend). */
  value: string | null;
  /** Hint sur le type connu de ce média (utile pour l'affichage immédiat). */
  initialType?: MediaType | null;
  /** Hint sur l'URL connue (évite un round-trip si on l'a déjà). */
  initialUrl?: string | null;
  /**
   * SVG inline connu. Un média image peut n'avoir aucune URL : son balisage est
   * alors porté par la question, et c'est la seule façon de l'afficher.
   */
  initialInlineSvg?: string | null;
  /** Limite le picker à un seul type (ex: audio pour CO). Sinon les 3 sont proposés. */
  allowedTypes?: MediaType[];
  onChange: (mediaId: string | null) => void;
}

const TYPE_LABEL: Record<MediaType, string> = {
  AUDIO: "Audio",
  IMAGE: "Image",
  VIDEO: "Vidéo",
};

const ACCEPT: Record<MediaType, string> = {
  AUDIO: "audio/*",
  IMAGE: "image/*",
  VIDEO: "video/*",
};

export function MediaPicker({
  value,
  initialType,
  initialUrl,
  initialInlineSvg,
  allowedTypes,
  onChange,
}: Props) {
  const types = allowedTypes ?? (["AUDIO", "IMAGE", "VIDEO"] as MediaType[]);
  const [selectedType, setSelectedType] = useState<MediaType>(
    initialType ?? types[0],
  );
  const [mode, setMode] = useState<"upload" | "url">("upload");
  const [url, setUrl] = useState("");
  const [altText, setAltText] = useState("");
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const hintSuffisant = Boolean(
    initialType && (initialUrl || initialInlineSvg),
  );

  // Récupère le média si on a un id mais pas de quoi l'afficher tout de suite
  const mediaQuery = useQuery({
    queryKey: ["media", value],
    queryFn: () => mediaApi.getById(value!),
    enabled: Boolean(value) && !hintSuffisant,
    staleTime: 60_000,
  });

  const current: {
    url: string | null;
    type: MediaType;
    altText?: string | null;
    inlineSvg?: string | null;
  } | null =
    value && initialType && hintSuffisant
      ? {
          url: initialUrl ?? null,
          type: initialType,
          inlineSvg: initialInlineSvg,
        }
      : mediaQuery.data
        ? {
            url: mediaQuery.data.url,
            type: mediaQuery.data.type,
            altText: mediaQuery.data.altText,
          }
        : null;

  useEffect(() => {
    if (initialType) setSelectedType(initialType);
  }, [initialType]);

  const uploadMutation = useMutation({
    mutationFn: (file: File) =>
      mediaApi.upload({
        file,
        type: selectedType,
        altText: altText || undefined,
      }),
    onSuccess: (m: MediaDto) => {
      onChange(m.id);
      setError(null);
      setAltText("");
      if (fileInputRef.current) fileInputRef.current.value = "";
    },
    onError: (err) => {
      setError(err instanceof HttpError ? err.message : (err as Error).message);
    },
  });

  const fromUrlMutation = useMutation({
    mutationFn: () =>
      mediaApi.createFromUrl({
        type: selectedType,
        url: url.trim(),
        altText: altText || undefined,
      }),
    onSuccess: (m: MediaDto) => {
      onChange(m.id);
      setError(null);
      setUrl("");
      setAltText("");
    },
    onError: (err) => {
      setError(err instanceof HttpError ? err.message : (err as Error).message);
    },
  });

  const handleFile = (file: File | undefined) => {
    if (!file) return;
    setError(null);
    uploadMutation.mutate(file);
  };

  const handleFromUrl = () => {
    if (!url.trim()) {
      setError("Indiquez une URL.");
      return;
    }
    setError(null);
    fromUrlMutation.mutate();
  };

  const handleClear = () => {
    onChange(null);
    setError(null);
  };

  const isBusy = uploadMutation.isPending || fromUrlMutation.isPending;

  return (
    <div className={styles.picker}>
      {current && (
        <div className={styles.currentWrap}>
          <MediaPreview
            url={current.url}
            type={current.type}
            altText={current.altText ?? undefined}
            inlineSvg={current.inlineSvg}
            compact
          />
          <div className={styles.currentActions}>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={handleClear}
              disabled={isBusy}
            >
              Retirer le média
            </Button>
          </div>
        </div>
      )}

      {!current && value && mediaQuery.isLoading && (
        <div className={styles.loading}>Chargement du média…</div>
      )}

      <div className={styles.controls}>
        {types.length > 1 && (
          <div className={styles.typeRow}>
            <span className={styles.label}>Type</span>
            <div className={styles.typeBtns}>
              {types.map((t) => (
                <button
                  key={t}
                  type="button"
                  className={`${styles.typeBtn} ${t === selectedType ? styles.typeBtnActive : ""}`}
                  onClick={() => setSelectedType(t)}
                  disabled={isBusy}
                >
                  {TYPE_LABEL[t]}
                </button>
              ))}
            </div>
          </div>
        )}

        <div className={styles.modeRow}>
          <button
            type="button"
            className={`${styles.modeBtn} ${mode === "upload" ? styles.modeBtnActive : ""}`}
            onClick={() => setMode("upload")}
          >
            Téléverser un fichier
          </button>
          <button
            type="button"
            className={`${styles.modeBtn} ${mode === "url" ? styles.modeBtnActive : ""}`}
            onClick={() => setMode("url")}
          >
            Depuis une URL
          </button>
        </div>

        {mode === "upload" && (
          <div className={styles.uploadRow}>
            <input
              ref={fileInputRef}
              type="file"
              accept={ACCEPT[selectedType]}
              className={styles.fileInput}
              onChange={(e) => handleFile(e.target.files?.[0])}
              disabled={isBusy}
            />
            <input
              type="text"
              className={styles.altInput}
              placeholder="Texte alternatif / description (optionnel)"
              value={altText}
              onChange={(e) => setAltText(e.target.value)}
              disabled={isBusy}
            />
          </div>
        )}

        {mode === "url" && (
          <div className={styles.urlRow}>
            <input
              type="url"
              className={styles.urlInput}
              placeholder="https://…"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              disabled={isBusy}
            />
            <input
              type="text"
              className={styles.altInput}
              placeholder="Texte alternatif (optionnel)"
              value={altText}
              onChange={(e) => setAltText(e.target.value)}
              disabled={isBusy}
            />
            <Button
              type="button"
              variant="primary"
              size="sm"
              onClick={handleFromUrl}
              disabled={isBusy}
            >
              {fromUrlMutation.isPending ? "Ajout…" : "Ajouter"}
            </Button>
          </div>
        )}

        {isBusy && <div className={styles.hint}>Envoi en cours…</div>}
        {error && <div className={styles.error}>{error}</div>}
      </div>
    </div>
  );
}
