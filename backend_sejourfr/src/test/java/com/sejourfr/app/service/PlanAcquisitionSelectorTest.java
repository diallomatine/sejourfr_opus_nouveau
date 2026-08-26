package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.progression.service.ProgressionPlanBridge;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>Ce qu'il reste a APPRENDRE</b> — la troisieme categorie du Plan.
 *
 * <p>Trois invariants, et rien d'autre : le selecteur ne rend que des
 * competences <b>du palier que CE DOMAINE construit</b>, <b>jamais
 * travaillees</b> et <b>reellement executables</b> — et il ne fabrique
 * <b>rien</b> pour remplir un ecran.
 *
 * <p>🛑 Depuis le 2026-08-26 il ne recoit <b>aucun plafond</b> : le pool est
 * complet, l'affichage coupe ailleurs.
 */
class PlanAcquisitionSelectorTest {

    private static final UUID USER = UUID.randomUUID();

    private SkillManager skillManager;
    private ProgressionPlanBridge bridge;
    private PlanAcquisitionSelector selector;
    private PlanDomainTargetLevelResolver targetLevelResolver;
    private final List<Skill> publiees = new ArrayList<>();

    @BeforeEach
    void setUp() {
        skillManager = mock(SkillManager.class);
        bridge = mock(ProgressionPlanBridge.class);
        // Le pont est en SHADOW : il rend toujours vide, donc c'est le repli
        // « cran au-dessus du niveau DU DOMAINE » qui decide. C'est bien l'etat
        // de production, et c'est la que vit le correctif.
        when(bridge.prescriptionLevel(any(), any(), any())).thenReturn(Optional.empty());
        targetLevelResolver = new PlanDomainTargetLevelResolver(bridge);
        selector = new PlanAcquisitionSelector(skillManager);
        publiees.clear();
    }

    /**
     * Le cas qui a ouvert le chantier : aucune fragilite en oral (rien n'y a
     * jamais ete observe), un palier entier a couvrir. Le Plan doit avoir quelque
     * chose a proposer.
     */
    @Test
    @DisplayName("Sans fragilite mais loin de l'objectif, le Plan a quand meme quoi faire")
    void unCandidatSansFragiliteRecoitDesCompetencesAAcquerir() {
        publie(
                skill("EO1-C1", SkillSection.EO, SkillTaskCode.EO1, "B1", 1),
                skill("EO2-C1", SkillSection.EO, SkillTaskCode.EO2, "B1", 1));

        List<Skill> acquis = selector.select(quatreDomaines(), Set.of(),
                paliers(quatreDomaines()), catalogueComplet());

        assertThat(acquis).extracting(Skill::getCode).containsExactly("EO1-C1", "EO2-C1");
    }

    /**
     * 🛑 <b>LE CORRECTIF DU 2026-08-26.</b> Chaque domaine construit <b>son</b>
     * palier : un candidat <b>EE A2 / EO B1</b> visant le B2 travaille du B1 a
     * l'ecrit et du <b>B2</b> a l'oral. Avant, le palier venait du niveau
     * <b>global</b> (le plancher, A2) : les deux domaines construisaient B1, les
     * competences B2 de l'oral n'etaient candidates a rien, et l'ecran affichait
     * « rien a travailler ».
     */
    @Test
    @DisplayName("Chaque domaine construit SON palier, jamais celui du plancher global")
    void chaqueDomaineConstruitSonPropredPalier() {
        publie(
                skill("EE2-C1", SkillSection.EE, SkillTaskCode.EE2, "B1", 1),
                skill("EE3-C1", SkillSection.EE, SkillTaskCode.EE3, "B2", 1),
                skill("EO2-C1", SkillSection.EO, SkillTaskCode.EO2, "B1", 1),
                skill("EO3-C1", SkillSection.EO, SkillTaskCode.EO3, "B2", 1));

        List<PlanDomainDto> domaines = List.of(
                domaine(EpreuveType.TCF_EE, NiveauCecrl.A2, PlanDomainPriority.FORTE),
                domaine(EpreuveType.TCF_EO, NiveauCecrl.B1,
                        PlanDomainPriority.PAS_ENCORE_PRIORITAIRE));

        assertThat(selector.select(domaines, Set.of(),
                paliers(domaines), catalogueComplet()))
                .extracting(Skill::getCode)
                .as("l'ecrit construit son B1, l'oral son B2")
                .containsExactly("EE2-C1", "EO3-C1");
    }

