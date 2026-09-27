package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyCycleArchiveDto;
import com.sejourfr.app.dto.JourneyExamResultDto;
import com.sejourfr.app.dto.JourneyHistoryBlocDto;
import com.sejourfr.app.dto.JourneyBlocRefDto;
import com.sejourfr.app.dto.JourneyHistoryCycleDto;
import com.sejourfr.app.dto.JourneyHistoryDto;
import com.sejourfr.app.dto.JourneyHistoryStatsDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyBlocKind;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.manager.ThemeManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>L'historique des cycles</b> — ce que sert
 * {@code GET /api/me/plan/journey/history} a la page « Ma progression »
 * (maquette {@code docs/progression/histo_cycle.html}).
 *
 * <h2>🛑 Ce service ne mesure rien et ne recalcule rien</h2>
 * <p>Il <b>raconte</b>. Chaque fait qu'il sert est deja ecrit :
 * <ul>
 *   <li>les dates : {@code journey.created_at} et {@code journey.historise_at} ;</li>
 *   <li>les niveaux d'entree et de sortie : les colonnes {@code entry_level} /
 *       {@code exit_level}, <b>lues telles quelles</b>. 🛑 <b>Aucun recalcul
 *       retroactif</b> (D-12, A35) : c'est un fait date, et {@code null} reste
 *       {@code null} — inconnu, jamais mauvais, et <b>jamais A2 par defaut</b> ;</li>
 *   <li>les competences travaillees : les etapes {@code TRAIN_SKILL} closes, et
 *       leur <b>titre</b> lu sur {@code skills.title}, un fait editorial deja
 *       servi ailleurs ;</li>
 *   <li>le rang d'un cycle : {@link JourneyCycleRank}, <b>partage</b> avec la
 *       lecture du Plan pour que les deux ecrans ne puissent pas annoncer deux
 *       nombres differents.</li>
 * </ul>
 *
 * <h2>Le cout : DEUX requetes, quel que soit le nombre de cycles</h2>
 * <p>Une pour les cycles ({@code JourneyManager.racontables}), une pour
 * <b>toutes</b> leurs etapes closes en un lot
 * ({@code JourneyStepManager.findCloturesDesCycles}, competence
 * {@code JOIN FETCH}). Un candidat de six mois paie donc exactement ce que paie
 * un nouveau. 🛑 Une requete par cycle aurait fait grimper le cout avec
 * l'anciennete du compte, et la regression serait restee invisible en unitaire —
 * meme raison que le budget de requetes fixe du Plan.
 */
@Service
@RequiredArgsConstructor
public class JourneyHistoryService {

    private final JourneyManager journeyManager;
    private final ThemeManager themeManager;
    private final JourneyStepManager stepManager;
    private final JourneyReadService readService;
    private final JourneyExamResultReader examResultReader;

    /**
     * L'historique du candidat sur le module demande.
     *
     * <p>🛑 <b>Le MODULE est le seul parametre au-dela de l'identite</b>
     * (B-10) : le serveur sait qui lit. ⚠️ <b>Revoque « le civique sort du
     * chantier »</b> (D-23) : depuis P8.4 son cycle existe, et depuis P8.9 il
     * se raconte ici avec le meme service — une seconde lecture aurait diverge
     * a la premiere correction.
     *
     * <p>Un candidat sans aucun cycle ferme recoit {@code cycles} <b>vide</b> et
     * des statistiques a <b>zero</b>, jamais {@code null} : l'ecran sait dire
     * « rien encore ».
     */
    @Transactional(readOnly = true)
    public JourneyHistoryDto lire(UUID userId, Module module) {
        // Requete 1 : les cycles, du plus ancien au plus recent — c'est l'ordre
        // qui DEFINIT le rang (JourneyCycleRank), pas celui de l'affichage.
        List<Journey> parCreation = journeyManager.racontables(userId, module);

        // Requete 2 : toutes leurs etapes closes, en un lot. Zero cycle, zero
        // requete.
        Map<UUID, List<JourneyStep>> etapesParCycle = etapesParCycle(
                stepManager.findCloturesDesCycles(
                        parCreation.stream().map(Journey::getId).toList()));

        List<JourneyHistoryCycleDto> cycles = new ArrayList<>();
        int competencesTravaillees = 0;
        int examensPasses = 0;

        for (int rangZeroBase = 0; rangZeroBase < parCreation.size(); rangZeroBase++) {
            Journey cycle = parCreation.get(rangZeroBase);
            List<JourneyStep> etapes =
                    etapesParCycle.getOrDefault(cycle.getId(), List.of());
            int competences = compter(etapes, JourneyStepType.TRAIN_SKILL);
            int examens = compterExamens(etapes);

            // 🛑 Les compteurs d'en-tete portent sur TOUS les cycles, le cycle en
            // cours COMPRIS : l'ecran dit « tout ce que vous avez deja
            // travaille », pas « dans vos cycles clos ». Les exclure ferait
            // reculer un compteur au demarrage du cycle suivant.
            competencesTravaillees += competences;
            examensPasses += examens;

            if (cycle.getStatus() != JourneyStatus.HISTORISE) continue;

            cycles.add(new JourneyHistoryCycleDto(
                    cycle.getId(),
                    // Le rang est la place du cycle dans l'ordre de creation :
                    // une seule regle pour les deux ecrans.
                    JourneyCycleRank.rang(rangZeroBase),
                    cycle.getCreatedAt(),
                    cycle.getHistoriseAt(),
                    cycle.getFinDeCycle(),
                    competences,
                    examens,
                    cycle.getEntryLevel(),
                    cycle.getExitLevel(),
                    // 🛑 Les DEUX mesures, et une seule remplie : un cycle TCF
                    // porte des paliers, un cycle civique des scores sur 40.
                    // `null` = inconnu de ce module, jamais zero.
                    cycle.getEntryScore(),
                    cycle.getExitScore(),
                    blocs(axe(module), etapes)));
        }

        // L'affichage va du plus RECENT au plus ancien (maquette). Le tri se
        // fait ici, sur `historise_at` : le rang, lui, reste celui de la
        // creation, et les deux ne se melangent pas.
        cycles.sort(Comparator.comparing(
                JourneyHistoryCycleDto::fin, Comparator.reverseOrder()));

        return new JourneyHistoryDto(
                new JourneyHistoryStatsDto(
                        competencesTravaillees, examensPasses, cycles.size()),
                List.copyOf(cycles));
    }

