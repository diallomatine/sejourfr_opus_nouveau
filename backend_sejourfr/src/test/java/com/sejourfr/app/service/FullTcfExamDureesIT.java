package com.sejourfr.app.service;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le temps d'un examen blanc TCF complet, sur base réelle.
 *
 * <p>Deux décisions verrouillées ici :
 * <ul>
 *   <li><b>il n'y a plus d'enveloppe globale de 90 min</b> — le total réel fait
 *       ~95 min, le temps restant d'une épreuve ne se transfère jamais à la
 *       suivante, et l'abandon-reprise entre épreuves est supporté : un compte
 *       à rebours d'ensemble expirerait au nez du candidat qui reprend le
 *       lendemain ;</li>
 *   <li><b>une épreuve a la même durée où qu'elle soit jouée</b> — la CE vaut
 *       35 min en examen complet comme en standalone (elle valait 30 min ici
 *       pour tenir dans l'enveloppe supprimée).</li>
 * </ul>
 */
class FullTcfExamDureesIT extends AbstractIntegrationTest {

    @Autowired FullTcfExamService service;
    @Autowired AttemptManager attemptManager;
    @Autowired TestData data;

    private Attempt sub(Attempt parent, EpreuveType e) {
        return attemptManager.findSubAttempts(parent.getId()).stream()
                .filter(a -> a.getEpreuve() == e)
                .findFirst()
                .orElseThrow();
    }

    @Test
    @DisplayName("Le parent ne porte AUCUN chrono global")
    void parentSansChronoGlobal() {
        User user = data.user();

        FullTcfExamResponse r = service.start(user.getId(), 1);
        Attempt parent = attemptManager.findById(r.id()).orElseThrow();

        assertThat(parent.getTimeLimitSeconds()).isNull();
        // timer_started_at reste : c'est la trace du début réel de l'examen
        // (bilan, statut de continuité), plus l'ancre d'un décompte.
        assertThat(parent.getTimerStartedAt()).isNull();
    }

    @Test
    @DisplayName("Chaque sous-epreuve porte SA duree, la CE vaut 35 min comme en standalone")
    void dureesDesSousEpreuves() {
        User user = data.user();

        FullTcfExamResponse r = service.start(user.getId(), 1);
        Attempt parent = attemptManager.findById(r.id()).orElseThrow();

        assertThat(sub(parent, EpreuveType.TCF_CO).getTimeLimitSeconds()).isEqualTo(20 * 60);
        assertThat(sub(parent, EpreuveType.TCF_CE).getTimeLimitSeconds()).isEqualTo(35 * 60);
        assertThat(sub(parent, EpreuveType.TCF_EE).getTimeLimitSeconds()).isEqualTo(30 * 60);
        // L'oral se chronomètre par tâche, jamais par épreuve.
        assertThat(sub(parent, EpreuveType.TCF_EO).getTimeLimitSeconds()).isNull();
    }

    @Test
    @DisplayName("Le DTO sert la duree et l'echeance de chaque epreuve — les fronts ne les recopient plus")
    void dtoPorteLeTemps() {
        User user = data.user();

        FullTcfExamResponse r = service.start(user.getId(), 1);

        FullTcfExamResponse.SubAttempt ce = r.subAttempts().stream()
                .filter(s -> s.epreuve() == EpreuveType.TCF_CE).findFirst().orElseThrow();
        assertThat(ce.timeLimitSeconds()).isEqualTo(35 * 60);
        // Pas encore lancée : ni ancre, ni échéance. Le chrono ne part qu'au
        // « Commencer · … » (POST /begin).
        assertThat(ce.timerStartedAt()).isNull();
        assertThat(ce.deadlineAt()).isNull();
    }

    @Test
    @DisplayName("Lancer une epreuve pose son ancre et son echeance, sans toucher aux autres")
    void beginPoseLancreEtLecheance() {
        User user = data.user();
        FullTcfExamResponse created = service.start(user.getId(), 1);

        FullTcfExamResponse r = service.beginEpreuve(user.getId(), created.id(), EpreuveType.TCF_CO);

        FullTcfExamResponse.SubAttempt co = r.subAttempts().stream()
                .filter(s -> s.epreuve() == EpreuveType.TCF_CO).findFirst().orElseThrow();
        assertThat(co.timerStartedAt()).isNotNull();
        assertThat(co.deadlineAt()).isEqualTo(co.timerStartedAt().plusSeconds(20 * 60));

        // La CE n'a pas commencé : son temps ne court pas encore. C'est
        // exactement ce qui rend la reprise entre deux épreuves possible.
        FullTcfExamResponse.SubAttempt ce = r.subAttempts().stream()
                .filter(s -> s.epreuve() == EpreuveType.TCF_CE).findFirst().orElseThrow();
        assertThat(ce.deadlineAt()).isNull();

        // Le parent garde sa trace de début, sans chrono.
        assertThat(r.timerStartedAt()).isNotNull();
        assertThat(attemptManager.findById(created.id()).orElseThrow().getTimeLimitSeconds()).isNull();
    }

    @Test
    @DisplayName("Reprendre la meme epreuve ne remet pas son chrono a zero")
    void repriseNeRemetPasLeChronoAZero() {
        User user = data.user();
        FullTcfExamResponse created = service.start(user.getId(), 1);

        FullTcfExamResponse premier = service.beginEpreuve(user.getId(), created.id(), EpreuveType.TCF_CO);
        FullTcfExamResponse second = service.beginEpreuve(user.getId(), created.id(), EpreuveType.TCF_CO);

        assertThat(second.subAttempts().stream()
                .filter(s -> s.epreuve() == EpreuveType.TCF_CO).findFirst().orElseThrow().deadlineAt())
                .isEqualTo(premier.subAttempts().stream()
                        .filter(s -> s.epreuve() == EpreuveType.TCF_CO).findFirst().orElseThrow().deadlineAt());
    }

    @Test
    @DisplayName("Tant que l'examen court, aucun statut de continuite n'est rendu")
    void pasDeContinuiteAvantLaFin() {
        User user = data.user();

        assertThat(service.start(user.getId(), 1).continuite()).isNull();
    }
}
