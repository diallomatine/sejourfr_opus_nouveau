package com.sejourfr.app.attempt;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface AttemptQuestionRepository extends JpaRepository<AttemptQuestion, UUID> {
}
