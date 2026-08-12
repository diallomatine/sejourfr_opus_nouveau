package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.EvaluationMarqueursA2;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * FILET DETERMINISTE sur les leviers « pour viser X » : un moyen que notre
 * grille classe <b>A2</b> ne peut pas etre ce qui separe le candidat d'un palier
 * <b>superieur</b>.
 *
 * <h2>Le meme defaut, une troisieme fois</h2>
 * Il a ete releve en base sur la restitution du correcteur
 * ({@code EvaluationPalierMarqueurFilter}) puis sur les leviers de la version au
 * niveau vise ({@code VersionCibleeLevierFilter}) : un bloc annonçant le B1
 * conseillait « et », « mais », « donc » comme les connecteurs a employer, alors
 * que notre propre rubrique exige, pour depasser A2, des connecteurs organisant
 * le propos « au-dela de et / mais / parce que ». Un candidat a suivi ce conseil,
 * a resoumis, et a obtenu la meme evaluation.
 *
 * <p><b>La liste des marqueurs n'est pas recopiee ici</b> : elle vit une seule
 * fois dans {@link EvaluationMarqueursA2}, tout comme la reconnaissance d'un
 * marqueur DESIGNE et le garde-fou des formules de rejet. Trois detections
 * ecrites separement, ce sont trois frontieres qui divergent au premier
 * ajustement.
 *
 * <h2>Pourquoi le levier est inspecte comme une citation</h2>
 * Un levier est un couple {@code {action, exemple}}, et {@code exemple} est par
 * definition un bout de langue a recopier. Le cas fautif type, ici, c'est
 * {@code exemple = "parce que"} — un marqueur A2 servi comme la cle du B1. Il est
 * donc inspecte <b>entre guillemets</b>, ce qu'il est semantiquement, et le filet
 * partage y voit une citation. L'{@code action}, elle, est inspectee telle
 * quelle : une formule de rejet qu'elle contiendrait (« au lieu de poser "mais"
 * seul ») masque la suite, exactement comme ailleurs — c'est le sens SÛR de
 * l'erreur.
 *
 * <h2>Frontieres — en cas de doute, on ne purge pas</h2>
 * <ul>
 *   <li><b>Rien n'est purge quand le niveau vise est A2</b> : « parce que » est
 *       alors exactement le moyen a conseiller ;</li>
 *   <li>un marqueur <b>rejete</b> par le levier ne compte pas ;</li>
 *   <li>une formule qui <b>contient</b> un marqueur sans s'y reduire
 *       (« ce qui me permettrait de ») ne compte pas : l'egalite avec le marqueur
 *       doit etre exacte.</li>
 * </ul>
 *
 * <p><b>Le levier tombe en ENTIER</b> : action et exemple forment un couple, un
 * demi-levier ne s'applique pas. Ce que fait le service du trou ainsi cree — une
 * reparation, puis l'abandon du bloc — est documente dans
 * {@link CompetenceNiveauViseService}.
 */
final class CompetenceNiveauViseLevierFilter {

    /**
     * @param gardes  leviers conserves, dans l'ordre rendu par le modele
     * @param retires leviers retires, pour le log, le compteur de purges et le
     *                message de reparation (qui les nomme un par un)
     */
    record Resultat(List<Map<String, Object>> gardes, List<Map<String, Object>> retires) {
    }

    private CompetenceNiveauViseLevierFilter() {
    }

    /**
     * @param leviers leviers deja valides (objets complets, champs non vides)
     * @param vise    palier VISE par le candidat, pose par le serveur. Null ou
     *                A2 : rien n'est purge.
     */
    static Resultat purge(List<Map<String, Object>> leviers, TargetLevel vise) {
        if (leviers == null || leviers.isEmpty()) return new Resultat(List.of(), List.of());
        if (!EvaluationMarqueursA2.sousLeNiveauVise(vise)) {
            return new Resultat(List.copyOf(leviers), List.of());
        }

        List<Map<String, Object>> gardes = new ArrayList<>();
        List<Map<String, Object>> retires = new ArrayList<>();
        for (Map<String, Object> levier : leviers) {
            if (designeUnMarqueurA2(levier)) {
                retires.add(levier);
            } else {
                gardes.add(levier);
            }
        }
        return new Resultat(gardes, retires);
    }

    /**
     * Le levier vendu comme phrase inspectable : l'action telle quelle, puis
     * l'exemple entre guillemets — c'est ce qu'il est, un bout de langue cite.
     */
    static boolean designeUnMarqueurA2(Map<String, Object> levier) {
        String action = texte(levier.get(CompetenceNiveauViseFields.ACTION));
        String exemple = texte(levier.get(CompetenceNiveauViseFields.EXEMPLE));
        String phrase = action.isEmpty() ? "" : action;
        if (!exemple.isEmpty()) {
            phrase = phrase.isEmpty() ? "« " + exemple + " »" : phrase + " : « " + exemple + " »";
        }
        return EvaluationMarqueursA2.designe(phrase);
    }

    /** Libelle court d'un levier, pour un log ou un message de reparation. */
    static String libelle(Map<String, Object> levier) {
        String action = texte(levier.get(CompetenceNiveauViseFields.ACTION));
        String exemple = texte(levier.get(CompetenceNiveauViseFields.EXEMPLE));
        if (exemple.isEmpty()) return action;
        return action + " — « " + exemple + " »";
    }

    private static String texte(Object valeur) {
        return valeur == null ? "" : valeur.toString().trim();
    }
}
