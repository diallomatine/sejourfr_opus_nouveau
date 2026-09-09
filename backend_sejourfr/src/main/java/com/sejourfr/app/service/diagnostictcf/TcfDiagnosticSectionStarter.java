package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.service.attempt.AttemptCompositionService;
import com.sejourfr.app.enums.DureeEpreuve;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

/**
 * La creation des 4 sections d'un diagnostic TCF, et le lancement de leur
 * chrono.
 *
 * <p>Sorti de {@link TcfDiagnosticService} parce que c'est un cas d'usage
 * distinct : composer et ancrer des epreuves, la ou le service orchestre le
 * parcours.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TcfDiagnosticSectionStarter {

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final AttemptCompositionService compositionService;
    private final TcfDiagnosticProperties props;

    /**
     * Cree CO, CE, EE et EO sous le parent.
     *
     * <p>🛑 <b>Une epreuve sans contenu n'est PAS creee</b> — c'est le mode
     * degrade de 10_ §9 : « aucun audio CO ⇒ section absente du diagnostic,
     * epreuve non evaluee, exclue du minimum, aucune priorite CO ». Elle ne
     * produit ni erreur ni message : le candidat ne doit jamais voir qu'il
     * manque du contenu.
     */
    public void creerLesQuatreSections(User user, TcfDiagnosticSession session, Attempt parent) {
        creerComprehension(user, session, parent, QuestionType.CO);
        creerComprehension(user, session, parent, QuestionType.CE);
        creerProduction(user, session, parent, EpreuveType.TCF_EE);
        creerProduction(user, session, parent, EpreuveType.TCF_EO);
    }

    private void creerComprehension(
            User user, TcfDiagnosticSession session, Attempt parent, QuestionType type) {

        List<Question> tirees = compositionService.composeDiagnosticComprehension(
                type, props.getItemsPerLevel(), false);
        if (tirees.isEmpty()) {
            log.warn("Diagnostic {} : aucune question {} disponible, section omise (mode dégradé).",
                    session.getId(), type);
            return;
        }

        Attempt sub = new Attempt();
        sub.setUser(user);
        sub.setType(AttemptType.MOCK_EXAM);
        sub.setModule(Module.TCF);
        sub.setEpreuve(type == QuestionType.CO ? EpreuveType.TCF_CO : EpreuveType.TCF_CE);
        sub.setParentAttempt(parent);
        sub.setTcfDiagnostic(session);
        sub.setModuleExamQuestionType(type);
        sub.setTotalQuestions(tirees.size());
        // La duree est celle de l'epreuve reelle ramenee au format reduit : le
        // diagnostic pose 15 items la ou l'epreuve en compte 25, il serait
        // malhonnete d'en garder le chrono entier.
        sub.setTimeLimitSeconds(dureeReduite(type, tirees.size()));
        sub.setStartedAt(Instant.now());
        sub = attemptManager.save(sub);

        for (int i = 0; i < tirees.size(); i++) {
            AttemptQuestion aq = new AttemptQuestion();
            aq.setAttempt(sub);
            aq.setQuestion(tirees.get(i));
            aq.setPosition(i);
            attemptQuestionManager.save(aq);
        }
    }

    /**
     * Duree d'une section reduite : la duree officielle de l'epreuve, au prorata
     * des items reellement poses.
     *
     * <p>🛑 La duree officielle vient de {@code DureeEpreuve} et le denominateur
     * de {@code AttemptCompositionService.MODULE_EXAM_TOTAL}. Aucun nombre
     * n'est ecrit ici : raccourcir une epreuve raccourcit automatiquement la
     * section, et le depot n'a pas d'autre « 25 » qui pourrait diverger.
     */
    static int dureeReduite(QuestionType type, int items) {
        int complete = DureeEpreuve.secondesPourQcm(type);
        int prorata = Math.round(
                complete * (float) items / AttemptCompositionService.MODULE_EXAM_TOTAL);
        // Une section ne descend jamais sous une minute, quelle que soit la
        // pauvrete du catalogue.
        return Math.max(60, prorata);
    }

    /**
     * EE et EO : des attempts <b>vides</b>. Les 3 taches seront soumises via
     * {@code /api/production-submissions} avec l'attemptId de la section —
     * exactement comme dans l'examen complet, sans une ligne de pipeline en
     * plus.
     *
     * <p>🛑 <b>Les 3 taches sont evaluees, jamais reduites</b> (arbitrage A2) :
     * « on ne reduit que la comprehension, jamais la production ». Le Plan
     * raisonne par tache — nommer « EO tache 2 » sans l'avoir evaluee rendrait
     * la personnalisation fictive.
     */
    private void creerProduction(
            User user, TcfDiagnosticSession session, Attempt parent, EpreuveType epreuve) {

        Attempt sub = new Attempt();
        sub.setUser(user);
        sub.setType(AttemptType.MOCK_EXAM);
        sub.setModule(Module.TCF);
        sub.setEpreuve(epreuve);
        sub.setParentAttempt(parent);
        sub.setTcfDiagnostic(session);
        sub.setStatus(AttemptStatus.EN_COURS);
        sub.setStartedAt(Instant.now());
        // Chrono d'epreuve pour l'ecrit (les 3 taches ensemble) ; l'oral se
        // chronometre par tache, pas par epreuve — meme regle que l'examen
        // complet, cf. DureeEpreuve.
        sub.setTimeLimitSeconds(DureeEpreuve.secondes(epreuve));
        attemptManager.save(sub);
    }

    /**
     * Lance le chrono d'une section. <b>Idempotent</b> : rappele, il rend le
     * temps reellement restant au lieu de repartir de zero.
     *
     * <p>C'est l'ancre du decompte, exactement comme
     * {@code FullTcfExamService.beginEpreuve} : quitter ne suspend rien, le
     * temps a couru pendant l'absence.
     */
    public Attempt lancerSection(TcfDiagnosticSession session, EpreuveType epreuve) {
        Attempt sub = attemptManager.findSubAttempts(session.getParentAttempt().getId()).stream()
                .filter(a -> a.getEpreuve() == epreuve)
                .findFirst()
                .orElseThrow(() -> new NotFoundException(
                        "Section " + epreuve + " absente de ce diagnostic."));

        if (sub.getTimerStartedAt() == null && sub.getFinishedAt() == null) {
            Instant now = Instant.now();
            sub.setTimerStartedAt(now);
            sub.setStartedAt(now);
            attemptManager.save(sub);
        }
        return sub;
    }
}
