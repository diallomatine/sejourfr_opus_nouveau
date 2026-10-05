import { useEffect, useId, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { conversationsApi } from "../../../api/conversationsApi";
import { httpErrorMessage } from "../../../api/http";
import { Avatar } from "../../../components/ui/Avatar";
import { BackLink } from "../../../components/ui/BackLink";
import { Button } from "../../../components/ui/Button";
import { Select } from "../../../components/ui/Form";
import { Icon } from "../../../components/ui/Icon";
import { InlineError } from "../../../components/ui/InlineError";
import { Modal } from "../../../components/ui/Modal";
import { Panel } from "../../../components/ui/Panel";
import { Spinner } from "../../../components/ui/Spinner";
import { Tag } from "../../../components/ui/Tag";
import { useToast } from "../../../components/ui/Toast";
import { formatParisDateTime } from "../../../lib/dates";
import type { MessageStatus } from "../../../types/api";
import { MESSAGE_STATUSES, STATUS_LABELS, STATUS_TONES, messageCountLabel } from "../conversationLabels";
import { ReplyComposer } from "./ReplyComposer";
import styles from "./ConversationDetail.module.css";

interface ConversationDetailProps {
  conversationId: string;
  onDeleted: () => void;
  /** Vue compacte (< 1180 px) : retour à la liste. */
  onBack?: () => void;
}

export function ConversationDetail({ conversationId, onDeleted, onBack }: ConversationDetailProps) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const statusId = useId();
  const threadRef = useRef<HTMLOListElement>(null);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const markReadMutation = useMutation({
    mutationFn: () => conversationsApi.markRead(conversationId),
    onSuccess: (data) => {
      queryClient.setQueryData(["conversation", conversationId], data);
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      queryClient.invalidateQueries({ queryKey: ["conversations", "unread-count"] });
    },
  });

  const detailQuery = useQuery({
    queryKey: ["conversation", conversationId],
    queryFn: () => conversationsApi.getDetail(conversationId),
  });

  // Ouvrir un fil non lu le marque lu côté admin.
  useEffect(() => {
    if (detailQuery.data?.unreadForAdmin) {
      markReadMutation.mutate();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [conversationId, detailQuery.data?.unreadForAdmin]);

  const statusMutation = useMutation({
    mutationFn: (status: MessageStatus) => conversationsApi.updateStatus(conversationId, status),
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
      setConfirmDelete(false);
      onDeleted();
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const messageCount = detailQuery.data?.messages.length ?? 0;
  useEffect(() => {
    const thread = threadRef.current;
    if (thread) thread.scrollTop = thread.scrollHeight;
  }, [conversationId, messageCount]);

  const back = onBack && <BackLink onClick={onBack} label="Boîte de réception" />;

  if (detailQuery.isPending) {
    return (
      <>
        {back}
        <Panel>
          <div className={styles.center}>
            <Spinner label="Chargement de la conversation…" />
          </div>
        </Panel>
      </>
    );
  }

  if (detailQuery.isError) {
    return (
      <>
        {back}
        <Panel>
          <InlineError onRetry={() => detailQuery.refetch()}>
            Impossible de charger la conversation : {httpErrorMessage(detailQuery.error)}
          </InlineError>
        </Panel>
      </>
    );
  }

  const c = detailQuery.data;
  const displayName = c.userFullName || c.userEmail;
  const busy = statusMutation.isPending || deleteMutation.isPending;

  return (
    <>
      {back}
      <Panel noPadding>
        <header className={styles.hero}>
          <div className={styles.identity}>
            <Avatar name={c.userFullName} email={c.userEmail} size="lg" />
            <div className={styles.identityText}>
              <p className={styles.name}>{displayName}</p>
              <a className={styles.email} href={`mailto:${c.userEmail}`}>
                {c.userEmail}
              </a>
              <div className={styles.badges}>
                {c.userId ? (
                  <Tag tone="info" dot>
                    Compte SejourFR
                  </Tag>
                ) : (
                  <Tag tone="neutral" dot>
                    Invité · sans compte
                  </Tag>
                )}
                <Tag tone={STATUS_TONES[c.status]} dot>
                  {STATUS_LABELS[c.status]}
                </Tag>
                {c.unreadForAdmin && (
                  <Tag tone="danger" dot>
                    Non lu
                  </Tag>
                )}
              </div>
            </div>
            {c.userId && (
              <Link to={`/users/${c.userId}`} className={styles.profileLink}>
                <Icon name="user" size={15} />
                Voir la fiche
              </Link>
            )}
          </div>

          <h2 className={styles.subject}>{c.subject}</h2>
          <p className={styles.meta}>
            Ouverte le {formatParisDateTime(c.createdAt)} · {messageCountLabel(c.messages.length)}
          </p>
        </header>

        <div className={styles.actions}>
          <div className={styles.statusField}>
            <label htmlFor={statusId} className={styles.statusLabel}>
              Statut
            </label>
            <Select
              id={statusId}
              className={styles.statusSelect}
              value={c.status}
              onChange={(e) => statusMutation.mutate(e.target.value as MessageStatus)}
              disabled={statusMutation.isPending}
            >
              {MESSAGE_STATUSES.map((s) => (
                <option key={s} value={s}>
                  {STATUS_LABELS[s]}
                </option>
              ))}
            </Select>
          </div>
          <div className={styles.actionButtons}>
            {c.unreadForAdmin && (
              <Button
                size="sm"
                onClick={() => markReadMutation.mutate()}
                disabled={markReadMutation.isPending}
              >
                <Icon name="eye" size={15} />
                Marquer comme lu
              </Button>
            )}
            {c.status !== "ARCHIVE" && (
              <Button size="sm" onClick={() => statusMutation.mutate("ARCHIVE")} disabled={busy}>
                <Icon name="archive" size={15} />
                Archiver
              </Button>
            )}
            <Button variant="danger" size="sm" onClick={() => setConfirmDelete(true)} disabled={busy}>
              <Icon name="trash" size={15} />
              Supprimer
            </Button>
          </div>
        </div>

        <ol ref={threadRef} className={styles.thread} aria-label={`Fil de la conversation, ${messageCountLabel(c.messages.length)}`}>
          {c.messages.map((m) => {
            const fromAdmin = m.senderType === "ADMIN";
            return (
              <li key={m.id} className={`${styles.message} ${fromAdmin ? styles.fromAdmin : styles.fromUser}`}>
                <div className={styles.messageHead}>
                  <span className={styles.author}>{fromAdmin ? m.authorName : m.authorName || displayName}</span>
                  {fromAdmin && <span className={styles.role}>Équipe</span>}
                  <time className={styles.time} dateTime={m.createdAt}>
                    {formatParisDateTime(m.createdAt)}
                  </time>
                </div>
                <div className={styles.bubble}>{m.body}</div>
              </li>
            );
          })}
        </ol>

        <ReplyComposer conversationId={c.id} recipientEmail={c.userEmail} />
      </Panel>

      <Modal
        open={confirmDelete}
        onClose={() => setConfirmDelete(false)}
        title="Supprimer cette conversation ?"
        description={`${c.subject} — ${displayName}`}
        size="sm"
        footer={
          <>
            <Button onClick={() => setConfirmDelete(false)} disabled={deleteMutation.isPending}>
              Annuler
            </Button>
            <Button variant="red" onClick={() => deleteMutation.mutate()} disabled={deleteMutation.isPending}>
              {deleteMutation.isPending ? "Suppression…" : "Supprimer définitivement"}
            </Button>
          </>
        }
      >
        <p className={styles.modalText}>
          Le fil et tous ses messages disparaissent de la console. Cette action est irréversible.
        </p>
      </Modal>
    </>
  );
}
