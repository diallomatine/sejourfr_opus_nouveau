package com.sejourfr.app.repository;

import com.sejourfr.app.entity.LegacyPassCompensation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface LegacyPassCompensationRepository
        extends JpaRepository<LegacyPassCompensation, UUID> {

    /**
     * Compensations dont l'e-mail d'annonce reste à envoyer, comptes supprimés
     * exclus — un compte peut avoir été supprimé entre la migration et l'envoi.
     * L'utilisateur est joint pour éviter un N+1 sur la boucle d'envoi.
     */
    @Query("""
            SELECT c FROM LegacyPassCompensation c
            JOIN FETCH c.user u
            WHERE c.mailedAt IS NULL
              AND u.deletedAt IS NULL
            ORDER BY c.grantedAt, c.id
            """)
    List<LegacyPassCompensation> findAEnvoyer();

    long countByMailedAtIsNotNull();
}
