package com.sejourfr.app.service.questionimport;

import com.sejourfr.app.dto.CoImageImportError;
import com.sejourfr.app.dto.CoImageImportQuestion;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.service.ImageUploadSupport.Dimensions;
import com.sejourfr.app.service.ImageUploadSupport.FormatImage;

import java.util.List;

/**
 * Une question du manifeste apres validation. Les champs normalises valent
 * {@code null} quand la donnee source est fautive ; une question n'est
 * importable que si {@link #erreurs()} est vide, et tous sont alors renseignes
 * (sauf {@code explication}, facultative).
 *
 * @param propositions       les 4 propositions, espaces normalises (ordre A..D)
 * @param indexBonneReponse  0..3
 */
public record QuestionAnalysee(
        int index,
        CoImageImportQuestion brut,
        String externalId,
        Difficulty niveau,
        Theme theme,
        List<String> propositions,
        Integer indexBonneReponse,
        String descriptionScene,
        String explication,
        FichierImport image,
        FormatImage format,
        Dimensions dimensions,
        List<CoImageImportError> erreurs
) {
    public boolean ok() {
        return erreurs.isEmpty();
    }
}
