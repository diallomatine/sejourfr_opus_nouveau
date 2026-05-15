package com.sejourfr.app.config;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

/**
 * Charge un fichier {@code .env} situe a cote du process (CWD) en posant
 * chaque entree en {@link System#setProperty}, de sorte que les placeholders
 * {@code ${VAR}} d'{@code application.yaml} la voient au boot.
 *
 * Appele depuis {@code main()} AVANT {@code SpringApplication.run(...)}.
 *
 * Choix : pas d'EnvironmentPostProcessor (deprecie et casse en Spring Boot 4),
 * pas de dependance externe (spring-dotenv 4.0 utilise encore l'ancien
 * spring.factories qui n'est plus charge). Implementation minimale, robuste.
 *
 * Format dotenv standard :
 *   - {@code KEY=VALUE}
 *   - {@code export KEY=VALUE} (le prefixe est tolere pour rester compatible
 *     avec un fichier sourcable directement via bash)
 *   - Lignes vides et commentaires {@code #} ignores
 *   - Guillemets autour de la valeur sont retires
 *
 * Une variable deja presente en System property ou variable d'env (passee
 * par le container en prod) n'est PAS ecrasee : le .env ne sert que de
 * fallback en dev.
 */
public final class DotenvLoader {

    private DotenvLoader() {}

    public static void loadIfPresent() {
        Path envPath = resolveEnvPath();
        if (envPath == null) return;

        int loaded = 0;
        int skipped = 0;
        try {
            List<String> lines = Files.readAllLines(envPath);
            for (String raw : lines) {
                String line = raw.trim();
                if (line.isEmpty() || line.startsWith("#")) continue;
                if (line.startsWith("export ")) line = line.substring(7).trim();
                int eq = line.indexOf('=');
                if (eq <= 0) continue;
                String key = line.substring(0, eq).trim();
                String value = line.substring(eq + 1).trim();
                if ((value.startsWith("\"") && value.endsWith("\""))
                        || (value.startsWith("'") && value.endsWith("'"))) {
                    value = value.substring(1, value.length() - 1);
                }
                if (System.getProperty(key) != null || System.getenv(key) != null) {
                    skipped++;
                    continue;
                }
                System.setProperty(key, value);
                loaded++;
            }
        } catch (IOException e) {
            System.err.println("[DotenvLoader] echec lecture de " + envPath + " : " + e.getMessage());
            return;
        }
        System.out.println("[DotenvLoader] " + envPath + " : " + loaded + " variables chargees"
            + (skipped > 0 ? " (" + skipped + " skippees, deja definies dans env/system)" : ""));
    }

    /** Cherche .env dans le CWD puis dans backend_sejourfr/.env (cas mvnw lance depuis racine repo). */
    private static Path resolveEnvPath() {
        List<Path> candidates = List.of(
            Paths.get(".env").toAbsolutePath(),
            Paths.get("backend_sejourfr", ".env").toAbsolutePath()
        );
        for (Path candidate : candidates) {
            if (Files.isRegularFile(candidate)) {
                return candidate;
            }
        }
        return null;
    }
}
