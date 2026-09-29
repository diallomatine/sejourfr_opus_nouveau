package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.ProductionTaskDto;
import com.sejourfr.app.entity.AgentRoleCard;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.AgentInfoImportance;
import com.sejourfr.app.enums.AgentRelation;
import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ProductionTaskMapperTest {

    private final ProductionTaskMapper mapper = new ProductionTaskMapper();

    @Test
    void toDto_mapsEveryField() {
        UUID id = UUID.randomUUID();
        ProductionTask task = new ProductionTask();
        task.setId(id);
        task.setEpreuve(EpreuveType.TCF_EE);
        task.setTacheNumero((short) 2);
        task.setNiveauCible("B1");
        task.setConsigne("Rédigez un message");
        task.setContexte("Vous écrivez à un ami");
        task.setDureeMaxSec(600);
        task.setDureeMinSec(120);
        task.setMotsMin(60);
        task.setMotsMax(120);

        ProductionTaskDto dto = mapper.toDto(task);

        assertThat(dto.id()).isEqualTo(id);
        assertThat(dto.epreuve()).isEqualTo(EpreuveType.TCF_EE);
        assertThat(dto.tacheNumero()).isEqualTo((short) 2);
        assertThat(dto.niveauCible()).isEqualTo("B1");
        assertThat(dto.consigne()).isEqualTo("Rédigez un message");
        assertThat(dto.contexte()).isEqualTo("Vous écrivez à un ami");
        assertThat(dto.dureeMaxSec()).isEqualTo(600);
        assertThat(dto.dureeMinSec()).isEqualTo(120);
        assertThat(dto.motsMin()).isEqualTo(60);
        assertThat(dto.motsMax()).isEqualTo(120);
    }

    @Test
    void toDto_nullTacheNumero_defaultsToZero() {
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero(null);
        task.setNiveauCible("A2");
        task.setConsigne("Présentez-vous");

        ProductionTaskDto dto = mapper.toDto(task);

        assertThat(dto.tacheNumero()).isEqualTo((short) 0);
        assertThat(dto.contexte()).isNull();
        assertThat(dto.dureeMaxSec()).isNull();
        assertThat(dto.motsMin()).isNull();
    }

    @Test
    void toDto_neverLeaksTheAgentRoleCard() {
        // Les `valeur` de la fiche T2 sont les reponses que le candidat doit
        // obtenir en questionnant l'examinateur : rien de la fiche ne doit
        // atteindre un client, sous aucune forme.
        ProductionTask task = new ProductionTask();
        task.setId(UUID.randomUUID());
        task.setEpreuve(EpreuveType.TCF_EO);
        task.setTacheNumero((short) 2);
        task.setNiveauCible("B1");
        task.setConsigne("Vous appelez le service après-vente.");
        task.setContexte("L'examinateur joue le conseiller.");
        task.setDureeMaxSec(210);
        task.setAgentRoleCard(new AgentRoleCard(
                "Conseiller du service après-vente",
                AgentRelation.INCONNU_VOUVOIEMENT,
                "Obtenir une réparation.",
                "Service après-vente, bonjour.",
                List.of(new AgentRoleCard.Info("delai", "Le délai est de trois semaines.", AgentInfoImportance.HAUTE)),
                List.of(new AgentRoleCard.Info("pret", "Aucun appareil de prêt.", AgentInfoImportance.BASSE)),
                List.of("Tu proposes d'abord la réparation.")));

        String json = new ObjectMapper().writeValueAsString(mapper.toDto(task));

        assertThat(json)
                .doesNotContain("agentRoleCard")
                .doesNotContain("trois semaines")
                .doesNotContain("Aucun appareil de prêt")
                .doesNotContain("Service après-vente, bonjour")
                .contains("Vous appelez le service après-vente.");
    }
}
