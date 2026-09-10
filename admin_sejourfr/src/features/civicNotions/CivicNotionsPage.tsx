import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { civicNotionsApi } from "../../api/civicNotionsApi";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import type { CivicNotionDto } from "../../types/api";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./CivicNotionsPage.module.css";

/**
 * `50_` §6.1.2 : commencer par les thèmes les mieux dotés pour **calibrer la
 * méthode** avant `CIV_PRINCIPES`, plus petit et plus sujet aux recouvrements.
 * L'ordre de cette liste est donc l'ordre de travail recommandé, pas
 * l'alphabet.
 */
const THEMES = [
  { code: "CIV_HISTOIRE_GEO", label: "Histoire, géo et culture" },
  { code: "CIV_INSTITUTIONS", label: "Institutions" },
  { code: "CIV_DROITS_DEVOIRS", label: "Droits et devoirs" },
  { code: "CIV_SOCIETE", label: "Vivre en société" },
  { code: "CIV_PRINCIPES", label: "Principes et valeurs" },
] as const;

const PAGE = 25;

/**
 * Seuils de lecture de `50_` §6.1 — **affichage uniquement**.
 *
 * 🛑 Ils ne sont appliqués nulle part côté serveur, et c'est voulu : la règle
 * dégrade **par notion ET par mention**, et le serveur sert les comptes pour
 * que chaque appelant tranche pour SA mention. Ici on les utilise seulement
 * pour colorer une ligne du tableau de couverture.
 */
const SEUIL_PLEINEMENT_UTILISABLE = 5;
const SEUIL_CANDIDATE_FUSION = 12;

/**
 * **Le référentiel de notions civiques et son tagging** (lot L8).
 *
 * C'est l'outil du chantier **éditorial** qui est sur le chemin critique :
 * 1 016 questions à rattacher à une notion. Le code ne fait pas ce travail, il
 * l'outille.
 *
 * 🛑 **Le job propose, un humain valide** (`50_` §6.1.3). Aucune suggestion
 * n'est pré-sélectionnée, aucune fusion n'est appliquée automatiquement.
 *
 * 🛑 **Aucun appel LLM n'est déclenché depuis cet écran.**
 */
