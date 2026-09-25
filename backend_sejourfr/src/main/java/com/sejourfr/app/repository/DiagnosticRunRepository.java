package com.sejourfr.app.repository;

import com.sejourfr.app.entity.DiagnosticRun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface DiagnosticRunRepository extends JpaRepository<DiagnosticRun, UUID> {

    /** Type de chacune des runs existantes parmi {@code ids}, en une requete. */
    @Query("SELECT r.id AS id, r.diagnosticType AS type FROM DiagnosticRun r WHERE r.id IN :ids")
    List<RunType> findTypesByIdIn(@Param("ids") Collection<UUID> ids);

    interface RunType {
        UUID getId();

        com.sejourfr.app.enums.DiagnosticRunType getType();
    }
}
