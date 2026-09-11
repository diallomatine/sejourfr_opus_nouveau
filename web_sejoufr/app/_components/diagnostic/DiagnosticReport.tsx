"use client";

/**
 * **Le résultat du diagnostic RAPIDE TCF.**
 *
 * Une seule production écrite a été observée : l'écran annonce une
 * *estimation*, dit ce qu'il a vu, dit **ce qu'il n'a pas vu**, et conduit au
 * diagnostic complet. Il ne pousse aucun abonnement — le candidat n'a pas
 * encore ses quatre niveaux sous les yeux, et un plan vendu sur un seul écrit
 * serait vendu à l'aveugle.
 *
 * 🛑 **Aucun style local.** Tout l'habillage vient du kit partagé
 * `app/_components/sejour/` (miroir du kit Flutter). Un motif qui manque
 * s'ajoute là-bas, jamais ici.
 *
 * 🛑 **`null` = inconnu, jamais mauvais.** Une production inexploitable
 * (`NON_EVALUABLE`) n'a pas de niveau : on écrit « — » et on dit ce qui manque.
 * Afficher A1 serait rendre un verdict que personne n'a rendu (V040/V041/V042).
 */

import type {ReactNode} from "react";
import {ArrowUp, BookOpen, Check, Headphones, Info, Mic, PenLine} from "lucide-react";
import {
  Card,
  CheckList,
  Cta,
  ExamRow,
  LevelTrack,
  NoteCard,
  Observation,
  Pad,
  SejourApp,
  Section,
  Stack,
  Top,
  sejourStyles as styles,
} from "@/app/_components/sejour/SejourKit";
import {TCF_DIAGNOSTIC_HUB_HREF, levelTrackPosition} from "@/lib/tcf-diagnostic";
import {niveauCecrlShort, type DiagnosticResultDto} from "@/lib/types";

/* ------------------------------------------------------------- les libellés */

const BACK_HREF = "/dashboard";
const TOP_KICKER = "Diagnostic rapide terminé";
const TOP_TITLE = "Votre estimation";

/**
 * 🛑 **Wording imposé** : « Niveau estimé **sur cet exercice** », jamais « votre
 * niveau TCF ». Trois épreuves sur quatre n'ont pas été mesurées.
 */
const HERO_LABEL = "Niveau estimé sur cet exercice";
const HERO_GOAL = "Votre objectif :";
/** 🛑 L'objectif est **nullable** : aucun front n'invente « B2 » pour un
 *  candidat qui n'a déclaré ni démarche ni palier. */
const OBJECTIVE_UNKNOWN = "à définir";
/** Ce qu'on affiche à la place d'un niveau qui n'existe pas. */
const LEVEL_UNKNOWN = "—";

/** 🛑 « Rendue, rien à observer » ≠ « faible ». La phrase ne juge pas la
 *  production : elle dit ce qui manque pour conclure. */
const INCOMPLETE_TEXT =
  "Nous n'avons pas reçu suffisamment de contenu pour estimer votre niveau."
  + " Une nouvelle production de deux minutes suffit.";

const OBSERVE_TITLE = "Ce que nous avons observé";
const OBSERVE_POSITIVE = "Positive";
const OBSERVE_AMELIORER = "À améliorer";
/** Plafond d'AFFICHAGE, arbitré produit : deux points à améliorer, pas une
 *  liste. Le serveur en sert jusqu'à trois ; on n'en montre que deux. */
const OBSERVE_MAX_AMELIORER = 2;

const TRANSITION_TITLE = "Ce n'est qu'une première estimation";
const TRANSITION_TEXT =
  "Cet exercice analyse votre manière de vous exprimer à l'écrit. "
  + "Au TCF, votre niveau dépend aussi de votre expression orale, de votre "
  + "compréhension orale et de votre compréhension écrite.";
const TRANSITION_EMPHASIS = "Votre niveau peut donc être différent selon les épreuves.";

const COMPLET_TITLE = "Découvrez où vous en êtes vraiment au TCF";
const COMPLET_EPREUVES = [
  {icon: Headphones, label: "Compréhension orale"},
  {icon: BookOpen, label: "Compréhension écrite"},
  {icon: PenLine, label: "Expression écrite"},
  {icon: Mic, label: "Expression orale"},
] as const;
const COMPLET_PROMISE = "À la fin, vous connaîtrez :";
const COMPLET_BENEFITS = [
  "votre niveau par épreuve",
  "les tâches qui vous limitent actuellement",
  "vos priorités pour atteindre votre objectif",
];
const COMPLET_CTA = "Faire mon diagnostic complet";
const COMPLET_NOTE = "Examen blanc complet dans les conditions du TCF.";

/* ------------------------------------------------------ les trois observations */

interface ObservationLine {
  tone: "ok" | "up";
  kicker: string;
  title: string;
  text: string | null;
}

