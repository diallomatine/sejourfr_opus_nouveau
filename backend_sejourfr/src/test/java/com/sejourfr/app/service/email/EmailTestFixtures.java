package com.sejourfr.app.service.email;

import com.sejourfr.app.config.EmailProperties;
import com.sejourfr.app.enums.EmailType;

import java.util.List;
import java.util.Map;

/** Configurations partagees par les tests unitaires du systeme d'emails. */
final class EmailTestFixtures {

    private EmailTestFixtures() {
    }

    static EmailAutomationConfig config(int dailyCap, List<Integer> delays, int maxDeferred) {
        EmailAutomationConfig v1 = EmailAutomationConfigLoader.load(1);
        return new EmailAutomationConfig(1, new EmailAutomationConfig.Engagement(dailyCap),
                new EmailAutomationConfig.Retry(delays, maxDeferred, 24, 60),
                v1.batchSize(), v1.retentionMonths(), v1.scenarios());
    }

    static EmailProperties properties() {
        EmailProperties p = new EmailProperties();
        p.getUnsubscribe().setCurrentKeyVersion(2);
        p.getUnsubscribe().setKeys(new java.util.LinkedHashMap<>(Map.of(
                1, "cle-de-test-version-1", 2, "cle-de-test-version-2")));
        EmailProperties.Template welcome = new EmailProperties.Template();
        welcome.setSubject("Bienvenue sur SejourFR");
        welcome.setPreheader("Votre compte est créé");
        welcome.setLocalTemplate("email/welcome");
        EmailProperties.Template plan = new EmailProperties.Template();
        plan.setSubject("Votre plan d'entraînement est prêt");
        plan.setPreheader("Diagnostic {{diagnosticType}} terminé");
        plan.setLocalTemplate("email/diagnostic-plan-ready");
        p.getTemplates().put(EmailType.WELCOME, welcome);
        p.getTemplates().put(EmailType.DIAGNOSTIC_PLAN_READY, plan);
        return p;
    }
}
