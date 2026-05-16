interface Props {
  /** Si fournie, affiche cette valeur ; sinon affiche `[À compléter]` en rouge. */
  value: string | null | undefined;
  /** Libellé alternatif si `[À compléter]` n'est pas assez parlant. */
  label?: string;
}

/**
 * Affiche `value` quand elle est renseignée, sinon `[À compléter]` en rouge ambré
 * + soulignement. Sert d'indicateur visuel pour que les trous des `legal-info.ts`
 * ne passent pas inaperçus avant la mise en prod.
 */
export function Placeholder({ value, label }: Props) {
  if (value && value.trim().length > 0) {
    return <span>{value}</span>;
  }
  return (
    <mark
      className="legal-placeholder"
      aria-label="Information à compléter avant publication"
      title="À compléter dans content/legal/legal-info.ts"
    >
      [À compléter{label ? ` — ${label}` : ""}]
      <style>{`
        .legal-placeholder {
          display: inline-block;
          background: var(--color-red-light);
          color: var(--color-red-dark);
          border: 1px solid rgba(225, 55, 47, 0.30);
          border-radius: 4px;
          padding: 2px 6px;
          font-size: 11px;
          font-family: var(--font-mono);
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }
      `}</style>
    </mark>
  );
}
