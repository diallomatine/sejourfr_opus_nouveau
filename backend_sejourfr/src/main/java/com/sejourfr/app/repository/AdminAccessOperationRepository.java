package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AdminAccessOperation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AdminAccessOperationRepository extends JpaRepository<AdminAccessOperation, UUID> {

    List<AdminAccessOperation> findByUserIdOrderByCreatedAtDesc(UUID userId);

    @Modifying
    @Query("DELETE FROM AdminAccessOperation a WHERE a.userId = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
