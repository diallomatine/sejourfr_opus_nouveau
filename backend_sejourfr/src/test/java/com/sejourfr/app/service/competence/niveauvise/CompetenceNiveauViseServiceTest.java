package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import tools.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * « Pour viser X » — SECOND appel LLM du module Competences, separe de l'analyse.
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>aucun appel n'est emis quand il n'y a rien a viser — c'est de l'argent
 *       economise, pas seulement un bloc absent ;</li>
 *   <li>un echec de ce second appel ne degrade JAMAIS l'analyse : pas
 *       d'exception, pas de bloc, la tentative reste telle quelle ;</li>
 *   <li>le niveau vise n'est envoye qu'a CE prompt-la ;</li>
 *   <li>UNE seule reparation, puis abandon — jamais deux appels payes de plus ;</li>
 *   <li>le serveur pose lui-meme les deux niveaux du bloc.</li>
 * </ul>
 */
class CompetenceNiveauViseServiceTest {

    private static final UUID ATTEMPT_ID = UUID.fromString("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");

    private UserSkillAttemptManager attemptManager;
    private CompetenceNiveauViseLlmClient client;
    private CompetenceProperties props;
    private CompetenceNiveauViseMetrics metrics;
    private CompetenceNiveauViseService service;

    @BeforeEach
    void setUp() {
        attemptManager = mock(UserSkillAttemptManager.class);
        client = mock(CompetenceNiveauViseLlmClient.class);
        when(client.getModelName()).thenReturn("modele-test");
        when(attemptManager.save(any())).thenAnswer(inv -> inv.getArgument(0));

        props = new CompetenceProperties();
        CompetenceNiveauViseRubricsProvider rubrics =
            new CompetenceNiveauViseRubricsProvider(props, new ObjectMapper());
        rubrics.load();
        metrics = new CompetenceNiveauViseMetrics();
        service = new CompetenceNiveauViseService(
            attemptManager, client,
            new CompetenceNiveauVisePromptBuilder(new ObjectMapper(), rubrics),
            new CompetenceNiveauViseValidator(rubrics), rubrics,
            new EvaluationPurgeMetrics(), metrics, props);
    }

    // ------------------------------------------------------------ fabriques

    private UserSkillAttempt attempt(String niveauConstate, TargetProcedure procedure,
                                     TargetLevel declare) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setSection(SkillSection.EE);
        skill.setTaskCode(SkillTaskCode.EE1);
        skill.setCode("EE1-C2");
        skill.setTitle("Formuler une demande");
        skill.setTargetLevel("A2");

        SkillPrompt prompt = new SkillPrompt();
        prompt.setId(UUID.randomUUID());
        prompt.setSkill(skill);
        prompt.setSection(SkillSection.EE);
        prompt.setCode("EE1-C2-S1");
        prompt.setContext("Vous ecrivez au secretariat d'un cabinet medical.");
        prompt.setInstruction("Demandez un rendez-vous.");
        prompt.setUniqueCriterion("Formuler une demande claire et polie.");

        User user = new User();
        user.setId(UUID.randomUUID());
        user.setTargetProcedure(procedure);
        user.setTargetLevel(declare);

        UserSkillAttempt attempt = new UserSkillAttempt();
        attempt.setId(ATTEMPT_ID);
        attempt.setUser(user);
        attempt.setSkillPrompt(prompt);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attempt.setWrittenProduction("Bonjour, je veux un rendez-vous jeudi. Merci.");
        attempt.setTokensInput(1000);
        attempt.setTokensOutput(100);
        attempt.setCoutMicroUsd(2);

