package com.sejourfr.app.repository;

import com.sejourfr.app.entity.ProcessedExternalEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProcessedExternalEventRepository
        extends JpaRepository<ProcessedExternalEvent, ProcessedExternalEvent.PK> {
}
