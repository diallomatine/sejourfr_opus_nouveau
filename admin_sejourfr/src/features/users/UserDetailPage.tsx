import { useState } from "react";
import type { ReactNode } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link, useLocation, useParams } from "react-router-dom";
import { HttpError, httpErrorMessage } from "../../api/http";
import { usersApi } from "../../api/usersApi";
import { Avatar } from "../../components/ui/Avatar";
import { BackLink } from "../../components/ui/BackLink";
import { Button } from "../../components/ui/Button";
import { Icon } from "../../components/ui/Icon";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { formatParisDate, formatParisDateTime } from "../../lib/dates";
import type {
  AdminAccessProductDto,
  AdminProductionCompteursDto,
  AdminRealtimeEoSessionsDto,
  AdminUserAccessDto,
  AdminUserDetailDto,
  AdminUserProgressionDto,
  AdminUserPurchaseDto,
} from "../../types/api";
import { ACCESS_STATUS_TONE, OPERATION_VARIANT, RESTRICTIVE_OPERATIONS } from "./accessTones";
import { AccessOperationModal } from "./components/AccessOperationModal";
import type { AccessOperationIntent } from "./components/AccessOperationModal";
import styles from "./UserDetailPage.module.css";

/** Accord d'affichage (0 et 1 au singulier, comme les phrases servies). */
function plural(n: number, word: string): string {
  return n > 1 ? `${word}s` : word;
}

function money(cents: number | null, currency: string | null): string {
  if (cents == null) return "—";
  return new Intl.NumberFormat("fr-FR", { style: "currency", currency: currency ?? "EUR" }).format(cents / 100);
}

/**
 * Fiche d'un utilisateur (spec §5), dans l'ordre : identité et accès effectif
 * lisibles en 5 s, accès par produit, achats (lecture seule), progression,
 * compte, historique admin. Tout est servi par `GET /api/admin/users/{id}` :
 * statuts, dates incluses, libellés, actions proposées (`availableOperations`).
 * ≥ 1180 px la fiche se lit sur deux colonnes (accès | dossier), comme le
 * panneau de la maquette ; en dessous, une seule.
 */
