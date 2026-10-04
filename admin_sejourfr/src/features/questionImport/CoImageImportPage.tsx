import { useEffect, useRef, useState } from "react";
import type { ChangeEvent, DragEvent } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { HttpError, httpErrorMessage } from "../../api/http";
import { questionImportApi } from "../../api/questionImportApi";
import { Button } from "../../components/ui/Button";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel } from "../../components/ui/Panel";
import { Tag } from "../../components/ui/Tag";
import type { CoImageImportReport } from "../../types/api";
import { ImportErrorList } from "./components/ImportErrorList";
import { ImportQuestionCard } from "./components/ImportQuestionCard";
import { formatBytes, type LocalImage } from "./localImages";
import styles from "./CoImageImportPage.module.css";

const ACCEPTED_IMAGES = "image/png,image/webp";

const MANIFEST_EXAMPLE = `{
  "version": "1",
  "format": "CO_IMAGE",
  "questions": [
    {
      "externalId": "co-a2-001",
      "level": "A2",
      "image": "co-a2-001.png",
      "sceneDescription": "Un couple descend l'allée d'un cinéma…",
      "choices": ["…", "…", "…", "…"],
      "correctAnswer": "C",
      "explanation": "…"
    }
  ]
}`;

function isJsonFile(file: File): boolean {
  return file.type === "application/json" || file.name.toLowerCase().endsWith(".json");
}

function failureMessage(error: unknown): string {
  if (error instanceof HttpError) {
    if (error.status === 409) {
      return `${httpErrorMessage(error)} Un autre import a probablement utilisé le même identifiant entre-temps.`;
    }
    if (error.status === 413) {
      return "Le lot est trop lourd pour être envoyé en une fois : réduisez le nombre ou le poids des images.";
    }
    if (error.status >= 500) {
      return `Le serveur n'a pas pu terminer l'import (${httpErrorMessage(error)}). Rien n'a été créé : relancez l'analyse puis l'import.`;
    }
  }
  return httpErrorMessage(error);
}

