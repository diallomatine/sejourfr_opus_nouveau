package com.sejourfr.app.entity;

import com.sejourfr.app.enums.AuthProvider;
import com.sejourfr.app.enums.ClientPlatform;
import com.sejourfr.app.enums.Role;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import org.hibernate.annotations.UuidGenerator;
import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "users", indexes = {
        @Index(name = "idx_users_email", columnList = "email", unique = true)
})
public class User {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(nullable = false, unique = true, length = 255)
    private String email;

    @Column(name = "password_hash")
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "auth_provider", nullable = false, length = 16)
    private AuthProvider authProvider = AuthProvider.LOCAL;

    @Column(name = "provider_user_id", length = 255)
    private String providerUserId;

    @Column(name = "first_name", length = 120)
    private String firstName;

    @Column(name = "last_name", length = 120)
    private String lastName;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_procedure", length = 16)
    private TargetProcedure targetProcedure;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_level", length = 8)
    private TargetLevel targetLevel;

    /**
     * Jour de l'examen vise, declare par le candidat (V047).
     *
     * <p>Un jour, pas un instant : une convocation ne porte pas d'heure, et un
     * {@code Instant} obligerait a inventer un fuseau puis a le reafficher.
     * NULL = pas de date, ce qui est une reponse PLEINE et la plus frequente —
     * la question est facultative et ne bloque jamais le tunnel.
     *
     * <p>Le decompte affiche (« dans 39 jours ») se calcule <b>a la lecture</b>,
     * jamais persiste.
     */
    @Column(name = "exam_date")
    private LocalDate examDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Role role = Role.USER;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    /**
     * Provenance du PREMIER JOUR : le reseau par lequel ce compte est arrive.
     * Posee a la creation (inscription locale ou premier sign-in social) et
     * <strong>jamais reecrite ensuite</strong> — la provenance d'une acquisition
     * est celle du jour ou elle a eu lieu, la reecrire a chaque visite
     * attribuerait toutes les acquisitions au dernier canal utilise.
     * {@code null} sur les comptes anterieurs a la mesure : rendu « inconnu »
     * a la lecture, jamais devine.
     */
    @Column(name = "signup_source", length = 40)
    private String signupSource;

    /** Plateforme d'inscription, meme regle que {@link #signupSource}. */
    @Enumerated(EnumType.STRING)
    @Column(name = "signup_platform", length = 16)
    private ClientPlatform signupPlatform;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = Instant.now();
    }

    /**
     * Anonymise le compte (suppression RGPD / App Store 5.1.1(v)). On garde la
     * ligne pour conserver l'historique d'abonnement lié (obligation comptable),
     * mais toutes les données personnelles directes disparaissent et le compte
     * devient inutilisable : login impossible (password invalide), email libéré
     * (deleted-{id}@anon.sejourfr, donc l'adresse d'origine peut se réinscrire),
     * identifiant social détaché (libère l'index unique provider). Idempotent.
     */
    public void anonymize() {
        if (deletedAt != null) {
            return;
        }
        this.email = "deleted-" + id + "@anon.sejourfr";
        this.firstName = null;
        this.lastName = null;
        this.passwordHash = "DELETED";
        this.providerUserId = null;
        this.targetProcedure = null;
        this.targetLevel = null;
        // La date d'examen est une donnee personnelle comme une autre : elle
        // designe un evenement de la vie administrative du candidat.
        this.examDate = null;
        this.active = false;
        this.deletedAt = Instant.now();
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public TargetProcedure getTargetProcedure() { return targetProcedure; }
    public void setTargetProcedure(TargetProcedure targetProcedure) { this.targetProcedure = targetProcedure; }

    public TargetLevel getTargetLevel() { return targetLevel; }
    public void setTargetLevel(TargetLevel targetLevel) { this.targetLevel = targetLevel; }

    public LocalDate getExamDate() { return examDate; }
    public void setExamDate(LocalDate examDate) { this.examDate = examDate; }

    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getLastLoginAt() { return lastLoginAt; }
    public void setLastLoginAt(Instant lastLoginAt) { this.lastLoginAt = lastLoginAt; }

    public Instant getDeletedAt() { return deletedAt; }
    public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }

    public AuthProvider getAuthProvider() { return authProvider; }
    public void setAuthProvider(AuthProvider authProvider) { this.authProvider = authProvider; }

    public String getProviderUserId() { return providerUserId; }
    public void setProviderUserId(String providerUserId) { this.providerUserId = providerUserId; }

    public String getSignupSource() { return signupSource; }
    public void setSignupSource(String signupSource) { this.signupSource = signupSource; }

    public ClientPlatform getSignupPlatform() { return signupPlatform; }
    public void setSignupPlatform(ClientPlatform signupPlatform) { this.signupPlatform = signupPlatform; }
}
