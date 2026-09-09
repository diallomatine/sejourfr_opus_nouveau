package com.sejourfr.app.progression.manager;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.ContentBankSignal;
import com.sejourfr.app.progression.entity.ProgressionContentSignalRecord;
import com.sejourfr.app.progression.repository.ProgressionContentSignalRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.UUID;

/** Le seul accès aux signaux de production de contenu (§12 bis.5). */
@Component
@RequiredArgsConstructor
@Slf4j
public class ProgressionContentSignalManager {

    private final ProgressionContentSignalRepository repository;

    public void signaler(UUID userId, ContentBankSignal signal, SkillSection section,
                         TargetLevel level, String detail) {
        ProgressionContentSignalRecord record = new ProgressionContentSignalRecord();
        record.setUserId(userId);
        record.setSignal(signal);
        record.setSection(section);
        record.setLevel(level);
        record.setDetail(detail);
        repository.save(record);
        log.info("Progression : {}({}, {}) — {}", signal, section, level, detail);
    }
}
