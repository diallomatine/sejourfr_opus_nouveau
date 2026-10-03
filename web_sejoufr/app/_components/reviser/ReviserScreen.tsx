"use client";

/**
 * **L'écran « Entraînement »** d'un module (ex-« Réviser ») — Navigation v2
 * (2026-10-03), maquettes `#tcf-entrainement` et `#civique-entrainement` de
 * `docs/redesign/sejourfr-navigation-web.html`, montées sur le KIT.
 *
 * TCF : `PageHead` (« 4 épreuves »), la carte « Recommandé par votre plan »
 * (`ActionCard`), une `Metric` par épreuve officielle (niveau servi, état servi
 * `StatutObjectif`, compteur, CTA plein sur l'épreuve de l'étape courante du
 * parcours), le bandeau « Entretien en temps réel » (lien vers le hub EO,
 * D3-B), puis « Renforcer mon français » — ordre de la maquette, le même sur
 * le mobile. Civique : `PageHead` (thèmes, séries), la carte
 * de reprise, une `ThemeCard` par thème (anneau = `avancementSeriesCivique`
 * du thème, description servie). « Statistiques par thème » de la maquette
 * est **masqué** : rien ne le sert.
 *
 * 🛑 **« Structure de la langue » n'est PAS une cinquième épreuve** (arbitrage
 * du propriétaire, 2026-09-13). Le TCF IRN en comporte quatre : CO, CE, EE,
 * EO. Elle est donc sortie de la liste et rangée dans sa propre section,
 * « Renforcer mon français », avec une note qui le dit — l'équivalent du
 * bandeau que le mobile posait déjà sur son écran de détail. Le backend
 * l'excluait déjà de l'examen blanc, du Plan et du diagnostic : seul
 * l'affichage la présentait comme un pair.
 *
 * 🛑 **« Reprendre » vient du PLAN** (demande du propriétaire, 2026-09-12) :
 * côté TCF c'est `planNowCard` — la **même** autorité que la carte « À faire
 * maintenant » du Plan et de l'Accueil, donc la même action, mesure de domaine
 * prioritaire comprise —, la cible de rang 1 côté civique. Réviser ne tient
 * aucun historique à lui, et les trois écrans ne peuvent donc pas désigner
 * trois choses différentes.
 *
 * 🛑 **Plus de porte « diagnostic » ici** (D-69, 2026-09-28) : le Plan existe
 * pour tout compte, donc « Reprendre » annonce toujours son action — le
 * premier examen du cycle pour un compte sans diagnostic. Un visiteur n'a pas
 * de Plan : il garde le catalogue et son bandeau de découverte.
 *
 * 🛑 **Pas de bascule de parcours ICI** : on arrive par la barre latérale, qui
 * porte une entrée « Entraînement » par module (Navigation v2).
 *
 * 🛑 **Aucune phrase n'est composée ici** : celles de Réviser vivent dans
 * `lib/reviser.ts` (miroir de `reviser_labels.dart`), celles de la maquette
 * dans `lib/module-ecrans.ts`, les états servis dans `lib/etats-servis.ts`.
 *
 * Colonne : celle du shell (`home`) pour un compte ; un visiteur, hors shell,
 * garde la colonne large du kit (`wide`).
 */

