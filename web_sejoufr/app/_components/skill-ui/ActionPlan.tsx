"use client";

import {Fragment} from "react";
import {ArrowRight, Bookmark, Sparkles, Zap} from "lucide-react";
import type {
  ActionPlanExempleCible,
  ActionPlanLevier,
  ActionPlanMemo,
  ActionPlanReformulation,
  ActionPlanSegment,
} from "@/lib/types";
import s from "./skill.module.css";

/* ---------------------------------------------------------------------------
 * Le plan d'action « pour viser X » — briques PARTAGÉES.
 *
 * Le micro-exercice de compétence et la production complète EE/EO sortent du
 * même second appel LLM et rendent le même plan : leviers, version plus aboutie
 * (ou reformulations à l'oral), tournure à retenir. Ces blocs vivaient dans
 * `competences/` ; ils ont été **promus** ici à leur deuxième consommateur
 * plutôt que recopiés — deux copies auraient divergé au premier retouche, et
 * c'est exactement ce que la règle de duplication du dépôt interdit.
 *
 * ⚠️ **Corps seulement, pas d'intertitre.** Chaque écran rend le sien avec son
 * propre gabarit de titre (`skill.module.css` côté compétences,
 * `production.module.css` dans le rapport de correction) : deux typographies de
 * titre empilées dans un même écran se lisent comme un bug. Les libellés, eux,
 * sont ci-dessous — ils sont gelés et communs aux deux surfaces.
 * ------------------------------------------------------------------------- */

/**
 * Intertitre des leviers d'une **production complète**. Il garde le palier :
 * c'est l'objectif du candidat, pas une affirmation sur un texte — donc il est
 * exact, contrairement à un titre qui étiquetterait un modèle d'un niveau que
 * rien ne vérifie.
 */
export function pourViserTitle(niveauVise: string): string {
  return `Pour viser ${niveauVise}`;
}

/**
 * Intertitre des leviers d'un **micro-exercice de compétence**.
 *
 * Depuis le contrat v2 de `competence-niveau-vise`, `niveauVise` n'y porte plus
 * l'objectif lointain du candidat mais le **palier cible** : la marche suivante
 * (`niveau constaté + 1`, plafonnée à son objectif), que le texte modèle doit
 * réellement démontrer — bornes de longueur du sujet appliquées, marqueurs de
 * palier recopiés du texte et vérifiés serveur. Le titre le nomme donc tel
 * quel : annoncer « Pour viser B2 » sur un texte qui vaut B1 est exactement le
 * défaut mesuré (un candidat a recopié ce modèle, l'a resoumis, et a été
 * réévalué A2).
 *
 * ⚠️ Formulation **positive**, règle gelée du dépôt : on nomme la marche
 * atteignable, jamais un manque (« presque B1 » est banni).
 *
 * Miroir mobile : `pourPasserAuTitle` (`widgets/action_plan.dart`).
 */
export function pourPasserAuTitle(palierCible: string): string {
  return `Pour passer au niveau ${palierCible}`;
}

/**
 * Intertitre du texte modèle. **Il ne nomme aucun palier** : la grille impose à
 * ce texte une longueur proche de la production du candidat, ce qui ne laisse
 * pas la place de démontrer honnêtement un niveau annoncé (mesuré : un candidat
 * a recopié un exemple étiqueté B2 et l'analyse l'a noté B1).
 */
export const ACTION_PLAN_EXEMPLE_TITLE = "Une version plus aboutie";

/** Même règle, au pluriel : à l'oral il n'y a pas UN texte modèle mais deux ou
 *  trois passages redits — la production n'est jamais réécrite en entier. */
export const ACTION_PLAN_REFORMULATIONS_TITLE = "Des versions plus abouties";

/* ---------------------------------------------------------------------------
 * L'attente du plan d'action
 *
 * Ce bloc vient d'un SECOND appel LLM, lancé par le serveur **après** que la
 * correction est persistée et la soumission passée à `EVALUATED` (invariant
 * backend : il ne doit jamais pouvoir retarder ni faire échouer la correction).
 * Un écran qui s'arrête net sur `EVALUATED` s'affiche donc sans plan alors
 * qu'il arrive dix à quinze secondes plus tard, et le candidat devait sortir
 * puis revenir pour le voir.
 *
 * Le sursis, son indicateur et son libellé vivent ici, à côté des blocs qu'ils
 * annoncent, et servent **les deux écrans** qui rendent ce plan : le rapport
 * d'une production EE/EO et le résultat d'un micro-exercice de compétence.
 * ------------------------------------------------------------------------- */

