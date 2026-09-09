package com.sejourfr.app.service;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.service.ProgressionPlanBridge;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>Le palier qu'un domaine construit</b> — une seule autorite, deux
 * implementations.
 *
 * <p>Ce qui est verrouille ici : le palier se lit sur le niveau <b>du
 * domaine</b>, jamais sur le plancher global ; le pont du moteur V4.2 passe
 * <b>avant</b> le repli ; et on ne saute ni ne depasse jamais un palier.
 */
class PlanDomainTargetLevelResolverTest {

    private static final UUID USER = UUID.randomUUID();

    private ProgressionPlanBridge bridge;
    private PlanDomainTargetLevelResolver resolver;

    @BeforeEach
    void setUp() {
        bridge = mock(ProgressionPlanBridge.class);
        when(bridge.prescriptionLevel(any(), any(), any())).thenReturn(Optional.empty());
        resolver = new PlanDomainTargetLevelResolver(bridge);
    }

    /**
     * 🛑 LE CORRECTIF : deux domaines, deux niveaux, <b>deux paliers</b>. Avant
     * le 2026-08-26 les deux construisaient le meme (le cran au-dessus du
     * plancher global), et l'oral n'avait rien a faire.
     */
    @Test
    @DisplayName("Chaque domaine construit le cran au-dessus de SON niveau")
    void chaqueDomaineConstruitLeCranAuDessusDeSonNiveau() {
        assertThat(resolver.pour(USER, SkillSection.EE, NiveauCecrl.A2, TargetLevel.B2))
                .isEqualTo(TargetLevel.B1);
        assertThat(resolver.pour(USER, SkillSection.EO, NiveauCecrl.B1, TargetLevel.B2))
                .isEqualTo(TargetLevel.B2);
    }

    /** On ne saute jamais un palier : A2 vers B2 passe par B1. */
    @Test
    @DisplayName("Un palier ne se saute jamais")
    void unPalierNeSeSauteJamais() {
        assertThat(PlanDomainTargetLevelResolver.suivant(NiveauCecrl.A1, TargetLevel.B2))
                .isEqualTo(TargetLevel.A2);
        assertThat(PlanDomainTargetLevelResolver.suivant(NiveauCecrl.A2, TargetLevel.B2))
                .isEqualTo(TargetLevel.B1);
    }

    /** On ne propose jamais plus haut que ce dont le candidat a besoin. */
    @Test
    @DisplayName("Le palier est plafonne par l'objectif")
    void lePalierEstPlafonneParLObjectif() {
        assertThat(PlanDomainTargetLevelResolver.suivant(NiveauCecrl.A2, TargetLevel.B1))
                .isEqualTo(TargetLevel.B1);
        assertThat(PlanDomainTargetLevelResolver.suivant(NiveauCecrl.B1, TargetLevel.B1))
                .as("objectif atteint localement : plus rien a acquerir")
                .isNull();
    }

    /**
     * 🛑 Un domaine <b>a</b> ou <b>au-dessus</b> de l'objectif ne recoit aucune
     * acquisition — il s'entretient. {@code null} n'est pas un defaut, c'est
     * « plus rien a apprendre ici ».
     */
    @Test
    @DisplayName("Un domaine a l'objectif n'a plus de palier a construire")
    void unDomaineALObjectifNaPlusDePalier() {
        assertThat(resolver.pour(USER, SkillSection.EO, NiveauCecrl.B2, TargetLevel.B2)).isNull();
    }

    /**
     * Sans mesure, on commence par le bas — on ne <b>suppose</b> jamais un
     * niveau. (Le selecteur, lui, ecarte de toute facon les domaines non
     * mesures : ils se mesurent avant de s'apprendre.)
     */
    @Test
    @DisplayName("Sans niveau mesure, le palier est A2")
    void sansNiveauMesureLePalierEstA2() {
        assertThat(resolver.pour(USER, SkillSection.CO, null, TargetLevel.B2))
                .isEqualTo(TargetLevel.A2);
    }

    /** Sans objectif declare, on ne devine pas une demarche a sa place. */
    @Test
    @DisplayName("Sans objectif, aucun palier")
    void sansObjectifAucunPalier() {
        assertThat(resolver.pour(USER, SkillSection.EE, NiveauCecrl.A2, null)).isNull();
    }

    /**
     * 🛑 <b>Le pont passe AVANT le repli.</b> C'est ce qui garantit qu'il n'y a
     * qu'une autorite : le jour ou le moteur V4.2 passe en {@code ACTIVE}, c'est
     * lui qui decide, sans qu'une ligne du Plan ne change.
     */
    @Test
    @DisplayName("Le moteur V4.2 a la main quand il repond")
    void leMoteurALaMainQuandIlRepond() {
        when(bridge.prescriptionLevel(USER, SkillSection.CO, TargetLevel.B2))
                .thenReturn(Optional.of(TargetLevel.A2));

        assertThat(resolver.pour(USER, SkillSection.CO, NiveauCecrl.B1, TargetLevel.B2))
                .as("le repli aurait dit B2 ; le moteur dit A2, et c'est lui qui fait foi")
                .isEqualTo(TargetLevel.A2);
    }

    /** Le pont est interroge a chaque fois : la couture n'est pas conditionnelle. */
    @Test
    @DisplayName("Le pont est toujours interroge")
    void lePontEstToujoursInterroge() {
        resolver.pour(USER, SkillSection.EE, NiveauCecrl.A2, TargetLevel.B2);

        verify(bridge).prescriptionLevel(USER, SkillSection.EE, TargetLevel.B2);
    }
}
