import { Link } from "react-router-dom";
import { Icon } from "./Icon";
import styles from "./BackLink.module.css";

type BackLinkProps = { label: string } & ({ to: string; onClick?: never } | { onClick: () => void; to?: never });

/** Retour vers la liste, au-dessus d'une fiche : lien de route, ou bouton quand le retour est un état d'écran. */
export function BackLink({ label, to, onClick }: BackLinkProps) {
  const content = (
    <>
      <Icon name="arrowLeft" size={15} />
      {label}
    </>
  );
  return to !== undefined ? (
    <Link to={to} className={styles.back}>
      {content}
    </Link>
  ) : (
    <button type="button" className={styles.back} onClick={onClick}>
      {content}
    </button>
  );
}
