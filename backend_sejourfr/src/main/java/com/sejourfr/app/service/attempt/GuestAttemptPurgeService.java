package com.sejourfr.app.service.attempt;

import com.sejourfr.app.manager.AttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Suppression d'<b>un lot</b> d'attempts invités, dans sa propre transaction.
 * Appelé en boucle par {@link GuestAttemptPurgeJob}, qui porte le drapeau, le
 * cutoff et la borne de lot — et qui est un bean <b>distinct</b> exprès : une
 * méthode transactionnelle appelée depuis la même classe court-circuite le
 * proxy Spring, et la borne de lot n'aurait alors plus aucun effet réel.
 *
 * <p>Propagation {@code REQUIRED} (défaut) et non {@link Propagation#REQUIRES_NEW} :
 * la passe qui boucle n'est <b>volontairement pas</b> transactionnelle, donc
 * chaque lot ouvre et commite bien la sienne — un lot commité le reste même si
 * le suivant échoue. Rien n'est rejoué : la passe suivante reprendra les lignes
 * restantes.
 *
 * <p>🛑 Le garde-fou {@code user IS NULL} est posé <b>deux fois</b> (sélection
 * des ids puis {@code DELETE}) : un attempt rattaché à un compte est
 * l'historique du candidat et la source de vérité du freemium, aucune passe de
 * purge ne peut l'emporter. Les tables filles partent en cascade base
 * ({@code attempt_questions} → {@code answers}, V006).
 */
@Service
@RequiredArgsConstructor
public class GuestAttemptPurgeService {

    private final AttemptManager attemptManager;

    /**
     * @param cutoff    instant avant lequel un attempt invité est purgeable
     *                  (comparé à {@code started_at}).
     * @param batchSize plafond de lignes supprimées par cet appel.
     * @return nombre d'attempts invités supprimés.
     */
    @Transactional
    public int purgeBatch(Instant cutoff, int batchSize) {
        List<UUID> ids = attemptManager.findGuestAttemptIdsStartedBefore(cutoff, batchSize);
        if (ids.isEmpty()) return 0;
        return attemptManager.deleteGuestAttemptsByIds(ids);
    }
}