export function UserDetailPage() {
  const { id = "" } = useParams<{ id: string }>();
  const location = useLocation();
  const listSearch = (location.state as { listSearch?: string } | null)?.listSearch ?? "";
  const [intent, setIntent] = useState<AccessOperationIntent | null>(null);

  const detailQuery = useQuery({
    queryKey: ["adminUsers", "detail", id],
    queryFn: () => usersApi.detail(id),
    enabled: id !== "",
  });

  const productsQuery = useQuery({
    queryKey: ["adminAccessProducts"],
    queryFn: () => usersApi.products(),
    staleTime: 5 * 60_000,
  });

  const back = <BackLink to={`/users${listSearch}`} label="Retour aux utilisateurs" />;

  if (detailQuery.isPending) {
    return (
      <>
        {back}
        <Panel>
          <div className={styles.loading}>
            <Spinner label="Chargement de la fiche…" />
          </div>
        </Panel>
      </>
    );
  }

  if (detailQuery.isError) {
    const notFound = detailQuery.error instanceof HttpError && detailQuery.error.status === 404;
    return (
      <>
        {back}
        <Panel>
          {notFound ? (
            <EmptyState title="Utilisateur introuvable" description="Ce compte n'existe pas." />
          ) : (
            <div className={styles.error} role="alert">
              <span>Impossible de charger la fiche : {httpErrorMessage(detailQuery.error)}</span>
              <Button variant="default" size="sm" onClick={() => detailQuery.refetch()}>
                Réessayer
              </Button>
            </div>
          )}
        </Panel>
      </>
    );
  }

  const d = detailQuery.data;
  const name = d.account.displayName ?? d.account.email;
  const grant = () => setIntent({ operation: "GRANT", product: null, label: "Donner un accès" });

  return (
    <>
      {back}

      <div className={styles.layout}>
        <div className={styles.column}>
          <Panel>
            <header className={styles.hero}>
              <div className={styles.identity}>
                <Avatar name={d.account.displayName} email={d.account.email} size="lg" />
                <div className={styles.identityText}>
                  <h1 className={styles.name}>{name}</h1>
                  {d.account.displayName && <p className={styles.email}>{d.account.email}</p>}
                </div>
              </div>
              <div className={styles.heroMeta}>
                <Tag tone={d.account.accountStatus === "DELETED" ? "danger" : "success"} dot>
                  Compte {d.account.accountStatusLabel.toLowerCase()}
                </Tag>
                {d.account.role === "ADMIN" && <Tag tone="info">Administrateur</Tag>}
                {d.account.internal && <Tag tone="neutral">Compte interne</Tag>}
                <span className={styles.heroDate}>Inscrit le {formatParisDate(d.account.createdAt)}</span>
                <div className={styles.heroActions}>
                  {detailQuery.isFetching && (
                    <span className={styles.refreshing} role="status">
                      Mise à jour…
                    </span>
                  )}
                  <Button variant="primary" size="sm" onClick={grant}>
                    <Icon name="plus" size={15} />
                    Donner un accès
                  </Button>
                </div>
              </div>
            </header>

            <Section>
              <EffectiveAccessCard detail={d} />
            </Section>

            <Section title="Accès" subtitle="Un bloc par produit vendu — droit réellement appliqué dans l'application">
              <div className={styles.products}>
                {d.accesses.map((a) => (
                  <ProductCard
                    key={a.product}
                    access={a}
                    product={productsQuery.data?.find((p) => p.code === a.product)}
                    onAction={setIntent}
                  />
                ))}
              </div>
            </Section>
          </Panel>
        </div>

        <div className={styles.column}>
          <Panel>
            <Section
              title="Achats"
              subtitle="Historique commercial réel — lecture seule, jamais modifié depuis cette fiche"
            >
              <Purchases purchases={d.purchases} />
            </Section>

            <Section title="Progression" subtitle="Données déjà enregistrées, lues sans effet de bord">
              <div className={styles.stack}>
                {d.progression.map((p) => (
                  <ProgressionBox key={p.module} progression={p} />
                ))}
                <ProductionsBox userId={d.account.id} productions={d.productions} />
              </div>
            </Section>

            <Section title="Compte" subtitle="Lecture seule">
              <dl className={styles.infoGrid}>
                <Info label="Identifiant" wide>
                  <code className={styles.code}>{d.account.id}</code>
                </Info>
                <Info label="Email">{d.account.email}</Info>
                <Info label="Prénom / nom">
                  {[d.account.firstName, d.account.lastName].filter(Boolean).join(" ") || "—"}
                </Info>
                <Info label="Inscription">{formatParisDateTime(d.account.createdAt)}</Info>
                <Info label="Dernière connexion">{formatParisDateTime(d.account.lastLoginAt)}</Info>
                <Info label="Statut">{d.account.accountStatusLabel}</Info>
                <Info label="Connexion via">{d.account.authProvider}</Info>
                <Info label="Démarche / niveau visés" wide>
                  {[d.account.targetProcedure, d.account.targetLevel].filter(Boolean).join(" · ") || "—"}
                </Info>
              </dl>
            </Section>

            <Section title="Historique administratif" subtitle="Une entrée par action admin, avec son motif">
              <History detail={d} />
            </Section>
          </Panel>
        </div>
      </div>

      {intent && (
        <AccessOperationModal
          key={`${intent.operation}-${intent.product ?? "any"}`}
          userId={d.account.id}
          userLabel={d.account.email}
          accessVersion={d.accessVersion}
          accesses={d.accesses}
          intent={intent}
          onClose={() => setIntent(null)}
        />
      )}
    </>
  );
}

function Section({ title, subtitle, children }: { title?: string; subtitle?: string; children: ReactNode }) {
  return (
    <section className={styles.section}>
      {title && (
        <div className={styles.sectionHead}>
          <h2>{title}</h2>
          {subtitle && <span>{subtitle}</span>}
        </div>
      )}
      {children}
    </section>
  );
}

/** Carte dégradée : le couple servi « produit effectif / modules ouverts », puis l'état de chaque produit. */
function EffectiveAccessCard({ detail: d }: { detail: AdminUserDetailDto }) {
  const hasAccess = d.effectiveAccess.effectiveProduct !== "NONE";
  return (
    <div className={styles.accessCard}>
      <div className={styles.accessTop}>
        <div>
          <div className={styles.accessLabel}>Produit effectif</div>
          <div className={styles.accessProduct}>{d.effectiveAccess.effectiveProductLabel}</div>
        </div>
        <span className={`${styles.accessModules} ${hasAccess ? styles.accessModulesOpen : ""}`}>
          Modules ouverts : {d.effectiveAccess.openModulesLabel}
        </span>
      </div>
      <dl className={styles.accessGrid}>
        {d.accesses.map((a) => (
          <div key={a.product}>
            <dt>{a.productLabel}</dt>
            <dd>{a.summary}</dd>
            {a.originLabel && <dd className={styles.accessOrigin}>{a.originLabel}</dd>}
          </div>
        ))}
        <div>
          <dt>Dernière activité</dt>
          <dd>{d.lastActivityAt ? formatParisDateTime(d.lastActivityAt) : "Aucune"}</dd>
        </div>
      </dl>
    </div>
  );
}

