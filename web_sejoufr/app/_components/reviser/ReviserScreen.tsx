"use client";

/**
 * **L'écran « Réviser »** — la maquette du propriétaire
 * (`~/Desktop/sejourfr_ecrans/reviser_{tcf,civique}.png`), montée sur le KIT.
 *
 * L'en-tête, la carte **« Reprendre là où vous vous êtes arrêté »**, puis la
 * liste des **quatre épreuves** du TCF IRN — ou des cinq thèmes en civique.
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
 * 🛑 **Sans diagnostic, la carte de tête PROPOSE LE DIAGNOSTIC** (demande du
 * propriétaire, 2026-09-13) — elle n'invente toujours aucune reprise, mais elle
 * ne disparaît plus : l'écran s'ouvrait sur sa liste d'épreuves sans jamais
 * nommer le geste qui débloque le reste. Le fait lu reste
 * **`prep.planDisponible`**, jamais `etape` — c'est lui qui rend mot pour mot la
 * condition du moteur —, et les phrases de la porte viennent de
 * `planIndisponible`, la même autorité que l'Accueil et l'écran Plan.
 *
 * 🛑 **Un VISITEUR n'a pas de porte** : il n'a pas de compte, donc pas de
 * diagnostic à faire. Il garde le catalogue et son bandeau de découverte.
 *
 * 🛑 **Pas de bascule de parcours ICI** (arbitrage du propriétaire,
 * 2026-09-12) : sur le web on arrive par la barre latérale, qui porte déjà ses
 * deux entrées « TCF IRN » et « Examen civique ». Le reste est **identique au
 * mobile**, qui garde la sienne parce que Réviser y est un onglet.
 *
 * 🛑 **Aucune phrase n'est composée ici** : elles vivent dans `lib/reviser.ts`,
 * miroir mot pour mot de `mobile_sejourfr/lib/screens/reviser/reviser_labels.dart`.
 *
 * 🛑 **Colonne LARGE en desktop** (`<SejourApp wide>`), et c'est la maquette qui
 * tranche : `grok_ecran/screenshots/reviser-hub.png` mesure 960 px de contenu à
 * 1280 px de fenêtre — la colonne de 1080 px, exactement. Réviser est un
 * **catalogue**, pas un écran de lecture : sa grille d'épreuves à deux colonnes
 * tenait dans 720 px, où les titres passaient à la ligne et où le tiers droit de
 * l'écran restait blanc.
 */

