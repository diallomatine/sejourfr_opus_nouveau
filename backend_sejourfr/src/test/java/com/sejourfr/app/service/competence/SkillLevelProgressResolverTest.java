package com.sejourfr.app.service.competence;

import com.sejourfr.app.dto.SkillLevelProgressDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SituationNiveauVise;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le DERIVE SERVEUR « ou en est le candidat par rapport a son objectif ».
 *
 * <p>Ce que cette classe verrouille : les <b>trois libelles geles</b> (recopies
 * a la main sur le web et le mobile), la regle « la demarche fait plancher », et
 * la jauge — dont aucun front ne doit deviner ni l'echelle ni la position du
 * curseur.
 */
class SkillLevelProgressResolverTest {

    // -------------------------------------------------- les trois libelles

    @Test
    void objectifAtteintQuandLeNiveauEgaleLeVise() {
        SkillLevelProgressDto p = SkillLevelProgressResolver.resolve(NiveauCecrl.B1, TargetLevel.B1);

        assertThat(p.situation()).isEqualTo(SituationNiveauVise.OBJECTIF_ATTEINT);
        assertThat(p.situationLabel()).isEqualTo("Tu as atteint ton objectif");
    }

    @Test
    void objectifAtteintQuandLeNiveauDepasseLeVise() {
        // Depasser son objectif reste une victoire : on ne cherche pas a
        // relativiser, et le curseur reste au bout de la barre.
        SkillLevelProgressDto p = SkillLevelProgressResolver.resolve(NiveauCecrl.B2, TargetLevel.A2);

        assertThat(p.situation()).isEqualTo(SituationNiveauVise.OBJECTIF_ATTEINT);
        assertThat(p.cursorIndex()).isEqualTo(2);
    }

    @Test
    void procheQuandIlManqueExactementUnPalier() {
        SkillLevelProgressDto p = SkillLevelProgressResolver.resolve(NiveauCecrl.B1, TargetLevel.B2);

        assertThat(p.situation()).isEqualTo(SituationNiveauVise.PROCHE);
        assertThat(p.situationLabel()).isEqualTo("Tu es proche du niveau visé");
        assertThat(p.cursorIndex()).isEqualTo(1);
    }

    @Test
    void enCheminQuandIlManqueDeuxPaliersOuPlus() {
        SkillLevelProgressDto p = SkillLevelProgressResolver.resolve(NiveauCecrl.A2, TargetLevel.B2);

        assertThat(p.situation()).isEqualTo(SituationNiveauVise.EN_CHEMIN);
        assertThat(p.situationLabel()).isEqualTo("Encore du chemin vers ton objectif");
        assertThat(p.cursorIndex()).isZero();
    }

    /**
     * A1_NON_ATTEINT est le plancher de l'echelle. Il tombe hors de la jauge des
     * qu'on vise B1 ou plus : le curseur est ramene au premier cran, et la phrase
     * au-dessus dit deja la verite. Aucun front n'a a inventer ce comportement.
     */
    @Test
    void unNiveauSousLePremierCranEstRameneAuPremier() {
        SkillLevelProgressDto p =
            SkillLevelProgressResolver.resolve(NiveauCecrl.A1_NON_ATTEINT, TargetLevel.B2);

        assertThat(p.scale()).containsExactly(NiveauCecrl.A2, NiveauCecrl.B1, NiveauCecrl.B2);
        assertThat(p.cursorIndex()).isZero();
        assertThat(p.situation()).isEqualTo(SituationNiveauVise.EN_CHEMIN);
    }

    // ------------------------------------------------------------- la jauge

    @Test
    void laJaugeCompteTroisCransEtSeTermineSurLObjectif() {
        assertThat(SkillLevelProgressResolver.resolve(NiveauCecrl.A2, TargetLevel.B2).scale())
            .containsExactly(NiveauCecrl.A2, NiveauCecrl.B1, NiveauCecrl.B2);
        assertThat(SkillLevelProgressResolver.resolve(NiveauCecrl.A1, TargetLevel.B1).scale())
            .containsExactly(NiveauCecrl.A1, NiveauCecrl.A2, NiveauCecrl.B1);
        // Viser A2 descend jusqu'au plancher : trois crans quand meme, jamais une
        // echelle tronquee que le front devrait completer.
        assertThat(SkillLevelProgressResolver.resolve(NiveauCecrl.A1, TargetLevel.A2).scale())
            .containsExactly(NiveauCecrl.A1_NON_ATTEINT, NiveauCecrl.A1, NiveauCecrl.A2);
    }

    // ------------------------------------------------------- le palier vise

    /**
     * LA REGLE QUI NE SE REECRIT NULLE PART : la demarche fait plancher. Un
     * candidat NAT portant un {@code targetLevel} herite a B1 vise le B2 — c'est
     * exactement le couple qui, ailleurs, avait fait feliciter un candidat d'avoir
     * « atteint son objectif » a B1.
     */
    @Test
    void laDemarcheFaitPlancherSurLeNiveauDeclare() {
        SkillLevelProgressDto p = SkillLevelProgressResolver.resolve(
            NiveauCecrl.B1, user(TargetProcedure.NAT, TargetLevel.B1), skill("A2"));

        assertThat(p.targetLevel()).isEqualTo(TargetLevel.B2);
        assertThat(p.situation()).isEqualTo(SituationNiveauVise.PROCHE);
    }

    @Test
    void viserPlusHautQueSaDemarcheEstRespecte() {
        SkillLevelProgressDto p = SkillLevelProgressResolver.resolve(
            NiveauCecrl.B1, user(TargetProcedure.CSP, TargetLevel.B2), skill("A2"));

        assertThat(p.targetLevel()).isEqualTo(TargetLevel.B2);
    }

    @Test
    void sansDemarcheNiPalierDeclareLeReplietEstLeNiveauDeLaCompetence() {
        SkillLevelProgressDto p = SkillLevelProgressResolver.resolve(
            NiveauCecrl.A1, user(null, null), skill("B1"));

        assertThat(p.targetLevel()).isEqualTo(TargetLevel.B1);
        assertThat(p.situation()).isEqualTo(SituationNiveauVise.EN_CHEMIN);
    }

    // --------------------------------------------------- quand il n'y a rien

    @Test
    void sansNiveauConstateIlNYARienASituer() {
        // Analyse produite par un contrat anterieur a v3 : aucun niveau persiste.
        assertThat(SkillLevelProgressResolver.resolve(null, TargetLevel.B2)).isNull();
        assertThat(SkillLevelProgressResolver.resolve(
            null, user(TargetProcedure.NAT, null), skill("A2"))).isNull();
    }

    @Test
    void sansObjectifLisibleAucuneJaugeNEstRendue() {
        // Le referentiel des competences descend jusqu'a A1, que TargetLevel ne
        // connait pas : ce n'est pas une anomalie, il n'y a simplement pas
        // d'objectif a afficher.
        assertThat(SkillLevelProgressResolver.resolve(
            NiveauCecrl.A1, user(null, null), skill("A1"))).isNull();
        assertThat(SkillLevelProgressResolver.resolve(
            NiveauCecrl.A1, null, null)).isNull();
    }

    private static User user(TargetProcedure procedure, TargetLevel declare) {
        User user = new User();
        user.setId(UUID.randomUUID());
        user.setTargetProcedure(procedure);
        user.setTargetLevel(declare);
        return user;
    }

    private static Skill skill(String targetLevel) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setTargetLevel(targetLevel);
        return skill;
    }
}
