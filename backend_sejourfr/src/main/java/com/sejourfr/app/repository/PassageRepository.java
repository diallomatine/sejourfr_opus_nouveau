package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Passage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface PassageRepository extends JpaRepository<Passage, UUID> {
}