    /**
     * <b>Un cycle clos, relu tel qu'il etait</b> — la page de consultation de
     * « Mes cycles » ({@code GET /api/me/plan/journey/history/{journeyId}},
     * 2026-09-27) : le rail, les blocs et leurs etapes, comme le Plan, en
     * lecture seule.
     *
     * <p>🛑 <b>404 sur le cycle d'un tiers, sur un cycle en cours et sur le
     * cycle en attente</b> : seul un cycle {@code HISTORISE} se consulte ici —
     * le cycle en cours a son ecran (le Plan), et le cycle en attente est
     * invisible (D-13). Repondre 403 confirmerait l'existence du cycle.
     *
     * <p>🛑 <b>Le rang suit la regle de {@link #lire}</b> ({@link JourneyCycleRank}
     * sur l'ordre de creation) : la liste et la page disent le meme numero.
     */
    @Transactional(readOnly = true)
    public JourneyCycleArchiveDto lireCycle(UUID userId, UUID journeyId) {
        Journey cycle = journeyManager.findDuCandidat(journeyId, userId)
                .filter(journey -> journey.getStatus() == JourneyStatus.HISTORISE)
                .orElseThrow(() -> new NotFoundException("Cycle introuvable : " + journeyId));

        List<Journey> parCreation = journeyManager.racontables(userId, cycle.getModule());
        int rangZeroBase = 0;
        for (int i = 0; i < parCreation.size(); i++) {
            if (parCreation.get(i).getId().equals(cycle.getId())) {
                rangZeroBase = i;
                break;
            }
        }
        int rang = JourneyCycleRank.rang(rangZeroBase);

        List<JourneyStep> etapes = stepManager.findAll(cycle.getId());
        Map<UUID, JourneyExamResultDto> resultats = examResultReader.lire(userId, etapes);
        JourneyBlocResolver.Vue vue = readService.lireArchive(cycle, etapes, rang, resultats);

        return new JourneyCycleArchiveDto(
                cycle.getId(),
                rang,
                cycle.getCreatedAt(),
                cycle.getHistoriseAt(),
                cycle.getFinDeCycle(),
                cycle.objectifRef(),
                cycle.getEntryLevel(),
                cycle.getExitLevel(),
                cycle.getEntryScore(),
                cycle.getExitScore(),
                vue.cycle(),
                vue.blocs());
    }

