package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionExampleDto;
import com.sejourfr.app.dto.ProductionSituationDto;
import com.sejourfr.app.dto.ProductionSituationMediaDto;
import com.sejourfr.app.entity.ProductionExample;
import com.sejourfr.app.entity.ProductionSituation;
import com.sejourfr.app.entity.ProductionSituationMedia;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Mapping pur des situations d'entrainement. Le service lui passe la situation
 * et ses supports / exemples deja charges (le mapper ne touche aucun repo).
 */
@Component
public class ProductionSituationMapper {

    public ProductionSituationDto toDto(ProductionSituation situation,
                                        List<ProductionSituationMedia> medias) {
        return new ProductionSituationDto(
                situation.getId(),
                situation.getTaskId(),
                situation.getTitre(),
                situation.getContexte(),
                situation.getConsigne(),
                situation.getRoleCandidat(),
                situation.getRoleExaminateur(),
                situation.getObjectif(),
                toDeclencheur(situation.getDeclencheur()),
                toEtapes(situation.getEtapes()),
                situation.getNiveauIndicatif(),
                medias.stream().map(this::toMediaDto).toList()
        );
    }

    public ProductionSituationMediaDto toMediaDto(ProductionSituationMedia media) {
        return new ProductionSituationMediaDto(
                media.getId(),
                media.getType(),
                media.getImageUrl(),
                media.getInlineSvg(),
                media.getLegende(),
                media.getAltText()
        );
    }

    public ProductionExampleDto toExampleDto(ProductionExample example) {
        return new ProductionExampleDto(
                example.getId(),
                example.getTitre(),
                example.getResume(),
                example.getContenu(),
                example.getAudioUrl(),
                example.getPlanPoints() != null ? example.getPlanPoints() : List.of(),
                example.getNiveauIndicatif()
        );
    }

    private ProductionSituationDto.Declencheur toDeclencheur(Map<String, Object> raw) {
        if (raw == null || raw.isEmpty()) return null;
        return new ProductionSituationDto.Declencheur(
                str(raw.get("expediteur")),
                str(raw.get("avatar")),
                str(raw.get("texte"))
        );
    }

    private List<ProductionSituationDto.Etape> toEtapes(List<Map<String, Object>> raw) {
        if (raw == null || raw.isEmpty()) return List.of();
        return raw.stream()
                .map(m -> new ProductionSituationDto.Etape(
                        str(m.get("icon")),
                        str(m.get("titre")),
                        str(m.get("aide"))))
                .toList();
    }

    private String str(Object value) {
        return value == null ? null : value.toString();
    }
}
