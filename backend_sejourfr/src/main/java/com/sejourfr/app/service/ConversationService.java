package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminMessagePreviewDto;
import com.sejourfr.app.dto.ConversationDetailDto;
import com.sejourfr.app.dto.ConversationSummaryDto;
import com.sejourfr.app.dto.MessageDto;
import com.sejourfr.app.entity.Conversation;
import com.sejourfr.app.entity.Message;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EmailType;
import com.sejourfr.app.enums.MessageSender;
import com.sejourfr.app.enums.MessageStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.ConversationManager;
import com.sejourfr.app.manager.MessageManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.MessageMapper;
import com.sejourfr.app.specification.ConversationSpecifications;
import com.sejourfr.app.service.email.EmailFormats;
import com.sejourfr.app.service.email.EmailMessage;
import com.sejourfr.app.service.email.SpringMailEmailSender;
import com.sejourfr.app.service.email.compose.SupportEmailComposer;
import com.sejourfr.app.service.email.event.AdminMessageEvent;
import com.sejourfr.app.service.email.event.ContactReceivedEvent;
import com.sejourfr.app.service.email.event.SupportReplyEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Boite de reception admin : recherche / detail / reponse / statut / suppression
 * sur les conversations utilisateur.
 */
@Service
@Transactional
@RequiredArgsConstructor
public class ConversationService {

    private static final int PREVIEW_MAX = 140;
    static final int SUBJECT_MIN = 3;
    static final int SUBJECT_MAX = 150;
    static final int BODY_MAX = 5000;
    static final String MSG_COMPTE_SUPPRIME =
            "Ce compte a été supprimé : il ne peut plus recevoir de message.";

    private final ConversationManager conversationManager;
    private final MessageManager messageManager;
    private final UserManager userManager;
    private final MessageMapper mapper;
    private final ApplicationEventPublisher eventPublisher;
    /** Rendu local des gabarits, pour l'apercu (absent si un autre fournisseur envoie). */
    private final ObjectProvider<SpringMailEmailSender> localRenderer;

    @Transactional(readOnly = true)
    public Page<ConversationSummaryDto> search(
            MessageStatus status, Boolean unreadOnly, UUID userId, String search, Pageable pageable) {
        Specification<Conversation> spec = Specification.allOf(
                ConversationSpecifications.hasStatus(status),
                ConversationSpecifications.unreadOnly(unreadOnly),
                ConversationSpecifications.hasUser(userId),
                ConversationSpecifications.subjectContains(search)
        );
        return conversationManager.search(spec, pageable).map(this::toSummary);
    }

    @Transactional(readOnly = true)
    public ConversationDetailDto getDetail(UUID id) {
        Conversation c = loadOrThrow(id);
        List<Message> messages = messageManager.findByConversationOrdered(id);
        return mapper.toDetail(c, messages);
    }

    public ConversationDetailDto markRead(UUID id) {
        Conversation c = loadOrThrow(id);
        c.setUnreadForAdmin(false);
        if (c.getStatus() == MessageStatus.NOUVEAU) {
            c.setStatus(MessageStatus.LU);
        }
        return mapper.toDetail(c, messageManager.findByConversationOrdered(id));
    }

    public MessageDto reply(UUID conversationId, String adminEmail, String body) {
        Conversation c = loadOrThrow(conversationId);
        User admin = userManager.findByEmail(adminEmail)
                .orElseThrow(() -> NotFoundException.of("User", adminEmail));

        Message m = new Message();
        m.setConversation(c);
        m.setSenderType(MessageSender.ADMIN);
        m.setAuthor(admin);
        m.setBody(body);
        Message saved = messageManager.save(m);

        c.setLastMessageAt(saved.getCreatedAt() != null ? saved.getCreatedAt() : Instant.now());
        c.setUnreadForAdmin(false);
        c.setUnreadForUser(true);
        c.setStatus(MessageStatus.REPONDU);

        // Toute réponse part par email APRES COMMIT. Conversation issue du
        // formulaire de contact : au contact (SUPPORT_REPLY). Conversation
        // rattachée à un compte (ouverte par un admin, D-58) : au compte, à son
        // adresse ACTUELLE (ADMIN_MESSAGE) — il n'existe aucune messagerie
        // in-app, une réponse non envoyée ne serait lue par personne. Un compte
        // supprimé ne reçoit rien.
        if (c.getContactEmail() != null && !c.getContactEmail().isBlank()) {
            eventPublisher.publishEvent(new SupportReplyEvent(saved.getId(), c.getContactEmail()));
        } else if (c.getUser() != null && c.getUser().getDeletedAt() == null) {
            eventPublisher.publishEvent(new AdminMessageEvent(
                    saved.getId(), c.getUser().getId(), c.getUser().getEmail()));
        }

        return mapper.toDto(saved);
    }

    /**
     * Crée une conversation depuis le formulaire de contact public : un message
     * entrant (côté USER, sans auteur car le visiteur n'a pas forcément de
     * compte), non lu côté admin, statut {@code NOUVEAU}. C'est ce qui alimente
     * la boite de réception admin.
     */
    public Conversation createFromContact(String name, String email, String subject, String message) {
        return createFromContact(name, email, subject, message, null);
    }

