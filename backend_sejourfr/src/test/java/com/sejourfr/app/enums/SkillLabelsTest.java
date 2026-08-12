package com.sejourfr.app.enums;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.LinkedHashMap;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Fige les libelles FR du module « Competences TCF ».
 *
 * <p><b>Pourquoi ce test existe.</b> Ces libelles ne transitent pas par le
 * reseau : chaque front en tient sa propre copie a la main
 * ({@code web_sejoufr/lib/types.ts}, {@code mobile .../core/models/skill_models.dart},
 * {@code admin .../features/skills/skillHelpers.ts}). Rien, dans le compilateur,
 * n'empeche donc une couche de deriver — et c'est arrive : le verdict
 * {@code NOT_VALIDATED} s'affichait « Critère non validé » cote serveur,
 * « Critère non atteint » sur mobile et « Critère à retravailler » sur le web,
 * trois formulations pour un meme etat. La parite web ⇄ mobile est une regle non
 * negociable du projet ; ce test en tient le cote serveur, les tests
 * {@code skill_models_test.dart} (mobile) et {@code lib/skill-labels.test.ts}
 * (web) tiennent les leurs, sur les memes chaines.
 *
 * <p>Un echec ici n'est pas un test a mettre a jour a la legere : c'est le signal
 * qu'un libelle a bouge et que les trois autres copies doivent bouger avec lui,
 * dans la meme passe.
 */
class SkillLabelsTest {

    @Test
    @DisplayName("Verdict de critere : les trois libelles sont geles")
    void verdictsDeCritere() {
        assertThat(labels(SkillCriterionStatus.class, SkillCriterionStatus::getLabel))
                .containsExactly(
                        Map.entry("VALIDATED", "Critère validé"),
                        Map.entry("PARTIAL", "Critère partiellement atteint"),
                        Map.entry("NOT_VALIDATED", "Critère non atteint"));
    }

    @Test
    @DisplayName("Statut d'un sujet : les quatre libelles sont geles")
    void statutsDeSujet() {
        assertThat(labels(SkillPromptStatus.class, SkillPromptStatus::getLabel))
                .containsExactly(
                        Map.entry("TODO", "À faire"),
                        Map.entry("TREATED", "Fait"),
                        Map.entry("VALIDATED", "Validé"),
                        Map.entry("TO_REINFORCE", "À renforcer"));
    }

    /**
     * Etat de maitrise d'une COMPETENCE, a ne pas confondre avec le statut d'un
     * SUJET ci-dessus : « À renforcer » se dit des deux, « En consolidation »
     * n'existe que pour une competence. Ces quatre chaines vont etre recopiees a
     * la main dans les cartes web et mobile, comme toutes les autres de ce
     * fichier — un libelle qui bouge, ce sont les trois copies a changer dans la
     * meme passe.
     */
    @Test
    @DisplayName("Etat de maitrise d'une competence : les quatre libelles sont geles")
    void etatsDeMaitrise() {
        assertThat(labels(SkillMasteryState.class, SkillMasteryState::getLabel))
                .containsExactly(
                        Map.entry("PRIORITY", "Priorité"),
                        Map.entry("TO_REINFORCE", "À renforcer"),
                        Map.entry("CONSOLIDATING", "En consolidation"),
                        Map.entry("SOLID", "Solide"));
    }

    @Test
    @DisplayName("Auto-evaluation : les trois libelles sont geles, a la premiere personne")
    void autoEvaluation() {
        assertThat(labels(SkillSelfEvaluation.class, SkillSelfEvaluation::getLabel))
                .containsExactly(
                        Map.entry("REUSSI", "Je pense avoir réussi"),
                        Map.entry("INCERTAIN", "Je ne suis pas sûr"),
                        Map.entry("DIFFICILE", "J'ai eu du mal"));
    }

    /**
     * Ces trois phrases s'affichent SOUS le niveau, sur la carte de resultat. Ce
     * sont elles qui repondent a « ou j'en suis » — la question qui a fait rendre
     * le niveau CECRL sur cette voie. Aucune ne nomme un manque : le depot a
     * retire le vocabulaire de deficit des cartes de resultat, on ne le
     * reintroduit pas ici.
     */
    @Test
    @DisplayName("Situation par rapport au niveau vise : les trois libelles sont geles")
    void situationParRapportAuNiveauVise() {
        assertThat(labels(SituationNiveauVise.class, SituationNiveauVise::getLabel))
                .containsExactly(
                        Map.entry("OBJECTIF_ATTEINT", "Tu as atteint ton objectif"),
                        Map.entry("PROCHE", "Tu es proche du niveau visé"),
                        Map.entry("EN_CHEMIN", "Encore du chemin vers ton objectif"));
    }

