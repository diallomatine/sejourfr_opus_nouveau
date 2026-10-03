package com.sejourfr.app.manager;

import com.sejourfr.app.repository.ActivityReadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Seule couche autorisee a toucher {@link ActivityReadRepository}. Lecture seule :
 * trois requetes constantes pour une periode, une pour le direct.
 */
@Component
@RequiredArgsConstructor
public class ActivityReadManager {

    private final ActivityReadRepository repository;

    /**
     * Parametres deja resolus par le service. Les bornes {@code *Since} sont le
     * premier jour mesure de chaque lecture (D117) ; une lecture non mesuree
     * recoit une borne qui ne selectionne rien et son resultat est jete.
     */
    public record Requete(LocalDate prevFrom, LocalDate from, LocalDate to, LocalDate activeSince,
                          LocalDate loginsSince, LocalDate webSince, LocalDate appSince, int screenTop,
                          boolean includeInternal) {
    }

    /** Les trois lectures d'une periode, dans une seule transaction (instantane coherent). */
    public record Lectures(List<ActivityReadRepository.ActiveCell> active,
                           List<ActivityReadRepository.LoginCell> logins,
                           List<ActivityReadRepository.ScreenCell> screens) {
    }

    @Transactional(readOnly = true)
    public Lectures lire(Requete q) {
        Instant endExclusive = paris(q.to().plusDays(1));
        return new Lectures(
                repository.active(q.prevFrom(), q.from(), q.activeSince(), q.to(), q.includeInternal()),
                repository.logins(paris(q.prevFrom()), paris(q.from()), paris(q.loginsSince()), endExclusive,
                        q.includeInternal()),
                repository.screens(paris(q.webSince()), paris(q.appSince()), endExclusive, q.screenTop(),
                        q.includeInternal()));
    }

    @Transactional(readOnly = true)
    public List<ActivityReadRepository.LiveCell> live(Instant since, LocalDate minDay, boolean includeInternal) {
        return repository.live(since, minDay, includeInternal);
    }

    private static Instant paris(LocalDate day) {
        return day.atStartOfDay(com.sejourfr.app.util.FenetreMesure.PARIS).toInstant();
    }
}
