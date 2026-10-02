import styles from "./Avatar.module.css";

/** Deux initiales d'affichage tirées du nom servi, sinon de l'email. */
function initialsOf(name: string | null | undefined, email: string): string {
  const source = name?.trim() || email.split("@")[0];
  const words = source.split(/[\s._-]+/).filter(Boolean);
  const letters =
    words.length >= 2 ? `${words[0][0]}${words[words.length - 1][0]}` : source.slice(0, 2);
  return letters.toUpperCase();
}

interface AvatarProps {
  name: string | null | undefined;
  email: string;
  size?: "sm" | "md" | "lg";
}

export function Avatar({ name, email, size = "md" }: AvatarProps) {
  return (
    <span className={`${styles.avatar} ${styles[size]}`} aria-hidden="true">
      {initialsOf(name, email)}
    </span>
  );
}
