import { useId, useState } from "react";
import type { FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useNavigate } from "react-router-dom";
import { httpErrorMessage } from "../../../api/http";
import { usersApi } from "../../../api/usersApi";
import { Button } from "../../../components/ui/Button";
import { FormRow, Input, Textarea } from "../../../components/ui/Form";
import { Icon } from "../../../components/ui/Icon";
import { Modal } from "../../../components/ui/Modal";
import { Segmented } from "../../../components/ui/Segmented";
import { Spinner } from "../../../components/ui/Spinner";
import { useToast } from "../../../components/ui/Toast";
import type { ConversationDetailDto } from "../../../types/api";
import { RecipientPicker } from "./RecipientPicker";
import type { MessageRecipient } from "./RecipientPicker";
import styles from "./ComposeMessageModal.module.css";

/** Bornes miroirs d'`AdminUserMessageRequest` (le serveur revérifie après nettoyage). */
const SUBJECT_MIN = 3;
const SUBJECT_MAX = 150;
const BODY_MAX = 5000;

const TABS = [
  { value: "write", label: "Rédiger" },
  { value: "preview", label: "Aperçu de l'email" },
] as const;
type Tab = (typeof TABS)[number]["value"];

interface ComposeMessageModalProps {
  /** Destinataire fixé (fiche utilisateur) ; absent ⇒ recherche d'un compte. */
  recipient?: MessageRecipient;
  onClose: () => void;
  /** Appelé avec la conversation créée ; sans lui, la modale affiche un lien vers le fil. */
  onSent?: (conversation: ConversationDetailDto) => void;
}

/**
 * Écrire à un compte (D-58), depuis `/conversations` (« Nouveau message ») et la
 * fiche `/users/:id` (« Envoyer un message ») : objet + texte libre, aperçu rendu
 * par le gabarit serveur `ADMIN_MESSAGE`, envoi qui crée une conversation.
 */
