/**
 * La consigne d'un exercice du diagnostic, mise en forme par
 * `diagnosticConsigneBlocks` (paragraphes, listes et leur amorce) sans en
 * réécrire un mot. Partagée par l'écran de l'exercice et par « Revoir ma
 * réponse » : une seule mise en forme de la même consigne.
 */
import {diagnosticConsigneBlocks} from "@/lib/diagnostic";
import styles from "./diagnostic.module.css";

/** La consigne servie, mise en forme sans être réécrite : paragraphes, et
 *  listes à puces précédées de leur amorce. */
export function DiagnosticConsigne({text}: {text: string}) {
  return (
    <div className={styles.instruction}>
      {diagnosticConsigneBlocks(text).map((block, index) =>
        block.kind === "paragraph" ? (
          <p key={index}>{block.text}</p>
        ) : (
          <div key={index} className={styles.instructionList}>
            {block.lead && <p className={styles.instructionLead}>{block.lead}</p>}
            {block.ordered ? (
              <ol>
                {block.items.map((item, itemIndex) => (
                  <li key={itemIndex}>{item}</li>
                ))}
              </ol>
            ) : (
              <ul>
                {block.items.map((item, itemIndex) => (
                  <li key={itemIndex}>{item}</li>
                ))}
              </ul>
            )}
          </div>
        ),
      )}
    </div>
  );
}
