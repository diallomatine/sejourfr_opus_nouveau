package com.sejourfr.app.progression.engine;

import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;

import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * <b>Les deux portes qui séparent « bon score » de « acquis »</b> — le
 * {@code qualificationGate} CO/CE (V4.2 §16) et le {@code transferGate} EE/EO
 * (§17).
 *
 * <p>Sans elles, un candidat atteint {@code SOLID} en refaisant la même série
 * jusqu'à la connaître par cœur, ou en enchaînant vingt micro-sujets sans jamais
 * écrire une vraie production. Les seuils de score et de confiance ne suffisent
 * pas : ils mesurent la performance, pas ce sur quoi elle a porté.
 *
 * <p>🛑 <b>Preuves directes uniquement.</b> Aucun de ces calculs ne regarde un
 * niveau voisin : une qualification se prouve à son propre palier.
 */
final class ProgressionGates {

    private ProgressionGates() {
    }

    /**
     * Le {@code qualificationGate} d'un palier CO/CE (§16) : un des trois cas.
     *
     * <p><b>Cas A</b> — un examen blanc direct à {@code result >= 0.80}.<br>
     * <b>Cas B</b> — deux séries calibrées réellement indépendantes, dont une au
     * moins à {@code result >= 0.70}.<br>
     * <b>Cas C</b> — un diagnostic fort <i>plus</i> une confirmation directe
     * indépendante. Un diagnostic seul ne verrouille jamais durablement un
     * palier (T08).
     */
    static boolean receptive(ProgressionConfig config, Collection<LearningEvidence> evidence) {
        ProgressionConfig.ReceptiveGate seuils = config.qualificationGates().receptiveLevel();

        boolean casA = evidence.stream().anyMatch(e ->
                estExamen(e.sourceType()) && e.result() >= seuils.mockStrongResult());
        if (casA) {
            return true;
        }

        List<LearningEvidence> seriesQualifiantes = seriesQualifiantes(evidence);
        boolean casB = compteIndependantes(seriesQualifiantes) >= 2
                && seriesQualifiantes.stream()
                        .anyMatch(e -> e.result() >= seuils.seriesPositiveResult());
        if (casB) {
            return true;
        }

        boolean diagnosticFort = evidence.stream().anyMatch(e ->
                e.sourceType() == EvidenceSourceType.DIAGNOSTIC
                        && e.result() >= seuils.diagnosticPositiveResult());
        if (!diagnosticFort) {
            return false;
        }
        return evidence.stream().anyMatch(e ->
                e.result() >= seuils.confirmationPositiveResult()
                        && (estExamen(e.sourceType())
                            || (e.sourceType() == EvidenceSourceType.CO_CE_20_SERIES
                                && e.calibrationStatus() == CalibrationStatus.CALIBRATED)));
    }

    /**
     * Le {@code transferGate} d'une compétence EE/EO (§17) : au moins une preuve
     * de transfert directe — une vraie tâche, une re-vérification ou un examen —
     * au-dessus du seuil.
     *
     * <p>Les micro-sujets, seuls, ne le franchissent jamais : ils mènent au plus
     * à {@code READY_FOR_REASSESSMENT} (T20, T21). À l'inverse, deux vraies
     * tâches suffisent — on n'impose pas les cinq micro-sujets à qui a déjà
     * prouvé le transfert (T22, invariant I28).
     */
    static boolean transfer(ProgressionConfig config, Collection<LearningEvidence> evidence) {
        double seuil = config.qualificationGates().productiveSkill().transferResult();
        return evidence.stream().anyMatch(e ->
                estPreuveDeTransfert(e.sourceType()) && e.result() >= seuil);
    }

    /** Combien de preuves comptent effectivement pour le gate — pour les logs. */
    static int compteQualifiantes(ProgressionConfig config,
                                  Collection<LearningEvidence> evidence) {
        ProgressionConfig.ReceptiveGate seuils = config.qualificationGates().receptiveLevel();
        long examens = evidence.stream().filter(e ->
                estExamen(e.sourceType()) && e.result() >= seuils.mockStrongResult()).count();
        return (int) examens + compteIndependantes(seriesQualifiantes(evidence));
    }

    /**
     * Les séries qui ont le <b>droit</b> de compter comme preuve qualifiante.
     *
     * <p>Trois exclusions, chacune fermant une faille réelle :
     * <ul>
     *   <li>{@code UNCALIBRATED} — la composition 6/10/4 n'est pas garantie, le
     *       score n'est pas comparable (§6.3) ;</li>
     *   <li>{@code REPEATED_EXACT_CONTENT} — c'est la même série relancée (T35) ;</li>
     *   <li>{@code NEW_CONTENT_SAME_BLUEPRINT} — le recouvrement d'items atteint
     *       le seuil, le candidat retombe sur ce qu'il connaît déjà (T34).</li>
     * </ul>
     *
     * <p>Autrement dit : seule une série {@link IndependenceClass#NEW_CONTENT}
     * calibrée qualifie. Une série exclue alimente quand même le
     * {@code masteryScore}, la confiance et la progression visible — elle ne
     * verrouille simplement pas un palier.
     */
    private static List<LearningEvidence> seriesQualifiantes(
            Collection<LearningEvidence> evidence) {
        return evidence.stream()
                .filter(e -> e.sourceType() == EvidenceSourceType.CO_CE_20_SERIES)
                .filter(e -> e.calibrationStatus() == CalibrationStatus.CALIBRATED)
                .filter(e -> e.independenceClass() == IndependenceClass.NEW_CONTENT)
                .toList();
    }

    /**
     * Deux séries ne comptent pour deux que si leur contenu <b>et</b> leur
     * tentative diffèrent (§12, §12 bis.4). Une seconde correction de la même
     * soumission n'est pas une nouvelle preuve indépendante.
     */
    private static int compteIndependantes(Collection<LearningEvidence> series) {
        Set<String> contenus = new HashSet<>();
        Set<String> tentatives = new HashSet<>();
        int compte = 0;
        for (LearningEvidence e : series) {
            boolean contenuNeuf = contenus.add(String.valueOf(e.contentId()));
            boolean tentativeNeuve = tentatives.add(String.valueOf(e.attemptId()));
            if (contenuNeuf && tentativeNeuve) {
                compte++;
            }
        }
        return compte;
    }

    static boolean estExamen(EvidenceSourceType sourceType) {
        return sourceType == EvidenceSourceType.DOMAIN_MOCK
                || sourceType == EvidenceSourceType.FULL_MOCK_EXAM;
    }

    static boolean estPreuveDeTransfert(EvidenceSourceType sourceType) {
        return sourceType == EvidenceSourceType.FULL_TASK
                || sourceType == EvidenceSourceType.REASSESSMENT
                || estExamen(sourceType);
    }
}
