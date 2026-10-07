import { useState } from "react";
import type { ReactNode } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link, useLocation, useParams } from "react-router-dom";
import { HttpError, httpErrorMessage } from "../../api/http";
import { productionsApi } from "../../api/productionsApi";
import { BackLink } from "../../components/ui/BackLink";
import { Button } from "../../components/ui/Button";
import { Collapsible } from "../../components/ui/Collapsible";
import { Icon } from "../../components/ui/Icon";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { formatParisDateTime } from "../../lib/dates";
import { NIVEAU_LABEL } from "../../lib/evaluation";
import type { AdminProductionDetailDto } from "../../types/api";
import { HumanNoteModal } from "../calibration/components/HumanNoteModal";
import { CalculBlock, NiveauIaVsRetenu } from "./components/CalculBlock";
import { CandidateFeedback } from "./components/CandidateFeedback";
import { EvaluationIaBlock } from "./components/EvaluationIaBlock";
import { Facts, NotAvailable, SectionLabel } from "./components/Facts";
import { ActiveFlagBanner, FlagHistory } from "./components/FlagSection";
import { FlagModal } from "./components/FlagModal";
import { ReponseBlock } from "./components/ReponseBlock";
import { TechBlock } from "./components/TechBlock";
import { EPREUVE_NOM, EPREUVE_SIGLE, EXAMINATEUR_IA_BADGE, SIGNALEMENT_TONE, STATUT_TONE, formatSeconds } from "./productionLabels";
import styles from "./ProductionDetailPage.module.css";

/**
 * Fiche d'une production (`GET /api/admin/productions/{id}`), dans l'ordre du
 * brief : contexte, sujet, réponse, évaluation IA, calcul SejourFR, feedback
 * candidat, technique, JSON persisté, signalements. Lecture passive : seules
 * les actions explicites (signaler, vérifier, retirer, annoter) écrivent.
 */