/**
 * Sursis de polling accordé au second appel, **une seule valeur pour les deux
 * écrans** (les compétences ont vécu à 10 s, les productions n'avaient rien :
 * deux durées pour la même attente n'avaient aucune justification).
 *
 * Déclaré en **durée** et non en nombre de tirages : c'est en traduisant chacun
 * de son côté que les deux fronts avaient divergé sur le budget de polling
 * principal. Miroir mobile : `kActionPlanGrace`.
 *
 * Le budget de polling global de chaque écran reste la **borne dure** : ce
 * sursis s'y ajoute, il ne le remplace pas.
 */
export const ACTION_PLAN_GRACE_MS = 15_000;

/**
 * Libellé de l'indicateur d'attente. **Contrat gelé**, miroir mot pour mot de
 * `kActionPlanPendingLabel` côté mobile — et tutoyé, comme tout ce qui entoure
 * ce plan.
 */
export const ACTION_PLAN_PENDING_LABEL = "On prépare tes conseils…";

/**
 * Ce que voit le candidat pendant le sursis : un petit spinner et une ligne, à
 * **l'emplacement exact** où le plan apparaîtra.
 *
 * Trois règles, à ne pas défaire :
 * - **non bloquant** — ce n'est ni un overlay, ni un écran de chargement, ni un
 *   squelette qui remplace le rapport : tout le reste reste lisible et
 *   utilisable pendant l'attente ;
 * - **il disparaît en silence** à la fin du sursis si rien n'arrive. Aucun
 *   message d'échec, aucun « indisponible » : un plan absent est un cas NORMAL
 *   (objectif déjà atteint, oral dégradé, second appel resté muet) ;
 * - **il ne s'arme que dans la fenêtre qui suit l'analyse.** Un rapport rouvert
 *   trois jours plus tard n'attend rien : c'est aux écrans de ne le rendre que
 *   pendant leur polling (cf. `productionActionPlanMayStillArrive` et
 *   `skillNiveauViseMayStillArrive`, qui exigent tous deux d'avoir vu la
 *   correction en vol).
 */
export function ActionPlanPending() {
  return (
    <p className={s.planPending} role="status" aria-live="polite">
      <span className={s.planPendingSpinner} aria-hidden />
      {ACTION_PLAN_PENDING_LABEL}
    </p>
  );
}

/** Trois teintes de pastille qui tournent : elles distinguent les leviers les
 *  uns des autres, elles ne les classent pas — l'ordre du serveur porte déjà la
 *  rentabilité (du plus au moins rentable). */
const DOT_TONE = [s.levierDotA, s.levierDotB, s.levierDotC];

/**
 * « Pour viser {niveau} » — ce qu'il manque, en deux ou trois gestes.
 *
 * Une ligne par levier : l'action à gauche, le bout de langue recopiable à
 * droite. Les deux sont plafonnés en mots côté serveur (6 et 5) ; aucune phrase
 * d'accompagnement n'est ajoutée ici.
 *
 * Rien ne s'affiche sans levier : l'absence du plan est un cas normal (second
 * appel best-effort), jamais une erreur à signaler.
 */
export function ActionPlanLeviers({leviers}: {leviers: readonly ActionPlanLevier[]}) {
  if (leviers.length === 0) return null;

  return (
    <ul className={s.levierList}>
      {leviers.map((levier, i) => (
        <li key={`${levier.action}-${i}`} className={s.levierRow}>
          <span className={`${s.levierDot} ${DOT_TONE[i % DOT_TONE.length]}`} aria-hidden>
            <Zap size={13} strokeWidth={2.4} />
          </span>
          <span className={s.levierAction}>{levier.action}</span>
          <span className={s.levierExample}>{levier.exemple}</span>
        </li>
      ))}
    </ul>
  );
}

/** Un morceau du texte réécrit : surligné, ou non. */
interface TextPart {
  text: string;
  marked: boolean;
}

/**
 * Découpe `texte` sur les extraits à mettre en évidence.
 *
 * Le serveur **garantit** que chaque `extrait` est une sous-chaîne exacte du
 * texte (il refuse le bloc entier sinon) : une simple recherche de chaîne
 * suffit, sans normalisation, sans approximation, et surtout **sans
 * `dangerouslySetInnerHTML`** — on rend des nœuds React, jamais du balisage
 * fabriqué à partir d'une sortie de modèle.
 *
 * Un extrait introuvable est **ignoré**, pas signalé : le texte se rend alors
 * sans son surlignage. Aucun extrait retrouvé ⇒ le texte brut, en un seul
 * morceau. On ne casse jamais le rendu et on n'invente jamais un surlignage.
 *
 * Les extraits qui se chevauchent sont départagés par ordre d'arrivée : le
 * premier posé garde sa place, le suivant cherche une autre occurrence et
 * s'efface s'il n'en trouve pas.
 */
