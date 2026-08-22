import { delta, deltaPct } from "../format";
import styles from "../analytics.module.css";
import { Icon } from "./Icon";

interface DeltaProps {
  current: number;
  previous: number | null | undefined;
  /**
   * Une hausse n'est pas toujours une bonne nouvelle (brief §75) : sur un taux
   * d'abandon, c'est `invert` qui decide que la baisse est le bon signe.
   */
  invert?: boolean;
  showFlat?: boolean;
}

/**
 * Variation vs periode precedente. N'affiche RIEN quand la comparaison n'a pas
 * de sens : periode precedente absente ou a zero. « On partait de rien » ne se
 * dit pas « +100 % ».
 */
export function Delta({ current, previous, invert, showFlat = true }: DeltaProps) {
  if (previous == null) return null;

  const value = delta(current, previous);
  if (value == null) return null;

  const direction = Math.abs(value) < 0.005 ? "flat" : value > 0 ? "up" : "down";
  if (direction === "flat" && !showFlat) return null;

  const good = invert ? direction === "down" : direction === "up";
  const tone =
    direction === "flat"
      ? styles.deltaFlat
      : good
        ? styles.deltaUp
        : styles.deltaDown;

  return (
    <span className={`${styles.delta} ${tone}`} title="vs période précédente">
      <Icon name={direction} size={12} stroke={2.4} />
      {deltaPct(value)}
    </span>
  );
}
