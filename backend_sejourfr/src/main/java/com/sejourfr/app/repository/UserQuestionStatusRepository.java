package com.sejourfr.app.repository;

import com.sejourfr.app.entity.UserQuestionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface UserQuestionStatusRepository extends JpaRepository<UserQuestionStatus, UUID> {
}
