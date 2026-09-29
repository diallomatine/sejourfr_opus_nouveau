import type { ReactNode } from "react";
import type {
  CalibrationStatsDto,
  NiveauCalibrationStatsDto,
} from "../../../types/api";
import {
  formatDecimal,
  formatPercent,
  formatSigned,
  readBias,
  readDispersion,
} from "../calibrationHelpers";
import type { HealthTone } from "../calibrationHelpers";
import styles from "./CalibrationHealth.module.css";

interface CalibrationHealthProps {
  stats: CalibrationStatsDto;
  niveau?: NiveauCalibrationStatsDto;
}

export function CalibrationHealth({ stats, niveau }: CalibrationHealthProps) {
  if (stats.totalNotes === 0) {
    return (
      <div className={styles.empty}>
        <strong>Aucune note humaine enregistrée.</strong> Tant que personne n&apos;a
        corrigé de production à la main, il n&apos;existe aucun point de
        comparaison : impossible de dire si l&apos;IA note juste. Annotez quelques
        soumissions ci-dessous pour que ce bandeau se remplisse.
      </div>
    );
  }

  const bias = readBias(stats.ecartMoyen, stats.seuilHorsCible);
  const dispersionTone = readDispersion(stats.ecartMoyenAbsolu, stats.seuilHorsCible);

  return (
    <section className={styles.wrap}>
      <header className={styles.head}>
        <div>
          <div className={styles.eyebrow}>Santé de la notation</div>
          <p className={styles.headSub}>
            Comparaison de la note de l&apos;IA avec celle d&apos;un correcteur
            humain, sur {stats.totalNotes} production
            {stats.totalNotes > 1 ? "s" : ""} annotée
            {stats.totalNotes > 1 ? "s" : ""}.
          </p>
        </div>
        <span
          className={`${styles.verdict} ${stats.calibre ? styles.verdictOk : styles.verdictKo}`}
        >
          {stats.calibre ? "Notation calibrée" : "Notation à recaler"}
        </span>
      </header>

      <div className={styles.duo}>
        <BigCard
          tone={bias.tone}
          eyebrow="Biais — dans quel sens se trompe-t-elle ?"
          value={`${formatSigned(stats.ecartMoyen)} pt`}
          formula="écart = note humaine − note IA, moyenne signée"
        >
          {bias.sentence}
        </BigCard>

        <BigCard
          tone={dispersionTone}
          eyebrow="Dispersion — de combien se trompe-t-elle ?"
          value={`${formatDecimal(stats.ecartMoyenAbsolu)} pt`}
          formula="moyenne de |écart|, sans tenir compte du sens"
        >
          En moyenne, chaque note de l&apos;IA tombe à{" "}
          {formatDecimal(stats.ecartMoyenAbsolu)} point
          {stats.ecartMoyenAbsolu >= 2 ? "s" : ""} de celle du correcteur, au-dessus
          ou en dessous.
        </BigCard>
      </div>

      <p className={styles.explainer}>
        Ces deux chiffres ne disent pas la même chose. Le <strong>biais</strong>{" "}
        peut être proche de zéro alors que la <strong>dispersion</strong> est
        forte : l&apos;IA se tromperait alors autant vers le haut que vers le bas,
        et ses erreurs se compenseraient en moyenne sans qu&apos;aucune note
        individuelle ne soit juste. Le biais dit <em>si l&apos;IA penche</em>, la
        dispersion dit <em>si on peut lui faire confiance note par note</em>.
      </p>

      <div className={styles.tiles}>
        <Tile
          label="Régularité de l'erreur"
          value={`${formatDecimal(stats.ecartTypeAbsolu)} pt`}
          hint="Écart-type des erreurs : plus il est bas, plus l'IA se trompe toujours de la même façon."
        />
        <Tile
          label="Notes hors cible"
          value={`${stats.ecartsHorsCible} · ${formatPercent(stats.pourcentageHorsCible)}`}
          hint={`Écart de plus de ${formatDecimal(stats.seuilHorsCible)} pt avec le correcteur (seuil fixé côté serveur).`}
        />
        <Tile
          label="Niveau CECRL divergent"
          value={
            niveau
              ? `${niveau.divergents} · ${formatPercent(niveau.pourcentageDivergents)}`
              : "—"
          }
          hint={
            niveau
              ? `Sur ${niveau.totalAvecNiveau} évaluation${niveau.totalAvecNiveau > 1 ? "s" : ""}, le niveau annoncé par le modèle diffère du niveau recalculé par le serveur.`
              : "Statistique de niveau indisponible."
          }
        />
      </div>
    </section>
  );
}

function BigCard({
  tone,
  eyebrow,
  value,
  formula,
  children,
}: {
  tone: HealthTone;
  eyebrow: string;
  value: string;
  formula: string;
  children: ReactNode;
}) {
  return (
    <article className={`${styles.card} ${styles[tone]}`}>
      <div className={styles.cardEyebrow}>{eyebrow}</div>
      <div className={styles.cardValue}>{value}</div>
      <p className={styles.cardSentence}>{children}</p>
      <div className={styles.cardFormula}>{formula}</div>
    </article>
  );
}

function Tile({
  label,
  value,
  hint,
}: {
  label: string;
  value: string;
  hint: string;
}) {
  return (
    <div className={styles.tile}>
      <div className={styles.tileLabel}>{label}</div>
      <div className={styles.tileValue}>{value}</div>
      <p className={styles.tileHint}>{hint}</p>
    </div>
  );
}
