package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressionCiviqueDto;
import com.sejourfr.app.dto.ProgressionEpreuveDto;
import com.sejourfr.app.dto.ProgressionMesureDto;
import com.sejourfr.app.dto.ProgressionTcfDto;
import com.sejourfr.app.dto.ProgressionThemeDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.ProgressionEtatSource;
import com.sejourfr.app.enums.ProgressionProvenance;
import com.sejourfr.app.enums.ProgressionRapport;
import com.sejourfr.app.enums.ProgressionUnite;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SubmissionStatut;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticLevelResolver;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Les quatre écrans de progression ({@code /api/me/progression/*}) contre la
 * vraie base : ce qui compte (examens blancs, jamais un diagnostic ni un
 * template mixte), comment c'est numéroté, ce qui est re-dérivé (D19), ce qui
 * reste inconnu, et ce qu'un compte gratuit voit (tout, D20).
 */
class ProgressionExamensServiceIT extends AbstractIntegrationTest {

    @Autowired private ProgressionExamensService service;
    @Autowired private TestData data;
    @Autowired private AttemptManager attemptManager;
    @Autowired private ProductionSubmissionManager submissionManager;
    @Autowired private AiEvaluationManager aiEvaluationManager;
    @Autowired private TcfDiagnosticSessionManager tcfSessionManager;
    @Autowired private CivicDiagnosticSessionManager civicSessionManager;
    @Autowired private ThemeManager themeManager;
    @Autowired private EntityManager entityManager;

    private final Instant maintenant = Instant.now().truncatedTo(ChronoUnit.SECONDS);

    // ══════════════════════════════════════════════════════════════════════
    //  Fixtures
    // ══════════════════════════════════════════════════════════════════════

    /** Examen de CO/CE passé SEUL, fini à {@code fin}, en {@code minutes} minutes. */
    private Attempt qcmSeul(User user, EpreuveType e, NiveauCecrl niveau, Instant fin, int minutes) {
        Attempt a = data.examenQcmTcfPasse(user, e, niveau);
        a.setStartedAt(fin.minus(minutes, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        a.setTimeLimitSeconds(e == EpreuveType.TCF_CE ? 2100 : 1200);
        a.setSlotNumber(1);
        return attemptManager.save(a);
    }

    private Attempt parentComplet(User user, Instant fin) {
        Attempt p = new Attempt();
        p.setUser(user);
        p.setType(AttemptType.MOCK_EXAM);
        p.setModule(Module.TCF);
        p.setEpreuve(EpreuveType.TCF_COMPLET);
        p.setMode(AttemptMode.EXAMEN);
        p.setStatus(fin == null ? AttemptStatus.EN_COURS : AttemptStatus.TERMINE);
        p.setStartedAt((fin == null ? maintenant : fin).minus(2, ChronoUnit.HOURS));
        p.setFinishedAt(fin);
        p.setSlotNumber(1);
        return attemptManager.save(p);
    }

    /** Sous-épreuve lancée ({@code timerStartedAt} posé) et finie. */
    private Attempt sousEpreuve(Attempt parent, User user, EpreuveType e, Instant fin) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE
                ? AttemptType.MOCK_EXAM : AttemptType.TRAINING);
        a.setModule(Module.TCF);
        a.setEpreuve(e);
        a.setMode(AttemptMode.EXAMEN);
        a.setStatus(AttemptStatus.TERMINE);
        a.setParentAttempt(parent);
        a.setStartedAt(fin.minus(40, ChronoUnit.MINUTES));
        a.setTimerStartedAt(fin.minus(15, ChronoUnit.MINUTES));
        a.setTimeLimitSeconds(e == EpreuveType.TCF_EO ? null : 1200);
        a.setFinishedAt(fin);
        return attemptManager.save(a);
    }

    /** Sous-épreuve close SANS avoir été ouverte : pas d'ancre, rien de rendu. */
    private Attempt jamaisOuverte(Attempt parent, User user, EpreuveType e, Instant fin) {
        Attempt a = sousEpreuve(parent, user, e, fin);
        a.setTimerStartedAt(null);
        return attemptManager.save(a);
    }

    private Attempt qcmDansComplet(Attempt parent, User user, EpreuveType e, NiveauCecrl n, Instant fin) {
        Attempt a = sousEpreuve(parent, user, e, fin);
        return data.reponsesQcmDemontrant(a, e == EpreuveType.TCF_CE ? QuestionType.CE : QuestionType.CO, n);
    }

    private void troisTachesNotees(Attempt a, User user, EpreuveType e, String note) {
        for (short numero = 1; numero <= 3; numero++) {
            ProductionSubmission s = data.productionSubmission(a, data.productionTacheNumero(e, numero), user);
            s.setStatut(SubmissionStatut.EVALUATED);
            submissionManager.save(s);
            AiEvaluation ev = data.aiEvaluation(s);
            ev.setNoteSur20(new BigDecimal(note));
            ev.setNiveauCecrl(null);
            ev.setNiveauCecrlIa(null);
            ev.setFeedbackJson(new java.util.HashMap<>());
            aiEvaluationManager.save(ev);
        }
    }

    private Attempt productionDansComplet(Attempt parent, User user, EpreuveType e, String note, Instant fin) {
        Attempt a = sousEpreuve(parent, user, e, fin);
        troisTachesNotees(a, user, e, note);
        return a;
    }

    /** Examen de production passé SEUL (le slot fait l'examen). */
    private Attempt productionSeule(User user, EpreuveType e, String note, Instant fin, int minutes) {
        Attempt a = new Attempt();
        a.setUser(user);
        a.setType(AttemptType.TRAINING);
        a.setModule(Module.TCF);
        a.setEpreuve(e);
        a.setMode(AttemptMode.EXAMEN);
        a.setStatus(AttemptStatus.TERMINE);
        a.setSlotNumber(1);
        a.setStartedAt(fin.minus(minutes, ChronoUnit.MINUTES));
        a.setTimeLimitSeconds(e == EpreuveType.TCF_EE ? 1800 : null);
        a.setFinishedAt(fin);
        attemptManager.save(a);
        troisTachesNotees(a, user, e, note);
        return a;
    }

    private void flush() {
        entityManager.flush();
        entityManager.clear();
    }

    private List<Theme> themesCiviques() {
        return themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
    }

    /**
     * Examen civique terminé : {@code questions} posées par thème (dans
     * l'ordre), {@code bonnes} premières réussies. Le {@code score} persisté est
     * le total des bonnes réponses, comme le pose le moteur.
     */
    private Attempt examenCivique(User user, UUID lotThemeId, int total, int seuil, Instant fin,
                                  List<Theme> themes, int[] posees, int[] bonnes, QuestionType type) {
        Attempt a = data.attempt(user);
        a.setType(AttemptType.MOCK_EXAM);
        a.setMode(AttemptMode.EXAMEN);
        a.setModule(Module.CIVIQUE);
        a.setEpreuve(EpreuveType.CIVIQUE);
        a.setStatus(AttemptStatus.TERMINE);
        a.setLotThemeId(lotThemeId);
        a.setTotalQuestions(total);
        a.setPassThreshold(seuil);
        a.setTimeLimitSeconds(total == 20 ? 1200 : 2700);
        a.setStartedAt(fin.minus(10, ChronoUnit.MINUTES));
        a.setFinishedAt(fin);
        int score = 0;
        for (int t = 0; t < themes.size() && t < posees.length; t++) {
            for (int i = 0; i < posees[t]; i++) {
                Question q = data.question(themes.get(t));
                if (type != null && i == 0) {
                    q.setQuestionType(type);
                }
                boolean juste = i < bonnes[t];
                data.answer(data.attemptQuestion(a, q), juste);
                if (juste) score++;
            }
        }
        a.setScore(score);
        return attemptManager.save(a);
    }

    private Attempt examenDeTheme(User user, Theme theme, int bonnes, Instant fin) {
        return examenCivique(user, theme.getId(), 20, 16, fin,
                List.of(theme), new int[]{20}, new int[]{bonnes}, null);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Une épreuve TCF
    // ══════════════════════════════════════════════════════════════════════

    @Nested
    class Epreuve {

        @Test
        @DisplayName("Aucun examen : liste vide, tout inconnu, jamais 0 ni A1")
        void aucunExamen() {
            User user = data.user();

            ProgressionEpreuveDto dto = service.epreuve(user.getId(), EpreuveType.TCF_CO);

            assertThat(dto.examens()).isEmpty();
            assertThat(dto.resume().nombre()).isZero();
            assertThat(dto.resume().dernier()).isNull();
            assertThat(dto.resume().sens()).isEqualTo(NiveauEvolution.INCONNUE);
            assertThat(dto.niveauActuel()).isNull();
            assertThat(dto.echelle().unite()).isEqualTo(ProgressionUnite.PROGRESSION_499);
            assertThat(dto.echelle().bandes()).isEmpty();
            assertThat(dto.cta().locked()).isFalse();
        }

        /**
         * 🛑 D1 + D18 : l'épreuve seule ET la sous-épreuve d'un examen complet
         * comptent ; la section de diagnostic et l'examen piloté par un
         * template mixte n'y entrent pas. Ordinal chronologique, rapport servi.
         */
        @Test
        @DisplayName("CO : les deux provenances d'examen blanc, sans diagnostic ni template mixte")
        void deuxProvenancesSansDiagnostic() {
            User user = data.user();
            Attempt seule = qcmSeul(user, EpreuveType.TCF_CO, NiveauCecrl.A2,
                    maintenant.minus(3, ChronoUnit.DAYS), 18);
            Attempt parent = parentComplet(user, maintenant.minus(1, ChronoUnit.DAYS));
            Attempt dansComplet = qcmDansComplet(parent, user, EpreuveType.TCF_CO, NiveauCecrl.B1,
                    maintenant.minus(1, ChronoUnit.DAYS));

            // Section de diagnostic complet : qualifiante pour l'Accueil, pas ici.
            TcfDiagnosticSession session = new TcfDiagnosticSession();
            session.setUser(user);
            Attempt parentDiag = parentComplet(user, maintenant);
            session.setParentAttempt(parentDiag);
            session.setConfigVersion(1);
            session.setStatus(TcfDiagnosticStatus.COMPLETED);
            session.setStartedAt(maintenant.minus(1, ChronoUnit.HOURS));
            session.setExpiresAt(maintenant.plus(7, ChronoUnit.DAYS));
            session.setCompletedAt(maintenant);
            tcfSessionManager.save(session);
            Attempt section = qcmDansComplet(parentDiag, user, EpreuveType.TCF_CO, NiveauCecrl.B2, maintenant);
            section.setTcfDiagnostic(session);
            attemptManager.save(section);

            // Template mixte (50 Q CO + CE), epreuve TCF_CO par défaut.
            Attempt mixte = qcmSeul(user, EpreuveType.TCF_CO, NiveauCecrl.B2, maintenant, 10);
            mixte.setExamTemplate(data.examTemplate());
            mixte.setModuleExamQuestionType(null);
            attemptManager.save(mixte);
            flush();

            ProgressionEpreuveDto dto = service.epreuve(user.getId(), EpreuveType.TCF_CO);

            assertThat(dto.examens()).extracting(ProgressionMesureDto::attemptId)
                    .containsExactly(dansComplet.getId(), seule.getId());
            assertThat(dto.examens()).extracting(ProgressionMesureDto::numero).containsExactly(2, 1);

            ProgressionMesureDto recent = dto.examens().getFirst();
            assertThat(recent.provenance()).isEqualTo(ProgressionProvenance.EXAMEN_COMPLET);
            assertThat(recent.rapport().kind()).isEqualTo(ProgressionRapport.EXAMEN_COMPLET);
            assertThat(recent.rapport().attemptId()).isEqualTo(parent.getId());
            assertThat(recent.niveau()).isEqualTo(NiveauCecrl.B1);
            assertThat(recent.max()).isEqualTo(499);
            // Sous-épreuve lancée 15 min avant sa fin, limite 20 min : fiable.
            assertThat(recent.dureeSecondes()).isEqualTo(15 * 60);

            ProgressionMesureDto ancien = dto.examens().getLast();
            assertThat(ancien.provenance()).isEqualTo(ProgressionProvenance.EPREUVE_SEULE);
            assertThat(ancien.rapport().kind()).isEqualTo(ProgressionRapport.QCM);
            assertThat(ancien.rapport().attemptId()).isEqualTo(seule.getId());
            assertThat(ancien.niveau()).isEqualTo(NiveauCecrl.A2);
            assertThat(ancien.dureeSecondes()).isEqualTo(18 * 60);
            // 🛑 A2 démontré = 100/499 (10 points pondérés sur 47, sous le hasard) :
            // le score et le palier ne disent pas la même chose, c'est voulu.
            assertThat(ancien.score()).isEqualByComparingTo("100");

            assertThat(dto.resume().nombre()).isEqualTo(2);
            assertThat(dto.resume().ecart()).isPositive();
            assertThat(dto.resume().sens()).isEqualTo(NiveauEvolution.HAUSSE);
            assertThat(dto.resume().meilleur()).isSameAs(dto.resume().dernier());
        }

        /** D3 + D9 : EE sur 20 avec les bandes officielles ; EO sans aucune durée. */
        @Test
        @DisplayName("EE/EO : note /20 et bandes officielles ; jamais de durée en EO")
        void productionSur20() {
            User user = data.user();
            productionSeule(user, EpreuveType.TCF_EE, "12", maintenant.minus(1, ChronoUnit.DAYS), 25);
            productionSeule(user, EpreuveType.TCF_EO, "8", maintenant, 12);
            flush();

            ProgressionEpreuveDto ee = service.epreuve(user.getId(), EpreuveType.TCF_EE);
            assertThat(ee.echelle().unite()).isEqualTo(ProgressionUnite.NOTE_20);
            assertThat(ee.echelle().bandes()).hasSize(5);
            assertThat(ee.examens()).singleElement().satisfies(m -> {
                assertThat(m.score()).isEqualByComparingTo("12.0");
                assertThat(m.max()).isEqualTo(20);
                assertThat(m.niveau()).isNotNull();
                assertThat(m.dureeSecondes()).isEqualTo(25 * 60);
                assertThat(m.rapport().kind()).isEqualTo(ProgressionRapport.PRODUCTION);
            });
            // D4 : le niveau actuel estimé (Accueil) est servi à côté.
            assertThat(ee.niveauActuel()).isEqualTo(ee.examens().getFirst().niveau());

            ProgressionEpreuveDto eo = service.epreuve(user.getId(), EpreuveType.TCF_EO);
            assertThat(eo.examens()).singleElement()
                    .satisfies(m -> assertThat(m.dureeSecondes()).isNull());
        }

        @Test
        @DisplayName("TCF_STRUCTURE n'est pas une épreuve du TCF IRN : 400")
        void structureRefusee() {
            User user = data.user();

            assertThatThrownBy(() -> service.epreuve(user.getId(), EpreuveType.TCF_STRUCTURE))
                    .isInstanceOf(BusinessException.class);
        }

        /**
         * 🛑 D20 : un compte gratuit voit TOUS ses résultats ; seul le bouton
         * porte un cadenas, et seulement quand la grille ne lui offre plus rien
         * (gratuité EE consommée). CO : jamais (créneau 1 rejouable).
         */
        @Test
        @DisplayName("Compte gratuit : tout est visible, seul le CTA EE se verrouille")
        void compteGratuitVoitTout() {
            User user = data.user();
            Attempt ee = productionSeule(user, EpreuveType.TCF_EE, "12", maintenant, 20);
            data.freeEntitlementUsage(user, FreeEntitlementCode.EXAM_BLANC_EE, ee);
            qcmSeul(user, EpreuveType.TCF_CO, NiveauCecrl.A2, maintenant, 10);
            flush();

            ProgressionEpreuveDto dtoEe = service.epreuve(user.getId(), EpreuveType.TCF_EE);
            assertThat(dtoEe.examens()).hasSize(1);
            assertThat(dtoEe.cta().locked()).isTrue();

            ProgressionEpreuveDto dtoCo = service.epreuve(user.getId(), EpreuveType.TCF_CO);
            assertThat(dtoCo.examens()).hasSize(1);
            assertThat(dtoCo.cta().locked()).isFalse();

            // Abonné : plus aucun cadenas.
            data.userSubscription(user, data.plan());
            flush();
            assertThat(service.epreuve(user.getId(), EpreuveType.TCF_EE).cta().locked()).isFalse();
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  TCF global
    // ══════════════════════════════════════════════════════════════════════

    @Nested
    class TcfGlobal {

        @Test
        @DisplayName("Aucun examen : 4 cartes toujours servies, rien d'inventé")
        void aucunExamen() {
            User user = data.user();

            ProgressionTcfDto dto = service.tcf(user.getId(), false);

            assertThat(dto.niveauActuel()).isNull();
            assertThat(dto.epreuves()).extracting(ProgressionTcfDto.EpreuveCarte::epreuve)
                    .containsExactly(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                            EpreuveType.TCF_EE, EpreuveType.TCF_EO);
            assertThat(dto.epreuves()).allSatisfy(c -> assertThat(c.resume().nombre()).isZero());
            assertThat(dto.examensComplets().nombre()).isZero();
            assertThat(dto.examensComplets().evolution()).isEqualTo(NiveauEvolution.INCONNUE);
            assertThat(dto.examens()).isEmpty();
            assertThat(dto.cta().locked()).isFalse();
        }

        /**
         * 🛑 D7 + D19. Quatre examens complets : un entier (palier persisté
         * sous l'ancienne règle), un partiel, une coquille vide, un en cours.
         * Seuls les deux premiers comptent ; le palier est RE-DÉRIVÉ.
         */
        @Test
        @DisplayName("D7 : coquilles vides hors compte ; D19 : palier re-dérivé, jamais relu")
        void examensCompletsComptesEtRederives() {
            User user = data.user();

            // (1) Entier, le plus ancien — figé à A1_NON_ATTEINT sous l'ancienne règle.
            Instant t1 = maintenant.minus(5, ChronoUnit.DAYS);
            Attempt entier = parentComplet(user, t1);
            entier.setFinalCecrlLevel(NiveauCecrl.A1_NON_ATTEINT);
            attemptManager.save(entier);
            qcmDansComplet(entier, user, EpreuveType.TCF_CO, NiveauCecrl.B2, t1);
            qcmDansComplet(entier, user, EpreuveType.TCF_CE, NiveauCecrl.B2, t1);
            productionDansComplet(entier, user, EpreuveType.TCF_EE, "16", t1);
            productionDansComplet(entier, user, EpreuveType.TCF_EO, "16", t1);

            // (2) Partiel : CO + CE passées, EE/EO jamais ouvertes.
            Instant t2 = maintenant.minus(2, ChronoUnit.DAYS);
            Attempt partiel = parentComplet(user, t2);
            qcmDansComplet(partiel, user, EpreuveType.TCF_CO, NiveauCecrl.A2, t2);
            qcmDansComplet(partiel, user, EpreuveType.TCF_CE, NiveauCecrl.B1, t2);
            jamaisOuverte(partiel, user, EpreuveType.TCF_EE, t2);
            jamaisOuverte(partiel, user, EpreuveType.TCF_EO, t2);

            // (3) Coquille vide : terminée, rien de mesuré.
            Instant t3 = maintenant.minus(1, ChronoUnit.DAYS);
            Attempt vide = parentComplet(user, t3);
            for (EpreuveType e : List.of(EpreuveType.TCF_CO, EpreuveType.TCF_CE,
                    EpreuveType.TCF_EE, EpreuveType.TCF_EO)) {
                jamaisOuverte(vide, user, e, t3);
            }

            // (4) En cours.
            Attempt enCours = parentComplet(user, null);
            qcmDansComplet(enCours, user, EpreuveType.TCF_CO, NiveauCecrl.B2, maintenant);
            flush();

            ProgressionTcfDto dto = service.tcf(user.getId(), false);

            ProgressionTcfDto.ExamensComplets ec = dto.examensComplets();
            assertThat(ec.nombre()).isEqualTo(2);
            assertThat(dto.examens()).extracting(ProgressionTcfDto.ExamenComplet::attemptId)
                    .containsExactly(partiel.getId(), entier.getId());
            assertThat(dto.examens()).extracting(ProgressionTcfDto.ExamenComplet::numero)
                    .containsExactly(2, 1);

            assertThat(ec.dernier().attemptId()).isEqualTo(partiel.getId());
            assertThat(ec.dernier().partiel()).isTrue();
            assertThat(ec.dernier().epreuvesComptees()).isEqualTo(2);
            // Meilleur et premier : les seuls non partiels.
            assertThat(ec.meilleur().attemptId()).isEqualTo(entier.getId());
            assertThat(ec.premier().attemptId()).isEqualTo(entier.getId());
            assertThat(ec.evolution()).isEqualTo(NiveauEvolution.INCONNUE);

            // 🛑 D19 : le palier de l'examen entier est le plancher RELU de ses
            // épreuves, pas le A1_NON_ATTEINT persisté.
            ProgressionTcfDto.ExamenComplet e1 = dto.examens().getLast();
            NiveauCecrl plancher = e1.parEpreuve().stream()
                    .map(ProgressionTcfDto.EpreuveLigne::niveau)
                    .filter(Objects::nonNull)
                    .min((a, b) -> Integer.compare(
                            TcfDiagnosticLevelResolver.rang(a), TcfDiagnosticLevelResolver.rang(b)))
                    .orElseThrow();
            assertThat(e1.niveau()).isEqualTo(plancher).isNotEqualTo(NiveauCecrl.A1_NON_ATTEINT);
            assertThat(e1.parEpreuve()).allSatisfy(l -> assertThat(l.score()).isNotNull());
            assertThat(e1.parEpreuve()).extracting(ProgressionTcfDto.EpreuveLigne::max)
                    .containsExactly(499, 499, 20, 20);

            // L'examen partiel : EE/EO « — », jamais 0.
            ProgressionTcfDto.ExamenComplet e2 = dto.examens().getFirst();
            assertThat(e2.parEpreuve().get(2).score()).isNull();
            assertThat(e2.parEpreuve().get(2).niveau()).isNull();
            assertThat(e2.parEpreuve().get(3).score()).isNull();

            // Les sous-épreuves alimentent aussi les cartes d'épreuve.
            assertThat(dto.epreuves().getFirst().resume().nombre()).isEqualTo(3);
            assertThat(dto.epreuves().get(2).resume().nombre()).isEqualTo(1);
        }

        @Test
        @DisplayName("D8 : 3 derniers par défaut, tous avec ?tous=true, numéros stables")
        void troisDerniersOuTous() {
            User user = data.user();
            for (int i = 0; i < 4; i++) {
                Instant fin = maintenant.minus(4 - i, ChronoUnit.DAYS);
                Attempt p = parentComplet(user, fin);
                qcmDansComplet(p, user, EpreuveType.TCF_CO, NiveauCecrl.A2, fin);
            }
            flush();

            ProgressionTcfDto court = service.tcf(user.getId(), false);
            ProgressionTcfDto tout = service.tcf(user.getId(), true);

            assertThat(court.examensComplets().nombre()).isEqualTo(4);
            assertThat(court.examens()).extracting(ProgressionTcfDto.ExamenComplet::numero)
                    .containsExactly(4, 3, 2);
            assertThat(tout.examens()).extracting(ProgressionTcfDto.ExamenComplet::numero)
                    .containsExactly(4, 3, 2, 1);
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Civique
    // ══════════════════════════════════════════════════════════════════════

    @Nested
    class Civique {

        /**
         * D10 + D12 + D13 : l'écran d'un thème ne lit que ses examens de thème ;
         * l'état est servi, et sa source aussi.
         */
        @Test
        @DisplayName("Thème : examens de thème seuls, état servi et sa source dite")
        void themeEtatServi() {
            User user = data.user();
            List<Theme> themes = themesCiviques();
            Theme t1 = themes.getFirst();
            Attempt ancien = examenDeTheme(user, t1, 12, maintenant.minus(3, ChronoUnit.DAYS));
            Attempt recent = examenDeTheme(user, t1, 17, maintenant.minus(1, ChronoUnit.DAYS));
            // Hors écran : un examen d'un AUTRE thème, un examen global.
            examenDeTheme(user, themes.get(1), 20, maintenant);
            examenCivique(user, null, 40, 32, maintenant, themes,
                    new int[]{8, 8, 8, 8, 8}, new int[]{8, 8, 8, 8, 8}, null);
            flush();

            ProgressionThemeDto dto = service.theme(user.getId(), t1.getId());

            assertThat(dto.code()).isEqualTo(t1.getCode());
            assertThat(dto.label()).isEqualTo(t1.getName());
            assertThat(dto.examens()).extracting(ProgressionMesureDto::attemptId)
                    .containsExactly(recent.getId(), ancien.getId());
            ProgressionMesureDto dernier = dto.examens().getFirst();
            assertThat(dernier.score()).isEqualByComparingTo("17");
            assertThat(dernier.max()).isEqualTo(20);
            assertThat(dernier.etat()).isEqualTo(CivicThemeState.SOLIDE);
            assertThat(dernier.seuilAtteint()).isTrue();
            assertThat(dernier.pointsManquants()).isZero();
            assertThat(dernier.taux()).isEqualTo(0.85);
            assertThat(dernier.provenance()).isEqualTo(ProgressionProvenance.EXAMEN_THEME);
            assertThat(dernier.rapport().kind()).isEqualTo(ProgressionRapport.QCM);

            ProgressionMesureDto premier = dto.examens().getLast();
            assertThat(premier.etat()).isEqualTo(CivicThemeState.A_RENFORCER);
            assertThat(premier.seuilAtteint()).isFalse();
            assertThat(premier.pointsManquants()).isEqualTo(4);

            assertThat(dto.resume().ecart()).isEqualByComparingTo("5");
            assertThat(dto.etat()).isEqualTo(CivicThemeState.SOLIDE);
            assertThat(dto.etatSource()).isEqualTo(ProgressionEtatSource.DERNIER_EXAMEN_THEME);
            assertThat(dto.etatSourceLabel()).isEqualTo(ProgressionEtatSource.DERNIER_EXAMEN_THEME.getLabel());
            assertThat(dto.echelle().seuil()).isEqualTo(16);
            // Examens de thème premium (D-33) : cadenas sur le bouton seulement.
            assertThat(dto.cta().locked()).isTrue();
        }

        @Test
        @DisplayName("Thème sans examen : état inconnu, jamais Faible")
        void themeSansExamen() {
            User user = data.user();
            Theme t = themesCiviques().getLast();

            ProgressionThemeDto dto = service.theme(user.getId(), t.getId());

            assertThat(dto.examens()).isEmpty();
            assertThat(dto.etat()).isNull();
            assertThat(dto.resume().nombre()).isZero();
        }

        @Test
        @DisplayName("Thème inconnu ou thème TCF : 404")
        void themeInconnu() {
            User user = data.user();
            Theme tcf = data.theme(Module.TCF, "TST_TCF", "Thème TCF");

            assertThatThrownBy(() -> service.theme(user.getId(), UUID.randomUUID()))
                    .isInstanceOf(NotFoundException.class);
            assertThatThrownBy(() -> service.theme(user.getId(), tcf.getId()))
                    .isInstanceOf(NotFoundException.class);
        }

        /**
         * 🛑 D11 : la part d'un thème dans un examen global est « x / n posées »,
         * mises en situation COMPRISES ; un thème non posé vaut 0 / 0. Les 5
         * thèmes sont toujours servis, dans l'ordre officiel.
         */
        @Test
        @DisplayName("Global : parts par thème en x / n posées, mises en situation comprises")
        void globalPartsParTheme() {
            User user = data.user();
            List<Theme> themes = themesCiviques();
            // T1 : 3 posées dont 1 mise en situation, 2 bonnes ; T2 : non posé ;
            // T5 : 1 posée, ratée.
            Attempt global = examenCivique(user, null, 40, 32, maintenant, themes,
                    new int[]{3, 0, 0, 0, 1}, new int[]{2, 0, 0, 0, 0}, QuestionType.MISE_SITUATION);
            // Le diagnostic civique n'est pas un examen global.
            Attempt diag = examenCivique(user, null, 40, 32, maintenant.minus(1, ChronoUnit.DAYS),
                    themes, new int[]{1, 0, 0, 0, 0}, new int[]{1, 0, 0, 0, 0}, null);
            CivicDiagnosticSession session = new CivicDiagnosticSession();
            session.setUser(user);
            session.setAttempt(diag);
            session.setMention(com.sejourfr.app.enums.Difficulty.CSP);
            session.setConfigVersion(1);
            session.setStatus(TcfDiagnosticStatus.COMPLETED);
            session.setStartedAt(maintenant.minus(1, ChronoUnit.DAYS));
            session.setCompletedAt(maintenant.minus(1, ChronoUnit.DAYS));
            civicSessionManager.save(session);
            diag.setCivicDiagnostic(session);
            attemptManager.save(diag);
            flush();

            ProgressionCiviqueDto dto = service.civique(user.getId(), false);

            assertThat(dto.echelle().max()).isEqualTo(40);
            assertThat(dto.echelle().seuil()).isEqualTo(32);
            assertThat(dto.global().nombre()).isEqualTo(1);
            assertThat(dto.themes()).extracting(ProgressionCiviqueDto.ThemeCarte::themeId)
                    .containsExactlyElementsOf(themes.stream().map(Theme::getId).toList());
            assertThat(dto.themes()).allSatisfy(c -> assertThat(c.resume().nombre()).isZero());

            assertThat(dto.examens()).singleElement().satisfies(ex -> {
                assertThat(ex.mesure().attemptId()).isEqualTo(global.getId());
                assertThat(ex.mesure().provenance()).isEqualTo(ProgressionProvenance.EXAMEN_GLOBAL);
                assertThat(ex.mesure().score()).isEqualByComparingTo("2");
                assertThat(ex.mesure().max()).isEqualTo(40);
                assertThat(ex.mesure().etat()).isEqualTo(CivicThemeState.FAIBLE);
                assertThat(ex.mesure().pointsManquants()).isEqualTo(30);
                assertThat(ex.parTheme()).hasSize(5);
                assertThat(ex.parTheme().get(0).posees()).isEqualTo(3);
                assertThat(ex.parTheme().get(0).bonnes()).isEqualTo(2);
                assertThat(ex.parTheme().get(1).posees()).isZero();
                assertThat(ex.parTheme().get(4).posees()).isEqualTo(1);
                assertThat(ex.parTheme().get(4).bonnes()).isZero();
            });
        }

        @Test
        @DisplayName("Global : 3 derniers par défaut, tous avec ?tous=true ; un template gratuit ouvre le CTA")
        void globalTroisDerniersEtCta() {
            User user = data.user();
            List<Theme> themes = themesCiviques();
            for (int i = 0; i < 4; i++) {
                examenCivique(user, null, 40, 32, maintenant.minus(4 - i, ChronoUnit.DAYS), themes,
                        new int[]{1, 1, 1, 1, 1}, new int[]{1, 1, 1, 1, i}, null);
            }
            data.examTemplate(Module.CIVIQUE, true, true);
            flush();

            ProgressionCiviqueDto court = service.civique(user.getId(), false);
            ProgressionCiviqueDto tout = service.civique(user.getId(), true);

            assertThat(court.global().nombre()).isEqualTo(4);
            assertThat(court.examens()).extracting(e -> e.mesure().numero()).containsExactly(4, 3, 2);
            assertThat(tout.examens()).hasSize(4);
            // Un template civique gratuit publié : la grille offre encore
            // quelque chose au compte gratuit.
            assertThat(court.cta().locked()).isFalse();
        }
    }
}
