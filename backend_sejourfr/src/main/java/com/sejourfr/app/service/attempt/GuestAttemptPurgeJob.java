package com.sejourfr.app.service.attempt;

import com.sejourfr.app.config.GuestAttemptPurgeProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;

/**
 * Purge des attempts <b>invités</b> ({@code user_id IS NULL}) au-delà d'un
 * certain âge — garde-fou contre l'inflation de la table {@code attempts} par
 * la démo publique, dont le quota a été retiré le 2026-05-17.
 *
 * <p>🛑 <b>LIVRÉ ÉTEINT</b> ({@code sejourfr.guest-attempt-purge.enabled=false},
 * même valeur dans le POJO et dans le YAML). À {@code false} la passe sort
 * immédiatement : <b>aucune ligne supprimée, aucun effet observable</b>. Même
 * patron que {@code production-evaluation.fluidite.enabled} et
 * {@code seconde-passe.enabled} — un interrupteur, pas du code mort.
 *
 * <p>🛑 <b>PRÉREQUIS AVANT D'ACTIVER.</b> Ces lignes <b>sont</b> la mesure
 * « combien de visiteurs se testent avant de créer un compte » : la
 * {@code client_ip} d'un attempt invité est posée exprès pour ça. Les purger
 * détruit la mesure. Il faut donc d'abord un <b>compteur agrégé</b> des
 * passages invités — une ligne par (surface, jour), sur le patron de la table
 * {@code page_views} (V020) : {@code INSERT … ON CONFLICT DO UPDATE}, borné par
 * construction, sans rien de personnel. Tant que ce compteur n'existe pas, ne
 * pas activer cette purge.
 *
 * <h2>Choix de conception</h2>
 * <ul>
 *   <li><b>Fréquence</b> : cron configurable, par défaut toutes les 30 min —
 *       deux fois plus fin que la rétention, donc un attempt invité vit au plus
 *       « rétention + 30 min ». Plus fin ne servirait à rien (il s'agit de
 *       borner une table, pas de tenir une échéance), moins fin laisserait des
 *       pics s'accumuler.</li>
 *   <li><b>Borne de lot</b> : {@code batch-size} attempts par passe, en une
 *       transaction par lot, et la passe boucle tant qu'un lot est plein. On ne
 *       supprime jamais 100 000 lignes dans une seule transaction : la cascade
 *       base ({@code attempt_questions} → {@code answers}) multiplie déjà le
 *       volume par 10 à 25, et un DELETE de cette taille tiendrait des verrous
 *       le temps d'une requête de production.</li>
 *   <li><b>Transaction</b> : une <b>par lot</b> (portée par
 *       {@link GuestAttemptPurgeService}), jamais sur la passe entière — cette
 *       méthode-ci n'est délibérément pas transactionnelle. Un lot commité
 *       reste commité même si le suivant échoue, et rien ne se rejoue à
 *       l'infini.</li>
 *   <li><b>Âge compté sur {@code started_at}</b>, jamais sur
 *       {@code finished_at} : un attempt invité abandonné en cours de route n'a
 *       pas de fin, il s'accumulerait éternellement.</li>
 *   <li><b>Index</b> : le prédicat est exactement celui que couvre l'index
 *       partiel {@code idx_attempts_demo_quota} (V006,
 *       {@code WHERE user_id IS NULL}). Aucun index à créer, aucune migration.</li>
 *   <li><b>Cascade base, pas de suppression manuelle</b> : les tables filles
 *       partent par les FK {@code ON DELETE CASCADE} de V006.</li>
 * </ul>
 *
 * <h2>Garde-fou non négociable</h2>
 * Un attempt rattaché à un compte n'est <b>jamais</b> touché : c'est
 * l'historique du candidat et la source de vérité du freemium. La condition
 * {@code user IS NULL} est posée <b>deux fois</b> — à la sélection des ids et
 * de nouveau dans le {@code DELETE} (cf.
 * {@code AttemptRepository.deleteGuestAttemptsByIds}) — pour qu'une liste d'ids
 * fausse ne puisse pas emporter un compte.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class GuestAttemptPurgeJob {

    private final GuestAttemptPurgeService purgeService;
    private final GuestAttemptPurgeProperties properties;

    /**
     * Passe de purge. Cron piloté par
     * {@code sejourfr.guest-attempt-purge.cron}.
     *
     * @return nombre d'attempts invités supprimés (0 quand le drapeau est
     *         éteint, ce qui est le cas par défaut).
     */
    @Scheduled(cron = "${sejourfr.guest-attempt-purge.cron:0 0/30 * * * *}")
    public int purgeExpiredGuestAttempts() {
        if (!properties.isEnabled()) {
            return 0; // interrupteur éteint : aucune ligne supprimée
        }
        int batchSize = properties.getBatchSize();
        if (batchSize <= 0) {
            log.warn("Purge des attempts invités activée avec batch-size={} : passe ignorée.", batchSize);
            return 0;
        }
        Instant cutoff = Instant.now().minus(properties.getRetention());

        int total = 0;
        int deleted;
        do {
            deleted = purgeService.purgeBatch(cutoff, batchSize);
            total += deleted;
        } while (deleted == batchSize);

        if (total > 0) {
            log.info("Attempts invités purgés : {} (démarrés avant {})", total, cutoff);
        }
        return total;
    }
}
