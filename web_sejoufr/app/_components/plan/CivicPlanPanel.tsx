"use client";

import {useCallback, useEffect, useMemo, useState} from "react";
import {useRouter} from "next/navigation";
import {Landmark, ListChecks, Lock} from "lucide-react";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {civicPlanApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
  CIVIC_PLAN_LOCKED_CTA,
  CIVIC_PLAN_LOCKED_NOTE,
  CIVIC_PLAN_NOW_CTA,
  CIVIC_PLAN_NOW_TITLE,
  CIVIC_PLAN_PRIORITIES_TITLE,
  CIVIC_PLAN_RESULT_SEUIL,
  CIVIC_PLAN_RESULT_TITLE,
  CIVIC_PLAN_REVIEW_TITLE,
  CIVIC_PLAN_WORK_CTA,
  civicPlanAutresLabel,
  civicPlanGrainNote,
  civicPlanRaison,
  civicRevueLabel,
  civicSerieLabel,
    CIVIC_PATH_LABELS,
    CIVIC_CHANGES_TITLE,
    CIVIC_PATH_TITLE,
    civicChangesWindowLabel,
    civicNextStepLabel,
    civicTransitionLabel,
    civicPath,
    civicPathCounter,
} from "@/lib/civic-plan";
import {planIndisponibleDepuisEtat} from "@/lib/preparation";
import {handleStartFailure} from "@/lib/start-failure";
import {
  canAccessModule,
  CIVIC_MAITRISE_LABEL,
  CIVIC_THEME_STATE_LABEL,
  type CivicPlanCibleDto,
  type CivicPlanDto,
  type CivicThemeState,
} from "@/lib/types";
import {
  Card,
  Cta,
  DoneRow,
  LockItem,
  LockList,
  NowCard,
  Pad,
  PillMeta,
  Pills,
  Prio,
  Section,
  Stack,
  ThemeLine,
  Top,
  cx,
  sejourStyles,
  type Tone,
  PathCard,
} from "@/app/_components/sejour/SejourKit";
import {PlanGate} from "./PlanGate";
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
  const router = useRouter();
  const [plan, setPlan] = useState<CivicPlanDto | null>(null);
  const [erreur, setErreur] = useState<string | null>(null);
  const [enCours, setEnCours] = useState<string | null>(null);
  const [paywall, setPaywall] = useState(false);

  useEffect(() => {
    let vivant = true;
    civicPlanApi.get().then(
      (p) => { if (vivant) setPlan(p); },
      () => { /* best-effort : jamais une erreur technique à la place d'un plan */ },
    );
    return () => { vivant = false; };
  }, []);

  /**
   * Ouvre la série ciblée. 🛑 Le **403** est un refus attendu — le verrou du
   * serveur et le `locked` servi sont la même règle — et il ouvre l'offre,
   * jamais un message d'erreur technique.
   */
  const commencer = useCallback(
    async (cible: CivicPlanCibleDto) => {
      if (enCours) return;
      if (cible.locked) {
        setPaywall(true);
        return;
      }
      setEnCours(cible.id);
      setErreur(null);
      try {
        const attempt = await civicPlanApi.serie(cible.id, cible.grain);
        router.push(`/sessions/${attempt.id}`);
      } catch (e) {
        handleStartFailure(e, {
          onPaywall: () => setPaywall(true),
          onMessage: setErreur,
          fallbackMessage: "Impossible de démarrer cette série.",
        });
        setEnCours(null);
      }
    },
    [enCours, router],
  );

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
        ? <CiviquePremium plan={plan} enCours={enCours} onStart={commencer} erreur={erreur} />
        : <CiviqueGratuit plan={plan} enCours={enCours} onStart={commencer} erreur={erreur} />}
      <PaywallSheet open={paywall} module="CIVIQUE" onClose={() => setPaywall(false)} />
    </>
  );
}

interface PanelProps {
  plan: CivicPlanDto;
  enCours: string | null;
  onStart: (cible: CivicPlanCibleDto) => void;
  erreur: string | null;
}

/* ----------------------------------------------------------------- abonné */

