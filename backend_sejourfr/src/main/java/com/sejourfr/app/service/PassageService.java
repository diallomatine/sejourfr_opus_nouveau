package com.sejourfr.app.service;

import com.sejourfr.app.dto.PassageDto;
import com.sejourfr.app.dto.PassageWriteRequest;
import com.sejourfr.app.entity.Media;
import com.sejourfr.app.entity.Passage;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.MediaManager;
import com.sejourfr.app.manager.PassageManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.mapper.PassageMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * CRUD admin des passages (textes / extraits multimedias attaches a une question).
 * Suppression interdite si au moins 1 question reference le passage.
 */
@Service
@Transactional
@RequiredArgsConstructor
public class PassageService {

    private final PassageManager passageManager;
    private final ThemeManager themeManager;
    private final MediaManager mediaManager;
    private final QuestionManager questionManager;
    private final PassageMapper mapper;

    @Transactional(readOnly = true)
    public List<PassageDto> list(UUID themeId) {
        List<Passage> passages = themeId == null
                ? passageManager.findAll()
                : passageManager.findByThemeOrdered(themeId);
        return passages.stream().map(this::toDto).toList();
    }

    @Transactional(readOnly = true)
    public PassageDto getById(UUID id) {
        return toDto(loadOrThrow(id));
    }

    public PassageDto create(PassageWriteRequest req) {
        Passage p = new Passage();
        applyCommon(p, req);
        return toDto(passageManager.save(p));
    }

    public PassageDto update(UUID id, PassageWriteRequest req) {
        Passage p = loadOrThrow(id);
        applyCommon(p, req);
        return toDto(p);
    }

    public void delete(UUID id) {
        Passage p = loadOrThrow(id);
        long count = questionManager.countByPassage(p.getId());
        if (count > 0) {
            throw new BusinessException(
                    "Impossible de supprimer : " + count + " question(s) sont rattachée(s) à ce passage");
        }
        passageManager.delete(p);
    }

    // ------------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------------

    private void applyCommon(Passage p, PassageWriteRequest req) {
        Theme theme = themeManager.findById(req.themeId())
                .orElseThrow(() -> NotFoundException.of("Theme", req.themeId()));
        p.setTheme(theme);
        p.setType(req.type());
        p.setContent(req.content());

        p.setMedia(req.mediaId() == null ? null : loadMedia(req.mediaId()));
    }

    private Media loadMedia(UUID id) {
        return mediaManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Media", id));
    }

    private Passage loadOrThrow(UUID id) {
        return passageManager.findById(id)
                .orElseThrow(() -> NotFoundException.of("Passage", id));
    }

    private PassageDto toDto(Passage p) {
        return mapper.toDto(p, questionManager.countByPassage(p.getId()));
    }
}
