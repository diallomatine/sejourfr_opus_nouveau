package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.util.StreamUtils;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * MIROIR VÉRIFIÉ : la liste fermée {@code EvaluationMarqueursA2.MARQUEURS_A2}
 * doit dire exactement ce que dit la GRILLE ACTIVE.
 *
 * <p>Même technique que {@code ProductionValidityService.MOTS_OUTILS_ETRANGERS} :
 * la liste vit en Java (une extraction par expression régulière à l'exécution
 * ferait taire le filet en silence le jour où une v14 reformulerait la phrase),
 * mais ce test la confronte au fichier de rubriques et échoue bruyamment si l'un
 * des deux bouge. Un marqueur qui change, ce sont deux fichiers à mettre à jour
 * dans la même passe.
 *
 * <p>Trois passages de la grille énumèrent ces moyens :
 * <ul>
 *   <li>le descripteur A2 de EE_T1 : « phrases simples coordonnees (parce que,
 *       mais, alors) » ;</li>
 *   <li>le PLAFOND A2, qui exige pour dépasser A2 des connecteurs organisant le
 *       propos « au-dela de et / mais / parce que / apres / aussi » ;</li>
 *   <li>le descripteur A2 de EE_T2 : « Phrases simples reliees par
 *       et/mais/parce que ».</li>
 * </ul>
 */
class EvaluationPalierMarqueurRubriqueTest {

    /**
     * ENUMERATIONS seulement : chaque motif exige un separateur repete (« , » ou
     * « / »). Sans cette exigence, « au-dela de l'elementaire » — une autre phrase
     * de la grille — serait ramasse comme un marqueur.
     */
    private static final Pattern COORDONNEES =
        Pattern.compile("coordonnees \\(([a-z' ]+(?:, [a-z' ]+)+)\\)");
    private static final Pattern AU_DELA_DE =
        Pattern.compile("au-dela de ([a-z' ]+(?:/[a-z' ]+)+)");
    private static final Pattern RELIEES_PAR =
        Pattern.compile("reliees par ([a-z' ]+(?:/[a-z' ]+)+)");

    @Test
    void laListeFermeeDesMarqueursA2EstCelleDeLaGrilleActive() throws Exception {
        String grille = grilleActive();

        Set<String> deLaGrille = new LinkedHashSet<>();
        collecte(COORDONNEES, grille, ",", deLaGrille);
        collecte(AU_DELA_DE, grille, "/", deLaGrille);
        collecte(RELIEES_PAR, grille, "/", deLaGrille);

        // Les trois passages doivent avoir ete trouves : si une version de grille
        // les reformule, ce test tombe — c'est le comportement voulu.
        assertThat(deLaGrille)
            .as("marqueurs A2 enumeres par la grille active")
            .isNotEmpty()
            .containsExactlyInAnyOrderElementsOf(EvaluationMarqueursA2.MARQUEURS_A2);
    }

    /**
     * Le mot « donc » NE fait PAS partie des marqueurs A2 : la grille le range
     * parmi les connecteurs qui ORGANISENT le propos (« c'est pourquoi, donc
     * argumentatif »), c'est-à-dire au-dessus de A2. Le conseiller pour viser le
     * B1 est légitime, et le filet ne doit pas y toucher.
     */
    @Test
    void doncNEstPasUnMarqueurA2() {
        assertThat(EvaluationMarqueursA2.MARQUEURS_A2).doesNotContain("donc", "car");
    }

    /**
     * Version REELLEMENT active : celle que {@code application.yaml} sert par
     * defaut, pas celle du POJO (qui vaut encore {@code v1}). Le test suit ainsi
     * la grille en vigueur sans qu'on ait a le modifier a chaque bascule.
     */
    private static String grilleActive() throws Exception {
        Matcher version = Pattern.compile("rubrics-version: \\$\\{EVAL_RUBRICS_VERSION:(v[\\d.]+)}")
            .matcher(lire("application.yaml"));
        assertThat(version.find())
            .as("version de grille active introuvable dans application.yaml")
            .isTrue();
        return replier(lire("prompts/production-rubrics-" + version.group(1) + ".json"));
    }

    private static String lire(String chemin) throws Exception {
        try (InputStream is = new ClassPathResource(chemin).getInputStream()) {
            return StreamUtils.copyToString(is, StandardCharsets.UTF_8);
        }
    }

    private static void collecte(Pattern pattern, String grille, String separateur,
                                 Set<String> out) {
        Matcher matcher = pattern.matcher(grille);
        boolean trouve = false;
        while (matcher.find()) {
            trouve = true;
            Arrays.stream(matcher.group(1).split(Pattern.quote(separateur)))
                .map(String::strip)
                .filter(mot -> !mot.isBlank())
                .forEach(out::add);
        }
        assertThat(trouve)
            .as("passage de la grille introuvable : " + pattern.pattern())
            .isTrue();
    }

    /** Minuscules, accents retires — la grille est ecrite sans accents. */
    private static String replier(String texte) {
        return Normalizer.normalize(texte, Normalizer.Form.NFD)
            .replaceAll("\\p{M}+", "")
            .toLowerCase(Locale.FRENCH);
    }
}