export function ProductionDetailPage() {
  const { id = "" } = useParams<{ id: string }>();
  const location = useLocation();
  const listSearch = (location.state as { listSearch?: string } | null)?.listSearch ?? "";
  const [flagOpen, setFlagOpen] = useState(false);
  const [annotateOpen, setAnnotateOpen] = useState(false);

  const detailQuery = useQuery({
    queryKey: ["adminProductions", "detail", id],
    queryFn: () => productionsApi.detail(id),
    enabled: id !== "",
  });

  const back = <BackLink to={`/productions-ia${listSearch}`} label="Retour aux productions" />;

  if (detailQuery.isPending) {
    return (
      <>
        {back}
        <div className={styles.loading}>
          <Spinner label="Chargement de la production…" />
        </div>
      </>
    );
  }

  if (detailQuery.isError) {
    const notFound = detailQuery.error instanceof HttpError && detailQuery.error.status === 404;
    return (
      <>
        {back}
        <Panel>
          <div className={styles.errorBox}>
            <EmptyState
              title={notFound ? "Production introuvable" : "Impossible de charger la production"}
              description={
                notFound
                  ? "Cette production n'existe pas ou n'est pas une production EE/EO corrigée par IA."
                  : httpErrorMessage(detailQuery.error)
              }
            />
            {!notFound && (
              <Button variant="default" size="sm" onClick={() => detailQuery.refetch()}>
                Réessayer
              </Button>
            )}
          </div>
        </Panel>
      </>
    );
  }

  const detail = detailQuery.data;
  const { entete } = detail;
  const activeFlag = detail.signalements.find((f) => f.etat !== "RETIRE") ?? null;
  const canAnnotate = entete.statutIa === "EVALUEE";
  const epreuveNom = EPREUVE_NOM[entete.epreuve] ?? entete.epreuve;

  return (
    <div className={styles.page}>
      {back}

      <Hero
        detail={detail}
        actions={
          <>
            {canAnnotate && (
              <Button variant="default" onClick={() => setAnnotateOpen(true)}>
                {entete.annotee ? "Revoir l'annotation" : "Annoter (calibration)"}
              </Button>
            )}
            {detail.signalable && (
              <Button variant="danger" onClick={() => setFlagOpen(true)}>
                <Icon name="flag" size={16} />
                Signaler cette évaluation
              </Button>
            )}
          </>
        }
      />

      {activeFlag && <ActiveFlagBanner flag={activeFlag} />}

      <Section title="Sujet" hint="Tel que reçu par le candidat">
        <SujetBlock detail={detail} />
      </Section>

      <Section
        title="Réponse du candidat"
        hint={entete.epreuve === "TCF_EO" ? "Transcription automatique, pas une retranscription fidèle" : undefined}
      >
        <ReponseBlock reponse={detail.reponse} epreuve={entete.epreuve} />
      </Section>

      <Section title="Évaluation IA" hint="Scores retenus après garde-fous serveur, sur 20">
        {detail.evaluationIa ? (
          <EvaluationIaBlock
            evaluation={detail.evaluationIa}
            criteresAuPlafond={detail.calcul.couplage?.criteresAuPlafond ?? []}
          />
        ) : (
          <NotAvailable>Aucune évaluation enregistrée ({entete.statutIaLabel.toLowerCase()})</NotAvailable>
        )}
      </Section>

      <Section title="Calcul SejourFR" hint="Relu avec la grille de l'évaluation" variant="calc">
        <CalculBlock calcul={detail.calcul} />
        {detail.evaluationIa && detail.evaluationIa.evaluabilite === "EVALUABLE" && (
          <NiveauIaVsRetenu evaluation={detail.evaluationIa} />
        )}
      </Section>

      <Section title="Feedback candidat" hint="Ce que le candidat a vu">
        {detail.vueCandidat.evaluation ? (
          <CandidateFeedback evaluation={detail.vueCandidat.evaluation} />
        ) : (
          <NotAvailable>Aucun feedback : la production n&apos;a pas d&apos;évaluation</NotAvailable>
        )}
      </Section>

      <Collapsible title="Informations techniques" hint={detail.technique.modele ?? undefined}>
        <TechBlock technique={detail.technique} />
      </Collapsible>

      <Collapsible title="JSON persisté après traitement serveur" hint="Lecture seule — ce n'est pas la réponse de l'IA">
        {detail.jsonPersiste ? (
          <pre className={styles.json}>{JSON.stringify(detail.jsonPersiste, null, 2)}</pre>
        ) : (
          <NotAvailable>Aucun JSON enregistré (pas d&apos;évaluation)</NotAvailable>
        )}
      </Collapsible>

      {detail.signalements.length > 0 && (
        <Section title="Historique des signalements" hint={`${detail.signalements.length} au total, retirés compris`}>
          <FlagHistory flags={detail.signalements} />
        </Section>
      )}

      {flagOpen && <FlagModal productionId={entete.id} onClose={() => setFlagOpen(false)} />}

      {annotateOpen && (
        <HumanNoteModal
          submissionId={entete.id}
          noteIa={detail.evaluationIa?.noteSur20 ?? null}
          description={`${epreuveNom}, tâche ${entete.tache} · ${entete.userEmail}`}
          onClose={() => setAnnotateOpen(false)}
        />
      )}
    </div>
  );
}

