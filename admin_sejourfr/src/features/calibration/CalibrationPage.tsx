import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { httpErrorMessage } from "../../api/http";
import { calibrationApi } from "../../api/calibrationApi";
import { Icon } from "../../components/ui/Icon";
import { PageHeader } from "../../components/ui/PageHeader";
import { Panel } from "../../components/ui/Panel";
import { Spinner } from "../../components/ui/Spinner";
import { CalibrationHealth } from "./components/CalibrationHealth";
import styles from "./CalibrationPage.module.css";

/**
 * Santé de la notation IA (biais, dispersion, divergence de niveau). La liste
 * des productions et leur annotation vivent dans « Productions IA » (F-1) :
 * l'annotation s'ouvre depuis la fiche d'une production.
 */
export function CalibrationPage() {
  const statsQuery = useQuery({
    queryKey: ["calibration", "stats"],
    queryFn: () => calibrationApi.stats(),
  });

  const niveauStatsQuery = useQuery({
    queryKey: ["calibration", "stats", "niveau"],
    queryFn: () => calibrationApi.niveauStats(),
  });

  return (
    <>
      <PageHeader eyebrow="§ 07 — Notation IA" title="Calibration de la" emphasis="notation" />

      <p className={styles.intro}>
        Comparer, production par production, la note de l&apos;IA avec celle d&apos;un correcteur
        humain. C&apos;est la seule façon de savoir si la notation tombe juste — et, à la longue, de
        constituer un corpus de référence fait de vraies copies plutôt que d&apos;exemples fabriqués.
      </p>

      {statsQuery.isPending && <Spinner label="Chargement de la santé de la notation…" />}

      {statsQuery.data && <CalibrationHealth stats={statsQuery.data} niveau={niveauStatsQuery.data} />}

      {statsQuery.isError && (
        <Panel>
          <div className={styles.error}>Erreur : {httpErrorMessage(statsQuery.error)}</div>
        </Panel>
      )}

      <Panel
        title="Annoter des productions"
        sub="La liste, les filtres et l'annotation se font dans « Productions IA » : ouvrez une production, puis « Annoter »."
      >
        <div className={styles.links}>
          <Link to="/productions-ia?annotation=NON_ANNOTEES&statut=EVALUEE" className={styles.link}>
            Productions évaluées à annoter
            <Icon name="chevronRight" size={16} />
          </Link>
          <Link to="/productions-ia?annotation=ANNOTEES" className={styles.link}>
            Productions déjà annotées
            <Icon name="chevronRight" size={16} />
          </Link>
        </div>
      </Panel>
    </>
  );
}
