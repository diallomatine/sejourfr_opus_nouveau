package com.sejourfr.app.entity;

import com.sejourfr.app.enums.ClientPlatform;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

import java.io.Serializable;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/** Cle de {@link UserActivityDay} : compte × jour (Europe/Paris) × plateforme. */
@Embeddable
public class UserActivityDayId implements Serializable {

    @Column(name = "user_id", columnDefinition = "uuid")
    private UUID userId;

    @Column(name = "day")
    private LocalDate day;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", length = 16)
    private ClientPlatform platform;

    public UserActivityDayId() {}

    public UserActivityDayId(UUID userId, LocalDate day, ClientPlatform platform) {
        this.userId = userId;
        this.day = day;
        this.platform = platform;
    }

    public UUID getUserId() { return userId; }
    public LocalDate getDay() { return day; }
    public ClientPlatform getPlatform() { return platform; }

    @Override
    public boolean equals(Object other) {
        if (this == other) return true;
        if (!(other instanceof UserActivityDayId that)) return false;
        return Objects.equals(userId, that.userId) && Objects.equals(day, that.day)
                && platform == that.platform;
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, day, platform);
    }
}
