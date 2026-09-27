package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyExamenCompletDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyFinDeCycle;
import com.sejourfr.app.enums.JourneyJalonRaison;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauProvenance;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.TcfProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Le jalon « Faire un examen blanc complet »</b> — l'autorite UNIQUE de
 * « est-il propose ? » (2026-09-27, D-68, decision du proprietaire).
 *
 * <p>L'examen blanc complet n'est plus une etape de fin de cycle (D-66) : c'est
 * un <b>jalon propose</b>, au-dessus du Plan, sous la carte « À faire
 * maintenant ». Il est propose quand l'une des deux conditions tient :
 * <ol>
 *   <li><b>{@code examenCompletJalonCycles} cycles de TRAVAIL termines depuis le
 *       dernier examen blanc complet</b> (3 en v4) — le compteur repart de zero
 *       apres chaque examen complet, donc le jalon revient tous les trois
 *       cycles ;</li>
 *   <li><b>le niveau objectif est atteint partout</b> — les quatre epreuves
 *       (TCF) ou les cinq thematiques (civique) —, <b>mesure par un examen
 *       blanc</b>, jamais par le diagnostic.</li>
 * </ol>
 *
 * <p>🛑 <b>Deux lecteurs, une regle</b> : la lecture du parcours
 * ({@code JourneyDto.examenComplet}) et le refus 409 du geste
 * ({@code JourneyCycleService.creerCycleDeMesure}). Le bouton servi et le refus
 * serveur ne peuvent pas diverger.
 *
 * <h2>Ce qui compte comme « cycle de travail termine »</h2>
 * <ul>
 *   <li>un cycle <b>historise</b> qui porte au moins une etape d'entrainement
 *       (obsoletes exclues) — un <b>cycle d'examens</b> n'en porte aucune, il
 *       ne compte donc pas ;</li>
 *   <li>🛑 <b>jamais le cycle d'AFFINAGE</b> (D-64) : son objet est de
 *       <b>mesurer</b> les epreuves une a une, ses competences sont
 *       facultatives. Autonomie, cf. A165 ;</li>
 *   <li>le cycle <b>en cours</b> compte des qu'il est termine
 *       ({@code JourneyCycleAffinage.termine}) : « trois cycles termines » est
 *       vrai avant qu'on actualise le troisieme — le candidat voit alors, en
 *       meme temps, « Actualiser mon plan » et le jalon.</li>
 * </ul>
 *
 * <h2>Ce qui remet le compteur a zero</h2>
 * <p>Un cycle historise par le jalon lui-meme — {@code INTERROMPU} ou
 * {@code EXAMEN_COMPLET} ({@code journey.fin_de_cycle}, V077/V078) : le cycle
 * qui le suit est le cycle d'examens. 🛑 Un <b>evenement persiste</b>, jamais
 * une derivation : un cycle sans entrainement n'est pas forcement un cycle
 * d'examens (un cycle promu vide ne porte que des « Évaluer mon niveau »).
 *
 * <h2>🛑 Jamais propose</h2>
 * <ul>
 *   <li>sur un <b>cycle d'examens</b> (cycle de mesure) : on y est deja ;</li>
 *   <li>au titre de l'objectif atteint, <b>juste apres un examen complet</b>
 *       (aucun cycle de travail termine depuis) : enchainer deux examens
 *       complets sans travail entre eux ne mesure rien de nouveau.</li>
 * </ul>
 *
 * <p>🛑 <b>Freemium inchange</b> : le jalon ne porte aucun verrou. Le cycle
 * d'examens qu'il ouvre porte, lui, les verrous d'acces de chaque examen
 * ({@code lockReason = ACCESS}), lus chez leurs autorites.
 */
@Component
@RequiredArgsConstructor
public class JourneyJalonExamenComplet {

    /**
     * Examens de theme civiques relus pour trouver le dernier de chaque theme.
     * Un plafond de lecture, pas un budget : un theme dont le dernier examen
     * tomberait au-dela reste « non atteint » — inconnu, jamais atteint.
     */
    static final int EXAMENS_DE_THEME_LUS = 100;

    private final JourneyManager journeyManager;
    private final TcfJourneyConfig config;
    private final TcfProfileService profileService;
    private final AttemptManager attemptManager;
    private final ThemeManager themeManager;

    /**
     * Le jalon est-il propose sur ce cycle EN COURS ?
     *
     * @param courant  le cycle en cours du candidat.
     * @param etapes   ses etapes, obsoletes comprises ou non.
     * @param affinage ce cycle est-il un cycle d'affinage
     *                 ({@link JourneyCycleAffinage}) ? Deja lu par l'appelant.
     * @return le jalon, ou {@code null} quand il n'est pas propose.
     */
    public JourneyExamenCompletDto pour(Journey courant, List<JourneyStep> etapes, boolean affinage) {
        List<JourneyStep> affichables = etapes.stream()
                .filter(step -> step.getResolution() != JourneyStepResolution.SUPERSEDED)
                .toList();
        if (JourneyBlocResolver.cycleDeMesure(affichables)) return null;

        UUID userId = courant.getUser().getId();
        Compte compte = compter(journeyManager.cyclesClos(userId, courant.getModule()),
                courant.getModule());
        boolean courantTermineDeTravail = !affinage
                && porteDuTravail(affichables)
                && JourneyCycleAffinage.termine(affichables, false);
        int cycles = compte.cyclesDepuis() + (courantTermineDeTravail ? 1 : 0);

        Integer seuil = config.examenCompletJalonCycles();
        boolean parCycles = seuil != null && cycles >= seuil;
        boolean justeApresUnExamen = compte.examenDejaLance() && cycles == 0;
        if (!parCycles && justeApresUnExamen) return null;

        // 🛑 L'OBJECTIF L'EMPORTE quand les deux tiennent : c'est la plus forte
        // des deux raisons de se mesurer. Lue apres le compte, parce qu'elle
        // coute des requetes et que le compte n'en coute qu'une.
        if (!justeApresUnExamen && objectifAtteintParExamen(courant)) {
            return new JourneyExamenCompletDto(JourneyJalonRaison.OBJECTIF_ATTEINT, cycles);
        }
        return parCycles
                ? new JourneyExamenCompletDto(JourneyJalonRaison.CYCLES_DE_TRAVAIL, cycles)
                : null;
    }