import Link from "next/link";
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
  Users,
  type LucideIcon,
} from "lucide-react";
import {
  civicPlanApi,
  dashboardApi,
  journeyApi,
  learningPlanApi,
  publicThemeApi,
  userContentApi,
} from "@/lib/api";
import { useCachedData } from "@/lib/use-cached-data";
import { themeSlug } from "@/lib/themes";
import { PaywallSheet } from "@/app/_components/PaywallSheet";
import { useCivicSerie } from "@/app/_components/plan/useCivicSerie";
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
  type ModulePreparation,
  type PlanDomainDto,
  type ThemeUserResponse,
} from "@/lib/types";
import {
  EE_CONFIG,
  EO_CONFIG,
  productionEntryHref,
} from "@/app/_components/production/config";
import {
  Card,
  Cta,
  EpreuveRow,
  NoteCard,
  Pad,
  Section,
  SejourApp,
  Stack,
  Top,
  sejourStyles,
} from "@/app/_components/sejour/SejourKit";
import {
  domainForCode,
  epreuveMeta,
  epreuveRatio,
  epreuveStatus,
  REVISER_DEPART_LABEL,
  REVISER_RESUME_CTA,
  REVISER_RESUME_LABEL,
  reviserResumeCivique,
  reviserResumeTcf,
  reviserSectionTitle,
  reviserSubtitle,
  reviserTitle,
  themeLigneFor,
  REVISER_RENFORCER_NOTE,
  REVISER_RENFORCER_NOTE_TITLE,
  REVISER_RENFORCER_TITLE,
  sectionEpreuve,
  TCF_CODE_COMPLEMENTAIRE,
  TCF_EPREUVES_OFFICIELLES,
  themeStatus,
} from "@/lib/reviser";
import {planIndisponible, type PlanIndisponible} from "@/lib/preparation";
import styles from "./reviser.module.css";

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

  return (
    <SejourApp wide>
      {/* 🛑 Le titre nomme le PARCOURS, pas l'écran (demande du propriétaire,
          2026-09-13) — divergence voulue avec le mobile, cf. `reviserTitle`. */}
      <Top title={reviserTitle(module)} />
      <Pad>
        <p className={styles.sub}>{reviserSubtitle(module)}</p>
      </Pad>
      {module === "TCF" ? (
        <TcfBody
          summary={summary.data ?? null}
          isGuest={isGuest}
          isPremium={isPremium}
        />
      ) : (
        <CiviqueBody
          summary={summary.data ?? null}
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
  summary: DashboardSummaryResponse | null;
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
  const prep = useModulePreparation(isGuest, "TCF");
  const disponible = prep?.planDisponible === true;
  /* 🛑 **Les mêmes lanceurs que le Plan**, jamais un second chemin : une
     ligne de séance est un exercice **ou** une mesure de domaine, et les
     deux savent déjà où aller. */
  const exercise = usePlanExercise();
  const assessment = usePlanAssessment();

  /* 🛑 Sans `planDisponible`, il n'y a rien à reprendre — et on ne l'invente
     pas. La carte de tête cesse d'être une reprise et devient la **porte du
     diagnostic**, avec les mots de `planIndisponible`. */
  const resume = disponible
    ? reviserResumeTcf(plan.data ?? null, journey.data ?? null)
    : null;
  const gate = prep && !disponible ? planIndisponible(prep, "TCF") : null;
  const carte = resume?.carte ?? null;
  const busy = exercise.starting || assessment.starting !== null;

  /* 🛑 **L'autorité d'AFFICHAGE du niveau**, servie par le tableau de bord déjà
     chargé — donc **aucun appel de plus**. C'est la même valeur que l'Accueil,
     le Profil, l'écran Progrès et l'écran Diagnostic
     (`TcfProfileService.levelProfileAccueil`). Réviser lisait le niveau du Plan
     puis `stat.level` : trois autorités pour une phrase.
     → `docs/regles/progression.md`. */
  const profil = summary?.tcfDomainProfile ?? null;

  const stats = useMemo(() => orderedTcf(summary), [summary]);
  /* 🛑 Servie comme les autres, mais rangée à part : ce n'est pas une épreuve
     du TCF IRN. `orderedTcf` ne la trouve plus dans son ordre canonique. */
  const complementaire = useMemo(() => statComplementaire(summary), [summary]);

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

  return (
    <>
      {resume ? (
        <ResumeCard
          /* Le domaine **réellement lancé** : celui de la mesure quand elle
             passe devant, celui de la priorité sinon. */
          icon={iconFor(sectionEpreuve(resume.section) ?? "TCF_CO")}
          title={resume.title}
          subtitle={resume.subtitle}
          onClick={reprendre}
          busy={busy}
          error={exercise.error ?? assessment.error}
          tone="primary"
        />
      ) : gate ? (
        <GateCard gate={gate} tone="primary" />
      ) : null}
      <PaywallSheet
        origin="plan"
        open={exercise.paywallOpen}
        module="INTEGRAL"
        onClose={exercise.closePaywall}
      />
      <PaywallSheet
        origin="plan"
        open={assessment.paywallOpen}
        module="INTEGRAL"
        onClose={assessment.closePaywall}
      />
      <DemoLink isGuest={isGuest} isPremium={isPremium} module="TCF" />
      <Section title={reviserSectionTitle("TCF", stats.length)}>
        <Pad>
          <Stack className={sejourStyles.deskGrid2}>
            {stats.map((stat) => {
              const domain: PlanDomainDto | null = domainForCode(
                plan.data ?? null,
                stat.code,
              );
              return (
                <EpreuveRow
                  key={stat.code}
                  icon={iconFor(stat.code)}
                  title={stat.label}
                  status={epreuveStatus(stat, domain, profil)}
                  meta={epreuveMeta(stat, domain)}
                  ratio={epreuveRatio(stat, domain)}
                  href={hrefFor(stat)}
                />
              );
            })}
          </Stack>
        </Pad>
      </Section>
      <Section title={REVISER_RENFORCER_TITLE}>
        <Pad>
          <Stack>
            <EpreuveRow
              icon={iconFor(complementaire.code)}
              title={complementaire.label}
              status={epreuveStatus(complementaire, null, profil)}
              meta={epreuveMeta(complementaire, null)}
              ratio={epreuveRatio(complementaire, null)}
              href={hrefFor(complementaire)}
            />
            <NoteCard
              variant="soft"
              icon={Info}
              title={REVISER_RENFORCER_NOTE_TITLE}
            >
              <p className={styles.sub}>{REVISER_RENFORCER_NOTE}</p>
            </NoteCard>
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
 * ligne le dit.
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
        lastMockScore: null,
        prevMockScore: null,
        level: null,
        seriesDone: 0,
        seriesTotal: 0,
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
      lastMockScore: null,
      prevMockScore: null,
      seriesDone: 0,
      seriesTotal: 0,
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
  summary: DashboardSummaryResponse | null;
  guestThemes: ThemeUserResponse[];
  isGuest: boolean;
  isPremium: boolean;
}) {
  const { enCours, erreur, paywall, setPaywall, commencer } = useCivicSerie();
  const civicPlan = useCachedData(isGuest ? null : civicPlanApi.cacheKey, () =>
    civicPlanApi.getCached(),
  );
  const prep = useModulePreparation(isGuest, "CIVIQUE");
  const disponible = prep?.planDisponible === true;

  const prochaine: CivicPlanCibleDto | null = disponible
    ? (civicPlan.data?.prochaine ?? null)
    : null;
  const resume = reviserResumeCivique(prochaine);
  const gate = prep && !disponible ? planIndisponible(prep, "CIVIQUE") : null;

  const stats = useMemo(() => {
    if (summary) return summary.civique;
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
        lastMockScore: null,
        prevMockScore: null,
        level: null,
        seriesDone: 0,
        seriesTotal: 0,
      }));
  }, [summary, guestThemes]);

  return (
    <>
      {resume && prochaine ? (
        <ResumeCard
          icon={iconFor(prochaine.themeCode)}
          title={resume.title}
          subtitle={resume.subtitle}
          onClick={() => void commencer(prochaine)}
          busy={enCours === prochaine.id}
          error={erreur}
          tone="blue"
        />
      ) : gate ? (
        <GateCard gate={gate} tone="blue" />
      ) : null}
      <DemoLink isGuest={isGuest} isPremium={isPremium} module="CIVIQUE" />
      <Section title={reviserSectionTitle("CIVIQUE", stats.length)}>
        <Pad>
          <Stack className={sejourStyles.deskGrid2}>
            {stats.map((stat) => (
              <EpreuveRow
                key={stat.code}
                icon={iconFor(stat.code)}
                title={stat.label}
                status={themeStatus(
                  themeLigneFor(civicPlan.data?.themes, stat.themeId),
                  stat,
                )}
                href={hrefFor(stat)}
              />
            ))}
          </Stack>
        </Pad>
      </Section>
      <PaywallSheet
        origin="plan"
        open={paywall}
        module="CIVIQUE"
        onClose={() => setPaywall(false)}
      />
    </>
  );
}