function highlightParts(texte: string, segments: readonly ActionPlanSegment[]): TextPart[] {
  const ranges: {start: number; end: number}[] = [];

  for (const segment of segments) {
    const extrait = segment.extrait;
    if (!extrait) continue;

    let from = 0;
    for (;;) {
      const at = texte.indexOf(extrait, from);
      if (at < 0) break;
      const end = at + extrait.length;
      const overlaps = ranges.some((r) => at < r.end && end > r.start);
      if (!overlaps) {
        ranges.push({start: at, end});
        break;
      }
      from = at + 1;
    }
  }

  if (ranges.length === 0) return [{text: texte, marked: false}];

  ranges.sort((a, b) => a.start - b.start);

  const parts: TextPart[] = [];
  let cursor = 0;
  for (const range of ranges) {
    if (range.start > cursor) {
      parts.push({text: texte.slice(cursor, range.start), marked: false});
    }
    parts.push({text: texte.slice(range.start, range.end), marked: true});
    cursor = range.end;
  }
  if (cursor < texte.length) parts.push({text: texte.slice(cursor), marked: false});

  return parts;
}

/**
 * « Une version plus aboutie » — à quoi ça ressemble quand c'est bien fait.
 *
 * La réponse du candidat réécrite, les passages décisifs surlignés dans le
 * texte, puis une puce par passage qui dit ce qu'il apporte. **Production
 * écrite seulement** : à l'oral, cf. {@link ActionPlanReformulations}.
 */
export function ActionPlanExemple({exemple}: {exemple: ActionPlanExempleCible}) {
  const segments = exemple.segments ?? [];
  const parts = highlightParts(exemple.texte, segments);

  return (
    <div className={s.exempleCard}>
      <span className={s.exempleIcon} aria-hidden>
        <Sparkles size={15} strokeWidth={2.2} />
      </span>
      <p className={s.exempleText}>
        {parts.map((part, i) => (
          <Fragment key={i}>
            {part.marked ? <mark className={s.exempleMark}>{part.text}</mark> : part.text}
          </Fragment>
        ))}
      </p>
      {segments.length > 0 && (
        <ul className={s.segList}>
          {segments.map((segment, i) => (
            <li key={`${segment.extrait}-${i}`} className={s.segChip}>
              <span className={s.segExtrait}>{segment.extrait}</span>
              <ArrowRight size={12} strokeWidth={2.4} aria-hidden />
              <span className={s.segApport}>{segment.apport}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/**
 * « Des versions plus abouties » — l'équivalent oral, deux ou trois passages
 * redits au niveau visé.
 *
 * **Il n'y a jamais de texte modèle complet à l'oral** : ce que lit le
 * correcteur est une transcription automatique, en refaire un beau discours
 * tromperait le candidat sur ce qu'il a réellement dit. On montre donc son
 * passage (atténué), puis la même chose mieux dite (en accent), puis ce que la
 * reformulation apporte.
 */
export function ActionPlanReformulations({
  reformulations,
}: {
  reformulations: readonly ActionPlanReformulation[];
}) {
  if (reformulations.length === 0) return null;

  return (
    <ul className={s.reformList}>
      {reformulations.map((r, i) => (
        <li key={`${r.original}-${i}`} className={s.reformCard}>
          <p className={s.reformOriginal}>{r.original}</p>
          <p className={s.reformNew}>{r.reformule}</p>
          <span className={s.reformChip}>
            <ArrowRight size={12} strokeWidth={2.4} aria-hidden />
            {r.apport}
          </span>
        </li>
      ))}
    </ul>
  );
}

/**
 * « À retenir » — la tournure à emporter ailleurs.
 *
 * Deux lignes et rien d'autre : la formule, écrite comme un patron, et ce
 * qu'elle sert. Les deux sont plafonnées en mots côté serveur (8 et 14) ; on
 * n'ajoute ni exemple, ni commentaire, ni encouragement. Le bloc porte son
 * propre libellé — c'est un mémo, pas une section de plus.
 */
export function ActionPlanMemoCard({
  memo,
  className,
}: {
  memo: ActionPlanMemo;
  /** Marge d'entrée du bloc : les compétences l'empilent dans un flux à marges,
   *  le rapport de correction dans une colonne à `gap`. */
  className?: string;
}) {
  return (
    <section className={`${s.memo} ${className ?? ""}`}>
      <span className={s.memoEyebrow}>
        <Bookmark size={12} strokeWidth={2.6} aria-hidden />À retenir
      </span>
      <strong className={s.memoFormule}>{memo.formule}</strong>
      {memo.explication && <p className={s.memoText}>{memo.explication}</p>}
    </section>
  );
}
