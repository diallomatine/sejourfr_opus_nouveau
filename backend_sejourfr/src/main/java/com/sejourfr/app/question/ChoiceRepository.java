package com.sejourfr.app.question;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ChoiceRepository extends JpaRepository<Choice, UUID> {
}
