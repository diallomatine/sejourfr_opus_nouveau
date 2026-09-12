"use client";

import Link from "next/link";
import {useEffect, useMemo, useState} from "react";
import {
    ArrowRight,
    ChevronRight,
    ClipboardCheck,
    Flame,
    GraduationCap,
    Lightbulb,
    Sparkles,
    Target,
    Trophy,
    Waves,
    Zap,
} from "lucide-react";
import {CategoryBarLine, ReinforceRow} from "@/app/_components/ReinforceRow";
import {AffinerPlanCard} from "@/app/_components/plan/AffinerPlanCard";
import {PreparationCard} from "@/app/_components/preparation/PreparationCard";
import {
    Card,
    Cta,
    NowCard,
    Pad,
    Section,
    SejourApp,
    Stack,
    sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {dashboardApi, diagnosticApi, learningPlanApi, userContentApi} from "@/lib/api";
import {PREPARATION_TITLE, affinerPlan, objectifLabel} from "@/lib/preparation";
import {useAuth} from "@/lib/auth-context";
import {moduleAverage, successHint} from "@/lib/dashboard";
import {
    diagnosticCompletedExerciseCount,
    diagnosticDashboardState,
    recommendedExerciseHref,
} from "@/lib/diagnostic";
import {
    type DashboardCategoryStat,
    type DashboardSummaryResponse,
    type DiagnosticResponse,
    type LearningPlanDto,
    type PreparationDto,
    estimatedTcfLevelScopeLabel,
    niveauCecrlShort,
} from "@/lib/types";

/**
 * **L'Accueil** de l'espace connecté : un seul appel agrégé
 * GET /api/me/dashboard (streak, examens blancs, réussite globale, niveau
 * TCF estimé, catégories par module), puis les vues légères Diagnostic /
 * Plan / Préparation qui pilotent la carte d'action prioritaire. Les recommandations complètes vivent sur /recommandations.
 *
 * ## La mise en page vient de la maquette (2026-09-12)
 *
 * `~/Desktop/grok_ecran` — `screenshots/accueil.png` et `accueil-civ.png`.
 * L'écran est monté sur le **KIT** (`SejourApp wide` → colonne de 1080 px au
 * palier desktop) et dispose ses sections par paires avec
 * `sejourStyles.deskPair` : deux colonnes à partir de 960 px, une seule en
 * dessous. 🛑 **Le desktop n'ajoute aucun composant** — ce sont les mêmes
 * briques, dans une grille qui n'existe qu'au-dessus de 960 px.
 *
 * ## Ce que la maquette ne décide PAS
 *
 * 🛑 Elle est une référence de **mise en page**, jamais une source de données
 * ni de règles. En particulier, la hiérarchie des actions est **inchangée** :
 * « À faire maintenant » porte l'action principale servie (le Plan pour un
 * abonné, la porte du diagnostic sinon), « Ma préparation » dit l'état des deux
 * modules, et « Continuez votre diagnostic complet » reste **secondaire** et
 * n'apparaît que de 1/4 à 3/4. Les blocs de la maquette qui n'ont pas de
 * donnée servie chez nous (le trio « compétences travaillées / maîtrisée /
 * validations », les raccourcis du bas) sont **omis**, pas fabriqués : nos
 * indicateurs réels prennent leur place.
 */
export default function DashboardPage() {
    const {user, status} = useAuth();

    const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
    const [diagnostic, setDiagnostic] = useState<DiagnosticResponse | null>(null);
    const [plan, setPlan] = useState<LearningPlanDto | null>(null);
    const [prep, setPrep] = useState<PreparationDto | null>(null);
    const [diagnosticDismissed, setDiagnosticDismissed] = useState(false);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (status !== "authenticated" || !user) return;
        let cancelled = false;
        (async () => {
            const [sum, currentDiagnostic, currentPlan, preparation] = await Promise.all([
                dashboardApi.summaryCached().catch((): DashboardSummaryResponse | null => null),
                diagnosticApi.currentCached().catch((): DiagnosticResponse | null => null),
                learningPlanApi.getCached().catch((): LearningPlanDto | null => null),
                // 🛑 Un SEUL appel pour tout l'écran : « Ma préparation » et la
                // carte « Continuez votre diagnostic complet » lisent le même
                // état. Deux appels auraient pu proposer deux prochaines actions.
                userContentApi.preparation().catch((): PreparationDto | null => null),
            ]);
            if (cancelled) return;
            setSummary(sum);
            setDiagnostic(currentDiagnostic);
            setPlan(currentPlan);
            setPrep(preparation);
            setLoading(false);
        })();
        return () => {
            cancelled = true;
        };
    }, [status, user]);

    /* Le diagnostic complet en cours, en action secondaire persistante.
       🛑 `abonne: false` : sur l'Accueil la carte ne s'affiche que lorsque le
       complet est COMMENCÉ, et ce libellé-là ne dépend pas de l'abonnement. */
    const affinerAccueil = useMemo(
        () => (prep ? affinerPlan(prep.tcf, {surface: "accueil", abonne: false}) : null),
        [prep],
    );

    // Top 3 des catégories travaillées les plus faibles, tous modules confondus.
    const weakest = useMemo(() => {
        if (!summary) return [];
        return [...summary.civique, ...summary.tcf]
            .filter((c) => c.percent !== null)
            .sort((a, b) => (a.percent ?? 0) - (b.percent ?? 0))
            .slice(0, 3);
    }, [summary]);

    if (status === "loading" || (loading && status === "authenticated")) {
        return <DashSkeleton/>;
    }
    if (!user) {
        return (
            <div className="dash-empty">
                <p>
                    Session expirée.{" "}
                    <Link href="/connexion" className="dash-empty-link">
                        Se reconnecter
                    </Link>
                </p>
                <style>{emptyStyle}</style>
            </div>
        );
    }

    const trainingHref =
        user.hasTcf !== false ? "/entrainement?module=TCF" : "/entrainement?module=CIVIQUE";

    return (
        <SejourApp wide className="home">
            {!user.targetProcedure && (
                <Pad>
                    <Link href="/parcours?from=/dashboard" className="home-banner">
                        <span>
                            <strong>Choisissez votre parcours</strong> (CSP, carte de résident ou
                            naturalisation) pour personnaliser votre préparation.
                        </span>
                        <ArrowRight size={16} aria-hidden/>
                    </Link>
                </Pad>
            )}

            {/* L'en-tête de la maquette : le prénom, puis la démarche visée en
                pastille. La démarche est **servie** (`user.targetProcedure`) et
                son libellé vient de l'autorité unique `objectifLabel`.

                🛑 **Aucun CTA ici** (arbitrage du propriétaire, 2026-09-12) :
                « l'en-tête doit rester simple — Bonjour / nom, objectif actuel.
                L'action principale passe entièrement par la carte À faire
                maintenant, juste en dessous. Une seule action dominante par
                écran. » Le bouton « Entraînement du jour » est parti avec son
                libellé ; sa destination reste atteignable par la bascule de
                parcours du rail, qui la porte déjà. */}
            <header className="home-hello">
                <h1>Bonjour {user.firstName ?? "à vous"}</h1>
                <span className="home-obj">{objectifLabel(user.targetProcedure)}</span>
            </header>

            <div className={sejourStyles.deskPair}>
                {diagnostic ? (
                    <Section title="À faire maintenant">
                        <Pad>
                            <ActionPrincipale
                                diagnostic={diagnostic}
                                plan={plan}
                                dismissed={diagnosticDismissed}
                                onDismiss={() => setDiagnosticDismissed(true)}
                            />
                        </Pad>
                    </Section>
                ) : null}

                {/* 🛑 « Ma préparation » est la PREMIÈRE des trois portes vers un
                    diagnostic inachevé (Accueil, Plan, Examens). Elle lit l'état
                    UNIQUE servi par `/api/me/preparation` — c'est ce qui garantit
                    que les trois écrans proposent la même prochaine action. */}
                <Section title={PREPARATION_TITLE}>
                    <Pad>
                        <PreparationCard prep={prep}/>
                    </Pad>
                </Section>
            </div>

            <div className={sejourStyles.deskPair}>
                {/* 🛑 **Secondaire, et seulement quand le diagnostic complet est
                    COMMENCÉ.** Elle permet de le reprendre sans passer par le Plan,
                    mais elle ne devient jamais l'action principale de l'Accueil :
                    celle-ci reste « Débloquer mon Plan » pour un compte gratuit et
                    l'action pédagogique du Plan pour un abonné. À 4 / 4 elle
                    disparaît — c'est `affinerPlan` qui rend `null`, sur des faits
                    servis, jamais un compteur reconstruit ici. */}
                {affinerAccueil && <AffinerPlanCard info={affinerAccueil}/>}

                <Section title="Votre progression">
                    <Pad>
                        <Card>
                            <div className="home-stats">
                                <StatBloc
                                    tone="blue"
                                    icon={<Target size={20}/>}
                                    value={
                                        summary?.globalSuccessPercent !== null &&
                                        summary?.globalSuccessPercent !== undefined
                                            ? `${summary.globalSuccessPercent}%`
                                            : "—"
                                    }
                                    label="Maîtrise globale"
                                    hint={successHint(summary?.globalSuccessPercent ?? null)}
                                />
                                <StatBloc
                                    tone="green"
                                    icon={<Trophy size={20}/>}
                                    value={`${summary?.mockExamsTotal ?? 0}`}
                                    label="Examens blancs"
                                    hint="passés au total"
                                />
                                <StatBloc
                                    tone="red"
                                    icon={<Flame size={20}/>}
                                    value={`${summary?.currentStreakDays ?? 0} j`}
                                    label="Série en cours"
                                    hint={
                                        summary && summary.recordStreakDays > 0
                                            ? `record : ${summary.recordStreakDays} jours`
                                            : "lancez votre série !"
                                    }
                                />
                                <StatBloc
                                    tone="blue"
                                    icon={<GraduationCap size={20}/>}
                                    value={niveauCecrlShort(summary?.estimatedTcfLevel ?? null)}
                                    label="Niveau TCF estimé"
                                    /* Un niveau qui ne porte pas sur les 4 épreuves le
                                       dit ici, à la place de la mention générique. */
                                    hint={estimatedTcfLevelScopeLabel(summary) ?? "équivalence CECRL"}
                                />
                            </div>
                        </Card>
                    </Pad>
                </Section>
            </div>

            <Section title="Vos parcours">
                <Pad>
                    {/* `Stack` porte l'écart vertical sur mobile, `deskPair` la
                        grille à deux colonnes à partir de 960 px. */}
                    <Stack className={sejourStyles.deskPair}>
                        <ModuleCard
                            accent="red"
                            icon={<Waves size={20}/>}
                            title="TCF IRN"
                            href="/entrainement?module=TCF"
                            categories={summary?.tcf ?? []}
                        />
                        <ModuleCard
                            accent="blue"
                            icon={<Lightbulb size={20}/>}
                            title="Examen civique"
                            href="/entrainement?module=CIVIQUE"
                            categories={summary?.civique ?? []}
                        />
                    </Stack>
                </Pad>
            </Section>

            <Section>
                <Pad>
                    <Card>
                        <div className="home-reinforce-head">
                            <h2>À renforcer en priorité</h2>
                            <Link href="/recommandations" className={sejourStyles.link}>
                                Tout voir <ChevronRight size={15} aria-hidden/>
                            </Link>
                        </div>

                        {weakest.length === 0 ? (
                            <div className="home-reinforce-empty">
                                <p>
                                    Entraînez-vous pour obtenir des recommandations personnalisées.
                                </p>
                                {/* 🛑 Un **accès**, pas une seconde action dominante : c'est
                                    exactement quand cette liste est vide — un compte tout
                                    neuf — que « À faire maintenant » porte son geste le plus
                                    important. Un second bouton plein l'aurait concurrencé. */}
                                <Link href={trainingHref} className={sejourStyles.link}>
                                    <Zap size={15} aria-hidden/>
                                    Commencer
                                    <ChevronRight size={15} aria-hidden/>
                                </Link>
                            </div>
                        ) : (
                            <ul className="home-reinforce-list">
                                {weakest.map((cat) => (
                                    <ReinforceRow key={cat.code} cat={cat}/>
                                ))}
                            </ul>
                        )}
                    </Card>
                </Pad>
            </Section>

            <style>{homeStyles}</style>
        </SejourApp>
    );
}

