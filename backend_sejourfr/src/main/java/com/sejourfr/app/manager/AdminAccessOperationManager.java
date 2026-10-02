package com.sejourfr.app.manager;

import com.sejourfr.app.entity.AdminAccessOperation;
import com.sejourfr.app.repository.AdminAccessOperationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

/** Couche d'accès au journal des actions admin sur les accès ({@code admin_access_operations}, V083). */
@Component
@RequiredArgsConstructor
public class AdminAccessOperationManager {

    private final AdminAccessOperationRepository repository;

    public AdminAccessOperation saveAndFlush(AdminAccessOperation operation) {
        return repository.saveAndFlush(operation);
    }

    public List<AdminAccessOperation> findByUserId(UUID userId) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserId(userId);
    }
}
