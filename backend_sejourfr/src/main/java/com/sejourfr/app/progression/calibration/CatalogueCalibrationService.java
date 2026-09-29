package com.sejourfr.app.progression.calibration;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.progression.config.ProgressionConfig;
import com.sejourfr.app.progression.dto.CatalogueCalibrationDto;
import com.sejourfr.app.progression.dto.QuestionBandAssignmentRequest;
import com.sejourfr.app.progression.repository.QuestionEmpiricalDifficultyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>L'outillage du tagging du catalogue</b> (V4.2 §7, phase 4).
 *
 * <p>Le tagging lui-même est un travail humain, fait hors application. Ce
 * service ne le remplace pas : il l'<b>outille</b>. Export pour travailler au
 * calme, réimport en masse, et un compteur qui dit où on en est.
 *
 * <p>🛑 <b>Rien ici ne pose une bande tout seul.</b> Ni le taux de réussite
 * observé, ni un quelconque défaut. Une bande décidée par un job ferait bouger
 * la calibration des séries, donc le poids des preuves, donc des paliers déjà
 * acquis — un candidat verrait un acquis disparaître sans avoir rien fait, et
 * personne ne saurait pourquoi.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CatalogueCalibrationService {

    private final ProgressionConfig config;
    private final QuestionManager questionManager;
    private final QuestionEmpiricalDifficultyRepository inventaireRepository;

    /**
     * L'export de travail : une ligne par question, prête pour un tableur.
     *
     * <p>Les questions <b>non taguées d'abord</b> — c'est le travail restant, et
     * une liste qui commence par ce qui est déjà fait se referme sans être lue.
     * La colonne {@code difficulty_band} est celle qu'on remplit ; les autres
     * sont là pour décider, pas pour être modifiées.
     */
    @Transactional(readOnly = true)
    public String exporterCsv(SkillSection section, TargetLevel level) {
        List<Question> questions = questionManager.findForCalibration(
                section == null ? null : section.name(),
                level == null ? null : level.name());

        StringBuilder csv = new StringBuilder("questionId,domain,level,difficulty_band,enonce\n");
        questions.stream()
                .sorted((a, b) -> Boolean.compare(
                        a.getDifficultyBand() != null, b.getDifficultyBand() != null))
                .forEach(question -> csv
                        .append(question.getId()).append(',')
                        .append(domaine(question)).append(',')
                        .append(question.getDifficulty()).append(',')
                        .append(question.getDifficultyBand() == null
                                ? "" : question.getDifficultyBand())
                        .append(',')
                        .append(echapper(question.getStatement()))
                        .append('\n'));
        return csv.toString();
    }

    /**
     * Pose les bandes d'un lot, ou les retire.
     *
     * <p>Chaque affectation est indépendante : un identifiant inconnu est
     * <b>compté et ignoré</b>, il n'annule pas les autres. Un import de 300
     * lignes dont une porte une coquille doit poser les 299 bonnes — sinon on
     * relance l'import entier et on ne sait plus ce qui a été appliqué.
     *
     * @return le nombre de questions réellement modifiées
     */
    @Transactional
    public Resultat affecter(QuestionBandAssignmentRequest requete) {
        int posees = 0;
        int retirees = 0;
        List<UUID> introuvables = new ArrayList<>();

        for (QuestionBandAssignmentRequest.Affectation affectation : requete.affectations()) {
            Question question = questionManager.findById(affectation.questionId()).orElse(null);
            if (question == null) {
                introuvables.add(affectation.questionId());
                continue;
            }
            DifficultyBand avant = question.getDifficultyBand();
            if (avant == affectation.band()) {
                continue;
            }
            question.setDifficultyBand(affectation.band());
            questionManager.save(question);
            if (affectation.band() == null) {
                retirees++;
            } else {
                posees++;
            }
        }
        log.info("Calibration catalogue : {} bandes posées, {} retirées, {} introuvables",
                posees, retirees, introuvables.size());
        return new Resultat(posees, retirees, introuvables);
    }

    /**
     * L'indicateur d'avancement : par (domaine, palier), combien de questions
     * sont taguées et <b>combien de séries 6/10/4 sont constructibles</b>.
     *
     * <p>Le second chiffre est le seul qui compte vraiment. Tant qu'il vaut
     * zéro, aucun candidat ne peut faire avancer ce palier par l'entraînement,
     * et les métriques shadow ne verront que des examens blancs.
     */
    @Transactional(readOnly = true)
    public CatalogueCalibrationDto.Inventaire inventaire() {
        Map<Cle, Compte> comptes = new java.util.LinkedHashMap<>();
        for (Object[] ligne : inventaireRepository.inventaireParBande()) {
            SkillSection section = "CE".equals(String.valueOf(ligne[0]))
                    ? SkillSection.CE : SkillSection.CO;
            TargetLevel level = TargetLevel.valueOf(String.valueOf(ligne[1]));
            DifficultyBand bande = ligne[2] == null
                    ? null : DifficultyBand.valueOf(String.valueOf(ligne[2]));
            long combien = ((Number) ligne[3]).longValue();
            comptes.computeIfAbsent(new Cle(section, level), cle -> new Compte())
                    .ajouter(bande, combien);
        }

        ProgressionConfig.ReceptiveSeriesBlueprint blueprint = config.receptiveSeriesBlueprint();
        List<CatalogueCalibrationDto> couples = new ArrayList<>();
        for (SkillSection section : List.of(SkillSection.CO, SkillSection.CE)) {
            for (TargetLevel level : TargetLevel.values()) {
                Compte compte = comptes.getOrDefault(new Cle(section, level), new Compte());
                couples.add(compte.versDto(section, level, blueprint));
            }
        }

        return new CatalogueCalibrationDto.Inventaire(
                couples,
                couples.stream().mapToLong(CatalogueCalibrationDto::taguees).sum(),
                couples.stream().mapToLong(CatalogueCalibrationDto::nonTaguees).sum(),
                (int) couples.stream()
                        .filter(couple -> couple.seriesConstructibles() > 0).count());
    }

    /** Ce qu'un import a réellement fait — y compris ce qu'il n'a pas trouvé. */
    public record Resultat(int posees, int retirees, List<UUID> introuvables) {}

    private record Cle(SkillSection section, TargetLevel level) {}

    /** Le décompte d'un couple, bande par bande. */
    private static final class Compte {

        private final Map<DifficultyBand, Long> parBande = new EnumMap<>(DifficultyBand.class);
        private long nonTaguees;

        void ajouter(DifficultyBand bande, long combien) {
            if (bande == null) {
                nonTaguees += combien;
            } else {
                parBande.merge(bande, combien, Long::sum);
            }
        }

        CatalogueCalibrationDto versDto(SkillSection section, TargetLevel level,
                                        ProgressionConfig.ReceptiveSeriesBlueprint blueprint) {
            long easy = parBande.getOrDefault(DifficultyBand.EASY, 0L);
            long medium = parBande.getOrDefault(DifficultyBand.MEDIUM, 0L);
            long hard = parBande.getOrDefault(DifficultyBand.HARD, 0L);

            // 🛑 Un MINIMUM, pas une moyenne : la bande la plus pauvre décide
            // seule. 200 questions MEDIUM ne servent à rien s'il n'y a que 3 HARD.
            int series = (int) Math.min(easy / blueprint.easy(),
                    Math.min(medium / blueprint.medium(), hard / blueprint.hard()));

            return new CatalogueCalibrationDto(section, level,
                    easy + medium + hard, nonTaguees, easy, medium, hard, series,
                    bandeLimitante(easy, medium, hard, blueprint));
        }

        /** Ce qu'il faut produire en priorité — pas « il manque des questions ». */
        private static String bandeLimitante(long easy, long medium, long hard,
                                             ProgressionConfig.ReceptiveSeriesBlueprint blueprint) {
            long possiblesEasy = easy / blueprint.easy();
            long possiblesMedium = medium / blueprint.medium();
            long possiblesHard = hard / blueprint.hard();
            long minimum = Math.min(possiblesEasy, Math.min(possiblesMedium, possiblesHard));
            if (possiblesEasy == minimum) return DifficultyBand.EASY.name();
            if (possiblesMedium == minimum) return DifficultyBand.MEDIUM.name();
            return DifficultyBand.HARD.name();
        }
    }

    private static String domaine(Question question) {
        return question.getQuestionType() == com.sejourfr.app.enums.QuestionType.CE ? "CE" : "CO";
    }

    /** Un énoncé peut contenir virgules, guillemets et retours ligne. */
    private static String echapper(String valeur) {
        if (valeur == null) {
            return "";
        }
        String propre = valeur.replace("\"", "\"\"").replace('\n', ' ').replace('\r', ' ');
        return "\"" + propre + "\"";
    }
}