function CiviquePremium({plan, enCours, onStart, erreur}: PanelProps) {
  const grain = grainWord(plan);
  const aConsolider = plan.priorites.length + plan.autresPriorites;
  const grainNote = civicPlanGrainNote(plan.grain);
  const autres = civicPlanAutresLabel(plan);
  const maintenant = useMemo(() => new Date(), []);

  return (
    <>
      <Top kicker="Votre préparation personnalisée à l'Examen civique" title="Mon plan du jour" />

      <Pad>
        <Card>
          <Pills>
            <PillMeta>{aConsolider} {grain.pluriel} à consolider</PillMeta>
            {plan.aRevoir.length > 0 && (
              <PillMeta>{plan.aRevoir.length} à revoir bientôt</PillMeta>
            )}
          </Pills>
          <p className={sejourStyles.tiny}>
            Le plan choisit {grain.leProchain} selon vos résultats, puis réévalue après chaque
            séance.
          </p>
        </Card>
      </Pad>

      {erreur && (
        <Pad>
          <p className={sejourStyles.tiny} role="alert">{erreur}</p>
        </Pad>
      )}

      {/* La paire de tête de `civique-plan.tsx` : l'action du jour et le
          parcours de la notion. Un seul des deux ⇒ il prend la rangée entière
          (règle du kit, `:only-child`). */}
      <div className={sejourStyles.deskPair}>
        {plan.prochaine && (
          <Section title={CIVIC_PLAN_NOW_TITLE}>
            <Pad>
              <CivicNowCard
                cible={plan.prochaine}
                badge="Priorité n°1"
                busy={enCours === plan.prochaine.id}
                onStart={() => onStart(plan.prochaine!)}
              />
            </Pad>
          </Section>
        )}

        {/* Le parcours de la notion en cours — c'est ICI que l'effet Leitner
            devient visible : ce que le candidat a franchi, où il en est, et ce
            qu'il reste avant que la notion soit tenue. */}
        {plan.prochaine && plan.prochaine.parcours.length > 0 && (
          <Section title={`${CIVIC_PATH_TITLE} — ${plan.prochaine.label}`} flush>
            <PathCard
              // Aucune étape en cours = la notion est tenue : on nomme la
              // dernière plutôt que de laisser l'en-tête vide.
              currentLabel={
                civicPath(plan.prochaine).find((e) => e.state === "now")?.label
                ?? CIVIC_PATH_LABELS[CIVIC_PATH_LABELS.length - 1]
              }
              counterLabel={civicPathCounter(plan.prochaine)}
              steps={civicPath(plan.prochaine)}
            />
          </Section>
        )}
      </div>

      {plan.priorites.length > 0 && (
        <Section title={CIVIC_PLAN_PRIORITIES_TITLE}>
          <Pad>
            <Stack className={sejourStyles.deskGrid}>
              {plan.priorites.slice(0, 3).map((cible, index) => (
                <Prio
                  key={cible.id}
                  rank={index === 0 ? 1 : index === 1 ? 2 : 3}
                  tag={cible.themeLabel}
                  title={cible.label}
                  text={`${CIVIC_MAITRISE_LABEL[cible.maitrise]} · ${civicPlanRaison(cible)}`}
                >
                  <button
                    type="button"
                    className={sejourStyles.link}
                    disabled={enCours === cible.id}
                    onClick={() => onStart(cible)}
                  >
                    {cible.locked ? CIVIC_PLAN_LOCKED_CTA : CIVIC_PLAN_WORK_CTA}
                  </button>
                </Prio>
              ))}
            </Stack>
            {autres && <p className={sejourStyles.tiny}>{autres}</p>}
          </Pad>
        </Section>
      )}

      {/* La seconde paire de la maquette : l'acquis et l'entretien. */}
      <div className={sejourStyles.deskPair}>
        {plan.solides.length > 0 && (
          <Section title="Déjà travaillé et validé">
            <Pad>
              <Card padding="rows">
                {plan.solides.map((cible) => (
                  <DoneRow
                    key={cible.id}
                    label={`${cible.label} — ${CIVIC_MAITRISE_LABEL[cible.maitrise]}`}
                  />
                ))}
              </Card>
            </Pad>
          </Section>
        )}

        {/* 🛑 Secondaire, et JAMAIS présenté comme une alerte : ce sont des points
            acquis qu'on entretient. La **boîte** Leitner ne s'affiche pas — on
            montre l'état de maîtrise et l'échéance, tous deux servis. */}
        {plan.aRevoir.length > 0 && (
          <Section title={CIVIC_PLAN_REVIEW_TITLE} flush>
            <Card variant="soft">
              <p className={sejourStyles.label}>Révision courte</p>
              <Stack>
                {plan.aRevoir.map((cible) => (
                  <div key={cible.id}>
                    <b>{cible.label}</b>
                    <p className={sejourStyles.tiny}>
                      {CIVIC_MAITRISE_LABEL[cible.maitrise]}
                      {civicRevueLabel(cible, maintenant)
                        ? ` · ${civicRevueLabel(cible, maintenant)}`
                        : ""}
                    </p>
                  </div>
                ))}
              </Stack>
            </Card>
          </Section>
        )}
      </div>

      {/* 🛑 `changements === null` est le cas NORMAL : le bloc DISPARAÎT, il ne
          s'affiche jamais vide. C'est le seul endroit où le candidat voit son
          plan bouger — l'user d'un « rien n'a changé » le rendrait invisible. */}
      {plan.changements && (
        <Section title={CIVIC_CHANGES_TITLE} flush>
          <Card variant="ok">
            <p className={sejourStyles.label}>
              {civicChangesWindowLabel(plan.changements)}
            </p>
            {plan.changements.transitions.map((t) => (
              <DoneRow key={t.cibleId} label={civicTransitionLabel(t)} />
            ))}
            {plan.changements.nouvellePriorite && (
              <p className={sejourStyles.insight}>
                {civicNextStepLabel(plan.changements.nouvellePriorite)}
              </p>
            )}
          </Card>
        </Section>
      )}

      {grainNote && <p className={sejourStyles.footNote}>{grainNote}</p>}
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

      {plan.priorites.length > 0 && (
        <Section title={CIVIC_PLAN_PRIORITIES_TITLE}>
          <Pad>
            <Stack className={sejourStyles.deskGrid}>
              {plan.priorites.slice(0, 3).map((cible, index) => (
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
  for (const cible of [...plan.priorites, ...plan.aRevoir, ...plan.solides]) {
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

/** Le mot du grain, **lu** sur `grain.courant` : le plan ne se présente jamais
 *  plus précis qu'il ne l'est. */
function grainWord(plan: CivicPlanDto) {
  return plan.grain.courant === "NOTION"
    ? {pluriel: "notions", leProchain: "la prochaine notion"}
    : {pluriel: "thèmes", leProchain: "le prochain thème"};
}
