import { useState } from "react";
import type { ReactNode } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, useNavigate, useParams } from "react-router-dom";
import { HttpError } from "../../api/http";
import { skillsApi } from "../../api/skillsApi";
import { Button } from "../../components/ui/Button";
import { PageHeader } from "../../components/ui/PageHeader";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import type {
  AdminSkillDto,
  AdminSkillPromptDto,
  SkillSection,
} from "../../types/api";
import { ConstraintIcon } from "./ConstraintIcon";
import { SkillFormModal } from "./SkillFormModal";
import { SkillPromptFormModal } from "./SkillPromptFormModal";
import { SkillReferencesModal } from "./SkillReferencesModal";
import {
  DIFFICULTY_LABEL,
  DIFFICULTY_TONE,
  SECTION_LABEL,
  SECTION_TONE,
  TASK_TITLE,
  deletionBlockedMessage,
  formatDate,
  formatRecommendation,
  guidanceState,
  referencesComplete,
  targetLevelTone,
  truncate,
} from "./skillHelpers";
import tableStyles from "../../components/ui/DataTable.module.css";
import styles from "./SkillDetailPage.module.css";

interface PromptTarget {
  id: string;
  code: string;
  title: string;
}

export function SkillDetailPage() {
  const params = useParams<{ id: string }>();
  const skillId = params.id as string;
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const toast = useToast();

  const [editingSkill, setEditingSkill] = useState(false);
  const [promptFormOpen, setPromptFormOpen] = useState(false);
  const [editingPromptId, setEditingPromptId] = useState<string | null>(null);
  const [referencesTarget, setReferencesTarget] = useState<PromptTarget | null>(null);

  const detailQuery = useQuery({
    queryKey: ["adminSkills", "detail", skillId],
    queryFn: () => skillsApi.getById(skillId),
  });

  const skill = detailQuery.data?.skill;
  const prompts = detailQuery.data?.prompts ?? [];

  const toggleMutation = useMutation({
    mutationFn: (next: AdminSkillDto) =>
      skillsApi.update(next.id, {
        title: next.title,
        description: next.description,
        generalCriterion: next.generalCriterion,
        targetLevel: next.targetLevel,
        displayOrder: next.displayOrder,
        active: !next.active,
      }),
    onSuccess: (saved) => {
      queryClient.invalidateQueries({ queryKey: ["adminSkills"] });
      toast.show(
        saved.active ? "Compétence activée" : "Compétence désactivée",
        "success",
      );
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const deleteSkillMutation = useMutation({
    mutationFn: () => skillsApi.remove(skillId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["adminSkills"] });
      toast.show("Compétence supprimée", "success");
      navigate("/skills");
    },
    onError: (err) => {
      if (err instanceof HttpError && err.status === 409) {
        toast.show(deletionBlockedMessage("skill"), "error");
        return;
      }
      toast.show((err as Error).message, "error");
    },
  });

  const deletePromptMutation = useMutation({
    mutationFn: (promptId: string) => skillsApi.removePrompt(promptId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["adminSkills"] });
      queryClient.invalidateQueries({ queryKey: ["adminSkillPrompts"] });
      toast.show("Sujet supprimé", "success");
    },
    onError: (err) => {
      if (err instanceof HttpError && err.status === 409) {
        toast.show(deletionBlockedMessage("prompt"), "error");
        return;
      }
      toast.show((err as Error).message, "error");
    },
  });

  const openPromptForm = (promptId: string | null) => {
    setEditingPromptId(promptId);
    setPromptFormOpen(true);
  };

  const handleDeletePrompt = (prompt: AdminSkillPromptDto) => {
    const warning =
      prompt.attemptCount > 0
        ? `\n\n${prompt.attemptCount} tentative(s) candidat existent : le serveur refusera la suppression. Désactivez plutôt le sujet.`
        : "";
    if (!window.confirm(`Supprimer le sujet ${prompt.code} ?${warning}`)) return;
    deletePromptMutation.mutate(prompt.id);
  };

  const nextOrder =
    prompts.length === 0
      ? 1
      : Math.min(20, Math.max(...prompts.map((p) => p.displayOrder)) + 1);

  return (
    <>
      <div className={styles.breadcrumb}>
        <Link to="/skills" className={styles.breadcrumbLink}>
          ← Toutes les compétences
        </Link>
      </div>

      {detailQuery.isLoading && <Spinner label="Chargement de la compétence..." />}

      {detailQuery.isError && (
        <Panel>
          <div className={styles.error}>
            Erreur : {(detailQuery.error as Error).message}
          </div>
        </Panel>
      )}

      {skill && (
        <>
          <PageHeader
            eyebrow={`${skill.code} · ${SECTION_LABEL[skill.section]} · ${skill.taskCode}`}
            title={skill.title}
            actions={
              <div className={styles.headerActions}>
                <Button variant="ghost" onClick={() => setEditingSkill(true)}>
                  Modifier
                </Button>
                <Button
                  variant={skill.active ? "default" : "primary"}
                  onClick={() => toggleMutation.mutate(skill)}
                  disabled={toggleMutation.isPending}
                >
                  {skill.active ? "Désactiver" : "Activer"}
                </Button>
              </div>
            }
          />

          <Panel title="Fiche" sub={TASK_TITLE[skill.taskCode]}>
            <div className={styles.factGrid}>
              <Fact label="Code">
                <code className={styles.code}>{skill.code}</code>
                <span className={styles.factHint}>immuable</span>
              </Fact>
              <Fact label="Épreuve">
                <Tag tone={SECTION_TONE[skill.section]}>
                  {SECTION_LABEL[skill.section]}
                </Tag>
              </Fact>
              <Fact label="Niveau visé">
                <Tag tone={targetLevelTone(skill.targetLevel)}>{skill.targetLevel}</Tag>
              </Fact>
              <Fact label="Rang d'affichage">
                <span className={styles.mono}>{skill.displayOrder} / 8</span>
              </Fact>
              <Fact label="Statut">
                {skill.active ? (
                  <Tag tone="active">Active</Tag>
                ) : (
                  <Tag tone="muted">Inactive</Tag>
                )}
              </Fact>
              <Fact label="Petits sujets">
                <span className={styles.mono}>{skill.promptCount}</span>
              </Fact>
              <Fact label="Créée le">
                <span className={styles.mono}>{formatDate(skill.createdAt)}</span>
              </Fact>
              <Fact label="Modifiée le">
                <span className={styles.mono}>{formatDate(skill.updatedAt)}</span>
              </Fact>
            </div>

            <div className={styles.textBlocks}>
              <div className={styles.descriptionBlock}>
                <div className={styles.descriptionLabel}>
                  Description · lue par le candidat
                </div>
                <p className={styles.description}>{skill.description}</p>
              </div>

              <div className={styles.descriptionBlock}>
                <div className={styles.descriptionLabel}>
                  Critère général travaillé
                </div>
                <p className={styles.description}>{skill.generalCriterion}</p>
                <p className={styles.blockHint}>
                  Ce qui est observé dans les {skill.promptCount} sujet(s) de la
                  compétence. Chaque sujet porte en plus son critère unique.
                </p>
              </div>
            </div>
          </Panel>

          <Panel
            title="Petits sujets"
            sub={`${prompts.length} sujet(s) · triés par rang d'affichage`}
            noPadding
            actions={
              <Button variant="red" size="sm" onClick={() => openPromptForm(null)}>
                Nouveau sujet
              </Button>
            }
          >
            {prompts.length === 0 ? (
              <EmptyState
                title="Aucun petit sujet"
                description="Une compétence sert 15 petits sujets. Commencez par en créer un."
              />
            ) : (
              <div className={tableStyles.tableWrap}>
                <table className={`${tableStyles.table} ${tableStyles.cardTable}`}>
                  <thead>
                    <tr>
                      <th>Sujet</th>
                      <th>Difficulté</th>
                      <th>{skill.section === "EE" ? "Longueur" : "Durée"}</th>
                      <th>Rang</th>
                      <th>Guidage de saisie</th>
                      <th>Références</th>
                      <th>Tentatives</th>
                      <th>Statut</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {[...prompts]
                      .sort((a, b) => a.displayOrder - b.displayOrder)
                      .map((prompt) => (
                        <tr key={prompt.id}>
                          <td data-label="Sujet">
                            <div className={styles.codeLine}>
                              <code>{prompt.code}</code>
                            </div>
                            <strong>{prompt.title}</strong>
                            <div className={styles.criterionLine}>
                              <span className={styles.criterionTag}>Critère</span>
                              {truncate(prompt.uniqueCriterion, 120)}
                            </div>
                          </td>
                          <td data-label="Difficulté">
                            <Tag tone={DIFFICULTY_TONE[prompt.difficultyLevel]}>
                              {DIFFICULTY_LABEL[prompt.difficultyLevel]}
                            </Tag>
                          </td>
                          <td data-label={skill.section === "EE" ? "Longueur" : "Durée"}>
                            <span className={styles.mono}>
                              {formatRecommendation(prompt)}
                            </span>
                          </td>
                          <td data-label="Rang">
                            <span className={styles.mono}>{prompt.displayOrder}</span>
                          </td>
                          <td data-label="Guidage de saisie">
                            <GuidanceCell prompt={prompt} section={skill.section} />
                          </td>
                          <td data-label="Références">
                            {referencesComplete(prompt.references) ? (
                              <Tag tone="active">3 / 3</Tag>
                            ) : (
                              <Tag tone="draft">À compléter</Tag>
                            )}
                          </td>
                          <td data-label="Tentatives">
                            <span className={styles.mono}>{prompt.attemptCount}</span>
                          </td>
                          <td data-label="Statut">
                            {prompt.active ? (
                              <Tag tone="active">Actif</Tag>
                            ) : (
                              <Tag tone="muted">Inactif</Tag>
                            )}
                          </td>
                          <td data-label="Actions">
                            <div className={tableStyles.rowActions}>
                              <button
                                type="button"
                                className={tableStyles.iconBtn}
                                onClick={() => openPromptForm(prompt.id)}
                              >
                                Modifier
                              </button>
                              <button
                                type="button"
                                className={tableStyles.iconBtn}
                                onClick={() =>
                                  setReferencesTarget({
                                    id: prompt.id,
                                    code: prompt.code,
                                    title: prompt.title,
                                  })
                                }
                              >
                                Références
                              </button>
                              <button
                                type="button"
                                className={`${tableStyles.iconBtn} ${tableStyles.danger}`}
                                onClick={() => handleDeletePrompt(prompt)}
                                disabled={deletePromptMutation.isPending}
                              >
                                Supprimer
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}
          </Panel>

          <Panel title="Retrait de la compétence">
            <p className={styles.dangerText}>
              Le geste normal est de <strong>désactiver</strong> : la compétence
              disparaît des parcours candidat, son historique reste intact. La
              suppression n&apos;est possible que tant qu&apos;aucun candidat
              n&apos;a travaillé l&apos;un de ses sujets — passé ce point, le
              serveur la refuse.
            </p>
            <Button
              variant="danger"
              onClick={() => {
                if (
                  !window.confirm(
                    `Supprimer définitivement la compétence ${skill.code} et ses ${skill.promptCount} sujet(s) ?`,
                  )
                )
                  return;
                deleteSkillMutation.mutate();
              }}
              disabled={deleteSkillMutation.isPending}
            >
              {deleteSkillMutation.isPending
                ? "Suppression..."
                : "Supprimer la compétence"}
            </Button>
          </Panel>

          <SkillFormModal
            open={editingSkill}
            skill={skill}
            onClose={() => setEditingSkill(false)}
          />

          <SkillPromptFormModal
            open={promptFormOpen}
            skillId={skill.id}
            skillCode={skill.code}
            section={skill.section}
            promptId={editingPromptId}
            suggestedOrder={nextOrder}
            onClose={() => {
              setPromptFormOpen(false);
              setEditingPromptId(null);
            }}
          />

          <SkillReferencesModal
            open={referencesTarget !== null}
            promptId={referencesTarget?.id ?? null}
            promptCode={referencesTarget?.code ?? ""}
            promptTitle={referencesTarget?.title ?? ""}
            onClose={() => setReferencesTarget(null)}
          />
        </>
      )}
    </>
  );
}

/**
 * Le guidage tel qu'il arrivera à l'écran du candidat : les quatre champs sont
 * montrés en lecture, pas seulement en édition — un éditeur doit pouvoir
 * relire ce qu'il publie sans rouvrir la modal. Chaque bloc absent disparaît :
 * un sujet sans guidage reste légal, les fronts retombent sur la consigne.
 */
function GuidanceCell({
  prompt,
  section,
}: {
  prompt: AdminSkillPromptDto;
  section: SkillSection;
}) {
  const state = guidanceState(prompt);
  const checklist = prompt.checklist ?? [];
  const tags = prompt.constraintTags ?? [];

  return (
    <div className={styles.guidance}>
      {state === "complete" && <Tag tone="active">Complet</Tag>}
      {state === "partial" && <Tag tone="draft">À compléter</Tag>}
      {state === "absent" && <Tag tone="muted">Absent</Tag>}

      {state === "absent" ? (
        <p className={styles.guidanceEmpty}>
          L&apos;écran de saisie retombera sur la consigne : ni check-list, ni
          étiquette, ni amorce, ni astuce.
        </p>
      ) : (
        <>
          {checklist.length > 0 && (
            <ol className={styles.guidanceList}>
              {checklist.map((action, index) => (
                <li key={`${index}-${action}`}>{action}</li>
              ))}
            </ol>
          )}

          {tags.length > 0 && (
            <div className={styles.guidanceTags}>
              {tags.map((tag) => (
                <span key={`${tag.icon}-${tag.label}`} className={styles.guidanceChip}>
                  <ConstraintIcon icon={tag.icon} size={13} />
                  {tag.label}
                </span>
              ))}
            </div>
          )}

          {prompt.answerStarter && (
            <p className={styles.guidanceStarter}>
              <span className={styles.guidanceLabel}>Amorce</span>
              {prompt.answerStarter}
            </p>
          )}

          {prompt.tip && (
            <p className={styles.guidanceTip}>
              <span className={styles.guidanceLabel}>Astuce</span>
              {prompt.tip}
            </p>
          )}

          {state === "partial" && (
            <p className={styles.guidanceEmpty}>
              Manque
              {[
                checklist.length === 0 ? " la check-list" : null,
                tags.length === 0 ? " les étiquettes" : null,
                !prompt.answerStarter ? " l'amorce" : null,
                !prompt.tip ? " l'astuce" : null,
              ]
                .filter((part): part is string => part !== null)
                .join(",")}
              . Le reste de l&apos;écran{" "}
              {section === "EE" ? "de saisie" : "d'enregistrement"} s&apos;affiche
              quand même.
            </p>
          )}
        </>
      )}
    </div>
  );
}

function Fact({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className={styles.fact}>
      <div className={styles.factLabel}>{label}</div>
      <div className={styles.factValue}>{children}</div>
    </div>
  );
}
