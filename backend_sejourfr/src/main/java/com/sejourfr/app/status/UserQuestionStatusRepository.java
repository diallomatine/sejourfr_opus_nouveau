package com.sejourfr.app.status;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface UserQuestionStatusRepository extends JpaRepository<UserQuestionStatus, UUID> {
}
