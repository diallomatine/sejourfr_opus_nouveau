package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.DureeEpreuve;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.attempt.AttemptChrono;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Gardes d'accès communes aux DEUX voies de notation d'une production EE/EO :
 * la voie asynchrone (audio / texte déposés puis évalués) et la voie temps réel
 * (dialogue avec l'examinateur vocal). Elles étaient auparavant écrites dans la
 * seule voie asynchrone ; la voie temps réel arrivait donc sans aucun contrôle
 * (épreuve terminée, chrono écoulé, quota freemium) et pouvait noter dans une
 * sous-épreuve pré-terminée par le verrou freemium.
 *
 * <p>Deux familles de règles, volontairement séparées :
 * <ul>
 *   <li>{@link #assertCanSubmit} — cohérence de la SESSION : propriété,
 *       épreuve terminée, chrono, correspondance épreuve tâche ⇄ attempt, et
 *       plafond « une soumission par tâche » en session d'examen ;</li>
 *   <li>{@link #enforceQuota} — budget FREEMIUM (les deux examens blancs de
 *       production offerts a vie).</li>
 * </ul>
 *
 * <h2>🛑 Le freemium EE/EO a ete refondu le 2026-09-18 (D-17, D-17 bis)</h2>
 * <p>Ce qui est gratuit, et <b>rien d'autre</b> : <b>un</b> examen blanc
 * d'expression ecrite et <b>un</b> examen blanc d'expression orale, une fois a
 * vie chacun, <b>analyse IA complete incluse</b>. Deux gratuites nominatives,
 * lues sur un ledger persiste ({@link FreeExamEntitlementService}).
 *
 * <p><b>Les regles revoquees</b>, et elles l'ont ete verbatim :
 * <ul>
 *   <li>« <b>1 essai d'entrainement par epreuve a vie</b> »
 *       ({@code FREE_TRAINING_PER_EPREUVE = 1}) : <b>supprime</b>. Il
 *       contredisait « travailler EE/EO est premium » (D-17).</li>
 *   <li>« <b>2 sessions d'examen, EE+EO confondues</b> »
 *       ({@code countProductionExamSessions(userId) >= 2}) : <b>supprime</b>,
 *       remplace par <b>1 par epreuve, nominatif</b>. L'ancien seuil ne savait
 *       pas dire ou la gratuite avait ete prise, et comptait des examens
 *       <b>demarres</b> — donc abandonnes.</li>
 *   <li>« Refaire l'examen 1 = tolere une fois mais consomme les essais
 *       d'entrainement restants » : <b>supprime</b>. Le rejeu est <b>ouvert</b>,
 *       c'est l'<b>analyse</b> du second passage qui est premium.</li>
 * </ul>
 *
 * <h2>🛑 Aucun appel paye ne part sur un rejeu — ni correcteur, NI WHISPER</h2>
 * <p>{@link #enforceQuota} est appele par {@code ProductionSubmissionService}
 * <b>avant</b> {@code submitAndEvaluate}, donc avant la transcription : c'est
 * exactement la place ou l'idempotence de V046 coupe deja. Un rejeu ne consomme
 * rien et ne coute rien.
 *
 * <h2>Le cas de l'ORAL est traite plus tot, et c'est un arbitrage</h2>
 * <p>En EE, un rejeu sans analyse reste honnete : le texte du candidat est sous
 * ses yeux, il peut le relire. En EO, <b>il ne resterait rien</b> — sans Whisper
 * il n'y a ni transcription, ni note, ni trace, et l'audio d'un candidat n'est
 * <b>jamais</b> conserve (decision consentement). Faire produire un candidat
 * dans le vide est un mauvais geste : le paywall de l'oral se presente donc
 * <b>au demarrage</b> ({@link #assertCanStartProductionExam}), pas apres la
 * soumission.
 */
@Service
@RequiredArgsConstructor
public class ProductionAccessService {

    /**
     * Grâce après expiration du chrono d'épreuve (latence de l'auto-soumission
     * front). Une seule valeur pour tout le dépôt, partagée avec le chrono QCM
     * — cf. {@link DureeEpreuve#GRACE_SOUMISSION_SECONDS}.
     */
    static final int SUBMIT_GRACE_SECONDS = DureeEpreuve.GRACE_SOUMISSION_SECONDS;

    /**
     * Refus d'un entrainement libre EE/EO — <b>affichable tel quel</b>.
     *
     * <p>🛑 Il n'y a plus d'essai gratuit d'entrainement :
     * {@code FREE_TRAINING_PER_EPREUVE = 1} est <b>supprime</b> par D-17
     * (« travailler EE/EO est premium, sans exception »).
     */
    public static final String ENTRAINEMENT_PREMIUM_MESSAGE =
            "S'entraîner à l'expression écrite et orale demande un accès TCF. "
                    + "Votre examen blanc offert, lui, est corrigé en entier.";

    /**
     * Refus de l'epreuve terminee. Couvre les sous-epreuves EE/EO pre-terminees
     * d'un examen complet : un client ne contourne pas le verrou en postant
     * quand meme.
     */
    static final String EPREUVE_TERMINEE_MESSAGE =
            "Cette épreuve est terminée — soumission refusée.";

    private final SubscriptionService subscriptionService;
    private final AttemptManager attemptManager;
    private final ProductionSubmissionManager submissionManager;
    private final DiagnosticSessionManager diagnosticSessionManager;
    private final FreeExamEntitlementService freeExamEntitlementService;

    /**
     * Toutes les gardes de session à passer avant de créer une soumission EE/EO,
     * quelle que soit la voie (async ou temps réel).
     *
     * @param userId  utilisateur courant
     * @param attempt session visée (déjà chargée)
     * @param task    tâche soumise
     */
    public void assertCanSubmit(UUID userId, Attempt attempt, ProductionTask task) {
        assertOwnership(userId, attempt);
        assertPurposeAndDiagnosticPair(userId, attempt, task);
        assertNotFinished(attempt);
        assertWithinTimeLimit(attempt);
        assertWithinSessionGuard(attempt);
        assertEpreuveMatches(attempt, task);
        assertTacheNotAlreadySubmitted(attempt, task);
    }

    /**
     * Vérif d'appartenance (IDOR) : sans ce check, un attaquant peut deviner un
     * UUID d'attempt actif d'une victime et y poster ses propres productions,
     * polluant son examen blanc (sous-épreuve finalisée prématurément, niveau
     * CECRL calculé sur les productions de l'attaquant).
     */
    private void assertOwnership(UUID userId, Attempt attempt) {
        if (attempt.getUser() == null || !attempt.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("Cette session ne vous appartient pas");
        }
    }

    /**
     * Épreuve déjà finalisée (fin de session, expiration du chrono, ou
     * sous-attempt pré-terminé par le verrou freemium d'un examen complet) :
     * plus aucune soumission.
     */
    private void assertNotFinished(Attempt attempt) {
        if (attempt.getFinishedAt() != null) {
            throw new BusinessException("Cette épreuve est terminée — soumission refusée.");
        }
    }

    /**
     * Chrono d'épreuve — <b>expression écrite uniquement</b> (30 min pour les
     * 3 tâches, allocation libre). Grâce de {@value #SUBMIT_GRACE_SECONDS} s
     * pour couvrir la latence réseau de l'auto-soumission front à 0:00.
     * L'ancre est celle de {@link AttemptChrono} : sur une sous-épreuve
     * d'examen complet, le décompte ne part qu'au lancement réel de l'épreuve.
     *
     * <p>L'expression <b>orale</b> n'a pas de chrono d'épreuve : son temps se
     * compte par tâche, au lancement de chaque tâche. Elle n'a donc pas de
     * {@code time_limit_seconds} et ne passe que par
     * {@link #assertWithinSessionGuard}.
     */
    private void assertWithinTimeLimit(Attempt attempt) {
        if (AttemptChrono.horsDelai(attempt, Instant.now())) {
            throw new BusinessException("Le temps de l'épreuve est écoulé — soumission refusée.");
        }
    }

    /**
     * <b>Garde-fou de session à l'oral — ce n'est pas un chrono d'épreuve.</b>
     * Une session EO n'a pas de compte à rebours ; sans aucune borne, elle
     * resterait ouverte indéfiniment et un compte gratuit pourrait y accumuler
     * des évaluations IA payantes (Whisper + LLM) longtemps après l'avoir
     * abandonnée. Volontairement très large
     * ({@value DureeEpreuve#EO_GARDE_SESSION_SECONDS} s, cf.
     * {@link DureeEpreuve#EO_GARDE_SESSION_SECONDS}) et <b>jamais exposé</b> :
     * il n'est ni persisté sur l'attempt, ni publié dans un DTO.
     *
     * <p>Périmètre inchangé par rapport au chrono qu'il remplace : les
     * <b>sessions d'examen EO isolées</b>. Les sous-épreuves EO d'un examen
     * complet n'en ont pas — leur {@code started_at} date de la création de
     * l'examen, des dizaines de minutes avant que l'oral ne s'ouvre, et leur
     * coût IA est déjà borné par le plafond « une soumission par tâche ».
     */
    private void assertWithinSessionGuard(Attempt attempt) {
        if (attempt.getEpreuve() != EpreuveType.TCF_EO) return;
        if (attempt.getParentAttempt() != null) return;
        Instant ancre = AttemptChrono.ancre(attempt);
        if (ancre == null) return;
        Instant limite = ancre.plusSeconds(DureeEpreuve.EO_GARDE_SESSION_SECONDS);
        if (Instant.now().isAfter(limite)) {
            throw new BusinessException(
                    "Cette session d'expression orale est ouverte depuis trop longtemps — "
                            + "relancez l'épreuve pour continuer.");
        }
    }

    /**
     * La tâche doit relever de l'épreuve de la session. Sans ce contrôle, une
     * production orale était acceptée, évaluée et comptée dans une session
     * d'expression écrite (et inversement) : dans un examen TCF complet, cela
     * auto-finalisait la mauvaise sous-épreuve et lui posait un niveau CECRL
     * faux — or c'est ce niveau qui fait foi.
     */
    private void assertEpreuveMatches(Attempt attempt, ProductionTask task) {
        EpreuveType attendue = attempt.getEpreuve();
        if (attendue != task.getEpreuve()) {
            throw new BusinessException(
                    "Cette tâche relève de l'épreuve " + task.getEpreuve()
                            + " ; la session ouverte est une épreuve " + attendue
                            + ". Soumission refusée.");
        }
    }

    /**
     * Session d'examen : un examen, c'est 3 tâches, une fois chacune. Sans ce
     * plafond, rien ne borne le nombre de productions (donc d'évaluations IA
     * payantes) rattachées à une même session — la composition renvoyée par
     * {@code /production-exam-tasks} n'étant jamais opposée à ce qui est soumis.
     * L'entraînement libre n'est pas concerné (il a son propre quota freemium).
     */
    private void assertTacheNotAlreadySubmitted(Attempt attempt, ProductionTask task) {
        if (task.isDiagnostic()) {
            if (submissionManager.countByAttempt(attempt.getId()) > 0) {
                throw new BusinessException("Cette étape du diagnostic a déjà été rendue.");
            }
            return;
        }
        if (!isExamSession(attempt)) return;
        Short tache = task.getTacheNumero();
        if (tache == null) return;
        if (submissionManager.countByAttemptAndTache(attempt.getId(), tache) > 0) {
            throw new BusinessException(
                    "La tâche " + tache + " de cet examen a déjà été rendue — une seule "
                            + "production par tâche.");
        }
    }

    /** Session d'examen blanc production : slot posé au start, ou sous-épreuve d'un examen complet. */
    public static boolean isExamSession(Attempt attempt) {
        return attempt.getSlotNumber() != null || attempt.getParentAttempt() != null;
    }

    /**
     * <b>Budget freemium EE/EO</b> (refondu le 2026-09-18 — D-17, D-17 bis).
     * Acces TCF : illimite. Sans acces TCF :
     * <ul>
     *   <li><b>session d'examen</b> de production (slot pose, ou sous-epreuve
     *       d'un examen complet) : la soumission passe tant que la gratuite de
     *       <b>cette epreuve</b> est disponible, ou qu'elle a ete consommee par
     *       <b>cet examen-la</b> — les 3 taches du freebie sont dues ;</li>
     *   <li><b>entrainement libre</b> : <b>premium, sans exception</b>. L'essai
     *       gratuit par epreuve est revoque (D-17) ;</li>
     *   <li><b>sujet de diagnostic</b> : n'arrive jamais ici, la surcharge
     *       {@link #enforceQuota(UUID, ProductionTask, UUID)} sort avant — le
     *       diagnostic rapide est gratuit par lui-meme.</li>
     * </ul>
     *
     * <p>🛑 <b>Appele AVANT le pipeline</b>, donc avant Whisper et avant le
     * correcteur : un rejeu ne declenche aucun appel paye.
     */
    public void enforceQuota(UUID userId, EpreuveType epreuve, UUID attemptId) {
        if (subscriptionService.hasTcf(userId)) return;

        if (attemptId != null) {
            Attempt attempt = attemptManager.findById(attemptId).orElse(null);
            if (attempt != null) {
                // Epreuve deja terminee : aucune soumission. Couvre les EE/EO
                // verrouillees d'un examen complet gratuit (pre-terminees au
                // start) — empeche un client de contourner le verrou.
                if (attempt.getFinishedAt() != null) {
                    throw new AccessDeniedException(EPREUVE_TERMINEE_MESSAGE);
                }
                if (isExamSession(attempt)) {
                    if (freeExamEntitlementService.analyseOffertePossible(
                            userId, epreuve, attempt.getId())) {
                        return;
                    }
                    throw new AccessDeniedException(analyseDejaOfferteMessage(epreuve));
                }
            }
        }

        // Entrainement libre : il n'y a plus d'essai gratuit (D-17).
        throw new AccessDeniedException(ENTRAINEMENT_PREMIUM_MESSAGE);
    }

    /**
     * Refus du <b>rejeu</b> d'un examen dont la gratuite est consommee — ecrit
     * pour etre affiche tel quel par un paywall : il dit ce qui a deja ete
     * offert avant de dire ce qui est ferme.
     */
    private static String analyseDejaOfferteMessage(EpreuveType epreuve) {
        return "Votre examen blanc d'" + epreuve.getLabel().toLowerCase()
                + " offert a déjà été corrigé en entier. "
                + "Vous pouvez repasser l'épreuve, mais l'analyse IA d'un nouveau passage "
                + "demande un accès TCF.";
    }

    /**
     * Le meme budget freemium, <b>en lecture</b> : « ce candidat peut-il encore
     * produire librement sur cette epreuve ? ».
     *
     * <p>Sert a poser le cadenas sur la verification en situation du Plan
     * ({@code ReassessmentExerciseSelector}) sans rien tenter ni rien consommer.
     * Jumelle de {@link #enforceQuota} — deux copies auraient fini par afficher
     * un sujet ouvert que le serveur refuse, ou l'inverse. Le sujet reste
     * <b>designe</b> meme verrouille : savoir quoi travailler est ce que le Plan
     * apporte.
     *
     * <p>🛑 <b>Sans acces TCF, c'est toujours verrouille</b> (D-17) : l'essai
     * gratuit d'entrainement par epreuve n'existe plus. Le parametre
     * {@code epreuve} est conserve — l'appelant raisonne par epreuve, et le jour
     * ou une gratuite d'entrainement reviendrait, elle serait nominative comme
     * les deux autres.
     */
    @Transactional(readOnly = true)
    public boolean isTrainingLocked(UUID userId, EpreuveType epreuve) {
        return !subscriptionService.hasTcf(userId);
    }

    /**
     * Demarrage d'une <b>session d'examen blanc de production</b>,
     * <b>opposable</b>.
     *
     * <p>🛑 <b>Le rejeu est OUVERT</b> (D-17 bis) : repasser un examen dont la
     * gratuite est consommee n'est pas interdit, c'est son <b>analyse</b> qui
     * est premium — et {@link #enforceQuota} la refuse avant tout appel paye.
     *
     * <p><b>Sauf a l'ORAL, et c'est l'arbitrage rendu.</b> Sans Whisper, un rejeu
     * EO ne laisse <b>rien</b> a lire : ni transcription, ni note, ni trace, et
     * l'audio d'un candidat n'est jamais conserve. Le paywall se presente donc
     * ici, <b>au demarrage</b>, plutot que de faire produire un candidat dans le
     * vide. A l'ecrit, le texte reste sous ses yeux : le rejeu y est honnete.
     *
     * <p>Appele par {@code AttemptService.startProductionAttempt}. Lit
     * {@link #isProductionExamSlotLocked}, que la grille servie lit aussi.
     */
    public void assertCanStartProductionExam(UUID userId, EpreuveType epreuve, int slot) {
        if (!isProductionExamSlotLocked(userId, epreuve, slot)) return;
        if (slot > 1) {
            throw new AccessDeniedException(
                    "Les examens blancs d'expression au-delà du premier sont réservés aux abonnés TCF.");
        }
        throw new AccessDeniedException(
                "Votre examen blanc d'expression orale offert a déjà été corrigé en entier. "
                        + "Sans accès TCF, un nouvel enregistrement ne pourrait pas être "
                        + "analysé — et il n'est jamais conservé. "
                        + "L'accès TCF rouvre l'épreuve et sa correction.");
    }

    /**
     * <b>Le créneau d'une grille d'examens blancs de production</b> (EE / EO)
     * peut-il être DÉMARRÉ par ce candidat ? Autorité unique du démarrage
     * ({@link #assertCanStartProductionExam}, 403) et du {@code locked} servi
     * créneau par créneau ({@code ExamSlotsService}) — arbitrage du 2026-09-24,
     * « c'est le serveur qui décide du verrouillage ».
     *
     * <ul>
     *   <li>abonné TCF : tout est ouvert ;</li>
     *   <li>créneau 2+ : réservé aux abonnés TCF ;</li>
     *   <li>créneau 1 : l'examen offert (D-17). Rejouable à l'écrit (c'est
     *       l'<b>analyse</b> du rejeu qui est premium, {@link #enforceQuota}) ;
     *       fermé à l'oral dès que la gratuité EO est consommée (D-17 bis).</li>
     * </ul>
     */
    @Transactional(readOnly = true)
    public boolean isProductionExamSlotLocked(UUID userId, EpreuveType epreuve, int slot) {
        if (FreeEntitlementCode.pourExamenBlanc(epreuve) == null) return false;
        if (subscriptionService.hasTcf(userId)) return false;
        if (slot > 1) return true;
        return epreuve == EpreuveType.TCF_EO && freeExamEntitlementService.estConsomme(userId, epreuve);
    }

    /**
     * La meme regle <b>en lecture</b> : « l'examen blanc de cette epreuve de
     * production apporterait-il encore quelque chose a ce candidat ? ».
     *
     * <p>Sert a poser le cadenas du jalon d'epreuve du Plan
     * ({@code PlanMilestoneSelector}) et de l'etape {@code SECTION_EXAM} du
     * parcours ({@code JourneyReadService}) sans rien tenter ni rien consommer.
     * L'etape reste <b>designee</b> meme verrouillee — savoir ou l'on en est
     * fait partie de ce que le Plan apporte.
     *
     * <p>🛑 <b>Le verrou porte sur l'ANALYSE</b>, qui est ce qui donne un niveau
     * a l'epreuve : une epreuve de production dont la gratuite est consommee ne
     * peut plus se mesurer sans acces TCF. C'est pour cela que le cadenas se
     * pose des que la gratuite est consommee, alors meme que le <b>demarrage</b>
     * de l'ecrit reste possible.
     *
     * <p>Rend {@code false} pour CO / CE, qui gardent leur regle inchangee
     * (« slot 1 offert <b>et rejouable a volonte</b> »,
     * {@code AttemptService.enforceMockExamSlotAccess}).
     */
    @Transactional(readOnly = true)
    public boolean isProductionExamLocked(UUID userId, EpreuveType epreuve) {
        if (FreeEntitlementCode.pourExamenBlanc(epreuve) == null) return false;
        if (subscriptionService.hasTcf(userId)) return false;
        return freeExamEntitlementService.estConsomme(userId, epreuve);
    }

    /**
     * Les epreuves EE/EO d'un <b>examen blanc TCF complet</b> sont-elles
     * <b>toutes deux</b> verrouillees pour ce candidat ?
     *
     * <p>Jumelle en lecture du jalon « examen blanc complet » du Plan, qui n'a
     * qu'<b>un</b> cadenas a servir pour les quatre epreuves. Il ne se pose donc
     * que quand la partie production de l'examen n'apporte plus <b>rien</b> :
     * tant qu'une des deux gratuites reste disponible, l'examen complet en fera
     * profiter le candidat, et annoncer un cadenas serait faux.
     *
     * <p>🛑 Le verrou effectif, lui, est <b>par epreuve</b>
     * ({@link #isFullExamProductionLocked(UUID, EpreuveType)}) : deux gratuites
     * nominatives ne se ferment pas ensemble.
     */
    @Transactional(readOnly = true)
    public boolean isFullExamProductionLocked(UUID userId) {
        return isFullExamProductionLocked(userId, EpreuveType.TCF_EE)
                && isFullExamProductionLocked(userId, EpreuveType.TCF_EO);
    }

    /**
     * Cette epreuve de production est-elle verrouillee dans un examen blanc
     * complet ?
     *
     * <p>Autorite de {@code FullTcfExamService.start}, qui pre-termine la
     * sous-epreuve correspondante. 🛑 <b>Ramene au ledger</b> : l'ancienne
     * lecture ({@code ProductionSubmissionManager.hasFullExamProductionSubmission})
     * devinait la gratuite a partir de l'existence d'une <b>soumission</b> —
     * donc la consommait des le depot d'une tache, avant toute correction, et
     * sans savoir sur quelle epreuve. Une soumission dont le correcteur echoue
     * ne doit rien consommer (D-17).
     */
    @Transactional(readOnly = true)
    public boolean isFullExamProductionLocked(UUID userId, EpreuveType epreuve) {
        return isProductionExamLocked(userId, epreuve);
    }

    /**
     * Bypass gratuit strictement borné au triplet task + attempt + session du
     * même utilisateur. Une task diagnostic seule ne suffit jamais.
     */
    public void enforceQuota(UUID userId, ProductionTask task, UUID attemptId) {
        if (task.isDiagnostic()) {
            Attempt attempt = attemptManager.findById(attemptId)
                    .orElseThrow(() -> new BusinessException("Session de production introuvable."));
            assertOwnership(userId, attempt);
            assertPurposeAndDiagnosticPair(userId, attempt, task);
            return;
        }
        if (attemptId != null && diagnosticSessionManager.existsByAttemptId(attemptId)) {
            throw new BusinessException("Cet attempt est réservé au diagnostic.");
        }
        enforceQuota(userId, task.getEpreuve(), attemptId);
    }

    private void assertPurposeAndDiagnosticPair(
            UUID userId, Attempt attempt, ProductionTask task) {
        var session = diagnosticSessionManager.findByAttemptIdWithContent(attempt.getId()).orElse(null);
        if (!task.isDiagnostic()) {
            if (session != null) {
                throw new BusinessException("Cet attempt est réservé au diagnostic.");
            }
            return;
        }
        if (session == null || session.getUser() == null
                || !userId.equals(session.getUser().getId())) {
            throw new BusinessException("Sujet diagnostic hors de votre session active.");
        }
        boolean written = attempt.getId().equals(session.getWrittenAttempt().getId())
                && task.getId().equals(session.getWrittenTask().getId())
                && attempt.getEpreuve() == EpreuveType.TCF_EE;
        // 🛑 `hasOral()` d'abord : un diagnostic rapide (L3) n'a pas d'attempt
        // oral, et le déréférencer ici ferait tomber TOUTE soumission écrite.
        boolean oral = session.hasOral()
                && attempt.getId().equals(session.getOralAttempt().getId())
                && task.getId().equals(session.getOralTask().getId())
                && attempt.getEpreuve() == EpreuveType.TCF_EO;
        if (!written && !oral) {
            throw new BusinessException("Le sujet ne correspond pas à cette étape du diagnostic.");
        }
        if (session.getStatus() == com.sejourfr.app.enums.DiagnosticSessionStatus.COMPLETED
                || session.getStatus() == com.sejourfr.app.enums.DiagnosticSessionStatus.ANALYZING) {
            throw new BusinessException("Ce diagnostic n'accepte plus de nouvelle production.");
        }
    }
}
