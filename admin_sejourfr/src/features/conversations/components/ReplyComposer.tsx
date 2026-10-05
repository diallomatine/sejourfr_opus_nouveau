import { useId, useState } from "react";
import type { FormEvent, KeyboardEvent } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { conversationsApi } from "../../../api/conversationsApi";
import { httpErrorMessage } from "../../../api/http";
import { Button } from "../../../components/ui/Button";
import { Textarea } from "../../../components/ui/Form";
import { Icon } from "../../../components/ui/Icon";
import { useToast } from "../../../components/ui/Toast";
import styles from "./ReplyComposer.module.css";

interface ReplyComposerProps {
  conversationId: string;
  recipientEmail: string;
}

/** Réponse de l'équipe : envoyée par email au contact, puis ajoutée au fil. */
export function ReplyComposer({ conversationId, recipientEmail }: ReplyComposerProps) {
  const queryClient = useQueryClient();
  const toast = useToast();
  const fieldId = useId();
  const hintId = useId();
  const [reply, setReply] = useState("");
  const [sent, setSent] = useState(false);

  const replyMutation = useMutation({
    mutationFn: () => conversationsApi.reply(conversationId, reply),
    onSuccess: () => {
      setReply("");
      setSent(true);
      queryClient.invalidateQueries({ queryKey: ["conversation", conversationId] });
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
      toast.show("Réponse envoyée", "success");
    },
    onError: (err) => toast.show((err as Error).message, "error"),
  });

  const canSend = reply.trim() !== "" && !replyMutation.isPending;

  const submit = (e?: FormEvent) => {
    e?.preventDefault();
    if (canSend) replyMutation.mutate();
  };

  const onKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) submit();
  };

  const onChange = (value: string) => {
    setReply(value);
    if (sent) setSent(false);
    if (replyMutation.isError) replyMutation.reset();
  };

  return (
    <form className={styles.composer} onSubmit={submit} aria-busy={replyMutation.isPending}>
      <label className={styles.label} htmlFor={fieldId}>
        Répondre
      </label>
      <Textarea
        id={fieldId}
        placeholder="Écrire la réponse…"
        value={reply}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={onKeyDown}
        rows={4}
        disabled={replyMutation.isPending}
        aria-describedby={hintId}
      />

      {replyMutation.isError && (
        <p className={`${styles.feedback} ${styles.error}`} role="alert">
          Envoi impossible : {httpErrorMessage(replyMutation.error)}. Votre texte est conservé.
        </p>
      )}
      {sent && (
        <p className={`${styles.feedback} ${styles.sent}`} role="status">
          <Icon name="checkCircle" size={15} />
          Réponse envoyée par email à {recipientEmail}.
        </p>
      )}

      <div className={styles.footer}>
        <p id={hintId} className={styles.hint}>
          Envoyée par email à <strong>{recipientEmail}</strong> · Ctrl + Entrée pour envoyer
        </p>
        <Button type="submit" variant="red" disabled={!canSend}>
          {!replyMutation.isPending && <Icon name="send" size={15} />}
          {replyMutation.isPending ? "Envoi…" : "Envoyer la réponse"}
        </Button>
      </div>
    </form>
  );
}
