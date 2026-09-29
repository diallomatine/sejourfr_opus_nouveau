package com.sejourfr.app.progression;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.AssistanceLevel;
import com.sejourfr.app.progression.domain.CalibrationStatus;
import com.sejourfr.app.progression.domain.EvidenceEntryPoint;
import com.sejourfr.app.progression.domain.EvidenceSourceType;
import com.sejourfr.app.progression.domain.IndependenceClass;
import com.sejourfr.app.progression.domain.LearningEvidence;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import com.sejourfr.app.progression.service.ContentIdentityService;
import com.sejourfr.app.progression.service.ProgressionIngestionService;
import com.sejourfr.app.progression.service.ProgressionReadService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>T34 et T35 au niveau de la base</b> — la fermeture de la dernière faille du
 * {@code qualificationGate} (V4.2 §12 bis).
 *
 * <p>Le scénario que ce fichier interdit : sur une banque de questions de taille
 * MVP, un candidat relance des séries jusqu'à retomber sur celles qu'il connaît
 * déjà, et le Cas B de §16 lui valide un palier. Il n'aurait rien appris ; le
 * moteur aurait mesuré sa mémoire.
 */
class ContentIdentityServiceIT extends AbstractIntegrationTest {

    @Autowired ContentIdentityService contentIdentityService;
    @Autowired ProgressionIngestionService ingestionService;
    @Autowired ProgressionReadService readService;
    @Autowired TestData data;

    private static final Instant T0 = Instant.parse("2026-03-01T09:00:00Z");

    /**
     * §12 bis.1 — le {@code contentId} est le hash des {@code questionIds}
     * <b>triés</b>. Sans le tri, mélanger l'ordre de présentation suffirait à
     * faire passer une relance pour un contenu neuf.
     */
    @Test
    @DisplayName("Deux séries des mêmes questions ont le même contentId, quel que soit l'ordre")
    void contentIdIndependantDeLOrdre() {
        List<UUID> questions = questions(20);
        List<UUID> melangees = new ArrayList<>(questions);
        Collections.shuffle(melangees, new java.util.Random(42));

        assertThat(contentIdentityService.contentIdDeSerie(melangees))
                .isEqualTo(contentIdentityService.contentIdDeSerie(questions));
    }

    /**
     * 🛑 Le test le plus important du fichier — T34.
     *
     * <p>Deux séries qui partagent 70 % de leurs items ne comptent pas pour deux
     * preuves indépendantes. Elles alimentent la maîtrise, la confiance et la
     * progression visible : le candidat a travaillé. Elles ne verrouillent
     * simplement pas un palier.
     */
    @Test
    @DisplayName("T34 — 70 % de recouvrement ne donne pas une seconde preuve qualifiante")
    void recouvrementFortNeQualifiePas() {
        User user = data.user();
        List<UUID> q1a20 = questions(20);

        ingerer(user.getId(), q1a20, 16, T0);
        assertThat(classer(user.getId(), q1a20, T0)).isNotNull();

        // 14 items communs sur 20 = 0,70, au-dessus du seuil de 0,50.
        List<UUID> chevauchante = new ArrayList<>(q1a20.subList(0, 14));
        chevauchante.addAll(questions(6));
        Instant j1 = T0.plus(Duration.ofDays(1));

        assertThat(classer(user.getId(), chevauchante, j1))
                .isEqualTo(IndependenceClass.NEW_CONTENT_SAME_BLUEPRINT);
        ingerer(user.getId(), chevauchante, 17, j1);

        assertThat(readService.palier(user.getId(), SkillSection.CO, TargetLevel.A2, j1).status())
                .isNotEqualTo(ProgressionStatus.SOLID);

        // Une troisième série sans le moindre item commun : celle-là qualifie.
        List<UUID> disjointe = questions(20);
        Instant j2 = T0.plus(Duration.ofDays(2));
        assertThat(classer(user.getId(), disjointe, j2)).isEqualTo(IndependenceClass.NEW_CONTENT);
        ingerer(user.getId(), disjointe, 16, j2);

        assertThat(readService.palier(user.getId(), SkillSection.CO, TargetLevel.A2, j2).status())
                .isEqualTo(ProgressionStatus.SOLID);
    }

    @Test
    @DisplayName("T35 — relancer la série identique ne verrouille jamais, même à 20/20")
    void relanceIdentiqueNeVerrouillePas() {
        User user = data.user();
        List<UUID> memes = questions(20);

        ingerer(user.getId(), memes, 16, T0);
        Instant j1 = T0.plus(Duration.ofDays(1));
        assertThat(classer(user.getId(), memes, j1))
                .isEqualTo(IndependenceClass.REPEATED_EXACT_CONTENT);
        ingerer(user.getId(), memes, 20, j1);
        Instant j2 = T0.plus(Duration.ofDays(2));
        ingerer(user.getId(), memes, 20, j2);

        assertThat(readService.palier(user.getId(), SkillSection.CO, TargetLevel.A2, j2).status())
                .isNotEqualTo(ProgressionStatus.SOLID);
    }

    /**
     * §12 bis.2 — la fenêtre de recouvrement est bornée à 60 jours : au-delà, un
     * item revu n'est plus « déjà connu ».
     */
    @Test
    @DisplayName("Hors fenêtre de 60 jours, les mêmes questions redeviennent du contenu neuf")
    void horsFenetreLeContenuRedevientNeuf() {
        User user = data.user();
        List<UUID> memes = questions(20);
        ingerer(user.getId(), memes, 16, T0);

        Instant bienPlusTard = T0.plus(Duration.ofDays(90));
        assertThat(classer(user.getId(), memes, bienPlusTard))
                .isEqualTo(IndependenceClass.NEW_CONTENT);
    }

    private IndependenceClass classer(UUID userId, List<UUID> questions, Instant quand) {
        return contentIdentityService.classerSerie(userId, SkillSection.CO, TargetLevel.A2,
                questions, contentIdentityService.contentIdDeSerie(questions), quand);
    }

    private void ingerer(UUID userId, List<UUID> questions, int correctes, Instant quand) {
        String contentId = contentIdentityService.contentIdDeSerie(questions);
        IndependenceClass independance = classer(userId, questions, quand);
        double accuracy = (double) correctes / questions.size();
        Map<String, Object> metadata = new LinkedHashMap<>();
        metadata.put("questionIds", questions.stream().map(UUID::toString).toList());

        ingestionService.ingerer(LearningEvidence.builder()
                .userId(userId)
                .attemptId(UUID.randomUUID())
                .occurredAt(quand)
                .ingestedAt(Instant.now())
                .entryPoint(EvidenceEntryPoint.REVISER)
                .sourceType(EvidenceSourceType.CO_CE_20_SERIES)
                .section(SkillSection.CO)
                .level(TargetLevel.A2)
                .result((accuracy - 0.25d) / 0.75d)
                .scoringConfidence(1.0d)
                .assistanceLevel(AssistanceLevel.NONE)
                .contentId(contentId)
                .calibrationStatus(CalibrationStatus.CALIBRATED)
                .independenceClass(independance)
                .engineVersionAtCreation(1)
                .metadata(metadata)
                .build());
    }

    private static List<UUID> questions(int combien) {
        List<UUID> ids = new ArrayList<>(combien);
        for (int i = 0; i < combien; i++) {
            ids.add(UUID.randomUUID());
        }
        return ids;
    }
}
