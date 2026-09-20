"use client";

import {useEffect, useMemo, useState} from "react";
import {Landmark, ListChecks, Lock} from "lucide-react";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {useCivicSerie} from "./useCivicSerie";
import {civicPlanApi, journeyApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  CIVIC_PLAN_LOCKED_NOTE,
  CIVIC_PLAN_NOW_CTA,
  CIVIC_PLAN_NOW_TITLE,
  CIVIC_PLAN_PRIORITIES_TITLE,
  CIVIC_PLAN_RESULT_SEUIL,
  CIVIC_PLAN_RESULT_TITLE,
  CIVIC_PLAN_REVIEW_TITLE,
  CIVIC_PLAN_WORK_CTA,
  civicPlanGrainNote,
  civicPlanRaison,
  civicRevueLabel,
  civicSerieLabel,
} from "@/lib/civic-plan";
import {planIndisponibleDepuisEtat} from "@/lib/preparation";
import {
  canAccessModule,
  CIVIC_MAITRISE_LABEL,
  CIVIC_THEME_STATE_LABEL,
  type CivicPlanCibleDto,
  type CivicPlanDto,
  type CivicThemeState,
  type JourneyDto,
} from "@/lib/types";
import {
  Card,
  Cta,
  GoalStrip,
  LockItem,
  LockList,
  NowCard,
  Pad,
  Prio,
  Section,
  Stack,
  ThemeLine,
  Top,
  cx,
  sejourStyles,
  type Tone,
} from "@/app/_components/sejour/SejourKit";
import {PlanGate} from "./PlanGate";
import {PlanCycleSection} from "./PlanCycleSection";
import {useCivicUniteSerie} from "./use-civic-unite-serie";
import {JOURNEY_LOCKED_BADGE, journeyStepSubtitle, journeyStepTitle} from "@/lib/journey";
import {CIVIQUE_EXAM_QUESTIONS, CIVIQUE_EXAM_SEUIL} from "@/lib/civique-examen";
import {CIVIC_PLAN_PREMIUM_BENEFITS, CIVIC_PLAN_PREMIUM_TEXT, PlanPaywall} from "./PlanPaywallCard";

/**
 * **Le plan civique** (L10) — refonte du 2026-09-11 sur le kit `sejour/`.
 *
 * 🛑 **Rien n'est dérivé ici.** L'ordre des cibles, leur état de maîtrise, leur
 * échéance et leur verrou arrivent **servis**. Ce panneau les met en mots
 * (`lib/civic-plan.ts`) et ouvre ce qui existe déjà — la série ciblée.
 *
 * 🛑 **La boîte Leitner ne s'affiche JAMAIS** au candidat : on montre
 * `maitrise` et `prochaineRevue`.
 *
 * 🛑 **Le plan travaille au grain que le tagging permet, et il le DIT**
 * (`grain.courant`) : thème par thème tant que les questions ne sont pas
 * taguées, notion par notion ensuite. Le code lit le grain servi, il ne présume
 * pas la notion.
 *
 * 🛑 **Le constat est intégralement gratuit.** `locked` porte sur la **série**,
 * jamais sur ce que le candidat a mesuré.
 *
 * ## Le palier desktop (2026-09-12)
 *
 * Mise en page de `grok_ecran/screenshots/civ-plan-web.png` et de
 * `screens/civique-plan.tsx` : **abonné** en `deskPair` « À faire maintenant » |
 * « Votre parcours », priorités en `deskGrid`, puis `deskPair` « Déjà travaillé
 * et validé » | « À revoir bientôt », « Progression détectée » en pleine
 * largeur. **Gratuit** : aucune paire — seules les priorités passent en grille,
 * pour que « Débloquer mon plan » reste la seule action dominante.
 * 🛑 Aucun composant nouveau, seulement deux classes de grille du kit, inertes
 * sous 960 px.
 */