    /**
     * Idem, et publie l'accuse de reception ({@code CONTACT_RECEIVED}) quand un
     * numero de suivi est fourni — envoye APRES le commit de cette transaction.
     */
    public Conversation createFromContact(String name, String email, String subject, String message,
                                          String ticketId) {
        Conversation c = new Conversation();
        c.setContactName(name);
        c.setContactEmail(email);
        c.setSubject(subject);
        c.setStatus(MessageStatus.NOUVEAU);
        c.setUnreadForAdmin(true);
        c.setUnreadForUser(false);
        Conversation saved = conversationManager.save(c);

        Message m = new Message();
        m.setConversation(saved);
        m.setSenderType(MessageSender.USER);
        m.setBody(message);
        Message savedMessage = messageManager.save(m);

        saved.setLastMessageAt(
                savedMessage.getCreatedAt() != null ? savedMessage.getCreatedAt() : Instant.now());
        if (ticketId != null) {
            eventPublisher.publishEvent(new ContactReceivedEvent(
                    saved.getId(), email, name, subject, message, ticketId));
        }
        return saved;
    }

    /**
     * Un admin écrit à un compte (D-58) : une NOUVELLE conversation rattachée au
     * compte, objet = sujet du mail, premier message signé par l'admin, puis le
     * mail {@code ADMIN_MESSAGE} APRES COMMIT. Statut {@code REPONDU} : la balle
     * est dans le camp du candidat, comme après une réponse.
     *
     * @throws ResponseStatusException 409 si le compte est supprimé
     */
    public ConversationDetailDto sendToUser(UUID userId, UUID adminId, String subject, String body) {
        User recipient = messageableUser(userId);
        String cleanSubject = cleanSubject(subject);
        String cleanBody = cleanBody(body);
        User admin = userManager.findById(adminId).orElseThrow(() -> NotFoundException.of("User", adminId));

        Conversation c = new Conversation();
        c.setUser(recipient);
        c.setSubject(cleanSubject);
        c.setStatus(MessageStatus.REPONDU);
        c.setUnreadForAdmin(false);
        c.setUnreadForUser(true);
        Conversation saved = conversationManager.save(c);

        Message m = new Message();
        m.setConversation(saved);
        m.setSenderType(MessageSender.ADMIN);
        m.setAuthor(admin);
        m.setBody(cleanBody);
        Message savedMessage = messageManager.save(m);
        saved.setLastMessageAt(
                savedMessage.getCreatedAt() != null ? savedMessage.getCreatedAt() : Instant.now());

        eventPublisher.publishEvent(new AdminMessageEvent(savedMessage.getId(), recipient.getId(), recipient.getEmail()));
        return mapper.toDetail(saved, List.of(savedMessage));
    }

    /**
     * Ce que le compte recevra, rendu par le vrai gabarit et les mêmes
     * variables que l'envoi ({@link SupportEmailComposer#adminMessageVariables}).
     * N'écrit rien, n'envoie rien.
     */
    @Transactional(readOnly = true)
    public AdminMessagePreviewDto previewToUser(UUID userId, String subject, String body) {
        User recipient = messageableUser(userId);
        SpringMailEmailSender renderer = localRenderer.getIfAvailable();
        if (renderer == null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Aperçu indisponible avec le fournisseur d'emails configuré.");
        }
        EmailMessage message = new EmailMessage(recipient.getEmail(), EmailType.ADMIN_MESSAGE,
                SupportEmailComposer.adminMessageVariables(
                        recipient.getFirstName(), cleanSubject(subject), cleanBody(body)),
                null, null);
        SpringMailEmailSender.Rendered r = renderer.render(message);
        return new AdminMessagePreviewDto(recipient.getEmail(), r.subject(), r.html(), r.text());
    }

    public ConversationDetailDto updateStatus(UUID id, MessageStatus newStatus) {
        Conversation c = loadOrThrow(id);
        c.setStatus(newStatus);
        if (newStatus != MessageStatus.NOUVEAU) {
            c.setUnreadForAdmin(false);
        }
        return mapper.toDetail(c, messageManager.findByConversationOrdered(id));
    }

    public void delete(UUID id) {
        conversationManager.delete(loadOrThrow(id));
    }

    public long countUnread() {
        return conversationManager.countUnreadForAdmin();
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private Conversation loadOrThrow(UUID id) {
        return conversationManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Conversation", id));
    }

    private User messageableUser(UUID userId) {
        User user = userManager.findById(userId).orElseThrow(() -> NotFoundException.of("User", userId));
        if (user.getDeletedAt() != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, MSG_COMPTE_SUPPRIME);
        }
        return user;
    }

    /** L'objet finit en en-tête de mail : jamais de CR/LF, blancs réduits. */
    static String cleanSubject(String subject) {
        String s = subject == null ? "" : subject.replaceAll("\\s+", " ").strip();
        if (s.length() < SUBJECT_MIN || s.length() > SUBJECT_MAX) {
            throw new IllegalArgumentException(
                    "L'objet doit faire entre " + SUBJECT_MIN + " et " + SUBJECT_MAX + " caractères");
        }
        return s;
    }

    static String cleanBody(String body) {
        String b = EmailFormats.normalizeLines(body);
        if (b.isEmpty() || b.length() > BODY_MAX) {
            throw new IllegalArgumentException(
                    "Le message doit faire entre 1 et " + BODY_MAX + " caractères");
        }
        return b;
    }

    private ConversationSummaryDto toSummary(Conversation c) {
        List<Message> messages = messageManager.findByConversationOrdered(c.getId());
        String preview = "";
        if (!messages.isEmpty()) {
            String body = messages.get(messages.size() - 1).getBody();
            preview = body.length() > PREVIEW_MAX ? body.substring(0, PREVIEW_MAX) + "..." : body;
        }
        return mapper.toSummary(c, preview, messages.size());
    }
}
