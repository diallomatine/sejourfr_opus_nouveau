"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ChevronRight} from "lucide-react";
import {ApiException, productionApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  productionTaskSubtitle,
  productionTaskTitle,
  type ProductionExampleDto,
  type ProductionTaskDto,
} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader, SectionLabel} from "@/app/_components/hub/HubParts";
import {type ProductionConfig} from "./config";
import hub from "@/app/_components/hub/hub.module.css";
import prod from "./production.module.css";

type Tab = "sujets" | "exemples";

/**
 * Sujets d'une tâche productive (T1/T2/T3, tous niveaux) + onglet « Exemples »
 * (réponses-modèles ; lecteur audio pour l'EO). Tap sujet → écran d'input.
 */
export function ProductionSubjects({config}: {config: ProductionConfig}) {
  const params = useParams<{n: string}>();
  const n = Number(params?.n ?? "0");
  const valid = n >= 1 && n <= 3;
  const router = useRouter();
  const {user, status} = useAuth();

  const [tab, setTab] = useState<Tab>("sujets");
  const [tasks, setTasks] = useState<ProductionTaskDto[]>([]);
  const [examples, setExamples] = useState<ProductionExampleDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [examplesLoaded, setExamplesLoaded] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (status !== "authenticated" || !valid) return;
    let cancelled = false;
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    productionApi
      .listTasks({epreuve: config.epreuve, tacheNumero: n})
      .then((list) => {
        if (!cancelled) {
          // Filtre défensif : certains backends ignorent `tacheNumero` sans niveau.
          setTasks(
            list
              .filter((t) => t.tacheNumero === n)
              .sort((a, b) => a.niveauCible.localeCompare(b.niveauCible)),
          );
        }
      })
      .catch((e) => {
        if (!cancelled)
          setError(e instanceof ApiException ? e.message : "Impossible de charger les sujets.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [status, valid, n, config.epreuve]);

  useEffect(() => {
    if (tab !== "exemples" || examplesLoaded || !valid) return;
    let cancelled = false;
    productionApi
      .listExamples(config.epreuve, n)
      .then((list) => {
        if (!cancelled) setExamples(list);
      })
      .catch(() => undefined)
      .finally(() => {
        if (!cancelled) setExamplesLoaded(true);
      });
    return () => {
      cancelled = true;
    };
  }, [tab, examplesLoaded, valid, n, config.epreuve]);

  if (status === "loading") return <div className={ds.gate} />;
  if (!user) return <ModuleDetailGate next={`${config.base}/tache/${n}`} />;
  if (!valid) {
    return (
      <DualChromeShell>
        <main className={hub.hub}>
          <p className={prod.empty}>Tâche inconnue.</p>
        </main>
      </DualChromeShell>
    );
  }

  return (
    <DualChromeShell>
      <main className={hub.hub}>
        <HubDetailHeader
          backHref={config.base}
          title={`Tâche ${n} · ${productionTaskTitle(config.epreuve, n)}`}
          subtitle={productionTaskSubtitle(config.epreuve, n)}
        />

        <div className={prod.tabs}>
          <button
            type="button"
            className={`${prod.tab} ${tab === "sujets" ? prod.tabActive : ""}`}
            onClick={() => setTab("sujets")}
          >
            Sujets
          </button>
          <button
            type="button"
            className={`${prod.tab} ${tab === "exemples" ? prod.tabActive : ""}`}
            onClick={() => setTab("exemples")}
          >
            Exemples
          </button>
        </div>

        {error && <div className={prod.error}>{error}</div>}

        {tab === "sujets" ? (
          loading ? (
            <p className={prod.loading}>Chargement des sujets…</p>
          ) : tasks.length === 0 ? (
            <p className={prod.empty}>Aucun sujet disponible pour cette tâche.</p>
          ) : (
            <>
              <SectionLabel label="Choisir un sujet" />
              <div className={hub.list}>
                {tasks.map((t, i) => (
                  <button
                    key={t.id}
                    type="button"
                    className={prod.row}
                    onClick={() => router.push(`${config.base}/${config.inputSegment}/${t.id}`)}
                  >
                    <span className={prod.rowChip}>{t.niveauCible}</span>
                    <span className={prod.rowBody}>
                      <span className={prod.rowTitle}>Sujet {i + 1}</span>
                      <span className={prod.rowSub}>{t.consigne}</span>
                    </span>
                    <ChevronRight size={20} className={prod.rowChevron} />
                  </button>
                ))}
              </div>
            </>
          )
        ) : !examplesLoaded ? (
          <p className={prod.loading}>Chargement des exemples…</p>
        ) : examples.length === 0 ? (
          <p className={prod.empty}>Aucun exemple-modèle pour cette tâche pour l&apos;instant.</p>
        ) : (
          <div className={hub.list}>
            {examples.map((ex) => (
              <ExampleCard key={ex.id} example={ex} />
            ))}
          </div>
        )}
      </main>
    </DualChromeShell>
  );
}

function ExampleCard({example: ex}: {example: ProductionExampleDto}) {
  return (
    <div className={prod.example}>
      <h3 className={prod.exampleTitle}>
        {ex.titre}
        {ex.niveauIndicatif && <span className={prod.rowChip}>{ex.niveauIndicatif}</span>}
      </h3>
      {ex.resume && <p className={prod.exampleResume}>{ex.resume}</p>}
      {ex.audioUrl && (
        <div className={prod.player} style={{maxWidth: "none", marginBottom: 12}}>
          <audio src={ex.audioUrl} controls preload="none" />
        </div>
      )}
      {ex.contenu && <p className={prod.exampleBody}>{ex.contenu}</p>}
      {ex.planPoints.length > 0 && (
        <ol className={prod.planList}>
          {ex.planPoints.map((p, i) => (
            <li key={i} className={prod.planItem}>
              <span className={prod.planNum}>{i + 1}.</span>
              {p}
            </li>
          ))}
        </ol>
      )}
      {ex.explications && <p className={prod.exampleExpl}>{ex.explications}</p>}
    </div>
  );
}