    /**
     * 🛑 <b>« Pas encore prioritaire » n'a jamais voulu dire « zero action ».</b>
     * Le §93 interdit de faire <b>redescendre</b> un domaine avance ; c'est
     * l'implementation qui avait durci la regle. Un domaine secondaire recoit ses
     * acquisitions, il passe simplement apres.
     */
    @Test
    @DisplayName("Un domaine « pas encore prioritaire » recoit quand meme ses acquisitions")
    void unDomaineSecondaireRecoitQuandMemeSesAcquisitions() {
        publie(skill("EO3-C1", SkillSection.EO, SkillTaskCode.EO3, "B2", 1));

        List<PlanDomainDto> domaines = List.of(
                domaine(EpreuveType.TCF_EO, NiveauCecrl.B1,
                        PlanDomainPriority.PAS_ENCORE_PRIORITAIRE));

        assertThat(selector.select(domaines, Set.of(),
                paliers(domaines), catalogueComplet()))
                .extracting(Skill::getCode).containsExactly("EO3-C1");
    }

    /**
     * 🛑 Et il ne <b>redescend</b> pas pour autant (§17, §93) : un domaine deja
     * au-dessus du palier global ne refait pas le palier inferieur.
     */
    @Test
    @DisplayName("Un domaine avance ne redescend jamais au palier inferieur")
    void unDomaineAvanceNeRedescendPas() {
        publie(
                skill("EO2-C1", SkillSection.EO, SkillTaskCode.EO2, "B1", 1),
                skill("EO3-C1", SkillSection.EO, SkillTaskCode.EO3, "B2", 1));

        List<PlanDomainDto> domaines = List.of(
                domaine(EpreuveType.TCF_EO, NiveauCecrl.B1, PlanDomainPriority.A_TRAVAILLER));

        assertThat(selector.select(domaines, Set.of(),
                paliers(domaines), catalogueComplet()))
                .extracting(Skill::getCode)
                .as("le B1 est derriere lui, on ne le lui repropose pas")
                .containsExactly("EO3-C1");
    }

    /**
     * Un domaine qui a <b>atteint l'objectif</b> n'a plus rien a acquerir : il
     * s'entretient. Aucun palier au-dessus de l'objectif n'est jamais propose.
     */
    @Test
    @DisplayName("Un domaine deja a l'objectif n'a plus rien a acquerir")
    void unDomaineDejaALObjectifNaPlusRienAAcquerir() {
        publie(skill("EO3-C1", SkillSection.EO, SkillTaskCode.EO3, "B2", 1));

        List<PlanDomainDto> domaines = List.of(
                domaine(EpreuveType.TCF_EO, NiveauCecrl.B2, PlanDomainPriority.ENTRETIEN));

        assertThat(selector.select(domaines, Set.of(),
                paliers(domaines), catalogueComplet()))
                .isEmpty();
    }

    /**
     * 🛑 L'invariant central : une competence d'un palier que ce domaine ne
     * construit <b>pas</b> n'entre jamais. Ni du B2 quand il construit son B1, ni
     * du A2 qu'il a deja derriere lui.
     */
    @Test
    @DisplayName("Une competence d'un palier non vise n'apparait pas")
    void unPalierHorsDuCycleEstEcarte() {
        publie(
                skill("EE1-C1", SkillSection.EE, SkillTaskCode.EE1, "A2", 1),
                skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 1),
                skill("EE1-C20", SkillSection.EE, SkillTaskCode.EE1, "B2", 1));