    /** Ce que l'historique dit : cycles de travail depuis le dernier examen complet. */
    private record Compte(int cyclesDepuis, boolean examenDejaLance) {}

    private Compte compter(List<JourneyManager.CycleClos> clos, Module module) {
        int cycles = 0;
        boolean examen = false;
        boolean premier = true;
        for (JourneyManager.CycleClos cycle : clos) {
            boolean rangUn = premier;
            premier = false;
            if (cycle.finDeCycle() == JourneyFinDeCycle.INTERROMPU
                    || cycle.finDeCycle() == JourneyFinDeCycle.EXAMEN_COMPLET) {
                // Le cycle d'examens commence apres celui-ci : on repart de zero.
                cycles = 0;
                examen = true;
                continue;
            }
            if (cycle.competences() == 0) continue;
            // 🛑 Le cycle d'AFFINAGE (D-64) n'est pas un cycle de travail : meme
            // definition que `JourneyCycleAffinage.pour`, rang 1 + amorce par le
            // diagnostic rapide. La requete n'est posee que sur ce cycle-la.
            if (rangUn && module == Module.TCF
                    && journeyManager.amorceParLeDiagnosticRapide(cycle.id())) {
                continue;
            }
            cycles++;
        }
        return new Compte(cycles, examen);
    }

    private static boolean porteDuTravail(List<JourneyStep> affichables) {
        return affichables.stream().anyMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL);
    }

    /**
     * <b>L'objectif est-il atteint partout, par un examen blanc ?</b>
     *
     * <p>🛑 {@code null} = inconnu, jamais atteint : une epreuve ou une
     * thematique sans examen ne ferme pas la condition.
     */
    private boolean objectifAtteintParExamen(Journey courant) {
        UUID userId = courant.getUser().getId();
        return courant.getModule() == Module.CIVIQUE
                ? tousLesThemesReussis(userId)
                : toutesLesEpreuvesAuNiveau(userId, courant.getTargetLevel());
    }

    /**
     * TCF : chaque epreuve a un palier <b>au moins egal</b> a l'objectif, et ce
     * palier vient d'un <b>examen blanc</b> ({@code NiveauProvenance.EXAMEN_BLANC},
     * commit 9b622650) — jamais du repli sur le diagnostic rapide.
     *
     * <p>🛑 Le palier lu est celui de l'<b>Accueil</b>
     * ({@code TcfProfileService.levelProfileAccueilDetaille}) : le niveau
     * ACTUEL estime, qui peut redescendre. Le Plan garde son maximum, qui ne
     * dirait jamais qu'un examen recent a ete moins bon.
     */
    private boolean toutesLesEpreuvesAuNiveau(UUID userId, TargetLevel cible) {
        if (cible == null) return false;
        NiveauCecrl requis = NiveauCecrl.valueOf(cible.name());
        TcfProfileService.ProfilAccueil profil = profileService.levelProfileAccueilDetaille(userId);
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            NiveauCecrl niveau = niveau(profil.profil(), epreuve);
            if (niveau == null) return false;
            if (profil.provenance(epreuve) != NiveauProvenance.EXAMEN_BLANC) return false;
            if (niveau.ordinal() < requis.ordinal()) return false;
        }
        return true;
    }

    private static NiveauCecrl niveau(TcfLevelProfile profil, EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO -> profil.co();
            case TCF_CE -> profil.ce();
            case TCF_EE -> profil.ee();
            case TCF_EO -> profil.eo();
            default -> null;
        };
    }

    /**
     * Civique : le <b>dernier examen de theme</b> de chacune des cinq
     * thematiques est reussi — au seuil <b>servi par l'attempt</b>, a defaut
     * {@link CivicExamFormat#SEUIL_REUSSITE_THEME} (16/20, 80 % comme
     * l'officiel), la meme lecture que l'ecran de progression d'un theme.
     *
     * <p>⚠️ Un examen civique <b>global</b> (40 questions) ne compte pas ici :
     * son score n'est celui d'aucune thematique. Le diagnostic civique non
     * plus : il est exclu en base ({@code civic_diagnostic_id IS NULL}).
     */
    private boolean tousLesThemesReussis(UUID userId) {
        List<Theme> thematiques = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        if (thematiques.isEmpty()) return false;
        Map<UUID, Attempt> dernier = new LinkedHashMap<>();
        for (Attempt examen : attemptManager.findCivicExamensThemePasses(
                userId, thematiques.stream().map(Theme::getId).toList(), EXAMENS_DE_THEME_LUS)) {
            // Du plus recent au plus ancien : le premier rencontre fait foi.
            dernier.putIfAbsent(examen.getLotThemeId(), examen);
        }
        for (Theme thematique : thematiques) {
            Attempt examen = dernier.get(thematique.getId());
            if (examen == null || examen.getScore() == null) return false;
            int seuil = examen.getPassThreshold() != null
                    ? examen.getPassThreshold()
                    : CivicExamFormat.SEUIL_REUSSITE_THEME;
            if (examen.getScore() < seuil) return false;
        }
        return true;
    }
}
