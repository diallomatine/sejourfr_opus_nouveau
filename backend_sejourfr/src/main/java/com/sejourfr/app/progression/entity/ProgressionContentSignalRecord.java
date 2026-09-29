package com.sejourfr.app.progression.entity;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.domain.ContentBankSignal;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Ce que la banque de questions n'a pas pu fournir (V4.2 §12 bis.5).
 *
 * <p>🛑 <b>Un signal ne modifie jamais un seuil.</b> Quand un couple
 * domaine + niveau est trop pauvre pour produire une seconde série sous le seuil
 * de recouvrement, la tentation est d'assouplir la règle « pour que le candidat
 * puisse avancer ». C'est exactement ce qu'il ne faut pas faire : on lui
 * validerait un palier sur des questions qu'il connaît déjà. On écrit la ligne
 * ici, et la production de contenu se priorise dessus.
 */
@Entity
@Table(name = "progression_content_signal")
@Getter
@Setter
public class ProgressionContentSignalRecord {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Column(name = "user_id", nullable = false, columnDefinition = "uuid")
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "signal", nullable = false, length = 32)
    private ContentBankSignal signal;

    @Enumerated(EnumType.STRING)
    @Column(name = "section", nullable = false, length = 2)
    private SkillSection section;

    @Enumerated(EnumType.STRING)
    @Column(name = "level", nullable = false, length = 2)
    private TargetLevel level;

    @Column(name = "detail", length = 255)
    private String detail;

    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt = Instant.now();
}
