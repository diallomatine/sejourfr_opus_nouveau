package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.JsonNode;

import org.springframework.core.io.ClassPathResource;
import org.springframework.util.StreamUtils;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Persona v3 (prompts/realtime-personas-v3.json) : VERROU DE LANGUE.
 *
 * <p><b>Pourquoi cette version.</b> Le transcripteur temps reel est le modele
 * natif-audio de Gemini Live, explicitement concu pour « changer de langue
 * naturellement en cours de conversation ». Sur un passage bruite ou mal
 * articule, il restitue donc la parole du candidat dans une AUTRE LANGUE —
 * arabe, neerlandais, anglais, cyrillique. Mesure en base au 2026-08-07 :
 * 6 transcriptions temps reel sur 39 portent une ecriture non latine, contre
 * <b>0 sur 36</b> cote Whisper asynchrone. Le defaut est donc entierement dans
 * la voie temps reel.
 *
 * <p><b>Pourquoi la persona et pas un parametre d'API.</b> L'API Live ne permet
 * pas d'imposer la langue de la transcription d'entree : le message
 * {@code AudioTranscriptionConfig} n'a aucun champ, et les modeles natif-audio
 * <b>refusent</b> {@code speechConfig.languageCode} (« Unsupported language
 * code »). Poser un code de langue ferait echouer l'emission du token et
 * basculerait silencieusement tout le temps reel en async — une regression. La
 * system instruction verrouillee dans le token est le SEUL levier disponible.
 *
 * <p><b>Ce que ce test garantit</b> : les trois regles de langue sont bien
 * rendues dans le prompt, et <b>tout le reste de la v2 est intact</b> — un
 * ajout, pas une reecriture (meme convention que les rubriques).
 */
class RealtimePersonaV3Test {

    private static RealtimePersonaBuilder builder(String version) {
        RealtimeProperties props = new RealtimeProperties();
        props.setPersonaVersion(version);
        RealtimePersonaTemplates templates = new RealtimePersonaTemplates(props, new ObjectMapper());
        templates.load();
        return new RealtimePersonaBuilder(templates);
    }

    private static ProductionTask task(short tache) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(EpreuveType.TCF_EO);
        t.setTacheNumero(tache);
        t.setDureeMaxSec(210);
        t.setNiveauCible("B1");
        t.setContexte("L'examinateur joue le conseiller du service après-vente.");
        t.setConsigne("Vous appelez le service après-vente.");
        return t;
    }

    private static List<String> regles(String version) {
        String path = "prompts/realtime-personas-" + version + ".json";
        try (InputStream is = new ClassPathResource(path).getInputStream()) {
            JsonNode root = new ObjectMapper().readTree(
                    StreamUtils.copyToString(is, StandardCharsets.UTF_8));
            List<String> out = new ArrayList<>();
            root.get("regles").forEach(n -> out.add(n.asString()));
            return out;
        } catch (Exception e) {
            throw new IllegalStateException(path, e);
        }
    }

    @Test
    void v3_declareLeVerrouDeLangue() {
        String out = builder("v3").build(task((short) 1));

        assertThat(out)
                .contains("LANGUE DE L'ÉCHANGE")
                .contains("INTÉGRALEMENT en français")
                .contains("N'INTERPRÈTE JAMAIS ce que tu entends comme une autre langue")
                .contains("Ne restitue jamais de la parole du candidat dans une autre écriture que l'alphabet latin")
                .contains("Ne bascule JAMAIS vers une autre langue");
    }

    @Test
    void v3_nommeLesLanguesReellementObservees() {
        // Les quatre langues effectivement remontees par les evaluations reelles.
        // Les nommer vaut mieux qu'une formule abstraite : c'est ce que le modele
        // produisait.
        assertThat(builder("v3").build(task((short) 1)))
                .contains("arabe")
                .contains("anglais")
                .contains("russe")
                .contains("néerlandais");
    }

    @Test
    void v3_impute_lIncomprehension_a_la_captation_jamais_au_candidat() {
        // Le candidat passe un examen DE francais : ce qu'il prononce est du
        // francais. C'est la premisse qui doit fermer la porte a la bascule.
        assertThat(builder("v3").build(task((short) 1)))
                .contains("apprenant qui passe un examen DE FRANÇAIS")
                .contains("mal prononcé, mal articulé ou mal capté")
                .contains("demande simplement de répéter, en français");
    }

    @Test
    void v3_estUnAjout_toutesLesReglesV2SontConservees() {
        // On versionne, on ne reecrit pas : chaque regle de la v2 doit se
        // retrouver TELLE QUELLE en v3.
        assertThat(regles("v3")).containsAll(regles("v2"));
        assertThat(regles("v3")).hasSize(regles("v2").size() + 3);
    }

    @Test
    void v3_neTouchePasAuxGabaritsDeTache() {
        // t1, t2, t2Fiche et relations sont identiques au caractere pres :
        // la v3 ne parle QUE de la langue de l'echange.
        RealtimeProperties p2 = new RealtimeProperties();
        p2.setPersonaVersion("v2");
        RealtimePersonaTemplates t2 = new RealtimePersonaTemplates(p2, new ObjectMapper());
        t2.load();

        RealtimeProperties p3 = new RealtimeProperties();
        p3.setPersonaVersion("v3");
        RealtimePersonaTemplates t3 = new RealtimePersonaTemplates(p3, new ObjectMapper());
        t3.load();

        assertThat(t3.t1()).isEqualTo(t2.t1());
        assertThat(t3.t2()).isEqualTo(t2.t2());
        assertThat(t3.t2Fiche()).isEqualTo(t2.t2Fiche());
        assertThat(t3.relations()).isEqualTo(t2.relations());
    }

    @Test
    void v3_conserveLesGarantiesDeConduiteDeLaV2() {
        String out = builder("v3").build(task((short) 2));

        assertThat(out)
                .contains("RÈGLES ABSOLUES")
                .contains("TU RÉPONDS, tu ne mènes pas")
                .contains("Ne corrige JAMAIS la langue du candidat")
                .contains("N'ORIENTE JAMAIS le candidat vers les questions attendues du sujet")
                .contains("Voici la deuxième partie");
    }

    @Test
    void v3_estLaVersionParDefautDuRuntime() {
        // Le defaut d'application.yaml. Si quelqu'un revient a v2, ce test
        // n'echoue pas (c'est une variable d'env) — il documente l'intention
        // livree et casse si le fichier v3 disparait du classpath.
        assertThat(builder("v3").build(task((short) 1))).isNotBlank();
    }
}
