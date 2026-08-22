package com.sejourfr.app.manager;

import com.sejourfr.app.enums.AnalyticsGrain;
import com.sejourfr.app.repository.AnalyticsReadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Locale;

/**
 * Seule couche autorisee a toucher {@link AnalyticsReadRepository}. Lecture
 * seule : l'audience s'observe, elle ne s'ecrit pas ici.
 *
 * <p>Le manager porte deux garde-fous que le SQL ne peut pas tenir :
 * <ul>
 *   <li>la liste d'exclusion n'est <b>jamais vide</b> — un {@code NOT IN ()} est
 *       une erreur de syntaxe Postgres, et un utilisateur qui viderait la
 *       configuration ferait planter l'ecran au lieu de simplement ne rien
 *       exclure ;</li>
 *   <li>les filtres facultatifs sont normalises une seule fois : une chaine
 *       vide vaut « pas de filtre », jamais « la valeur vide ».</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AnalyticsReadManager {

    /**
     * Valeur sentinelle quand aucun compte n'est exclu. Aucune adresse ne peut
     * valoir la chaine vide (contrainte d'unicite + validation d'e-mail), donc
     * elle n'exclut rien tout en gardant le {@code NOT IN} syntaxiquement
     * valide.
     */
    private static final List<String> AUCUNE_EXCLUSION = List.of("");

    private final AnalyticsReadRepository repository;

    public List<AnalyticsReadRepository.VisitorCell> visitorCells(
            Instant from, Instant to, AnalyticsGrain grain, Filtres filtres) {
        return repository.visitorCells(from, to, grain.getSqlUnit(),
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.UserCell> userCells(
            Instant from, Instant to, AnalyticsGrain grain,
            Collection<String> excluded, Filtres filtres) {
        return repository.userCells(from, to, grain.getSqlUnit(), exclusions(excluded),
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.DiagStepCell> diagnosticSteps(
            Instant from, Instant to, Collection<String> excluded, Filtres filtres) {
        return repository.diagnosticSteps(from, to, exclusions(excluded),
                filtres.source(), filtres.country(), filtres.device(), filtres.platform());
    }

    public List<AnalyticsReadRepository.CtaCell> ctaCells(
            Instant from, Instant to, Collection<String> excluded, Filtres filtres) {
        return repository.ctaCells(from, to, exclusions(excluded),
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

    public long totalUsers(Collection<String> excluded) {
        return repository.totalUsers(exclusions(excluded));
    }

    private static Collection<String> exclusions(Collection<String> excluded) {
        if (excluded == null || excluded.isEmpty()) return AUCUNE_EXCLUSION;
        List<String> normalises = excluded.stream()
                .filter(mail -> mail != null && !mail.isBlank())
                .map(mail -> mail.trim().toLowerCase(Locale.ROOT))
                .distinct()
                .toList();
        return normalises.isEmpty() ? AUCUNE_EXCLUSION : normalises;
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
