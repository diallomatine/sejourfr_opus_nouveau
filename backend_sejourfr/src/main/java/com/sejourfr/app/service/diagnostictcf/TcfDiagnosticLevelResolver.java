package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Le niveau d'une epreuve du diagnostic TCF, et le niveau global (10_ §4.3).
 *
 * <p><b>Composant pur</b> : il ne lit ni base ni horloge, on lui donne des
 * comptages et il rend un palier. C'est ce qui le rend testable aux frontieres
 * exactes des seuils, ce que la spec exige nommement.
 *
 * <p>🛑 <b>{@code null} = NON EVALUEE, jamais le palier le plus bas.</b> Une
 * epreuve que le candidat n'a pas passee n'a pas de niveau : elle sort du
 * minimum et s'affiche « non evaluee ». La confondre avec
 * {@code A1_NON_ATTEINT} reproduirait exactement l'incident V040/V041/V042, ou
 * une absence de mesure etait devenue un verdict.
 */
@Component
@RequiredArgsConstructor
public class TcfDiagnosticLevelResolver {

    private final TcfDiagnosticProperties props;

    /**
     * Niveau d'une epreuve de COMPREHENSION (CO ou CE), deterministe.
     *
     * <p>La regle se lit du haut vers le bas — on retient le palier le plus
     * eleve dont toutes les conditions sont tenues :
     * <pre>
     *   B2  si taux(A2) >= 0,80  et  taux(B1) >= 0,70  et  taux(B2) >= 0,60
     *   B1  si taux(A2) >= 0,80  et  taux(B1) >= 0,60
     *   A2  si taux(A2) >= 0,60
     *   A1  sinon
     * </pre>
     *
     * <p>Un palier superieur exige donc de tenir AUSSI les paliers inferieurs :
     * reussir les items B2 en echouant les A2 ne fait pas un B2, cela fait un
     * candidat irregulier — et le TCF, qui mesure une competence installee, le
     * traite comme tel.
     *
     * <p>Les taux sont calcules <b>palier par palier</b>, jamais sur le total :
     * 10 bonnes reponses sur 15 ne disent rien tant qu'on ignore lesquelles.
     *
     * @param bonnesParPalier bonnes reponses par palier d'item
     * @param posesParPalier  items reellement poses par palier (le denominateur
     *                        reel, qui peut etre inferieur au reglage si le
     *                        catalogue etait sous-dote — mode degrade 10_ §9)
     * @return le palier, ou {@code Optional.empty()} si l'epreuve n'a pas ete
     *         passee (aucun item pose)
     */
    public Optional<NiveauCecrl> niveauComprehension(
            Map<Difficulty, Integer> bonnesParPalier,
            Map<Difficulty, Integer> posesParPalier) {

        if (posesParPalier == null || totalPoses(posesParPalier) == 0) {
            // Aucune preuve : on ne conclut pas. Ce n'est pas un echec.
            return Optional.empty();
        }

        double tauxA2 = taux(bonnesParPalier, posesParPalier, Difficulty.A2);
        double tauxB1 = taux(bonnesParPalier, posesParPalier, Difficulty.B1);
        double tauxB2 = taux(bonnesParPalier, posesParPalier, Difficulty.B2);
        TcfDiagnosticProperties.Seuils s = props.getSeuils();

        if (tauxA2 >= s.getA2PourB1() && tauxB1 >= s.getB1PourB2() && tauxB2 >= s.getB2()) {
            return Optional.of(NiveauCecrl.B2);
        }
        if (tauxA2 >= s.getA2PourB1() && tauxB1 >= s.getB1()) {
            return Optional.of(NiveauCecrl.B1);
        }
        if (tauxA2 >= s.getA2()) {
            return Optional.of(NiveauCecrl.A2);
        }
        return Optional.of(NiveauCecrl.A1);
    }

