package com.sejourfr.app.repository;

import com.sejourfr.app.entity.PageView;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface PageViewRepository extends JpaRepository<PageView, UUID> {

    /**
     * Incrémente le compteur du bucket (page, source, événement, jour), en le
     * créant s'il n'existe pas.
     *
     * <p>Requête native pour bénéficier du {@code ON CONFLICT DO UPDATE} de
     * Postgres : l'opération est <strong>atomique</strong>. Un lire-puis-écrire
     * côté Java perdrait des incréments dès que deux visiteurs arrivent en même
     * temps, et l'endpoint étant public c'est le cas nominal, pas le cas limite.
     */
    // clearAutomatically : l'upsert passe sous le radar de la session Hibernate.
    // Sans purge du contexte de persistance, une lecture ultérieure dans la même
    // transaction renverrait l'entité mise en cache avant l'incrément (hits figé).
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = """
            INSERT INTO page_views (id, path, source, event, day, hits, updated_at)
            VALUES (:id, :path, :source, :event, :day, 1, now())
            ON CONFLICT ON CONSTRAINT uq_page_views_bucket
            DO UPDATE SET hits = page_views.hits + 1, updated_at = now()
            """, nativeQuery = true)
    void increment(@Param("id") UUID id,
                   @Param("path") String path,
                   @Param("source") String source,
                   @Param("event") String event,
                   @Param("day") LocalDate day);

    List<PageView> findByPathAndDayGreaterThanEqual(String path, LocalDate from);
}