        Map<String, Object> analyse = new LinkedHashMap<>();
        analyse.put(CompetenceAnalysisFields.STATUS, "PARTIAL");
        if (niveauConstate != null) {
            analyse.put(CompetenceAnalysisFields.LEVEL_REACHED, niveauConstate);
        }
        analyse.put(CompetenceAnalysisFields.VERDICT, "La demande est la, mais elle est abrupte.");
        analyse.put(CompetenceAnalysisFields.STRENGTH_TAG, "Demande claire");
        analyse.put(CompetenceAnalysisFields.FOCUS_TAG, "Plus de politesse");
        attempt.setAnalysisJson(analyse);

        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.of(attempt));
        return attempt;
    }

    private static CompetenceNiveauViseLlmClient.Outcome outcome(Map<String, Object> sortie) {
        return new CompetenceNiveauViseLlmClient.Outcome(sortie, 800, 200, 3);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> bloc(UserSkillAttempt attempt) {
        return (Map<String, Object>) attempt.getAnalysisJson()
            .get(CompetenceAnalysisFields.BLOC_POUR_VISER);
    }

    // ---------------------------------------------------------- cas nominal

    @Test
    @SuppressWarnings("unchecked")
    void ajouteLeBlocQuandIlResteQuelqueChoseAViser() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        Map<String, Object> bloc = bloc(attempt);
        assertThat(bloc).isNotNull();
        // Les DEUX niveaux sont poses par le SERVEUR : le contrat de sortie ne
        // prevoit aucun champ ou le modele pourrait les ecrire.
        assertThat(bloc.get(CompetenceNiveauViseFields.NIVEAU_VISE)).isEqualTo("B1");
        assertThat(bloc.get(CompetenceNiveauViseFields.NIVEAU_CONSTATE)).isEqualTo("A2");
        assertThat((List<?>) bloc.get(CompetenceNiveauViseFields.LEVIERS)).hasSize(2);
        assertThat(bloc.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE)).isNotNull();
        assertThat(bloc.get(CompetenceNiveauViseFields.A_RETENIR)).isNotNull();
        // L'analyse d'origine est intacte a cote du bloc.
        assertThat(attempt.getAnalysisJson())
            .containsEntry(CompetenceAnalysisFields.FOCUS_TAG, "Plus de politesse");
        verify(attemptManager).save(attempt);
    }

    /**
     * L'EXTRAIT SERVI EST LA SOUS-CHAINE ORIGINALE EXACTE du texte modele.
     *
     * <p>Le validateur compare desormais apres neutralisation typographique — un
     * extrait a l'apostrophe courbe est retrouve dans un texte a l'apostrophe
     * droite. Sans cette resolution, le front recevrait l'extrait tel que rendu
     * par le modele et son surlignage, une simple recherche de chaine, echouerait
     * en silence.
     */
    @Test
    @SuppressWarnings("unchecked")
    void lExtraitPersisteEstUneSousChaineLitteraleDuTexteModele() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        Map<String, Object> exemple =
            (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        List<Map<String, Object>> segments =
            (List<Map<String, Object>>) exemple.get(CompetenceNiveauViseFields.SEGMENTS);
        segments.get(0).put(CompetenceNiveauViseFields.EXTRAIT,
            "serait-il possible d’obtenir un rendez-vous");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        String texte = String.valueOf(servi.get(CompetenceNiveauViseFields.TEXTE));
        for (Map<String, Object> segment
            : (List<Map<String, Object>>) servi.get(CompetenceNiveauViseFields.SEGMENTS)) {
            assertThat(texte).contains(
                String.valueOf(segment.get(CompetenceNiveauViseFields.EXTRAIT)));
        }
    }

    @Test
    void leCoutDuSecondAppelRejointCeluiDeLAnalyse() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        // Sous-estimer le cout sur les cas les plus chers rendrait le suivi faux
        // la ou il sert.
        assertThat(attempt.getTokensInput()).isEqualTo(1800);
        assertThat(attempt.getTokensOutput()).isEqualTo(300);
        assertThat(attempt.getCoutMicroUsd()).isEqualTo(5);
    }

    /**
     * LA DEMARCHE FAIT PLANCHER : NAT exige B2, meme avec un B1 declare — et
     * c'est ce plafond-la qui borne la marche suivante. Depuis un B1 constate,
     * la cible est donc B2 ; avec une demarche CR (B1 exige), il n'y aurait
     * simplement rien a viser.
     */
    @Test
    void laDemarcheFaitPlancherSurLeNiveauDeclare() {
        attempt("B1", TargetProcedure.NAT, TargetLevel.B1);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).produire(anyString(), user.capture());
        assertThat(user.getValue()).contains("\"niveau_vise\":\"B2\"");
        assertThat(user.getValue()).contains("le niveau B2");
    }

    /**
     * LE TEXTE MODELE VISE LA MARCHE SUIVANTE, PAS L'OBJECTIF LOINTAIN.
     *
     * <p>Cas mesure en base : constate A2, objectif B2. Le bloc annonçait « pour
     * viser B2 » et servait un texte que le correcteur, resoumis tel quel par le
     * candidat, a reevalue A2. Un micro-exercice de quelques phrases ne demontre
     * pas deux paliers d'un coup — et les deux ancres de la grille n'enseignent
     * que des sauts d'UN palier.
     */
    @Test
    void unSautDeDeuxPaliersEstRamenceALaMarcheSuivante() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).produire(anyString(), user.capture());
        assertThat(user.getValue())
            .as("l'objectif B2 ne descend jamais jusqu'au redacteur : il ne voit que la cible")
            .contains("\"niveau_vise\":\"B1\"")
            .contains("le niveau B1")
            .doesNotContain("B2");
        // Le bloc persiste la CIBLE : c'est elle que les fronts nomment.
        assertThat(bloc(attempt).get(CompetenceNiveauViseFields.NIVEAU_VISE)).isEqualTo("B1");
    }

    /**
     * LES BORNES DU SUJET SONT INJECTEES, jamais devinees. Sans elles, le modele
     * rendait des textes de cinquante mots sur un sujet qui en attend quinze a
     * trente-cinq, et la consigne lui demandait meme de « garder la longueur »
     * de la production du candidat.
     */
    @Test
    void lesBornesDeLongueurDuSujetPartentDansLePrompt() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        attempt.getSkillPrompt().setRecommendedMinWords(15);
        attempt.getSkillPrompt().setRecommendedMaxWords(35);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).produire(anyString(), user.capture());
        assertThat(user.getValue()).contains("\"mots_min\":15", "\"mots_max\":35")
            .contains("15 a 35 mots");
    }

    // ------------------------------------------------- quand rien n'est emis

    @Test
    void aucunAppelQuandLObjectifEstDejaAtteint() {
        UserSkillAttempt attempt = attempt("B2", TargetProcedure.CR, null);

        service.enrichir(ATTEMPT_ID);

        // Pas seulement « pas de bloc » : pas d'appel PAYE. Montrer une version
        // B1 a quelqu'un qui ecrit deja du B2 serait un contresens, et le payer
        // le serait deux fois.
        verifyNoInteractions(client);
        assertThat(bloc(attempt)).isNull();
        verify(attemptManager, never()).save(any());
    }

    @Test
    void aucunAppelQuandLeNiveauViseEgaleLeNiveauConstate() {
        attempt("B1", TargetProcedure.CR, null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelSurUneAnalyseAncienneSansNiveau() {
        // Contrat v1/v2 : aucun level_reached persiste, rien a comparer.
        attempt(null, TargetProcedure.NAT, null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelQuandLeCoupeCircuitEstOuvert() {
        props.getNiveauVise().setEnabled(false);
        attempt("A2", TargetProcedure.NAT, null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    @Test
    void aucunAppelSansProduction() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        attempt.setWrittenProduction(null);

        service.enrichir(ATTEMPT_ID);

        verifyNoInteractions(client);
    }

    // ------------------------------------------------------- best-effort

    @Test
    void unEchecDuFournisseurNeDegradeJamaisLAnalyse() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        when(client.produire(anyString(), anyString()))
            .thenThrow(new AiEvaluationException("fournisseur indisponible"));

        assertThatCode(() -> service.enrichir(ATTEMPT_ID)).doesNotThrowAnyException();

        assertThat(bloc(attempt)).isNull();
        assertThat(attempt.getStatut()).isEqualTo(SkillAttemptStatut.EVALUATED);
        verify(attemptManager, never()).save(any());
    }

    @Test
    void uneTentativeIntrouvableNeCassePasLePipeline() {
        when(attemptManager.findByIdWithPrompt(ATTEMPT_ID)).thenReturn(Optional.empty());

        assertThatCode(() -> service.enrichir(ATTEMPT_ID)).doesNotThrowAnyException();
        verifyNoInteractions(client);
    }

    // --------------------------------------------------------- reparation

    /**
     * ⚠️ REMPLACE trois gels de l'ancienne regle (« un extrait introuvable
     * declenche une reparation », « son message nomme l'extrait », « il abandonne
     * le bloc apres reparation »). Le surlignage ne vaut plus un appel paye : le
     * segment tombe, le texte reste.
     */
    @Test
    @SuppressWarnings("unchecked")
    void unExtraitIntrouvableRetireLeSegment_sansAppelPayeEtSansPerdreLeTexte() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        segments(sortie).get(0).put(
            CompetenceNiveauViseFields.EXTRAIT, "veuillez agreer mes salutations");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat(servi.get(CompetenceNiveauViseFields.TEXTE)).isNotNull();
        assertThat((List<?>) servi.get(CompetenceNiveauViseFields.SEGMENTS)).hasSize(1);
        assertThat(metrics.compteurs())
            .containsEntry("SEGMENT_RETIRE/EXTRAIT_INTROUVABLE", 1L);
        assertThat(metrics.compteurs().keySet())
            .as("un surlignage ne vaut pas un appel paye")
            .noneMatch(cle -> cle.startsWith("REPARATION/"));
    }

    /** TOUS les segments perdus : le texte est servi seul, sans surlignage. */
    @Test
    @SuppressWarnings("unchecked")
    void tousLesSegmentsInvalides_leTexteEstServiSansSurlignage() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        Map<String, Object> exemple =
            (Map<String, Object>) sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        exemple.put(CompetenceNiveauViseFields.SEGMENTS, List.of(
            "pas un objet",
            Map.of(CompetenceNiveauViseFields.EXTRAIT, "phrase inventee",
                CompetenceNiveauViseFields.APPORT, "plus poli")));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat(servi.get(CompetenceNiveauViseFields.TEXTE)).isNotNull();
        assertThat((List<?>) servi.get(CompetenceNiveauViseFields.SEGMENTS)).isEmpty();
        assertThat(metrics.compteurs())
            .containsEntry("SEGMENT_RETIRE/MALFORME", 1L)
            .containsEntry("SEGMENT_RETIRE/EXTRAIT_INTROUVABLE", 1L);
    }

    /**
     * LE TEXTE TIENT SA SECTION, ET ELLE SEULE. ⚠️ REMPLACE le gel « un texte
     * fautif fait tomber tout le bloc » : les leviers et la tournure a retenir ne
     * dependent d'aucun texte, les perdre avec lui privait le candidat de toute
     * la partie « comment y arriver » de son ecran.
     */
    @Test
    void unTexteModeleFautifFaitTomberSaSectionSeule() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> fautive = CompetenceNiveauViseValidatorTest.sortieValide();
        exempleCible(fautive).put(CompetenceNiveauViseFields.TEXTE, "   ");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(ATTEMPT_ID);

        // Structure fautive : aucun appel paye pour la reparer.
        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> bloc = bloc(attempt);
        assertThat(bloc).isNotNull();
        assertThat(bloc).doesNotContainKey(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat((List<?>) bloc.get(CompetenceNiveauViseFields.LEVIERS)).hasSize(2);
        assertThat(bloc.get(CompetenceNiveauViseFields.A_RETENIR)).isNotNull();
        assertThat(metrics.compteurs())
            .containsEntry("SECTION_ABANDONNEE/EXEMPLE_CIBLE/STRUCTURE", 1L);
    }

    /**
     * TEXTE HORS BORNES : une reparation payee — le motif est mecanique et
     * nommable — puis, si elle ne repare rien, la SECTION seule est abandonnee.
     */
    @Test
    void unTexteModeleHorsBornesDeclencheUneReparationPuisTombeSeul() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        attempt.getSkillPrompt().setRecommendedMinWords(15);
        attempt.getSkillPrompt().setRecommendedMaxWords(35);
        Map<String, Object> tropLong = CompetenceNiveauViseValidatorTest.sortieValide();
        exempleCible(tropLong).put(CompetenceNiveauViseFields.TEXTE, "mot ".repeat(50).trim());
        when(client.produire(anyString(), anyString())).thenReturn(outcome(tropLong));

        service.enrichir(ATTEMPT_ID);

        ArgumentCaptor<String> prompts = ArgumentCaptor.forClass(String.class);
        verify(client, times(2)).produire(anyString(), prompts.capture());
        // Le message de reparation est ACTIONNABLE : compte obtenu, bornes,
        // mots a retirer. Un libelle brut repare 0 cas sur 8 (mesure du depot).
        assertThat(prompts.getAllValues().get(1))
            .contains("50 mots", "15 a 35 mots", "RETIRANT au moins 15");

        Map<String, Object> bloc = bloc(attempt);
        assertThat(bloc).isNotNull().doesNotContainKey(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat((List<?>) bloc.get(CompetenceNiveauViseFields.LEVIERS)).hasSize(2);
        assertThat(metrics.compteurs())
            .containsEntry("REPARATION/TEXTE_HORS_BORNES", 1L)
            .containsEntry("SECTION_ABANDONNEE/EXEMPLE_CIBLE/TEXTE_HORS_BORNES", 1L);
    }

    /** Une reparation reussie rend le bloc complet, texte modele compris. */
    @Test
    void unTexteModeleRameneDansLesBornesEstServi() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        attempt.getSkillPrompt().setRecommendedMinWords(15);
        attempt.getSkillPrompt().setRecommendedMaxWords(35);
        Map<String, Object> tropLong = CompetenceNiveauViseValidatorTest.sortieValide();
        exempleCible(tropLong).put(CompetenceNiveauViseFields.TEXTE, "mot ".repeat(50).trim());
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(tropLong))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(2)).produire(anyString(), anyString());
        assertThat(bloc(attempt)).containsKey(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
    }

    // ------------------------------------------------- marqueurs du palier

    /**
     * UN MARQUEUR QUI SUR-VEND LE PALIER EST RETIRE, sans rien couter d'autre :
     * ni appel paye, ni texte modele. C'est le tool-schema qui REQUIERT ces
     * marqueurs — le refus a posteriori viderait l'ecran.
     */
    @Test
    @SuppressWarnings("unchecked")
    void unMarqueurQuiSurVendLePalierEstRetireSansRienCouterDAutre() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        // Cible B1 : une objection traitee est un procede B2, elle sur-vend.
        marqueurs(sortie).set(1, CompetenceNiveauViseValidatorTest.marqueur(
            "jeudi prochain", MarqueurPalier.OBJECTION_TRAITEE));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat((List<?>) servi.get(CompetenceNiveauViseFields.MARQUEURS_PALIER)).hasSize(1);
        assertThat(servi.get(CompetenceNiveauViseFields.TEXTE)).isNotNull();
        assertThat(metrics.compteurs()).containsEntry("MARQUEUR_RETIRE/TYPE_SUR_VENDU", 1L);
        assertThat(metrics.compteurs().keySet())
            .as("une preuve de palier ne vaut pas un appel paye")
            .noneMatch(cle -> cle.startsWith("REPARATION/"));
    }

    /** Un marqueur introuvable dans le texte modele est retire, comme un segment. */
    @Test
    @SuppressWarnings("unchecked")
    void unMarqueurIntrouvableDansLeTexteEstRetire() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        marqueurs(sortie).set(0, CompetenceNiveauViseValidatorTest.marqueur(
            "une phrase que le modele n'a jamais ecrite", MarqueurPalier.SUBORDINATION));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        assertThat((List<?>) servi.get(CompetenceNiveauViseFields.MARQUEURS_PALIER)).hasSize(1);
        assertThat(metrics.compteurs()).containsEntry("MARQUEUR_RETIRE/EXTRAIT_INTROUVABLE", 1L);
    }

    /**
     * L'EXTRAIT PERSISTE EST LA SOUS-CHAINE ORIGINALE EXACTE, marqueurs compris :
     * c'est ce qui permettra de repondre en SQL a « sur quoi ce B1 etait-il
     * fonde ? » sans avoir a deviner ce que le modele avait en tete.
     */
    @Test
    @SuppressWarnings("unchecked")
    void lExtraitDUnMarqueurPersisteEstUneSousChaineDuTexte() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        marqueurs(sortie).get(0).put(CompetenceNiveauViseFields.EXTRAIT,
            "serait-il possible d’obtenir un rendez-vous");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        Map<String, Object> servi = (Map<String, Object>)
            bloc(attempt).get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        String texte = String.valueOf(servi.get(CompetenceNiveauViseFields.TEXTE));
        for (Map<String, Object> marqueur : (List<Map<String, Object>>)
            servi.get(CompetenceNiveauViseFields.MARQUEURS_PALIER)) {
            assertThat(texte).contains(
                String.valueOf(marqueur.get(CompetenceNiveauViseFields.EXTRAIT)));
        }
    }

    @Test
    void uneSortieStructurellementFausseNOuvreDroitAAucunSecondAppel() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> fautive = CompetenceNiveauViseValidatorTest.sortieValide();
        fautive.put("bonus", "une cle hors contrat");
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        assertThat(bloc(attempt)).isNull();
        assertThat(metrics.compteurs()).containsEntry("BLOC_ABANDONNE/STRUCTURE", 1L);
    }

    @Test
    void uneSortieVideEstCompteeAPart() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        when(client.produire(anyString(), anyString())).thenReturn(outcome(Map.of()));

        service.enrichir(ATTEMPT_ID);

        assertThat(bloc(attempt)).isNull();
        assertThat(metrics.compteurs()).containsEntry("BLOC_ABANDONNE/SORTIE_HORS_CONTRAT", 1L);
    }

    // ------------------------------------------------------- filet A2

    @Test
    @SuppressWarnings("unchecked")
    void unLevierQuiVendUnMoyenA2EstPurgeEtLeResteEstServi() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        List<Map<String, Object>> leviers =
            (List<Map<String, Object>>) sortie.get(CompetenceNiveauViseFields.LEVIERS);
        leviers.add(Map.of(
            CompetenceNiveauViseFields.ACTION, "Relie tes idées",
            CompetenceNiveauViseFields.EXEMPLE, "parce que"));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        // Il reste deux leviers valides : pas de reparation, le bloc est servi.
        verify(client, times(1)).produire(anyString(), anyString());
        assertThat((List<?>) bloc(attempt).get(CompetenceNiveauViseFields.LEVIERS)).hasSize(2);
    }

    @Test
    void moinsDeDeuxLeviersApresPurgeDeclencheUneReparationPuisLAbandon() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.NAT, null);
        Map<String, Object> fautive = CompetenceNiveauViseValidatorTest.sortieValide();
        fautive.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            Map.of(CompetenceNiveauViseFields.ACTION, "Relie tes idées",
                CompetenceNiveauViseFields.EXEMPLE, "parce que"),
            Map.of(CompetenceNiveauViseFields.ACTION, "Enchaîne tes phrases",
                CompetenceNiveauViseFields.EXEMPLE, "mais")));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(fautive));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(2)).produire(anyString(), anyString());
        assertThat(bloc(attempt)).isNull();
        // UN appel paye, et il est compte : c'est le seul motif qui en vaut un.
        assertThat(metrics.compteurs())
            .containsEntry("REPARATION/PURGE_LEVIERS", 1L)
            .containsEntry("BLOC_ABANDONNE/PURGE_LEVIERS", 1L);
    }

    // ------------------------------------------- le procede des leviers (v3)

    /**
     * 🛑 UN PROCEDE FAUTIF NE COUTE PAS SON LEVIER — et c'est tout l'arbitrage de
     * ce chantier. Les leviers portent le bloc entier : les purger sur ce motif
     * viderait l'ecran du candidat, alors que ce qui tient la regle, c'est le
     * SCHEMA (le modele ne peut pas rendre un conseil de ton sans le rattacher a
     * une operation de langue). L'anomalie est comptee, le procede fautif n'est
     * pas persiste, et aucun appel n'est paye.
     */
    @Test
    @SuppressWarnings("unchecked")
    void unProcedeFautifNeCoutePasSonLevier_ilEstCompteEtLeLevierEstServi() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        Map<String, Object> sortie = CompetenceNiveauViseValidatorTest.sortieValide();
        // Cible B1 : traiter une objection est un procede B2, il sur-vend.
        sortie.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            CompetenceNiveauViseValidatorTest.levier("Annonce l'objection", "On objectera que",
                MarqueurPalier.OBJECTION_TRAITEE),
            CompetenceNiveauViseValidatorTest.levier("Remercie a la fin", "Je vous remercie",
                null)));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sortie));

        service.enrichir(ATTEMPT_ID);

        verify(client, times(1)).produire(anyString(), anyString());
        List<Map<String, Object>> leviers =
            (List<Map<String, Object>>) bloc(attempt).get(CompetenceNiveauViseFields.LEVIERS);
        assertThat(leviers).hasSize(2);
        assertThat(leviers).allSatisfy(l ->
            assertThat(l).doesNotContainKey(CompetenceNiveauViseFields.PROCEDE));
        assertThat(metrics.compteurs())
            .containsEntry("PROCEDE_ANORMAL/SUR_VENDU", 1L)
            .containsEntry("PROCEDE_ANORMAL/ABSENT", 1L);
        assertThat(metrics.compteurs().keySet())
            .as("un procede fautif ne vaut pas un appel paye")
            .noneMatch(cle -> cle.startsWith("REPARATION/"));
    }

    /** Un procede valide est persiste — c'est lui qui rend le levier opposable en SQL. */
    @Test
    @SuppressWarnings("unchecked")
    void unProcedeValideEstPersisteSurLeLevier() {
        UserSkillAttempt attempt = attempt("A2", TargetProcedure.CR, null);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        List<Map<String, Object>> leviers =
            (List<Map<String, Object>>) bloc(attempt).get(CompetenceNiveauViseFields.LEVIERS);
        assertThat(leviers).allSatisfy(l -> assertThat(l)
            .containsEntry(CompetenceNiveauViseFields.PROCEDE,
                MarqueurPalier.REGISTRE_AJUSTE.name()));
        assertThat(metrics.compteurs().keySet()).noneMatch(cle -> cle.startsWith("PROCEDE_"));
    }

    /** Le prompt demande le procede — et il lit la table des paliers, pas une copie. */
    @Test
    void lePromptDemandeLeProcedeDeChaqueLevier() {
        attempt("A2", TargetProcedure.CR, null);
        when(client.produire(anyString(), anyString()))
            .thenReturn(outcome(CompetenceNiveauViseValidatorTest.sortieValide()));

        service.enrichir(ATTEMPT_ID);

        ArgumentCaptor<String> systeme = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).produire(systeme.capture(), user.capture());
        assertThat(user.getValue()).contains("`procede`");
        assertThat(systeme.getValue()).contains("`leviers[].procede`");
        assertThat(systeme.getValue()).contains(MarqueurPalier.table().keySet());
    }

    /**
     * RETOUR ARRIERE REEL : sous le contrat v2, le champ n'est ni demande, ni
     * compte — et une sortie qui le porterait quand meme redevient une cle hors
     * contrat, exactement comme avant v3.
     */
    @Test
    void sousLeContratV2LeProcedeNEstNiDemandeNiCompte() {
        CompetenceNiveauViseService v2 = serviceSousContrat("v2");
        attempt("A2", TargetProcedure.CR, null);
        Map<String, Object> sansProcede = CompetenceNiveauViseValidatorTest.sortieValide();
        sansProcede.put(CompetenceNiveauViseFields.LEVIERS, List.of(
            CompetenceNiveauViseValidatorTest.levier("Formule ta demande poliment",
                "Serait-il possible de", null),
            CompetenceNiveauViseValidatorTest.levier("Remercie a la fin", "Je vous remercie",
                null)));
        when(client.produire(anyString(), anyString())).thenReturn(outcome(sansProcede));

        v2.enrichir(ATTEMPT_ID);

        ArgumentCaptor<String> user = ArgumentCaptor.forClass(String.class);
        verify(client).produire(anyString(), user.capture());
        assertThat(user.getValue()).doesNotContain("`procede`");
        assertThat(metrics.compteurs().keySet()).noneMatch(cle -> cle.startsWith("PROCEDE_"));
    }

    /** Le meme service, cable sur un autre contrat — c'est tout le retour arriere. */
    private CompetenceNiveauViseService serviceSousContrat(String version) {
        CompetenceProperties autres = new CompetenceProperties();
        autres.getNiveauVise().setRubricsVersion(version);
        autres.getNiveauVise().setToolSchemaVersion(version);
        CompetenceNiveauViseRubricsProvider rubrics =
            new CompetenceNiveauViseRubricsProvider(autres, new ObjectMapper());
        rubrics.load();
        return new CompetenceNiveauViseService(
            attemptManager, client,
            new CompetenceNiveauVisePromptBuilder(new ObjectMapper(), rubrics),
            new CompetenceNiveauViseValidator(rubrics), rubrics,
            new EvaluationPurgeMetrics(), metrics, autres);
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

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> marqueurs(Map<String, Object> sortie) {
        return (List<Map<String, Object>>)
            exempleCible(sortie).get(CompetenceNiveauViseFields.MARQUEURS_PALIER);
    }
}
