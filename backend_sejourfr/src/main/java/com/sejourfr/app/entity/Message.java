package com.sejourfr.app.entity;

import com.sejourfr.app.enums.MessageSender;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "messages", indexes = {
        @Index(name = "idx_message_conv", columnList = "conversation_id"),
        @Index(name = "idx_message_author", columnList = "author_id")
})
public class Message {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @Enumerated(EnumType.STRING)
    @Column(name = "sender_type", nullable = false, length = 16)
    private MessageSender senderType;

    /**
     * Auteur du message. {@code null} pour le message entrant d'un contact non
     * connecté (formulaire). Les réponses admin portent toujours un auteur.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id")
    private User author;

    @Column(nullable = false, columnDefinition = "text")
    private String body;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Conversation getConversation() { return conversation; }
    public void setConversation(Conversation conversation) { this.conversation = conversation; }

    public MessageSender getSenderType() { return senderType; }
    public void setSenderType(MessageSender senderType) { this.senderType = senderType; }

    public User getAuthor() { return author; }
    public void setAuthor(User author) { this.author = author; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