function ProductCard({
  access: a,
  product,
  onAction,
}: {
  access: AdminUserAccessDto;
  product: AdminAccessProductDto | undefined;
  onAction: (intent: AccessOperationIntent) => void;
}) {
  return (
    <article className={`${styles.productCard} ${a.status === "ACTIVE" ? styles.productCardActive : ""}`}>
      <div className={styles.productTop}>
        <div className={styles.productHeading}>
          <h3 className={styles.productName}>{a.productLabel}</h3>
          {product && <div className={styles.productModules}>Ouvre : {product.modulesLabel}</div>}
        </div>
        <Tag tone={ACCESS_STATUS_TONE[a.status]} dot>
          {a.statusLabel}
        </Tag>
      </div>
      <p className={styles.productSummary}>{a.summary}</p>
      <dl className={styles.facts}>
        <div>
          <dt>Début</dt>
          <dd>{formatParisDate(a.startsAt)}</dd>
        </div>
        <div>
          <dt>Fin incluse</dt>
          <dd>{a.endLabel ?? "—"}</dd>
        </div>
        <div>
          <dt>Origine</dt>
          <dd>{a.originLabel ?? "—"}</dd>
        </div>
      </dl>
      {a.realtimeEoSessions && <RealtimeSessions sessions={a.realtimeEoSessions} />}
      {a.alerts.length > 0 && (
        <ul className={styles.alerts}>
          {a.alerts.map((al) => (
            <li key={al.code}>{al.label}</li>
          ))}
        </ul>
      )}
      {a.availableOperations.length > 0 && (
        <div className={styles.productActions}>
          {a.availableOperations.map((op) => (
            <Button
              key={op.code}
              size="sm"
              variant={OPERATION_VARIANT[op.code]}
              onClick={() => onAction({ operation: op.code, product: a.product, label: op.label })}
            >
              {op.label}
            </Button>
          ))}
        </div>
      )}
    </article>
  );
}

/**
 * Sessions EO temps réel de la carte Intégral (D-45) : la phrase et chaque
 * solde sont servis séparément (achat, accès manuel, accès programmé) ; rien
 * n'est additionné ici.
 */
function RealtimeSessions({ sessions: s }: { sessions: AdminRealtimeEoSessionsDto }) {
  return (
    <div className={styles.sessions}>
      <div className={styles.sessionsHead}>
        <Icon name="mic" size={15} />
        <span>Sessions EO temps réel</span>
      </div>
      <p className={styles.sessionsLabel}>{s.label}</p>
      <dl className={styles.sessionsFacts}>
        <div>
          <dt>Achat</dt>
          <dd>
            {s.purchaseRemaining === null ? "—" : `${s.purchaseRemaining} ${plural(s.purchaseRemaining, "restante")}`}
          </dd>
        </div>
        <div>
          <dt>Accès manuel</dt>
          <dd>
            {s.grantGranted === null || s.grantRemaining === null
              ? "—"
              : `${s.grantRemaining} ${plural(s.grantRemaining, "restante")} sur ${s.grantGranted} ${plural(s.grantGranted, "accordée")}`}
          </dd>
        </div>
        {s.scheduledGrantGranted !== null && (
          <div>
            <dt>Accès programmé</dt>
            <dd>
              {s.scheduledGrantGranted} {plural(s.scheduledGrantGranted, "accordée")}
            </dd>
          </div>
        )}
      </dl>
      {s.info && <p className={styles.sessionsInfo}>{s.info}</p>}
    </div>
  );
}

function Purchases({ purchases }: { purchases: AdminUserPurchaseDto[] }) {
  if (purchases.length === 0) {
    return (
      <div className={styles.infoItem}>
        <span>Achats</span>
        <strong>Aucun achat payant</strong>
      </div>
    );
  }
  return (
    <ul className={styles.stack}>
      {purchases.map((p) => (
        <li key={p.id} className={styles.purchase}>
          <div className={styles.purchaseLeft}>
            <span className={styles.purchaseIcon} aria-hidden="true">
              <Icon name="card" size={17} />
            </span>
            <div className={styles.purchaseText}>
              <strong>{p.planName ?? p.productLabel ?? p.planCode ?? "—"}</strong>
              <span>
                {p.sourceLabel} · {formatParisDateTime(p.purchasedAt ?? p.startsAt)} · {p.statusLabel}
                {p.paymentStatusLabel && ` · ${p.paymentStatusLabel}`}
              </span>
              <span>
                Fin : {p.endLabel ?? "—"}
                {p.externalReference && (
                  <>
                    {" "}
                    · Réf. <code className={styles.ref}>{p.externalReference}</code>
                  </>
                )}
              </span>
              {p.recurring && (
                <span className={styles.recurring}>
                  <Tag tone="warning">Abonnement récurrent</Tag>
                </span>
              )}
            </div>
          </div>
          <div className={styles.purchasePrice}>
            <strong>{money(p.amountCents, p.currency)}</strong>
            <span>Lecture seule</span>
          </div>
        </li>
      ))}
    </ul>
  );
}