export function CivicPlanPanel() {
  const {user} = useAuth();
  const [plan, setPlan] = useState<CivicPlanDto | null>(null);
  /* 🛑 **Le CYCLE civique** (D-50) : c'est lui qui porte « À faire maintenant »
     et les blocs. `null` est un cas normal — pas encore lu. */
  const [journey, setJourney] = useState<JourneyDto | null>(null);
  /* 🛑 Le geste vit dans `useCivicSerie`, partagé avec l'écran Réviser : la
     même cible ne peut pas s'ouvrir de deux façons selon l'écran. */
  const {enCours, erreur, paywall, setPaywall, commencer} = useCivicSerie();

  useEffect(() => {
    let vivant = true;
    civicPlanApi.getCached().then(
      (p) => { if (vivant) setPlan(p); },
      () => { /* best-effort : jamais une erreur technique à la place d'un plan */ },
    );
    journeyApi.getCached("CIVIQUE").then(
      (j) => { if (vivant) setJourney(j); },
      () => { /* idem : le cycle absent fait disparaître sa section, pas l'écran */ },
    );
    return () => { vivant = false; };
  }, []);


  /* 🛑 **La bascule de parcours ne se fait jamais attendre.** C'est l'en-tête
     qui la porte (`TopSlot`), donc on le rend dès le premier passage, avant le
     plan : rendre `null` ici laissait l'écran sans aucune porte vers le TCF
     tant que `/api/me/civic-plan` n'avait pas répondu. Même état que le
     chargement du plan TCF, qui rend déjà son `Top` seul. */
  if (!plan) {
    return (
      <Top kicker="Votre préparation personnalisée à l'Examen civique" title="Mon plan du jour" />
    );
  }

  if (!plan.disponible) {
    return (
      <PlanGate
        kicker="Votre préparation personnalisée à l'Examen civique"
        gate={planIndisponibleDepuisEtat("DIAGNOSTIC_A_FAIRE", "CIVIQUE")}
        icon={Landmark}
      />
    );
  }

  const premium = canAccessModule(user, "CIVIQUE");
  return (
    <>
      {premium
        ? <CiviquePremium plan={plan} journey={journey} enCours={enCours}
                          onStart={commencer} erreur={erreur} />
        : <CiviqueGratuit plan={plan} enCours={enCours} onStart={commencer} erreur={erreur} />}
      <PaywallSheet origin="plan" open={paywall} module="CIVIQUE" onClose={() => setPaywall(false)} />
    </>
  );
}

interface PanelProps {
  plan: CivicPlanDto;
  journey?: JourneyDto | null;
  enCours: string | null;
  onStart: (cible: CivicPlanCibleDto) => void;
  erreur: string | null;
}

/* ----------------------------------------------------------------- abonné */

function CiviquePremium({plan, journey, enCours, onStart, erreur}: PanelProps) {
  const maintenant = useMemo(() => new Date(), []);

  /* ⚠️ CE PANNEAU A ÉTÉ REFONDU (P8.7, D-50, 2026-09-20).
     Il portait huit sections ; quatre d'entre elles n'étaient pas des « en
     plus » mais des RETARDS — le TCF les a retirées les 18 et 19 septembre,
     au motif qu'elles redisaient les blocs du cycle en moins précis et sous un
     plafond d'affichage.

     Ce qui PART : « Vos priorités », « Déjà travaillé et validé »,
     « Progression détectée », et la carte de contexte (deux pastilles) — la
     bande objectif la remplace. Le « parcours de la notion » part AVEC elles :
     il illustrait la cible du plan dérivé, et la carte d'action ne la nomme
     plus (voir ci-dessous).

     Ce qui RESTE : « À revoir bientôt ». C'est le seul affichage du Leitner,
     que le cycle ne porte pas — D-49 a posé deux autorités exactement pour ça,
     et la supprimer perdrait un fait vrai. */
  return (
    <>
      <Top kicker="Votre préparation personnalisée à l'Examen civique" title="Mon plan du jour" />

      {/* 🛑 LA BANDE OBJECTIF (D-50 §1) : la démarche visée et le seuil, deux
          FAITS du référentiel. ⛔ **Jamais un score d'entrée** — il se lirait
          comme un niveau acquis alors que c'est un résultat d'examen blanc. */}
      {journey?.objectif && (
        <Pad>
          <GoalStrip
            currentLabel="Objectif"
            current={journey.objectif.label}
            goalLabel="Seuil de réussite"
            goal={`${CIVIQUE_EXAM_SEUIL}/${CIVIQUE_EXAM_QUESTIONS}`}
          />
        </Pad>
      )}

      {erreur && (
        <Pad>
          <p className={sejourStyles.tiny} role="alert">{erreur}</p>
        </Pad>
      )}

      {/* 🛑 « À FAIRE MAINTENANT » VIENT DU CYCLE (D-50 §2), plus du plan
          dérivé. Une seule réponse alimente la carte et la timeline — c'est ce
          qui a supprimé, le 2026-09-16, la contradiction où l'Accueil annonçait
          une action et le Plan une autre au même instant. */}
      <CivicActionMaintenant journey={journey} />

      {/* Le cycle en blocs — la MÊME section que le TCF, module en paramètre. */}
      <PlanCycleSection journey={journey ?? null} plan={null} module="CIVIQUE" />

      {/* 🛑 Secondaire, et JAMAIS présenté comme une alerte : ce sont des points
          acquis qu'on entretient. La **boîte** Leitner ne s'affiche pas — on
          montre l'état de maîtrise et l'échéance, tous deux servis. */}
      {plan.aRevoirVisibles.length > 0 && (
        <Section title={CIVIC_PLAN_REVIEW_TITLE} flush>
          <Card variant="soft">
            <p className={sejourStyles.label}>Révision courte</p>
            <Stack>
              {plan.aRevoirVisibles.map((cible) => (
                <div key={cible.id}>
                  <b>{cible.label}</b>
                  <p className={sejourStyles.tiny}>
                    {CIVIC_MAITRISE_LABEL[cible.maitrise]}
                    {civicRevueLabel(cible, maintenant)
                      ? ` · ${civicRevueLabel(cible, maintenant)}`
                      : ""}
                  </p>
                  <button
                    type="button"
                    className={sejourStyles.link}
                    disabled={enCours === cible.id}
                    onClick={() => onStart(cible)}
                  >
                    {CIVIC_PLAN_WORK_CTA}
                  </button>
                </div>
              ))}
            </Stack>
          </Card>
        </Section>
      )}
    </>
  );
}

