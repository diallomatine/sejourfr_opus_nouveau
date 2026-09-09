package com.sejourfr.app.progression.repository;

import com.sejourfr.app.progression.entity.ProgressionContentSignalRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ProgressionContentSignalRepository
        extends JpaRepository<ProgressionContentSignalRecord, UUID> {
}
