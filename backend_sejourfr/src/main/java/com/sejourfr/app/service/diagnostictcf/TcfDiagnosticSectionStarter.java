package com.sejourfr.app.service.diagnostictcf;

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

        // 🛑 EXACTEMENT LA COMPOSITION D'UN EXAMEN BLANC D'EPREUVE depuis le
        // 2026-09-13 (arbitrage du proprietaire : « chaque epreuve du
        // diagnostic complet se lance comme un examen blanc complet de
        // l'epreuve ; on peut d'ailleurs y prendre l'examen blanc n°1, meme si
        // on n'affiche pas "examen 1" »). Les memes 25 items (8 A2 / 9 B1 /
        // 8 B2), le meme tirage, la meme duree.
        //
        // ⚠️ REVOQUE `composeDiagnosticComprehension` POUR CE CHEMIN, et avec
        // elle ses deux specificites : la repartition egale 8/8/8 et l'absence
        // de repli hors palier. Le calcul de niveau n'en souffre pas — il lit
        // un TAUX PAR PALIER et ajuste ses denominateurs sur ce qui a
        // reellement ete pose (mode degrade 10_ §9), donc un palier a 9 items
        // se lit aussi bien qu'un palier a 8, et une question ajoutee par le
        // repli compte dans le palier qu'elle porte.
        List<Question> tirees = compositionService.composeModuleExam(Module.TCF, type, false);
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
        // La duree PLEINE de l'epreuve, plus un prorata : la section EST
        // l'epreuve. `dureeReduite` a ete supprimee avec la composition
        // reduite qu'elle accompagnait.
        sub.setTimeLimitSeconds(DureeEpreuve.secondesPourQcm(type));
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
    /**
     * <b>Clot une section COMMENCEE</b> — quitter une epreuve, c'est la
     * terminer.
     *
     * <p>Meme regle qu'un examen blanc (arbitrage du proprietaire,
     * 2026-09-13) : « pour les epreuves, c'est toute l'epreuve qui est
     * chronometree ; l'abandonner, c'est fini, si elle est deja commencee ».
     * Une section jamais ouverte n'est jamais fermee par un geste de sortie :
     * elle attend le candidat aussi longtemps qu'il faut.
     *
     * <p>🛑 <b>L'EXPRESSION ORALE NE PASSE PAS PAR ICI</b>, et c'est la seule
     * exception : son chrono est <b>par tache</b>, donc quitter n'y termine
     * que la tache en cours — le candidat rouvre l'epreuve et reprend a la
     * suivante. Sa cloture reste celle de l'examen : le serveur pose
     * {@code finishedAt} des la 3e soumission.
     *
     * <p><b>Idempotent</b> : rappelee sur une section deja close, elle ne
     * redate rien.
     */
    public Attempt cloreSection(TcfDiagnosticSession session, EpreuveType epreuve) {
        Attempt sub = section(session, epreuve);
        // Jamais commencee : elle attend le candidat aussi longtemps qu'il
        // faut. On ne ferme que ce qui a ete ouvert — c'est exactement la
        // regle de suspension d'un examen blanc.
        if (sub.getTimerStartedAt() == null || sub.getFinishedAt() != null) {
            return sub;
        }
        sub.setFinishedAt(Instant.now());
        sub.setStatus(AttemptStatus.TERMINE);
        return attemptManager.save(sub);
    }

    public Attempt lancerSection(TcfDiagnosticSession session, EpreuveType epreuve) {
        Attempt sub = section(session, epreuve);
        if (sub.getTimerStartedAt() == null && sub.getFinishedAt() == null) {
            Instant now = Instant.now();
            sub.setTimerStartedAt(now);
            sub.setStartedAt(now);
            attemptManager.save(sub);
        }
        return sub;
    }

    private Attempt section(TcfDiagnosticSession session, EpreuveType epreuve) {
        return attemptManager.findSubAttempts(session.getParentAttempt().getId()).stream()
                .filter(a -> a.getEpreuve() == epreuve)
                .findFirst()
                .orElseThrow(() -> new NotFoundException(
                        "Section " + epreuve + " absente de ce diagnostic."));
    }
}
