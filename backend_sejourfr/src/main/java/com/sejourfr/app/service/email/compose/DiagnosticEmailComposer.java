package com.sejourfr.app.service.email.compose;

import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.dto.LearningPlanPriorityDto;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.service.LearningPlanService;
import com.sejourfr.app.service.email.EmailErrors;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailKeys;
import com.sejourfr.app.service.email.EmailLinks;
import com.sejourfr.app.service.email.EmailRequest;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * {@code DIAGNOSTIC_PLAN_READY} : « votre plan est pret », avec au plus les trois
 * premieres priorites SERVIES par le Plan du module (pas le plan complet).
 *
 * <p>🛑 Un Plan provisoire a souvent moins de trois priorites (« peu de
 * priorites, toutes vraies, est le bon resultat ») : {@code priority2} et
 * {@code priority3} restent VIDES, jamais comblees. Si le Plan ne se lit pas,
 * le mail part sans priorite plutot que d'en inventer.
 *
 * <p>Les titres de priorite sont lisibles par un compte gratuit (« LISIBLE mais
 * INEXECUTABLE », docs/regles/freemium.md) : les citer ne devoile rien.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DiagnosticEmailComposer {

    static final int MAX_PRIORITIES = 3;

    private final AccountEmailComposer accounts;
    private final LearningPlanService learningPlanService;
    private final CivicPlanService civicPlanService;
    private final EmailLinks links;

    /**
     * 🛑 En LECTURE SEULE, et c'est un correctif, pas une precaution : lire le
     * Plan TCF epingle sa premiere place ({@code plan_pinned_priorities}). Le
     * mail compose sur l'executor pendant que le candidat ouvre son Plan : deux
     * epinglages concurrents violaient la cle primaire et faisaient echouer la
     * requete du CANDIDAT. Ici, rien n'est ecrit — la transaction est en
     * lecture seule jusqu'a la connexion, et une ecriture tentee se solde par
     * un mail sans priorite, jamais par une erreur ailleurs.
     */
    @Transactional(readOnly = true)
    public Optional<EmailRequest> planReady(UUID userId, Module module, UUID diagnosticId,
                                            EmailRequest.Origin origin) {
        return accounts.activeUser(userId).map(user -> {
            List<String> priorities = priorities(userId, module);
            Map<String, String> vars = new HashMap<>();
            vars.put("firstName", EmailFormats.firstName(user.getFirstName()));
            vars.put("greeting", EmailFormats.greeting(user.getFirstName()));
            vars.put("diagnosticType", module == Module.TCF ? "TCF" : "civique");
            vars.put("planUrl", links.plan(module));
            vars.put("prioritiesIntro", priorities.isEmpty() ? "" : "Vos premières priorités :");
            for (int i = 0; i < MAX_PRIORITIES; i++) {
                vars.put("priority" + (i + 1), i < priorities.size() ? priorities.get(i) : "");
            }
            return new EmailRequest(EmailType.DIAGNOSTIC_PLAN_READY, user.getId(), user.getEmail(), vars,
                    EmailKeys.diagnosticPlanReady(user.getId(), module), diagnosticId, null, origin);
        });
    }

    List<String> priorities(UUID userId, Module module) {
        try {
            List<String> titles = module == Module.TCF ? tcf(userId) : civique(userId);
            return titles.stream().filter(Objects::nonNull).map(String::trim)
                    .filter(t -> !t.isEmpty()).limit(MAX_PRIORITIES).toList();
        } catch (RuntimeException e) {
            log.warn("Priorites du Plan {} illisibles pour le mail (user={}) : {}", module, userId,
                    EmailErrors.sanitize(e));
            return List.of();
        }
    }

    private List<String> tcf(UUID userId) {
        LearningPlanDto plan = learningPlanService.get(userId);
        List<String> titles = new ArrayList<>();
        if (plan.currentPriority() != null) {
            titles.add(plan.currentPriority().title());
        }
        if (plan.nextPriorities() != null) {
            plan.nextPriorities().stream().map(LearningPlanPriorityDto::title).forEach(titles::add);
        }
        return titles;
    }

    private List<String> civique(UUID userId) {
        CivicPlanDto plan = civicPlanService.plan(userId);
        if (plan.prioritesVisibles() == null) {
            return List.of();
        }
        return plan.prioritesVisibles().stream().map(CivicPlanDto.Cible::label).toList();
    }
}
