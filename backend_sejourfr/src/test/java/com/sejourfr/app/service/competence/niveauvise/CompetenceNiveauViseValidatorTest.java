package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.util.ProductionTextBounds;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le validateur du SECOND appel — et ce qu'il ne juge PLUS.
 *
 * <p>Depuis le 2026-08-12 (alignement sur les productions), les {@code segments}
 * ne passent plus par ici : ils sont un confort de lecture, filtres un a un par
 * {@code SegmentsSurlignage} et verrouilles par {@code SegmentsSurlignageTest}.
 * Les {@code marqueurs_du_palier} du contrat v2 suivent exactement la meme
 * regle : ils PROUVENT le palier, mais leur perte ne vide jamais l'ecran.
 *
 * <p>Ce que ce validateur tient, c'est la <b>structure</b> du bloc et son
 * <b>texte</b> — presence, forme et desormais <b>longueur</b> : eux seuls
 * peuvent faire tomber la section, et la section tombe SEULE.
 */
class CompetenceNiveauViseValidatorTest {

    private static final String TEXTE =
        "Bonjour, serait-il possible d'obtenir un rendez-vous jeudi prochain ? "
            + "Je vous remercie par avance.";

    private static final int MAX_LEVIERS = 3;

    private CompetenceNiveauViseValidator validator;

    @BeforeEach
    void setUp() {
        CompetenceNiveauViseRubricsProvider rubrics =
            new CompetenceNiveauViseRubricsProvider(new CompetenceProperties(), new ObjectMapper());
        rubrics.load();
        validator = new CompetenceNiveauViseValidator(rubrics);
    }

    // ------------------------------------------------------------ fabriques

    private static Map<String, Object> levier(String action, String exemple) {
        return levier(action, exemple, MarqueurPalier.REGISTRE_AJUSTE);
    }

    static Map<String, Object> levier(String action, String exemple, MarqueurPalier procede) {
        Map<String, Object> l = new LinkedHashMap<>();
        l.put(CompetenceNiveauViseFields.ACTION, action);
        l.put(CompetenceNiveauViseFields.EXEMPLE, exemple);
        if (procede != null) {
            l.put(CompetenceNiveauViseFields.PROCEDE, procede.name());
        }
        return l;
    }

    private static Map<String, Object> segment(String extrait, String apport) {
        Map<String, Object> s = new LinkedHashMap<>();
        s.put(CompetenceNiveauViseFields.EXTRAIT, extrait);
        s.put(CompetenceNiveauViseFields.APPORT, apport);
        return s;
    }