    /**
     * Niveau d'une epreuve de PRODUCTION (EE ou EO) : le <b>minimum</b> des
     * niveaux de ses 3 taches.
     *
     * <p>Le minimum est retenu volontairement (10_ §4.3) : au TCF, une tache
     * ratee plafonne le resultat de l'epreuve. Les 3 taches etant toutes
     * evaluees au diagnostic, chacune garde par ailleurs son propre niveau —
     * c'est ce qui autorise le Plan a nommer une tache precise en priorite.
     *
     * <p>🛑 Une tache <b>non rendue</b> ou <b>inexploitable</b> n'a pas de
     * niveau et est simplement <b>absente</b> de la liste : elle ne tire pas
     * l'epreuve vers le bas. Une epreuve dont aucune tache n'a de niveau est
     * non evaluee.
     */
    public Optional<NiveauCecrl> niveauProduction(Collection<NiveauCecrl> niveauxDesTaches) {
        if (niveauxDesTaches == null) {
            return Optional.empty();
        }
        return niveauxDesTaches.stream()
                .filter(java.util.Objects::nonNull)
                .min(java.util.Comparator.comparingInt(TcfDiagnosticLevelResolver::rang));
    }

    /**
     * Niveau global : le <b>minimum des epreuves EVALUEES</b> (arbitrage A7).
     *
     * <p>Au TCF IRN le niveau requis doit etre atteint dans <i>chaque</i>
     * epreuve : le plancher est donc factuellement juste, et c'est lui qui
     * justifie naturellement le plan.
     *
     * <p>🛑 Les epreuves non evaluees sont <b>exclues</b>, jamais comptees au
     * plus bas — et l'ecran doit alors les signaler explicitement. Aucune
     * epreuve evaluee ⇒ pas de niveau global.
     */
    public Optional<NiveauCecrl> niveauGlobal(Collection<NiveauCecrl> niveauxDesEpreuves) {
        return niveauProduction(niveauxDesEpreuves);
    }

    /**
     * Distance en paliers entre un niveau et une cible, bornee a zero.
     *
     * <p>Sert au score de priorite (10_ §4.4). Une epreuve <b>au-dessus</b> de
     * la cible rend 0, jamais un ecart negatif qui reduirait le score d'une
     * autre epreuve par effet de bord.
     */
    public static int ecart(NiveauCecrl atteint, NiveauCecrl cible) {
        if (atteint == null || cible == null) {
            return 0;
        }
        return Math.max(0, rang(cible) - rang(atteint));
    }

    /**
     * Rang CECRL d'un niveau. {@code A1_NON_ATTEINT} vaut 0 : c'est un palier
     * plancher reel, pas une absence — l'absence, c'est {@code null}, qui n'a
     * pas de rang et n'arrive jamais ici.
     */
    public static int rang(NiveauCecrl niveau) {
        return switch (niveau) {
            case A1_NON_ATTEINT -> 0;
            case A1 -> 1;
            case A2 -> 2;
            case B1 -> 3;
            case B2 -> 4;
            case C1 -> 5;
            case C2 -> 6;
        };
    }

    /** Repartition attendue du tirage : {@code itemsPerLevel} par palier. */
    public Map<Difficulty, Integer> repartitionAttendue() {
        Map<Difficulty, Integer> attendu = new EnumMap<>(Difficulty.class);
        for (Difficulty d : List.of(Difficulty.A2, Difficulty.B1, Difficulty.B2)) {
            attendu.put(d, props.getItemsPerLevel());
        }
        return attendu;
    }

    private static double taux(
            Map<Difficulty, Integer> bonnes, Map<Difficulty, Integer> poses, Difficulty palier) {
        int denominateur = poses.getOrDefault(palier, 0);
        if (denominateur == 0) {
            // Palier non pose (catalogue sous-dote) : on ne peut rien exiger de
            // lui. Le compter 0 ferait echouer une condition que le candidat
            // n'a jamais eu l'occasion de tenir — c'est le mode degrade de
            // 10_ §9, qui ajuste les denominateurs au lieu d'inventer un echec.
            return 1.0;
        }
        int numerateur = bonnes == null ? 0 : bonnes.getOrDefault(palier, 0);
        return (double) numerateur / denominateur;
    }

    private static int totalPoses(Map<Difficulty, Integer> poses) {
        return poses.values().stream().mapToInt(v -> v == null ? 0 : v).sum();
    }
}