/**
 * Une ligne positive, puis deux à améliorer — dans cet ordre.
 *
 * 🛑 **Rien n'est dérivé.** Le point fort est une observation que le serveur a
 * marquée `SOLID` ; les points à améliorer sont les priorités qu'il a classées.
 * Le front choisit dans une liste servie, il ne juge pas.
 *
 * ⚠️ Le repli sur `strengths` existe parce que le serveur sert deux formes du
 * même fait : des observations nommées (titre + explication) et, quand il n'en
 * a aucune, des phrases nues. On n'invente pas de ligne pour remplir le bloc —
 * ni l'une ni l'autre ⇒ pas de ligne positive.
 */
function observationLines(result: DiagnosticResultDto | null): ObservationLine[] {
  const solide = (result?.written?.skills ?? []).find(
    (skill) => skill.observed && skill.status === "SOLID",
  );
  const positive: ObservationLine[] = solide
    ? [{tone: "ok", kicker: OBSERVE_POSITIVE, title: solide.skillTitle, text: solide.explanation}]
    : (result?.strengths ?? [])
        .slice(0, 1)
        .map((phrase) => ({tone: "ok" as const, kicker: OBSERVE_POSITIVE, title: phrase, text: null}));

  return [
    ...positive,
    ...(result?.priorities ?? []).slice(0, OBSERVE_MAX_AMELIORER).map((skill) => ({
      tone: "up" as const,
      kicker: OBSERVE_AMELIORER,
      title: skill.skillTitle,
      text: skill.explanation,
    })),
  ];
}

/* ------------------------------------------------------------------- écran */

export function DiagnosticReport({
  diagnostic,
  targetLevel,
  notice,
}: {
  diagnostic: {result: DiagnosticResultDto | null};
  /** Palier visé, servi par `/api/auth/me`. `null` = démarche non déclarée. */
  targetLevel: string | null;
  notice?: ReactNode;
}) {
  const result = diagnostic.result;
  const written = result?.written ?? null;
  // 🛑 Seule la valeur `NON_EVALUABLE` **explicite** se lit « rendue, rien à
  // observer » : l'absence du champ, elle, ne veut rien dire (backend ancien).
  const inexploitable = written?.evaluabilite === "NON_EVALUABLE";
  const niveau = written?.levelEstimate ?? null;
  const analyse = inexploitable ? INCOMPLETE_TEXT : written?.summary ?? null;
  const track = levelTrackPosition(niveau, targetLevel);
  const observations = observationLines(result);

  return (
    <SejourApp>
      {notice}
      <Top backTo={BACK_HREF} kicker={TOP_KICKER} title={TOP_TITLE} />

      {/* 1 — le niveau. L'élément dominant de l'écran. */}
      <Pad>
        <Card variant="hero">
          <p className={styles.label}>{HERO_LABEL}</p>
          <p className={styles.level}>{niveau ? niveauCecrlShort(niveau) : LEVEL_UNKNOWN}</p>
          <p className={styles.goalLine}>
            {HERO_GOAL} <span>{targetLevel ?? OBJECTIVE_UNKNOWN}</span>
          </p>
          {/* Piste absente quand un palier sort de l'échelle affichée : mieux
              vaut rien qu'un candidat rabattu sur un palier qui n'est pas le sien. */}
          {track && (
            <LevelTrack
              levels={[...track.levels]}
              currentIndex={track.currentIndex}
              goalIndex={track.goalIndex}
            />
          )}
          {analyse && <p className={styles.insight}>{analyse}</p>}
        </Card>
      </Pad>

      {/* 2 — ce que nous avons observé. Absent quand le serveur n'a rien
          classé : un bloc vide ne se remplit pas. */}
      {observations.length > 0 && (
        <Section title={OBSERVE_TITLE}>
          <Pad>
            <Stack>
              {observations.map((line) => (
                <Observation
                  key={`${line.kicker}-${line.title}`}
                  tone={line.tone}
                  kicker={line.kicker}
                  title={line.title}
                  text={line.text ?? undefined}
                  icon={line.tone === "ok" ? Check : ArrowUp}
                />
              ))}
            </Stack>
          </Pad>
        </Section>
      )}

      {/* 3 — la transition. Ce n'est pas décoratif, c'est une obligation
          d'honnêteté : le diagnostic rapide n'observe qu'un écrit. */}
      <Section>
        <Pad>
          <NoteCard variant="soft" icon={Info} title={TRANSITION_TITLE}>
            <p className={styles.insight}>{TRANSITION_TEXT}</p>
            <span className={styles.emphasis}>{TRANSITION_EMPHASIS}</span>
          </NoteCard>
        </Pad>
      </Section>

      {/* 4 — le diagnostic complet, seule suite proposée par cet écran. */}
      <Section title={COMPLET_TITLE}>
        <Pad>
          <Stack>
            {COMPLET_EPREUVES.map((epreuve) => (
              <ExamRow key={epreuve.label} icon={epreuve.icon} title={epreuve.label} />
            ))}
            <Card>
              <p className={styles.label}>{COMPLET_PROMISE}</p>
              <CheckList items={COMPLET_BENEFITS} />
            </Card>
            <Cta href={TCF_DIAGNOSTIC_HUB_HREF} caption={COMPLET_NOTE}>
              {COMPLET_CTA}
            </Cta>
          </Stack>
        </Pad>
      </Section>
    </SejourApp>
  );
}