        assertThat(selector.select(quatreDomaines(), Set.of(),
                paliers(quatreDomaines()), catalogueComplet()))
                .extracting(Skill::getCode)
                .as("seul le palier que ce domaine construit est propose")
                .containsExactly("EE1-C9");
    }

    /**
     * 🛑 « A acquerir » veut dire <b>jamais travaillee</b>. Une competence deja
     * observee — solide, fragile ou meme {@code NOT_OBSERVED} — n'en est pas une :
     * la premiere est finie, la deuxieme est une fragilite, et la troisieme se
     * traite par une <b>mesure</b>, pas en proposant d'apprendre ce que le
     * candidat vient peut-etre de faire.
     */
    @Test
    @DisplayName("Une competence deja travaillee — solide comprise — n'est jamais reproposee")
    void uneCompetenceDejaTravailleeNestJamaisReproposee() {
        Skill solide = skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 1);
        Skill vierge = skill("EE2-C9", SkillSection.EE, SkillTaskCode.EE2, "B1", 1);
        publie(solide, vierge);

        assertThat(selector.select(quatreDomaines(), Set.of(solide.getId()),
                paliers(quatreDomaines()), catalogueComplet()))
                .extracting(Skill::getCode).containsExactly("EE2-C9");
    }

    /**
     * 🆕 <b>Filtre de faisabilite</b> : une competence dont aucun sujet n'est
     * publie ne peut porter aucune action. Elle n'entre pas dans le pool — une
     * carte qui ouvre sur du vide est pire que pas de carte.
     */
    @Test
    @DisplayName("Une competence sans contenu publie n'entre pas dans le pool")
    void uneCompetenceSansContenuNentrePasDansLePool() {
        Skill avecSujets = skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 1);
        Skill sansSujet = skill("EE2-C9", SkillSection.EE, SkillTaskCode.EE2, "B1", 1);
        publie(avecSujets, sansSujet);

        PlanContentAvailability.Disponibilite catalogue =
                new PlanContentAvailability.Catalogue(
                        Set.of(avecSujets.getId()), Map.of());

        assertThat(selector.select(quatreDomaines(), Set.of(),
                paliers(quatreDomaines()), catalogue))
                .extracting(Skill::getCode).containsExactly("EE1-C9");
    }

    /**
     * Un domaine <b>jamais mesure</b> se mesure avant de s'apprendre : la porte
     * existe deja ({@code domainesAEvaluer}), en ouvrir une seconde ferait dire
     * deux choses differentes au meme ecran.
     */
    @Test
    @DisplayName("Un domaine jamais mesure ne donne rien a acquerir : il se mesure d'abord")
    void unDomaineNonMesureNeDonneRienAAcquerir() {
        publie(skill("EO1-C1", SkillSection.EO, SkillTaskCode.EO1, "B1", 1));

        List<PlanDomainDto> domaines = new ArrayList<>(quatreDomaines());
        domaines.replaceAll(domaine -> domaine.epreuve() == EpreuveType.TCF_EO
                ? PlanDomainDto.sansCompetences(EpreuveType.TCF_EO, false, null,
                        PlanDomainPriority.A_EVALUER, null, null, List.of(), List.of())
                : domaine);

        assertThat(selector.select(domaines, Set.of(),
                paliers(domaines), catalogueComplet())).isEmpty();
    }

    /**
     * L'urgence des domaines est celle que le serveur a <b>deja</b> decidee : on
     * ne la recalcule pas ici, deux classements auraient fini par se contredire a
     * l'ecran.
     */
    @Test
    @DisplayName("L'ordre suit l'urgence du domaine, puis l'ordre editorial")
    void lOrdreSuitLUrgenceDesDomaines() {
        publie(
                skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 2),
                skill("EE1-C8", SkillSection.EE, SkillTaskCode.EE1, "B1", 1),
                skill("EO1-C9", SkillSection.EO, SkillTaskCode.EO1, "B1", 1));

        // L'oral est « Priorite forte », l'ecrit seulement « Entretien ».
        List<PlanDomainDto> domaines = List.of(
                domaine(EpreuveType.TCF_CO, NiveauCecrl.A2, PlanDomainPriority.ENTRETIEN),
                domaine(EpreuveType.TCF_CE, NiveauCecrl.A2, PlanDomainPriority.ENTRETIEN),
                domaine(EpreuveType.TCF_EE, NiveauCecrl.A2, PlanDomainPriority.ENTRETIEN),
                domaine(EpreuveType.TCF_EO, NiveauCecrl.A2, PlanDomainPriority.FORTE));

        assertThat(selector.select(domaines, Set.of(),
                paliers(domaines), catalogueComplet()))
                .extracting(Skill::getCode)
                .containsExactly("EO1-C9", "EE1-C8", "EE1-C9");
    }

    /** Deux lectures du meme etat rendent exactement la meme liste. */
    @Test
    @DisplayName("La selection est deterministe")
    void laSelectionEstDeterministe() {
        publie(
                skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 1),
                skill("EO1-C9", SkillSection.EO, SkillTaskCode.EO1, "B1", 1));

        assertThat(selector.select(quatreDomaines(), Set.of(),
                paliers(quatreDomaines()), catalogueComplet()))
                .isEqualTo(selector.select(quatreDomaines(), Set.of(),
                paliers(quatreDomaines()), catalogueComplet()));
    }

    /**
     * Sans objectif declare il n'y a rien a construire — et surtout aucune
     * requete a emettre : on ne devine pas une demarche a la place du candidat.
     */
    @Test
    @DisplayName("Sans objectif, aucune requete n'est emise")
    void sansObjectifAucuneRequeteNestEmise() {
        assertThat(selector.select(quatreDomaines(), Set.of(),
                targetLevelResolver.parSection(USER, quatreDomaines(), null), catalogueComplet()))
                .isEmpty();
        assertThat(selector.select(List.of(), Set.of(),
                paliers(List.of()), catalogueComplet()))
                .isEmpty();

        verify(skillManager, never()).findActiveByTargetLevels(anyCollection());
    }

    /**
     * 🛑 <b>Un seul lot, quels que soient les paliers</b> : deux domaines qui
     * construisent deux paliers differents ne coutent pas deux requetes. C'est la
     * condition posee pour que le budget de requetes du Plan puisse augmenter —
     * il augmente d'un nombre <b>fixe</b>, jamais d'un N+1.
     */
    @Test
    @DisplayName("Deux paliers differents se chargent en une seule requete")
    void deuxPaliersDifferentsSeChargentEnUneSeuleRequete() {
        publie(
                skill("EE2-C1", SkillSection.EE, SkillTaskCode.EE2, "B1", 1),
                skill("EO3-C1", SkillSection.EO, SkillTaskCode.EO3, "B2", 1));

        List<PlanDomainDto> domaines = List.of(
                domaine(EpreuveType.TCF_EE, NiveauCecrl.A2, PlanDomainPriority.FORTE),
                domaine(EpreuveType.TCF_EO, NiveauCecrl.B1, PlanDomainPriority.A_TRAVAILLER));

        assertThat(selector.select(domaines, Set.of(),
                paliers(domaines), catalogueComplet()))
                .hasSize(2);

        verify(skillManager).findActiveByTargetLevels(anyCollection());
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private void publie(Skill... skills) {
        publiees.addAll(Arrays.asList(skills));
        when(skillManager.findActiveByTargetLevels(anyCollection()))
                .thenAnswer(invocation -> {
                    Collection<?> paliers = invocation.getArgument(0);
                    return List.of(skills).stream()
                            .filter(skill -> paliers.contains(skill.getTargetLevel()))
                            .toList();
                });
    }

    /** Le palier de chaque domaine, resolu par l'autorite unique. */
    private Map<SkillSection, TargetLevel> paliers(List<PlanDomainDto> domaines) {
        return targetLevelResolver.parSection(USER, domaines, TargetLevel.B2);
    }

    /** Tout ce qui est publie a du contenu : ces tests decrivent la selection. */
    private PlanContentAvailability.Disponibilite catalogueComplet() {
        return new PlanContentAvailability.Catalogue(
                publiees.stream().map(Skill::getId)
                        .collect(Collectors.toCollection(LinkedHashSet::new)),
                Map.of());
    }

    /** Les quatre domaines, tous mesures A2, tous a la meme urgence. */
    private static List<PlanDomainDto> quatreDomaines() {
        return List.of(
                domaine(EpreuveType.TCF_CO, NiveauCecrl.A2, PlanDomainPriority.A_TRAVAILLER),
                domaine(EpreuveType.TCF_CE, NiveauCecrl.A2, PlanDomainPriority.A_TRAVAILLER),
                domaine(EpreuveType.TCF_EE, NiveauCecrl.A2, PlanDomainPriority.A_TRAVAILLER),
                domaine(EpreuveType.TCF_EO, NiveauCecrl.A2, PlanDomainPriority.A_TRAVAILLER));
    }

    private static PlanDomainDto domaine(
            EpreuveType epreuve, NiveauCecrl niveau, PlanDomainPriority priority) {
        return PlanDomainDto.sansCompetences(epreuve, true, niveau, priority,
                TargetLevel.A2, TargetLevel.B1, List.of(), List.of());
    }

    private static Skill skill(
            String code, SkillSection section, SkillTaskCode tache, String palier, int rang) {
        Skill skill = new Skill();
        skill.setId(UUID.randomUUID());
        skill.setCode(code);
        skill.setTitle("Compétence " + code);
        skill.setSection(section);
        skill.setTaskCode(tache);
        skill.setTargetLevel(palier);
        skill.setDisplayOrder((short) rang);
        return skill;
    }
}
