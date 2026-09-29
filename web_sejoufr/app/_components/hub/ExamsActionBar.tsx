import Link from "next/link";
import { Target } from "lucide-react";
import styles from "./exams-action-bar.module.css";

/**
 * **« Examens blancs », collé en bas** du détail d'une épreuve TCF ou d'un
 * thème civique. Miroir de `ExamsActionBar` côté mobile
 * (`core/widgets/exams_action_bar.dart`) : bouton pill bleu plein
 * (`--color-blue` ⇄ `AppColors.blue`), cible à gauche, pleine largeur de la
 * colonne, fondu vers le fond pour laisser le contenu défiler dessous.
 *
 * `position: sticky` et non `fixed` : la barre reste dans la colonne de
 * contenu, jamais sous la barre latérale. À poser en **dernier enfant** de la
 * coquille (`DetailShell`, `SkillShell`), qui retire alors son padding bas.
 */
export function ExamsActionBar({ href }: { href: string }) {
  return (
    <div className={styles.bar} data-exams-bar>
      <Link href={href} className={styles.btn}>
        <Target size={20} strokeWidth={2} aria-hidden />
        Examens blancs
      </Link>
    </div>
  );
}
