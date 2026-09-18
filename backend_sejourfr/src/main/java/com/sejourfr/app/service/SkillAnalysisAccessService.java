package com.sejourfr.app.service;

import com.sejourfr.app.dto.SkillAnalysisQuotaDto;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * <b>L'analyse IA du module Competences est PREMIUM, sans exception</b>
 * (arbitrage D-17, 2026-09-18).
 *
 * <h2>🛑 Ce qui est revoque</h2>
 * <p>Les <b>3 analyses offertes a vie</b> n'existent plus :
 * {@code sejourfr.competences.analysis.free-analyses: 3} est <b>supprime</b>, et
 * il n'est <b>pas remplace</b>. La phrase revoquee, verbatim
 * ({@code docs/regles/competences.md}, 2026-08-10) :
 * <blockquote>« les <b>3 analyses IA offertes a vie ne bougent pas</b> : un sujet
 * ouvert reste analysable dans la limite du quota existant
 * ({@code free-analyses}, decompte inchange). »</blockquote>
 *
 * <p>🛑 <b>Et aucun quota journalier ne le remplace</b> : le premier jet de la
 * spec proposait « 1 analyse IA / jour », l'arbitrage est <b>plus simple</b> —
 * pas de fenetre journaliere du tout, {@code dailyQuota} n'existe pas.
 *
 * <p>⚠️ <b>Ce service est devenu redondant en pratique</b>, et c'est assume :
 * depuis D-18, {@link SkillAccessService} ne laisse plus aucun sujet ouvert a un
 * compte gratuit, donc aucune production ne peut y naitre. Le verrou reste
 * neanmoins ecrit ici : c'est la <b>seule</b> autorite de « l'analyse est-elle
 * due ? », et un verrou d'acces ne se deduit jamais d'un autre.
 *
 * <p><b>Ce qui reste gratuit</b> et ne depend pas de lui : le diagnostic rapide
 * et les <b>deux examens blancs de production offerts</b>, dont les 3 taches
 * sont reellement corrigees ({@link FreeExamEntitlementService}). Ces deux
 * gratuites ont leur propre ledger et ne passent jamais par ici.
 */
@Service
@RequiredArgsConstructor
public class SkillAnalysisAccessService {

    /** Renvoye dans {@code remaining} pour dire « illimite ». */
    public static final int UNLIMITED = -1;

    /**
     * Analyses offertes a un compte gratuit : <b>aucune</b> (D-17).
     *
     * <p>🛑 <b>Zero n'est pas un reglage, c'est la regle</b> — d'ou une constante
     * et non une cle de configuration : remettre une cle ici ferait croire qu'on
     * peut rouvrir un quota gratuit sans arbitrage.
     */
    public static final int FREE_ANALYSES = 0;

    /**
     * Refus, ecrit pour etre <b>affichable tel quel</b> par un paywall : il dit
     * ce qui reste avant de dire ce qui manque.
     */
    public static final String LOCKED_MESSAGE =
            "L'analyse détaillée d'une production nécessite un accès TCF. "
                    + "Votre examen blanc d'expression écrite et votre examen blanc "
                    + "d'expression orale offerts, eux, sont corrigés en entier.";

    private final SubscriptionService subscriptionService;
    private final UserSkillAttemptManager attemptManager;

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
        throw new AccessDeniedException(LOCKED_MESSAGE);
    }

    /**
     * Etat du quota, tel qu'affiche par les fronts.
     *
     * <p>⚠️ <b>Contrat conserve, valeurs devenues degenerees</b> :
     * {@code freeAnalysesTotal} vaut desormais <b>0</b> et {@code remaining}
     * vaut 0 pour un compte gratuit, {@code -1} pour un abonne. Le champ
     * {@code freeAnalysesUsed} continue de compter les analyses deja demandees —
     * c'est un fait, il reste vrai. La forme du DTO ne bouge pas : casser le
     * contrat aurait fait tomber les deux fronts sur une refonte de freemium qui
     * ne leur demandait rien d'autre qu'un libelle.
     */
    @Transactional(readOnly = true)
    public SkillAnalysisQuotaDto quota(UUID userId) {
        boolean premium = subscriptionService.hasTcf(userId);
        int used = (int) Math.min(Integer.MAX_VALUE, attemptManager.countAnalysesRequested(userId));
        int remaining = premium ? UNLIMITED : 0;
        return new SkillAnalysisQuotaDto(premium, premium, FREE_ANALYSES, used, remaining);
    }
}