function Hero({ detail, actions }: { detail: AdminProductionDetailDto; actions: ReactNode }) {
  const { entete } = detail;
  const niveau = entete.niveauObserve;
  const montre = detail.evaluationIa?.niveauMontreAuCandidat ?? false;

  return (
    <section className={styles.hero}>
      <div className={styles.heroMain}>
        <div className={styles.heroTags}>
          <Tag tone="info">{EPREUVE_SIGLE[entete.epreuve] ?? entete.epreuve}</Tag>
          {entete.source === "REALTIME" && <Tag tone="neutral">{EXAMINATEUR_IA_BADGE}</Tag>}
          <Tag tone={STATUT_TONE[entete.statutIa]} dot>
            {entete.statutIaLabel}
          </Tag>
          {entete.etatSignalement !== "AUCUN" && (
            <Tag tone={SIGNALEMENT_TONE[entete.etatSignalement]} dot>
              {entete.etatSignalementLabel}
            </Tag>
          )}
          {entete.annotee && <Tag tone="neutral">Annotée</Tag>}
          {entete.userInternal && <Tag tone="neutral">Compte interne</Tag>}
        </div>
        <h1 className={styles.heroTitle}>
          {EPREUVE_NOM[entete.epreuve] ?? entete.epreuve}, tâche {entete.tache}
        </h1>
        <p className={styles.heroId}>Production {entete.id}</p>
      </div>

      <div className={styles.heroLevel}>
        <span className={`${styles.levelRound} ${niveau ? "" : styles.levelNone}`}>
          {niveau ? NIVEAU_LABEL[niveau] : "—"}
        </span>
        <span className={styles.levelLabel}>Niveau observé (tâche)</span>
        {niveau && !montre && <span className={styles.levelNote}>Non montré au candidat</span>}
      </div>

      <div className={styles.heroFacts}>
        <Facts
          columns={4}
          items={[
            {
              label: "Candidat",
              value: (
                <Link to={`/users/${entete.userId}`} className={styles.inlineLink}>
                  {entete.userEmail}
                </Link>
              ),
            },
            { label: "ID utilisateur", value: entete.userId, mono: true },
            { label: "Soumise le", value: formatParisDateTime(entete.submittedAt) },
            {
              label: "Contexte",
              value: entete.contexteLabel,
            },
          ]}
        />
        <p className={styles.heroNote}>
          Le niveau qui fait foi pour le candidat est celui de l&apos;épreuve : une tâche isolée ne décide
          jamais de son niveau.
        </p>
      </div>

      <div className={styles.heroActions}>{actions}</div>
    </section>
  );
}

function SujetBlock({ detail }: { detail: AdminProductionDetailDto }) {
  const { sujet } = detail;
  const bornes =
    sujet.motsMin !== null || sujet.motsMax !== null
      ? `${sujet.motsMin ?? "—"} à ${sujet.motsMax ?? "—"} mots`
      : sujet.dureeMinSec !== null || sujet.dureeMaxSec !== null
        ? `${sujet.dureeMinSec === null ? "—" : formatSeconds(sujet.dureeMinSec)} à ${sujet.dureeMaxSec === null ? "—" : formatSeconds(sujet.dureeMaxSec)}`
        : null;

  return (
    <div className={styles.sujet}>
      <div>
        <SectionLabel>Titre</SectionLabel>
        <p className={styles.sujetTitle}>{sujet.titre ?? <NotAvailable>Sans titre</NotAvailable>}</p>
      </div>
      <div>
        <SectionLabel>Consigne</SectionLabel>
        <p className={styles.prose}>{sujet.consigne}</p>
      </div>
      {sujet.contexte && (
        <div>
          <SectionLabel>Contexte</SectionLabel>
          <p className={styles.prose}>{sujet.contexte}</p>
        </div>
      )}
      <Facts
        columns={3}
        items={[
          { label: "Niveau visé du sujet", value: sujet.niveauCible },
          { label: "Longueur attendue", value: bornes },
          { label: "ID du sujet", value: sujet.productionTaskId, mono: true },
        ]}
      />
    </div>
  );
}

function Section({
  title,
  hint,
  variant,
  children,
}: {
  title: string;
  hint?: string;
  variant?: "calc";
  children: ReactNode;
}) {
  return (
    <Panel title={title} sub={hint}>
      <div className={`${styles.sectionBody} ${variant === "calc" ? styles.sectionCalc : ""}`}>{children}</div>
    </Panel>
  );
}