export function ComposeMessageModal({ recipient: fixedRecipient, onClose, onSent }: ComposeMessageModalProps) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const navigate = useNavigate();
  const subjectId = useId();
  const bodyId = useId();
  const [picked, setPicked] = useState<MessageRecipient | null>(null);
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [tab, setTab] = useState<Tab>("write");
  const [sent, setSent] = useState<ConversationDetailDto | null>(null);

  const recipient = fixedRecipient ?? picked;
  const subjectLength = subject.trim().length;
  const bodyLength = body.trim().length;
  const subjectValid = subjectLength >= SUBJECT_MIN && subject.length <= SUBJECT_MAX;
  const bodyValid = bodyLength > 0 && body.length <= BODY_MAX;
  const ready = Boolean(recipient) && subjectValid && bodyValid;
  const request = { subject, body };

  const preview = useQuery({
    queryKey: ["adminUserMessagePreview", recipient?.id, request],
    queryFn: () => usersApi.previewMessage(recipient!.id, request),
    enabled: tab === "preview" && ready,
    staleTime: Infinity,
    retry: false,
  });

  const send = useMutation({
    mutationFn: () => usersApi.sendMessage(recipient!.id, request),
    onSuccess: (conversation) => {
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      toast.show("Message envoyé", "success", `Email envoyé à ${recipient?.email}.`);
      if (onSent) {
        onSent(conversation);
        onClose();
      } else {
        setSent(conversation);
      }
    },
  });

  const submit = (e?: FormEvent) => {
    e?.preventDefault();
    if (ready && !send.isPending) send.mutate();
  };

  const edit = (apply: () => void) => {
    apply();
    if (send.isError) send.reset();
  };

  if (sent) {
    return (
      <Modal
        open
        onClose={onClose}
        title="Message envoyé"
        description={recipient?.email}
        footer={
          <>
            <Button onClick={onClose}>Fermer</Button>
            <Button variant="primary" onClick={() => navigate(`/conversations?c=${sent.id}`)}>
              <Icon name="message" size={15} />
              Ouvrir la conversation
            </Button>
          </>
        }
      >
        <p className={styles.success} role="status">
          <Icon name="checkCircle" size={16} />
          L'email « {sent.subject} » est parti. La conversation est enregistrée dans « Conversations », où
          vous pourrez poursuivre l'échange.
        </p>
      </Modal>
    );
  }

  const footer = (
    <>
      <Button onClick={onClose} disabled={send.isPending}>
        Annuler
      </Button>
      <Button type="submit" form={`${subjectId}-form`} variant="red" disabled={!ready || send.isPending}>
        {!send.isPending && <Icon name="send" size={15} />}
        {send.isPending ? "Envoi…" : "Envoyer l'email"}
      </Button>
    </>
  );

  return (
    <Modal
      open
      onClose={onClose}
      eyebrow="Conversations"
      title={fixedRecipient ? "Envoyer un message" : "Nouveau message"}
      description={
        fixedRecipient
          ? `À ${fixedRecipient.displayName ? `${fixedRecipient.displayName} · ` : ""}${fixedRecipient.email}`
          : "Un email de l'équipe SejourFR à un compte, enregistré comme conversation."
      }
      size="lg"
      footer={footer}
    >
      <form id={`${subjectId}-form`} className={styles.form} onSubmit={submit} aria-busy={send.isPending}>
        {!fixedRecipient && (
          <FormRow label="Destinataire">
            <RecipientPicker value={picked} onChange={(r) => edit(() => setPicked(r))} disabled={send.isPending} />
          </FormRow>
        )}

        <Segmented label="Rédiger ou prévisualiser" options={TABS} value={tab} onChange={setTab} />

        {tab === "write" ? (
          <>
            <FormRow label="Objet" htmlFor={subjectId}>
              <Input
                id={subjectId}
                value={subject}
                maxLength={SUBJECT_MAX}
                placeholder="Objet de l'email"
                disabled={send.isPending}
                onChange={(e) => edit(() => setSubject(e.target.value))}
              />
              <span className={styles.counter}>
                {subject.length} / {SUBJECT_MAX}
              </span>
            </FormRow>
            <FormRow label="Message" htmlFor={bodyId}>
              <Textarea
                id={bodyId}
                value={body}
                maxLength={BODY_MAX}
                rows={10}
                placeholder="Votre message…"
                disabled={send.isPending}
                onChange={(e) => edit(() => setBody(e.target.value))}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) submit();
                }}
              />
              <span className={styles.counter}>
                {body.length} / {BODY_MAX}
              </span>
            </FormRow>
            <p className={styles.hint}>
              « Bonjour Prénom », la signature « L'équipe SejourFR » et le pied de page sont ajoutés
              automatiquement. Le texte part tel quel (sauts de ligne conservés, aucune mise en forme). La
              personne peut répondre directement à l'email : sa réponse arrive au support.
            </p>
          </>
        ) : (
          <div className={styles.previewBox}>
            {!ready && (
              <p className={styles.previewState}>
                {recipient
                  ? `Renseignez un objet (${SUBJECT_MIN} caractères au moins) et un message pour voir l'aperçu.`
                  : "Choisissez d'abord le compte destinataire."}
              </p>
            )}
            {ready && preview.isPending && (
              <div className={styles.previewState}>
                <Spinner label="Préparation de l'aperçu…" />
              </div>
            )}
            {ready && preview.isError && (
              <p className={`${styles.feedback} ${styles.error}`} role="alert">
                Aperçu impossible : {httpErrorMessage(preview.error)}
              </p>
            )}
            {ready && preview.data && (
              <>
                <p className={styles.previewMeta}>
                  <span>
                    À <strong>{preview.data.recipient}</strong>
                  </span>
                  <span>
                    Objet : <strong>{preview.data.subject}</strong>
                  </span>
                </p>
                <iframe
                  className={styles.frame}
                  title="Aperçu de l'email"
                  sandbox=""
                  srcDoc={preview.data.html}
                />
              </>
            )}
          </div>
        )}

        {send.isError && (
          <p className={`${styles.feedback} ${styles.error}`} role="alert">
            Envoi impossible : {httpErrorMessage(send.error)}. Votre texte est conservé.
          </p>
        )}
      </form>
    </Modal>
  );
}
