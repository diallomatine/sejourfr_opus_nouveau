package com.sejourfr.app.service.realtime;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * GARDE-FOU STRUCTUREL (V084, B-1) : le quota EO temps réel a deux lieux de
 * stockage (l'achat, le GRANT INTEGRAL admin) mais UNE seule autorité, et les
 * paiements ne touchent jamais une décision admin. Lu sur les sources de
 * {@code src/main/java} :
 * <ol>
 *   <li>le solde d'une décision admin n'est lu ou écrit que par
 *       {@code RealtimeQuotaService} et {@code AccessOverridePlanner} ;
 *       {@code AdminAccessOperationService} ne fait que le remettre à 0 à la
 *       supersession ;</li>
 *   <li>les deux {@code decrementRealtimeSessions} ne sont appelés que depuis
 *       {@code RealtimeQuotaService} (hors managers et repositories qui les
 *       définissent) ;</li>
 *   <li>aucun service ni contrôleur de paiement (webhooks Stripe / Apple /
 *       Google, reçus, statut) ne référence une décision admin — seule
 *       {@code CreditProration}, lecture pure pour le prix, les lit (D-31).</li>
 * </ol>
 */
class QuotaEoAutoriteUniqueTest {

    private static final Path RACINE = Path.of("src/main/java/com/sejourfr/app");

    private static final Pattern SOLDE_DECISION = Pattern.compile("RealtimeEoSessions(Granted|Remaining)\\b(\\([^)]*\\))?");
    private static final Pattern DEBIT = Pattern.compile("\\.decrementRealtimeSessions\\(");
    private static final Pattern DECISION_ADMIN = Pattern.compile("AccessOverride|AdminAccessOperation|accessOverride");

    private static Map<String, String> sources() throws IOException {
        Map<String, String> out = new TreeMap<>();
        try (Stream<Path> fichiers = Files.walk(RACINE)) {
            for (Path p : fichiers.filter(f -> f.toString().endsWith(".java")).toList()) {
                out.put(RACINE.relativize(p).toString().replace('\\', '/'), Files.readString(p, StandardCharsets.UTF_8));
            }
        }
        assertThat(out).as("sources introuvables depuis %s", RACINE.toAbsolutePath()).isNotEmpty();
        return out;
    }

    @Test
    @DisplayName("Le solde EO d'une décision admin n'est lu que par RealtimeQuotaService et AccessOverridePlanner")
    void soldeDecisionLuParLAutoriteSeulement() throws IOException {
        Set<String> autorises = Set.of("service/realtime/RealtimeQuotaService.java",
                "service/access/AccessOverridePlanner.java");
        sources().forEach((fichier, code) -> {
            if (!code.contains("AccessOverride") || autorises.contains(fichier)) return;
            Matcher m = SOLDE_DECISION.matcher(code);
            while (m.find()) {
                // Seul usage toléré hors autorité : la remise à 0 d'une ligne remplacée.
                assertThat(fichier + " : " + m.group())
                        .as("solde EO d'une décision admin manipulé hors de l'autorité")
                        .isEqualTo("service/adminuser/AdminAccessOperationService.java : RealtimeEoSessionsRemaining(0)");
            }
        });
    }

    @Test
    @DisplayName("Les deux débits de session EO ne sont appelés que par RealtimeQuotaService")
    void unSeulPointDeDebit() throws IOException {
        sources().forEach((fichier, code) -> {
            if (fichier.startsWith("manager/") || fichier.startsWith("repository/")) return;
            if (DEBIT.matcher(code).find()) {
                assertThat(fichier).as("débit de session EO hors de l'autorité du quota")
                        .isEqualTo("service/realtime/RealtimeQuotaService.java");
            }
        });
    }

    @Test
    @DisplayName("Aucun service ni contrôleur de paiement ne référence une décision admin (webhooks compris)")
    void paiementsSansDecisionAdmin() throws IOException {
        Map<String, String> sources = sources();
        List<String> paiements = sources.keySet().stream()
                .filter(f -> (f.startsWith("service/billing/") && !f.equals("service/billing/CreditProration.java"))
                        || List.of("service/BillingService.java", "service/StoreWebhookService.java",
                        "service/ReceiptVerificationService.java", "controller/BillingController.java",
                        "controller/BillingWebhookController.java").contains(f))
                .toList();
        assertThat(paiements).contains("service/billing/StripeSubscriptionService.java",
                "service/billing/AppleSubscriptionService.java", "service/billing/GoogleSubscriptionService.java",
                "service/billing/OneTimeAccessService.java", "service/BillingService.java");
        for (String f : paiements) {
            assertThat(DECISION_ADMIN.matcher(sources.get(f)).find())
                    .as("%s référence une décision admin : un paiement ne doit jamais en lire ni en écrire", f)
                    .isFalse();
        }
    }
}
