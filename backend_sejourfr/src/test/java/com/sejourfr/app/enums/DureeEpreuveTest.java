package com.sejourfr.app.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Gèle l'autorité unique des durées d'épreuve. Ces valeurs étaient éparpillées
 * dans {@code AttemptService} et {@code FullTcfExamService}, et la
 * compréhension écrite en avait <b>deux</b> (35 min isolée, 30 min en examen
 * complet) — d'où deux durées différentes affichées sur les fronts pour la
 * même épreuve.
 */
class DureeEpreuveTest {

    @Test
    @DisplayName("Une epreuve a la meme duree ou qu'elle soit jouee")
    void dureesParEpreuve() {
        assertThat(DureeEpreuve.secondes(EpreuveType.TCF_CO)).isEqualTo(20 * 60);
        assertThat(DureeEpreuve.secondes(EpreuveType.TCF_CE)).isEqualTo(35 * 60);
        assertThat(DureeEpreuve.secondes(EpreuveType.TCF_STRUCTURE)).isEqualTo(20 * 60);
        assertThat(DureeEpreuve.secondes(EpreuveType.TCF_EE)).isEqualTo(30 * 60);
    }

    @Test
    @DisplayName("L'expression orale n'a AUCUNE duree d'epreuve : le temps se compte par tache")
    void oralSansChronoDepreuve() {
        assertThat(DureeEpreuve.secondes(EpreuveType.TCF_EO)).isNull();
        assertThat(DureeEpreuve.EO.getSecondes()).isNull();
    }

    @Test
    @DisplayName("L'examen complet n'a plus d'enveloppe globale")
    void examenCompletSansEnveloppe() {
        assertThat(DureeEpreuve.secondes(EpreuveType.TCF_COMPLET)).isNull();
        assertThat(DureeEpreuve.secondes(EpreuveType.CIVIQUE)).isNull();
        assertThat(DureeEpreuve.secondes(null)).isNull();
    }

    @Test
    @DisplayName("La duree annoncee d'un examen complet est la somme des 4 epreuves")
    void dureeAnnonceeExamenComplet() {
        // 20 + 35 + 30 + 10 = 95 min — et non les 90 min de l'ancienne enveloppe,
        // qui n'ont jamais couvert le contenu réel.
        assertThat(DureeEpreuve.secondesExamenComplet()).isEqualTo(95 * 60);
    }

    @Test
    @DisplayName("Le temps de parole de l'oral est celui des 3 taches du catalogue")
    void tempsDeParoleOral() {
        assertThat(DureeEpreuve.EO_TEMPS_DE_PAROLE_SECONDS).isEqualTo(180 + 210 + 210);
    }

    @Test
    @DisplayName("Le garde-fou de session orale est large et n'est PAS une duree d'examen")
    void gardeFouSessionOrale() {
        // Il doit rester très au-dessus du temps de parole : c'est un garde-fou
        // anti-abus, pas un chrono. Le resserrer réintroduirait par la bande le
        // compte à rebours d'épreuve qu'on vient de supprimer.
        assertThat(DureeEpreuve.EO_GARDE_SESSION_SECONDS)
                .isGreaterThan(6 * DureeEpreuve.EO_TEMPS_DE_PAROLE_SECONDS);
    }

    @Test
    @DisplayName("La grace de soumission est unique pour tout le depot")
    void graceUnique() {
        assertThat(DureeEpreuve.GRACE_SOUMISSION_SECONDS).isEqualTo(60);
    }

    @Test
    @DisplayName("Duree d'un examen QCM par type de question")
    void dureeParQuestionType() {
        assertThat(DureeEpreuve.secondesPourQcm(QuestionType.CO)).isEqualTo(20 * 60);
        assertThat(DureeEpreuve.secondesPourQcm(QuestionType.CO_IMAGE)).isEqualTo(20 * 60);
        assertThat(DureeEpreuve.secondesPourQcm(QuestionType.CE)).isEqualTo(35 * 60);
        assertThat(DureeEpreuve.secondesPourQcm(QuestionType.STRUCTURE)).isEqualTo(20 * 60);
    }

    @Test
    @DisplayName("Un type sans epreuve QCM chronometree est refuse, jamais silencieux")
    void typeSansEpreuveQcm() {
        assertThatThrownBy(() -> DureeEpreuve.secondesPourQcm(QuestionType.CONNAISSANCE))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
