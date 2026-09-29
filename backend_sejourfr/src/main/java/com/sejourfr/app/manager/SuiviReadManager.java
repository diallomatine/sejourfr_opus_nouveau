package com.sejourfr.app.manager;

import com.sejourfr.app.repository.SuiviReadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Seule couche autorisee a toucher {@link SuiviReadRepository}. Lecture seule,
 * six requetes constantes par appel.
 */
@Component
@RequiredArgsConstructor
public class SuiviReadManager {

    private final SuiviReadRepository repository;

    /**
     * Parametres communs, deja resolus par le service.
     *
     * @param horizon   {@code to + windowDays} (dernier fait possible d'une cohorte)
     * @param type      {@code TCF} / {@code CIVIQUE} (type d'achat) ou {@code null}
     * @param runType   {@code QUICK_TCF} / {@code CIVIQUE} (type de run) ou {@code null}
     * @param platform  {@code WEB} / {@code IOS} / {@code ANDROID} ou {@code null}
     * @param source    groupe de source ou {@code null}
     * @param srcMap    objet JSON source declaree → groupe (config)
     * @param fallback  groupe de repli (config)
     * @param civicMinRatio part minimale de questions repondues d'un « soumis »
     *                  civique (config, controle C)
     */
    public record Requete(Instant prevFrom, Instant from, Instant to, Instant horizon, int windowDays,
                          String type, String runType, String platform, String source,
                          boolean includeInternal, String srcMap, String fallback, double civicMinRatio,
                          Debuts debuts) {
    }

    /**
     * Borne basse de la periode COURANTE de chaque lecture : minuit (Paris) du
     * premier jour ou ses indicateurs sont mesures, jamais avant {@code from}
     * (D117). La periode precedente garde ses bornes {@code [prevFrom, from)}.
     *
     * @param visitors    visiteurs et sources
     * @param cohort      entrees du tunnel (etape 1)
     * @param submitted   soumissions (KPI, activite)
     * @param anonymous   soumis anonymes jamais rattaches
     * @param attached    connexions apres diagnostic
     * @param purchases   achats
     * @param refunds     remboursements
     * @param signups     total des inscriptions
     * @param signupContext contexte d'inscription
     * @param signupPlatform ventilation par plateforme
     */
    public record Debuts(Instant visitors, Instant cohort, Instant submitted, Instant anonymous,
                         Instant attached, Instant purchases, Instant refunds, Instant signups,
                         Instant signupContext, Instant signupPlatform) {
    }

    /** Les six lectures d'un appel, dans une seule transaction (instantane coherent). */
    public record Lectures(List<SuiviReadRepository.VisitorCell> visitors,
                           List<SuiviReadRepository.FunnelRow> funnel,
                           SuiviReadRepository.ActivityRow activity,
                           List<SuiviReadRepository.PurchaseCell> purchases,
                           List<SuiviReadRepository.RefundCell> refunds,
                           SuiviReadRepository.SignupRow signups) {
    }

    @Transactional(readOnly = true)
    public Lectures lire(Requete q) {
        Debuts d = q.debuts();
        return new Lectures(
                repository.visitors(q.prevFrom(), q.from(), d.visitors(), q.to(), q.platform(), q.source(),
                        q.includeInternal(), q.srcMap(), q.fallback()),
                repository.funnel(d.cohort(), q.to(), q.horizon(), q.windowDays(), q.platform(), q.source(),
                        q.includeInternal(), q.srcMap(), q.fallback(), q.civicMinRatio()),
                repository.activity(q.prevFrom(), q.from(), d.submitted(), d.anonymous(), d.attached(), q.to(),
                        q.windowDays(), q.runType(), q.platform(), q.source(), q.includeInternal(), q.srcMap(),
                        q.fallback(), q.civicMinRatio()),
                repository.purchases(q.prevFrom(), q.from(), d.purchases(), q.to(), q.type(), q.platform(),
                        q.source(), q.includeInternal(), q.srcMap(), q.fallback()),
                repository.refunds(q.prevFrom(), q.from(), d.refunds(), q.to(), q.type(), q.platform(),
                        q.source(), q.includeInternal(), q.srcMap(), q.fallback()),
                repository.signups(d.signups(), d.signupContext(), d.signupPlatform(), q.to(), q.platform(),
                        q.source(), q.includeInternal(), q.srcMap(), q.fallback()));
    }
}