function ProgressionBox({ progression: p }: { progression: AdminUserProgressionDto }) {
  const c = p.currentCycle;
  return (
    <article className={styles.progressBox}>
      <h3 className={styles.progressTitle}>{p.moduleLabel}</h3>
      <dl className={styles.infoGrid}>
        <Info label="Diagnostic">
          {p.diagnosticDone ? `Fait le ${formatParisDate(p.diagnosticCompletedAt)}` : "Non fait"}
        </Info>
        <Info label="Cycle en cours">{c ? `Depuis le ${formatParisDate(c.startedAt)}` : "Aucun cycle"}</Info>
        {c && (
          <>
            <Info label="Niveau d'entrée">{c.entryLevel ?? "—"}</Info>
            <Info label="Objectif">{[c.targetProcedure, c.targetLevel].filter(Boolean).join(" · ") || "—"}</Info>
            <Info label="Étapes closes">
              {c.stepsClosed} / {c.stepsTotal}
            </Info>
          </>
        )}
        <Info label="Cycles historisés">{p.historisedCycles}</Info>
      </dl>
    </article>
  );
}

/** Lien vers la liste Productions IA de ce compte : depuis toujours, comptes internes compris (D-57). */
function productionsLink(userId: string, avecExaminateur: boolean): string {
  const params = new URLSearchParams({ q: userId, internes: "1" });
  if (avecExaminateur) params.set("examinateur", "AVEC");
  return `/productions-ia?${params.toString()}`;
}

/** Productions EE/EO corrigées par IA, servies (D-57) : le front n'additionne rien. */
function ProductionsBox({ userId, productions: p }: { userId: string; productions: AdminProductionCompteursDto }) {
  return (
    <article className={styles.progressBox}>
      <h3 className={styles.progressTitle}>Productions IA (EE / EO)</h3>
      <div className={styles.productionFigures}>
        <Link to={productionsLink(userId, false)} className={styles.productionFigure}>
          <strong>{p.total}</strong>
          <span>{plural(p.total, "soumise")}</span>
        </Link>
        <Link to={productionsLink(userId, true)} className={styles.productionFigure}>
          <strong>{p.avecExaminateur}</strong>
          <span>avec examinateur IA</span>
        </Link>
      </div>
      {p.total > 0 && (
        <p className={styles.productionBreakdown}>
          EE {p.ee} · EO {p.eo} — {p.evaluees} {plural(p.evaluees, "évaluée")} · {p.nonEvaluables} non{" "}
          {plural(p.nonEvaluables, "évaluable")} · {p.enEchec} en échec
          {p.enCours > 0 && ` · ${p.enCours} en cours`}
          {p.signalees > 0 && ` · ${p.signalees} ${plural(p.signalees, "signalée")}`}
        </p>
      )}
    </article>
  );
}

function History({ detail: d }: { detail: AdminUserDetailDto }) {
  if (d.history.length === 0) {
    return <p className={styles.emptyNote}>Aucune action administrative sur ce compte.</p>;
  }
  return (
    <ol className={styles.timeline}>
      {d.history.map((h) => (
        <li
          key={h.operationId}
          className={`${styles.timelineItem} ${RESTRICTIVE_OPERATIONS.includes(h.operation) ? styles.timelineRed : ""}`}
        >
          <span className={styles.dot} aria-hidden="true" />
          <div className={styles.timelineContent}>
            <strong>
              {h.operationLabel} : {h.fromProductLabel ? `${h.fromProductLabel} → ${h.productLabel}` : h.productLabel}
            </strong>
            <p>
              {formatParisDateTime(h.createdAt)} — {h.adminEmail ?? h.adminId}
            </p>
            {h.changes.length > 0 && (
              <ul className={styles.changes}>
                {h.changes.map((c) => (
                  <li key={c}>{c}</li>
                ))}
              </ul>
            )}
            <p className={styles.reason}>Motif : {h.reason}</p>
          </div>
        </li>
      ))}
    </ol>
  );
}

function Info({ label, children, wide = false }: { label: string; children: ReactNode; wide?: boolean }) {
  return (
    <div className={`${styles.infoItem} ${wide ? styles.infoWide : ""}`}>
      <dt>{label}</dt>
      <dd>{children}</dd>
    </div>
  );
}
