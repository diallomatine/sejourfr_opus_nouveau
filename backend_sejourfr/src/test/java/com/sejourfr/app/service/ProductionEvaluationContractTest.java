package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.core.io.ClassPathResource;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProductionEvaluationContractTest {

    private static final Set<String> CODES = Set.of(
        "communiquer", "interagir", "lexique", "morphosyntaxe");
    private static final List<String> NIVEAUX = List.of(
        "A1_NON_ATTEINT", "A1", "A2", "B1", "B2");
    /**
     * Ce par quoi v12 remplace un chiffre de bornes recopie : un RENVOI a la
     * seule source de verite ({@code production_tasks}, injectee en tete de
     * l'enonce sous « LONGUEUR ATTENDUE »).
     */
    private static final String BORNES_RENVOI =
        "dans les bornes du bloc LONGUEUR ATTENDUE, registre et destinataire";
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void v7AndV4FormOneStrictTcfIrnContract() throws Exception {
        Map<String, Object> v7 = resource("prompts/production-rubrics-v7.json");
        Map<String, Object> v4 = resource("prompts/production-evaluation-tool-schema-v4.json");
        String rawV7 = resourceText("prompts/production-rubrics-v7.json");

        assertThat(v7)
            .containsEntry("rubrics-version", "v7")
            .containsEntry("profile", "TCF_IRN")
            .containsEntry("tool_schema_version", "v4")
            .containsEntry("niveau_max", "B2");
        assertThat(rawV7).doesNotContain("\"C1\"", "\"C2\"");

        Map<String, Object> commun = map(v7.get("commun"));
        Map<String, Object> niveau = map(commun.get("niveau"));
        assertThat(niveau)
            .containsEntry("seuil_b2", 10)
            .containsEntry("seuil_b1", 6)
            .containsEntry("seuil_a2", 2);
        assertThat(map(commun.get("couplage"))).containsEntry("ecart_max", 1);
        assertThat(map(commun.get("bandes_criteres")))
            .containsEntry("tres_bonne_maitrise", 10)
            .containsEntry("satisfaisant", 6)
            .containsEntry("en_cours_acquisition", 2);

        Map<String, Object> rubrics = map(v7.get("rubrics"));
        assertThat(rubrics.keySet()).containsExactlyInAnyOrder(
            "EE_T1", "EE_T2", "EE_T3", "EO_T1", "EO_T2", "EO_T3");
        for (Map.Entry<String, Object> entry : rubrics.entrySet()) {
            List<?> criteres = list(map(entry.getValue()).get("criteres"));
            assertThat(criteres).as(entry.getKey()).hasSize(4);
            assertThat(criteres.stream().map(c -> map(c).get("code").toString()).toList())
                .containsExactly("communiquer", "interagir", "lexique", "morphosyntaxe");
            assertThat(criteres.stream()
                .mapToDouble(c -> ((Number) map(c).get("poids")).doubleValue()).sum())
                .isEqualTo(1.0);
        }
        assertBounds(rubrics, "EE_T1", 30, 60);
        assertBounds(rubrics, "EE_T2", 60, 90);
        assertBounds(rubrics, "EE_T3", 60, 90);

        assertThat(v4.get("additionalProperties")).isEqualTo(false);
        assertThat(strings(map(map(v4.get("properties")).get("niveau_cecrl")).get("enum")))
            .containsExactlyElementsOf(NIVEAUX);
        Map<String, Object> scores = map(map(v4.get("properties")).get("scores_criteres"));
        assertThat(scores).containsEntry("minItems", 4).containsEntry("maxItems", 4);
        assertThat(strings(map(map(scores.get("items")).get("properties"))
            .get("code") instanceof Map<?, ?> code ? code.get("enum") : null))
            .containsExactlyInAnyOrderElementsOf(CODES);
        Map<String, Object> scoreProperties = map(map(scores.get("items")).get("properties"));
        Map<String, Object> preuve = map(scoreProperties.get("preuve"));
        assertThat(preuve).containsEntry("minLength", 1);
        assertThat(rawV7).doesNotContain("mets une chaine vide");
        assertAllObjectsClosed(v4, "root");
    }

    /**
     * v8 = v7 pour TOUT ce qui note, v5 = v4 pour tout ce qui note. Ce test est
     * le verrou de cette promesse : si une future retouche de restitution
     * deplacait un seuil, une pondération, un critere ou une borne, il casse.
     */
    @Test
    void v8NeChangeQueLaRestitution_paseLeBareme() throws Exception {
        Map<String, Object> v7 = resource("prompts/production-rubrics-v7.json");
        Map<String, Object> v8 = resource("prompts/production-rubrics-v8.json");

        assertThat(v8)
            .containsEntry("rubrics-version", "v8")
            .containsEntry("profile", "TCF_IRN")
            .containsEntry("tool_schema_version", "v5")
            .containsEntry("niveau_max", "B2");
        assertThat(resourceText("prompts/production-rubrics-v8.json")).doesNotContain("\"C1\"", "\"C2\"");

        Map<String, Object> communV7 = map(v7.get("commun"));
        Map<String, Object> communV8 = map(v8.get("commun"));
        for (String bloc : List.of("niveau", "couplage", "plafonds", "bandes_criteres", "few_shot")) {
            assertThat(communV8.get(bloc))
                .as("v8 ne touche pas a commun." + bloc + " : la notation est celle de v7")
                .isEqualTo(communV7.get(bloc));
        }

        Map<String, Object> rubricsV7 = map(v7.get("rubrics"));
        Map<String, Object> rubricsV8 = map(v8.get("rubrics"));
        assertThat(rubricsV8.keySet()).isEqualTo(rubricsV7.keySet());
        for (String cle : rubricsV7.keySet()) {
            Map<String, Object> taskV7 = map(rubricsV7.get(cle));
            Map<String, Object> taskV8 = map(rubricsV8.get(cle));
            for (String champ : taskV7.keySet()) {
                if ("consignes_correcteur".equals(champ)) continue;
                assertThat(taskV8.get(champ)).as(cle + "." + champ).isEqualTo(taskV7.get(champ));
            }
            // Les consignes ne font que S'ETOFFER d'un rappel de restitution.
            assertThat(taskV8.get("consignes_correcteur").toString())
                .as(cle + " : rappel de restitution ajoute, consignes de notation intactes")
                .startsWith(taskV7.get("consignes_correcteur").toString().stripTrailing())
                .contains("RESTITUTION v8")
                .contains("accomplissement.objectif");
            assertThat(taskV8.get("consignes_correcteur").toString())
                .as(cle + " : la version amelioree n'existe qu'a l'ecrit")
                .contains(cle.startsWith("EE_")
                    ? "VERSION AMELIOREE obligatoire"
                    : "AUCUNE version_amelioree sur une tache orale");
        }
    }

    /**
     * v9 = v8 pour TOUT, sauf les DEUX SECTIONS ORALES. Ce test est le verrou de
     * cette promesse : elle est ce qui rend la campagne de banc interpretable —
     * si un seuil, une ponderation, un critere, une borne, une ancre few-shot ou
     * une consigne de tache bougeait en meme temps, on ne saurait plus ce que la
     * mesure attribue a quoi.
     */
    @Test
    void v9NeChangeQueLesDeuxSectionsOrales() throws Exception {
        Map<String, Object> v8 = resource("prompts/production-rubrics-v8.json");
        Map<String, Object> v9 = resource("prompts/production-rubrics-v9.json");

        assertThat(v9)
            .containsEntry("rubrics-version", "v9")
            .containsEntry("profile", "TCF_IRN")
            .containsEntry("tool_schema_version", "v5")
            .containsEntry("niveau_max", "B2");
        assertThat(resourceText("prompts/production-rubrics-v9.json"))
            .doesNotContain("\"C1\"", "\"C2\"");

        // Les six rubriques par tache : identiques au champ pres.
        assertThat(v9.get("rubrics"))
            .as("v9 ne touche a aucune rubrique de tache")
            .isEqualTo(v8.get("rubrics"));

        Map<String, Object> communV8 = map(v8.get("commun"));
        Map<String, Object> communV9 = map(v9.get("commun"));
        for (String bloc : List.of("niveau", "couplage", "plafonds", "bandes_criteres", "few_shot")) {
            assertThat(communV9.get(bloc))
                .as("v9 ne touche pas a commun." + bloc + " : la notation est celle de v8")
                .isEqualTo(communV8.get(bloc));
        }

        List<?> sectionsV8 = list(communV8.get("sections"));
        List<?> sectionsV9 = list(communV9.get("sections"));
        assertThat(sectionsV9).hasSameSizeAs(sectionsV8);
        List<Integer> modifiees = new java.util.ArrayList<>();
        for (int i = 0; i < sectionsV8.size(); i++) {
            if (!sectionsV8.get(i).equals(sectionsV9.get(i))) modifiees.add(i);
        }
        assertThat(modifiees)
            .as("exactement deux sections changent, et ce sont les deux sections orales")
            .hasSize(2);
        for (int index : modifiees) {
            assertThat(map(sectionsV8.get(index)).get("titre").toString())
                .as("section " + index)
                .contains("orale");
        }

        String orale = map(sectionsV9.get(modifiees.get(0))).get("contenu").toString();
        String interaction = map(sectionsV9.get(modifiees.get(1))).get("contenu").toString();

        // (a) artefacts de transcription : opposable, et sans echappatoire.
        assertThat(orale)
            .contains("ARTEFACT")
            .contains("L'ECHAPPATOIRE EST FERMEE")
            .contains("LA REGLE DE PREUVE NE CHANGE PAS");
        // (b) le deroule de l'echange compte, sans toucher au garde-fou oral.
        assertThat(interaction)
            .contains("LE DEROULE DE L'ECHANGE EST UN ELEMENT D'APPRECIATION")
            .contains("UNE RELANCE DE L'EXAMINATEUR N'EST PAS UNE HESITATION DU CANDIDAT")
            .contains("communiquer ET interagir")
            .contains("'Candidat :'");
    }

    /**
     * v10 et v11 = v9 pour TOUT, sauf UNE SEULE section : la section orale des
     * artefacts de transcription, ou elles ajoutent la regle ASYMETRIQUE EE/EO
     * sur la LANGUE. Meme verrou, meme raison que pour v9 : c'est ce qui rend la
     * campagne de banc interpretable. Si un seuil, une ponderation, un critere,
     * une borne, une ancre few-shot ou une consigne de tache bougeait en meme
     * temps, on ne saurait plus ce que la mesure attribue a quoi — et cette
     * bascule-la est precisement celle qui doit prouver qu'elle ne casse pas le
     * piege AUTRE_LANGUE du corpus.
     *
     * <p>v11 succede a v10 (meme regle, un tiers de texte en moins, sanction
     * enoncee avant tolerance) ; les deux restent chargeables, et chacune est
     * rattachable a sa campagne.
     */
    @ParameterizedTest
    @CsvSource({"v10", "v11"})
    void chaqueVersionDeLangueNeChangeQueLaSectionOraleDesArtefacts(String version) throws Exception {
        Map<String, Object> v9 = resource("prompts/production-rubrics-v9.json");
        Map<String, Object> candidate = resource("prompts/production-rubrics-" + version + ".json");

        assertThat(candidate)
            .containsEntry("rubrics-version", version)
            .containsEntry("profile", "TCF_IRN")
            .containsEntry("tool_schema_version", "v5")
            .containsEntry("niveau_max", "B2");
        assertThat(resourceText("prompts/production-rubrics-" + version + ".json"))
            .doesNotContain("\"C1\"", "\"C2\"");

        assertThat(candidate.get("rubrics"))
            .as(version + " ne touche a aucune rubrique de tache")
            .isEqualTo(v9.get("rubrics"));

        Map<String, Object> communV9 = map(v9.get("commun"));
        Map<String, Object> communCandidate = map(candidate.get("commun"));
        for (String bloc : List.of("niveau", "couplage", "plafonds", "bandes_criteres", "few_shot")) {
            assertThat(communCandidate.get(bloc))
                .as(version + " ne touche pas a commun." + bloc + " : la notation est celle de v9")
                .isEqualTo(communV9.get(bloc));
        }

        List<?> sectionsV9 = list(communV9.get("sections"));
        List<?> sections = list(communCandidate.get("sections"));
        assertThat(sections).hasSameSizeAs(sectionsV9);
        List<Integer> modifiees = new java.util.ArrayList<>();
        for (int i = 0; i < sectionsV9.size(); i++) {
            if (!sectionsV9.get(i).equals(sections.get(i))) modifiees.add(i);
        }
        assertThat(modifiees)
            .as("exactement UNE section change, et c'est la section orale des artefacts")
            .hasSize(1);

        Map<String, Object> section = map(sections.get(modifiees.get(0)));
        assertThat(section.get("titre").toString())
            .isEqualTo(map(sectionsV9.get(modifiees.get(0))).get("titre").toString())
            .contains("TRANSCRIPTION AUTOMATIQUE");

        String orale = section.get("contenu").toString();

        // (a) la section v9 est integralement conservee : on ajoute, on ne reecrit pas.
        String oraleV9 = map(sectionsV9.get(modifiees.get(0))).get("contenu").toString();
        for (String garantieV9 : List.of(
                "ARTEFACT DE TRANSCRIPTION — LA REGLE, ET ELLE EST OPPOSABLE.",
                "CE QUI N'EST PAS UN ARTEFACT — L'ECHAPPATOIRE EST FERMEE.",
                "LA REGLE DE PREUVE NE CHANGE PAS D'UN IOTA.",
                "TU NE JUGES NI la prononciation")) {
            assertThat(oraleV9).as("garantie v9 presente en v9").contains(garantieV9);
            assertThat(orale).as("garantie v9 conservee en " + version).contains(garantieV9);
        }

        // (b) la TOLERANCE (artefact) : opposable, jamais laissee au feeling.
        assertThat(orale)
            .as(version + " enonce le cote tolerance de facon opposable")
            .containsIgnoringCase("ARTEFACT")
            .contains("ISOLE")
            .contains("NULLE PART");

        // (c) la SANCTION : le piege AUTRE_LANGUE doit rester attrapable. Les
        //     trois criteres discriminants sont ecrits, et la consequence aussi.
        //     (les deux versions les ecrivent, v10 au feminin, v11 au masculin :
        //     on verifie la racine, pas l'accord.)
        assertThat(orale)
            .as(version + " enonce le cote sanction de facon opposable")
            .contains("CONTINU")
            .contains("COHERENT")
            .contains("DOMIN")
            .contains("SEUL LE FRANCAIS REELLEMENT PRODUIT COMPTE")
            .contains("un quart");

        // (d) l'asymetrie EE/EO est ecrite noir sur blanc.
        assertThat(orale)
            .as(version + " declare l'asymetrie EE/EO")
            .contains("A L'ECRIT, RIEN DE CETTE REGLE NE S'APPLIQUE");
    }

    /**
     * v11 seule : elle reaffirme explicitement les deux regles que la campagne
     * du 2026-08-07 a vues bouger sous v10 (hors-sujet passe de A1_NON_ATTEINT a
     * A1, transcription bruitee passee de A2 a B1). C'est la correction de
     * cette derive, et elle doit rester ecrite.
     */
    @Test
    void v11_reaffirmeExplicitementCeQueLaRegleNeChangePas() throws Exception {
        Map<String, Object> v11 = resource("prompts/production-rubrics-v11.json");
        List<?> sections = list(map(v11.get("commun")).get("sections"));
        String orale = sections.stream()
            .map(s -> map(s).get("contenu").toString())
            .filter(c -> c.contains("A L'ECRIT, RIEN DE CETTE REGLE NE S'APPLIQUE"))
            .findFirst()
            .orElseThrow();

        assertThat(orale)
            .contains("CE QUE CETTE REGLE NE CHANGE PAS")
            .contains("HORS-SUJET")
            .contains("BRUITEE")
            .contains("un artefact leve une sanction, il n'ajoute jamais rien");
    }

    /**
     * L'asymetrie ne peut pas fuiter vers l'ecrit : la regle de langue vit dans
     * une section ORALE, et aucune rubrique EE ne la mentionne. C'est ce qui
     * garantit qu'une production ecrite en langue etrangere reste une vraie
     * non-realisation.
     */
    @ParameterizedTest
    @CsvSource({"v10", "v11"})
    void laRegleDeLangueNeToucheAucuneRubriqueEcrite(String version) throws Exception {
        Map<String, Object> rubrics = map(
            resource("prompts/production-rubrics-" + version + ".json").get("rubrics"));

        for (String cle : List.of("EE_T1", "EE_T2", "EE_T3")) {
            assertThat(map(rubrics.get(cle)).toString())
                .as(cle + " ne parle jamais d'artefact de transcription")
                .doesNotContain("ARTEFACT");
        }
    }

    /**
     * v12 = v9 pour TOUT ce qui note, et ne change QUE DEUX CHOSES, toutes deux
     * de FORME : (1) la preuve — le correcteur ne recopie plus un extrait, il
     * designe le NUMERO d'un segment ; (2) les BORNES DE MOTS — v9 et avant les
     * recopiaient en dur (« taches 2 et 3 : 60 a 90 mots ») a cote des bornes
     * reellement injectees depuis {@code production_tasks}, ce qui envoyait au
     * correcteur deux longueurs contradictoires des que la base changeait
     * (V724 : minimum T2/T3 60 -> 40). v12 ne les redeclare plus, il RENVOIE au
     * bloc LONGUEUR ATTENDUE de l'enonce.
     *
     * <p>Ce test est le verrou de cette promesse — et il compte double ici,
     * parce que cette bascule est livree SANS campagne de banc : la seule chose
     * qui garantisse qu'elle ne deplace pas une note, c'est qu'aucune regle de
     * notation n'a bouge d'un caractere. D'ou une comparaison v9 ⇄ v12 champ par
     * champ, ou le SEUL ecart tolere est celui, enumere, des bornes de mots.
     */
    @Test
    void v12NeChangeQueLaFormeDeLaPreuve() throws Exception {
        Map<String, Object> v9 = resource("prompts/production-rubrics-v9.json");
        Map<String, Object> v12 = resource("prompts/production-rubrics-v12.json");

        assertThat(v12)
            .containsEntry("rubrics-version", "v12")
            .containsEntry("profile", "TCF_IRN")
            .containsEntry("tool_schema_version", "v6")
            .containsEntry("niveau_max", "B2");
        assertThat(resourceText("prompts/production-rubrics-v12.json"))
            .doesNotContain("\"C1\"", "\"C2\"");

        // Les six rubriques de tache : identiques au champ pres, hors bornes de mots.
        Map<String, Object> rubricsV9 = map(v9.get("rubrics"));
        Map<String, Object> rubricsV12 = map(v12.get("rubrics"));
        assertThat(rubricsV12.keySet()).isEqualTo(rubricsV9.keySet());
        for (String tache : rubricsV9.keySet()) {
            Map<String, Object> blocV9 = new java.util.LinkedHashMap<>(map(rubricsV9.get(tache)));
            Map<String, Object> blocV12 = new java.util.LinkedHashMap<>(map(rubricsV12.get(tache)));

            if (tache.startsWith("EE_")) {
                assertThat(blocV9.remove("bornes_mots_indicatives"))
                    .as(tache + " : v9 portait bien une copie des bornes")
                    .isNotNull();
            }
            assertThat(blocV12)
                .as(tache + " : v12 ne duplique plus les bornes de production_tasks")
                .doesNotContainKey("bornes_mots_indicatives");

            String consignesV9 = String.valueOf(blocV9.remove("consignes_correcteur"));
            String consignesV12 = String.valueOf(blocV12.remove("consignes_correcteur"));
            assertThat(consignesV12)
                .as(tache + " : seule la mention des bornes change dans les consignes")
                .isEqualTo(consignesV9
                    .replace("en 30 a 60 mots, registre et destinataire", BORNES_RENVOI)
                    .replace("en 60 a 90 mots, registre et destinataire", BORNES_RENVOI));

            assertThat(blocV12)
                .as(tache + " : tout le reste de la rubrique est celui de v9")
                .isEqualTo(blocV9);
        }

        Map<String, Object> communV9 = map(v9.get("commun"));
        Map<String, Object> communV12 = map(v12.get("commun"));
        for (String bloc : List.of("niveau", "couplage", "plafonds", "bandes_criteres", "few_shot")) {
            assertThat(communV12.get(bloc))
                .as("v12 ne touche pas a commun." + bloc + " : la notation est celle de v9")
                .isEqualTo(communV9.get(bloc));
        }

        List<?> sectionsV9 = list(communV9.get("sections"));
        List<?> sectionsV12 = list(communV12.get("sections"));
        assertThat(sectionsV12).hasSameSizeAs(sectionsV9);
        List<String> titresModifies = new java.util.ArrayList<>();
        for (int i = 0; i < sectionsV9.size(); i++) {
            if (sectionsV9.get(i).equals(sectionsV12.get(i))) continue;
            Map<String, Object> section = map(sectionsV12.get(i));
            assertThat(section.get("titre"))
                .as("un titre de section ne bouge pas")
                .isEqualTo(map(sectionsV9.get(i)).get("titre"));
            titresModifies.add(section.get("titre").toString());
        }
        assertThat(titresModifies)
            .as("seules changent les sections qui decrivent la MECANIQUE DE LA PREUVE "
                + "et celle qui recopiait les BORNES DE MOTS")
            .containsExactly(
                "Preuves litterales et priorites : ENSEIGNER, PAS CONSTATER (regle capitale)",
                "Version amelioree de la production (taches ECRITES uniquement)",
                "Production orale : tu lis une TRANSCRIPTION AUTOMATIQUE, tu evalues le SENS "
                    + "(regle capitale)",
                "Production orale en INTERACTION (dialogue examinateur/candidat)",
                "Methode d'evaluation",
                "Principes et format de sortie");

        // Chaque section touchee enonce la nouvelle mecanique, et plus l'ancienne.
        String v12Texte = sectionsV12.stream()
            .map(s -> map(s).get("contenu").toString())
            .reduce("", (a, b) -> a + "\n" + b);
        assertThat(v12Texte)
            .contains("preuve_segment")
            .contains("SEGMENTS NUMEROTES")
            .as("le correcteur ne recopie plus rien pour prouver")
            .doesNotContain("recopiee EXACTEMENT telle qu'elle apparait")
            .doesNotContain("caractere par caractere");
        // L'invariant oral survit a la bascule : la preuve reste un tour candidat.
        assertThat(v12Texte)
            .contains("seuls les tours 'Candidat :' portent un numero")
            .contains("les tours de l'examinateur ne portent aucun numero");

        // La section « version amelioree » ne change QUE sur la regle 3 (bornes).
        String versionAmelioreeV9 = sectionContenu(sectionsV9, TITRE_VERSION_AMELIOREE);
        String versionAmelioreeV12 = sectionContenu(sectionsV12, TITRE_VERSION_AMELIOREE);
        assertThat(lignesHors(versionAmelioreeV12, "3)"))
            .as("les regles 1, 2, 4 et 5 de la version amelioree sont intactes")
            .isEqualTo(lignesHors(versionAmelioreeV9, "3)"));
        assertThat(versionAmelioreeV12)
            .as("la regle 3 RENVOIE aux bornes injectees au lieu de les redeclarer")
            .contains("du bloc LONGUEUR ATTENDUE de l'enonce")
            .contains("ne te fie a AUCUN chiffre memorise")
            .doesNotContain("30 a 60 mots")
            .doesNotContain("60 a 90 mots");
    }

    private static final String TITRE_VERSION_AMELIOREE =
        "Version amelioree de la production (taches ECRITES uniquement)";

    private static String sectionContenu(List<?> sections, String titre) {
        return sections.stream()
            .map(ProductionEvaluationContractTest::map)
            .filter(s -> titre.equals(String.valueOf(s.get("titre"))))
            .map(s -> String.valueOf(s.get("contenu")))
            .findFirst()
            .orElseThrow(() -> new AssertionError("section absente : " + titre));
    }

    /** Le contenu prive des lignes commencant par {@code prefixe}. */
    private static String lignesHors(String contenu, String prefixe) {
        return java.util.Arrays.stream(contenu.split("\n"))
            .filter(l -> !l.startsWith(prefixe))
            .reduce("", (a, b) -> a + "\n" + b);
    }

    /**
     * Le contrat de sortie v6 : celui de v5, la citation remplacee par un
     * numero de segment. Rien d'autre — ni la note, ni le niveau, ni la
     * restitution.
     */
    @Test
    void v6RemplaceLaCitationParUnNumeroDeSegmentEtRienDAutre() throws Exception {
        Map<String, Object> v5 = resource("prompts/production-evaluation-tool-schema-v5.json");
        Map<String, Object> v6 = resource("prompts/production-evaluation-tool-schema-v6.json");

        assertThat(strings(v6.get("required")))
            .containsExactlyElementsOf(strings(v5.get("required")));
        Map<String, Object> propsV5 = map(v5.get("properties"));
        Map<String, Object> propsV6 = map(v6.get("properties"));
        assertThat(propsV6.keySet()).isEqualTo(propsV5.keySet());
        for (String champ : propsV5.keySet()) {
            if ("scores_criteres".equals(champ) || "version_amelioree".equals(champ)) continue;
            assertThat(propsV6.get(champ)).as(champ + " ne bouge pas entre v5 et v6")
                .isEqualTo(propsV5.get(champ));
        }
        // version_amelioree : seule sa DESCRIPTION bouge, et seulement sur les
        // bornes de mots, que v5 recopiait a cote de celles vraiment injectees.
        Map<String, Object> vaV5 = new java.util.LinkedHashMap<>(map(propsV5.get("version_amelioree")));
        Map<String, Object> vaV6 = new java.util.LinkedHashMap<>(map(propsV6.get("version_amelioree")));
        String descV5 = String.valueOf(vaV5.remove("description"));
        String descV6 = String.valueOf(vaV6.remove("description"));
        assertThat(vaV6).as("version_amelioree : type et contraintes inchanges").isEqualTo(vaV5);
        assertThat(descV5).contains("T2 et T3 : 60 a 90 mots");
        assertThat(descV6)
            .as("v6 renvoie aux bornes injectees au lieu d'en recopier")
            .contains("les bornes de mots annoncees dans le bloc LONGUEUR ATTENDUE")
            .doesNotContain("30 a 60 mots")
            .doesNotContain("60 a 90 mots");

        Map<String, Object> scoresV5 = map(propsV5.get("scores_criteres"));
        Map<String, Object> scoresV6 = map(propsV6.get("scores_criteres"));
        assertThat(scoresV6).containsEntry("minItems", 4).containsEntry("maxItems", 4);
        Map<String, Object> itemsV5 = map(scoresV5.get("items"));
        Map<String, Object> itemsV6 = map(scoresV6.get("items"));
        assertThat(strings(itemsV6.get("required")))
            .containsExactly("code", "note_sur_20", "commentaire", "preuve_segment");
        Map<String, Object> champsV6 = map(itemsV6.get("properties"));
        assertThat(champsV6.keySet())
            .containsExactlyInAnyOrder("code", "note_sur_20", "commentaire", "preuve_segment");
        for (String champ : List.of("code", "note_sur_20", "commentaire")) {
            assertThat(champsV6.get(champ)).as("scores_criteres." + champ)
                .isEqualTo(map(itemsV5.get("properties")).get(champ));
        }
        // C'est CA qui rend une preuve inventee impossible : un entier borne.
        assertThat(map(champsV6.get("preuve_segment")))
            .containsEntry("type", "integer")
            .containsEntry("minimum", 1);
        assertThat(strings(map(propsV6.get("niveau_cecrl")).get("enum")))
            .containsExactlyElementsOf(NIVEAUX);
        assertThat(v6.get("additionalProperties")).isEqualTo(false);
        assertAllObjectsClosed(v6, "root");
    }

    /** Le contrat de sortie v5 : celui de v4, plus les seules cles de restitution. */
    @Test
    void v5AjouteLeVerdictLaVersionAmelioreeEtLesPlafondsDeRestitution() throws Exception {
        Map<String, Object> v4 = resource("prompts/production-evaluation-tool-schema-v4.json");
        Map<String, Object> v5 = resource("prompts/production-evaluation-tool-schema-v5.json");

        assertThat(strings(v5.get("required")))
            .as("les champs obligatoires a la racine ne bougent pas : "
                + "version_amelioree n'est exigee que sur les taches ecrites, cote serveur")
            .containsExactlyElementsOf(strings(v4.get("required")));

        Map<String, Object> props = map(v5.get("properties"));
        assertThat(props.keySet())
            .containsAll(map(v4.get("properties")).keySet())
            .contains("version_amelioree");
        assertThat(map(props.get("version_amelioree")))
            .containsEntry("type", "string")
            .containsEntry("minLength", 1);

        Map<String, Object> accomplissement = map(props.get("accomplissement"));
        assertThat(strings(accomplissement.get("required")))
            .containsExactlyInAnyOrder("objectif", "objectif_resume", "points_traites", "points_oublies");
        assertThat(strings(map(map(accomplissement.get("properties")).get("objectif")).get("enum")))
            .containsExactly("ATTEINT", "PARTIELLEMENT_ATTEINT", "NON_ATTEINT");
        assertThat(map(map(accomplissement.get("properties")).get("objectif_resume")))
            .containsEntry("minLength", 1);

        assertThat(map(props.get("points_forts"))).containsEntry("maxItems", 2);
        assertThat(map(props.get("points_a_ameliorer"))).containsEntry("maxItems", 2);
        assertThat(map(props.get("exemples_corriges"))).containsEntry("maxItems", 3);

        // Rien de ce qui porte la NOTE n'a bouge entre v4 et v5 : seules les
        // consignes de restitution (commentaire, confiance, suggestions...) ont
        // ete reecrites.
        Map<String, Object> propsV4 = map(v4.get("properties"));
        for (String champ : List.of("note_globale", "niveau_cecrl")) {
            assertThat(props.get(champ)).as(champ).isEqualTo(propsV4.get(champ));
        }
        Map<String, Object> scoresV5 = map(props.get("scores_criteres"));
        Map<String, Object> scoresV4 = map(propsV4.get("scores_criteres"));
        assertThat(scoresV5).containsEntry("minItems", 4).containsEntry("maxItems", 4);
        Map<String, Object> itemsV5 = map(scoresV5.get("items"));
        Map<String, Object> itemsV4 = map(scoresV4.get("items"));
        assertThat(strings(itemsV5.get("required"))).containsExactlyElementsOf(strings(itemsV4.get("required")));
        for (String champ : List.of("code", "note_sur_20", "preuve")) {
            assertThat(map(itemsV5.get("properties")).get(champ)).as("scores_criteres." + champ)
                .isEqualTo(map(itemsV4.get("properties")).get(champ));
        }
        assertThat(v5.get("additionalProperties")).isEqualTo(false);
        assertAllObjectsClosed(v5, "root");
    }

    @Test
    void v7RefusesAnOldToolSchemaAtLoadTime() {
        var props = new com.sejourfr.app.config.ProductionEvaluationProperties();
        props.setRubricsVersion("v7");
        props.setProvider("deepseek");
        props.getDeepseek().setPromptVersion("v3");

        assertThatThrownBy(() -> new ProductionRubricsProvider(props, objectMapper).load())
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Rubriques production introuvables/illisibles")
            .hasRootCauseMessage("contrat rubriques/tool-schema incompatible : rubriques v7 -> v4, "
                + "provider deepseek -> v3");
    }

    @ParameterizedTest
    @CsvSource({
        "v3, v2",
        "v4, v2",
        "v4.1, v2",
        "v4.2, v2",
        "v5, v3",
        "v6, v3",
        "v7, v4",
        "v8, v5",
        "v9, v5",
        "v10, v5",
        "v11, v5",
        "v12, v6"
    })
    void chaqueVersionDeRubriquesAccepteUniquementSonToolSchema(
            String rubricsVersion, String toolSchemaVersion) {
        var props = new com.sejourfr.app.config.ProductionEvaluationProperties();
        props.setRubricsVersion(rubricsVersion);
        props.setProvider("deepseek");
        props.getDeepseek().setPromptVersion(toolSchemaVersion);

        new ProductionRubricsProvider(props, objectMapper).load();
    }

    @ParameterizedTest
    @CsvSource({
        "v3, v3, v2",
        "v4, v3, v2",
        "v4.1, v3, v2",
        "v4.2, v3, v2",
        "v5, v2, v3",
        "v6, v4, v3",
        "v7, v3, v4",
        "v8, v4, v5",
        "v9, v4, v5",
        "v10, v4, v5",
        "v11, v4, v5",
        "v12, v5, v6"
    })
    void unePaireRubriquesToolSchemaIncompatibleEchoueAuChargement(
            String rubricsVersion, String activeSchema, String expectedSchema) {
        var props = new com.sejourfr.app.config.ProductionEvaluationProperties();
        props.setRubricsVersion(rubricsVersion);
        props.setProvider("deepseek");
        props.getDeepseek().setPromptVersion(activeSchema);

        assertThatThrownBy(() -> new ProductionRubricsProvider(props, objectMapper).load())
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Rubriques production introuvables/illisibles")
            .hasRootCauseMessage("contrat rubriques/tool-schema incompatible : rubriques "
                + rubricsVersion + " -> " + expectedSchema + ", provider deepseek -> " + activeSchema);
    }

    private void assertBounds(Map<String, Object> rubrics, String key, int min, int max) {
        Map<String, Object> bounds = map(map(rubrics.get(key)).get("bornes_mots_indicatives"));
        assertThat(bounds).as(key).containsEntry("min", min).containsEntry("max", max);
    }

    private void assertAllObjectsClosed(Object node, String path) {
        if (node instanceof Map<?, ?> map) {
            if ("object".equals(map.get("type"))) {
                assertThat(map.get("additionalProperties")).as(path).isEqualTo(false);
            }
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                assertAllObjectsClosed(entry.getValue(), path + "." + entry.getKey());
            }
        } else if (node instanceof List<?> list) {
            for (int i = 0; i < list.size(); i++) assertAllObjectsClosed(list.get(i), path + "[" + i + "]");
        }
    }

    private Map<String, Object> resource(String path) throws Exception {
        try (var input = new ClassPathResource(path).getInputStream()) {
            return objectMapper.readValue(input, new TypeReference<Map<String, Object>>() {});
        }
    }

    private String resourceText(String path) throws Exception {
        try (var input = new ClassPathResource(path).getInputStream()) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> map(Object value) {
        return (Map<String, Object>) value;
    }

    private static List<?> list(Object value) {
        return (List<?>) value;
    }

    private static List<String> strings(Object value) {
        return list(value).stream().map(Object::toString).toList();
    }
}
