"use client";

import Link from "next/link";
import { ProgresMouvement } from "@/app/_components/progres/ProgresMouvement";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  BookOpen,
  Gavel,
  Globe,
  Headphones,
  Landmark,
  Lightbulb,
  Mic,
  Minus,
  PenLine,
  Plus,
  Scale,
  SpellCheck,
  TrendingDown,
  TrendingUp,
  Users,
  BarChart3,
} from "lucide-react";
import { CategoryBarLine } from "@/app/_components/ReinforceRow";
import { ProgressDonut } from "@/app/_components/hub/ModuleHubParts";
import {
  Card,
  ChartNote,
  ChartTitle,
  EpreuveStatList,
  EpreuveStatRow,
  FilterChips,
  GoalHero,
  LevelChart,
  LevelStrip,
  Pad,
  PanelHead,
  SejourApp,
  Stack,
  Top,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import { dashboardApi, progressApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { categoryBadge, categoryHref, moduleAverage, successHint } from "@/lib/dashboard";
import {
  accueilEpreuveStatut,
  accueilEpreuveTon,
  accueilEvaluees,
  PROGRESSION_COURBE_SUB,
  PROGRESSION_COURBE_TITLE,
  PROGRESSION_COURBE_VIDE_TITLE,
  PROGRESSION_EPREUVES_SUB,
  PROGRESSION_EPREUVES_TITLE,
  PROGRESSION_EYEBROW,
  PROGRESSION_HERO_LABEL,
  PROGRESSION_HERO_META,
  PROGRESSION_LEAD,
  PROGRESSION_NIVEAU_ACTUEL_LABEL,
  PROGRESSION_SANS_EXAMEN_TEXT,
  PROGRESSION_TITLE,
  PROGRESSION_VOIR_LABEL,
  SUIVI_SANS_EXAMEN_LABEL,
  niveauActuelEpreuve,
  progresCourbe,
  progresEvolutionFleche,
  progresEvolutionTrendTone,
  progressionCourbeVideText,
  progressionDerniereMesure,
  progressionMark,
  progressionMesureesLabel,
  progressionMesureesPart,
  progressionMesureesPourcent,
  progressionNom,
  progressionObjectifPill,
  progressionPalier,
  progressionPalierCaption,
  progressionResultatsHref,
  progressionSerieLabel,
  suiviNiveauLabel,
} from "@/lib/progres";
import {
  type DashboardCategoryStat,
  type DashboardSummaryResponse,
  type EpreuveType,
  type EvaluationQualifianteDto,
  niveauCecrlLabel,
  type ProgressDto,
  type ProgressEpreuveDto,
  type TcfDomainProfileDto,
} from "@/lib/types";

/** Tonalité d'une catégorie (mêmes couleurs que les cards des hubs). */
const CATEGORY_TONES: Record<string, string> = {
  TCF_CO: "blue",
  TCF_CE: "green",
  TCF_STRUCTURE: "amber",
  TCF_EE: "slate",
  TCF_EO: "red",
  CIV_PRINCIPES: "blue",
  CIV_INSTITUTIONS: "green",
  CIV_DROITS_DEVOIRS: "amber",
  CIV_HISTOIRE_GEO: "red",
  CIV_SOCIETE: "slate",
};

/** Icône d'une catégorie (mêmes pictos que les hubs). */
const CATEGORY_ICONS: Record<string, React.ReactNode> = {
  TCF_CO: <Headphones size={18} strokeWidth={1.8} />,
  TCF_CE: <BookOpen size={18} strokeWidth={1.8} />,
  TCF_STRUCTURE: <SpellCheck size={18} strokeWidth={1.8} />,
  TCF_EE: <PenLine size={18} strokeWidth={1.8} />,
  TCF_EO: <Mic size={18} strokeWidth={1.8} />,
  CIV_PRINCIPES: <Scale size={18} strokeWidth={1.8} />,
  CIV_INSTITUTIONS: <Landmark size={18} strokeWidth={1.8} />,
  CIV_DROITS_DEVOIRS: <Gavel size={18} strokeWidth={1.8} />,
  CIV_HISTOIRE_GEO: <Globe size={18} strokeWidth={1.8} />,
  CIV_SOCIETE: <Users size={18} strokeWidth={1.8} />,
};

/**
 * **« Votre progression »** — la progression **globale**, ouverte depuis le
 * Profil.
 *
 * ⚠️ **À ne pas confondre avec `/plan/progression`** (« Ma progression »,
 * l'historique des cycles) ni avec `/historique/epreuve/{domaine}` (« Vos
 * résultats » d'une épreuve). Cette page-ci répond à « où en est mon niveau,
 * épreuve par épreuve ».
 *
 * 🛑 **La partie TCF est refaite sur le template du propriétaire**
 * (`docs/progression/ecran_progression_normal.html`, première partie) : le
 * bandeau d'objectif et sa bande de paliers, « Votre évolution » à onglets, et
 * « Vos épreuves ». Le **parcours civique** reste en dessous, inchangé : le
 * template ne le couvre pas.
 *
 * 🛑 **Rien n'est classé ici.** Paliers, tendances et mots d'état arrivent
 * **servis** — `GET /api/me/progress` pour les 4 épreuves (le palier vient de
 * `TcfProfileService.levelProfileAccueil`, **l'autorité d'affichage**, la même
 * que l'Accueil, le Profil, le Diagnostic et Réviser) et
 * `GET /api/me/progress/tcf/{epreuve}/historique` pour la série d'examens
 * qualifiants. Les dérivations vivent dans `lib/progres.ts`, miroir mot pour
 * mot de `screens/progres/progres_labels.dart`.
 *
 * 🛑 **Miroir de `ProgresScreen` côté mobile**, bloc pour bloc.
 */
export default function StatistiquesPage() {
  const { user, status } = useAuth();
  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [progres, setProgres] = useState<ProgressDto | null>(null);
  /** La série servie de chaque épreuve, la plus récente d'abord. */
  const [histos, setHistos] = useState<Partial<Record<EpreuveType, EvaluationQualifianteDto[]>>>({});
  const [loading, setLoading] = useState(true);
  const [onglet, setOnglet] = useState<EpreuveType>("TCF_CO");
  /** Le point choisi, **dans l'ordre servi**. `null` ⇒ la mesure la plus récente. */
  const [point, setPoint] = useState<number | null>(null);
  const courbeRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (status !== "authenticated" || !user) return;
    let cancelled = false;
    dashboardApi
      .summaryCached()
      .then((d) => {
        if (cancelled) return;
        setSummary(d);
        setLoading(false);
      })
      .catch(() => {
        if (!cancelled) setLoading(false);
      });
    /* 🛑 **Le palier d'une épreuve vient de `progressApi`**, l'autorité
       d'affichage — jamais d'un second calcul. La lecture est mise en cache par
       le client, que l'Accueil vient de remplir. */
    progressApi
      .get()
      .then((p) => {
        if (!cancelled) setProgres(p);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, [status, user]);

  /* 🛑 **La série d'une épreuve est SERVIE** : une lecture par épreuve publiée,
     mises en cache par le client. Une bascule d'onglet ne coûte donc aucun
     appel, et c'est le même total que visiter les quatre onglets un à un. */
  const epreuves: ProgressEpreuveDto[] = useMemo(
    () => progres?.tcf.epreuves ?? [],
    [progres],
  );

  useEffect(() => {
    if (epreuves.length === 0) return;
    let cancelled = false;
    for (const e of epreuves) {
      progressApi
        .historique(e.epreuve)
        .then((h) => {
          if (cancelled) return;
          setHistos((prev) => ({ ...prev, [e.epreuve]: h.evaluations }));
        })
        .catch(() => undefined);
    }
    return () => {
      cancelled = true;
    };
  }, [epreuves]);

  /** Le tap d'une ligne sélectionne l'onglet et ramène la courbe sous les yeux. */
  const choisirEpreuve = useCallback((epreuve: EpreuveType) => {
    setOnglet(epreuve);
    setPoint(null);
    courbeRef.current?.scrollIntoView({ behavior: "smooth", block: "center" });
  }, []);

  if (status === "loading" || (loading && status === "authenticated")) {
    return (
      <div className="prog prog-loading" aria-busy>
        <div className="prog-sk" />
        <div className="prog-sk prog-sk-tall" />
        <style>{styles}</style>
      </div>
    );
  }
  if (!user) {
    return (
      <div className="prog-empty">
        <p>
          Session expirée.{" "}
          <Link href="/connexion" className="prog-empty-link">
            Se reconnecter
          </Link>
        </p>
        <style>{styles}</style>
      </div>
    );
  }

  const civiqueAvg = summary ? moduleAverage(summary.civique) : null;
  const globalAvg = summary?.globalSuccessPercent ?? null;

  const objectif = progres?.tcf.objectif ?? null;
  const compte = accueilEvaluees(epreuves);
  const valeur = progressionMesureesLabel(compte);
  /* 🛑 **Un onglet par épreuve SERVIE**, jamais sur une épreuve que le serveur
     ne publie pas. */
  const courant = epreuves.some((e) => e.epreuve === onglet)
    ? onglet
    : epreuves[0]?.epreuve ?? onglet;
  const situation = epreuves.find((e) => e.epreuve === courant) ?? null;
  const servies = histos[courant] ?? [];
  const { ladder, points } = progresCourbe(servies, objectif);
  const choisi = point == null || point >= servies.length ? 0 : point;
  const mesure = servies[choisi] ?? null;
  const resultatsHref = progressionResultatsHref(courant);

  return (
    <SejourApp wide>
      <Top
        kicker={PROGRESSION_EYEBROW}
        title={PROGRESSION_TITLE}
        lead={PROGRESSION_LEAD}
      />

      {/* ------------------------------------------------- TCF (le template) */}
      {epreuves.length > 0 && (
        <Pad>
          <Stack>
            <GoalHero
              label={PROGRESSION_HERO_LABEL}
              /* 🛑 Sans les deux nombres servis, on n'annonce **aucun
                 chiffre** : le bandeau garde son intitulé et sa bande. */
              value={valeur}
              pill={progressionObjectifPill(objectif)}
              ratio={progressionMesureesPart(compte)}
              metaLabel={valeur ? PROGRESSION_HERO_META : null}
              metaValue={progressionMesureesPourcent(compte)}
            >
              <LevelStrip
                items={epreuves.map((epreuve) => ({
                  mark: progressionMark(epreuve.epreuve),
                  level: progressionPalier(epreuve),
                  /* 🛑 La flèche **lit** le sens servi (`evolution`), elle ne
                     le déduit d'aucune série de paliers. */
                  trend: progresEvolutionFleche(epreuve.evolution),
                  trendTone: progresEvolutionTrendTone(epreuve.evolution),
                  /* 🛑 Le mot est celui de l'ACCUEIL, la seule dérivation du
                     dépôt pour cet état servi. Le template en proposait trois à
                     lui (« En progrès » / « Stable » / « À évaluer ») : un
                     second vocabulaire d'état aurait fait dire deux mots
                     différents du même fait sur deux écrans que le candidat
                     voit à la suite. */
                  caption: accueilEpreuveStatut(epreuve),
                }))}
              />
            </GoalHero>

            <section ref={courbeRef} className="prog-sec">
              <PanelHead title={PROGRESSION_COURBE_TITLE} sub={PROGRESSION_COURBE_SUB} />
              <Card>
                <FilterChips
                  options={epreuves.map((e) => ({
                    id: e.epreuve,
                    label: progressionMark(e.epreuve),
                  }))}
                  value={courant}
                  onChange={choisirEpreuve}
                />
                <ChartTitle
                  name={progressionNom(courant)}
                  /* 🛑 Le palier vient de l'autorité d'affichage servie, « — »
                     compris : jamais « A1 » pour une absence de mesure. */
                  level={situation ? progressionPalier(situation) : "—"}
                  caption={PROGRESSION_NIVEAU_ACTUEL_LABEL}
                />
                {/* 🛑 **Pas de courbe sans point** : un panneau vide
                    raconterait une absence comme un incident. */}
                {points.length > 0 ? (
                  <LevelChart
                    ladder={ladder}
                    points={points}
                    /* Les points sont chronologiques, la liste servie ne l'est
                       pas : l'index se retourne. */
                    activeIndex={servies.length - 1 - choisi}
                    onSelect={(i) => setPoint(servies.length - 1 - i)}
                  />
                ) : (
                  <div className="prog-chart-empty">
                    <span className="prog-chart-empty-ico" aria-hidden>
                      <Plus size={22} strokeWidth={2} />
                    </span>
                    <strong>{PROGRESSION_COURBE_VIDE_TITLE}</strong>
                    <span>{progressionCourbeVideText(courant)}</span>
                  </div>
                )}
                {/* 🛑 **Aucun score n'est servi** par l'historique : on affiche
                    ce qui l'est (la provenance, la date, le palier) et rien de
                    plus. Le « x / 25 bonnes réponses » du template n'existe
                    pas ici. */}
                <ChartNote
                  title={progressionDerniereMesure(mesure) ?? SUIVI_SANS_EXAMEN_LABEL}
                  text={mesure ? suiviNiveauLabel(mesure.niveau) : PROGRESSION_SANS_EXAMEN_TEXT}
                  actionLabel={mesure ? PROGRESSION_VOIR_LABEL : null}
                  href={mesure ? resultatsHref : null}
                />
              </Card>
            </section>

            <section className="prog-sec">
              <PanelHead
                title={PROGRESSION_EPREUVES_TITLE}
                sub={PROGRESSION_EPREUVES_SUB}
              />
              <EpreuveStatList>
                {epreuves.map((epreuve) => (
                  <EpreuveStatRow
                    key={epreuve.epreuve}
                    mark={progressionMark(epreuve.epreuve)}
                    title={progressionNom(epreuve.epreuve)}
                    pill={accueilEpreuveStatut(epreuve)}
                    pillTone={accueilEpreuveTon(epreuve)}
                    /* 🛑 **La série vient de l'historique SERVI**, dans l'ordre
                       servi : on la lit du plus ancien au plus récent, rien n'y
                       est interprété. */
                    desc={
                      progressionSerieLabel(histos[epreuve.epreuve] ?? [])
                      ?? SUIVI_SANS_EXAMEN_LABEL
                    }
                    level={progressionPalier(epreuve)}
                    levelCaption={progressionPalierCaption(epreuve)}
                    measured={epreuve.niveau !== null}
                    selected={epreuve.epreuve === courant}
                    onClick={() => choisirEpreuve(epreuve.epreuve)}
                  />
                ))}
              </EpreuveStatList>
            </section>
          </Stack>
        </Pad>
      )}

      {/* ------------------------- Le parcours CIVIQUE — inchangé, en dessous */}
      <Pad>
        <div className="prog-civ">
          {/* 🛑 **Ce qui a BOUGÉ** (T28, `30_` §7) : il couvre les DEUX
              parcours, donc il reste ici. */}
          <ProgresMouvement />

          <section className="prog-donuts" aria-label="Vue d'ensemble">
            <DonutCard
              label="Maîtrise globale"
              percent={globalAvg}
              headline={successHint(globalAvg)}
              chip="Tous parcours confondus"
              chipTone="neutral"
            />
            <DonutCard
              label="Examen civique"
              percent={civiqueAvg}
              headline={successHint(civiqueAvg)}
              chip={`${summary?.civique.length ?? 5} catégories`}
              chipTone="red"
            />
          </section>

          <ModuleProgressSection
            icon={<Lightbulb size={18} strokeWidth={2} />}
            title="Examen civique"
            categories={summary?.civique ?? []}
            examOutOf={20}
            profil={summary?.tcfDomainProfile ?? null}
          />
        </div>
      </Pad>

      <style>{styles}</style>
    </SejourApp>
  );
}

function DonutCard({
  label,
  percent,
  headline,
  hint,
  chip,
  chipTone,
}: {
  label: string;
  percent: number | null;
  headline: string;
  /** Précision facultative sous le titre. */
  hint?: string | null;
  chip: string;
  chipTone: "neutral" | "blue" | "red";
}) {
  return (
    <article className="prog-donut-card">
      <span className="prog-donut-label">{label}</span>
      <div className="prog-donut-row">
        <ProgressDonut percent={percent} />
        <div className="prog-donut-text">
          <span className="prog-donut-headline">{headline}</span>
          {hint && <span className="prog-donut-hint">{hint}</span>}
          <span className={`prog-chip prog-chip-${chipTone}`}>{chip}</span>
        </div>
      </div>
    </article>
  );
}

function ModuleProgressSection({
  icon,
  title,
  categories,
  examOutOf,
  profil,
}: {
  icon: React.ReactNode;
  title: string;
  categories: DashboardCategoryStat[];
  examOutOf: number;
  /**
   * L'autorité d'affichage du niveau d'une épreuve, servie par le **même**
   * appel que les catégories (`GET /api/me/dashboard`) — aucun appel de plus.
   * Sans effet sur la section civique : aucune de ses catégories n'y figure,
   * donc aucune ligne n'y gagne de palier.
   */
  profil: TcfDomainProfileDto | null;
}) {
  return (
    <section className="prog-module">
      <header className="prog-module-head">
        <span className="prog-module-icon" aria-hidden>
          {icon}
        </span>
        <h2>{title}</h2>
      </header>
      <ul className="prog-rows">
        {categories.map((cat) => (
          <CategoryRow key={cat.code} cat={cat} examOutOf={examOutOf} profil={profil} />
        ))}
      </ul>
    </section>
  );
}

/**
 * Une ligne de catégorie.
 *
 * 🛑 **Le niveau vient de l'AUTORITÉ D'AFFICHAGE** (`tcfDomainProfile`, par
 * `niveauActuelEpreuve`), la même que l'Accueil, le Profil, le Diagnostic et
 * Réviser — jamais de `DashboardCategoryStat.level`, qui voyait le dernier
 * niveau de **n'importe quelle** soumission, entraînements compris.
 * → `docs/decisions/diagnostic.md`, 2026-09-16.
 *
 * 🛑 **Seules les 4 épreuves TCF ont un palier.** Un thème civique rend
 * `null` : la ligne retombe alors sur ce qu'elle sait **compter**.
 */
function CategoryRow({
  cat,
  examOutOf,
  profil,
}: {
  cat: DashboardCategoryStat;
  examOutOf: number;
  profil: TcfDomainProfileDto | null;
}) {
  const isProduction = cat.code === "TCF_EE" || cat.code === "TCF_EO";
  const stat = categoryBadge(cat.percent);
  const niveau = niveauActuelEpreuve(profil, cat.code);

  const sub = isProduction
    ? suiviNiveauLabel(niveau)
    : cat.mockExams > 0
      ? `${cat.mockExams} examen${cat.mockExams > 1 ? "s" : ""}${
          cat.bestMockScore != null ? ` · record ${cat.bestMockScore}/${examOutOf}` : ""
        }`
      : "Pas encore d'examen";

  // Tendance : dernier examen vs avant-dernier (— si moins de 2 examens).
  const trend =
    cat.lastMockScore != null && cat.prevMockScore != null
      ? cat.lastMockScore > cat.prevMockScore
        ? "up"
        : cat.lastMockScore < cat.prevMockScore
          ? "down"
          : "flat"
      : null;

  return (
    <li>
      <Link href={categoryHref(cat)} className="prog-row">
        <span
          className={`prog-row-icon prog-icon-${CATEGORY_TONES[cat.code] ?? "blue"}`}
          aria-hidden
        >
          {CATEGORY_ICONS[cat.code] ?? <BarChart3 size={18} strokeWidth={1.8} />}
        </span>
        <span className="prog-row-titles">
          <span className="prog-row-title">{cat.label}</span>
          <span className="prog-row-sub">{sub}</span>
        </span>
        <span className="prog-row-bar">
          <CategoryBarLine
            percent={cat.percent}
            fallback={niveau ? niveauCecrlLabel(niveau) : "—"}
          />
        </span>
        <span className={`prog-trend prog-trend-${trend ?? "none"}`} aria-hidden>
          {trend === "up" ? (
            <TrendingUp size={17} />
          ) : trend === "down" ? (
            <TrendingDown size={17} />
          ) : (
            <Minus size={15} />
          )}
        </span>
        <span className={`prog-badge prog-badge-${stat.tone}`}>{stat.label}</span>
      </Link>
    </li>
  );
}

const styles = `
  /* 🛑 La partie TCF n'a AUCUN CSS d'écran : elle est entièrement en kit. Ce
     qui suit habille le parcours CIVIQUE, laissé inchangé, plus la section
     d'une carte de kit et l'état vide de la courbe. */

  .prog-sec { display: grid; gap: 10px; }

  /* L'etat vide de la courbe : le rendu sans mesure du template. */
  .prog-chart-empty {
    display: grid;
    justify-items: center;
    gap: 5px;
    padding: 24px 12px;
    text-align: center;
  }
  .prog-chart-empty-ico {
    display: grid; place-items: center;
    width: 52px; height: 52px;
    border-radius: var(--sf-radius-lg);
    background: var(--color-paper-2);
    color: var(--color-blue);
  }
  .prog-chart-empty strong {
    margin-top: 5px;
    font-size: 13px; font-weight: 800;
    color: var(--color-ink);
  }
  .prog-chart-empty span {
    font-size: 11.5px; line-height: 1.4;
    color: var(--color-muted);
  }

  /* ===== le parcours civique ===== */
  .prog-civ { display: grid; gap: 22px; margin-top: 22px; }

  .prog-donuts {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
  }
  .prog-donut-card {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 16px;
    padding: 18px 20px;
    min-width: 0;
  }
  .prog-donut-label {
    display: block;
    font-size: 12.5px; font-weight: 600;
    color: var(--color-muted-2);
    margin-bottom: 12px;
  }
  .prog-donut-row { display: flex; align-items: center; gap: 16px; }
  .prog-donut-text { min-width: 0; }
  .prog-donut-headline {
    display: block;
    font-family: var(--font-sans);
    font-size: 19px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
    margin-bottom: 7px;
  }
  .prog-donut-hint {
    display: block;
    font-family: var(--font-sans);
    font-size: 12px; font-weight: 500; line-height: 1.35;
    color: var(--color-muted-2);
    margin: -3px 0 7px;
    overflow-wrap: anywhere;
  }
  .prog-chip {
    display: inline-block;
    font-size: 11.5px; font-weight: 700;
    padding: 4px 10px; border-radius: 999px;
    white-space: nowrap;
  }
  .prog-chip-neutral { background: var(--color-line-2); color: var(--color-muted); }
  .prog-chip-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .prog-chip-red { background: var(--color-red-light); color: var(--color-red); }

  .prog-module {
    background: #fff;
    border: 1px solid var(--color-line);
    border-radius: 18px;
    padding: 0 0 8px;
    overflow: hidden;
  }
  .prog-module-head {
    display: flex; align-items: center; gap: 10px;
    padding: 14px 22px;
    background: var(--color-blue-soft);
    border-bottom: 1px solid var(--color-line-2);
    margin-bottom: 4px;
  }
  .prog-module-icon { color: var(--color-blue); display: flex; }
  .prog-module-head h2 {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 15.5px; font-weight: 800; letter-spacing: -0.01em;
    color: var(--color-ink);
  }

  .prog-rows { list-style: none; margin: 0; padding: 0; }
  .prog-row {
    display: grid;
    grid-template-columns: 38px minmax(180px, 1.1fr) 1.4fr 28px 110px;
    align-items: center;
    gap: 14px;
    padding: 14px 22px;
    text-decoration: none;
    border-bottom: 1px solid var(--color-line-2);
    transition: background 0.15s;
    min-width: 0;
  }
  .prog-rows li:last-child .prog-row { border-bottom: none; }
  .prog-row:hover { background: var(--color-blue-soft); }

  .prog-row-icon {
    width: 38px; height: 38px;
    border-radius: 11px;
    display: grid; place-items: center;
  }
  .prog-icon-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .prog-icon-green { background: color-mix(in srgb, var(--color-green) 14%, #fff); color: var(--color-green); }
  .prog-icon-amber { background: color-mix(in srgb, var(--color-amber) 18%, #fff); color: color-mix(in srgb, var(--color-amber) 75%, var(--color-ink)); }
  .prog-icon-red { background: var(--color-red-light); color: var(--color-red); }
  .prog-icon-slate { background: var(--color-paper-2); color: var(--color-muted); }
  .prog-row-titles { min-width: 0; }
  .prog-row-title {
    display: block;
    font-size: 14px; font-weight: 700;
    color: var(--color-ink);
    line-height: 1.3;
  }
  .prog-row-sub {
    display: block;
    font-size: 12px; color: var(--color-muted);
    margin-top: 2px;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .prog-row-bar { min-width: 0; }

  .prog-trend { display: flex; justify-content: center; }
  .prog-trend-up { color: var(--color-green); }
  .prog-trend-down { color: var(--color-red); }
  .prog-trend-flat { color: var(--color-muted-2); }
  .prog-trend-none { color: var(--color-muted-2); opacity: 0.5; }

  .prog-badge {
    font-size: 12px; font-weight: 600;
    padding: 5px 11px; border-radius: 999px;
    text-align: center;
    white-space: nowrap;
  }
  .prog-badge-green { background: color-mix(in srgb, var(--color-green) 12%, #fff); color: var(--color-green); }
  .prog-badge-blue { background: var(--color-blue-light); color: var(--color-blue-dark); }
  .prog-badge-amber { background: color-mix(in srgb, var(--color-amber) 14%, #fff); color: color-mix(in srgb, var(--color-amber) 75%, var(--color-ink)); }
  .prog-badge-none { background: var(--color-line-2); color: var(--color-muted); }

  /* ===== états ===== */
  .prog { max-width: 1180px; margin: 0 auto; padding: 30px 40px 80px; }
  .prog-empty {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    font-size: 15px; color: var(--color-muted);
  }
  .prog-empty-link { color: var(--color-blue); font-weight: 700; }
  .prog-sk {
    height: 120px; border-radius: 16px; margin-bottom: 16px;
    background: linear-gradient(90deg, #EDEFF7 25%, #F5F6FB 50%, #EDEFF7 75%);
    background-size: 200% 100%;
    animation: prog-shimmer 1.4s infinite;
  }
  .prog-sk-tall { height: 420px; }
  @keyframes prog-shimmer { to { background-position: -200% 0; } }

  /* ===== responsive ===== */
  @media (max-width: 1000px) {
    .prog-donuts { grid-template-columns: 1fr; }
    .prog-row { grid-template-columns: 38px 1fr 28px 110px; }
    .prog-row-bar { grid-column: 2 / -1; grid-row: 2; }
  }
  @media (max-width: 768px) {
    .prog { padding: 64px 18px 48px; }
    .prog-badge { display: none; }
    .prog-row { grid-template-columns: 38px 1fr 28px; gap: 10px; }
    .prog-module { border-radius: 14px; }
    .prog-module-head, .prog-row { padding-left: 14px; padding-right: 14px; }
  }
`;