    static Map<String, Object> marqueur(String extrait, MarqueurPalier type) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put(CompetenceNiveauViseFields.EXTRAIT, extrait);
        m.put(CompetenceNiveauViseFields.TYPE, type.name());
        return m;
    }

    static Map<String, Object> sortieValide() {
        Map<String, Object> exemple = new LinkedHashMap<>();
        exemple.put(CompetenceNiveauViseFields.TEXTE, TEXTE);
        exemple.put(CompetenceNiveauViseFields.SEGMENTS, new ArrayList<>(List.of(
            segment("serait-il possible d'obtenir un rendez-vous", "plus poli"),
            segment("Je vous remercie par avance", "cloture soignee"))));
        exemple.put(CompetenceNiveauViseFields.MARQUEURS_PALIER, new ArrayList<>(List.of(
            marqueur("serait-il possible d'obtenir un rendez-vous",
                MarqueurPalier.REGISTRE_AJUSTE),
            marqueur("jeudi prochain", MarqueurPalier.LEXIQUE_PRECIS))));

        Map<String, Object> aRetenir = new LinkedHashMap<>();
        aRetenir.put(CompetenceNiveauViseFields.FORMULE, "Serait-il possible de + infinitif");
        aRetenir.put(CompetenceNiveauViseFields.EXPLICATION,
            "Pour demander quelque chose sans donner d'ordre.");

        Map<String, Object> sortie = new LinkedHashMap<>();
        sortie.put(CompetenceNiveauViseFields.LEVIERS, new ArrayList<>(List.of(
            levier("Formule ta demande plus poliment", "Serait-il possible de"),
            levier("Remercie a la fin", "Je vous remercie"))));
        sortie.put(CompetenceNiveauViseFields.EXEMPLE_CIBLE, exemple);
        sortie.put(CompetenceNiveauViseFields.A_RETENIR, aRetenir);
        return sortie;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> exempleCible(Map<String, Object> sortie) {
        return (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> segments(Map<String, Object> sortie) {
        return (List<Map<String, Object>>)
            exempleCible(sortie).get(CompetenceNiveauViseFields.SEGMENTS);
    }

    private static String mots(int n) {
        return IntStream.range(0, n).mapToObj(i -> "mot").collect(Collectors.joining(" "));
    }

    /** Toutes les violations, sections confondues — sans bornes de longueur. */
    private List<String> violations(Map<String, Object> sortie) {
        return validator.violations(sortie, MAX_LEVIERS, null).toutes();
    }

    // ---------------------------------------------------------------- tests

    @Test
    void sortieConformeAucuneViolation() {
        assertThat(violations(sortieValide())).isEmpty();
    }

    @Test
    void sortieVideEstRefusee() {
        assertThat(violations(null)).isNotEmpty();
        assertThat(violations(Map.of())).isNotEmpty();
    }

    // -------------------------------- le texte, et lui seul, tient la section

    /**
     * ⚠️ REMPLACE l'ancien gel « un extrait invente est refuse » : il faisait
     * tomber tout le bloc — leviers et tournure a retenir compris — pour un
     * surlignage. Le segment fautif est desormais RETIRE par
     * {@code SegmentsSurlignage} ; le validateur, lui, n'a plus rien a en dire.
     */
    @Test
    void unExtraitInventeNEstPlusUneViolation() {
        Map<String, Object> sortie = sortieValide();
        segments(sortie).get(0).put(
            CompetenceNiveauViseFields.EXTRAIT, "veuillez agreer mes salutations");

        assertThat(violations(sortie)).isEmpty();
    }

    /** ⚠️ REMPLACE « moins de deux segments est refuse » et « un apport bavard est refuse ». */
    @Test
    void desSegmentsAbsentsMalTypesOuUniquesNeFontPlusTomberLaSection() {
        Map<String, Object> sansSegments = sortieValide();
        exempleCible(sansSegments).remove(CompetenceNiveauViseFields.SEGMENTS);
        assertThat(violations(sansSegments)).isEmpty();

        Map<String, Object> malTypes = sortieValide();
        exempleCible(malTypes).put(CompetenceNiveauViseFields.SEGMENTS, "pas une liste");
        assertThat(violations(malTypes)).isEmpty();

        Map<String, Object> unSeul = sortieValide();
        exempleCible(unSeul).put(CompetenceNiveauViseFields.SEGMENTS,
            List.of(segment("jeudi prochain", mots(12))));
        assertThat(violations(unSeul)).isEmpty();
    }

    /**
     * MEME REGLE POUR LES MARQUEURS DU PALIER. Ils prouvent le niveau annonce,
     * mais leur perte ne doit jamais vider l'ecran : c'est le tool-schema qui les
     * REQUIERT, pas un refus a posteriori qui couterait au candidat son texte.
     */
    @Test
    void desMarqueursAbsentsOuMalTypesNeFontPasTomberLaSection() {
        Map<String, Object> sansMarqueurs = sortieValide();
        exempleCible(sansMarqueurs).remove(CompetenceNiveauViseFields.MARQUEURS_PALIER);
        assertThat(violations(sansMarqueurs)).isEmpty();

        Map<String, Object> malTypes = sortieValide();
        exempleCible(malTypes).put(CompetenceNiveauViseFields.MARQUEURS_PALIER, "pas une liste");
        assertThat(violations(malTypes)).isEmpty();
    }

    /** Le TEXTE, lui, reste obligatoire : sans lui il n'y a plus rien a montrer. */
    @Test
    void unTexteModeleAbsentOuVideFaitTomberLaSection() {
        Map<String, Object> absent = sortieValide();
        exempleCible(absent).remove(CompetenceNiveauViseFields.TEXTE);
        assertThat(violations(absent))
            .anySatisfy(v -> assertThat(v).contains("exemple_cible.texte", "absent"));

        Map<String, Object> vide = sortieValide();
        exempleCible(vide).put(CompetenceNiveauViseFields.TEXTE, "   ");
        assertThat(violations(vide))
            .anySatisfy(v -> assertThat(v).contains("exemple_cible.texte", "vide"));
    }

    // ------------------------------------------- longueur du texte modele (v2)

    /**
     * LE PLAFOND EST OPPOSE AU MOT PRES. C'est le controle qui manquait : un
     * texte modele de cinquante mots etait servi sur un sujet qui en attend
     * quinze a trente-cinq, et la consigne demandait meme de « garder la
     * longueur » de la production du candidat.
     */
    @Test
    void unTexteModeleAuDelaDuPlafondDuSujetEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        exempleCible(sortie).put(CompetenceNiveauViseFields.TEXTE, mots(50));

        List<String> violations =
            validator.violations(sortie, MAX_LEVIERS, new ProductionTextBounds(15, 35))
                .de(CompetenceNiveauViseValidator.Section.EXEMPLE_CIBLE);

        assertThat(violations).singleElement().satisfies(v -> assertThat(v)
            .startsWith(CompetenceNiveauViseValidator.VIOLATION_LONGUEUR)
            .contains("50 mots", "15 a 35 mots"));
        // Seul motif MECANIQUE de la section, donc le seul qui vaille un appel paye.
        assertThat(CompetenceNiveauViseValidator.uniquementReparables(violations)).isTrue();
    }

    /**
     * PLAFOND SEUL, jamais le plancher : sur un micro-exercice, un texte un peu
     * plus court reste lisible et utile — le faire tomber priverait le candidat
     * de sa version modele pour un mot manquant.
     */
    @Test
    void unTexteModeleSousLePlancherResteServi() {
        Map<String, Object> sortie = sortieValide();
        exempleCible(sortie).put(CompetenceNiveauViseFields.TEXTE, mots(9));

        assertThat(validator.violations(sortie, MAX_LEVIERS, new ProductionTextBounds(15, 35))
            .toutes()).isEmpty();
    }

    /** Sans bornes (sujet ORAL, ou contrat v1), aucune longueur n'est opposee. */
    @Test
    void sansBornesDeclareesAucuneLongueurNEstOpposee() {
        Map<String, Object> sortie = sortieValide();
        exempleCible(sortie).put(CompetenceNiveauViseFields.TEXTE, mots(300));

        assertThat(violations(sortie)).isEmpty();
    }

    @Test
    void uneCleHorsContratDansLExempleCibleResteUneViolation() {
        Map<String, Object> sortie = sortieValide();
        exempleCible(sortie).put("note", 14);

        assertThat(violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("cle hors contrat", "exemple_cible.note"));
    }

    /** Une sortie vide se compte a part : elle ne se corrige pas comme un champ fautif. */
    @Test
    void uneSortieVideEstNommeeCommeTelle() {
        assertThat(violations(Map.of())).singleElement().satisfies(v ->
            assertThat(v).startsWith(CompetenceNiveauViseValidator.VIOLATION_SORTIE_VIDE));
    }

    // ------------------------------------------------------------- sections

    /**
     * UNE SECTION FACULTATIVE NE CONDAMNE PAS LE BLOC. Un texte modele fautif
     * n'a rien a voir avec les leviers, qui ne dependent d'aucun texte : les
     * ranger ensemble aurait fait disparaitre toute la partie « comment y
     * arriver » de l'ecran.
     */
    @Test
    void unExempleCibleFautifNEstPasFatal() {
        Map<String, Object> sortie = sortieValide();
        exempleCible(sortie).remove(CompetenceNiveauViseFields.TEXTE);

        CompetenceNiveauViseValidator.Rapport rapport =
            validator.violations(sortie, MAX_LEVIERS, null);

        assertThat(rapport.fatale()).isFalse();
        assertThat(rapport.de(CompetenceNiveauViseValidator.Section.EXEMPLE_CIBLE)).isNotEmpty();
        assertThat(rapport.de(CompetenceNiveauViseValidator.Section.LEVIERS)).isEmpty();
    }

    @Test
    void desLeviersFautifsEtUneCleRacineSontFatals() {
        Map<String, Object> leviersFautifs = sortieValide();
        leviersFautifs.put(CompetenceNiveauViseFields.LEVIERS, "pas une liste");
        assertThat(validator.violations(leviersFautifs, MAX_LEVIERS, null).fatale()).isTrue();

        Map<String, Object> cleEnTrop = sortieValide();
        cleEnTrop.put("bonus", "x");
        assertThat(validator.violations(cleEnTrop, MAX_LEVIERS, null).fatale()).isTrue();
    }

    // ------------------------------------------------------------- leviers

    @Test
    void moinsDeDeuxLeviersEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceNiveauViseFields.LEVIERS,
            List.of(levier("Formule ta demande poliment", "Serait-il possible de")));

        assertThat(violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("leviers", "au moins 2"));
    }

    @Test
    void plusDeTroisLeviersEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            levier("Un", "un"), levier("Deux", "deux"),
            levier("Trois", "trois"), levier("Quatre", "quatre")));

        assertThat(violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("leviers", "maximum est 3"));
    }

    @Test
    void unLevierIncompletEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            Map.of(CompetenceNiveauViseFields.ACTION, "Formule ta demande poliment"),
            levier("Remercie a la fin", "Je vous remercie")));

        assertThat(violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("leviers[1].exemple", "absent"));
    }

    // ----------------------------------------- le procede d'un levier (v3)

    /**
     * 🛑 LE PROCEDE NE PEUT PAS FAIRE TOMBER LE BLOC. Une violation de la section
     * LEVIERS est FATALE : si le validateur refusait un procede absent, inconnu ou
     * sur-vendu, l'ecran du candidat se viderait pour une etiquette — l'inverse
     * exact du but. Ce qu'il vaut se COMPTE, dans
     * {@link CompetenceNiveauViseProcedeAudit}.
     */
    @Test
    void unProcedeAbsentInconnuOuSurVenduNEstJamaisUneViolation() {
        Map<String, Object> absent = sortieValide();
        absent.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            levier("Formule ta demande poliment", "Serait-il possible de", null),
            levier("Remercie a la fin", "Je vous remercie", null)));
        assertThat(violations(absent)).isEmpty();

        Map<String, Object> inconnu = sortieValide();
        inconnu.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            Map.of(CompetenceNiveauViseFields.ACTION, "Formule ta demande poliment",
                CompetenceNiveauViseFields.EXEMPLE, "Serait-il possible de",
                CompetenceNiveauViseFields.PROCEDE, "TON_CHALEUREUX"),
            levier("Remercie a la fin", "Je vous remercie")));
        assertThat(violations(inconnu)).isEmpty();

        Map<String, Object> surVendu = sortieValide();
        surVendu.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            levier("Traite une objection", "On objectera que", MarqueurPalier.OBJECTION_TRAITEE),
            levier("Remercie a la fin", "Je vous remercie")));
        assertThat(violations(surVendu)).isEmpty();
    }

    /**
     * RETOUR ARRIERE REEL : sous le contrat v2, le champ n'existe pas — il
     * redevient une cle hors contrat, exactement comme avant v3.
     */
    @Test
    void sousLeContratV2LeProcedeRedevientUneCleHorsContrat() {
        CompetenceProperties props = new CompetenceProperties();
        props.getNiveauVise().setRubricsVersion("v2");
        props.getNiveauVise().setToolSchemaVersion("v2");
        CompetenceNiveauViseRubricsProvider v2 =
            new CompetenceNiveauViseRubricsProvider(props, new ObjectMapper());
        v2.load();

        List<String> violations = new CompetenceNiveauViseValidator(v2)
            .violations(sortieValide(), MAX_LEVIERS, null).toutes();

        assertThat(violations).anySatisfy(v ->
            assertThat(v).contains("cle hors contrat", "leviers[1].procede"));
    }

    @Test
    void uneActionBavardeEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        // Plafond 6 mots, tolerance 1,2 -> 7 : huit mots, ce n'est plus une action.
        sortie.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            levier(mots(8), "Serait-il possible de"),
            levier("Remercie a la fin", "Je vous remercie")));

        assertThat(violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("leviers[1].action", "8 mots", "maximum est 6"));
    }

    // ----------------------------------------------------------- a retenir

    @Test
    void uneExplicationBavardeEstRefusee() {
        Map<String, Object> sortie = sortieValide();
        @SuppressWarnings("unchecked")
        Map<String, Object> aRetenir =
            (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.A_RETENIR);
        aRetenir.put(CompetenceNiveauViseFields.EXPLICATION, mots(20));

        assertThat(violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("explication", "maximum est 14"));
    }

    @Test
    void unBlocARetenirManquantEstRefuse() {
        Map<String, Object> sortie = sortieValide();
        sortie.remove(CompetenceNiveauViseFields.A_RETENIR);

        assertThat(violations(sortie))
            .anySatisfy(v -> assertThat(v).contains("a_retenir", "absent"));
    }

    @Test
    void toutesLesViolationsSontCollectees() {
        Map<String, Object> sortie = sortieValide();
        sortie.put("bonus", "x");
        sortie.remove(CompetenceNiveauViseFields.A_RETENIR);
        exempleCible(sortie).remove(CompetenceNiveauViseFields.TEXTE);

        // Une violation par appel couterait un appel LLM par violation.
        assertThat(violations(sortie)).hasSize(3);
    }
}
