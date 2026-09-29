"use client";

import { AlertCircle } from "lucide-react";
import { TCF_LEVEL_BY_PROCEDURE, type TargetProcedure } from "@/lib/types";
import styles from "./auth.module.css";

/** Le palier exigé vient du référentiel partagé, jamais recopié ici :
 *  `TCF_LEVEL_BY_PROCEDURE` est le miroir gelé de l'enum `TargetProcedure`
 *  côté backend (cf. `lib/types.test.ts`). */
const MENTIONS: { v: TargetProcedure; code: string; name: string }[] = [
  { v: "CSP", code: "CSP", name: "Carte de séjour" },
  { v: "CR", code: "CR", name: "Carte de résident" },
  { v: "NAT", code: "NAT", name: "Naturalisation" },
];

/**
 * LA question « Votre démarche » — montée par `RegisterForm` (inscription et
 * écrans de compte des diagnostics) et par `/completer-profil` (premier accès
 * d'un compte Google, compte ancien sans démarche). Un seul libellé, un seul
 * rendu : les deux écrans posent exactement la même question.
 *
 * 🛑 **Rien n'est pré-coché** (`value` à `null` par défaut chez les appelants) :
 * le candidat choisit, sinon le formulaire ne part pas. Seule exception, et
 * c'est SA réponse : la démarche qu'il a déjà déclarée avant un diagnostic
 * civique.
 *
 * La première option porte `id="targetProcedure"` : c'est elle que
 * `focusFirstError` atteint quand la question est restée sans réponse.
 */
export function DemarcheField({
  value,
  onChange,
  error,
  disabled,
}: {
  value: TargetProcedure | null;
  onChange: (value: TargetProcedure) => void;
  error?: string;
  disabled?: boolean;
}) {
  const errId = error ? "targetProcedure-error" : undefined;
  return (
    <fieldset
      className={`${styles.mentions} ${error ? styles.mentionsInvalid : ""}`}
      disabled={disabled}
      aria-describedby={errId}
    >
      <legend className={styles.label}>Votre démarche</legend>
      <div className={styles.mentionGrid} role="radiogroup" aria-invalid={error ? true : undefined}>
        {MENTIONS.map((opt, i) => {
          const active = value === opt.v;
          return (
            <label
              key={opt.v}
              className={`${styles.mentionOpt} ${active ? styles.mentionActive : ""}`}
            >
              <input
                id={i === 0 ? "targetProcedure" : undefined}
                type="radio"
                name="targetProcedure"
                value={opt.v}
                checked={active}
                required
                onChange={() => onChange(opt.v)}
              />
              <span className={styles.mentionCode}>{opt.code}</span>
              <span className={styles.mentionName}>{opt.name}</span>
              <span className={styles.mentionTcf}>
                TCF <strong>{TCF_LEVEL_BY_PROCEDURE[opt.v]}</strong>
              </span>
            </label>
          );
        })}
      </div>
      {error ? (
        <p id={errId} className={styles.fieldError}>
          <AlertCircle size={15} aria-hidden />
          <span>{error}</span>
        </p>
      ) : null}
    </fieldset>
  );
}
