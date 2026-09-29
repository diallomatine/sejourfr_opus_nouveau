package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.enums.CivicExamFormat;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La projection d'un diagnostic sur l'échelle de l'examen réel (20_ §4.4).
 *
 * <p>🛑 Elle est calculée **côté serveur** et nulle part ailleurs : ni écrite en
 * dur dans une maquette, ni recalculée par un front. Deux calculs de la même
 * chose finissent par afficher deux nombres.
 */
class CivicExamFormatTest {

    @Test
    @DisplayName("L'exemple de la spec : 18 / 24 → 30 / 40")
    void exempleDeLaSpec() {
        assertThat(CivicExamFormat.projection(18, 24)).isEqualTo(30);
    }

    @Test
    @DisplayName("🛑 Aucune question posée ⇒ null, jamais 0 sur 40")
    void aucuneQuestionPoseeNeDonnePasZero() {
        // « On n'a rien mesuré » ne se dit pas « vous auriez 0 sur 40 ».
        assertThat(CivicExamFormat.projection(0, 0)).isNull();
    }

    @Test
    @DisplayName("Le format officiel est du code, pas un réglage")
    void formatOfficiel() {
        // Arrêté du 10 octobre 2025, art. 3 : QCM de 40 questions, 45 min,
        // seuil de 80 %. Ces trois valeurs ne sont pas des paramètres produit.
        assertThat(CivicExamFormat.QUESTIONS).isEqualTo(40);
        assertThat(CivicExamFormat.SEUIL_REUSSITE).isEqualTo(32);
        assertThat(CivicExamFormat.DUREE_SECONDES).isEqualTo(45 * 60);
    }

    @Test
    @DisplayName("🛑 Le partage officiel : 28 connaissances + 12 mises en situation = 40")
    void partageOfficiel() {
        // Annexe I de l'arrêté. 🛑 Les 12 mises en situation ne sont PAS
        // réparties sur les cinq thématiques : 6 en « Principes et valeurs »,
        // 6 en « Droits et devoirs », aucune ailleurs. Où elles tombent relève
        // du quota par unité, donc de la table des 16 — pas de cette classe.
        assertThat(CivicExamFormat.CONNAISSANCES).isEqualTo(28);
        assertThat(CivicExamFormat.MISES_EN_SITUATION).isEqualTo(12);
        assertThat(CivicExamFormat.CONNAISSANCES + CivicExamFormat.MISES_EN_SITUATION)
                .isEqualTo(CivicExamFormat.QUESTIONS);
    }

    @Test
    @DisplayName("L'examen de thème est un format SejourFR, et il a enfin une autorité")
    void formatDeTheme() {
        // 20 / 16 / 20 min ont vécu en constantes privées d'AttemptService, et
        // le seuil en littéral dans MeService. Le cycle en fait sa clôture de
        // bloc : il lui fallait une autorité.
        assertThat(CivicExamFormat.QUESTIONS_THEME).isEqualTo(20);
        assertThat(CivicExamFormat.SEUIL_REUSSITE_THEME).isEqualTo(16);
        assertThat(CivicExamFormat.DUREE_THEME_SECONDES).isEqualTo(20 * 60);
    }

    @Test
    @DisplayName("🛑 Les invariants du format tiennent — les deux seuils sont bien à 80 %")
    void invariants() {
        // Une constante corrigée à moitié casse ce test, pas la production.
        CivicExamFormat.assertionsDeFormat();
    }

    @Test
    @DisplayName("🛑 Aucun quota par unité ni total par thématique n'est déclaré ici (D-38)")
    void aucunQuotaParUnite() throws Exception {
        // Le quota par unité vit dans la table des 16 unités officielles, et les
        // totaux par thématique (11/6/11/8/4) NULLE PART -- ils se dérivent par
        // somme. Ce test échoue si quelqu'un les ramène ici : ce serait une 2ᵉ
        // copie, et un jour l'une des deux aurait tort.
        final var declarees = java.util.Arrays.stream(CivicExamFormat.class.getDeclaredFields())
                .filter(f -> java.lang.reflect.Modifier.isStatic(f.getModifiers()))
                .map(java.lang.reflect.Field::getName)
                .toList();
        assertThat(declarees).containsExactlyInAnyOrder(
                "QUESTIONS", "SEUIL_REUSSITE", "DUREE_SECONDES",
                "CONNAISSANCES", "MISES_EN_SITUATION",
                "QUESTIONS_THEME", "SEUIL_REUSSITE_THEME", "DUREE_THEME_SECONDES");
    }

    @Test
    @DisplayName("Tout raté projette 0 — et c'est une vraie mesure, elle")
    void toutRate() {
        assertThat(CivicExamFormat.projection(0, 24)).isZero();
    }
}