    @Test
    @DisplayName("Difficulte : « Accessible » decrit le sujet, il ne juge pas le candidat")
    void difficulte() {
        assertThat(labels(SkillDifficulty.class, SkillDifficulty::getLabel))
                .containsExactly(
                        Map.entry("EASY", "Accessible"),
                        Map.entry("MEDIUM", "Intermédiaire"),
                        Map.entry("HARD", "Exigeant"));
    }

    @Test
    @DisplayName("Niveaux de reference : libelles et ORDRE d'affichage geles")
    void niveauxDeReference() {
        assertThat(labels(SkillReferenceLevel.class, SkillReferenceLevel::getLabel))
                .containsExactly(
                        Map.entry("INSUFFICIENT", "Insuffisant"),
                        Map.entry("EXPECTED", "Attendu"),
                        Map.entry("EXCELLENT", "Très réussi"));
    }

    @Test
    @DisplayName("Epreuves du module : libelles geles")
    void sections() {
        assertThat(labels(SkillSection.class, SkillSection::getLabel))
                .containsExactly(
                        Map.entry("EE", "Expression écrite"), Map.entry("EO", "Expression orale"));
    }

    /**
     * Les 6 intitules de tache sont recopies dans la console admin
     * ({@code TASK_TITLE}) : ils font partie du meme contrat de libelles.
     */
    @Test
    @DisplayName("Intitules des 6 taches TCF : geles")
    void intitulesDesTaches() {
        assertThat(labels(SkillTaskCode.class, SkillTaskCode::getTitle))
                .containsExactly(
                        Map.entry("EE1", "Écrire un message court"),
                        Map.entry("EE2", "Raconter une expérience"),
                        Map.entry("EE3", "Donner son opinion"),
                        Map.entry("EO1", "Entretien dirigé : parler de soi"),
                        Map.entry("EO2", "Jeu de rôle : demander et obtenir des informations"),
                        Map.entry("EO3", "Exprimer et développer un point de vue"));
    }

    @Test
    @DisplayName("Aucun libelle n'est vide ni doublonne au sein d'un meme enum")
    void libellesNonVidesEtUniques() {
        assertThat(labels(SkillCriterionStatus.class, SkillCriterionStatus::getLabel).values())
                .doesNotHaveDuplicates()
                .allSatisfy(l -> assertThat(l).isNotBlank());
        assertThat(labels(SkillPromptStatus.class, SkillPromptStatus::getLabel).values())
                .doesNotHaveDuplicates()
                .allSatisfy(l -> assertThat(l).isNotBlank());
        assertThat(labels(SkillMasteryState.class, SkillMasteryState::getLabel).values())
                .doesNotHaveDuplicates()
                .allSatisfy(l -> assertThat(l).isNotBlank());
        assertThat(labels(SkillSelfEvaluation.class, SkillSelfEvaluation::getLabel).values())
                .doesNotHaveDuplicates()
                .allSatisfy(l -> assertThat(l).isNotBlank());
        assertThat(labels(SkillDifficulty.class, SkillDifficulty::getLabel).values())
                .doesNotHaveDuplicates()
                .allSatisfy(l -> assertThat(l).isNotBlank());
        assertThat(labels(SkillReferenceLevel.class, SkillReferenceLevel::getLabel).values())
                .doesNotHaveDuplicates()
                .allSatisfy(l -> assertThat(l).isNotBlank());
        assertThat(labels(SituationNiveauVise.class, SituationNiveauVise::getLabel).values())
                .doesNotHaveDuplicates()
                .allSatisfy(l -> assertThat(l).isNotBlank());
    }

    /** Libelles indexes par nom de constante, dans l'ordre de declaration. */
    private static <E extends Enum<E>> Map<String, String> labels(
            Class<E> type, java.util.function.Function<E, String> label) {
        Map<String, String> out = new LinkedHashMap<>();
        for (E value : type.getEnumConstants()) {
            out.put(value.name(), label.apply(value));
        }
        return out;
    }
}
