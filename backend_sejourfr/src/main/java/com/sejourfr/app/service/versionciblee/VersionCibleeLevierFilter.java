package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.EvaluationMarqueursA2;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * FILET DETERMINISTE sur les leviers de la version au niveau vise : un moyen que
 * notre grille classe <b>A2</b> ne peut pas etre ce qui separe le candidat d'un
 * palier <b>superieur</b>.
 *
 * <h2>Le defaut, verbatim, releve en base</h2>
 * Un bloc {@code niveau_vise: B1} portait le levier « Relier les phrases avec des
 * connecteurs simples : « et », « mais », « donc » au lieu de juxtaposer des
 * idees sans lien ». Or « et » et « mais » sont classes A2 par notre propre
 * rubrique, qui exige justement, pour depasser A2, des connecteurs organisant le
 * propos « au-dela de et / mais / parce que / apres / aussi ». Le levier etait
 * donc <b>structurellement incapable</b> de faire progresser le candidat — meme
 * defaut que celui corrige cote correcteur par
 * {@code EvaluationPalierMarqueurFilter}, sous un autre contrat.
 *
 * <p>Il est devenu urgent le jour ou les fronts ont retire {@code version_amelioree}
 * de l'ecran : {@code version_ciblee} est desormais LE plan d'action mis en
 * evidence sur un resultat de production. Le mauvais conseil est passe de discret
 * a proeminent.
 *
 * <h2>Pourquoi c'est plus SÛR ici que cote correcteur</h2>
 * Cote correcteur, le palier revendique doit se deviner dans la phrase
 * (« pour viser le B1... »). Ici il est <b>declare</b> : {@code niveau_vise} est un
 * champ structure du bloc, pose par le SERVEUR, jamais par le modele. La moitie
 * fragile du jugement disparait donc, et il ne reste que la detection du
 * marqueur, partagee mot pour mot avec l'autre filet
 * ({@link EvaluationMarqueursA2#designe(String)}) — la liste n'est recopiee nulle
 * part.
 *
 * <h2>Deux formes de levier, une seule regle</h2>
 * <ul>
 *   <li>contrat v1 : le levier est une PHRASE de 25 mots, inspectee telle
 *       quelle ;</li>
 *   <li>contrat v2 : le levier est un couple {@code {action, exemple}}, et
 *       {@code exemple} est par definition un bout de langue a recopier. Le cas
 *       fautif type y devient {@code exemple = "parce que"} — un marqueur A2
 *       servi comme la cle du B1. Il est donc inspecte <b>entre guillemets</b>,
 *       ce qu'il est semantiquement, et le filet partage y voit une citation.
 *       L'{@code action}, elle, est inspectee telle quelle : une formule de rejet
 *       qu'elle contiendrait (« au lieu de poser "mais" seul ») masque la suite,
 *       exactement comme ailleurs — c'est le sens SÛR de l'erreur.</li>
 * </ul>
 *
 * <h2>Frontieres — en cas de doute, on ne purge pas</h2>
 * <ul>
 *   <li><b>Rien n'est purge quand le niveau vise est A2</b> : « parce que » est
 *       alors exactement le moyen a conseiller, et c'est meme ce qu'ordonne une
 *       ancre de la grille de notation ;</li>
 *   <li>un marqueur <b>rejete</b> par le levier (« ... au lieu de poser "mais"
 *       seul », formulation de notre propre ancre few-shot) ne compte pas :
 *       {@link EvaluationMarqueursA2} ignore tout ce qui suit une formule de
 *       rejet ;</li>
 *   <li>une citation qui <b>contient</b> un marqueur sans s'y reduire
 *       (« ce qui me permettrait de ») ne compte pas : l'egalite avec le marqueur
 *       doit etre exacte.</li>
 * </ul>
 *
 * <h2>Le levier tombe en ENTIER</h2>
 * On ne purge pas la phrase mais l'element de liste : action et exemple forment
 * un couple, et un demi-levier ne s'applique pas. Ce que fait le service du trou
 * ainsi cree — une reparation, puis l'abandon du bloc — est documente dans
 * {@link ProductionVersionCibleeService}.
 */
final class VersionCibleeLevierFilter {

    /**
     * @param gardes  leviers conserves, dans l'ordre rendu par le modele
     * @param retires leviers retires, pour le log, le compteur de purges et le
     *                message de reparation (qui les nomme un par un)
     */
    record Resultat(List<Object> gardes, List<Object> retires) {
    }

    private VersionCibleeLevierFilter() {
    }

    /**
     * @param leviers leviers deja valides ; chaine sous le contrat v1, couple
     *                {@code {action, exemple}} sous le contrat v2.
     * @param vise    palier VISE par le candidat, pose par le serveur. Null ou
     *                A2 : rien n'est purge.
     */
    static Resultat purge(List<Object> leviers, TargetLevel vise) {
        if (leviers == null || leviers.isEmpty()) return new Resultat(List.of(), List.of());
        if (!EvaluationMarqueursA2.sousLeNiveauVise(vise)) {
            return new Resultat(List.copyOf(leviers), List.of());
        }

        List<Object> gardes = new ArrayList<>();
        List<Object> retires = new ArrayList<>();
        for (Object levier : leviers) {
            if (EvaluationMarqueursA2.designe(phraseInspectable(levier))) {
                retires.add(levier);
            } else {
                gardes.add(levier);
            }
        }
        return new Resultat(gardes, retires);
    }

    /**
     * Le levier vendu comme phrase inspectable : sous v2, l'action telle quelle
     * puis l'exemple entre guillemets — c'est ce qu'il est, un bout de langue
     * cite.
     */
    static String phraseInspectable(Object levier) {
        if (!(levier instanceof Map<?, ?> couple)) return texte(levier);
        String action = texte(couple.get(VersionCibleeFields.ACTION));
        String exemple = texte(couple.get(VersionCibleeFields.EXEMPLE));
        if (exemple.isEmpty()) return action;
        return action.isEmpty() ? "« " + exemple + " »" : action + " : « " + exemple + " »";
    }

    /** Libelle court d'un levier, pour un log ou un message de reparation. */
    static String libelle(Object levier) {
        if (!(levier instanceof Map<?, ?> couple)) return texte(levier);
        String action = texte(couple.get(VersionCibleeFields.ACTION));
        String exemple = texte(couple.get(VersionCibleeFields.EXEMPLE));
        if (exemple.isEmpty()) return action;
        return action + " — « " + exemple + " »";
    }

    private static String texte(Object valeur) {
        return valeur == null ? "" : valeur.toString().trim();
    }
}
