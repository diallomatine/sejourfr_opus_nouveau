package com.sejourfr.app.entity;

import com.sejourfr.app.enums.PageViewEvent;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Un compteur d'audience agrégé : le nombre d'événements d'un type donné, sur
 * une page donnée, pour une source donnée, un jour donné.
 *
 * <p>Ce n'est <strong>pas</strong> un journal d'événements — une visite
 * n'ajoute pas de ligne, elle incrémente {@code hits}. La table reste donc
 * bornée quoi qu'il arrive, y compris face à un endpoint public.
 *
 * <p>Aucune donnée personnelle n'y transite : ni IP, ni user-agent, ni
 * identifiant de visiteur (cf. migration V020 et la page /confidentialite qui
 * s'appuie sur cette absence).
 */
@Entity
@Table(
        name = "page_views",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_page_views_bucket",
                columnNames = {"path", "source", "event", "day"}),
        indexes = @Index(name = "idx_page_views_path_day", columnList = "path, day DESC"))
@Getter
@Setter
public class PageView {

    @Id
    @UuidGenerator
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "path", nullable = false, length = 160)
    private String path;

    @Column(name = "source", nullable = false, length = 40)
    private String source;

    @Enumerated(EnumType.STRING)
    @Column(name = "event", nullable = false, length = 64)
    private PageViewEvent event;

    @Column(name = "day", nullable = false)
    private LocalDate day;

    @Column(name = "hits", nullable = false)
    private long hits;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}
