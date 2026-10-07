import { useCallback, useEffect, useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useSearchParams } from "react-router-dom";
import { conversationsApi } from "../../api/conversationsApi";
import { httpErrorMessage } from "../../api/http";
import { Button } from "../../components/ui/Button";
import { Chips } from "../../components/ui/Chips";
import { Icon } from "../../components/ui/Icon";
import { InlineError } from "../../components/ui/InlineError";
import { PageHeader } from "../../components/ui/PageHeader";
import { Pagination } from "../../components/ui/Pagination";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { SearchField } from "../../components/ui/SearchField";
import { Spinner } from "../../components/ui/Spinner";
import { useMediaQuery } from "../../hooks/useMediaQuery";
import { oneOf, useClampPage, useUrlListState, useUrlSearchInput } from "../../hooks/useUrlListState";
import { ComposeMessageModal } from "./components/ComposeMessageModal";
import { ConversationDetail } from "./components/ConversationDetail";
import { ConversationList } from "./components/ConversationList";
import { MESSAGE_STATUSES, STATUS_LABELS } from "./conversationLabels";
import styles from "./ConversationsPage.module.css";

/** ≥ 1180 px : liste et fil côte à côte ; en dessous, l'un OU l'autre. */
const SPLIT_QUERY = "(min-width: 1180px)";
const LIST_SIZE = 50;
const NUMBER_FORMAT = new Intl.NumberFormat("fr-FR");

const STATUS_OPTIONS = [
  { value: "ALL", label: "Tous" },
  ...MESSAGE_STATUSES.map((s) => ({ value: s, label: STATUS_LABELS[s] })),
] as const;

const READ_OPTIONS = [
  { value: "ALL", label: "Tous" },
  { value: "UNREAD", label: "Non lus" },
] as const;

/**
 * Boîte de réception des messages du formulaire de contact (invités compris)
 * et des échanges avec les utilisateurs. Filtres, page et fil ouvert vivent
 * dans l'URL (`status`, `unread`, `q`, `page`, `c`) : en vue compacte, le
 * bouton retour du navigateur ramène du fil à la liste.
 */
