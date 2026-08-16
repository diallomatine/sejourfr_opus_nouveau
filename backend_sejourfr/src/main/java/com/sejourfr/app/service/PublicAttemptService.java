package com.sejourfr.app.service;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Pipeline d'attempts pour visiteurs non authentifiés (démo guest).
 * <p>
 * Règles :
 * <ul>
 *   <li>Seuls TRAINING et MOCK_EXAM sont autorisés (REVIEW exige un compte).</li>
 *   <li>Démo illimitée : aucun quota n'est appliqué. Les questions tirées sont
 *       déterministes (cf. {@link AttemptService#startGuestDemo}), donc relancer
 *       une démo redonne toujours la même série — l'objectif est de convertir,
 *       pas d'offrir un entraînement complet.</li>
 *   <li>Périmètre ouvert sans compte : série 1, template free (diagnostic
 *       complet), examen civique global, et depuis le 2026-08-16 le
 *       <b>slot 1</b> d'un examen blanc d'épreuve TCF QCM (CO / CE /
 *       STRUCTURE). Les examens civiques de thème, les slots 2+ et les
 *       productions EE/EO restent réservés aux comptes.</li>
 *   <li>Accès en lecture / answers / finish : exige que l'attempt soit guest
 *       (user IS NULL) ET que l'IP du caller corresponde. Sinon 404 silencieux
 *       (pas 403, pour ne pas révéler l'existence).</li>
 * </ul>
 * La construction effective de l'attempt (tirage des questions, persistance)
 * est déléguée à {@link AttemptService#startGuestDemo} pour ne pas dupliquer
 * la logique métier.
 */
@Service
@RequiredArgsConstructor
public class PublicAttemptService {

    private final AttemptService attemptService;

    @Transactional
    public AttemptResponse startDemo(StartAttemptRequest req, String clientIp) {
        if (req.type() != AttemptType.TRAINING && req.type() != AttemptType.MOCK_EXAM) {
            throw new BusinessException("La démo guest ne supporte que TRAINING et MOCK_EXAM");
        }
        if (clientIp == null || clientIp.isBlank()) {
            // En théorie impossible (getRemoteAddr renvoie toujours quelque chose
            // dans un environnement servlet standard). On conserve l'invariant
            // "client_ip toujours posée pour un guest" pour l'audit / une
            // éventuelle réactivation de quota plus tard.
            throw new BusinessException("Impossible de déterminer l'IP du client");
        }

        // Quota supprimé 2026-05-17 : la démo est désormais illimitée mais joue
        // toujours la même série déterministe de questions (cf. AttemptService).
        return attemptService.startGuestDemo(req, clientIp);
    }

    @Transactional(readOnly = true)
    public AttemptResponse getDemoById(UUID id, String clientIp) {
        Attempt attempt = attemptService.loadGuestAttempt(id, clientIp);
        return attemptService.readAttempt(attempt);
    }

    @Transactional
    public AnswerResultResponse submitDemoAnswer(UUID id, String clientIp, SubmitAnswerRequest req) {
        Attempt attempt = attemptService.loadGuestAttempt(id, clientIp);
        return attemptService.submitAnswerForAttempt(attempt, req);
    }

    @Transactional
    public AttemptResponse finishDemo(UUID id, String clientIp) {
        Attempt attempt = attemptService.loadGuestAttempt(id, clientIp);
        return attemptService.finishAttempt(attempt);
    }
}