/**
 * **L'action principale de l'Accueil**, dans la carte hero du KIT.
 *
 * 🛑 Les trois états et leurs phrases sont **inchangés** : ce qui a changé,
 * c'est la brique qui les porte (`NowCard`), pas ce qu'elles disent.
 */
function ActionPrincipale({
                              diagnostic,
                              plan,
                              dismissed,
                              onDismiss,
                          }: {
    diagnostic: DiagnosticResponse;
    plan: LearningPlanDto | null;
    dismissed: boolean;
    onDismiss: () => void;
}) {
    const state = diagnosticDashboardState(diagnostic);
    if (state === "NOT_STARTED" && dismissed) return null;

    if (state === "NOT_STARTED") {
        return (
            <NowCard
                icon={ClipboardCheck}
                title="Découvrez ce qui vous bloque au TCF"
                subtitle="2 exercices · ≈ 8 à 10 min"
                badge="Votre point de départ"
                objective="On analyse votre écrit et votre oral pour construire votre premier plan."
            >
                <div className="home-now-actions">
                    <Cta href="/diagnostic">Faire mon diagnostic</Cta>
                    <button type="button" onClick={onDismiss} className="home-now-later">
                        Plus tard
                    </button>
                </div>
            </NowCard>
        );
    }

    if (state === "IN_PROGRESS") {
        const done = diagnosticCompletedExerciseCount(diagnostic);
        const analyzing = diagnostic.status === "ANALYZING" || diagnostic.nextStep === "ANALYSIS";
        return (
            <NowCard
                icon={Sparkles}
                title={analyzing ? "Votre analyse est en préparation" : "Reprenez votre diagnostic"}
                subtitle={`${done} / 2 terminé${done > 1 ? "s" : ""}`}
                badge="Diagnostic en cours"
                objective={
                    analyzing
                        ? "Vos deux réponses sont enregistrées ; vous pouvez revenir voir le résultat."
                        : "Continuez exactement à l'étape où vous vous êtes arrêté."
                }
            >
                <div className="home-now-actions">
                    <Cta href="/diagnostic">
                        {analyzing ? "Voir l'analyse" : "Reprendre mon diagnostic"}
                    </Cta>
                </div>
            </NowCard>
        );
    }

    const live = plan?.currentPriority ?? null;
    /* 🛑 **Une priorité verrouillée n'est jamais NOMMÉE ici.** Depuis que le
       Plan sait aussi désigner une compétence *à acquérir*, la priorité n°1
       peut porter un cadenas — et « Mes priorités » la floute alors. L'écrire
       en clair sur l'Accueil démentirait ce rideau. Miroir du mobile
       (`PlanPriorityHomeCard`, `home_screen.dart`), qui retombe déjà sur son
       texte générique. */
    const priority = live && !live.locked ? live : null;
    const exercise = priority?.recommendedExercise ?? null;
    /* 🛑 **Un raccourci verrouillé n'en est pas un.** La priorité du jour peut
       être une compétence **à acquérir** — désignée avec son `locked`, le
       serveur ayant vérifié qu'elle n'est pas ouverte par sa place n°1 —, et
       « Commencer directement » enverrait alors un compte gratuit droit sur un
       403. Le Plan, lui, reste ouvert : on garde « Continuer mon plan », qui
       porte le cadenas et l'offre. */
    const startable = Boolean(exercise) && !exercise?.locked;
    return (
        <NowCard
            icon={Target}
            /* Le titre de la priorité, et rien d'autre : `explanation` est le
               constat d'une production déjà faite — il raconte le passé sur une
               carte qui annonce l'action à mener, et il vit déjà dans le Plan. */
            title={priority?.title ?? "Continuez votre plan personnalisé"}
            subtitle={exercise ? `${exercise.title} · ${exercise.estimatedMinutes} min` : undefined}
            badge="Votre priorité du jour"
        >
            <div className="home-now-actions">
                <Cta href="/plan">Continuer mon plan</Cta>
                {startable && exercise && (
                    <Link href={recommendedExerciseHref(exercise)} className="home-now-later">
                        Commencer directement
                    </Link>
                )}
            </div>
        </NowCard>
    );
}

