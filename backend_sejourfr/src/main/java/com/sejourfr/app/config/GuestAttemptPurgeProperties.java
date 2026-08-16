package com.sejourfr.app.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Purge des attempts <b>invités</b> ({@code user_id IS NULL}) — cf.
 * {@code service.attempt.GuestAttemptPurgeJob}.
 *
 * <p><b>Livrée ÉTEINTE</b> ({@code enabled = false} ici comme dans le YAML,
 * même précédent que {@code sejourfr.production-evaluation.fluidite.enabled} et
 * {@code seconde-passe.enabled}). Ce n'est pas du code mort : c'est un
 * interrupteur, prêt à servir le jour où le prérequis ci-dessous est en place.
 *
 * <p><b>PRÉREQUIS AVANT D'ACTIVER — ne pas passer {@code enabled} à
 * {@code true} sans lui.</b> Les lignes {@code attempts} invitées portent une
 * {@code client_ip} posée exprès : elles SONT la mesure « combien de visiteurs
 * se testent avant de créer un compte ». Les supprimer détruit cette mesure.
 * Il faut donc d'abord un <b>compteur agrégé</b> des passages invités — une
 * ligne par (surface, jour), sur le patron de la table {@code page_views}
 * (V020) : {@code INSERT … ON CONFLICT DO UPDATE}, bornée par construction,
 * sans rien de personnel. Tant que ce compteur n'existe pas, la purge reste à
 * {@code false}.
 */
@ConfigurationProperties(prefix = "sejourfr.guest-attempt-purge")
public class GuestAttemptPurgeProperties {

    /** Interrupteur. {@code false} = aucune ligne supprimée, jamais. */
    private boolean enabled = false;

    /**
     * Âge au-delà duquel un attempt invité est purgeable, compté sur
     * {@code started_at} (et non {@code finished_at}) : un attempt abandonné en
     * cours de route n'a pas de fin, il s'accumulerait indéfiniment sinon.
     * 2 h est une décision produit, pas une constante — d'où sa présence ici.
     */
    private Duration retention = Duration.ofHours(2);

    /**
     * Nombre maximal d'attempts supprimés par passe. Borne la transaction et
     * le volume de cascade : on ne supprime jamais 100 000 lignes d'un coup.
     * Un excédent est simplement traité à la passe suivante.
     */
    private int batchSize = 500;

    /**
     * Cron de la passe (heure serveur). Par défaut toutes les 30 min : deux
     * fois plus fin que la rétention, donc un attempt vit au plus 2 h 30.
     */
    private String cron = "0 0/30 * * * *";

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public Duration getRetention() {
        return retention;
    }

    public void setRetention(Duration retention) {
        this.retention = retention;
    }

    public int getBatchSize() {
        return batchSize;
    }

    public void setBatchSize(int batchSize) {
        this.batchSize = batchSize;
    }

    public String getCron() {
        return cron;
    }

    public void setCron(String cron) {
        this.cron = cron;
    }
}
