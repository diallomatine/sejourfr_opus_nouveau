import styles from "./Pagination.module.css";

const NUMBER_FORMAT = new Intl.NumberFormat("fr-FR");

type PageSlot = number | "gap-start" | "gap-end";

/**
 * Pages à afficher : la première, la dernière, la courante et ses deux voisines ;
 * un trou d'une seule page est comblé par son numéro plutôt que par « … ».
 */
function pageSlots(current: number, totalPages: number): PageSlot[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i);
  }
  const start = Math.max(1, Math.min(current - 1, totalPages - 4));
  const end = Math.min(totalPages - 2, Math.max(current + 1, 3));
  const slots: PageSlot[] = [0];
  if (start > 2) slots.push("gap-start");
  else if (start === 2) slots.push(1);
  for (let i = start; i <= end; i++) slots.push(i);
  if (end < totalPages - 3) slots.push("gap-end");
  else if (end === totalPages - 3) slots.push(totalPages - 2);
  slots.push(totalPages - 1);
  return slots;
}

interface PaginationProps {
  /** Page courante, indexée à 0 comme le `PageResponse` du backend. */
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  onSizeChange?: (size: number) => void;
  sizeOptions?: readonly number[];
  /** Vrai pendant un chargement : les commandes se figent, la position reste lisible. */
  busy?: boolean;
  itemLabel?: string;
}

export function Pagination({
  page,
  size,
  totalElements,
  totalPages,
  onPageChange,
  onSizeChange,
  sizeOptions,
  busy = false,
  itemLabel = "résultats",
}: PaginationProps) {
  if (totalElements === 0) return null;

  const from = page * size + 1;
  const to = Math.min(totalElements, (page + 1) * size);
  const hasPrev = page > 0;
  const hasNext = page + 1 < totalPages;

  return (
    <nav className={styles.bar} aria-label="Pagination" aria-busy={busy}>
      <div className={styles.range}>
        {from <= totalElements ? (
          <>
            <strong>
              {NUMBER_FORMAT.format(from)}–{NUMBER_FORMAT.format(to)}
            </strong>{" "}
            sur {NUMBER_FORMAT.format(totalElements)} {itemLabel}
          </>
        ) : (
          <>
            {NUMBER_FORMAT.format(totalElements)} {itemLabel}
          </>
        )}
      </div>

      {totalPages > 1 && (
        <div className={styles.pages}>
          <button
            type="button"
            className={styles.step}
            onClick={() => onPageChange(page - 1)}
            disabled={!hasPrev || busy}
            aria-label="Page précédente"
          >
            ←<span className={styles.stepText}> Précédent</span>
          </button>

          <ol className={styles.numbers}>
            {pageSlots(page, totalPages).map((slot) =>
              typeof slot === "number" ? (
                <li key={slot}>
                  <button
                    type="button"
                    className={`${styles.number} ${slot === page ? styles.current : ""}`}
                    onClick={() => onPageChange(slot)}
                    disabled={busy || slot === page}
                    aria-current={slot === page ? "page" : undefined}
                    aria-label={`Page ${slot + 1}`}
                  >
                    {slot + 1}
                  </button>
                </li>
              ) : (
                <li key={slot} className={styles.gap} aria-hidden="true">
                  …
                </li>
              ),
            )}
          </ol>

          <span className={styles.compact}>
            {page + 1} / {totalPages}
          </span>

          <button
            type="button"
            className={styles.step}
            onClick={() => onPageChange(page + 1)}
            disabled={!hasNext || busy}
            aria-label="Page suivante"
          >
            <span className={styles.stepText}>Suivant </span>→
          </button>
        </div>
      )}

      {onSizeChange && sizeOptions && sizeOptions.length > 1 && (
        <label className={styles.sizePicker}>
          <span>Par page</span>
          <select
            className={styles.sizeSelect}
            value={size}
            onChange={(e) => onSizeChange(Number(e.target.value))}
            disabled={busy}
          >
            {sizeOptions.map((opt) => (
              <option key={opt} value={opt}>
                {opt}
              </option>
            ))}
          </select>
        </label>
      )}
    </nav>
  );
}
