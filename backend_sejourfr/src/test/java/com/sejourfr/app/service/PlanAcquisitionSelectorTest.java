package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanCycleDto;
import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanCycleState;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.SkillManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * <b>Ce qu'il reste a APPRENDRE</b> — la troisieme categorie du Plan.
 *
 * <p>Tout ce qui est verifie ici tient en une phrase : le selecteur ne rend que
 * des competences <b>du palier en construction</b> que le candidat n'a
 * <b>jamais travaillees</b>, et il ne fabrique <b>rien</b> pour remplir l'ecran.
 */
class PlanAcquisitionSelectorTest {

    private SkillManager skillManager;
    private PlanAcquisitionSelector selector;

    @BeforeEach
    void setUp() {
        skillManager = mock(SkillManager.class);
        selector = new PlanAcquisitionSelector(skillManager);
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

        List<Skill> acquis = selector.select(
                cycle(TargetLevel.B1), quatreDomaines(), Set.of(), 5);

        assertThat(acquis).extracting(Skill::getCode).containsExactly("EO1-C1", "EO2-C1");
    }

    /**
     * 🛑 L'invariant central : une competence d'un palier que le cycle ne
     * construit <b>pas</b> n'entre jamais. On n'envoie pas un candidat qui
     * construit son B1 travailler du B2 — ni du A2 qu'il a deja derriere lui.
     */
    @Test
    @DisplayName("Une competence d'un palier non vise n'apparait pas")
    void unPalierHorsDuCycleEstEcarte() {
        publie(
                skill("EE1-C1", SkillSection.EE, SkillTaskCode.EE1, "A2", 1),
                skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 1),
                skill("EE1-C20", SkillSection.EE, SkillTaskCode.EE1, "B2", 1));

        List<Skill> acquis = selector.select(
                cycle(TargetLevel.B1), quatreDomaines(), Set.of(), 5);

        assertThat(acquis).extracting(Skill::getCode)
                .as("seul le palier en construction est propose")
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

        List<Skill> acquis = selector.select(
                cycle(TargetLevel.B1), quatreDomaines(), Set.of(solide.getId()), 5);

        assertThat(acquis).extracting(Skill::getCode).containsExactly("EE2-C9");
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
                ? new PlanDomainDto(EpreuveType.TCF_EO, false, null,
                        PlanDomainPriority.A_EVALUER, null, null, List.of(), List.of())
                : domaine);

        assertThat(selector.select(cycle(TargetLevel.B1), domaines, Set.of(), 5)).isEmpty();
    }

    /**
     * 🛑 Le plafond est un <b>plafond</b>, jamais un quota : il coupe ce qui
     * depasse, il ne complete rien. Et sous le plafond, tout ce qui est vrai est
     * servi.
     */
    @Test
    @DisplayName("Le plafond coupe ce qui depasse et ne fabrique jamais rien")
    void lePlafondCoupeMaisNeRemplitPas() {
        publie(
                skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 1),
                skill("EE2-C9", SkillSection.EE, SkillTaskCode.EE2, "B1", 1),
                skill("EE3-C9", SkillSection.EE, SkillTaskCode.EE3, "B1", 1));

        assertThat(selector.select(cycle(TargetLevel.B1), quatreDomaines(), Set.of(), 2))
                .extracting(Skill::getCode).containsExactly("EE1-C9", "EE2-C9");
        assertThat(selector.select(cycle(TargetLevel.B1), quatreDomaines(), Set.of(), 10))
                .as("rien n'est invente pour atteindre la limite")
                .hasSize(3);
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
                domaine(EpreuveType.TCF_CO, PlanDomainPriority.ENTRETIEN),
                domaine(EpreuveType.TCF_CE, PlanDomainPriority.ENTRETIEN),
                domaine(EpreuveType.TCF_EE, PlanDomainPriority.ENTRETIEN),
                domaine(EpreuveType.TCF_EO, PlanDomainPriority.FORTE));

        assertThat(selector.select(cycle(TargetLevel.B1), domaines, Set.of(), 5))
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

        assertThat(selector.select(cycle(TargetLevel.B1), quatreDomaines(), Set.of(), 5))
                .isEqualTo(selector.select(cycle(TargetLevel.B1), quatreDomaines(), Set.of(), 5));
    }

    /**
     * Sans palier en construction il n'y a rien a apprendre — et surtout aucune
     * requete a emettre : c'est le seul cas ou le referentiel n'est pas charge.
     */
    @Test
    @DisplayName("Sans cycle, aucune requete n'est emise")
    void sansCycleAucuneRequeteNestEmise() {
        assertThat(selector.select(null, quatreDomaines(), Set.of(), 5)).isEmpty();
        assertThat(selector.select(cycle(null), quatreDomaines(), Set.of(), 5)).isEmpty();

        verify(skillManager, never()).findActiveByTargetLevels(anyCollection());
    }

    /**
     * 🛑 Le referentiel est charge <b>meme quand il ne reste aucune place</b> :
     * le nombre de places depend des fragilites du candidat, et faire dependre un
     * aller-retour en base de ses donnees rendrait le cout du Plan variable d'un
     * compte a l'autre — donc invérifiable. Une requete bornee et previsible vaut
     * mieux qu'une economie invisible.
     */
    @Test
    @DisplayName("Le cout ne depend pas des donnees : le referentiel se charge meme sans place")
    void leCoutNeDependPasDesDonnees() {
        publie(skill("EE1-C9", SkillSection.EE, SkillTaskCode.EE1, "B1", 1));

        assertThat(selector.select(cycle(TargetLevel.B1), quatreDomaines(), Set.of(), 0))
                .isEmpty();

        verify(skillManager).findActiveByTargetLevels(anyCollection());
    }

    // ------------------------------------------------------------------------
    // Fabriques
    // ------------------------------------------------------------------------

    private void publie(Skill... skills) {
        when(skillManager.findActiveByTargetLevels(anyCollection()))
                .thenAnswer(invocation -> {
                    Collection<?> paliers = invocation.getArgument(0);
                    return List.of(skills).stream()
                            .filter(skill -> paliers.contains(skill.getTargetLevel()))
                            .toList();
                });
    }

    private static PlanCycleDto cycle(TargetLevel enConstruction) {
        return new PlanCycleDto(NiveauCecrl.A2, enConstruction, TargetLevel.B2,
                PlanCycleState.TRAINING, 4, 4, true, List.of());
    }

    /** Les quatre domaines, tous mesures, tous a la meme urgence. */
    private static List<PlanDomainDto> quatreDomaines() {
        return List.of(
                domaine(EpreuveType.TCF_CO, PlanDomainPriority.A_TRAVAILLER),
                domaine(EpreuveType.TCF_CE, PlanDomainPriority.A_TRAVAILLER),
                domaine(EpreuveType.TCF_EE, PlanDomainPriority.A_TRAVAILLER),
                domaine(EpreuveType.TCF_EO, PlanDomainPriority.A_TRAVAILLER));
    }

    private static PlanDomainDto domaine(EpreuveType epreuve, PlanDomainPriority priority) {
        return new PlanDomainDto(epreuve, true, NiveauCecrl.A2, priority,
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
