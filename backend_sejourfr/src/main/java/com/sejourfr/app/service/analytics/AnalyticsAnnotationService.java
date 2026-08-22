package com.sejourfr.app.service.analytics;

import com.sejourfr.app.dto.AnalyticsAnnotationDto;
import com.sejourfr.app.dto.AnalyticsAnnotationRequest;
import com.sejourfr.app.entity.AnalyticsAnnotation;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AnalyticsAnnotationManager;
import com.sejourfr.app.util.FenetreMesure;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Les reperes produit / marketing de la courbe (brief §52).
 *
 * <p>Saisis a la main, ils sont la seule chose de cet ecran qui ne se mesure
 * pas : ils <b>expliquent</b>. « Le 12, trois videos publiees » rend un pic
 * lisible ; sans repere, un ecart s'attribue au hasard, au produit ou au
 * marketing sans qu'on puisse trancher.
 *
 * <p>La lecture passe par la meme {@link FenetreMesure} que le reste de l'ecran :
 * un repere qui apparaitrait hors de la periode affichee serait pose a cote de
 * la courbe qu'il commente.
 */
@Service
@RequiredArgsConstructor
public class AnalyticsAnnotationService {

    private final AnalyticsAnnotationManager manager;

    /** Les reperes d'une fenetre, bornes incluses, du plus ancien au plus recent. */
    public List<AnalyticsAnnotationDto> between(LocalDate from, LocalDate to) {
        return manager.between(from, to).stream().map(AnalyticsAnnotationDto::from).toList();
    }

    /**
     * Cree un repere.
     *
     * @param createdBy auteur, conserve pour la tracabilite. L'annotation lui
     *                  survit ({@code ON DELETE SET NULL}) : c'est un repere
     *                  produit, pas une donnee personnelle.
     */
    public AnalyticsAnnotationDto create(AnalyticsAnnotationRequest request, UUID createdBy) {
        AnalyticsAnnotation annotation = new AnalyticsAnnotation();
        annotation.setOccurredOn(request.occurredOn());
        annotation.setTitle(request.title().trim());
        annotation.setDescription(blankToNull(request.description()));
        annotation.setCategory(request.category());
        annotation.setCreatedBy(createdBy);
        return AnalyticsAnnotationDto.from(manager.save(annotation));
    }

    /**
     * Supprime un repere.
     *
     * <p>Un identifiant inconnu est un <b>404 nomme</b>, jamais un succes muet :
     * l'appelant doit savoir que son repere n'a pas ete efface.
     */
    public void delete(UUID id) {
        AnalyticsAnnotation annotation = manager.findById(id).orElseThrow(
                () -> new NotFoundException("Repère introuvable : " + id));
        manager.delete(annotation);
    }

    private static String blankToNull(String raw) {
        if (raw == null) return null;
        String trimmed = raw.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
