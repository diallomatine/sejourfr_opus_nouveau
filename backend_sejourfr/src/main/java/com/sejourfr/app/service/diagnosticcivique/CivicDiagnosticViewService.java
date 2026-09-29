package com.sejourfr.app.service.diagnosticcivique;

import com.sejourfr.app.dto.CivicDiagnosticDto;
import com.sejourfr.app.dto.CivicDiagnosticResultDto;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AttemptQuestionManager;
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
 * Les vues du diagnostic civique servies aux fronts (20_ §4.5).
 *
 * <p>Separe de {@link CivicDiagnosticService}, qui orchestre le parcours : ici
 * on ne fait que <b>recalculer</b> a la lecture. Rien de ce qui suit n'est
 * persiste — ni les etats de theme, ni la projection, ni les priorites. Un
 * recalibrage des seuils se refletera donc au prochain affichage, sans
 * migration ni job.
 */
@Service
@RequiredArgsConstructor
public class CivicDiagnosticViewService {

    private final AttemptQuestionManager attemptQuestionManager;
    private final ThemeManager themeManager;
    private final CivicDiagnosticThemeResolver themeResolver;

    /**
     * L'ecran d'accueil et de reprise.
     *
     * <p>🛑 <b>Aucun score n'y transite.</b> Le resultat est le moment de
     * conversion : le diluer pendant la passation le detruit.
     */
    @Transactional(readOnly = true)
    public CivicDiagnosticDto vue(CivicDiagnosticSession session) {
        int total = session.getAttempt().getTotalQuestions() == null
                ? 0 : session.getAttempt().getTotalQuestions();
        long repondues = attemptQuestionManager.findByAttemptOrderedByPosition(session.getAttempt().getId())
                .stream()
                .filter(aq -> aq.getAnswer() != null)
                .count();
        return new CivicDiagnosticDto(
                session.getId(),
                session.getAttempt().getId(),
                session.getStatus(),
                session.getMention(),
                total,
                (int) repondues,
                session.getStartedAt(),
                session.getCompletedAt());
    }

    /** L'ecran de resultat (20_ §4.5). */
    @Transactional(readOnly = true)
    public CivicDiagnosticResultDto resultat(CivicDiagnosticSession session) {
        // [themeId, QuestionType, poses, reussis]
        List<Object[]> lignes =
                attemptQuestionManager.aggregateByThemeAndType(session.getAttempt().getId());

        Map<UUID, int[]> connaissancesParTheme = new LinkedHashMap<>();
        int situationsPosees = 0;
        int situationsReussies = 0;
        int bonnes = 0;
        int posees = 0;

        for (Object[] ligne : lignes) {
            UUID themeId = (UUID) ligne[0];
            QuestionType type = (QuestionType) ligne[1];
            int p = ((Number) ligne[2]).intValue();
            int r = ligne[3] == null ? 0 : ((Number) ligne[3]).intValue();
            posees += p;
            bonnes += r;
            if (type == QuestionType.MISE_SITUATION) {
                situationsPosees += p;
                situationsReussies += r;
                // 🛑 Les mises en situation n'entrent PAS dans l'etat d'un
                // theme : 20_ §4.5 en fait un bloc distinct, parce que c'est
                // une competence differente. Les melanger ferait chuter un
                // theme sur une difficulte qui n'est pas la sienne.
                continue;
            }
            int[] compte = connaissancesParTheme.computeIfAbsent(themeId, k -> new int[2]);
            compte[0] += p;
            compte[1] += r;
        }

        // 🛑 TOUS les themes, y compris ceux qu'aucune question n'a touches : un
        // theme absent de la liste disparaitrait de l'ecran au lieu de se dire
        // « non evalue ».
        List<CivicDiagnosticResultDto.ThemeResultat> themes = new ArrayList<>();
        for (Theme theme : themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE)) {
            int[] compte = connaissancesParTheme.getOrDefault(theme.getId(), new int[2]);
            themes.add(new CivicDiagnosticResultDto.ThemeResultat(
                    theme.getId(),
                    theme.getCode(),
                    theme.getName(),
                    themeResolver.etat(compte[1], compte[0]),
                    compte[1],
                    compte[0],
                    CivicDiagnosticThemeResolver.taux(compte[1], compte[0])));
        }

        return new CivicDiagnosticResultDto(
                session.getId(),
                session.getMention(),
                bonnes,
                posees,
                CivicExamFormat.projection(bonnes, posees),
                CivicExamFormat.SEUIL_REUSSITE,
                CivicExamFormat.QUESTIONS,
                themes,
                new CivicDiagnosticResultDto.Situations(situationsReussies, situationsPosees),
                priorites(themes),
                session.getCompletedAt());
    }

    /**
     * « Ce qui vous coute le plus de points » (20_ §4.5 bloc 4).
     *
     * <p>🛑 <b>Au niveau THEME, et c'est le mode degrade ASSUME</b> de
     * 20_ §3.4 : « Plan et diagnostic au niveau theme » tant que le tagging des
     * notions n'est pas fait. La spec le prevoit noir sur blanc — « (au niveau
     * theme si le tagging n'est pas suffisant) ». Le jour ou les notions sont
     * taguees, ce classement descendra d'un cran sans changer de contrat.
     *
     * <p>🛑 <b>Un theme NON EVALUE n'est jamais une priorite.</b> On ne fait pas
     * travailler quelqu'un sur ce qu'on n'a pas mesure.
     *
     * <p>Le tri porte sur le nombre de <b>points manques</b>, pas sur le taux :
     * un theme rate a 50 % sur 8 questions coute plus cher qu'un theme rate a
     * 40 % sur 3. C'est bien « ce qui coute le plus de points », comme le titre
     * le dit. A egalite, le taux le plus bas passe devant, puis l'ordre
     * d'affichage du theme pour rester deterministe.
     */
    private static List<CivicDiagnosticResultDto.PrioriteTheme> priorites(
            List<CivicDiagnosticResultDto.ThemeResultat> themes) {
        List<CivicDiagnosticResultDto.ThemeResultat> candidats = themes.stream()
                .filter(t -> t.etat() == CivicThemeState.FAIBLE
                        || t.etat() == CivicThemeState.A_RENFORCER)
                .sorted(Comparator
                        .comparingInt((CivicDiagnosticResultDto.ThemeResultat t) ->
                                -(t.posees() - t.bonnes()))
                        .thenComparing(t -> t.taux() == null ? 1.0 : t.taux()))
                .toList();

        List<CivicDiagnosticResultDto.PrioriteTheme> out = new ArrayList<>(candidats.size());
        for (int i = 0; i < candidats.size(); i++) {
            CivicDiagnosticResultDto.ThemeResultat t = candidats.get(i);
            out.add(new CivicDiagnosticResultDto.PrioriteTheme(
                    i + 1, t.themeId(), t.code(), t.label(), t.etat(),
                    t.posees() - t.bonnes()));
        }
        return out;
    }
}
