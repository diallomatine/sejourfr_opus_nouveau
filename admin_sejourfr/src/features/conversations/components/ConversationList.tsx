import { Avatar } from "../../../components/ui/Avatar";
import { Tag } from "../../../components/ui/Tag";
import { formatParisDateTime, formatParisShort } from "../../../lib/dates";
import type { ConversationSummaryDto } from "../../../types/api";
import { STATUS_LABELS, STATUS_TONES, messageCountLabel } from "../conversationLabels";
import styles from "./ConversationList.module.css";

interface ConversationListProps {
  items: ConversationSummaryDto[];
  selectedId: string | null;
  onSelect: (id: string) => void;
}

/** Fils de la boîte de réception : un bouton par conversation, la sélection en `aria-current`. */
export function ConversationList({ items, selectedId, onSelect }: ConversationListProps) {
  return (
    <ul className={styles.list}>
      {items.map((c) => {
        const selected = c.id === selectedId;
        const showEmail = c.userFullName.trim() !== "" && c.userFullName !== c.userEmail;
        return (
          <li key={c.id}>
            <button
              type="button"
              className={`${styles.item} ${selected ? styles.selected : ""} ${
                c.unreadForAdmin ? styles.unread : ""
              }`}
              aria-current={selected ? "true" : undefined}
              onClick={() => onSelect(c.id)}
            >
              <Avatar name={c.userFullName} email={c.userEmail} size="sm" />
              <span className={styles.body}>
                <span className={styles.top}>
                  <span className={styles.name}>{c.userFullName || c.userEmail}</span>
                  <time className={styles.date} dateTime={c.lastMessageAt} title={formatParisDateTime(c.lastMessageAt)}>
                    {formatParisShort(c.lastMessageAt)}
                  </time>
                </span>
                {showEmail && <span className={styles.email}>{c.userEmail}</span>}
                <span className={styles.subject}>
                  {c.unreadForAdmin && (
                    <span className={styles.unreadDot}>
                      <span className="visually-hidden">Non lu · </span>
                    </span>
                  )}
                  {c.subject}
                </span>
                <span className={styles.snippet}>{c.lastMessagePreview}</span>
                <span className={styles.meta}>
                  <Tag tone={STATUS_TONES[c.status]} dot>
                    {STATUS_LABELS[c.status]}
                  </Tag>
                  <span className={styles.count}>{messageCountLabel(c.messageCount)}</span>
                  {!c.userId && <span className={styles.guest}>Invité</span>}
                </span>
              </span>
            </button>
          </li>
        );
      })}
    </ul>
  );
}
