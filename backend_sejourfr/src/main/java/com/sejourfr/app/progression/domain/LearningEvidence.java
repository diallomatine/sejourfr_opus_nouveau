package com.sejourfr.app.progression.domain;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import lombok.Builder;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Une observation issue d'une activite reellement effectuee par le
 * candidat</b> (V4.2 §5) — le registre immuable dont tout le reste se deduit.
 *
 * <p>🛑 <b>Il n'existe pas de preuve synthetique.</b> Aucun {@code
 * syntheticEvidence}, {@code syntheticResult} ni {@code syntheticWeight} ne doit
 * jamais etre cree pour simuler un niveau inferieur valide par un niveau
 * superieur (invariants I3, I4). Cette deduction-la est portee par
 * {@code prerequisiteSatisfied} (§18), qui est <b>derive a la lecture et
 * revocable</b> — pas par une ligne d'historique falsifiee.
 *
 * <p>{@link #entryPoint} et {@link #sourceType} ne doivent jamais etre
 * confondus : le premier dit d'ou l'utilisateur est parti, le second ce qu'il a
 * reellement fait. Seul le second entre dans un calcul.
 *
 * @param occurredAt   l'heure <b>pedagogique</b> de fin d'activite, pas l'heure
 *                     de synchronisation : une preuve arrivee hors-ligne trois
 *                     jours plus tard garde sa date reelle (§5). Un
 *                     {@code occurredAt} dans le futur est rejete ou normalise
 *                     par une regle serveur explicite, jamais accepte en
 *                     silence.
 * @param ingestedAt   l'heure d'arrivee serveur — tracabilite, aucun calcul.
 * @param result       deja normalise dans {@code [0,1]} selon le type d'etat :
 *                     corrige du hasard en CO/CE (§6.1), {@code 0 / 0.5 / 1}
 *                     pour une observation IA (§6.5).
 * @param contentId    l'identite du contenu reellement traite (§12 bis.1) —
 *                     pour une serie, le hash de ses {@code questionIds} tries,
 *                     donc independant de l'ordre de presentation.
 * @param independenceClass toujours <b>calcule serveur</b> a la creation, jamais
 *                     fourni par le client (invariant I38).
 */
@Builder(toBuilder = true)
public record LearningEvidence(
        UUID id,
        UUID userId,
        UUID attemptId,
        Instant occurredAt,
        Instant ingestedAt,
        EvidenceEntryPoint entryPoint,
        EvidenceSourceType sourceType,
        SkillSection section,
        TargetLevel level,
        String skillId,
        double result,
        double scoringConfidence,
        AssistanceLevel assistanceLevel,
        String contentId,
        String blueprintId,
        CalibrationStatus calibrationStatus,
        IndependenceClass independenceClass,
        int engineVersionAtCreation,
        Map<String, Object> metadata
) {

    /**
     * <b>La cle naturelle d'idempotence</b> (§42) : un retry reseau ne doit
     * jamais doubler la progression.
     *
     * <p>Elle porte l'{@code observationIndex} via {@link #skillId} pour les
     * observations IA multiples d'une meme soumission ; c'est l'unicite en base
     * qui fait foi, pas un controle applicatif.
     */
    public String naturalKey() {
        return String.join("|",
                String.valueOf(attemptId),
                sourceType.name(),
                section.name(),
                level == null ? "-" : level.name(),
                skillId == null ? "-" : skillId);
    }

    /** La cle d'etat que cette preuve alimente. */
    public ProgressionStateKey stateKey() {
        return skillId == null
                ? ProgressionStateKey.receptive(section, level)
                : ProgressionStateKey.productive(section, skillId);
    }

    /** La famille de sources, pour le cap micro des accumulateurs (§11.1). */
    public EvidenceSourceFamily family() {
        return sourceType.family();
    }
}
