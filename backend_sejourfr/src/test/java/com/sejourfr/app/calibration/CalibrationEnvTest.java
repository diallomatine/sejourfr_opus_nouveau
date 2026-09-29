package com.sejourfr.app.calibration;

import com.sejourfr.app.config.EvaluationConfigFixture;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.service.ProductionRubricsProvider;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * Verifie que l'environnement du banc est COHERENT — jamais qu'il designe tel
 * correcteur.
 *
 * <p>Ce test figeait le provider et le modele actifs. Consequence : revenir a
 * DeepSeek, ou essayer un autre modele, passait le build au rouge alors que rien
 * n'etait casse — l'inverse exact de la regle du projet, ou changer de LLM tient
 * en une ligne de {@code .env} et un redemarrage.
 *
 * <p>Ce qui reste garanti, et qui est le vrai risque : le banc et le runtime
 * lisent la MEME configuration (il n'existe volontairement aucune surcharge
 * {@code calibration.provider}), et cette configuration est utilisable —
 * provider connu, modele nomme, cle presente, paire rubriques ⇄ tool-schema
 * valide. Mesurer un correcteur pour en deployer un autre serait pire que ne
 * rien mesurer.
 */
class CalibrationEnvTest {

    @Test
    void le_provider_du_banc_est_un_provider_que_le_runtime_sait_cabler() {
        ProductionEvaluationProperties props = CalibrationEnv.properties(null, null);

        assertThat(props.getProvider())
            .as("aucun provider resolu : le banc appellerait dans le vide")
            .isNotNull().isNotBlank();
        assertThat(props.getProvider().strip().toLowerCase(java.util.Locale.ROOT))
            .as("provider '%s' inconnu d'EvaluationLlmConfig — le runtime refuserait de "
                + "demarrer, le banc doit refuser de mesurer.", props.getProvider())
            .isIn(EvaluationConfigFixture.PROVIDERS);
    }

    @Test
    void le_bloc_du_provider_actif_est_exploitable() {
        ProductionEvaluationProperties props = CalibrationEnv.properties(null, null);
        EvaluationConfigFixture.BlocProvider bloc = EvaluationConfigFixture.blocActif(props);

        assertThat(bloc.modele())
            .as("provider %s actif sans modele configure", bloc.provider())
            .isNotNull().isNotBlank();
        assertThat(EvaluationConfigFixture.versionPromptActive(props))
            .as("provider %s actif sans version de tool-schema", bloc.provider())
            .isNotNull().isNotBlank();
    }

    @Test
    void la_cle_d_api_du_provider_actif_est_renseignee() {
        // Sans .env local il n'y a pas d'environnement a verifier (clone frais,
        // integration continue) : la question ne se pose pas.
        assumeTrue(EvaluationConfigFixture.dotEnvPresent(),
            "Pas de .env local : aucun environnement d'evaluation a verifier.");

        ProductionEvaluationProperties props = CalibrationEnv.properties(null, null);
        EvaluationConfigFixture.BlocProvider bloc = EvaluationConfigFixture.blocActif(props);

        // On n'observe QUE la presence, jamais la valeur.
        assertThat(bloc.cleRenseignee())
            .as("provider %s actif mais aucune cle d'API : le backend echouerait a la "
                + "premiere correction, et le banc au premier cas.", bloc.provider())
            .isTrue();
    }

    @Test
    void la_paire_rubriques_tool_schema_est_valide() {
        ProductionEvaluationProperties props = CalibrationEnv.properties(null, null);

        assertThat(props.getRubricsVersion()).isNotNull().isNotBlank();

        // Meme chemin qu'au demarrage du backend : le provider charge sa grille
        // et refuse une paire incoherente. On ne dit pas laquelle doit etre
        // active, seulement qu'elle tient debout.
        ProductionRubricsProvider provider = new ProductionRubricsProvider(props, new ObjectMapper());
        assertThatCode(() -> CalibrationEnv.postConstruct(provider, "load"))
            .as("rubriques %s incompatibles avec le tool-schema %s du provider %s",
                props.getRubricsVersion(), EvaluationConfigFixture.versionPromptActive(props),
                props.getProvider())
            .doesNotThrowAnyException();

        assertThat(CalibrationEnv.champsRequis(
            EvaluationConfigFixture.versionPromptActive(props), new ObjectMapper()))
            .as("le tool-schema actif ne declare aucun champ obligatoire")
            .isNotEmpty();
    }
}
