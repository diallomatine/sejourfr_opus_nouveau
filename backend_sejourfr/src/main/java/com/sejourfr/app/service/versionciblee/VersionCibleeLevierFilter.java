package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.EvaluationMarqueursA2;

import java.util.ArrayList;
import java.util.List;

/**
 * FILET DETERMINISTE sur les leviers {@code version_ciblee.ce_qui_manque} : un
 * moyen que notre grille classe <b>A2</b> ne peut pas etre ce qui separe le
 * candidat d'un palier <b>superieur</b>.
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
 * de l'ecran : {@code version_ciblee} est desormais LE texte modele mis en
 * evidence sur un resultat EE, ses leviers juste en dessous. Le mauvais conseil
 * est passe de discret a proeminent.
 *
 * <h2>Pourquoi c'est plus SÛR ici que cote correcteur</h2>
 * Cote correcteur, le palier revendique doit se deviner dans la phrase
 * (« pour viser le B1... »). Ici il est <b>declare</b> : {@code niveau_vise} est un
 * champ structure du bloc, pose par le SERVEUR, jamais par le modele. La moitie
 * fragile du jugement disparait donc, et il ne reste que la detection du
 * marqueur, partagee mot pour mot avec l'autre filet
 * ({@link EvaluationMarqueursA2#designe(String)}) — a la deuxieme occurrence, on
 * extrait.
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
 *       (« Physiquement... mais... », « mais ce que j'apprecie surtout ») ne
 *       compte pas : l'egalite avec le marqueur doit etre exacte.</li>
 * </ul>
 *
 * <h2>Le levier tombe en ENTIER</h2>
 * On ne purge pas la phrase mais l'element de liste : la grille impose « une
 * seule phrase » par levier, et un demi-levier ne s'applique pas. Ce que fait le
 * service du trou ainsi cree — une reparation, puis l'abandon du bloc — est
 * documente dans {@code ProductionVersionCibleeService}.
 */
final class VersionCibleeLevierFilter {

    /**
     * @param gardes  leviers conserves, dans l'ordre rendu par le modele
     * @param retires leviers retires, pour le log, le compteur de purges et le
     *                message de reparation (qui les nomme un par un)
     */
    record Resultat(List<String> gardes, List<String> retires) {
    }

    private VersionCibleeLevierFilter() {
    }

    /**
     * @param leviers leviers deja valides (non nuls, non vides, sous plafond)
     * @param vise    palier VISE par le candidat, pose par le serveur. Null ou
     *                A2 : rien n'est purge.
     */
    static Resultat purge(List<String> leviers, TargetLevel vise) {
        if (leviers == null || leviers.isEmpty()) return new Resultat(List.of(), List.of());
        if (!marqueursA2SousLeNiveauVise(vise)) return new Resultat(List.copyOf(leviers), List.of());

        List<String> gardes = new ArrayList<>();
        List<String> retires = new ArrayList<>();
        for (String levier : leviers) {
            if (EvaluationMarqueursA2.designe(levier)) {
                retires.add(levier);
            } else {
                gardes.add(levier);
            }
        }
        return new Resultat(gardes, retires);
    }

    /**
     * Vrai quand les marqueurs de {@link EvaluationMarqueursA2#MARQUEURS_A2} sont
     * classes <b>au niveau vise ou en dessous</b> — c'est-a-dire des que le
     * candidat vise plus haut que A2. Les designer comme la marche suivante n'a
     * alors aucun sens : il les emploie deja.
     */
    private static boolean marqueursA2SousLeNiveauVise(TargetLevel vise) {
        return vise != null
            && NiveauCecrl.valueOf(vise.name()).ordinal() > NiveauCecrl.A2.ordinal();
    }
}
