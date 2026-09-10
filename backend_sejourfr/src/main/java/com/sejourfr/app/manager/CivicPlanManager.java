package com.sejourfr.app.manager;

import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.repository.CivicPlanRepository;
import com.sejourfr.app.service.plancivique.CivicReponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Seule couche autorisee a toucher {@link CivicPlanRepository}. */
@Component
@RequiredArgsConstructor
public class CivicPlanManager {

    private final CivicPlanRepository repository;

    /**
     * Les reponses civiques d'un candidat, deja mises en forme pour le repli
     * Leitner. L'ordre de la requete est conserve : c'est lui qui fait la boite.
     */
    public List<CivicReponse> reponses(UUID userId) {
        return repository.reponsesCiviques(userId).stream()
                .map(row -> new CivicReponse(
                        (UUID) row[0],
                        (UUID) row[1],
                        Boolean.TRUE.equals(row[2]),
                        instant(row[3])))
                .toList();
    }

    /** Par theme : {@code [total actif, tagues]}. */
    public Map<UUID, long[]> taggageParTheme() {
        Map<UUID, long[]> out = new LinkedHashMap<>();
        for (Object[] row : repository.taggageParTheme()) {
            out.put((UUID) row[0], new long[]{
                    ((Number) row[1]).longValue(), ((Number) row[2]).longValue()});
        }
        return out;
    }

    /** Questions jouables par notion, pour CETTE mention. */
    public Map<UUID, Long> questionsParNotion(Difficulty mention) {
        return compter(repository.questionsParNotion(mention.name()));
    }

    /** Questions jouables par theme, pour CETTE mention. */
    public Map<UUID, Long> questionsParTheme(Difficulty mention) {
        return compter(repository.questionsParTheme(mention.name()));
    }

    private static Map<UUID, Long> compter(List<Object[]> rows) {
        Map<UUID, Long> out = new LinkedHashMap<>();
        for (Object[] row : rows) {
            out.put((UUID) row[0], ((Number) row[1]).longValue());
        }
        return out;
    }


    /**
     * Le tirage d'une serie ciblee. L'ordre du repository porte l'intention du
     * plan (rate d'abord, jamais vu ensuite) : ne pas le retrier ici.
     */
    public List<UUID> tirageSerieCiblee(
            UUID userId, Difficulty mention, UUID notionId, UUID themeId, int taille) {
        return repository.tirageSerieCiblee(
                userId, mention.name(), notionId, themeId, taille);
    }

    /** Postgres rend un {@code Timestamp} sur une projection native. */
    private static Instant instant(Object value) {
        if (value == null) return null;
        if (value instanceof Instant instant) return instant;
        if (value instanceof Timestamp timestamp) return timestamp.toInstant();
        return null;
    }
}
