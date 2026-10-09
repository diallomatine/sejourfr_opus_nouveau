package com.sejourfr.app.repository;

import com.sejourfr.app.entity.RealtimeFallback;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface RealtimeFallbackRepository extends JpaRepository<RealtimeFallback, UUID> {
}
