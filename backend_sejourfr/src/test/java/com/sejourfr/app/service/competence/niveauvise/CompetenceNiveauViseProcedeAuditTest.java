package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;
import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * LE PROCEDE D'UN LEVIER — ce qu'on compte, et ce qu'on ne retire jamais.
 *
 * <p>Ce que verrouille cette classe :
 * <ul>
 *   <li>🛑 <b>aucun levier n'est jamais retire</b>, quel que soit son procede :
 *       les leviers portent le bloc entier, et le vider pour une etiquette serait
 *       l'inverse du but ;</li>
 *   <li>un procede manquant, inconnu ou qui SUR-VEND le palier cible est compte
 *       par un motif distinct, et n'est pas persiste — une valeur qu'on ne peut
 *       pas opposer ne repond a aucune question SQL ;</li>
 *   <li>un procede plus MODESTE que le palier cible reste legitime ;</li>
 *   <li>la table de compatibilite est celle des marqueurs, jamais une copie.</li>
 * </ul>
 */
class CompetenceNiveauViseProcedeAuditTest {

    private static Map<String, Object> levier(String action, String exemple, Object procede) {
        Map<String, Object> l = new LinkedHashMap<>();
        l.put(CompetenceNiveauViseFields.ACTION, action);
        l.put(CompetenceNiveauViseFields.EXEMPLE, exemple);
        if (procede != null) l.put(CompetenceNiveauViseFields.PROCEDE, procede);
        return l;
    }

    private static Object procede(Map<String, Object> levier) {
        return levier.get(CompetenceNiveauViseFields.PROCEDE);
    }

    @Test
    void unProcedeValideEstConserveEtNormalise() {
        CompetenceNiveauViseProcedeAudit.Resultat resultat =
            CompetenceNiveauViseProcedeAudit.inspecter(List.of(
                levier("Subordonne ta demande", "si jamais tu es libre", " subordination "),
                levier("Choisis un terme precis", "un gain considerable", "LEXIQUE_PRECIS")),
                TargetLevel.B1);

        assertThat(resultat.anomalies()).isEmpty();
        assertThat(resultat.leviers()).hasSize(2);
        assertThat(procede(resultat.leviers().get(0))).isEqualTo("SUBORDINATION");
        assertThat(procede(resultat.leviers().get(1))).isEqualTo("LEXIQUE_PRECIS");
    }

    /**
     * LE CAS QUI A MOTIVE v3 : « Rends ton invitation plus chaleureuse » n'est
     * porte par aucune operation de langue. Le levier est servi quand meme — le
     * candidat garde son plan d'action — mais l'anomalie est comptee.
     */
    @Test
    void unProcedeAbsentEstCompteEtLeLevierEstServiSansLui() {
        CompetenceNiveauViseProcedeAudit.Resultat resultat =
            CompetenceNiveauViseProcedeAudit.inspecter(List.of(
                levier("Rends ton invitation plus chaleureuse", "avec grand plaisir", null),
                levier("Termine par une formule engageante", "a tres bientot", "   ")),
                TargetLevel.B2);

        assertThat(resultat.leviers())
            .as("les leviers portent le bloc : on ne les purge jamais sur ce motif")
            .hasSize(2);
        assertThat(resultat.leviers()).allSatisfy(l ->
            assertThat(l).doesNotContainKey(CompetenceNiveauViseFields.PROCEDE));
        assertThat(resultat.anomalies()).extracting(
                CompetenceNiveauViseProcedeAudit.Anomalie::motif)
            .containsExactly(CompetenceNiveauViseProcedeAudit.Motif.ABSENT,
                CompetenceNiveauViseProcedeAudit.Motif.ABSENT);
        assertThat(resultat.anomalies().get(0).libelle())
            .contains("Rends ton invitation plus chaleureuse", "aucun procédé");
    }

    @Test
    void unProcedeInconnuEstCompteEtNEstPasPersiste() {
        CompetenceNiveauViseProcedeAudit.Resultat resultat =
            CompetenceNiveauViseProcedeAudit.inspecter(List.of(
                levier("Sois plus convaincant", "vraiment", "TON_CHALEUREUX")), TargetLevel.B1);

        assertThat(resultat.leviers()).hasSize(1);
        assertThat(procede(resultat.leviers().get(0)))
            .as("une valeur qu'on ne peut pas opposer ne repond a aucune question SQL")
            .isNull();
        assertThat(resultat.anomalies()).singleElement().satisfies(a -> {
            assertThat(a.motif()).isEqualTo(CompetenceNiveauViseProcedeAudit.Motif.INCONNU);
            assertThat(a.libelle()).contains("TON_CHALEUREUX");
        });
    }

    /** Sur-vente : une objection traitee ne demontre rien de la marche vers l'A2. */
    @Test
    void unProcedeQuiSurVendLePalierCibleEstCompteSansPurger() {
        CompetenceNiveauViseProcedeAudit.Resultat resultat =
            CompetenceNiveauViseProcedeAudit.inspecter(List.of(
                levier("Annonce l'objection", "On objectera que", "OBJECTION_TRAITEE")),
                TargetLevel.A2);

        assertThat(resultat.leviers()).hasSize(1);
        assertThat(procede(resultat.leviers().get(0))).isNull();
        assertThat(resultat.anomalies()).singleElement().satisfies(a ->
            assertThat(a.motif()).isEqualTo(CompetenceNiveauViseProcedeAudit.Motif.SUR_VENDU));
    }

    /**
     * ON NE COMPTE QUE LA SUR-VENTE, dans le sens sûr : un procede plus modeste
     * que le palier cible reste un moyen de langue legitime a travailler — meme
     * regle que {@code CompetenceNiveauViseMarqueurFilter}, meme table.
     */
    @Test
    void unProcedePlusModesteQueLePalierCibleResteLegitime() {
        CompetenceNiveauViseProcedeAudit.Resultat resultat =
            CompetenceNiveauViseProcedeAudit.inspecter(List.of(
                levier("Adapte ton salut au destinataire", "Madame, Monsieur",
                    "REGISTRE_AJUSTE")), TargetLevel.B2);

        assertThat(resultat.anomalies()).isEmpty();
        assertThat(procede(resultat.leviers().get(0))).isEqualTo("REGISTRE_AJUSTE");
    }

    @Test
    void aucunLevierRienAInspecter() {
        assertThat(CompetenceNiveauViseProcedeAudit.inspecter(List.of(), TargetLevel.B1).leviers())
            .isEmpty();
        assertThat(CompetenceNiveauViseProcedeAudit.inspecter(null, TargetLevel.B1).anomalies())
            .isEmpty();
    }
}
