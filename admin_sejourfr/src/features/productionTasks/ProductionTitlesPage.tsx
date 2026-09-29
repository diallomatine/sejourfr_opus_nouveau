import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { productionTasksApi } from "../../api/productionTasksApi";
import { Button } from "../../components/ui/Button";
import { Input, Select } from "../../components/ui/Form";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import type { AdminProductionTaskDto, EpreuveType } from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./ProductionTitlesPage.module.css";

/** Aligné sur `production_tasks.titre varchar(80)` (V028) et sur le 422 serveur. */
const TITRE_MAX = 80;

const EPREUVES: { value: EpreuveType; label: string }[] = [
  { value: "TCF_EE", label: "Expression écrite" },
  { value: "TCF_EO", label: "Expression orale" },
];

/**
 * Console : les **intitulés éditoriaux** des sujets EO/EE.
 *
 * Périmètre volontairement étroit — on lit le catalogue, on pose ou on retire
 * un titre. Le reste d'un sujet (consigne, bornes de mots/durée, activation,
 * fiche de scénario T2) reste piloté par les migrations de contenu : ce sont
 * des données que la notation et des tests de seed verrouillent, pas du texte
 * d'affichage.
 *
 * Le contenu initial est publié par la migration V754 (générée depuis
 * `backend_sejourfr/tools/production-titres/`), mais une fois les migrations
 * appliquées c'est la **base** qui fait foi — même convention que le module
 * Compétences.
 */
export function ProductionTitlesPage() {
  const [epreuve, setEpreuve] = useState<EpreuveType>("TCF_EE");
  const [tache, setTache] = useState<string>("");

  const tacheNumero = tache ? Number(tache) : undefined;

  const tasksQuery = useQuery({
    queryKey: ["adminProductionTasks", { epreuve, tacheNumero }],
    queryFn: () => productionTasksApi.listAdmin(epreuve, tacheNumero),
  });

  const sansTitre = (tasksQuery.data ?? []).filter((t) => !t.titre).length;

  return (
    <>
      <PageHeader
        eyebrow="§ 03 — Contenu"
        title="Titres des "
        emphasis="sujets EE/EO"
      />

      {tasksQuery.isLoading && <Spinner label="Chargement..." />}

      {tasksQuery.isError && (
        <Panel>
          <div className={styles.error}>
            Erreur : {(tasksQuery.error as Error).message}
          </div>
        </Panel>
      )}

      <Panel noPadding>
        <div className={styles.filtersBar}>
          <div className={styles.filterGroup}>
            <span className={styles.filterLabel}>Épreuve</span>
            <Select
              value={epreuve}
              onChange={(e) => setEpreuve(e.target.value as EpreuveType)}
            >
              {EPREUVES.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </Select>
          </div>
          <div className={styles.filterGroup}>
            <span className={styles.filterLabel}>Tâche</span>
            <Select value={tache} onChange={(e) => setTache(e.target.value)}>
              <option value="">Toutes</option>
              <option value="1">Tâche 1</option>
              <option value="2">Tâche 2</option>
              <option value="3">Tâche 3</option>
            </Select>
          </div>
        </div>
        <div className={styles.help}>
          Le titre s&apos;affiche en tête de la carte de sujet, côté web et
          mobile — la consigne reste dessous. Visez 2 à 5 mots, une forme
          nominale, fidèle à la situation du sujet. N&apos;y remettez ni le
          numéro de tâche, ni le palier, ni le nombre de mots : ils sont déjà
          affichés ailleurs sur la carte. Deux sujets d&apos;une même tâche ne
          doivent jamais se confondre — c&apos;est toute la raison d&apos;être
          de ces titres. Vider le champ retire le titre : les fronts
          réaffichent alors <code>Sujet N</code>.
        </div>
      </Panel>

      {tasksQuery.data && (
        <Panel
          title="Sujets publiés"
          sub={`${tasksQuery.data.length} sujets · ${sansTitre} sans titre`}
          noPadding
        >
          {tasksQuery.data.length === 0 ? (
            <EmptyState title="Aucun sujet pour ce filtre" />
          ) : (
            <div className={tableStyles.tableWrap}>
              <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
                <thead>
                  <tr>
                    <th>Sujet · titre</th>
                    <th>Consigne</th>
                    <th>Tâche</th>
                    <th>Niveau</th>
                    <th>Statut</th>
                  </tr>
                </thead>
                <tbody>
                  {tasksQuery.data.map((task, i) => (
                    <TaskRow key={task.id} task={task} rank={i + 1} />
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Panel>
      )}
    </>
  );
}

function TaskRow({
  task,
  rank,
}: {
  task: AdminProductionTaskDto;
  rank: number;
}) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const [value, setValue] = useState(task.titre ?? "");

  // Le champ suit la donnée serveur : après un changement de filtre ou une
  // invalidation, la ligne se réutilise et garderait sinon la saisie d'un
  // autre sujet.
  useEffect(() => {
    setValue(task.titre ?? "");
  }, [task.id, task.titre]);

  const mutation = useMutation({
    mutationFn: (titre: string | null) =>
      productionTasksApi.updateTitre(task.id, { titre }),
    onSuccess: (updated) => {
      queryClient.invalidateQueries({ queryKey: ["adminProductionTasks"] });
      toast.show(
        updated.titre ? "Titre enregistré." : "Titre retiré.",
        "success",
      );
    },
    onError: (e: Error) => toast.show(e.message, "error"),
  });

  const trimmed = value.trim();
  const current = task.titre ?? "";
  const dirty = trimmed !== current;
  const tropLong = trimmed.length > TITRE_MAX;

  function submit(e: FormEvent) {
    e.preventDefault();
    if (!dirty || tropLong || mutation.isPending) return;
    mutation.mutate(trimmed === "" ? null : trimmed);
  }

  return (
    <tr>
      {/* Première colonne = titre de la fiche sous 720 px (cf. `cardTable`),
          donc pas de `data-label` : c'est le rang + le champ qu'on veut lire en
          tête, pas un intitulé de colonne. */}
      <td className={styles.titreCell}>
        <form className={styles.titreForm} onSubmit={submit}>
          <span className={styles.rankCell}>
            {String(rank).padStart(2, "0")}
          </span>
          <Input
            className={styles.titreInput}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            placeholder={`Sujet ${rank} (aucun titre)`}
            aria-label={`Titre du sujet ${rank}`}
          />
          <span
            className={`${styles.counter} ${tropLong ? styles.counterOver : ""}`}
          >
            {trimmed.length}/{TITRE_MAX}
          </span>
          <Button
            type="submit"
            size="sm"
            variant="primary"
            disabled={!dirty || tropLong || mutation.isPending}
          >
            {mutation.isPending ? "..." : "Enregistrer"}
          </Button>
        </form>
      </td>
      <td data-label="Consigne">
        <div className={styles.consigne}>
          {task.contexte && (
            <span className={styles.contexte}>{task.contexte}</span>
          )}
          {task.consigne}
        </div>
      </td>
      <td data-label="Tâche">T{task.tacheNumero}</td>
      <td data-label="Niveau">{task.niveauCible ?? "—"}</td>
      <td data-label="Statut">
        {task.active ? (
          <Tag tone="active">Publié</Tag>
        ) : (
          <Tag tone="muted">Dépublié</Tag>
        )}
      </td>
    </tr>
  );
}
