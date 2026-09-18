package com.sejourfr.app.manager;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.FreeEntitlementUsage;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.FreeEntitlementCode;
import com.sejourfr.app.repository.FreeEntitlementUsageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Le <b>ledger des gratuites nominatives</b> : ce qui a deja ete offert, et a
 * quelle date.
 *
 * <p>⚠️ <b>Aucun appelant en P2</b>, et c'est voulu : la bascule des quatre
 * implementations ad hoc de « premiere fois gratuite » est en P4 (D-17). Ce
 * manager existe des maintenant parce que la table existe, et qu'une table sans
 * couche d'acces finit lue depuis un service.
 */
@Component
@RequiredArgsConstructor
public class FreeEntitlementUsageManager {

    private final FreeEntitlementUsageRepository repository;

    public boolean estConsomme(UUID userId, FreeEntitlementCode code) {
        return repository.existsByUserIdAndCode(userId, code);
    }

    public Optional<FreeEntitlementUsage> find(UUID userId, FreeEntitlementCode code) {
        return repository.findByUserIdAndCode(userId, code);
    }

    public List<FreeEntitlementUsage> findAll(UUID userId) {
        return repository.findAllByUserId(userId);
    }

    /**
     * Consomme la gratuite, <b>au plus une fois dans la vie du candidat</b>.
     *
     * <p>🛑 <b>A appeler a la REMISE DE L'ANALYSE</b>, jamais au demarrage de
     * l'examen ni sur la seule cloture de la session : un abandon, une
     * expiration ou un echec du correcteur doivent laisser le freebie intact
     * (D-17).
     *
     * <p><b>Idempotent, et il avale la violation d'unicite plutot que de la
     * propager</b> — patron de {@code ProcessedExternalEventManager
     * .tryMarkProcessed}, pour la meme raison : entre le {@code exists} et
     * l'insertion, un second envoi peut passer, et l'appelant de cette methode
     * est une <b>remise d'analyse deja payee</b>. La faire echouer ferait
     * perdre au candidat une analyse qu'il a recue, pour un doublon que la base
     * a justement empeche. Le booleen dit lequel des deux appels a ecrit.
     *
     * @return {@code true} si <b>cet</b> appel a consomme la gratuite,
     *         {@code false} si elle l'etait deja — par un appel precedent ou par
     *         un concurrent.
     */
    public boolean consommer(User user, FreeEntitlementCode code, Attempt source) {
        if (repository.existsByUserIdAndCode(user.getId(), code)) return false;
        FreeEntitlementUsage usage = new FreeEntitlementUsage();
        usage.setUser(user);
        usage.setCode(code);
        usage.setSourceAttempt(source);
        try {
            repository.save(usage);
            return true;
        } catch (DataIntegrityViolationException dejaConsommee) {
            return false;
        }
    }

    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }
}
