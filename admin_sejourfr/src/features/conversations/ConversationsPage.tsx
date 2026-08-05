import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { conversationsApi } from "../../api/conversationsApi";
import { Button } from "../../components/ui/Button";
import { EmptyState, Panel } from "../../components/ui/Panel";
import { PageHeader } from "../../components/ui/PageHeader";
import { Spinner } from "../../components/ui/Spinner";
import { Tag } from "../../components/ui/Tag";
import { useToast } from "../../components/ui/Toast";
import type { MessageStatus } from "../../types/api";
import styles from "./ConversationsPage.module.css";

const STATUS_LABELS: Record<MessageStatus, string> = {
  NOUVEAU: "Nouveau",
  LU: "Lu",
  EN_COURS: "En cours",
  REPONDU: "Répondu",
  ARCHIVE: "Archivé",
};

const STATUS_TONES: Record<MessageStatus, "csp" | "muted" | "cr" | "active" | "draft"> = {
  NOUVEAU: "csp",
  LU: "muted",
  EN_COURS: "cr",
  REPONDU: "active",
  ARCHIVE: "draft",
};

export function ConversationsPage() {
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const listQuery = useQuery({
    queryKey: ["conversations", { statusFilter, unreadOnly }],
    queryFn: () =>
      conversationsApi.search({
        status: (statusFilter as MessageStatus) || undefined,
        unreadOnly: unreadOnly || undefined,
        size: 50,
      }),
  });

  // Selection auto du premier element a chaque arrivee de liste
  useEffect(() => {
    if (
      listQuery.data &&
      listQuery.data.content.length > 0 &&
      (!selectedId ||
        !listQuery.data.content.some((c) => c.id === selectedId))
    ) {
      setSelectedId(listQuery.data.content[0].id);
    }
  }, [listQuery.data, selectedId]);

  return (
    <>
      <PageHeader
        eyebrow="§ 04 — Échanges utilisateurs"
        title="Conver"
        emphasis="sations"
      />

      <div className={styles.layout}>
        <div className={styles.listPanel}>
          <div className={styles.listFilters}>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="">Tous statuts</option>
              {Object.entries(STATUS_LABELS).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
            <label className={styles.unreadToggle}>
              <input
                type="checkbox"
                checked={unreadOnly}
                onChange={(e) => setUnreadOnly(e.target.checked)}
              />
              Non lus uniquement
            </label>
          </div>

          {listQuery.isLoading && (
            <div className={styles.listCenter}>
              <Spinner label="Chargement..." />
            </div>
          )}

          {listQuery.isError && (
            <div className={styles.errorBlock}>
              Erreur : {(listQuery.error as Error).message}
            </div>
          )}

          {listQuery.data && listQuery.data.content.length === 0 && (
            <EmptyState title="Aucune conversation" />
          )}

          {listQuery.data && (
            <ul className={styles.list}>
              {listQuery.data.content.map((c) => (
                <li
                  key={c.id}
                  className={`${styles.listItem} ${
                    selectedId === c.id ? styles.listItemActive : ""
                  } ${c.unreadForAdmin ? styles.unread : ""}`}
                  onClick={() => setSelectedId(c.id)}
                >
                  <div className={styles.itemHeader}>
                    <span className={styles.itemUser}>{c.userFullName}</span>
                    <Tag tone={STATUS_TONES[c.status]}>
                      {STATUS_LABELS[c.status]}
                    </Tag>
                  </div>
                  <div className={styles.itemSubject}>{c.subject}</div>
                  <div className={styles.itemPreview}>
                    {c.lastMessagePreview}
                  </div>
                  <div className={styles.itemMeta}>
                    {formatRelative(c.lastMessageAt)} ·{" "}
                    {c.messageCount} message{c.messageCount > 1 ? "s" : ""}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className={styles.detailPanel}>
          {selectedId ? (
            <ConversationDetail
              key={selectedId}
              conversationId={selectedId}
              onDeleted={() => setSelectedId(null)}
            />
          ) : (
            <EmptyState
              title="Sélectionnez une conversation"
              description="Choisissez un fil dans la liste pour le consulter."
            />
          )}
        </div>
      </div>
    </>
  );
}

function ConversationDetail({
  conversationId,
  onDeleted,
}: {
  conversationId: string;
  onDeleted: () => void;
}) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const [reply, setReply] = useState("");

  // mark-read au chargement (POST) puis on stocke en cache via setQueryData
  const markReadMutation = useMutation({
    mutationFn: () => conversationsApi.markRead(conversationId),
    onSuccess: (data) => {
      queryClient.setQueryData(["conversation", conversationId], data);
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      queryClient.invalidateQueries({
        queryKey: ["conversations", "unread-count"],
      });
    },
  });

  const detailQuery = useQuery({
    queryKey: ["conversation", conversationId],
    queryFn: () => conversationsApi.getDetail(conversationId),
  });

  // Premier passage : si la conv est non lue cote admin, on la marque lue
  useEffect(() => {
    if (detailQuery.data?.unreadForAdmin) {
      markReadMutation.mutate();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [conversationId, detailQuery.data?.unreadForAdmin]);

  const replyMutation = useMutation({
    mutationFn: () => conversationsApi.reply(conversationId, reply),
    onSuccess: () => {
      setReply("");
      queryClient.invalidateQueries({ queryKey: ["conversation", conversationId] });
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      toast.show("Réponse envoyée", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const statusMutation = useMutation({
    mutationFn: (status: MessageStatus) =>
      conversationsApi.updateStatus(conversationId, status),
    onSuccess: (data) => {
      queryClient.setQueryData(["conversation", conversationId], data);
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      toast.show("Statut mis à jour", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const deleteMutation = useMutation({
    mutationFn: () => conversationsApi.delete(conversationId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      toast.show("Conversation supprimée", "success");
      onDeleted();
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  if (detailQuery.isLoading) {
    return (
      <div className={styles.detailCenter}>
        <Spinner label="Chargement..." />
      </div>
    );
  }

  if (detailQuery.isError) {
    return (
      <div className={styles.errorBlock}>
        Erreur : {(detailQuery.error as Error).message}
      </div>
    );
  }

  const c = detailQuery.data;
  if (!c) return null;

  return (
    <Panel
      noPadding
      title={c.subject}
      sub={`${c.userFullName} · ${c.userEmail}`}
      actions={
        <div className={styles.detailActions}>
          <select
            className={styles.statusSelect}
            value={c.status}
            onChange={(e) =>
              statusMutation.mutate(e.target.value as MessageStatus)
            }
            disabled={statusMutation.isPending}
          >
            {Object.entries(STATUS_LABELS).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
          <Button
            variant="danger"
            size="sm"
            onClick={() => {
              if (window.confirm("Supprimer cette conversation ?")) {
                deleteMutation.mutate();
              }
            }}
          >
            Supprimer
          </Button>
        </div>
      }
    >
      <div className={styles.thread}>
        {c.messages.map((m) => (
          <div
            key={m.id}
            className={`${styles.message} ${
              m.senderType === "ADMIN" ? styles.messageAdmin : styles.messageUser
            }`}
          >
            <div className={styles.messageHeader}>
              <span className={styles.messageAuthor}>{m.authorName}</span>
              <span className={styles.messageTime}>
                {formatDateTime(m.createdAt)}
              </span>
            </div>
            <div className={styles.messageBody}>{m.body}</div>
          </div>
        ))}
      </div>

      <div className={styles.replyBox}>
        <textarea
          placeholder="Votre réponse..."
          value={reply}
          onChange={(e) => setReply(e.target.value)}
          rows={4}
        />
        <div className={styles.replyActions}>
          <Button
            variant="red"
            onClick={() => replyMutation.mutate()}
            disabled={!reply.trim() || replyMutation.isPending}
          >
            {replyMutation.isPending ? "Envoi..." : "Envoyer la réponse"}
          </Button>
        </div>
      </div>
    </Panel>
  );
}

function formatDateTime(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatRelative(iso: string): string {
  const d = new Date(iso);
  const diffMs = Date.now() - d.getTime();
  const minutes = Math.round(diffMs / 60_000);
  if (minutes < 1) return "à l'instant";
  if (minutes < 60) return `il y a ${minutes} min`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `il y a ${hours} h`;
  const days = Math.round(hours / 24);
  if (days < 7) return `il y a ${days} j`;
  return d.toLocaleDateString("fr-FR", { day: "2-digit", month: "short" });
}
