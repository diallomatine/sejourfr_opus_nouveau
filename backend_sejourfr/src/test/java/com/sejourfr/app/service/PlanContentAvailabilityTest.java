package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <b>Une action n'existe que si elle est executable.</b>
 *
 * <p>Deux branches, et il ne faut pas les confondre : l'expression se joue sur
 * un <b>petit sujet publie</b>, la comprehension sur un <b>stock de questions au
 * palier</b> — la serie ciblee ne choisit son contenu qu'au demarrage de la
 * session.
 */
class PlanContentAvailabilityTest {

    private final Skill avecSujets = skill("EE1-C1", SkillSection.EE, "B1");
    private final Skill sansSujet = skill("EE2-C1", SkillSection.EE, "B1");
    private final Skill comprehension = skill("CO-B1", SkillSection.CO, "B1");

    private final PlanContentAvailability.Disponibilite catalogue =
            new PlanContentAvailability.Catalogue(
                    Set.of(avecSujets.getId()),
                    Map.of(QuestionType.CO, Map.of(Difficulty.B1, 42L)));

    @Test
    @DisplayName("Une competence d'expression sans sujet publie n'est pas executable")
    void uneCompetenceDExpressionSansSujetNestPasExecutable() {
        assertThat(catalogue.estExecutable(avecSujets, TargetLevel.B1)).isTrue();
        assertThat(catalogue.estExecutable(sansSujet, TargetLevel.B1)).isFalse();
    }

    /**
     * 🛑 En comprehension, ce qu'on verifie est le <b>stock au palier</b> :
     * demander une serie B2 quand aucune question B2 n'est publiee donnerait un
     * ecran vide au demarrage de la session, pas une carte inutile.
     */
    @Test
    @DisplayName("Une serie ciblee sans question a ce palier n'est pas executable")
    void uneSerieCibleeSansQuestionNestPasExecutable() {
        assertThat(catalogue.estExecutable(comprehension, TargetLevel.B1)).isTrue();
        assertThat(catalogue.estExecutable(comprehension, TargetLevel.B2))
                .as("aucune question B2 en stock")
                .isFalse();
    }

    /**
     * 🛑 Une competence de comprehension <b>sans palier</b> n'est pas
     * executable : on ne sait pas dans quel stock la serie tirerait. C'est le
     * defaut qui, une fois, a fait disparaitre des fragilites CO reelles du
     * Plan — le palier doit toujours etre fourni.
     */
    @Test
    @DisplayName("Sans palier, une competence de comprehension n'est pas executable")
    void sansPalierUneCompetenceDeComprehensionNestPasExecutable() {
        assertThat(catalogue.estExecutable(comprehension, null)).isFalse();
    }

    /** Le filtre ecarte, et ne reordonne jamais ce qu'il garde. */
    @Test
    @DisplayName("Le filtre ecarte sans reordonner")
    void leFiltreEcarteSansReordonner() {
        List<Skill> executables = catalogue.filtrer(
                List.of(sansSujet, avecSujets), Map.of());

        assertThat(executables).containsExactly(avecSujets);
    }

    private static Skill skill(String code, SkillSection section, String palier) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setSection(section);
        skill.setTargetLevel(palier);
        return skill;
    }
}
