package com.sejourfr.app.support;

import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;

/**
 * Base des tests d'intégration : contexte Spring complet (profil {@code test}),
 * Postgres embarqué partagé (Flyway applique les 200+ migrations réelles), et
 * {@code MockMvc} prêt pour les tests de controllers/droits.
 *
 * <p>Le contexte est mis en cache par Spring entre les classes qui partagent la
 * même configuration → une seule fois le coût du démarrage + des migrations.</p>
 *
 * <p>Pour seeder/authentifier, injecter {@link TestData} et {@link AuthTestSupport}
 * (beans fournis par {@link TestSupportConfig}).</p>
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import(TestSupportConfig.class)
@Transactional   // rollback après chaque test → isolation, base toujours propre
public abstract class AbstractIntegrationTest {

    @DynamicPropertySource
    static void datasourceProperties(DynamicPropertyRegistry registry) {
        EmbeddedPostgresHolder.registerDatasource(registry);
    }
}
