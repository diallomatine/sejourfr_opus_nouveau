package com.sejourfr.app.service.progres;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import com.sejourfr.app.support.AbstractIntegrationTest;
import com.sejourfr.app.support.TestData;
import jakarta.persistence.EntityManager;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 🛑 <b>Le niveau CECRL d'un QCM n'est plus persisté : il se dérive des
 * réponses. Ce test garantit que cette dérivation ne coûte JAMAIS une requête
 * par ligne affichée.</b>
 *
 * <p>C'est le risque que la bascule du 2026-09-20 introduit et le seul qui ne
 * se voie pas en test unitaire : chaque écran de LISTE — historique, profil
 * TCF, « Voir mes résultats », liste des examens blancs — lisait avant une
 * colonne déjà chargée avec la ligne. Il lit maintenant un agrégat, et une
 * boucle d'appels unitaires y ferait un N+1 invisible.
 *
 * <p>⚠️ <b>Les assertions sont des ÉGALITÉS, jamais des {@code <=}.</b> Un
 * {@code <=} laisse passer exactement ce qu'on cherche à interdire : il reste
 * vrai tant que le nombre de requêtes est « raisonnable », et un N+1 sur trois
 * lignes de fixture l'est toujours. Le vrai test est que le compte ne bouge pas
 * quand le nombre de tentatives est multiplié.
 */
class NiveauQcmDeriveSansNPlusUnIT extends AbstractIntegrationTest {

    @Autowired private TestData data;
    @Autowired private TcfLevelEstimatorService levelEstimator;
    @Autowired private EpreuveHistoriqueService historiqueService;
    @Autowired private EntityManager entityManager;

    /**
     * L'autorité elle-même : les niveaux de N tentatives coûtent
     * <b>exactement une</b> requête, que N vaille 1 ou 6.
     */
    @Test
    @DisplayName("🛑 niveauxQcm : UNE requête, que la page porte 1 tentative ou 6")
    void niveauxQcm_couteExactementUneRequete_quelQueSoitLeNombreDeTentatives() {
        User user = data.user();
        List<UUID> une = new ArrayList<>();
        une.add(data.examenQcmTcfPasse(user, EpreuveType.TCF_CO, NiveauCecrl.B1).getId());

        List<UUID> six = new ArrayList<>(une);
        for (int i = 0; i < 5; i++) {
            six.add(data.examenQcmTcfPasse(user, EpreuveType.TCF_CO, NiveauCecrl.A2).getId());
        }

        assertThat(compterRequetes(() -> levelEstimator.niveauxQcm(une))).isEqualTo(1);
        assertThat(compterRequetes(() -> levelEstimator.niveauxQcm(six))).isEqualTo(1);

        // Et la dérivation est bien réelle : le palier sort des réponses.
        assertThat(levelEstimator.niveauxQcm(six))
                .hasSize(6)
                .containsEntry(une.get(0), NiveauCecrl.B1)
                .containsValue(NiveauCecrl.A2);
    }

    /**
     * L'écran « Voir mes résultats » de bout en bout : <b>deux</b> requêtes —
     * les sessions, puis leurs niveaux — et ce compte ne bouge pas quand le
     * candidat a six examens au lieu d'un.
     */
    @Test
    @DisplayName("🛑 « Voir mes résultats » : 2 requêtes pour 1 examen comme pour 6")
    void historiqueDEpreuve_neGrossitPasAvecLeNombreDExamens() {
        User unSeul = data.user();
        data.examenQcmTcfPasse(unSeul, EpreuveType.TCF_CE, NiveauCecrl.B1);

        User sixExamens = data.user();
        for (int i = 0; i < 6; i++) {
            data.examenQcmTcfPasse(sixExamens, EpreuveType.TCF_CE, NiveauCecrl.A2);
        }

        long avecUn = compterRequetes(
                () -> historiqueService.historique(unSeul.getId(), EpreuveType.TCF_CE));
        long avecSix = compterRequetes(
                () -> historiqueService.historique(sixExamens.getId(), EpreuveType.TCF_CE));

        assertThat(avecUn).isEqualTo(2);
        assertThat(avecSix).isEqualTo(2);
    }

    /** Requêtes préparées émises par {@code action}, session vidée au préalable. */
    private long compterRequetes(Runnable action) {
        entityManager.flush();
        entityManager.clear();
        Statistics statistics = entityManager.getEntityManagerFactory()
                .unwrap(SessionFactory.class).getStatistics();
        statistics.setStatisticsEnabled(true);
        statistics.clear();
        action.run();
        return statistics.getPrepareStatementCount();
    }
}