function StatBloc({
                      tone,
                      icon,
                      value,
                      label,
                      hint,
                  }: {
    tone: "blue" | "green" | "red";
    icon: React.ReactNode;
    value: string;
    label: string;
    hint: string;
}) {
    return (
        <div className="home-stat">
            <span className={`home-stat-ico home-stat-ico-${tone}`} aria-hidden>
                {icon}
            </span>
            <span className="home-stat-body">
                <span className="home-stat-value">{value}</span>
                <span className="home-stat-label">{label}</span>
                <span className="home-stat-hint">{hint}</span>
            </span>
        </div>
    );
}

function ModuleCard({
                        accent,
                        icon,
                        title,
                        href,
                        categories,
                    }: {
    accent: "blue" | "red";
    icon: React.ReactNode;
    title: string;
    href: string;
    categories: DashboardCategoryStat[];
}) {
    const average = moduleAverage(categories);
    return (
        <Card className="home-module">
            <header className="home-module-head">
                <Link href={href} className="home-module-id">
                    <span className={`home-module-ico home-module-ico-${accent}`} aria-hidden>
                        {icon}
                    </span>
                    <span className="home-module-titles">
                        <span className="home-module-title">{title}</span>
                        <span className="home-module-sub">{categories.length} catégories</span>
                    </span>
                </Link>
                <span className={`home-module-pct home-module-pct-${accent}`}>
                    {average !== null ? `${average}%` : "—"}
                </span>
            </header>

            <ul className="home-module-rows">
                {categories.map((cat) => (
                    <li key={cat.code} className="home-module-row">
                        <span className="home-module-row-label">{cat.label}</span>
                        <CategoryBarLine percent={cat.percent} fallback={cat.level ?? "—"}/>
                    </li>
                ))}
            </ul>
        </Card>
    );
}

