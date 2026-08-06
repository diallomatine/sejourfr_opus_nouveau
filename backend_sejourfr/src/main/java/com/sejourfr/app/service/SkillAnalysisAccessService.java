package com.sejourfr.app.service;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.dto.SkillAnalysisQuotaDto;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Budget freemium des analyses IA du module competences.
 *
 * <p><b>Ce qui est gratuit et illimite pour tout compte inscrit</b> : produire
 * sur n'importe quel sujet, s'auto-evaluer, lire les 3 references. Aucun sujet
 * n'est verrouille. <b>Seule l'analyse IA est premium</b>, avec 3 analyses
 * offertes a vie aux comptes gratuits.
 *
 * <p><b>Le quota se consomme a l'ACCEPTATION, pas au succes.</b> C'est
 * volontaire : compter les analyses reussies rendrait le retry gratuit d'une
 * tentative en echec exploitable pour obtenir plus de 3 analyses. C'est
 * pourquoi le compteur s'appuie sur {@code analysis_requested} et non sur la
 * presence d'un resultat.
 */
@Service
@RequiredArgsConstructor
public class SkillAnalysisAccessService {

    /** Renvoye dans {@code remaining} pour dire « illimite ». */
    public static final int UNLIMITED = -1;

    private final SubscriptionService subscriptionService;
    private final UserSkillAttemptManager attemptManager;
    private final CompetenceProperties props;

    /**
     * Autorise (ou non) une nouvelle analyse IA. Ne consomme rien : le quota est
     * consomme par la persistance de la tentative avec
     * {@code analysisRequested = true}, dans la meme unite de travail que la
     * production.
     *
     * @throws AccessDeniedException (403) quand les analyses offertes sont epuisees
     */
    @Transactional(readOnly = true)
    public void assertCanAnalyse(UUID userId) {
        if (subscriptionService.hasTcf(userId)) {
            return;
        }
        int free = props.getAnalysis().getFreeAnalyses();
        long used = attemptManager.countAnalysesRequested(userId);
        if (used >= free) {
            throw new AccessDeniedException(
                    "Vos " + free + " analyses offertes ont été utilisées. "
                            + "Vous pouvez continuer à vous entraîner et à consulter les productions "
                            + "de référence gratuitement ; l'analyse détaillée nécessite un accès TCF.");
        }
    }

    /** Etat du quota, tel qu'affiche par les fronts. */
    @Transactional(readOnly = true)
    public SkillAnalysisQuotaDto quota(UUID userId) {
        boolean premium = subscriptionService.hasTcf(userId);
        int free = props.getAnalysis().getFreeAnalyses();
        int used = (int) Math.min(Integer.MAX_VALUE, attemptManager.countAnalysesRequested(userId));
        int remaining = premium ? UNLIMITED : Math.max(0, free - used);
        return new SkillAnalysisQuotaDto(premium, premium, free, used, remaining);
    }
}