/* ----------------------------------------------------------- Les briques */

/**
 * **La carte de tête** — « Reprendre là où vous vous êtes arrêté », ou la porte
 * du diagnostic quand il n'y a rien à reprendre.
 *
 * Même anatomie que la carte « À faire maintenant » du Plan : c'est la même
 * action, vue depuis un autre écran. Rouge côté TCF, bleu côté civique — la
 * sémantique de parcours du produit.
 *
 * 🛑 **Une seule carte pour les deux états**, pas deux composants presque
 * identiques : ce sont les mêmes quatre lignes — sur-titre, pictogramme, titre
 * et sous-titre, bouton — et seul leur contenu change.
 *
 * 🛑 **C'est le KIT qui porte la carte** (`Card variant="hero"`), plus une
 * `<article>` maison : `.resume` ne garde que le dégradé. Le mobile monte déjà
 * son `_ResumeCard` sur `SfCard(variant: hero)` — la divergence coûtait, au
 * palier desktop, un bouton plafonné à 420 px au milieu d'une carte pleine
 * largeur (le kit n'ouvre ce plafond que dans ses propres cartes).
 */
function ResumeCard({
  icon: Icon,
  label = REVISER_RESUME_LABEL,
  title,
  subtitle,
  cta = REVISER_RESUME_CTA,
  href,
  onClick,
  busy,
  error,
  tone,
}: {
  icon: LucideIcon;
  label?: string;
  title: string;
  subtitle: string | null;
  cta?: string;
  href?: string;
  onClick?: () => void;
  busy?: boolean;
  error?: string | null;
  tone: "primary" | "blue";
}) {
  return (
    <Pad className={styles.resumeWrap}>
      <Card variant="hero" className={styles.resume}>
        <p className={sejourStyles.label}>{label}</p>
        <div className={styles.resumeHead}>
          <span className={styles.resumeIco}>
            <Icon size={24} strokeWidth={2} aria-hidden />
          </span>
          <span>
            <b>{title}</b>
            {subtitle ? <span>{subtitle}</span> : null}
          </span>
        </div>
        <Cta href={href} onClick={onClick} variant={tone} disabled={busy}>
          {cta}
        </Cta>
        {error ? (
          <p className={sejourStyles.tiny} role="alert">
            {error}
          </p>
        ) : null}
      </Card>
    </Pad>
  );
}

