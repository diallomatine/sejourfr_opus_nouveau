package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Indice de fluidite (debit + pauses longues) : eteint par defaut, purement
 * factuel une fois allume. Cf. {@link ProductionFluiditeService}.
 */
class ProductionFluiditeServiceTest {

    private static final String TRANSCRIPT_60_MOTS = ("mot ".repeat(60)).trim();

    private ProductionEvaluationProperties props;
    private ProductionFluiditeService service;

    @BeforeEach
    void setUp() {
        props = new ProductionEvaluationProperties();
        service = new ProductionFluiditeService(props);
    }

    private static ProductionTask task(EpreuveType epreuve) {
        ProductionTask t = new ProductionTask();
        t.setId(UUID.randomUUID());
        t.setEpreuve(epreuve);
        t.setTacheNumero((short) 1);
        return t;
    }

    private static ProductionSubmission submission(Integer dureeSec) {
        ProductionSubmission s = new ProductionSubmission();
        s.setId(UUID.randomUUID());
        s.setMediaDurationSec(dureeSec);
        return s;
    }

    // ------------------------------------------------------------------ flag

    @Test
    void drapeau_eteint_ne_produit_rien() {
        assertThat(props.getFluidite().isEnabled()).isFalse();
        assertThat(service.indicateurs(submission(120), task(EpreuveType.TCF_EO), TRANSCRIPT_60_MOTS))
            .isNull();
    }

    @Test
    void drapeau_allume_calcule_le_debit() {
        props.getFluidite().setEnabled(true);

        Map<String, Object> out =
            service.indicateurs(submission(120), task(EpreuveType.TCF_EO), TRANSCRIPT_60_MOTS);

        assertThat(out).isNotNull();
        assertThat(out.get("mots")).isEqualTo(60);
        assertThat(out.get("duree_sec")).isEqualTo(120);
        assertThat(out.get("debit_mots_par_minute")).isEqualTo(30); // 60 mots / 2 min
        assertThat(out.get("informatif")).isEqualTo(true);
        assertThat(out.get("mention")).isEqualTo(ProductionFluiditeService.MENTION_INFORMATIVE);
    }

    // ------------------------------------------------------------- garde-fous

    @Test
    void ecrit_jamais_de_fluidite() {
        props.getFluidite().setEnabled(true);
        assertThat(service.indicateurs(submission(120), task(EpreuveType.TCF_EE), TRANSCRIPT_60_MOTS))
            .isNull();
    }

    @Test
    void duree_absente_ou_trop_courte_ne_produit_rien() {
        props.getFluidite().setEnabled(true);
        assertThat(service.indicateurs(submission(null), task(EpreuveType.TCF_EO), TRANSCRIPT_60_MOTS))
            .isNull();
        // duree-min-sec = 20 par defaut
        assertThat(service.indicateurs(submission(5), task(EpreuveType.TCF_EO), TRANSCRIPT_60_MOTS))
            .isNull();
    }

    @Test
    void transcription_vide_ne_produit_rien() {
        props.getFluidite().setEnabled(true);
        assertThat(service.indicateurs(submission(120), task(EpreuveType.TCF_EO), "   ")).isNull();
        assertThat(service.indicateurs(submission(120), task(EpreuveType.TCF_EO), null)).isNull();
    }

    // ----------------------------------------------------------------- pauses

    @Test
    void sans_horodatage_les_pauses_sont_declarees_indisponibles() {
        props.getFluidite().setEnabled(true);

        Map<String, Object> out =
            service.indicateurs(submission(120), task(EpreuveType.TCF_EO), TRANSCRIPT_60_MOTS);

        assertThat(out).containsEntry("pauses_longues", null);
        assertThat(out.get("pauses_raison_indisponible")).asString().contains("horodatages");
    }

    @Test
    void horodatages_exploitables_comptent_les_silences_longs() {
        props.getFluidite().setEnabled(true);
        // Silences : 0.5 s (non compte), 4.0 s (compte), 1.0 s (non compte).
        String transcript = """
            00:00:00,000 --> 00:00:05,000 bonjour je m'appelle Karim
            00:00:05,500 --> 00:00:10,000 je viens du Maroc
            00:00:14,000 --> 00:00:20,000 je travaille comme cuisinier a Lyon
            00:00:21,000 --> 00:00:30,000 et j'aime beaucoup mon metier
            """;

        Map<String, Object> out =
            service.indicateurs(submission(120), task(EpreuveType.TCF_EO), transcript);

        assertThat(out.get("pauses_longues")).isEqualTo(1);
        assertThat((BigDecimal) out.get("pause_la_plus_longue_sec"))
            .isEqualByComparingTo(new BigDecimal("4.0"));
        assertThat(out).doesNotContainKey("pauses_raison_indisponible");
    }

    @Test
    void un_seul_segment_horodate_ne_permet_pas_de_conclure() {
        assertThat(ProductionFluiditeService.compterPausesLongues(
            "00:00:00,000 --> 00:00:05,000 bonjour", 3.0)).isNull();
    }

    @Test
    void seuil_de_pause_configurable() {
        String transcript = "00:00:00,000 --> 00:00:05,000 a\n00:00:07,000 --> 00:00:09,000 b";
        // Silence de 2 s : compte a 1.5 s de seuil, pas a 3 s.
        assertThat(ProductionFluiditeService.compterPausesLongues(transcript, 1.5).nombre()).isEqualTo(1);
        assertThat(ProductionFluiditeService.compterPausesLongues(transcript, 3.0).nombre()).isZero();
    }

    @Test
    void comptage_des_mots_ignore_la_ponctuation() {
        assertThat(ProductionFluiditeService.compterMots("Bonjour, je m'appelle Karim !")).isEqualTo(4);
        assertThat(ProductionFluiditeService.compterMots("  ")).isZero();
        assertThat(ProductionFluiditeService.compterMots(null)).isZero();
    }
}
