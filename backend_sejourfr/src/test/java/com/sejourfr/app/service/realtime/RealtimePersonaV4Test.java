package com.sejourfr.app.service.realtime;

import com.sejourfr.app.config.RealtimeProperties;
import com.sejourfr.app.entity.AgentRoleCard;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.AgentInfoImportance;
import com.sejourfr.app.enums.AgentRelation;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Persona v4 (prompts/realtime-personas-v4.json, chantier examinateur IA, lot 1) :
 * temps de parole, neutralité, cas prévus avec leur phrase, messages de
 * l'application entre crochets, ouvertures courtes, T2 non passive.
 *
 * <p>Ce que ce test garantit : l'assemblage ne laisse aucun placeholder, l'en-tête
 * « Voici la deuxième partie » n'existe qu'en examen blanc, l'ouverture T1 tient
 * en 25 mots, le verrou de langue de la v3 est repris mot pour mot (à la seule
 * phrase près que le brief retire), et les versions v1 à v3 restent intactes.
 */
class RealtimePersonaV4Test {

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{[a-zA-Z]+}");

    private static RealtimePersonaBuilder builder(String version) {
        RealtimeProperties props = new RealtimeProperties();
        props.setPersonaVersion(version);
        RealtimePersonaTemplates templates = new RealtimePersonaTemplates(props, new ObjectMapper());
        templates.load();
        return new RealtimePersonaBuilder(templates);
    }

    private static ProductionTask task(short tache, AgentRoleCard card) {
        ProductionTask t = new ProductionTask();
        t.setEpreuve(EpreuveType.TCF_EO);
        t.setTacheNumero(tache);
        t.setDureeMaxSec(tache == 1 ? 180 : 210);
        t.setNiveauCible("B1");
        t.setContexte("Tu es conseiller du service après-vente.");
        t.setConsigne("Vous appelez le service après-vente pour une réparation.");
        t.setAgentRoleCard(card);
        return t;
    }

    private static AgentRoleCard card() {
        return new AgentRoleCard(
                "Conseiller du service après-vente",
                AgentRelation.INCONNU_VOUVOIEMENT,
                "Obtenir une réparation et négocier un délai.",
                "Service après-vente, bonjour, que puis-je pour vous ?",
                List.of(new AgentRoleCard.Info("delai", "Le délai de réparation est de trois semaines.",
                        AgentInfoImportance.HAUTE)),
                List.of(),
                List.of("Tu proposes d'abord la réparation."));
    }

    static int mots(String texte) {
        return texte.isBlank() ? 0 : texte.strip().split("\\s+").length;
    }

    /** Ouverture T2 telle que le candidat l'entend : en-tête éventuel + réplique d'entrée + « Je vous écoute. ». */
    static int motsOuvertureT2(String phraseOuverture, boolean examenBlanc) {
        return (examenBlanc ? mots("Voici la deuxième partie.") : 0) + mots(phraseOuverture) + mots("Je vous écoute.");
    }

    private static JsonNode json(String version) throws IOException {
        return new ObjectMapper().readTree(
                new ClassPathResource("prompts/realtime-personas-" + version + ".json").getInputStream());
    }

    @Test
    void aucun_placeholder_residuel_en_t1_et_en_t2_examen_ou_entrainement() {
        RealtimePersonaBuilder v4 = builder("v4");
        for (String out : List.of(
                v4.build(task((short) 1, null), false),
                v4.build(task((short) 1, null), true),
                v4.build(task((short) 2, card()), false),
                v4.build(task((short) 2, card()), true),
                v4.build(task((short) 2, null), true))) {
            assertThat(PLACEHOLDER.matcher(out).find()).as(out).isFalse();
        }
    }

    @Test
    void l_ouverture_t1_est_imposee_et_tient_en_25_mots() {
        String out = builder("v4").build(task((short) 1, null));

        Matcher m = Pattern.compile("Ouverture, mot pour mot : « (.+?) »").matcher(out);
        assertThat(m.find()).isTrue();
        assertThat(m.group(1)).isEqualTo(
                "Bonjour. Nous commençons la première partie. Pouvez-vous vous présenter, s'il vous plaît ?");
        assertThat(mots(m.group(1))).isLessThanOrEqualTo(25);
        assertThat(out).contains("environ 180 secondes");
    }

