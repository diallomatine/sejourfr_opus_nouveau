package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyHistoryBlocDto;
import com.sejourfr.app.dto.JourneyHistoryCycleDto;
import com.sejourfr.app.dto.JourneyHistoryDto;
import com.sejourfr.app.dto.JourneyHistoryStatsDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.JourneyStepManager;
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
    private final JourneyStepManager stepManager;

    /**
     * L'historique du candidat sur le module TCF.
     *
     * <p>🛑 <b>Aucun parametre au-dela de l'identite</b> (B-10) : le serveur
     * sait qui lit. Le civique sort du chantier (D-23), son plan reste
     * integralement derive et ne porte aucun cycle.
     *
     * <p>Un candidat sans aucun cycle ferme recoit {@code cycles} <b>vide</b> et
     * des statistiques a <b>zero</b>, jamais {@code null} : l'ecran sait dire
     * « rien encore ».
     */
    @Transactional(readOnly = true)
    public JourneyHistoryDto lire(UUID userId) {
        // Requete 1 : les cycles, du plus ancien au plus recent — c'est l'ordre
        // qui DEFINIT le rang (JourneyCycleRank), pas celui de l'affichage.
        List<Journey> parCreation = journeyManager.racontables(userId, Module.TCF);

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
            int examens = compter(etapes, JourneyStepType.SECTION_EXAM);

            // 🛑 Les compteurs d'en-tete portent sur TOUS les cycles, le cycle en
            // cours COMPRIS : l'ecran dit « tout ce que vous avez deja
            // travaille », pas « dans vos cycles clos ». Les exclure ferait
            // reculer un compteur au demarrage du cycle suivant.
            competencesTravaillees += competences;
            examensPasses += examens;

            if (cycle.getStatus() != JourneyStatus.HISTORISE) continue;

            cycles.add(new JourneyHistoryCycleDto(
                    // Le rang est la place du cycle dans l'ordre de creation :
                    // une seule regle pour les deux ecrans.
                    JourneyCycleRank.rang(rangZeroBase),
                    cycle.getCreatedAt(),
                    cycle.getHistoriseAt(),
                    competences,
                    examens,
                    cycle.getEntryLevel(),
                    cycle.getExitLevel(),
                    blocs(etapes)));
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
     * Les competences travaillees, <b>groupees par epreuve</b>, dans l'ordre
     * {@code TcfDomainProfileDto.ORDRE} (CO, CE, EO, EE) — autorite unique et
     * non configurable (D-9, D-20).
     *
     * <p>🛑 <b>Un bloc sans competence cloturee n'apparait pas</b> : un
     * historique raconte ce qui a ete fait, et « Compréhension écrite — rien »
     * n'apprend rien au candidat. Consequence assumee : les examens d'une
     * epreuve qui n'a recu aucune competence ne sont comptes que par
     * {@code JourneyHistoryCycleDto.examens}.
     */
    private static List<JourneyHistoryBlocDto> blocs(List<JourneyStep> etapesCloses) {
        Map<EpreuveType, List<String>> titres = new LinkedHashMap<>();
        Map<EpreuveType, Integer> examens = new LinkedHashMap<>();
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            titres.put(epreuve, new ArrayList<>());
            examens.put(epreuve, 0);
        }

        // Les etapes arrivent dans l'ordre de la file : les titres d'un bloc
        // sortent donc dans l'ordre ou le candidat les a travailles.
        for (JourneyStep etape : etapesCloses) {
            EpreuveType epreuve = etape.getExamType();
            // Une etape DIAGNOSTIC ne porte pas d'epreuve : elle mesure le
            // candidat, pas une epreuve. Elle n'appartient a aucun bloc.
            //
            // ⚠️ AXE : CHEMIN TCF (DETTE-A1). Une etape CIVIQUE tombe ici aussi
            // dans ce `continue` — son bloc est une thematique, pas une epreuve.
            // Ce n'est pas un NPE, c'est un TROU MUET : l'historique civique
            // serait vide. Il se comble en P8.9, en lisant `blocCode()`.
            // ⛔ P8.9 est BLOQUEE (template non fourni) : ne rien concevoir ici.
            if (epreuve == null || !titres.containsKey(epreuve)) continue;
            if (etape.getType() == JourneyStepType.SECTION_EXAM) {
                examens.merge(epreuve, 1, Integer::sum);
            } else if (etape.getType() == JourneyStepType.TRAIN_SKILL) {
                Skill competence = etape.getSkill();
                if (competence != null) titres.get(epreuve).add(competence.getTitle());
            }
        }

        List<JourneyHistoryBlocDto> blocs = new ArrayList<>();
        titres.forEach((epreuve, codes) -> {
            if (codes.isEmpty()) return;
            blocs.add(new JourneyHistoryBlocDto(
                    epreuve, List.copyOf(codes), examens.get(epreuve)));
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
}
