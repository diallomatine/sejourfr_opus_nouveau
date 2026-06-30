package com.sejourfr.app.support;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.springframework.test.context.DynamicPropertyRegistry;

import java.io.IOException;

/**
 * Démarre <b>un seul</b> Postgres embarqué (Zonky) pour toute la JVM de test et
 * le réutilise dans chaque classe d'intégration. Pas de Docker : Zonky lance un
 * vrai binaire {@code postgres} extrait du classpath (binaire arm64 macOS en
 * local, linux-amd64 en CI — cf. {@code pom.xml}).
 *
 * <p>Le serveur n'est jamais arrêté explicitement : il s'éteint avec la JVM. Le
 * démarrer une fois (~1-2 s) puis le partager évite de payer le coût à chaque
 * classe. Chaque contexte Spring applique les migrations Flyway sur la même
 * instance — les tests s'isolent via {@code @Transactional} (rollback) ou en
 * nettoyant leurs propres données.</p>
 */
public final class EmbeddedPostgresHolder {

    private static volatile EmbeddedPostgres instance;

    private EmbeddedPostgresHolder() {
    }

    private static EmbeddedPostgres instance() {
        EmbeddedPostgres local = instance;
        if (local == null) {
            synchronized (EmbeddedPostgresHolder.class) {
                local = instance;
                if (local == null) {
                    try {
                        local = EmbeddedPostgres.builder().start();
                    } catch (IOException e) {
                        throw new IllegalStateException(
                                "Impossible de démarrer le Postgres embarqué de test", e);
                    }
                    instance = local;
                }
            }
        }
        return local;
    }

    /**
     * Branche le datasource Spring sur l'instance embarquée. Appelé depuis un
     * {@code @DynamicPropertySource}. Auth « trust » locale : le mot de passe
     * est ignoré par le serveur, on en pose un non-vide par propreté.
     */
    public static void registerDatasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgres pg = instance();
        registry.add("spring.datasource.url", () -> pg.getJdbcUrl("postgres", "postgres"));
        registry.add("spring.datasource.username", () -> "postgres");
        registry.add("spring.datasource.password", () -> "postgres");
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
    }
}