export function CivicNotionsPage() {
  const [theme, setTheme] = useState<string>(THEMES[0].code);
  const [offset, setOffset] = useState(0);
  const queryClient = useQueryClient();

  const referentiel = useQuery({
    queryKey: ["civic-notions"],
    queryFn: ({ signal }) => civicNotionsApi.referentiel(signal),
  });

  const file = useQuery({
    queryKey: ["civic-tagging", theme, offset],
    queryFn: ({ signal }) =>
      civicNotionsApi.file({ theme, tagged: false, limit: PAGE, offset }, signal),
  });

  const taguer = useMutation({
    mutationFn: ({ questionId, notionCode }: { questionId: string; notionCode: string | null }) =>
      civicNotionsApi.taguer(questionId, notionCode),
    onSuccess: () => {
      // Les deux vues bougent ensemble : la file se vide, la couverture monte.
      void queryClient.invalidateQueries({ queryKey: ["civic-tagging"] });
      void queryClient.invalidateQueries({ queryKey: ["civic-notions"] });
    },
  });

  /** Les notions du thème courant, seules proposables : une question
   *  d'histoire ne se tague pas sur une notion d'institutions. */
  const notionsDuTheme = useMemo(
    () =>
      (referentiel.data ?? []).filter((n) => n.themeCode === theme && n.active),
    [referentiel.data, theme],
  );

  return (
    <>
      <PageHeader
        eyebrow="Contenu civique"
        title="Référentiel de "
        emphasis="notions"
        actions={
          <div className={styles.themes}>
            {THEMES.map((t) => (
              <button
                key={t.code}
                type="button"
                className={t.code === theme ? styles.themeActive : styles.theme}
                onClick={() => {
                  setTheme(t.code);
                  setOffset(0);
                }}
              >
                {t.label}
              </button>
            ))}
          </div>
        }
      />

      <Panel
        title="À taguer"
        sub={
          file.data
            ? `${file.data.resteATaguer} question(s) civique(s) active(s) encore sans notion, tous thèmes confondus.`
            : undefined
        }
        noPadding
      >
        {file.isLoading && <Spinner />}
        {file.data && file.data.questions.length === 0 && (
          <EmptyState title="Rien à taguer sur ce thème." />
        )}
        {file.data && file.data.questions.length > 0 && (
          <>
            <table className={tableStyles.table}>
              <thead>
                <tr>
                  <th>Question</th>
                  <th>Mention</th>
                  <th>Suggestions</th>
                  <th>Notion</th>
                </tr>
              </thead>
              <tbody>
                {file.data.questions.map((question) => (
                  <tr key={question.questionId}>
                    <td className={styles.enonce}>{question.enonce}</td>
                    <td>{question.mention}</td>
                    <td className={styles.suggestions}>
                      {/* 🛑 Affichées, jamais pré-sélectionnées : un tag validé
                          est toujours un geste. Vide est l'état NORMAL — rien
                          ne remplit cette table sans décision du propriétaire. */}
                      {question.suggestions.length === 0
                        ? "—"
                        : question.suggestions
                            .map((s) => `${s.notionLabel} (${Math.round(s.confidence * 100)} %)`)
                            .join(" · ")}
                    </td>
                    <td>
                      <select
                        className={styles.select}
                        value={question.notionCode ?? ""}
                        disabled={taguer.isPending}
                        onChange={(event) =>
                          taguer.mutate({
                            questionId: question.questionId,
                            notionCode: event.target.value || null,
                          })
                        }
                      >
                        <option value="">— pas encore taguée —</option>
                        {notionsDuTheme.map((n) => (
                          <option key={n.code} value={n.code}>
                            {n.label}
                          </option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className={styles.pagination}>
              <button
                type="button"
                disabled={offset === 0}
                onClick={() => setOffset(Math.max(0, offset - PAGE))}
              >
                Précédent
              </button>
              <span>{offset + 1}–{offset + file.data.questions.length}</span>
              <button
                type="button"
                disabled={file.data.questions.length < PAGE}
                onClick={() => setOffset(offset + PAGE)}
              >
                Suivant
              </button>
            </div>
          </>
        )}
      </Panel>

      <Panel
        title="Couverture mesurée"
        sub="C'est ce tableau qui alimente la porte de revue (§6.1.3) : trop peu de questions ⇒ candidate à la fusion, trop ⇒ candidate à la scission."
        noPadding
      >
        {referentiel.isLoading && <Spinner />}
        {referentiel.data && <Couverture notions={referentiel.data} />}
      </Panel>
    </>
  );
}

function Couverture({ notions }: { notions: CivicNotionDto[] }) {
  const mentions = useMemo(() => {
    const set = new Set<string>();
    notions.forEach((n) => n.parMention.forEach((m) => set.add(m.mention)));
    return [...set].sort();
  }, [notions]);

  return (
    <table className={tableStyles.table}>
      <thead>
        <tr>
          <th>Notion</th>
          <th>Thème</th>
          <th>Total</th>
          {mentions.map((m) => (
            <th key={m}>{m}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {notions.map((notion) => (
          <tr key={notion.code} className={notion.active ? undefined : styles.fusionnee}>
            <td>
              {notion.label}
              {notion.mergedIntoCode && (
                <span className={styles.fusionNote}>
                  {" "}→ fusionnée dans {notion.mergedIntoCode}
                </span>
              )}
            </td>
            <td className={styles.themeCell}>{notion.themeCode}</td>
            <td
              className={
                notion.questionsTaguees < SEUIL_CANDIDATE_FUSION ? styles.alerte : undefined
              }
            >
              {notion.questionsTaguees}
            </td>
            {mentions.map((mention) => {
              const compte =
                notion.parMention.find((m) => m.mention === mention)?.questions ?? 0;
              return (
                <td
                  key={mention}
                  className={compte < SEUIL_PLEINEMENT_UTILISABLE ? styles.attenue : undefined}
                >
                  {compte}
                </td>
              );
            })}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
