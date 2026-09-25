package com.sejourfr.app.manager;

import com.sejourfr.app.enums.AnalyticsGrain;
import com.sejourfr.app.repository.AnalyticsReadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Locale;

/**
 * Seule couche autorisee a toucher {@link AnalyticsReadRepository}. Lecture
 * seule : l'audience s'observe, elle ne s'ecrit pas ici.
 *
 * <p>Les filtres facultatifs sont normalises une seule fois : une chaine vide
 * vaut « pas de filtre », jamais « la valeur vide ». Les comptes internes sont
 * exclus EN SQL par {@code users.is_internal} (V074, seule autorite).
 */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AnalyticsReadManager {

    private final AnalyticsReadRepository repository;

    public List<AnalyticsReadRepository.VisitorCell> visitorCells(
            Instant from, Instant to, AnalyticsGrain grain, Filtres filtres) {
        return repository.visitorCells(from, to, grain.getSqlUnit(),
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.UserCell> userCells(
            Instant from, Instant to, AnalyticsGrain grain, Filtres filtres) {
        return repository.userCells(from, to, grain.getSqlUnit(),
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.DiagStepCell> diagnosticSteps(
            Instant from, Instant to, Filtres filtres) {
        return repository.diagnosticSteps(from, to,
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.CtaCell> ctaCells(
            Instant from, Instant to, Filtres filtres) {
        return repository.ctaCells(from, to,
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.PathCell> topPaths(
            Instant from, Instant to, Filtres filtres) {
        return repository.topPaths(from, to,
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.TriggerCell> registrationTriggers(
            Instant from, Instant to, Filtres filtres) {
        return repository.registrationTriggers(from, to,
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public long totalUsers() {
        return repository.totalUsers();
    }

    /**
     * Les quatre filtres facultatifs de l'ecran. {@code null} = pas de filtre —
     * distinct d'une valeur vide, qui ne filtrerait rien tout en pretendant
     * filtrer.
     */
    public record Filtres(String source, String country, String device, String platform) {

        public static final Filtres AUCUN = new Filtres(null, null, null, null);

        public Filtres {
            // La provenance est normalisee en minuscules (allowlist TrafficSource),
            // les trois autres en majuscules (codes ISO et enums).
            source = vide(source) == null ? null : source.trim().toLowerCase(Locale.ROOT);
            country = vide(country) == null ? null : country.trim().toUpperCase(Locale.ROOT);
            device = vide(device) == null ? null : device.trim().toUpperCase(Locale.ROOT);
            platform = vide(platform) == null ? null : platform.trim().toUpperCase(Locale.ROOT);
        }

        private static String vide(String raw) {
            if (raw == null) return null;
            String trimmed = raw.trim();
            return trimmed.isEmpty() ? null : trimmed;
        }

        /** Cle stable pour le cache court : deux memes filtres, une meme cle. */
        public String cle() {
            return String.join("|",
                    String.valueOf(source), String.valueOf(country),
                    String.valueOf(device), String.valueOf(platform));
        }
    }
}
