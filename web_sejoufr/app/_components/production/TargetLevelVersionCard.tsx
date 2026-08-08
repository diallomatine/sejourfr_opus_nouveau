"use client";

import {ArrowUpRight} from "lucide-react";
import {
  VERSION_CIBLEE_EYEBROW,
  VERSION_CIBLEE_LEVIERS_TITLE,
  versionCibleeIntro,
  versionCibleeTitle,
} from "@/lib/production-feedback";
import type {EeVersionCiblee} from "@/lib/types";
import styles from "./production.module.css";

/**
 * **La marche au-dessus** : la réponse du candidat réécrite au palier qu'il
 * VISE, plus les deux ou trois leviers qui l'en séparent.
 *
 * C'est la demande du propriétaire, mot pour mot : « un candidat cherchant la
 * naturalisation, produire un exemple et lui expliquer ce qu'il doit améliorer
 * pour atteindre ce niveau souhaité ».
 *
 * **C'est le SEUL texte modèle du rapport** depuis le 2026-08-08 :
 * `version_amelioree` (qui réécrivait la production au niveau **déjà constaté**,
 * en bascule sous la rédaction) n'est plus affichée nulle part. Elle était le
 * texte le plus visible et le plus copiable de la page, et recopier un modèle
 * écrit à son propre niveau ne fait pas monter d'un palier — mesuré : même note,
 * même niveau au dixième près.
 *
 * D'où la forme : **section titrée à part**, teinte bleue, titre qui nomme le
 * niveau visé, et sous-titre qui dit explicitement que ce texte n'est pas celui
 * du candidat.
 *
 * Rien n'est rendu quand le bloc est absent : EO, évaluation antérieure, second
 * appel LLM en échec, ou niveau visé déjà atteint. Pas de squelette, pas de
 * « non disponible ». Miroir mobile : `target_level_version_card.dart`.
 */
export function TargetLevelVersionCard({version}: {version: EeVersionCiblee | null}) {
  if (!version) return null;

  return (
    <section className={styles.targetSection}>
      <p className={styles.sectionHead}>
        <span className={styles.sectionTitle}>{versionCibleeTitle(version.niveauVise)}</span>
      </p>

      <div className={styles.targetCard}>
        <p className={styles.targetEyebrow}>
          <ArrowUpRight size={13} strokeWidth={2.6} aria-hidden />
          {VERSION_CIBLEE_EYEBROW}
        </p>
        <p className={styles.targetIntro}>{versionCibleeIntro(version.niveauVise)}</p>
        <p className={styles.targetText}>{version.texte}</p>

        {version.ceQuiManque.length > 0 && (
          <>
            <p className={styles.targetGapTitle}>{VERSION_CIBLEE_LEVIERS_TITLE}</p>
            {/* Ordre du backend PRÉSERVÉ : il est trié du plus rentable au
                moins rentable, le numéro le rend lisible sans le retrier. */}
            <ol className={styles.targetGapList}>
              {version.ceQuiManque.map((levier, i) => (
                <li key={levier} className={styles.targetGapItem}>
                  <span className={styles.targetGapRank} aria-hidden>
                    {i + 1}
                  </span>
                  <span>{levier}</span>
                </li>
              ))}
            </ol>
          </>
        )}
      </div>
    </section>
  );
}
