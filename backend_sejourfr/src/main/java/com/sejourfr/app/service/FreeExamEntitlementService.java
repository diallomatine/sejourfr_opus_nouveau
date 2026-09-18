package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.manager.FreeEntitlementUsageManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * <b>Les deux examens blancs de production offerts a vie</b> — un pour
 * l'expression ecrite, un pour l'expression orale (arbitrages D-17 et D-17 bis,
 * 2026-09-18).
 *
 * <p>Ce service est la <b>seule</b> porte du ledger {@code free_entitlement_usage}
 * pour les examens de production : il dit si la gratuite est encore disponible,
 * et il l'ecrit. {@link ProductionAccessService} l'interroge pour opposer le
 * verrou et servir le {@code locked} ; le pipeline de correction l'appelle pour
 * consommer.
 *
 * <h2>🛑 Ce que le freebie est, exactement</h2>
 * <ul>
 *   <li><b>Deux gratuites nominatives</b>, pas « une au choix » : un candidat
 *       qui a use la sienne en EE garde la sienne en EO.</li>
 *   <li><b>Complete</b> : les 3 taches de l'epreuve sont reellement corrigees, le
 *       LLM <b>est</b> appele, l'analyse entiere est rendue. C'est la vitrine du
 *       produit, pas un apercu.</li>
 *   <li><b>Le rejeu reste ouvert, c'est l'ANALYSE qui est premium</b> : repasser
 *       l'epreuve n'est pas interdit, la faire corriger une seconde fois l'est.
 *       🛑 Et un rejeu ne declenche <b>aucun appel paye</b> — ni correcteur, ni
 *       <b>Whisper</b> : le refus se pose avant le pipeline, a l'endroit meme ou
 *       l'idempotence de V046 coupe deja.</li>
 *   <li>🛑 <b>Aucun quota journalier</b> : le premier jet de la spec proposait
 *       « 1 analyse IA / jour », l'arbitrage est <b>premium, point</b> (D-17).</li>
 * </ul>
 *
 * <h2>🛑 La consommation s'ecrit a la REMISE DE L'ANALYSE</h2>
 * <p>Ni au demarrage de l'examen, ni sur la seule cloture de la session : un
 * abandon, une expiration, un echec technique ou un echec du correcteur laissent
 * la gratuite <b>intacte</b>, et le candidat la retrouve. Sinon « offert une
 * fois » voudrait dire « perdu une fois », et ce serait une promesse trahie a
 * l'ecran. Le point d'ecriture est donc
 * {@link #consommerApresAnalyse(UUID)}, appele par
 * {@code ProductionPipelineAsyncRunner} <b>apres</b> qu'une {@code AiEvaluation}
 * a ete produite et persistee.
 *
 * <h2>Pourquoi la ligne porte l'attempt, et pourquoi c'est la 1<sup>re</sup>
 * analyse qui la pose</h2>
 * <p>Un examen, c'est <b>3</b> taches. La gratuite est ecrite des que la
 * <b>premiere</b> analyse est rendue, et les deux taches suivantes de <b>ce
 * meme attempt</b> restent alors corrigees gratuitement — c'est a cela que sert
 * {@code source_attempt_id}. L'alternative (n'ecrire qu'apres la 3<sup>e</sup>
 * tache) laissait un candidat abandonner chaque examen sur la 2<sup>e</sup> tache
 * et obtenir ainsi des corrections LLM <b>sans aucune borne</b> : c'est l'argent
 * du proprietaire, et « offert une fois » ne peut pas signifier « offert autant
 * de fois qu'on abandonne ». Le candidat qui recoit une analyse a bien recu
 * quelque chose ; celui qui n'en recoit aucune n'a rien consomme.
 *
 * <h2>Pourquoi un abonne ne consomme rien</h2>
 * <p>Le ledger dit « ceci lui a ete <b>offert</b> ». Un abonne n'a rien recu en
 * cadeau : sa correction est payee par son abonnement. Lui ecrire une ligne lui
 * confisquerait sa gratuite pour le jour ou il se desabonnerait.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FreeExamEntitlementService {

    private final FreeEntitlementUsageManager ledger;
    private final SubscriptionService subscriptionService;
    private final ProductionSubmissionManager submissionManager;

    /**
     * La gratuite de cette epreuve est-elle <b>deja consommee</b> ?
     *
     * <p>Ne regarde <b>pas</b> l'abonnement : c'est un fait du ledger, pas un
     * droit d'acces. L'appelant compose les deux.
     */
    @Transactional(readOnly = true)
    public boolean estConsomme(UUID userId, EpreuveType epreuve) {
        FreeEntitlementCode code = FreeEntitlementCode.pourExamenBlanc(epreuve);
        return code != null && ledger.estConsomme(userId, code);
    }

    /**
     * <b>Cet examen-la peut-il encore recevoir une analyse offerte ?</b>
     *
     * <p>Vrai dans deux cas, et deux seulement : la gratuite n'est pas encore
     * consommee, <b>ou</b> elle l'a ete par <b>cet attempt</b> — les 2 taches
     * restantes du meme examen sont dues au titre de la meme gratuite.
     *
     * <p>Ne regarde pas l'abonnement, pour la meme raison que
     * {@link #estConsomme}.
     *
     * @param attemptId la session d'examen visee ; {@code null} n'est jamais
     *                  l'examen qui a consomme la gratuite.
     */
    @Transactional(readOnly = true)
    public boolean analyseOffertePossible(UUID userId, EpreuveType epreuve, UUID attemptId) {
        FreeEntitlementCode code = FreeEntitlementCode.pourExamenBlanc(epreuve);
        if (code == null) return false;
        return ledger.find(userId, code)
                .map(usage -> {
                    Attempt source = usage.getSourceAttempt();
                    return attemptId != null && source != null
                            && attemptId.equals(source.getId());
                })
                .orElse(true);
    }

    /**
     * <b>Consomme la gratuite, maintenant que l'analyse est rendue.</b>
     *
     * <p>Ne fait rien — et c'est le cas le plus courant — hors des trois
     * conditions cumulees : la production releve d'une <b>session d'examen</b>
     * de production (slot pose, ou sous-epreuve d'un examen complet), son
     * epreuve porte une gratuite (EE ou EO), et le candidat <b>n'a pas</b>
     * l'acces TCF. Un sujet de diagnostic n'entre jamais ici : le diagnostic
     * rapide est gratuit par lui-meme et n'a pas a consommer une gratuite
     * d'examen.
     *
     * <p><b>Transaction propre et exceptions avalees</b> : cet appel est un
     * enrichissement de fin de pipeline. Il ne doit <b>jamais</b> degrader une
     * correction deja obtenue — le candidat a recu son analyse, c'est ce qui
     * compte. L'ecriture elle-meme est idempotente
     * ({@code FreeEntitlementUsageManager.consommer} avale la violation
     * d'unicite), donc un second passage ne peut ni echouer ni compter deux fois.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void consommerApresAnalyse(UUID submissionId) {
        try {
            ProductionSubmission submission =
                    submissionManager.findByIdWithTaskAndUser(submissionId).orElse(null);
            if (submission == null || submission.getUser() == null) return;
            if (submission.isDiagnostic()
                    || (submission.getProductionTask() != null
                            && submission.getProductionTask().isDiagnostic())) {
                return;
            }
            Attempt attempt = submission.getAttempt();
            if (attempt == null || !ProductionAccessService.isExamSession(attempt)) return;
            FreeEntitlementCode code =
                    FreeEntitlementCode.pourExamenBlanc(attempt.getEpreuve());
            if (code == null) return;
            UUID userId = submission.getUser().getId();
            if (subscriptionService.hasTcf(userId)) return;
            if (ledger.consommer(submission.getUser(), code, attempt)) {
                log.info("Gratuite {} consommee par l'utilisateur {} (examen {}, analyse {})",
                        code, userId, attempt.getId(), submissionId);
            }
        } catch (Exception jamaisBloquant) {
            log.warn("Consommation de la gratuite ignoree pour la submission {} : {}",
                    submissionId, jamaisBloquant.getMessage());
        }
    }
}
