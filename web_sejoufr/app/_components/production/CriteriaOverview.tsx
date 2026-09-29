"use client";

import {
  BookOpen,
  MessageSquareMore,
  Quote,
  SpellCheck,
  Target,
  UserRound,
} from "lucide-react";
import {critereBandeFromNote} from "@/lib/production-feedback";
import {bandeCritereLabel, type EeCriterion} from "@/lib/types";
import styles from "./production.module.css";

/**
 * Nom court d'un critère, pour la vue « en un coup d'œil ».
 *
 * Le `label` du serveur est une **définition** (« Communiquer : accomplir la
 * tâche et enchaîner les idées »), pas un nom : sur deux lignes, il pousse la
 * bande hors de vue et rend la liste illisible d'un regard. On garde donc le nom
 * court dans la ligne — la définition réapparaît quand on déplie, elle n'est
 * jamais perdue.
 */
function shortLabel(code: string): string | null {
  switch (code) {
    case "communiquer":
      return "Communiquer";
    case "interagir":
      return "Interagir";
    case "lexique":
    case "vocabulaire":
      return "Vocabulaire";
    case "morphosyntaxe":
    case "grammaire":
      return "Grammaire";
    default:
      return null;
  }
}

/** Icône d'un critère. Couvre les codes des grilles précédentes : les
 *  évaluations déjà en base en portent d'autres, et retomber sur une icône par
 *  défaut ferait toutes se ressembler. */
function CriterionIcon({code}: {code: string}) {
  const props = {size: 19, strokeWidth: 2.1, "aria-hidden": true} as const;
  switch (code) {
    case "interagir":
    case "adequation_destinataire":
    case "conduite_echange":
      return <UserRound {...props} />;
    case "lexique":
    case "vocabulaire":
      return <BookOpen {...props} />;
    case "morphosyntaxe":
    case "grammaire":
    case "orthographe":
      return <SpellCheck {...props} />;
    case "developpement_reponses":
    case "coherence":
    case "organisation":
      return <MessageSquareMore {...props} />;
    default:
      return <Target {...props} />;
  }
}

/**
 * Le profil du candidat **en un coup d'œil** : les quatre critères, leur bande
 * et leur barre, sans une ligne de prose.
 *
 * Cette liste était rangée dans « Voir l'analyse complète », donc invisible en
 * pratique — alors que c'est la seule vue d'ensemble du rapport. Elle remonte
 * ici, mais **une carte par critère** et **compacte** : commentaire, preuve et
 * définition ne s'affichent que sur demande, carte par carte. Quatre lignes
 * serrées dans une seule carte se lisaient comme un tableau, pas comme quatre
 * choses sur lesquelles on peut appuyer.
 */
export function CriteriaOverview({criteres}: {criteres: EeCriterion[]}) {
  if (criteres.length === 0) return null;

  return (
    <section className={styles.critSection}>
      <p className={styles.sectionHead}>
        <span className={styles.sectionTitle}>Votre profil en un coup d&apos;œil</span>
        <span className={styles.sectionHint}>Appuyez pour le détail</span>
      </p>
      {criteres.map((c, i) => (
        <CriterionCard key={c.code || i} criterion={c} />
      ))}
    </section>
  );
}

/**
 * Un critère, toujours rendu par sa **bande qualitative**.
 *
 * Les évaluations antérieures ne portent pas de `bande` : elle est alors dérivée
 * de la note sur la même échelle (celle du TCF) que celle du serveur
 * ({@link critereBandeFromNote}). Plus aucun chiffre ni jauge sur un critère —
 * une jauge « note / 20 » se lirait comme un pourcentage de réussite alors qu'un
 * critère à 12 vaut B2.
 */
function CriterionCard({criterion: c}: {criterion: EeCriterion}) {
  const bande = c.bande ?? critereBandeFromNote(c.noteSurVingt);
  const full = c.label ?? c.code;
  const short = shortLabel(c.code) ?? full;
  const hasDetail = Boolean(c.commentaire || c.preuve || full !== short);

  return (
    <details className={styles.critCard} data-band={bande}>
      <summary className={styles.critSummary}>
        <span className={styles.critIcon} data-band={bande}>
          <CriterionIcon code={c.code} />
        </span>
        <span className={styles.critMain}>
          <span className={styles.critName}>{short}</span>
          <span className={styles.critBar} data-band={bande} aria-hidden>
            <span />
          </span>
        </span>
        <span className={styles.critBande} data-band={bande}>
          {bandeCritereLabel(bande)}
        </span>
        {/* Les deux libellés vivent dans le DOM et CSS en montre un : `<details>`
            n'expose pas son état à React sans JS, et un « Voir pourquoi » figé
            sur une carte ouverte est une affordance qui ment. */}
        {hasDetail && (
          <span className={styles.critWhy}>
            <span className={styles.critWhyClosed}>Voir pourquoi</span>
            <span className={styles.critWhyOpen}>Masquer le détail</span>
          </span>
        )}
      </summary>

      {hasDetail && (
        <div className={styles.critDetail}>
          {full !== short && <p className={styles.critFull}>{full}</p>}
          {c.commentaire && <p className={styles.critComment}>{c.commentaire}</p>}
          {c.preuve && (
            <p className={styles.critProof}>
              <Quote size={12} strokeWidth={2.4} aria-hidden />
              <span>{c.preuve}</span>
            </p>
          )}
        </div>
      )}
    </details>
  );
}