/**
 * **« À faire maintenant », depuis le CYCLE** (D-50 §2).
 *
 * 🛑 **L'étape courante est SERVIE** (`journey.current`) : l'écran ne choisit
 * pas quoi faire ensuite, il l'affiche. Son geste est la série sur l'**unité**
 * de l'étape, quand elle en porte une — un examen de bloc, lui, se lance depuis
 * son encart dans le cycle.
 *
 * 🛑 `null` est un cas NORMAL : cycle terminé, plus rien à faire, ou rien
 * d'exécutable. La carte disparaît, elle n'affiche jamais un squelette.
 */
function CivicActionMaintenant({journey}: {journey?: JourneyDto | null}) {
  const serie = useCivicUniteSerie();
  const etape = journey?.current ?? null;
  if (!etape) return null;

  const unite = etape.unite;
  const sousTitre = journeyStepSubtitle(etape);
  return (
    <>
      <Section title={CIVIC_PLAN_NOW_TITLE}>
        <Pad>
          <NowCard
            icon={Landmark}
            title={journeyStepTitle(etape)}
            subtitle={etape.bloc?.label}
            badge={etape.locked ? JOURNEY_LOCKED_BADGE : undefined}
            /* `journeyStepSubtitle` peut ne rien avoir à dire : on n'affiche
               alors aucune méta plutôt qu'une ligne vide. */
            meta={sousTitre ? [{icon: ListChecks, label: sousTitre}] : undefined}
          >
            {/* 🛑 Un geste seulement quand il y en a un : une étape verrouillée
                ou un examen de bloc n'ouvre rien ICI. C'est le garde-fou du
                2026-09-17 — rien ne se résout ⇒ aucun bouton. */}
            {unite && !etape.locked && (
              <Cta onClick={() => void serie.start(unite.code)}>
                {serie.enCours === unite.code ? "Ouverture…" : CIVIC_PLAN_WORK_CTA}
              </Cta>
            )}
          </NowCard>
          {serie.erreur && (
            <p className={sejourStyles.tiny} role="alert">{serie.erreur}</p>
          )}
        </Pad>
      </Section>
      <PaywallSheet
        origin="plan"
        open={serie.paywall}
        module="CIVIQUE"
        onClose={() => serie.setPaywall(false)}
      />
    </>
  );
}

/* ---------------------------------------------------------------- gratuit */

function CiviqueGratuit({plan, enCours, onStart, erreur}: PanelProps) {
  const themes = useMemo(() => themesATravailler(plan), [plan]);
  const grainNote = civicPlanGrainNote(plan.grain);

  return (
    <>
      <Top kicker="Créé à partir de votre diagnostic" title="Mon plan du jour" />

      {plan.resultat && (
        <Pad>
          <Card variant="hero">
            <p className={sejourStyles.label}>{CIVIC_PLAN_RESULT_TITLE}</p>
            <p className={cx(sejourStyles.score, sejourStyles.scoreMd)}>
              {plan.resultat.bonnes} <small>/ {plan.resultat.posees}</small>
            </p>
            <p className={sejourStyles.tiny}>
              {CIVIC_PLAN_RESULT_SEUIL} : {plan.resultat.seuil} / {plan.resultat.format}
            </p>
          </Card>
        </Pad>
      )}

      {themes.length > 0 && (
        <Section title="Thèmes à travailler">
          <Pad>
            <Card padding="tight">
              {themes.map((theme) => (
                <ThemeLine
                  key={theme.code}
                  tone={theme.tone}
                  name={theme.label}
                  status={CIVIC_THEME_STATE_LABEL[theme.etat]}
                />
              ))}
            </Card>
          </Pad>
        </Section>
      )}

      {plan.prioritesVisibles.length > 0 && (
        <Section title={CIVIC_PLAN_PRIORITIES_TITLE}>
          <Pad>
            <Stack className={sejourStyles.deskGrid}>
              {plan.prioritesVisibles.slice(0, 3).map((cible, index) => (
                <Prio
                  key={cible.id}
                  rank={index === 0 ? 1 : index === 1 ? 2 : 3}
                  tag={cible.themeLabel}
                  title={cible.label}
                  text={CIVIC_MAITRISE_LABEL[cible.maitrise]}
                />
              ))}
            </Stack>
          </Pad>
        </Section>
      )}

      {erreur && (
        <Pad>
          <p className={sejourStyles.tiny} role="alert">{erreur}</p>
        </Pad>
      )}

      {plan.prochaine && (
        <Section title="Votre première étape est prête">
          <Pad>
            <CivicNowCard
              cible={plan.prochaine}
              busy={enCours === plan.prochaine.id}
              onStart={() => onStart(plan.prochaine!)}
            />
          </Pad>
        </Section>
      )}

      {grainNote && <p className={sejourStyles.footNote}>{grainNote}</p>}

      <PlanPaywall
        module="CIVIQUE"
        benefits={CIVIC_PLAN_PREMIUM_BENEFITS}
        text={CIVIC_PLAN_PREMIUM_TEXT}
        cta="Débloquer mon plan"
      />
    </>
  );
}

