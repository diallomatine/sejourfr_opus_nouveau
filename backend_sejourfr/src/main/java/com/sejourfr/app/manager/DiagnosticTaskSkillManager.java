package com.sejourfr.app.manager;

import com.sejourfr.app.entity.DiagnosticTaskSkill;
import com.sejourfr.app.repository.DiagnosticTaskSkillRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class DiagnosticTaskSkillManager {

    private final DiagnosticTaskSkillRepository repository;

    public List<DiagnosticTaskSkill> findActiveByTaskId(UUID taskId) {
        return repository.findActiveByTaskId(taskId);
    }
}
