package com.sejourfr.app.question;

import com.sejourfr.app.theme.enums.Module;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface QuestionRepository
        extends JpaRepository<Question, UUID>, JpaSpecificationExecutor<Question> {

    long countByModule(Module module);
    long countByModuleAndActive(Module module, boolean active);
    long countByThemeId(UUID themeId);
}
