package com.sejourfr.app.repository;

import com.sejourfr.app.entity.FreeEntitlementUsage;
import com.sejourfr.app.enums.FreeEntitlementCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FreeEntitlementUsageRepository extends JpaRepository<FreeEntitlementUsage, UUID> {

    boolean existsByUserIdAndCode(UUID userId, FreeEntitlementCode code);

    Optional<FreeEntitlementUsage> findByUserIdAndCode(UUID userId, FreeEntitlementCode code);

    /**
     * Les gratuites deja consommees, <b>toutes ensemble</b> : un paywall qui
     * annonce l'etat des deux freebies ne doit pas payer deux allers-retours
     * pour deux lignes.
     */
    List<FreeEntitlementUsage> findAllByUserId(UUID userId);

    @Modifying
    @Query("DELETE FROM FreeEntitlementUsage f WHERE f.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