export function CoImageImportPage() {
  const queryClient = useQueryClient();
  const [manifest, setManifest] = useState("");
  const [images, setImages] = useState<LocalImage[]>([]);
  const imagesRef = useRef<LocalImage[]>([]);
  const [revision, setRevision] = useState(0);
  const [report, setReport] = useState<CoImageImportReport | null>(null);
  const [reportRevision, setReportRevision] = useState<number | null>(null);
  const [failure, setFailure] = useState<string | null>(null);
  const [imported, setImported] = useState<CoImageImportReport | null>(null);
  const [manifestDragOver, setManifestDragOver] = useState(false);
  const [imagesDragOver, setImagesDragOver] = useState(false);
  const jsonInputRef = useRef<HTMLInputElement>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);

  useEffect(
    () => () => {
      for (const image of imagesRef.current) URL.revokeObjectURL(image.url);
      imagesRef.current = [];
    },
    [],
  );

  function commitImages(next: LocalImage[]) {
    imagesRef.current = next;
    setImages(next);
    setRevision((r) => r + 1);
  }

  function changeManifest(value: string) {
    setManifest(value);
    setRevision((r) => r + 1);
  }

  async function loadManifestFile(file: File) {
    changeManifest(await file.text());
  }

  function addFiles(files: File[]) {
    const json = files.find(isJsonFile);
    if (json) void loadManifestFile(json);
    const added = files.filter((f) => !isJsonFile(f));
    if (added.length === 0) return;
    const byName = new Map(imagesRef.current.map((image) => [image.name, image]));
    for (const file of added) {
      const previous = byName.get(file.name);
      if (previous) URL.revokeObjectURL(previous.url);
      byName.set(file.name, { name: file.name, file, url: URL.createObjectURL(file) });
    }
    commitImages([...byName.values()]);
  }

  function removeImage(name: string) {
    const target = imagesRef.current.find((image) => image.name === name);
    if (target) URL.revokeObjectURL(target.url);
    commitImages(imagesRef.current.filter((image) => image.name !== name));
  }

  function clearImages() {
    for (const image of imagesRef.current) URL.revokeObjectURL(image.url);
    commitImages([]);
  }

  function resetAll() {
    clearImages();
    changeManifest("");
    setReport(null);
    setReportRevision(null);
    setFailure(null);
    setImported(null);
  }

  const analyzeMutation = useMutation({
    mutationFn: (at: number) =>
      questionImportApi
        .analyzeCoImage(manifest, images.map((i) => i.file))
        .then((result) => ({ result, at })),
    onMutate: () => setFailure(null),
    onSuccess: ({ result, at }) => {
      setReport(result);
      setReportRevision(at);
    },
    onError: (error) => setFailure(failureMessage(error)),
  });

  const importMutation = useMutation({
    mutationFn: (at: number) =>
      questionImportApi
        .importCoImage(manifest, images.map((i) => i.file))
        .then((result) => ({ result, at })),
    onMutate: () => setFailure(null),
    onSuccess: ({ result, at }) => {
      if (result.imported) {
        setImported(result);
        setReport(null);
        setReportRevision(null);
        queryClient.invalidateQueries({ queryKey: ["audioDrafts"] });
        queryClient.invalidateQueries({ queryKey: ["dashboard"] });
        return;
      }
      setReport(result);
      setReportRevision(at);
    },
    onError: (error) => {
      setReportRevision(null);
      setFailure(failureMessage(error));
    },
  });

  const busy = analyzeMutation.isPending || importMutation.isPending;
  const upToDate = report !== null && reportRevision === revision;
  const canImport = upToDate && report.ok && !busy;
  const imageByName = new Map(images.map((image) => [image.name, image]));
  const questionsInError = report ? report.questions.filter((q) => !q.ok).length : 0;

  function onManifestDrop(e: DragEvent<HTMLTextAreaElement>) {
    const file = Array.from(e.dataTransfer.files).find(isJsonFile);
    setManifestDragOver(false);
    if (!file) return;
    e.preventDefault();
    void loadManifestFile(file);
  }

  function onImagesDrop(e: DragEvent<HTMLDivElement>) {
    e.preventDefault();
    setImagesDragOver(false);
    addFiles(Array.from(e.dataTransfer.files));
  }

  function onPickJson(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (file) void loadManifestFile(file);
  }

  function onPickImages(e: ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? []);
    e.target.value = "";
    addFiles(files);
  }

  if (imported) {
    const count = imported.questions.length;
    return (
      <>
        <PageHeader eyebrow="Génération IA" title="Importer des" emphasis="CO image" />
        <Panel>
          <div className={styles.success} role="status">
            <h2 className={styles.successTitle}>
              {count} brouillon{count > 1 ? "s" : ""} créé{count > 1 ? "s" : ""}
            </h2>
            <p className={styles.successLead}>
              Aucune question n'est encore publiée : elles le seront une par une, à la validation.
            </p>
            <ol className={styles.steps}>
              <li>
                <strong>Générer l'audio</strong> : sur « Audio à valider », « Générer 10 audios »
                traite les brouillons en attente (filtrez par niveau au besoin).
              </li>
              <li>
                <strong>Relire</strong> : écouter la bande, vérifier l'image et les quatre
                propositions lues.
              </li>
              <li>
                <strong>Valider</strong> : la question CO image entre au catalogue TCF, active. Un
                brouillon défectueux se rejette.
              </li>
            </ol>
            <ul className={styles.importedList}>
              {imported.questions.map((q) => (
                <li key={q.index}>
                  <span className={styles.mono}>{q.externalId}</span>
                  {q.level && <Tag tone="info">{q.level}</Tag>}
                  {q.themeName && <span className={styles.muted}>{q.themeName}</span>}
                </li>
              ))}
            </ul>
            <div className={styles.successActions}>
              <Link to="/audio-questions/review" className={styles.primaryLink}>
                Ouvrir « Audio à valider »
              </Link>
              <Button variant="ghost" onClick={resetAll}>
                Importer un autre lot
              </Button>
            </div>
          </div>
        </Panel>
      </>
    );
  }

  return (
    <>
      <PageHeader
        eyebrow="Génération IA"
        title="Importer des"
        emphasis="CO image"
        description="Un manifeste JSON et ses images deviennent des brouillons audio. L'analyse n'écrit rien ; l'import crée tout le lot ou rien."
      />

      <div className={styles.zones}>
        <Panel title="1. Manifeste JSON" sub="Collez-le, déposez un fichier .json ou choisissez-le.">
          <div className={styles.zoneBody}>
            <label htmlFor="co-image-manifest" className="visually-hidden">
              Manifeste JSON
            </label>
            <textarea
              id="co-image-manifest"
              className={`${styles.manifest} ${manifestDragOver ? styles.dragOver : ""}`}
              value={manifest}
              onChange={(e) => changeManifest(e.target.value)}
              onDragOver={(e) => {
                if (e.dataTransfer.types.includes("Files")) {
                  e.preventDefault();
                  setManifestDragOver(true);
                }
              }}
              onDragLeave={() => setManifestDragOver(false)}
              onDrop={onManifestDrop}
              placeholder={MANIFEST_EXAMPLE}
              spellCheck={false}
              rows={16}
            />
            <div className={styles.zoneActions}>
              <input
                ref={jsonInputRef}
                type="file"
                accept="application/json,.json"
                className={styles.fileInput}
                onChange={onPickJson}
                tabIndex={-1}
                aria-hidden="true"
              />
              <Button variant="default" size="sm" onClick={() => jsonInputRef.current?.click()}>
                Choisir un fichier .json
              </Button>
              {manifest && (
                <Button variant="ghost" size="sm" onClick={() => changeManifest("")}>
                  Vider
                </Button>
              )}
            </div>
          </div>
        </Panel>

        <Panel
          title="2. Images"
          sub="PNG ou WEBP, 4:3, 800 px de large au moins, opaques, 5 Mo au plus. Nom = « image » du manifeste."
        >
          <div className={styles.zoneBody}>
            <div
              className={`${styles.dropZone} ${imagesDragOver ? styles.dragOver : ""}`}
              onDragOver={(e) => {
                e.preventDefault();
                setImagesDragOver(true);
              }}
              onDragLeave={() => setImagesDragOver(false)}
              onDrop={onImagesDrop}
            >
              <p className={styles.dropText}>Glissez les images ici</p>
              <input
                ref={imageInputRef}
                type="file"
                accept={ACCEPTED_IMAGES}
                multiple
                className={styles.fileInput}
                onChange={onPickImages}
                tabIndex={-1}
                aria-hidden="true"
              />
              <Button variant="default" size="sm" onClick={() => imageInputRef.current?.click()}>
                Choisir des images
              </Button>
            </div>

            {images.length > 0 && (
              <>
                <div className={styles.fileListHead}>
                  <span>
                    {images.length} fichier{images.length > 1 ? "s" : ""}
                  </span>
                  <Button variant="ghost" size="sm" onClick={clearImages}>
                    Tout retirer
                  </Button>
                </div>
                <ul className={styles.fileList}>
                  {images.map((image) => (
                    <li key={image.name} className={styles.fileItem}>
                      <img src={image.url} alt="" className={styles.fileThumb} />
                      <span className={styles.fileMeta}>
                        <span className={styles.fileName}>{image.name}</span>
                        <span className={styles.muted}>{formatBytes(image.file.size)}</span>
                      </span>
                      <button
                        type="button"
                        className={styles.removeBtn}
                        onClick={() => removeImage(image.name)}
                        aria-label={`Retirer ${image.name}`}
                      >
                        ×
                      </button>
                    </li>
                  ))}
                </ul>
              </>
            )}
          </div>
        </Panel>
      </div>

      <div className={styles.actionBar}>
        <Button
          variant="primary"
          onClick={() => analyzeMutation.mutate(revision)}
          disabled={!manifest.trim() || busy}
        >
          {analyzeMutation.isPending ? "Analyse…" : "Analyser"}
        </Button>
        <Button variant="red" onClick={() => importMutation.mutate(revision)} disabled={!canImport}>
          {importMutation.isPending ? "Import…" : "Importer"}
        </Button>
        <span className={styles.actionHint} aria-live="polite">
          {report === null
            ? "Analysez le lot avant de l'importer."
            : !upToDate
              ? "Le manifeste ou les images ont changé : relancez l'analyse."
              : report.ok
                ? "Lot valide : l'import créera les brouillons."
                : "Corrigez les erreurs puis relancez l'analyse."}
        </span>
      </div>

      {failure && (
        <div className={styles.failure} role="alert">
          {failure}
        </div>
      )}

      {report && (
        <section
          className={`${styles.report} ${upToDate ? "" : styles.stale}`}
          aria-label="Rapport d'analyse"
        >
          <div className={styles.summary}>
            <Tag tone={report.ok ? "success" : "danger"} dot>
              {report.ok ? "Lot valide" : "Lot refusé"}
            </Tag>
            <span>
              {report.questionCount} question{report.questionCount > 1 ? "s" : ""}
              {questionsInError > 0 && ` · ${questionsInError} en erreur`}
            </span>
            <span className={styles.muted}>
              {report.questionCount}/{report.maxQuestions} max · charte {report.charteVersion}
            </span>
          </div>

          {report.errors.length > 0 && (
            <div className={styles.batchErrors}>
              <h2 className={styles.sectionTitle}>Erreurs du lot</h2>
              <ImportErrorList errors={report.errors} />
            </div>
          )}

          {report.questions.length > 0 && (
            <div className={styles.cards}>
              {report.questions.map((q) => (
                <ImportQuestionCard
                  key={q.index}
                  question={q}
                  localImage={q.image ? (imageByName.get(q.image) ?? null) : null}
                />
              ))}
            </div>
          )}
        </section>
      )}
    </>
  );
}