function DashSkeleton() {
    return (
        <SejourApp wide className="home">
            <Pad>
                <div className="sk sk-head"/>
                <div className="sk-grid sk-grid-2">
                    <div className="sk sk-card"/>
                    <div className="sk sk-card"/>
                </div>
                <div className="sk-grid sk-grid-2">
                    <div className="sk sk-module"/>
                    <div className="sk sk-module"/>
                </div>
            </Pad>
            <style>{homeStyles}</style>
            <style>{`
        .sk {
          background: linear-gradient(90deg, #EDEFF7 25%, #F5F6FB 50%, #EDEFF7 75%);
          background-size: 200% 100%;
          animation: sk-shimmer 1.4s infinite;
          border-radius: 16px;
        }
        @keyframes sk-shimmer {
          to { background-position: -200% 0; }
        }
        .sk-head { height: 92px; margin-bottom: 22px; }
        .sk-grid {
          display: grid;
          grid-template-columns: 1fr;
          gap: 16px;
          margin-bottom: 22px;
        }
        .sk-card { height: 180px; }
        .sk-module { height: 280px; }
        @media (min-width: 960px) {
          .sk-grid-2 { grid-template-columns: 1fr 1fr; }
        }
      `}</style>
        </SejourApp>
    );
}

const emptyStyle = `
  .dash-empty {
    min-height: 60vh;
    display: flex; align-items: center; justify-content: center;
    font-size: 15px;
    color: var(--color-muted);
  }
  .dash-empty-link { color: var(--color-blue); font-weight: 700; }
`;