import { useMemo } from "react";
import {
  BookOpen,
  Compass,
  Ear,
  FileText,
  Gavel,
  Globe,
  Info,
  Landmark,
  LayoutGrid,
  Mic,
  PenLine,
  Scale,
  Sparkles,
  Users,
  type LucideIcon,
} from "lucide-react";
import {
  civicPlanApi,
  dashboardApi,
  journeyApi,
  learningPlanApi,
  PROGRESS_CACHE_PREFIX,
  progressApi,
  publicThemeApi,
  themeApi,
} from "@/lib/api";
import { type CachedData, useCachedData } from "@/lib/use-cached-data";
import { themeSlug } from "@/lib/themes";
import { entrainementHref } from "@/lib/module-switch";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { useCivicSerie } from "@/app/_components/plan/useCivicSerie";
import { useCivicUniteSerie } from "@/app/_components/plan/use-civic-unite-serie";
import { planUnlockHref } from "@/lib/plan-unlock";
import {
  usePlanAssessment,
  usePlanExercise,
} from "@/app/_components/plan/use-plan-exercise";
import {
  canAccessModule,
  type AuthenticatedUser,
  type CivicPlanCibleDto,
  type DashboardCategoryStat,
  type DashboardSummaryResponse,
  type JourneyDto,
  type LearningPlanDto,
  niveauCecrlShort,
  type PlanDomainDto,
  type ProgressDto,
  type ThemeUserResponse,
} from "@/lib/types";
import {
  EE_CONFIG,
  EO_CONFIG,
  productionEntryHref,
} from "@/app/_components/production/config";
import {
  ActionCard,
  type ActionCardCta,
  Badge,
  BlockError,
  BlockSkeleton,
  Card,
  Cta,
  Grid,
  Hero,
  InfoCard,
  Metric,
  Pad,
  PageHead,
  Section,
  SejourApp,
  Stack,
  ThemeCard,
  TipCard,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {
  avancementSeriesCivique,
  domainForCode,
  epreuveMeta,
  epreuveStatus,
  isProductionCode,
  REVISER_NOT_STARTED,
  REVISER_RESUME_LABEL,
  reviserResumeCivique,
  reviserResumeTcf,
  reviserSectionTitle,
  themeLigneFor,
  REVISER_RENFORCER_NOTE,
  REVISER_RENFORCER_NOTE_TITLE,
  REVISER_RENFORCER_TITLE,
  sectionEpreuve,
  TCF_CODE_COMPLEMENTAIRE,
  TCF_EPREUVES_OFFICIELLES,
  themeStatus,
} from "@/lib/reviser";
import { niveauActuelEpreuve } from "@/lib/progres";
import { etatEpreuveTcf } from "@/lib/etats-servis";
import { ACCUEIL_BLOCK_ERROR, ACCUEIL_INCONNU, ACCUEIL_RETRY } from "@/lib/accueil";
import { PLAN_DOMAIN_SECTION, type PlanDomainEpreuve } from "@/lib/plan-domain";
import {
  ENTRAINEMENT_METRIC_CTA,
  ENTRAINEMENT_TCF_BADGE,
  ENTRAINEMENT_TCF_SUBTITLE,
  ENTRAINEMENT_THEME_CTA,
  ENTRAINEMENT_TITLE,
  ENTRETIEN_CTA,
  ENTRETIEN_LABEL,
  ENTRETIEN_SECTION_TITLE,
  ENTRETIEN_STAT,
  ENTRETIEN_SUB,
  ENTRETIEN_TITLE,
  entrainementCiviqueSubtitle,
  entrainementSeriesBadge,
  entrainementThemesBadge,
  MODULE_CIVIQUE_KICKER,
  MODULE_TCF_KICKER,
} from "@/lib/module-ecrans";
import {
  JOURNEY_NEEDS_OBJECTIVE_CTA,
  JOURNEY_NEEDS_OBJECTIVE_TEXT,
  JOURNEY_NEEDS_OBJECTIVE_TITLE,
  journeyTargetPathHref,
} from "@/lib/journey";
import {PASS_MODULE_NAME, PASS_OFFER_PLAN, PASS_PITCH, passModuleOfExam} from "@/lib/passes";

/** Le pictogramme rendu à la taille d'une carte du kit. */
function renderIcon(Icon: LucideIcon) {
  return <Icon aria-hidden />;
}

/** Pictogramme d'une catégorie — le même que sur le mobile et sur le Plan. */
const ICONS: Record<string, LucideIcon> = {
  TCF_CO: Ear,
  TCF_CE: FileText,
  TCF_STRUCTURE: LayoutGrid,
  TCF_EE: PenLine,
  TCF_EO: Mic,
  CIV_PRINCIPES: Scale,
  CIV_INSTITUTIONS: Landmark,
  CIV_DROITS_DEVOIRS: Gavel,
  CIV_HISTOIRE_GEO: Globe,
  CIV_SOCIETE: Users,
};

function iconFor(code: string): LucideIcon {
  return ICONS[code] ?? BookOpen;
}

/** Le code court d'une épreuve (« CO »), lu sur la table du Plan. */
function codeCourt(code: string): string {
  return code in PLAN_DOMAIN_SECTION ? PLAN_DOMAIN_SECTION[code as PlanDomainEpreuve] : code;
}

/** Les parties non vides, jointes par « · ». */
function joindre(parts: Array<string | null | undefined>): string | null {
  const kept = parts.filter((p): p is string => Boolean(p && p.trim()));
  return kept.length > 0 ? kept.join(" · ") : null;
}

/** Ordre canonique des **quatre** épreuves du TCF IRN — le serveur sert les
 *  thèmes QCM puis ajoute EE/EO en synthétique.
 *
 *  🛑 **Structure de la langue n'y figure pas** : ce n'est pas une épreuve de
 *  l'examen (cf. `TCF_EPREUVES_OFFICIELLES`). Elle a sa propre section, sous
 *  les quatre, avec sa note. */
const TCF_ORDER: readonly string[] = TCF_EPREUVES_OFFICIELLES;

/** Où mène une ligne : l'écran de détail **qui existe déjà**. */
function hrefFor(stat: DashboardCategoryStat): string {
  switch (stat.code) {
    case "TCF_CO":
      return "/entrainement/tcf/co";
    case "TCF_CE":
      return "/entrainement/tcf/ce";
    case "TCF_STRUCTURE":
      return "/entrainement/tcf/structure";
    case "TCF_EE":
      return productionEntryHref(EE_CONFIG.base);
    case "TCF_EO":
      return productionEntryHref(EO_CONFIG.base);
    default:
      return `/entrainement/civique/${themeSlug(stat.code)}`;
  }
}

export function ReviserScreen({
  module,
  user,
}: {
  module: "TCF" | "CIVIQUE";
  user: AuthenticatedUser | null;
}) {
  const isGuest = user === null;
  const isPremium = !isGuest && canAccessModule(user, module);

  /* Un visiteur n'a ni tableau de bord ni plan : il voit le catalogue, et le
     bandeau de découverte l'invite à créer un compte. */
  const summary = useCachedData<DashboardSummaryResponse>(
    isGuest ? null : "reviser:dashboard",
    () => dashboardApi.summaryCached(),
  );
  const guestThemes = useCachedData<ThemeUserResponse[]>(
    isGuest && module === "CIVIQUE" ? "reviser:themes-publics" : null,
    () => publicThemeApi.list("CIVIQUE"),
  );

  /* 🛑 Le shell connecté porte la colonne de la maquette (`home`) ; un
     visiteur garde le chrome public et la colonne large du kit. */
  return (
    <SejourApp wide={isGuest} className={isGuest ? undefined : sejourStyles.home}>
      {module === "TCF" ? (
        <TcfBody
          summary={summary}
          isGuest={isGuest}
          isPremium={isPremium}
        />
      ) : (
        <CiviqueBody
          summary={summary}
          guestThemes={guestThemes.data ?? []}
          isGuest={isGuest}
          isPremium={isPremium}
        />
      )}
    </SejourApp>
  );
}

/* ------------------------------------------------------------------- TCF */

function TcfBody({
  summary,
  isGuest,
  isPremium,
}: {
  summary: CachedData<DashboardSummaryResponse>;
  isGuest: boolean;
  isPremium: boolean;
}) {
  const plan = useCachedData<LearningPlanDto>(
    isGuest ? null : learningPlanApi.cacheKey,
    () => learningPlanApi.getCached(),
  );
  /* 🛑 Le parcours, lu au **même endroit** que le Plan : les deux alimentent la
     même carte de reprise, et n'en lire qu'un rouvrirait l'écart. */
  const journey = useCachedData<JourneyDto>(
    isGuest ? null : journeyApi.cacheKey,
    () => journeyApi.getCached(),
  );
  /* L'état de chaque épreuve face à l'objectif (`StatutObjectif`), servi par
     `/api/me/progress` — la lecture EN CACHE de l'Accueil. Son échec retire
     seulement la ligne d'état : le reste de la tuile est servi ailleurs. */
  const progres = useCachedData<ProgressDto>(
    isGuest ? null : `${PROGRESS_CACHE_PREFIX}current`,
    () => progressApi.get(),
  );
  /* 🛑 **Les mêmes lanceurs que le Plan**, jamais un second chemin : une
     ligne de séance est un exercice **ou** une mesure de domaine, et les
     deux savent déjà où aller. */
  const exercise = usePlanExercise();
  const assessment = usePlanAssessment();

  /* 🛑 **Le drapeau d'accès descend jusqu'à l'autorité**, il n'est pas relu
     ici : c'est `planNowCard` qui en tire le geste, comme sur le Plan. */
  const resume = reviserResumeTcf(plan.data ?? null, journey.data ?? null, !isPremium);
  const carte = resume?.carte ?? null;
  const busy = exercise.starting || assessment.starting !== null;

  /* 🛑 **L'autorité d'AFFICHAGE du niveau**, servie par le tableau de bord déjà
     chargé — donc **aucun appel de plus**. C'est la même valeur que l'Accueil,
     le Profil, l'écran Progrès et l'écran Diagnostic
     (`TcfProfileService.levelProfileAccueil`). → `docs/regles/progression.md`. */
  const profil = summary.data?.tcfDomainProfile ?? null;

  const stats = useMemo(() => orderedTcf(summary.data ?? null), [summary.data]);
  /* 🛑 Servie comme les autres, mais rangée à part : ce n'est pas une épreuve
     du TCF IRN. `orderedTcf` ne la trouve plus dans son ordre canonique. */
  const complementaire = useMemo(() => statComplementaire(summary.data ?? null), [summary.data]);

  /* **L'épreuve que le serveur désigne** — celle de l'étape « À faire
     maintenant » du parcours (`journey.current`), la même autorité que le Plan
     et l'Accueil : sa tuile porte le CTA plein, les autres le doux. Aucune
     désignation ⇒ tout en doux. Miroir : `_prioritaire` (mobile). */
  const blocCourant = journey.data?.current?.bloc ?? null;
  const prioritaire = blocCourant?.kind === "EPREUVE" ? blocCourant.code : null;

  /* 🛑 **Le même geste que le bouton du Plan**, sur la **même** action : une
     MESURE passe devant tout le reste, et c'est `planNowCard` qui l'a tranché —
     l'écran exécute, il ne rechoisit pas. */
  const reprendre = () => {
    if (!carte) return;
    if (carte.mesure) {
      void assessment.start(carte.mesure.assessment);
      return;
    }
    if (carte.exercise) void exercise.start(carte.exercise);
  };
  /* 🛑 **Le geste ET sa destination viennent du Plan** : `OUVRIR_ETAPE`
     ouvre l'écran de l'étape (ses deux séries), `LANCER` démarre l'action, et
     un geste d'achat passe par l'écran de transition (A145). */
  const resumeCta: ActionCardCta | null = !resume
    ? null
    : resume.geste === "DEBLOQUER"
      ? { label: resume.cta, href: planUnlockHref("TCF") }
      : resume.geste === "OUVRIR_ETAPE" && resume.etapeHref
        ? { label: resume.cta, href: resume.etapeHref }
        : { label: resume.cta, onClick: reprendre, disabled: busy };
  const resumeError = exercise.error ?? assessment.error;

  return (
    <>
      <Pad>
        <PageHead
          kicker={MODULE_TCF_KICKER}
          title={ENTRAINEMENT_TITLE}
          subtitle={ENTRAINEMENT_TCF_SUBTITLE}
          aside={<Badge>{ENTRAINEMENT_TCF_BADGE}</Badge>}
        />
      </Pad>
      {resume ? (
        <Pad className={sejourStyles.pageBody}>
          <ActionCard
            module="tcf"
            /* Le domaine **réellement lancé** : celui de la mesure quand elle
               passe devant, celui de la priorité sinon. */
            icon={renderIcon(iconFor(sectionEpreuve(resume.section) ?? "TCF_CO"))}
            label={REVISER_RESUME_LABEL}
            title={resume.title}
            meta={resume.subtitle}
            badge={resume.section}
            cta={resumeCta}
            block
          >
            {resumeError ? <p className={sejourStyles.actionNote} role="alert">{resumeError}</p> : null}
          </ActionCard>
        </Pad>
      ) : null}
      {/* 🛑 **L'invitation à déclarer un objectif se lit ici aussi** (arbitrage
          du propriétaire, 2026-09-17). Elle n'enlève rien — la reprise
          ci-dessus reste servie, le Plan n'exige pas d'objectif. */}
      {journey.data?.state === "NEEDS_OBJECTIVE" && (
        <Section title={JOURNEY_NEEDS_OBJECTIVE_TITLE}>
          <Pad>
            <Card>
              <p className={sejourStyles.tiny}>{JOURNEY_NEEDS_OBJECTIVE_TEXT}</p>
              <Cta href={journeyTargetPathHref(entrainementHref("TCF"))}>{JOURNEY_NEEDS_OBJECTIVE_CTA}</Cta>
            </Card>
          </Pad>
        </Section>
      )}
      {/* 🛑 **« Reprendre » n'est PAS le Plan** (consigne du propriétaire,
          contrôle F, D113) : il ne compterait comme tel que si l'exercice repris
          avait été lancé depuis le Plan avec un marqueur PERSISTÉ au lancement,
          et ce marqueur n'existe pas. Un 403 y prend donc le CTA de l'écran
          d'arrivée, sans parcours : `MOCK_EXAM` pour une mesure, `OTHER` pour
          un exercice — miroir du mobile. */}
      <PaywallSheet
        ctaLocation={assessment.paywallOpen ? "MOCK_EXAM" : "OTHER"}
        screen="reviser"
        journeyId={null}
        open={exercise.paywallOpen || assessment.paywallOpen}
        module="INTEGRAL"
        onClose={() => {
          exercise.closePaywall();
          assessment.closePaywall();
        }}
      />
      <DemoLink isGuest={isGuest} isPremium={isPremium} module="TCF" />
      <Section title={reviserSectionTitle("TCF", stats.length)}>
        <Pad>
          {summary.loading ? (
            <Grid cols={4}>
              {stats.map((stat) => <BlockSkeleton key={stat.code} height={236} />)}
            </Grid>
          ) : summary.error !== null ? (
            <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={summary.reload} />
          ) : (
            <Grid cols={4}>
              {stats.map((stat) => {
                const domain: PlanDomainDto | null = domainForCode(plan.data ?? null, stat.code);
                const niveau = niveauActuelEpreuve(profil, stat.code);
                const epreuve = progres.data?.tcf.epreuves.find((e) => e.epreuve === stat.code) ?? null;
                /* Sans le profil : le niveau est déjà la valeur de la tuile, la méta ne
                   le redit pas (parité mobile). */
                const etape = isProductionCode(stat.code) ? epreuveStatus(stat, domain, null) : null;
                return (
                  <Metric
                    key={stat.code}
                    module="tcf"
                    code={codeCourt(stat.code)}
                    value={niveau ? niveauCecrlShort(niveau) : ACCUEIL_INCONNU}
                    state={etatEpreuveTcf(epreuve)}
                    /* Le nom, le compteur servi, puis — pour une production —
                       l'étape que le Plan construit ou ce qui est acquis
                       (`epreuveStatus`). Le niveau est déjà la valeur. */
                    meta={joindre([
                      stat.label,
                      epreuveMeta(stat),
                      etape !== REVISER_NOT_STARTED ? etape : null,
                    ])}
                    cta={{ label: ENTRAINEMENT_METRIC_CTA, href: hrefFor(stat) }}
                    ctaEmphasis={prioritaire === stat.code ? "solid" : "soft"}
                  />
                );
              })}
            </Grid>
          )}
        </Pad>
      </Section>
      {/* **Entretien en temps réel** (D3-B) : le hub de l'expression orale, où
          vit l'examinateur vocal. Texte statique de la maquette, aucune donnée
          — le quota de simulations se lit là-bas. */}
      <Section title={ENTRETIEN_SECTION_TITLE}>
        <Pad>
          <Hero
            module="tcf"
            icon={<Sparkles />}
            label={ENTRETIEN_LABEL}
            title={ENTRETIEN_TITLE}
            sub={ENTRETIEN_SUB}
            stat={ENTRETIEN_STAT}
            cta={{ label: ENTRETIEN_CTA, href: productionEntryHref(EO_CONFIG.base) }}
          />
        </Pad>
      </Section>
      <Section title={REVISER_RENFORCER_TITLE}>
        <Pad>
          <Stack>
            <InfoCard
              module="tcf"
              icon={renderIcon(iconFor(complementaire.code))}
              title={complementaire.label}
              meta={joindre([epreuveStatus(complementaire, null, profil), epreuveMeta(complementaire)])}
              trailing="chevron"
              href={hrefFor(complementaire)}
            />
            <TipCard
              icon={<Info aria-hidden />}
              label={REVISER_RENFORCER_NOTE_TITLE}
              text={REVISER_RENFORCER_NOTE}
            />
          </Stack>
        </Pad>
      </Section>
    </>
  );
}

/**
 * Les **quatre** épreuves du TCF IRN, dans l'ordre canonique.
 *
 * Un visiteur n'a pas de tableau de bord : on rend le **catalogue** (les quatre
 * épreuves, à zéro), plutôt qu'un écran vide. Rien n'y est mesuré, et chaque
 * tuile le dit (« — »).
 */
function orderedTcf(
  summary: DashboardSummaryResponse | null,
): DashboardCategoryStat[] {
  const byCode = new Map((summary?.tcf ?? []).map((c) => [c.code, c]));
  return TCF_ORDER.map(
    (code) =>
      byCode.get(code) ?? {
        themeId: null,
        code,
        label: TCF_FALLBACK_LABEL[code] ?? code,
        percent: null,
        answered: 0,
        total: 0,
        mockExams: 0,
        bestMockScore: null,
        level: null,
        seriesDone: 0,
        seriesTotal: 0,
        subjectsDone: 0,
        subjectsTotal: 0,
      },
  );
}

/**
 * Structure de la langue, servie comme les autres mais **hors des quatre**.
 *
 * Même repli qu'`orderedTcf` : un visiteur la voit à zéro plutôt que pas du
 * tout — la page reste un catalogue.
 */
function statComplementaire(
  summary: DashboardSummaryResponse | null,
): DashboardCategoryStat {
  return (
    (summary?.tcf ?? []).find((c) => c.code === TCF_CODE_COMPLEMENTAIRE) ?? {
      themeId: null,
      code: TCF_CODE_COMPLEMENTAIRE,
      label: TCF_FALLBACK_LABEL[TCF_CODE_COMPLEMENTAIRE],
      percent: null,
      answered: 0,
      total: 0,
      mockExams: 0,
      bestMockScore: null,
      seriesDone: 0,
      seriesTotal: 0,
      subjectsDone: 0,
      subjectsTotal: 0,
    }
  );
}

/** Le nom d'une épreuve quand le serveur n'a pas été appelé (visiteur). */
const TCF_FALLBACK_LABEL: Record<string, string> = {
  TCF_CO: "Compréhension orale",
  TCF_CE: "Compréhension écrite",
  TCF_STRUCTURE: "Structure de la langue",
  TCF_EE: "Expression écrite",
  TCF_EO: "Expression orale",
};

/* --------------------------------------------------------------- Civique */

function CiviqueBody({
  summary,
  guestThemes,
  isGuest,
  isPremium,
}: {
  summary: CachedData<DashboardSummaryResponse>;
  guestThemes: ThemeUserResponse[];
  isGuest: boolean;
  isPremium: boolean;
}) {
  const { enCours, erreur, paywall, setPaywall, commencer } = useCivicSerie();
  /* 🛑 **Un lanceur par GRAIN** (A87), comme sur le Plan civique : l'unité
     officielle du cycle et la cible du plan dérivé sont deux routes serveur
     distinctes. La source est **servie**, l'écran exécute. */
  const serieUnite = useCivicUniteSerie();
  const civicPlan = useCachedData(isGuest ? null : civicPlanApi.cacheKey, () =>
    civicPlanApi.getCached(),
  );
  /* 🛑 **Le CYCLE, comme sur le Plan** : « À faire maintenant » y lit
     `journey.current` depuis D-50 §2. Sans lui, Réviser annoncerait la cible du
     plan dérivé pendant que le Plan annonce l'étape du cycle. */
  const journey = useCachedData<JourneyDto>(
    isGuest ? null : journeyApi.cacheKeyFor("CIVIQUE"),
    () => journeyApi.getCached("CIVIQUE"),
  );
  /* La description éditoriale de chaque thème (`ThemeUserResponse.description`,
     servie) : un compte la lit sur `/api/themes`, un visiteur sur la liste
     publique déjà chargée. Son échec retire seulement les descriptions. */
  const themes = useCachedData<ThemeUserResponse[]>(
    isGuest ? null : "reviser:themes",
    () => themeApi.list("CIVIQUE"),
  );
  const prochaine: CivicPlanCibleDto | null = civicPlan.data?.prochaine ?? null;
  const resume = reviserResumeCivique(civicPlan.data ?? null, journey.data ?? null, !isPremium);

  const stats = useMemo(() => {
    if (summary.data) return summary.data.civique;
    return [...guestThemes]
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map<DashboardCategoryStat>((t) => ({
        themeId: t.id,
        code: t.code,
        label: t.name,
        percent: null,
        answered: 0,
        total: 0,
        mockExams: 0,
        bestMockScore: null,
        level: null,
        seriesDone: 0,
        seriesTotal: 0,
        subjectsDone: 0,
        subjectsTotal: 0,
      }));
  }, [summary.data, guestThemes]);

  const descriptions = useMemo(() => {
    const source = isGuest ? guestThemes : (themes.data ?? []);
    return new Map(source.map((t) => [t.id, t.description?.trim() || null]));
  }, [isGuest, guestThemes, themes.data]);

  /* 🛑 Le pourcentage UNIQUE (`avancementSeriesCivique`), sur tous les thèmes
     servis — la même valeur que l'Accueil et le Plan civique. */
  const avancement = summary.data ? avancementSeriesCivique(summary.data.civique) : null;

  const resumeCta: ActionCardCta | null = !resume
    ? null
    : resume.geste === "DEBLOQUER"
      ? { label: resume.cta, href: planUnlockHref("CIVIQUE") }
      : resume.geste === "OUVRIR_ETAPE" && resume.etapeHref
        ? { label: resume.cta, href: resume.etapeHref }
        : {
          label: resume.cta,
          disabled: enCours !== null || serieUnite.enCours !== null,
          onClick: () => {
            const source = resume.source;
            if (!source) return;
            if (source.kind === "UNITE") void serieUnite.start(source.code);
            else void commencer(source.cible);
          },
        };
  const resumeError = erreur ?? serieUnite.erreur;

  return (
    <>
      <Pad>
        <PageHead
          tone="civique"
          kicker={MODULE_CIVIQUE_KICKER}
          title={ENTRAINEMENT_TITLE}
          subtitle={entrainementCiviqueSubtitle(stats.length > 0 ? stats.length : null)}
          aside={
            <>
              {stats.length > 0 && <Badge module="civique">{entrainementThemesBadge(stats.length)}</Badge>}
              {avancement && avancement.total > 0 && (
                <Badge module="civique">{entrainementSeriesBadge(avancement.terminees, avancement.total)}</Badge>
              )}
            </>
          }
        />
      </Pad>
      {resume ? (
        <Pad className={sejourStyles.pageBody}>
          <ActionCard
            module="civique"
            /* Le pictogramme du thème quand la reprise en a un ; une **unité**
               du cycle n'en porte pas, on reprend alors la boussole. */
            icon={renderIcon(prochaine ? iconFor(prochaine.themeCode) : Compass)}
            label={REVISER_RESUME_LABEL}
            title={resume.title}
            meta={resume.subtitle}
            badge={resume.badge}
            cta={resumeCta}
            block
          >
            {resumeError ? <p className={sejourStyles.actionNote} role="alert">{resumeError}</p> : null}
          </ActionCard>
        </Pad>
      ) : null}
      <DemoLink isGuest={isGuest} isPremium={isPremium} module="CIVIQUE" />
      <Section title={reviserSectionTitle("CIVIQUE", stats.length)}>
        <Pad>
          {summary.loading ? (
            <Grid cols={2}>
              <BlockSkeleton height={196} />
              <BlockSkeleton height={196} />
            </Grid>
          ) : summary.error !== null ? (
            <BlockError message={ACCUEIL_BLOCK_ERROR} retryLabel={ACCUEIL_RETRY} onRetry={summary.reload} />
          ) : (
            <Grid cols={2}>
              {stats.map((stat) => {
                const theme = avancementSeriesCivique([stat]);
                /* La ligne d'état composée sur des faits servis (`themeStatus`) —
                   jamais déduite de l'anneau. Sans série servie (visiteur),
                   elle prend la place du compteur. */
                const statut = themeStatus(themeLigneFor(civicPlan.data?.themes, stat.themeId), stat);
                const compteur = epreuveMeta(stat);
                return (
                  <ThemeCard
                    key={stat.code}
                    module="civique"
                    icon={renderIcon(iconFor(stat.code))}
                    title={stat.label}
                    description={stat.themeId ? descriptions.get(stat.themeId) ?? null : null}
                    ring={theme.pourcentage}
                    count={compteur ?? statut}
                    state={compteur ? { label: statut, tone: "neutral" } : null}
                    cta={{ label: ENTRAINEMENT_THEME_CTA, href: hrefFor(stat) }}
                  />
                );
              })}
            </Grid>
          )}
        </Pad>
      </Section>
      {/* 🛑 La reprise civique relance l'action de `civicNowCard`, sans
          marqueur persisté de lancement depuis le Plan : pas le Plan (D113),
          le CTA d'une série (`OTHER`), sans parcours — miroir du mobile. */}
      <PaywallSheet
        ctaLocation="OTHER"
        screen="reviser"
        journeyId={null}
        open={paywall || serieUnite.paywall}
        module="CIVIQUE"
        onClose={() => {
          setPaywall(false);
          serieUnite.setPaywall(false);
        }}
      />
    </>
  );
}

/* ----------------------------------------------------------- Les briques */

/**
 * Le bandeau de découverte, **conservé de l'ancien hub** : c'est la surface de
 * conversion de la page, et `/entrainement` reste ouverte aux visiteurs. Il
 * disparaît dès que le module est accessible. Stylé en `InfoCard` (maquette).
 */
function DemoLink({
  isGuest,
  isPremium,
  module,
}: {
  isGuest: boolean;
  isPremium: boolean;
  module: "TCF" | "CIVIQUE";
}) {
  if (isPremium) return null;
  const quoi = module === "TCF" ? "épreuve et niveau" : "thème";
  const passModule = passModuleOfExam(module);
  return (
    <Pad className={sejourStyles.pageBody}>
      <InfoCard
        module={module === "TCF" ? "tcf" : "civique"}
        icon={<Sparkles aria-hidden />}
        title={isGuest
          ? `Découverte gratuite · 1 série offerte par ${quoi}`
          : `Toutes les séries avec le pass ${PASS_MODULE_NAME[passModule]}`}
        meta={isGuest
          ? "Et le 1ᵉʳ examen blanc offert. Créez un compte gratuit pour sauvegarder vos résultats."
          : PASS_PITCH[passModule]}
        trailing="chevron"
        href={isGuest ? "/connexion" : `/paiement?plan=${PASS_OFFER_PLAN[passModule]}`}
      />
    </Pad>
  );
}
