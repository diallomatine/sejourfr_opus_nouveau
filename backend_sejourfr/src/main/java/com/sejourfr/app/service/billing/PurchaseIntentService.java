package com.sejourfr.app.service.billing;

import com.sejourfr.app.dto.PurchaseIntentRequest;
import com.sejourfr.app.dto.PurchaseIntentResponse;
import com.sejourfr.app.entity.DiagnosticRun;
import com.sejourfr.app.entity.Plan;
import com.sejourfr.app.entity.PurchaseIntent;
import com.sejourfr.app.enums.AnalyticsCtaLocation;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.PurchaseOrigin;
import com.sejourfr.app.manager.DiagnosticRunManager;
import com.sejourfr.app.manager.PlanManager;
import com.sejourfr.app.manager.PurchaseIntentManager;
import com.sejourfr.app.service.analytics.AnalyticsConfig;
import com.sejourfr.app.util.ClientContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.EnumSet;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Intentions d'achat (arbitrage Q12) : creation avant chaque demarrage d'achat,
 * puis consommation — une seule fois — au moment ou l'achat est ecrit.
 *
 * <p>🛑 <b>Aucune reconstruction heuristique.</b> Un achat sans intention
 * valide (absente, illisible, d'un autre compte, d'un autre produit, expiree,
 * deja consommee) est range {@link PurchaseOrigin#UNKNOWN}, run nulle. On ne
 * cherche jamais « la run la plus recente » du compte.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PurchaseIntentService {

    /**
     * Les CTA « du Plan » : seul un achat parti d'eux peut etre
     * {@link PurchaseOrigin#DIAGNOSTIC_PLAN}. Aujourd'hui tous les boutons
     * « Debloquer » du Plan posent {@code LOCKED_PLAN} (web et mobile).
     */
    static final Set<AnalyticsCtaLocation> CTA_DU_PLAN = EnumSet.of(AnalyticsCtaLocation.LOCKED_PLAN);

    private final PurchaseIntentManager purchaseIntentManager;
    private final DiagnosticRunManager diagnosticRunManager;
    private final PlanManager planManager;
    private final AnalyticsConfig analyticsConfig;
    private final Clock clock;

    /**
     * Creation explicite (mobile, avant la feuille Apple / Google).
     *
     * @throws ResponseStatusException 404 produit inconnu ou inactif ; 400
     *         emplacement de CTA hors liste
     */
    @Transactional
    public PurchaseIntentResponse creer(UUID userId, PurchaseIntentRequest request, ClientContext client) {
        Plan plan = planDuProduit(request.productId())
                .filter(Plan::isActive)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Produit inconnu ou inactif : " + request.productId()));
        AnalyticsCtaLocation cta = ctaLocation(request.ctaLocation())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "ctaLocation inconnu : " + request.ctaLocation()));
        PurchaseIntent intent = enregistrer(userId, plan, cta, request.journeyId(), plateforme(client));
        return new PurchaseIntentResponse(intent.getId(), intent.getExpiresAt());
    }

    /**
     * Creation implicite par le checkout Stripe. Ne bloque JAMAIS un paiement :
     * un CTA absent (client anterieur au champ) ou hors liste ne cree rien, et
     * l'achat sera {@link PurchaseOrigin#UNKNOWN}.
     */
    @Transactional
    public Optional<UUID> creerPourCheckout(UUID userId, Plan plan, String ctaLocationRaw,
                                            String journeyIdRaw, ClientContext client) {
        Optional<AnalyticsCtaLocation> cta = ctaLocation(ctaLocationRaw);
        if (cta.isEmpty()) {
            log.debug("Checkout sans ctaLocation exploitable (user={}) : pas d'intention.", userId);
            return Optional.empty();
        }
        return Optional.of(enregistrer(userId, plan, cta.get(), journeyIdRaw, plateforme(client)).getId());
    }

    /**
     * Consomme l'intention recue avec un achat et en rend l'attribution. A
     * appeler DANS la transaction qui ecrit l'achat : un rollback rend
     * l'intention au mobile, qui pourra la renvoyer au rejeu.
     *
     * @param purchasedAt instant de l'achat selon le canal ; l'expiration se
     *                    juge a cet instant, pas a l'heure de reception d'un
     *                    webhook relance
     */
    @Transactional
    public AttributionAchat consommer(UUID userId, Plan plan, String intentIdRaw, Instant purchasedAt) {
        UUID intentId = uuid(intentIdRaw);
        if (intentId == null || plan == null || plan.getCode() == null) {
            return AttributionAchat.INCONNUE;
        }
        Instant now = clock.instant();
        Instant at = purchasedAt != null ? purchasedAt : now;
        if (!purchaseIntentManager.consume(intentId, userId, plan.getCode(), at, now)) {
            log.info("Intention d'achat {} refusee (autre compte, autre produit, expiree ou deja "
                    + "consommee) : origine UNKNOWN.", intentId);
            return AttributionAchat.INCONNUE;
        }
        PurchaseIntent intent = purchaseIntentManager.findById(intentId).orElse(null);
        if (intent == null) return AttributionAchat.INCONNUE;
        if (CTA_DU_PLAN.contains(intent.getCtaLocation())) {
            // Parti du Plan, mais sans run fondatrice resoluble (parcours absent,
            // d'un autre compte, ou diagnostic sans run) : l'achat vient bien du
            // Plan, donc OTHER_CTA serait faux — il est INCONNU.
            PurchaseOrigin origin = intent.getDiagnosticRunId() != null
                    ? PurchaseOrigin.DIAGNOSTIC_PLAN : PurchaseOrigin.UNKNOWN;
            return new AttributionAchat(origin, intent.getId(), intent.getJourneyId(),
                    intent.getDiagnosticRunId());
        }
        return new AttributionAchat(PurchaseOrigin.OTHER_CTA, intent.getId(), intent.getJourneyId(), null);
    }

    private PurchaseIntent enregistrer(UUID userId, Plan plan, AnalyticsCtaLocation cta,
                                       String journeyIdRaw, ClientPlatform platform) {
        Instant now = clock.instant();
        UUID journeyId = purchaseIntentManager.ownedJourney(uuid(journeyIdRaw), userId).orElse(null);
        PurchaseIntent intent = new PurchaseIntent();
        intent.setId(UUID.randomUUID());
        intent.setUserId(userId);
        intent.setCtaLocation(cta);
        intent.setProductId(plan.getCode());
        intent.setPlatform(platform);
        intent.setJourneyId(journeyId);
        intent.setDiagnosticRunId(diagnosticRunManager.findFoundingRun(journeyId, userId)
                .map(DiagnosticRun::getId).orElse(null));
        intent.setCreatedAt(now);
        intent.setExpiresAt(now.plus(analyticsConfig.purchaseIntentTtlHours(), ChronoUnit.HOURS));
        return purchaseIntentManager.save(intent);
    }

    /** Code du pass d'abord (web), puis SKU Apple, puis SKU Google (mobile). */
    private Optional<Plan> planDuProduit(String productId) {
        if (productId == null || productId.isBlank()) return Optional.empty();
        String id = productId.trim();
        return planManager.findByCode(id)
                .or(() -> planManager.findByAppleProductId(id))
                .or(() -> planManager.findByGoogleProductId(id));
    }

    static Optional<AnalyticsCtaLocation> ctaLocation(String raw) {
        if (raw == null || raw.isBlank()) return Optional.empty();
        try {
            return Optional.of(AnalyticsCtaLocation.valueOf(raw.trim().toUpperCase(Locale.ROOT)));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    private static ClientPlatform plateforme(ClientContext client) {
        return client != null && client.platform() != null ? client.platform() : ClientPlatform.UNKNOWN;
    }

    private static UUID uuid(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return UUID.fromString(raw.trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
