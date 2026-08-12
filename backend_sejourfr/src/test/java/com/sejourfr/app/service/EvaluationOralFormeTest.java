package com.sejourfr.app.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LA RÈGLE ORALE PARTAGÉE : « une faute est une STRUCTURE, jamais la forme d'un
 * mot ».
 *
 * <p>Elle sert deux surfaces — le volet FORME du filet de restitution
 * ({@code EvaluationOralArtifactFilter}) et les reformulations du second appel
 * ({@code VersionCibleeReformulationFilter}). Ce test la fige une fois, là où
 * elle vit.
 */
class EvaluationOralFormeTest {

    // -------------------------------------------------- le passage cité (volet FORME)

    @Test
    void unPassageDUnOuDeuxMotsPleins_nommeUneForme() {
        assertThat(EvaluationOralForme.nommeUneFormeIsolee("abit")).isTrue();
        assertThat(EvaluationOralForme.nommeUneFormeIsolee("abit à Lille")).isTrue();
    }

    /**
     * ZÉRO mot plein — une citation faite uniquement de mots-outils — est une
     * STRUCTURE pure (« pour ne pas que »), pas une forme. Le resserrement du
     * 2026-08-09 : elle était purgée par inadvertance.
     */
    @Test
    void unPassageSansAucunMotPlein_estUneStructurePure() {
        assertThat(EvaluationOralForme.nommeUneFormeIsolee("pour ne pas que")).isFalse();
    }

    @Test
    void unPassageDeTroisMotsPleins_decritUneStructure() {
        assertThat(EvaluationOralForme.nommeUneFormeIsolee("je suis des nationalites gueneennes"))
            .isFalse();
    }

    @Test
    void leSeuilEstFigeATrois() {
        assertThat(EvaluationOralForme.MOTS_PORTEURS_STRUCTURE_MIN).isEqualTo(3);
        assertThat(EvaluationOralForme.estFormeIsolee(0)).isFalse();
        assertThat(EvaluationOralForme.estFormeIsolee(1)).isTrue();
        assertThat(EvaluationOralForme.estFormeIsolee(2)).isTrue();
        assertThat(EvaluationOralForme.estFormeIsolee(3)).isFalse();
    }

    // ------------------------------------------ la reformulation (second appel)

    /**
     * LE CAS RÉEL du 2026-08-08 : le candidat avait dit « j'habite à Lille », la
     * machine a écrit « abit ». Une reformulation qui ne remet que ce mot en
     * place ne corrige pas le candidat, elle corrige NOTRE transcription.
     */
    @Test
    @DisplayName("RÉEL : « abit à Lille » → « habite à Lille » ne change qu'une forme")
    void remplacerUnMotSurPlace_estUneReparationDeForme() {
        int remplaces = EvaluationOralForme.motsPorteursRemplacesEnPlace(
            "Je abit à Lille depuis trois ans.", "Je habite à Lille depuis trois ans.");

        assertThat(remplaces).isEqualTo(1);
        assertThat(EvaluationOralForme.estFormeIsolee(remplaces)).isTrue();
    }

    /**
     * LE FAUX POSITIF À NE JAMAIS PRODUIRE. Subordonner déplace les mots : c'est
     * exactement la montée de niveau qu'on veut conserver. Comparer des ENSEMBLES
     * de mots aurait vu ici « un connecteur échangé », donc une forme.
     */
    @Test
    void subordonner_deplaceLesMots_doncNEstPasUneReparationDeForme() {
        int remplaces = EvaluationOralForme.motsPorteursRemplacesEnPlace(
            "Je veux mettre mon vélo en bas parce que je viens d'arriver.",
            "Puisque je viens d'arriver, je veux mettre mon vélo en bas.");

        assertThat(EvaluationOralForme.estFormeIsolee(remplaces)).isFalse();
    }

    /** Une phrase refaite n'a plus la même longueur : rien n'est purgé. */
    @Test
    void refaireLaPhrase_nEstJamaisUneReparationDeForme() {
        int remplaces = EvaluationOralForme.motsPorteursRemplacesEnPlace(
            "Et je fais comment pour avoir le badge, c'est vous qui donnez ?",
            "Pourriez-vous me dire à qui je dois m'adresser pour obtenir ce badge ?");

        assertThat(remplaces).isZero();
        assertThat(EvaluationOralForme.estFormeIsolee(remplaces)).isFalse();
    }

    /** Ni original ni reformulation exploitables : en cas de doute, on ne purge pas. */
    @Test
    void sansMotPlein_onNeConclutRien() {
        assertThat(EvaluationOralForme.motsPorteursRemplacesEnPlace("", "Peu importe.")).isZero();
        assertThat(EvaluationOralForme.motsPorteursRemplacesEnPlace("je le lui ai", "je le lui ai"))
            .isZero();
    }
}
