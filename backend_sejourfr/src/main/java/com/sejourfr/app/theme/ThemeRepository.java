package com.sejourfr.app.theme;

import com.sejourfr.app.theme.enums.Module;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ThemeRepository extends JpaRepository<Theme, UUID> {
    List<Theme> findByModuleOrderByDisplayOrderAsc(Module module);
    Optional<Theme> findByCode(String code);
    boolean existsByCode(String code);
}