/* ------------------------------------------------------------- une cible */

/**
 * « À faire maintenant ».
 *
 * 🛑 **Aucun « objectif de cette séance »** : le serveur n'en sert aucun et on
 * n'en fabrique pas. Ce que l'encart annonce, c'est ce que le plan a
 * **observé** — état de maîtrise servi et raison composée de faits.
 *
 * 🛑 Le verrou se **lit** (`locked`) : verrouillée, la cible garde son nom et
 * son état — c'est la **série** qui est fermée, pas le constat.
 */
function CivicNowCard({cible, badge, busy, onStart}: {
  cible: CivicPlanCibleDto;
  badge?: string;
  busy: boolean;
  onStart: () => void;
}) {
  const sousTitre = cible.label === cible.themeLabel ? undefined : cible.themeLabel;
  return (
    <>
      <NowCard
        icon={Landmark}
        title={cible.label}
        subtitle={sousTitre}
        badge={badge}
        objectiveLabel="Ce que le plan a observé"
        objective={`${CIVIC_MAITRISE_LABEL[cible.maitrise]} · ${civicPlanRaison(cible)}`}
        meta={[{icon: ListChecks, label: civicSerieLabel(cible)}]}
      >
        {cible.locked ? (
          <LockList>
            <LockItem icon={Lock} label="Questions ciblées" />
            <LockItem icon={Lock} label="Explications de vos erreurs" />
            <LockItem icon={Lock} label="Suivi de maîtrise" />
            <LockItem icon={Lock} label="Révisions au bon moment" />
          </LockList>
        ) : (
          <Cta variant="blue" onClick={onStart} disabled={busy}>
            {CIVIC_PLAN_NOW_CTA}
          </Cta>
        )}
      </NowCard>
      {cible.locked && <p className={sejourStyles.tiny}>{CIVIC_PLAN_LOCKED_NOTE}</p>}
    </>
  );
}

/* --------------------------------------------------------------- lecture */

/**
 * Les thèmes que le plan désigne, **dans l'ordre servi**, avec l'état que le
 * serveur porte sur chaque cible (`etatDuTheme`).
 *
 * 🛑 On ne reconstruit pas les cinq thèmes du référentiel : le plan civique
 * n'en sert pas la liste, et l'inventer serait affirmer un état sur un thème
 * dont il ne dit rien. `SOLIDE` sort de « à travailler » — il n'y a rien à y
 * faire.
 */
function themesATravailler(plan: CivicPlanDto) {
  const vus = new Map<string, {code: string; label: string; etat: CivicThemeState; tone: Tone}>();
  for (const cible of [...plan.prioritesVisibles, ...plan.aRevoirVisibles, ...plan.solides]) {
    if (cible.etatDuTheme === "SOLIDE") continue;
    if (vus.has(cible.themeCode)) continue;
    vus.set(cible.themeCode, {
      code: cible.themeCode,
      label: cible.themeLabel,
      etat: cible.etatDuTheme,
      tone: themeTone(cible.etatDuTheme),
    });
  }
  return [...vus.values()];
}

/** 🛑 `NON_EVALUE` n'a **pas** de ton d'alerte : c'est une absence de mesure,
 *  pas un échec — et son libellé servi le dit. */
function themeTone(etat: CivicThemeState): Tone {
  if (etat === "FAIBLE") return "hot";
  if (etat === "SOLIDE") return "ok";
  if (etat === "NON_EVALUE") return "muted";
  return "warn";
}
