package com.sejourfr.app.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * <b>Un ESSAI de serie, lance depuis une carte d'etape</b> (V072).
 *
 * <p>Une etape de <b>comprehension</b> (CO/CE) et une etape <b>civique</b> se
 * valident par <b>deux series reussies</b>. L'ecran d'etape montre donc deux
 * cartes, et cette table dit quelle session appartient a quelle carte.
 *
 * <h2>🛑 Le LIEN est persiste, jamais le VERDICT</h2>
 * <p>Il n'y a ici ni {@code reussie}, ni {@code validee}, ni {@code score} :
 * <ul>
 *   <li>« cette serie est reussie » se relit sur l'attempt
 *       ({@code score >= seuil}, {@code JourneySerieVerdict}) ;</li>
 *   <li>« cette carte est validee » se relit comme « au moins un essai de cette
 *       carte est reussi ».</li>
 * </ul>
 * Figer le verdict ici le ferait diverger de l'attempt le jour ou le ratio de
 * reussite bouge — et ce ratio a deja une autorite unique,
 * {@code learning-plan.comprehension.solid-ratio}.
 *
 * <h2>Pourquoi le lien, lui, ne se relit pas</h2>
 * <p>Un attempt de serie ciblee ne porte aucune trace de l'etape qui l'a lance.
 * « Le candidat a lance la serie n°2 de cette etape-ci » est une <b>decision
 * prise a un instant</b>, que rien ne permet de reconstituer : c'est le meme
 * critere que l'epingle du Plan (V065) et que l'ordre du parcours (V066), les
 * deux seules autres exceptions assumees du depot.
 *
 * <h2>Une ligne par ESSAI</h2>
 * <p>🛑 <b>Aucune unicite sur {@code (step_id, series_index)}</b> : « refaire »
 * ajoute une ligne. C'est ce qui donne le <b>dernier score</b> (la ligne la plus
 * recente) et l'historique, sans rien ecraser. L'unicite porte sur
 * {@link #attempt} : une session appartient a une seule carte, sans quoi un
 * double appel aurait valide les deux d'un coup.
 */
@Entity
@Table(name = "journey_step_series")
@Getter
@Setter
public class JourneyStepSeries {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "step_id", nullable = false)
    private JourneyStep step;

    /**
     * Le rang de la <b>carte</b> : 1 ou 2 (le quota vient de
     * {@code tcf-journey-config.trainSeriesQuota}, jamais d'ici). Plusieurs
     * lignes peuvent porter le meme rang — ce sont les essais successifs.
     */
    @Column(name = "series_index", nullable = false)
    private short seriesIndex;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "attempt_id", nullable = false, unique = true)
    private Attempt attempt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    /** Le rang de la carte, tel que le contrat servi l'exprime. */
    public int index() {
        return seriesIndex;
    }
}
