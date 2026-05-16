package com.sejourfr.app.service;

import com.sejourfr.app.dto.AnswerResultResponse;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.StartAttemptRequest;
import com.sejourfr.app.dto.SubmitAnswerRequest;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.DemoLimitReachedException;
import com.sejourfr.app.repository.AttemptRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;

/**
 * Pipeline d'attempts pour visiteurs non authentifiés (démo guest).
 * <p>
 * Règles :
 * <ul>
 *   <li>Seuls TRAINING et MOCK_EXAM sont autorisés (REVIEW exige un compte).</li>
 *   <li>Quota : 1 attempt par (client_ip, module, attempt_type) par mois
 *       calendaire. Au-delà → {@link DemoLimitReachedException} (HTTP 429).</li>
 *   <li>Accès en lecture / answers / finish : exige que l'attempt soit guest
 *       (user IS NULL) ET que l'IP du caller corresponde. Sinon 404 silencieux
 *       (pas 403, pour ne pas révéler l'existence).</li>
 * </ul>
 * La construction effective de l'attempt (tirage des questions, persistance)
 * est déléguée à {@link AttemptService#startGuestDemo} pour ne pas dupliquer
 * la logique métier.
 */
@Service
public class PublicAttemptService {

    private final AttemptService attemptService;
    private final AttemptRepository attemptRepository;

    public PublicAttemptService(AttemptService attemptService, AttemptRepository attemptRepository) {
        this.attemptService = attemptService;
        this.attemptRepository = attemptRepository;
    }

    @Transactional
    public AttemptResponse startDemo(StartAttemptRequest req, String clientIp) {
        if (req.type() != AttemptType.TRAINING && req.type() != AttemptType.MOCK_EXAM) {
            throw new BusinessException("La démo guest ne supporte que TRAINING et MOCK_EXAM");
        }
        if (clientIp == null || clientIp.isBlank()) {
            // En théorie impossible (getRemoteAddr renvoie toujours quelque chose
            // dans un environnement servlet standard), mais on évite tout quota
            // sur null qui permettrait de contourner avec un proxy bizarre.
            throw new BusinessException("Impossible de déterminer l'IP du client");
        }

        Instant monthStart = LocalDate.now(ZoneOffset.UTC)
                .withDayOfMonth(1)
                .atStartOfDay(ZoneOffset.UTC)
                .toInstant();

        long used = attemptRepository
                .countByClientIpAndModuleAndTypeAndUserIsNullAndStartedAtAfter(
                        clientIp, req.module(), req.type(), monthStart
                );
        if (used >= 1) {
            throw new DemoLimitReachedException(req.module(), req.type());
        }

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