    /**
     * <b>L'axe de l'historique</b> — les memes blocs que le cycle, dans le meme
     * ordre. 🛑 {@code TcfDomainProfileDto.ORDRE} cote TCF (D-9, D-20), l'ordre
     * d'affichage des thematiques cote civique : une <b>donnee</b>, pas un enum.
     */
    private List<JourneyBlocRefDto> axe(Module module) {
        if (module == Module.CIVIQUE) {
            return themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE).stream()
                    .map(theme -> new JourneyBlocRefDto(
                            JourneyBlocKind.THEMATIQUE, theme.getCode(), theme.getName()))
                    .toList();
        }
        return TcfDomainProfileDto.ORDRE.stream()
                .map(epreuve -> new JourneyBlocRefDto(
                        JourneyBlocKind.EPREUVE, epreuve.name(), epreuve.getLabel()))
                .toList();
    }

    /**
     * Les unites travaillees, <b>groupees par bloc</b>, dans l'ordre de
     * {@link #axe(Module)} — {@code TcfDomainProfileDto.ORDRE} cote TCF (D-9,
     * D-20), l'ordre d'affichage des thematiques cote civique.
     *
     * <p>🛑 <b>Un bloc sans unite cloturee n'apparait pas</b> : un historique
     * raconte ce qui a ete fait, et « Compréhension écrite — rien » n'apprend
     * rien au candidat. Consequence assumee : les examens d'un bloc qui n'a
     * recu aucune unite ne sont comptes que par
     * {@code JourneyHistoryCycleDto.examens}.
     */
    private static List<JourneyHistoryBlocDto> blocs(
            List<JourneyBlocRefDto> axe, List<JourneyStep> etapesCloses) {
        Map<String, List<String>> titres = new LinkedHashMap<>();
        Map<String, Integer> examens = new LinkedHashMap<>();
        Map<String, JourneyBlocRefDto> refs = new LinkedHashMap<>();
        for (JourneyBlocRefDto bloc : axe) {
            titres.put(bloc.code(), new ArrayList<>());
            examens.put(bloc.code(), 0);
            refs.put(bloc.code(), bloc);
        }

        // Les etapes arrivent dans l'ordre de la file : les titres d'un bloc
        // sortent donc dans l'ordre ou le candidat les a travailles.
        java.util.Set<String> examensVus = new java.util.HashSet<>();
        for (JourneyStep etape : etapesCloses) {
            // ✅ AXE : `blocCode()` (DETTE-A1 refermee ici). Une etape DIAGNOSTIC
            // ne porte aucun bloc -- elle mesure le candidat (R11, A45) -- et
            // tombe dans ce `continue` ; une etape CIVIQUE, elle, trouve
            // desormais sa thematique.
            String bloc = etape.blocCode();
            if (bloc == null || !titres.containsKey(bloc)) continue;
            if (etape.getType() == JourneyStepType.SECTION_EXAM) {
                // Meme regle que `compterExamens` : une evaluation, un examen.
                if (examensVus.add(cleExamen(etape))) examens.merge(bloc, 1, Integer::sum);
            } else if (etape.getType() == JourneyStepType.TRAIN_SKILL) {
                // 🛑 L'unite travaillable, quelle qu'elle soit : une competence
                // TCF ou une unite officielle civique. `uniteLabel()` porte
                // cette uniformite a la source.
                String titre = etape.uniteLabel();
                if (titre != null) titres.get(bloc).add(titre);
            }
        }

        List<JourneyHistoryBlocDto> blocs = new ArrayList<>();
        titres.forEach((code, unites) -> {
            if (unites.isEmpty()) return;
            blocs.add(new JourneyHistoryBlocDto(
                    refs.get(code), List.copyOf(unites), examens.get(code)));
        });
        return List.copyOf(blocs);
    }

    private static Map<UUID, List<JourneyStep>> etapesParCycle(List<JourneyStep> etapes) {
        Map<UUID, List<JourneyStep>> parCycle = new LinkedHashMap<>();
        for (JourneyStep etape : etapes) {
            parCycle.computeIfAbsent(
                    etape.getJourney().getId(), cle -> new ArrayList<>()).add(etape);
        }
        return parCycle;
    }

    private static int compter(List<JourneyStep> etapes, JourneyStepType type) {
        return (int) etapes.stream().filter(etape -> etape.getType() == type).count();
    }

    /**
     * <b>Les examens passes</b> — un par evaluation et par bloc, jamais un par
     * ligne.
     *
     * <p>🛑 <b>Deux etapes d'examen du meme bloc closes par la MEME evaluation
     * sont UN examen</b> (constat du 2026-09-27, compte reel : deux etapes
     * « Évaluer mon niveau » CO, closes par le meme examen blanc, comptaient
     * « 2 examens passes »). Le bloc reste dans la cle : un examen civique
     * global qui clot les cinq thematiques d'un coup reste compte une fois par
     * thematique, comme avant.
     */
    private static int compterExamens(List<JourneyStep> etapes) {
        return (int) etapes.stream()
                .filter(etape -> etape.getType() == JourneyStepType.SECTION_EXAM)
                .map(JourneyHistoryService::cleExamen)
                .distinct()
                .count();
    }

    private static String cleExamen(JourneyStep etape) {
        UUID evaluation = etape.getResolvedByAssessmentId();
        return etape.blocCode() + "/" + (evaluation != null ? evaluation : etape.getId());
    }
}
