package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/**
 * Configuration des providers OAuth/OIDC externes (Google + Apple).
 * <p>
 * Lue depuis application.yaml (cle {@code sejourfr.oauth}).
 * <p>
 * <b>Audiences</b> = liste de client IDs autorises a appeler /api/auth/google
 * ou /api/auth/apple. Le backend extrait le claim {@code aud} de l'ID token
 * et verifie qu'il appartient a cette liste — sinon 401. Permet d'autoriser
 * en meme temps le client web GIS, le client iOS et le client Android sur
 * un seul endpoint.
 * <p>
 * Quand la liste est vide pour un provider, l'endpoint correspondant
 * renvoie 503 ("provider non configure").
 */
@ConfigurationProperties(prefix = "sejourfr.oauth")
public class SocialAuthProperties {

    private final Google google = new Google();
    private final Apple apple = new Apple();

    public Google getGoogle() { return google; }
    public Apple getApple() { return apple; }

    public static class Google {
        /**
         * Client IDs Google autorises (web, iOS, Android). Format :
         * "xxx-xxx.apps.googleusercontent.com". Sur Android, c'est le client
         * web (server client id) qui finit dans le token, pas le client
         * Android lui-meme.
         */
        private List<String> audiences = List.of();

        public List<String> getAudiences() { return audiences; }
        public void setAudiences(List<String> v) { this.audiences = v; }

        public boolean isConfigured() { return !audiences.isEmpty(); }
    }

    public static class Apple {
        /**
         * Audiences Apple autorisees :
         * - Bundle ID iOS pour l'app native ("com.sejourfr.app")
         * - Services ID configure dans Apple Developer pour le web ("fr.sejourfr.web") — non utilise pour l'instant
         */
        private List<String> audiences = List.of();

        /**
         * Apple Team ID (10 caracteres). Pas utilise pour la verification du
         * JWT (on lit l'audience), mais conserve pour generer le client_secret
         * cote serveur si on ajoute un jour Apple Sign In via web (necessite
         * de signer un JWT avec la cle .p8 Apple).
         */
        private String teamId = "";

        public List<String> getAudiences() { return audiences; }
        public void setAudiences(List<String> v) { this.audiences = v; }

        public String getTeamId() { return teamId; }
        public void setTeamId(String v) { this.teamId = v; }

        public boolean isConfigured() { return !audiences.isEmpty(); }
    }
}
