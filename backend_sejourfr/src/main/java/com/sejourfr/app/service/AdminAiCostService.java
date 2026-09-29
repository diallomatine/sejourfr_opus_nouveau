package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminAiCostResponse;
import com.sejourfr.app.manager.AiUsageManager;
import com.sejourfr.app.util.FenetreMesure;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * <b>La supervision du cout IA</b> (lot L12, {@code 00_} §8.4).
 *
 * <p>Ce service ne mesure rien : il <b>lit</b> {@code v_ai_usage} (V048), qui
 * unifie les quatre endroits ou le depot ecrit deja son cout au moment ou il le
 * connait. Aucune cinquieme ecriture, donc aucune seconde verite a tenir a
 * jour.
 *
 * <h2>Ce que ce service refuse de faire</h2>
 * <ul>
 *   <li>🛑 <b>Additionner les deux colonnes de cout.</b> Millioniemes de dollar
 *       et centimes d'euro : deux unites, deux devises, deux epoques. Elles
 *       remontent cote a cote jusqu'a l'ecran.</li>
 *   <li>🛑 <b>Compter zero un cout inconnu.</b> {@code lignesSansCout} est
 *       expose partout. Sans lui, un total bas se lit « l'IA ne coute presque
 *       rien » alors qu'il se lit « on ne sait pas ce qu'elle a coute ».</li>
 *   <li>🛑 <b>Deviner un rattachement gratuit/abonne.</b> V048 le documente :
 *       savoir si un appel a ete paye par un quota gratuit exige l'etat de
 *       l'abonnement A L'INSTANT de l'appel, que rien ne persiste.</li>
 * </ul>
 *
 * <p>La fenetre est celle de {@link FenetreMesure}, reutilisee telle quelle :
 * une seconde definition de « les 30 derniers jours » finirait par afficher
 * deux periodes differentes sur deux ecrans de la meme console.
 */
@Service
@RequiredArgsConstructor
public class AdminAiCostService {

    private final AiUsageManager manager;

    @Transactional(readOnly = true)
    public AdminAiCostResponse lire(String from, String to, int days) {
        FenetreMesure fenetre = FenetreMesure.resolve(from, to, days);
        var debut = fenetre.startInstant();
        var fin = fenetre.endInstantExclusive();

        return new AdminAiCostResponse(
                fenetre.from(),
                fenetre.to(),
                ligneSansCle(manager.total(debut, fin)),
                lignes(manager.parFamille(debut, fin)),
                lignes(manager.parSource(debut, fin)),
                lignes(manager.parModele(debut, fin)),
                coutMoyen(
                        manager.diagnosticsClos(debut, fin),
                        manager.coutDiagnosticsMicroUsd(debut, fin)));
    }

    /**
     * Le cout moyen d'un diagnostic mene a terme.
     *
     * <p>🛑 <b>C'est un rapport de deux totaux de fenetre</b>, pas une moyenne
     * de couts par session : {@code v_ai_usage} ne porte pas l'identifiant de
     * soumission, et l'y ajouter demanderait de reecrire une vue livree. La
     * difference se voit sur les diagnostics a cheval sur les bornes ; elle
     * s'efface des que la fenetre depasse quelques jours.
     *
     * <p>🛑 <b>Aucun cout connu ⇒ {@code null}, jamais zero</b>, et aucune
     * session ⇒ pas de division.
     */
    private static AdminAiCostResponse.CoutMoyen coutMoyen(long sessions, Long totalMicroUsd) {
        if (sessions <= 0) {
            return new AdminAiCostResponse.CoutMoyen(0, null, totalMicroUsd);
        }
        Long moyenne = totalMicroUsd == null ? null : totalMicroUsd / sessions;
        return new AdminAiCostResponse.CoutMoyen(sessions, moyenne, totalMicroUsd);
    }

    /** Le total : meme forme, sans cle — l'agregat n'a pas de nom. */
    private static AdminAiCostResponse.Ligne ligneSansCle(List<Object[]> rows) {
        if (rows.isEmpty()) {
            return new AdminAiCostResponse.Ligne(null, 0, 0, null, null, null, null, null);
        }
        Object[] row = rows.getFirst();
        return new AdminAiCostResponse.Ligne(
                null,
                nombre(row[0]), nombre(row[1]),
                nombreOuNull(row[2]), nombreOuNull(row[3]), nombreOuNull(row[4]),
                nombreOuNull(row[5]), nombreOuNull(row[6]));
    }

    private static List<AdminAiCostResponse.Ligne> lignes(List<Object[]> rows) {
        return rows.stream()
                .map(row -> new AdminAiCostResponse.Ligne(
                        row[0] == null ? null : String.valueOf(row[0]),
                        nombre(row[1]), nombre(row[2]),
                        nombreOuNull(row[3]), nombreOuNull(row[4]), nombreOuNull(row[5]),
                        nombreOuNull(row[6]), nombreOuNull(row[7])))
                .toList();
    }

    private static long nombre(Object value) {
        return value instanceof Number n ? n.longValue() : 0L;
    }

    /**
     * 🛑 {@code null} reste {@code null}. Un {@code SUM} sur zero ligne, ou sur
     * des lignes toutes nulles, rend {@code NULL} en SQL : le transformer en
     * {@code 0} dirait « ca n'a rien coute » la ou la verite est « on ne sait
     * pas ».
     */
    private static Long nombreOuNull(Object value) {
        return value instanceof Number n ? n.longValue() : null;
    }
}
