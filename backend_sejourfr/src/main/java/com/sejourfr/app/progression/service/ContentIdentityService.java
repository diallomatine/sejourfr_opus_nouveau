package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.domain.ContentBankSignal;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.entity.LearningEvidenceRecord;
import com.sejourfr.app.progression.manager.LearningEvidenceManager;
import com.sejourfr.app.progression.manager.ProgressionContentSignalManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Qui décide si un contenu était vraiment neuf</b> (V4.2 §12 bis).
 *
 * <p>C'est la fermeture de la dernière faille exploitable du
 * {@code qualificationGate}. Sans elle, sur une banque de questions de taille
 * MVP, deux séries « différentes » partagent une large part de leurs items : un
 * candidat qui relance des séries jusqu'à retomber sur celles qu'il connaît
 * satisfait le Cas B de §16 sans avoir rien appris. Le moteur lui validerait un
 * palier sur sa mémoire, pas sur sa compréhension.
 *
 * <p>🛑 <b>{@code independenceClass} n'est jamais fourni par le client</b>
 * (invariant I38). Il se calcule ici, au moment de créer la preuve, contre
 * l'historique réel du candidat.
 */
@Service
@RequiredArgsConstructor
public class ContentIdentityService {

    private final ProgressionConfig config;
    private final LearningEvidenceManager evidenceManager;
    private final ProgressionContentSignalManager signalManager;

    /**
     * §12 bis.1 — l'identité d'une série : le hash de ses {@code questionIds}
     * <b>triés</b>.
     *
     * <p>Le tri est le point : deux séries composées exactement des mêmes
     * questions, présentées dans un ordre différent, ont le même
     * {@code contentId}. Sans lui, mélanger l'ordre suffirait à faire passer une
     * relance pour un contenu neuf.
     */
    public String contentIdDeSerie(Collection<UUID> questionIds) {
        String joint = questionIds.stream()
                .map(UUID::toString)
                .sorted()
                .reduce((a, b) -> a + "|" + b)
                .orElse("");
        return sha256(joint);
    }

    /** §12 bis.1 — une tâche EE/EO s'identifie par le sujet réellement traité. */
    public String contentIdDeSujet(UUID sujetId) {
        return "sujet:" + sujetId;
    }

    /** §12 bis.1 — un examen s'identifie par l'instance de son gabarit. */
    public String contentIdDExamen(UUID examTemplateInstanceId) {
        return "exam:" + examTemplateInstanceId;
    }

    /**
     * §12 bis.3 — la classe d'indépendance d'une série qu'on est en train
     * d'ingérer.
     *
     * <p>Trois cas, du plus sévère au plus permissif :
     * <ol>
     *   <li>le {@code contentId} existe déjà dans la fenêtre → c'est la même
     *       série relancée, {@code REPEATED_EXACT_CONTENT} (facteur 0.50) ;</li>
     *   <li>le recouvrement d'items avec une série antérieure atteint le seuil →
     *       {@code NEW_CONTENT_SAME_BLUEPRINT} (0.90) ;</li>
     *   <li>sinon {@code NEW_CONTENT} (1.00).</li>
     * </ol>
     *
     * <p>Une série des cas 1 et 2 alimente quand même le {@code masteryScore},
     * la confiance et la progression visible. Elle ne peut simplement pas servir
     * de <b>seconde preuve qualifiante</b> (§12 bis.4). C'est bien une
     * atténuation, pas une annulation : le candidat a travaillé.
     */
    public IndependenceClass classerSerie(UUID userId, SkillSection section, TargetLevel level,
                                          Collection<UUID> questionIds, String contentId,
                                          Instant occurredAt) {
        Instant depuis = occurredAt.minus(
                Duration.ofDays(config.independence().overlapWindowDays()));
        List<LearningEvidenceRecord> anterieures =
                evidenceManager.seriesRecentes(userId, section, level, depuis);

        boolean memeContenu = anterieures.stream()
                .anyMatch(e -> contentId.equals(e.getContentId()));
        if (memeContenu) {
            return IndependenceClass.REPEATED_EXACT_CONTENT;
        }

        double maxRecouvrement = maxRecouvrement(questionIds, anterieures);
        return maxRecouvrement >= config.independence().independenceOverlapThreshold()
                ? IndependenceClass.NEW_CONTENT_SAME_BLUEPRINT
                : IndependenceClass.NEW_CONTENT;
    }

    /**
     * §12 bis.5 — quand la banque est trop pauvre pour produire une seconde
     * série indépendante, <b>on ne relâche pas le seuil</b> : on le dit.
     *
     * <p>La tentation inverse est forte — « le candidat est bloqué, laissons
     * passer » — et c'est exactement ce qui transformerait un acquis mesuré en
     * acquis décrété. Le signal remonte, la production de contenu se priorise
     * dessus, et le seuil ne bouge pas.
     */
    public void signalerBanqueInsuffisante(UUID userId, SkillSection section, TargetLevel level,
                                           int questionsDisponibles) {
        signalManager.signaler(userId, ContentBankSignal.CONTENT_BANK_TOO_SMALL, section, level,
                questionsDisponibles + " questions disponibles, "
                        + config.receptiveSeriesBlueprint().questionCount() + " requises");
    }

    /**
     * §12 bis.2 — le recouvrement maximal avec les séries antérieures, rapporté
     * à la taille de la série <b>en cours</b>.
     *
     * <p>Le dénominateur n'est pas symétrique volontairement : ce qui compte est
     * la part de <i>cette</i> série que le candidat avait déjà vue.
     */
    private double maxRecouvrement(Collection<UUID> questionIds,
                                   List<LearningEvidenceRecord> anterieures) {
        if (questionIds.isEmpty()) {
            return 0.0d;
        }
        Set<String> courantes = new LinkedHashSet<>();
        questionIds.forEach(id -> courantes.add(id.toString()));

        double max = 0.0d;
        for (LearningEvidenceRecord anterieure : anterieures) {
            Set<String> precedentes = questionsDe(anterieure);
            if (precedentes.isEmpty()) {
                continue;
            }
            Set<String> commun = new HashSet<>(courantes);
            commun.retainAll(precedentes);
            max = Math.max(max, (double) commun.size() / courantes.size());
        }
        return max;
    }

    /**
     * Les {@code questionIds} d'une preuve antérieure, relus depuis ses
     * métadonnées.
     *
     * <p>Ils y sont écrits à l'ingestion précisément pour ce calcul : le
     * {@code contentId} est un hash, il ne permet de détecter que l'identité
     * exacte, pas le recouvrement partiel — qui est le cas intéressant.
     */
    private Set<String> questionsDe(LearningEvidenceRecord record) {
        Object brut = record.getMetadata() == null ? null : record.getMetadata().get("questionIds");
        if (brut instanceof Collection<?> collection) {
            Set<String> ids = new LinkedHashSet<>();
            collection.forEach(id -> ids.add(String.valueOf(id)));
            return ids;
        }
        return Set.of();
    }

    private static String sha256(String valeur) {
        try {
            byte[] empreinte = MessageDigest.getInstance("SHA-256")
                    .digest(valeur.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(empreinte.length * 2);
            for (byte b : empreinte) {
                hex.append(Character.forDigit((b >> 4) & 0xF, 16));
                hex.append(Character.forDigit(b & 0xF, 16));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponible", e);
        }
    }
}
