package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.entity.UserSubscription;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.email.automation.PremiumAccessEndResolver.Wording;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

/**
 * Les mails ENGAGEMENT des scenarios automatises, composes a partir de ce que
 * la requete de scenario a deja lu (aucune lecture supplementaire).
 *
 * <p>🛑 Ton informatif et d'accompagnement : aucun prix, aucune remise, aucune
 * « offre », aucune urgence commerciale — et la fin d'acces mene a « Mon pass »,
 * jamais a {@code /paiement} (arbitrage n°6).
 *
 * <p>{@code nextStepLabel} (brief §9, « si disponible ») n'est pas fourni en V1 :
 * le lire exigerait de construire le Plan de chaque candidat pendant le passage
 * (decision D-27).
 */
@Component
@RequiredArgsConstructor
public class EngagementEmailComposer {

    private final EmailLinks links;

    public EmailRequest noPremiumAfter7Days(UUID userId, String email, String firstName) {
        return request(EmailType.NO_PREMIUM_AFTER_7_DAYS, userId, email, firstName,
                Map.of("appUrl", links.dashboard()),
                EmailKeys.byReference(EmailType.NO_PREMIUM_AFTER_7_DAYS, userId), userId);
    }

    /** Episode d'inactivite : la cle porte la date (Europe/Paris) de la derniere activite. */
    public EmailRequest noTraining7Days(UUID userId, String email, String firstName, LocalDate lastActivity) {
        return request(EmailType.NO_TRAINING_7_DAYS, userId, email, firstName,
                Map.of("resumeUrl", links.dashboard()),
                EmailKeys.episode(EmailType.NO_TRAINING_7_DAYS, userId, lastActivity), userId);
    }

    /** Episode : la cle porte la date de reference = max(derniere activite, debut d'acces). */
    public EmailRequest premiumInactive2Days(UUID userId, String email, String firstName, LocalDate reference) {
        return request(EmailType.PREMIUM_INACTIVE_2_DAYS, userId, email, firstName,
                Map.of("resumeUrl", links.dashboard()),
                EmailKeys.episode(EmailType.PREMIUM_INACTIVE_2_DAYS, userId, reference), userId);
    }

    public EmailRequest premiumEnding(EmailType type, UserSubscription access, String email, String firstName,
                                      Wording wording) {
        if (type != EmailType.PREMIUM_ENDING_7_DAYS && type != EmailType.PREMIUM_ENDING_2_DAYS) {
            throw new IllegalArgumentException("type de fin d'acces inattendu : " + type);
        }
        return request(type, access.getUser().getId(), email, firstName,
                Map.of("accessLabel", wording.accessLabel(),
                        "accessEndDate", EmailFormats.date(access.getEndsAt()),
                        "remainingAccessSentence", wording.remainingAccessSentence(),
                        "manageAccessUrl", links.manageAccess()),
                EmailKeys.byReference(type, access.getId()), access.getId());
    }

    public EmailRequest premiumEnded(UserSubscription access, String email, String firstName, Wording wording) {
        return request(EmailType.PREMIUM_ENDED, access.getUser().getId(), email, firstName,
                Map.of("accessLabel", wording.accessLabel(),
                        "accessEndDate", EmailFormats.date(access.getEndsAt()),
                        "remainingAccessSentence", wording.remainingAccessSentence(),
                        "dashboardUrl", links.dashboard()),
                EmailKeys.byReference(EmailType.PREMIUM_ENDED, access.getId()), access.getId());
    }

    private static EmailRequest request(EmailType type, UUID userId, String email, String firstName,
                                        Map<String, String> extra, String key, UUID reference) {
        java.util.HashMap<String, String> vars = new java.util.HashMap<>(extra);
        vars.put("firstName", EmailFormats.firstName(firstName));
        vars.put("greeting", EmailFormats.greeting(firstName));
        return new EmailRequest(type, userId, email, vars, key, reference, null, EmailRequest.Origin.SCHEDULER);
    }
}
