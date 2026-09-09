package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Comparator;
import java.util.List;
import java.util.Objects;

/**
 * Le classement des priorites du diagnostic TCF (10_ §4.4).
 *
 * <p><b>Composant pur.</b> On lui donne l'etat mesure de chaque tache, il rend
 * une liste ordonnee et bornee. Aucune lecture de base, aucune horloge.
 *
 * <p>🛑 <b>Une priorite porte sur une TACHE, pas sur une competence</b>
 * (arbitrage A5) : « Expression orale, tache 3 » se comprend, « eo_nuancer »
 * non. Les competences fines restent internes et servent a expliquer.
 */
@Component
@RequiredArgsConstructor
public class TcfDiagnosticPriorityResolver {

    private final TcfDiagnosticProperties props;

    /**
     * Etat mesure d'une tache candidate a devenir une priorite.
     *
     * @param epreuve         l'epreuve dont la tache releve
     * @param taskCode        « EE1 »… « EO3 » ; {@code null} en comprehension,
     *                        ou la priorite porte sur l'epreuve entiere
     * @param niveauTache     niveau observe sur cette tache, {@code null} si non
     *                        evaluee
     * @param niveauEpreuve   niveau de l'epreuve, {@code null} si non evaluee
     * @param aTravailler     nombre de competences jugees « a travailler »
     * @param fragiles        nombre de competences jugees « fragiles »
     */
    public record TacheMesuree(
            EpreuveType epreuve,
            String taskCode,
            NiveauCecrl niveauTache,
            NiveauCecrl niveauEpreuve,
            int aTravailler,
            int fragiles) {
    }

    /** Une priorite retenue, avec le score qui l'a fait retenir. */
    public record Priorite(
            EpreuveType epreuve,
            String taskCode,
            NiveauCecrl niveauTache,
            NiveauCecrl niveauEpreuve,
            int score,
            int rang) {
    }

    /**
     * Les priorites du diagnostic, triees et bornees a
     * {@code maxPriorites} (3 par defaut, arbitrage A6).
     *
     * <p>Score, tel que la spec le fixe :
     * <pre>
     *   gap_tache     = distance(niveau_tache,   cible)     // 0..3
     *   gap_epreuve   = distance(niveau_epreuve, cible)
     *   severite      = 2 x (competences a travailler) + 1 x (fragiles)
     *   poids_epreuve = 1,0 si l'epreuve est SOUS la cible, 0,3 sinon
     *
     *   score = (3 x gap_tache + 2 x gap_epreuve + severite) x poids_epreuve
     * </pre>
     *
     * <p>Le poids d'epreuve est ce qui empeche une tache un peu faible d'une
     * epreuve <b>deja au niveau</b> de passer devant une vraie difficulte : il
     * ne l'annule pas (une observation reste une observation), il la range
     * derriere.
     *
     * <p>🛑 <b>Une epreuve deja au niveau cible ne genere AUCUNE priorite</b>
     * (10_ §4.4) : elle apparait dans « Deja au niveau attendu ». Le poids de
     * 0,3 ne concerne donc que les taches faibles d'une epreuve qui, elle,
     * reste sous la cible par ailleurs.
     *
     * <p>🛑 <b>Une tache NON EVALUEE ne peut pas devenir une priorite</b>
     * (test de garde exige par 10_ §13). Nommer « EO tache 2 » sans l'avoir
     * evaluee rendrait la personnalisation fictive — c'est la faute produit que
     * l'arbitrage A2 existe pour empecher.
     *
     * <p>Egalites tranchees <b>EO &gt; EE &gt; CE &gt; CO</b> : l'expression est
     * ce qui bloque le plus souvent et se travaille le mieux. A epreuve egale,
     * l'ordre des taches (1, 2, 3) departage — pour qu'un meme diagnostic rende
     * toujours le meme classement.
     */
    public List<Priorite> priorites(List<TacheMesuree> taches, NiveauCecrl cible) {
        if (taches == null || cible == null) {
            return List.of();
        }

        List<Priorite> retenues = taches.stream()
                .filter(Objects::nonNull)
                // Non evaluee ⇒ jamais une priorite. Garde dure, pas un filtre
                // de confort : c'est elle qui empeche de nommer une tache dont
                // on ne sait rien.
                .filter(t -> t.niveauTache() != null)
                // Epreuve deja au niveau cible ⇒ rien a prioriser dessus.
                .filter(t -> TcfDiagnosticLevelResolver.ecart(t.niveauEpreuve(), cible) > 0)
                .map(t -> new Priorite(
                        t.epreuve(), t.taskCode(), t.niveauTache(), t.niveauEpreuve(),
                        score(t, cible), 0))
                .filter(p -> p.score() > 0)
                .sorted(Comparator
                        .comparingInt(Priorite::score).reversed()
                        .thenComparingInt(p -> ordreEpreuve(p.epreuve()))
                        .thenComparing(p -> p.taskCode() == null ? "" : p.taskCode()))
                .limit(props.getMaxPriorites())
                .toList();

        // Le rang est pose APRES le tri : c'est une position d'affichage, pas
        // une propriete de la tache.
        return java.util.stream.IntStream.range(0, retenues.size())
                .mapToObj(i -> {
                    Priorite p = retenues.get(i);
                    return new Priorite(
                            p.epreuve(), p.taskCode(), p.niveauTache(), p.niveauEpreuve(),
                            p.score(), i + 1);
                })
                .toList();
    }

    /** Le score brut d'une tache. Visible pour le test, jamais pour le candidat. */
    int score(TacheMesuree t, NiveauCecrl cible) {
        int gapTache = TcfDiagnosticLevelResolver.ecart(t.niveauTache(), cible);
        int gapEpreuve = TcfDiagnosticLevelResolver.ecart(t.niveauEpreuve(), cible);
        int severite = 2 * Math.max(0, t.aTravailler()) + Math.max(0, t.fragiles());
        boolean sousObjectif = gapEpreuve > 0;

        int brut = 3 * gapTache + 2 * gapEpreuve + severite;
        // Le poids s'applique en entier puis s'arrondit : un score est un rang,
        // pas une mesure — on ne transporte pas de decimale jusqu'a l'ecran.
        return sousObjectif ? brut : (int) Math.round(brut * 0.3);
    }

    /**
     * Ordre de departage a score egal : EO, EE, CE, CO.
     *
     * <p>Ce n'est pas un gout : l'expression est ce qui bloque le plus souvent
     * un candidat et ce qui repond le mieux a l'entrainement.
     */
    private static int ordreEpreuve(EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_EO -> 0;
            case TCF_EE -> 1;
            case TCF_CE -> 2;
            case TCF_CO -> 3;
            default -> 9;
        };
    }
}
