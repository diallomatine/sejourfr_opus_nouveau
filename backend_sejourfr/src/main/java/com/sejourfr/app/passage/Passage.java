package com.sejourfr.app.passage;

import com.sejourfr.app.media.Media;
import com.sejourfr.app.passage.enums.PassageType;
import com.sejourfr.app.theme.Theme;
import jakarta.persistence.*;
import org.hibernate.annotations.UuidGenerator;

import java.util.UUID;

@Entity
@Table(name = "passages")
public class Passage {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "uuid")
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private PassageType type;

    @Column(columnDefinition = "text")
    private String content;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "media_id")
    private Media media;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "theme_id")
    private Theme theme;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public PassageType getType() { return type; }
    public void setType(PassageType type) { this.type = type; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Media getMedia() { return media; }
    public void setMedia(Media media) { this.media = media; }

    public Theme getTheme() { return theme; }
    public void setTheme(Theme theme) { this.theme = theme; }
}