/**
 * 🛑 **Aucune couleur ni font en dur** : tout passe par les tokens `@theme`
 * (`--color-*`, `--font-*`) et par les variables du KIT (`--sf-*`), disponibles
 * parce que l'écran est dans le scope `.app`.
 *
 * 🛑 **Aucune borne nouvelle** : les seules media queries ici sont celles de la
 * fondation (960 px), et elles ne font que reprendre ce que le KIT décide déjà.
 */
const homeStyles = `
  /* ===== bandeaux ===== */
  .home-banner {
    display: flex; align-items: center; justify-content: space-between; gap: 14px;
    background: var(--color-blue-light);
    border: 1px solid color-mix(in srgb, var(--color-blue) 18%, transparent);
    color: var(--color-ink);
    border-radius: 14px;
    padding: 13px 18px;
    font-size: 14px;
    text-decoration: none;
    margin-top: 14px;
    transition: filter 0.15s;
  }
  .home-banner:hover { filter: brightness(0.98); }
  .home-banner strong { color: var(--color-blue); }
  /* ===== en-tête « Bonjour X » ===== */
  /* Deux lignes, et rien d'autre : le nom, puis la démarche visée en pastille.
     L'en-tête était une rangée à deux pôles parce qu'elle portait un CTA à
     droite ; il est parti (une seule action dominante par écran), la rangée
     avec lui. La pastille passe à la ligne d'elle-même : le titre est un bloc. */
  .home-hello {
    padding: 14px 16px 2px;
  }
  .home-hello h1 {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 26px;
    font-weight: 800;
    letter-spacing: -0.035em;
    line-height: 1.15;
    color: var(--color-ink);
  }
  .home-obj {
    display: inline-flex;
    margin-top: 10px;
    padding: 5px 10px;
    border-radius: var(--sf-radius-pill);
    background: var(--color-blue-light);
    color: var(--color-blue-dark);
    font-size: 12px;
    font-weight: 750;
  }
  /* ===== actions de la carte « À faire maintenant » ===== */
  .home-now-actions {
    margin-top: 14px;
    display: grid;
    gap: 8px;
    justify-items: start;
  }
  .home-now-actions > * { width: 100%; }
  .home-now-later {
    justify-self: center;
    border: 0;
    padding: 4px;
    background: transparent;
    color: var(--color-muted);
    font: inherit;
    font-size: 13px;
    font-weight: 700;
    text-align: center;
    text-decoration: none;
    cursor: pointer;
    width: auto;
  }
  .home-now-later:hover { color: var(--color-blue); text-decoration: underline; }

  /* ===== indicateurs ===== */
  /* auto-fit plutôt qu'une borne de plus : la grille se replie d'elle-même
     à 360 px comme dans une demi-colonne de desktop. */
  .home-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 16px 12px;
  }
  .home-stat { display: flex; align-items: center; gap: 12px; min-width: 0; }
  .home-stat-ico {
    width: 40px; height: 40px;
    border-radius: var(--sf-radius-sm);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .home-stat-ico-blue { background: var(--color-blue-light); color: var(--color-blue); }
  .home-stat-ico-green {
    background: var(--color-green-light);
    color: var(--color-green-dark);
  }
  .home-stat-ico-red { background: var(--color-red-light); color: var(--color-red); }
  .home-stat-body { display: flex; flex-direction: column; min-width: 0; }
  .home-stat-value {
    font-family: var(--font-sans);
    font-size: 22px;
    font-weight: 800;
    letter-spacing: -0.02em;
    color: var(--color-ink);
    line-height: 1.15;
  }
  .home-stat-label {
    font-size: 13px;
    font-weight: 700;
    color: var(--color-ink-2);
    margin-top: 2px;
  }
  .home-stat-hint {
    font-size: 12px;
    color: var(--color-muted);
    margin-top: 1px;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* ===== cartes de parcours ===== */
  .home-module-head {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    margin-bottom: 16px;
  }
  .home-module-id {
    display: flex; align-items: center; gap: 12px;
    text-decoration: none;
    min-width: 0;
  }
  .home-module-ico {
    width: 42px; height: 42px;
    border-radius: var(--sf-radius-sm);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .home-module-ico-blue { background: var(--color-blue); color: #fff; }
  .home-module-ico-red { background: var(--color-red); color: #fff; }
  .home-module-titles { display: flex; flex-direction: column; min-width: 0; }
  .home-module-title {
    font-size: 16px;
    font-weight: 800;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .home-module-id:hover .home-module-title { color: var(--color-blue); }
  .home-module-sub { font-size: 12.5px; color: var(--color-muted); margin-top: 1px; }
  .home-module-pct {
    font-family: var(--font-sans);
    font-size: 22px;
    font-weight: 800;
    letter-spacing: -0.02em;
    flex-shrink: 0;
  }
  .home-module-pct-blue { color: var(--color-blue); }
  .home-module-pct-red { color: var(--color-red); }
  .home-module-rows {
    list-style: none;
    margin: 0; padding: 0;
    display: flex; flex-direction: column; gap: 12px;
  }
  .home-module-row {
    display: grid;
    grid-template-columns: 1fr;
    gap: 6px;
    min-width: 0;
  }
  .home-module-row-label {
    font-size: 13.5px;
    color: var(--color-ink-2);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* ===== à renforcer ===== */
  .home-reinforce-head {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    margin-bottom: 14px;
  }
  .home-reinforce-head h2 {
    margin: 0;
    font-family: var(--font-sans);
    font-size: 17px;
    font-weight: 800;
    letter-spacing: -0.01em;
    color: var(--color-ink);
  }
  .home-reinforce-list {
    list-style: none;
    margin: 0; padding: 0;
    display: flex; flex-direction: column; gap: 10px;
  }
  .home-reinforce-empty {
    display: flex; align-items: center; justify-content: space-between;
    gap: 14px;
    flex-wrap: wrap;
  }
  .home-reinforce-empty p { margin: 0; font-size: 14px; color: var(--color-muted); }

  /* ===== palier desktop (960 px) — la borne du KIT, pas une de plus ===== */
  @media (min-width: 960px) {
    .home-hello {
      padding-left: 0;
      padding-right: 0;
      padding-top: 10px;
    }
    .home-hello h1 { font-size: 32px; }
    .home-module-row {
      grid-template-columns: minmax(110px, 170px) 1fr;
      align-items: center;
      gap: 12px;
    }
  }
`;
