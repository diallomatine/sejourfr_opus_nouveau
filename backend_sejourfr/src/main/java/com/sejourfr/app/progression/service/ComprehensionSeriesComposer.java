package com.sejourfr.app.progression.service;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.DifficultyBand;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.progression.config.ProgressionConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

/**
 * <b>Le tirage d'une série de compréhension</b> — calibrée quand le catalogue le
 * permet, honnête quand il ne le permet pas (V4.2 §6.2, §7, §12 bis.5).
 *
 * <p>Une série qualifiante vaut <b>6 EASY / 10 MEDIUM / 4 HARD sur 20</b>. Ce
 * n'est pas une préférence esthétique : sans composition fixe, deux séries du
 * même palier ne sont pas comparables, et le moteur additionnerait des scores
 * qui ne mesurent pas la même chose.
 *
 * <p>🛑 <b>Quand la banque ne suffit pas, on ne triche pas.</b> La tentation est
 * de compléter avec des questions non taguées et d'appeler ça calibré — le
 * candidat avance, tout le monde est content, et le moteur lui valide un palier
 * sur une mesure qui n'existe pas. Ici, la série est tirée quand même (le priver
 * de son entraînement serait pire), mais elle est marquée
 * {@code UNCALIBRATED} : elle compte dans la maîtrise, la confiance et la
 * progression visible, avec un poids réduit — et elle ne verrouille aucun
 * palier. Le manque remonte en {@code CONTENT_BANK_TOO_SMALL}.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ComprehensionSeriesComposer {

    private final ProgressionConfig config;
    private final QuestionManager questionManager;
    private final ContentIdentityService contentIdentityService;

    /**
     * Une série tirée, et le fait de savoir si elle est comparable aux autres.
     *
     * @param calibree la composition respecte-t-elle exactement le blueprint ?
     *                 C'est ce booléen, et lui seul, qui décide du
     *                 {@code sourceType} et donc du poids de la preuve.
     */
    public record SerieComposee(List<Question> questions, boolean calibree) {

        public List<UUID> questionIds() {
            return questions.stream().map(Question::getId).toList();
        }
    }

    /**
     * Compose la série d'un palier.
     *
     * <p>Deux passes, dans cet ordre : le blueprint d'abord, et le tirage
     * historique en repli. Jamais l'inverse — un repli qui se ferait passer pour
     * une composition calibrée serait exactement la faille que ce fichier
     * existe pour fermer.
     */
    public SerieComposee composer(UUID userId, SkillSection section, TargetLevel level) {
        QuestionType questionType = section == SkillSection.CO ? QuestionType.CO : QuestionType.CE;
        Difficulty difficulty = Difficulty.valueOf(level.name());

        List<Question> calibree = tirerSelonBlueprint(userId, questionType, difficulty);
        if (calibree != null) {
            Collections.shuffle(calibree);
            return new SerieComposee(calibree, true);
        }

        signalerBanqueInsuffisante(userId, section, level, questionType, difficulty);
        List<Question> repli = questionManager.findLeastRecentlySeen(
                userId, Module.TCF, difficulty, questionType,
                config.receptiveSeriesBlueprint().questionCount());
        return new SerieComposee(repli, false);
    }

    /**
     * Le blueprint, ou rien.
     *
     * <p>{@code null} dès qu'une seule bande ne peut pas être remplie
     * intégralement : une série à 6/10/3 n'est pas « presque calibrée », elle
     * est non calibrée. Il n'y a pas de demi-comparabilité.
     */
    private List<Question> tirerSelonBlueprint(UUID userId, QuestionType questionType,
                                               Difficulty difficulty) {
        ProgressionConfig.ReceptiveSeriesBlueprint blueprint = config.receptiveSeriesBlueprint();
        List<Question> serie = new ArrayList<>(blueprint.questionCount());

        for (BandeDemandee bande : List.of(
                new BandeDemandee(DifficultyBand.EASY, blueprint.easy()),
                new BandeDemandee(DifficultyBand.MEDIUM, blueprint.medium()),
                new BandeDemandee(DifficultyBand.HARD, blueprint.hard()))) {
            List<Question> tirees = questionManager.findLeastRecentlySeenInBand(
                    userId, Module.TCF, difficulty, questionType, bande.band(), bande.combien());
            if (tirees.size() < bande.combien()) {
                return null;
            }
            serie.addAll(tirees);
        }
        return serie;
    }

    /**
     * §12 bis.5 — dire ce qui manque, précisément.
     *
     * <p>Le signal porte la bande la plus courte, pas un « il manque des
     * questions » général : c'est ce qui rend l'information actionnable pour la
     * production de contenu.
     */
    private void signalerBanqueInsuffisante(UUID userId, SkillSection section, TargetLevel level,
                                            QuestionType questionType, Difficulty difficulty) {
        ProgressionConfig.ReceptiveSeriesBlueprint blueprint = config.receptiveSeriesBlueprint();
        StringBuilder detail = new StringBuilder();
        int disponibles = 0;
        for (BandeDemandee bande : List.of(
                new BandeDemandee(DifficultyBand.EASY, blueprint.easy()),
                new BandeDemandee(DifficultyBand.MEDIUM, blueprint.medium()),
                new BandeDemandee(DifficultyBand.HARD, blueprint.hard()))) {
            long stock = questionManager.countInBand(
                    Module.TCF, difficulty, questionType, bande.band());
            disponibles += (int) stock;
            if (!detail.isEmpty()) {
                detail.append(", ");
            }
            detail.append(bande.band()).append(" ").append(stock).append("/").append(bande.combien());
        }
        contentIdentityService.signalerBanqueInsuffisante(
                userId, section, level, disponibles);
        log.info("Série {} {} non calibrée — stock par bande : {}", section, level, detail);
    }

    private record BandeDemandee(DifficultyBand band, int combien) {}
}
