package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Conversation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface ConversationRepository
        extends JpaRepository<Conversation, UUID>, JpaSpecificationExecutor<Conversation> {

    long countByUnreadForAdminTrue();

    /**
     * Purge des conversations de support d'un user (suppression de compte). Les
     * messages liés partent via le FK {@code messages.conversation_id ON DELETE
     * CASCADE} au niveau base.
     */
    @Modifying
    @Query("DELETE FROM Conversation c WHERE c.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