/**
 * **La porte du diagnostic**, à la place de la reprise.
 *
 * 🛑 **Aucune phrase n'est écrite ici** : `planIndisponible` porte le titre, le
 * texte, le libellé du bouton et sa destination — la **même autorité** que
 * l'Accueil et l'écran Plan. C'est elle qui distingue « faire » de
 * « reprendre » quand un diagnostic est déjà commencé, et qui sait que le
 * civique a **sa** porte (`/diagnostic-civique`).
 */
function GateCard({gate, tone}: {gate: PlanIndisponible; tone: "primary" | "blue"}) {
  return (
    <ResumeCard
      icon={Compass}
      label={REVISER_DEPART_LABEL}
      title={gate.titre}
      subtitle={gate.texte}
      cta={gate.cta}
      href={gate.href}
      tone={tone}
    />
  );
}

/**
 * Le bandeau de découverte, **conservé de l'ancien hub** : c'est la surface de
 * conversion de la page, et `/entrainement` reste ouverte aux visiteurs. Il
 * disparaît dès que le module est accessible.
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
  return (
    <Pad className={styles.demoWrap}>
      <Link href={isGuest ? "/connexion" : "/paiement"} className={styles.demo}>
        <span className={styles.demoBody}>
          <b>
            {isGuest
              ? `Découverte gratuite · 1 série offerte par ${quoi}`
              : "Débloquez l'entraînement illimité"}
          </b>
          <span>
            {isGuest
              ? "Et un examen blanc complet offert. Créez un compte gratuit pour continuer et sauvegarder vos résultats."
              : "L'abonnement Intégral débloque tout le TCF, le civique et les examens blancs."}
          </span>
        </span>
        <span className={styles.demoArrow} aria-hidden>
          →
        </span>
      </Link>
    </Pad>
  );
}

/**
 * L'état servi du module — `planDisponible` en est **le seul fait** qui autorise
 * une carte de reprise, et le reste décide de la porte qui la remplace.
 *
 * `null` pour un visiteur et tant que l'état n'a pas répondu : ni reprise, ni
 * porte. On n'affiche pas une carte qu'on devra retirer une seconde plus tard,
 * et on ne propose pas un diagnostic à qui n'a pas de compte.
 */
function useModulePreparation(
  isGuest: boolean,
  module: "TCF" | "CIVIQUE",
): ModulePreparation | null {
  const prep = useCachedData(isGuest ? null : "reviser:preparation", () =>
    userContentApi.preparation(),
  );
  return (module === "TCF" ? prep.data?.tcf : prep.data?.civique) ?? null;
}