export function ConversationsPage() {
  const { params, page, size, setFilter, setPage, resetFilters } = useUrlListState(LIST_SIZE);
  const [, setSearchParams] = useSearchParams();
  const split = useMediaQuery(SPLIT_QUERY);
  const [composing, setComposing] = useState(false);

  const status = oneOf(params.get("status"), MESSAGE_STATUSES);
  const unreadOnly = params.get("unread") === "1";
  const q = params.get("q") ?? "";
  const selectedId = params.get("c");
  const hasActiveFilter = Boolean(status || unreadOnly || q);

  const commitSearch = useCallback(
    (value: string | undefined) => setFilter("q", value, { replace: true }),
    [setFilter],
  );
  const [searchInput, setSearchInput] = useUrlSearchInput(q, commitSearch);

  const select = useCallback(
    (id: string | null, options?: { replace?: boolean }) =>
      setSearchParams(
        (prev) => {
          const next = new URLSearchParams(prev);
          if (id) next.set("c", id);
          else next.delete("c");
          return next;
        },
        { replace: options?.replace ?? false },
      ),
    [setSearchParams],
  );

  const listQuery = useQuery({
    queryKey: ["conversations", { status, unreadOnly, q, page, size }],
    queryFn: () =>
      conversationsApi.search({
        status,
        unreadOnly: unreadOnly || undefined,
        search: q || undefined,
        page,
        size,
      }),
    placeholderData: keepPreviousData,
  });

  const unreadQuery = useQuery({
    queryKey: ["conversations", "unread-count"],
    queryFn: () => conversationsApi.unreadCount(),
  });

  const data = listQuery.data;
  const isStale = listQuery.isPlaceholderData;
  useClampPage(data?.totalPages, isStale, page, setPage);

  // Côte à côte, le premier fil s'ouvre d'office ; une sélection posée reste
  // ouverte même si le fil sort de la liste filtrée (lu, archivé…).
  const firstId = data?.content[0]?.id;
  useEffect(() => {
    if (split && !selectedId && firstId && !isStale) select(firstId, { replace: true });
  }, [split, selectedId, firstId, isStale, select]);

  const handleReset = () => {
    setSearchInput("");
    resetFilters();
  };

  const unreadCount = unreadQuery.data?.count;
  const sub = data
    ? [
        `${NUMBER_FORMAT.format(data.totalElements)} conversation${data.totalElements > 1 ? "s" : ""}`,
        unreadCount ? `${NUMBER_FORMAT.format(unreadCount)} non lue${unreadCount > 1 ? "s" : ""}` : null,
      ]
        .filter(Boolean)
        .join(" · ")
    : undefined;

  const inbox = (
    <Panel
      title="Boîte de réception"
      sub={sub}
      actions={
        listQuery.isFetching && data ? (
          <span className={styles.refreshing} role="status">
            Mise à jour…
          </span>
        ) : undefined
      }
      noPadding
    >
      <div className={styles.toolbar}>
        <SearchField
          label="Rechercher une conversation par son objet"
          placeholder="Rechercher dans les objets…"
          value={searchInput}
          onChange={setSearchInput}
        />
        <Chips
          label="Filtrer par statut"
          options={STATUS_OPTIONS}
          value={status ?? "ALL"}
          onChange={(value) => setFilter("status", value === "ALL" ? undefined : value)}
        />
        <Chips
          label="Filtrer par lecture"
          options={READ_OPTIONS}
          value={unreadOnly ? "UNREAD" : "ALL"}
          onChange={(value) => setFilter("unread", value === "UNREAD" ? "1" : undefined)}
        />
      </div>

      {listQuery.isPending && (
        <div className={styles.loading}>
          <Spinner label="Chargement des conversations…" />
        </div>
      )}

      {listQuery.isError && (
        <InlineError onRetry={() => listQuery.refetch()}>
          {data ? "Actualisation impossible" : "Impossible de charger les conversations"} :{" "}
          {httpErrorMessage(listQuery.error)}
        </InlineError>
      )}

      {data &&
        (data.totalElements === 0 ? (
          hasActiveFilter ? (
            <div className={styles.emptyWithAction}>
              <EmptyState title="Aucune conversation ne correspond" description="Modifiez la recherche ou les filtres." />
              <Button size="sm" onClick={handleReset}>
                Réinitialiser
              </Button>
            </div>
          ) : (
            <EmptyState
              title="Aucune conversation"
              description="Les messages envoyés depuis le formulaire de contact arriveront ici."
            />
          )
        ) : (
          <div className={`${styles.listScroll} ${isStale ? styles.stale : ""}`} aria-busy={isStale}>
            <ConversationList items={data.content} selectedId={selectedId} onSelect={(id) => select(id)} />
          </div>
        ))}

      {data && data.totalPages > 1 && (
        <Pagination
          page={data.page}
          size={data.size}
          totalElements={data.totalElements}
          totalPages={data.totalPages}
          onPageChange={(p) => setPage(p)}
          busy={listQuery.isFetching}
          itemLabel="conversations"
        />
      )}
    </Panel>
  );

  const detail = selectedId ? (
    <ConversationDetail
      key={selectedId}
      conversationId={selectedId}
      onDeleted={() => select(null, { replace: true })}
      onBack={split ? undefined : () => select(null)}
    />
  ) : (
    <Panel>
      <EmptyState
        title="Sélectionnez une conversation"
        description="Choisissez un fil dans la liste pour le lire et y répondre."
      />
    </Panel>
  );

  return (
    <>
      <PageHeader
        title="Conversations"
        description="Les messages du formulaire de contact, invités sans compte compris, et les échanges avec les utilisateurs. Une réponse part par email au contact."
        actions={
          <Button variant="primary" onClick={() => setComposing(true)}>
            <Icon name="plus" size={15} />
            Nouveau message
          </Button>
        }
      />

      {composing && (
        <ComposeMessageModal onClose={() => setComposing(false)} onSent={(c) => select(c.id)} />
      )}

      {split ? (
        <div className={styles.split}>
          <section className={styles.listColumn} aria-label="Boîte de réception">
            {inbox}
          </section>
          <section className={styles.detailColumn} aria-label="Conversation ouverte">
            {detail}
          </section>
        </div>
      ) : selectedId ? (
        <section aria-label="Conversation ouverte">{detail}</section>
      ) : (
        <section aria-label="Boîte de réception">{inbox}</section>
      )}
    </>
  );
}
