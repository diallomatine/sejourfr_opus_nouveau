interface Props {
  /** En-têtes (1ère colonne = label, suivantes = valeurs). */
  columns: string[];
  rows: React.ReactNode[][];
}

/**
 * Tableau légal qui se transforme en cards verticales sur mobile (chaque ligne
 * = une carte avec label/valeur). Garde la largeur de lecture et évite le
 * scroll horizontal sur les écrans étroits.
 */
export function LegalTable({ columns, rows }: Props) {
  return (
    <div className="legal-table">
      <div className="legal-table-desktop">
        <table>
          <thead>
            <tr>
              {columns.map((c) => (
                <th key={c}>{c}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row, i) => (
              <tr key={i}>
                {row.map((cell, j) => (
                  <td key={j} className={j === 0 ? "is-label" : undefined}>
                    {cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="legal-table-mobile">
        {rows.map((row, i) => (
          <div key={i} className="legal-table-card">
            <dl>
              {row.map((cell, j) => (
                <div key={j} className="legal-table-card-row">
                  <dt>{columns[j]}</dt>
                  <dd className={j === 0 ? "is-label" : undefined}>{cell}</dd>
                </div>
              ))}
            </dl>
          </div>
        ))}
      </div>

      <style>{`
        .legal-table {
          margin: 24px 0;
        }
        .legal-table-desktop {
          display: none;
        }
        @media (min-width: 768px) {
          .legal-table-desktop {
            display: block;
            overflow: hidden;
            border-radius: 12px;
            border: 1px solid var(--color-line);
          }
        }
        .legal-table-desktop table {
          width: 100%;
          font-size: 14px;
          line-height: 1.55;
          text-align: left;
          border-collapse: collapse;
        }
        @media (min-width: 1024px) {
          .legal-table-desktop table {
            font-size: 15px;
          }
        }
        .legal-table-desktop thead tr {
          background: var(--color-line-2);
        }
        .legal-table-desktop th {
          padding: 10px 16px;
          font-weight: 600;
          color: var(--color-ink);
          border-bottom: 1px solid var(--color-line);
        }
        .legal-table-desktop td {
          padding: 10px 16px;
          border-top: 1px solid var(--color-line);
          color: var(--color-ink-2);
          vertical-align: top;
        }
        .legal-table-desktop tr:nth-child(even) td {
          background: rgba(238, 240, 248, 0.35);
        }
        .legal-table-desktop td.is-label {
          font-weight: 500;
          color: var(--color-ink);
        }
        .legal-table-mobile {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }
        @media (min-width: 768px) {
          .legal-table-mobile {
            display: none;
          }
        }
        .legal-table-card {
          border: 1px solid var(--color-line);
          border-radius: 12px;
          background: #fff;
          padding: 16px;
        }
        .legal-table-card dl {
          display: grid;
          grid-template-columns: 1fr;
          gap: 10px;
          margin: 0;
        }
        .legal-table-card-row {
          display: grid;
          grid-template-columns: 1fr;
          gap: 2px;
        }
        .legal-table-card-row dt {
          font-size: 11px;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          font-weight: 600;
          color: var(--color-muted);
          margin: 0;
        }
        .legal-table-card-row dd {
          margin: 0;
          font-size: 14px;
          color: var(--color-ink-2);
        }
        .legal-table-card-row dd.is-label {
          font-weight: 600;
          color: var(--color-ink);
        }
      `}</style>
    </div>
  );
}
