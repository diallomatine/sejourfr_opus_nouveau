package com.sejourfr.app.service;

import com.sejourfr.app.dto.PassageDto;
import com.sejourfr.app.dto.PassageWriteRequest;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.repository.MediaRepository;
import com.sejourfr.app.repository.PassageRepository;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.repository.ThemeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class PassageService {

    private final PassageRepository passageRepository;
    private final ThemeRepository themeRepository;
    private final MediaRepository mediaRepository;
    private final QuestionRepository questionRepository;

    public PassageService(PassageRepository passageRepository,
                          ThemeRepository themeRepository,
                          MediaRepository mediaRepository,
                          QuestionRepository questionRepository) {
        this.passageRepository = passageRepository;
        this.themeRepository = themeRepository;
        this.mediaRepository = mediaRepository;
        this.questionRepository = questionRepository;
    }

    private PassageDto toDto(Passage p) {
        long count = questionRepository.countByPassageId(p.getId());
        return new PassageDto(
                p.getId(),
                p.getType(),
                p.getContent(),
                p.getTheme() != null ? p.getTheme().getId() : null,
                p.getTheme() != null ? p.getTheme().getName() : null,
                p.getMedia() != null ? p.getMedia().getId() : null,
                p.getMedia() != null ? p.getMedia().getUrl() : null,
                p.getMedia() != null ? p.getMedia().getType() : null,
                count
        );
    }

    @Transactional(readOnly = true)
    public List<PassageDto> list(UUID themeId) {
        List<Passage> passages = themeId == null
                ? passageRepository.findAll()
                : passageRepository.findByThemeIdOrderByIdAsc(themeId);
        return passages.stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public PassageDto getById(UUID id) {
        return toDto(loadOrThrow(id));
    }

    public PassageDto create(PassageWriteRequest req) {
        Passage p = new Passage();
        applyCommon(p, req);
        return toDto(passageRepository.save(p));
    }

    public PassageDto update(UUID id, PassageWriteRequest req) {
        Passage p = loadOrThrow(id);
        applyCommon(p, req);
        return toDto(p);
    }

    public void delete(UUID id) {
        Passage p = loadOrThrow(id);
        long count = questionRepository.countByPassageId(p.getId());
        if (count > 0) {
            throw new BusinessException(
                    "Impossible de supprimer : " + count + " question(s) sont rattachée(s) à ce passage");
        }
        passageRepository.delete(p);
    }

    private void applyCommon(Passage p, PassageWriteRequest req) {
        Theme theme = themeRepository.findById(req.themeId())
                .orElseThrow(() -> NotFoundException.of("Theme", req.themeId()));
        p.setTheme(theme);
        p.setType(req.type());
        p.setContent(req.content());

        if (req.mediaId() != null) {
            Media m = mediaRepository.findById(req.mediaId())
                    .orElseThrow(() -> NotFoundException.of("Media", req.mediaId()));
            p.setMedia(m);
        } else {
            p.setMedia(null);
        }
    }

    private Passage loadOrThrow(UUID id) {
        return passageRepository.findById(id)
                .orElseThrow(() -> NotFoundException.of("Passage", id));
    }
}