    @Test
    void l_entete_de_la_t2_n_existe_qu_en_examen_blanc() {
        RealtimePersonaBuilder v4 = builder("v4");

        String examen = v4.build(task((short) 2, card()), true);
        String entrainement = v4.build(task((short) 2, card()), false);

        assertThat(examen).contains("« Voici la deuxième partie. »");
        assertThat(entrainement).doesNotContain("deuxième partie");
        assertThat(entrainement).contains("Entre dans ton rôle avec ta réplique d'entrée");
        assertThat(examen).contains("« Service après-vente, bonjour, que puis-je pour vous ? »");
        // La fiche ne fait plus relire le cadre.
        assertThat(examen).doesNotContain("une fois le cadre annoncé").doesNotContain("Posez-moi vos questions");
        assertThat(motsOuvertureT2("Service après-vente, bonjour, que puis-je pour vous ?", true))
                .isLessThanOrEqualTo(35);
    }

    @Test
    void la_t2_n_est_plus_passive_mais_ne_souffle_pas() {
        String out = builder("v4").build(task((short) 2, card()), false);

        assertThat(out)
                .contains("Mais tu n'es PAS passif")
                .contains("Une seule aide de ce type par blocage")
                .contains("INTERDIT : nommer une information de ta fiche qu'il n'a pas demandée")
                .contains("SITUATION DU CANDIDAT (elle est affichée à son écran, ne la lis pas)")
                .doesNotContain("tu ne mènes pas")
                .doesNotContain("ne prends jamais l'initiative");
    }

    @Test
    void les_regles_portent_neutralite_cas_prevus_et_messages_entre_crochets() {
        String out = builder("v4").build(task((short) 1, null));

        assertThat(out)
                .contains("Chaque réplique : une phrase, deux au maximum. Une seule question à la fois.")
                .contains("Ne commente pas ce que le candidat vient de dire.")
                .contains("« D'accord. », « Je vois. », « Hm hm. »")
                .contains("INTERDITS : « très bien », « bravo », « parfait », « excellent », « super », « intéressant », « beau projet »")
                .contains("« Je ne peux pas vous le dire pendant l'épreuve. »")
                .contains("« Dites-le avec vos mots. »")
                .contains("« En français, s'il vous plaît. »")
                .contains("« Ici, c'est votre avis qui compte. »")
                .contains("« Revenons à notre échange. »")
                .contains("« Pardon, pouvez-vous répéter ? »")
                .contains("Ne les lis JAMAIS à voix haute")
                .contains("[SILENCE]").contains("[FIN]").contains("[REPRISE]")
                .contains("dis exactement « Merci, nous allons nous arrêter ici. » et rien d'autre")
                .doesNotContain("tu n'adaptes pas ton niveau")
                .doesNotContain("encourageant")
                .doesNotContain("acquiescements naturels : « très bien »");
    }

    @Test
    void le_verrou_de_langue_de_la_v3_est_repris_mot_pour_mot() throws IOException {
        JsonNode v3 = json("v3").get("regles");
        String v4 = builder("v4").build(task((short) 1, null));

        // Lignes 8 à 10 de la v3 : intactes.
        for (int i = 4; i <= 6; i++) {
            assertThat(v4).contains(v3.get(i).asString());
        }
        // Ligne 7 : seule la phrase contradictoire (F10) est retirée.
        assertThat(v4).contains("- Parle exclusivement en français, un français authentique, clair et "
                + "accessible (un niveau B2 doit suffire à te comprendre). Ne bascule JAMAIS vers une autre langue.");
    }

    @Test
    void les_versions_v1_a_v3_restent_inchangees_et_ignorent_le_mode() {
        for (String v : List.of("v1", "v2", "v3")) {
            RealtimePersonaBuilder b = builder(v);
            assertThat(b.build(task((short) 2, card()), true)).isEqualTo(b.build(task((short) 2, card())));
            assertThat(b.build(task((short) 2, card()), true)).doesNotContain("{enteteExamen}");
        }
        assertThat(builder("v3").build(task((short) 1, null))).contains("Bonjour, je suis votre examinateur");
    }
}
