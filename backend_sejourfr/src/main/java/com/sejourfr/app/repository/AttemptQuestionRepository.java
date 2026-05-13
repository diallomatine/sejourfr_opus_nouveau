package com.sejourfr.app.repository;

import com.sejourfr.app.entity.AttemptQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface AttemptQuestionRepository extends JpaRepository<AttemptQuestion, UUID> {
}
