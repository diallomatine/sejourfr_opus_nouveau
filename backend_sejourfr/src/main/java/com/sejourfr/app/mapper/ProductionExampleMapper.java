package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.enums.ExampleAudioStatus;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Mapping pur des exemples-modeles vers la vue candidat. L'audio n'est exposé
 * qu'une fois {@code PUBLISHED} (validé admin).
 */
@Component
public class ProductionExampleMapper {

    public ProductionExampleDto toDto(ProductionExample e) {
        String audioUrl = e.getAudioStatus() == ExampleAudioStatus.PUBLISHED ? e.getAudioUrl() : null;
        return new ProductionExampleDto(
                e.getId(),
                e.getTitre(),
                e.getResume(),
                e.getContenu(),
                e.getExplications(),
                audioUrl,
                e.getPlanPoints() != null ? e.getPlanPoints() : List.of(),
                e.getNiveauIndicatif()
        );
    }
}
