package com.sejourfr.app.service;

import com.sejourfr.app.enums.NiveauCecrl;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * FILET DETERMINISTE contre le CONSEIL QUI NE FAIT PAS PROGRESSER : un moyen que
 * la grille active classe <b>A2</b> presente au candidat comme la cle du palier
 * <b>superieur</b>.
 *
 * <h2>L'incident</h2>
 * Une evaluation reelle affirmait, dans {@code exemples_corriges[].gain} :
 * « cette version emploie une subordonnee causale avec <b>« parce que »</b>,
 * <b>marqueur attendu au B1</b> », et dans {@code suggestions} : « Pour viser le
 * palier B1, essaie d'ajouter ... « j'aime discuter avec elle <b>parce qu'</b>elle
 * est tres agreable ». » Le proprietaire a suivi le conseil a la lettre, a
 * resoumis, et a obtenu <b>exactement la meme note</b>.
 *
 * <p>C'est faux au regard de notre propre rubrique, qui le dit deux fois :
 * le descripteur A2 de EE_T1 (« phrases simples coordonnees (parce que, mais,
 * alors) ») et le plafond A2, qui exige des connecteurs organisant le propos
 * « au-dela de <b>et / mais / parce que / apres / aussi</b> ». Le conseil etait
 * donc <b>structurellement incapable</b> de faire progresser le candidat.
 *
 * <h2>Pourquoi un filet et pas une consigne</h2>
 * La rubrique dit DEJA la bonne chose, et le correcteur s'est contredit lui-meme
 * dans la meme evaluation (« marqueurs A2 citables » ailleurs). Rajouter du texte
 * a la grille est exactement ce que le depot a mesure comme DEGRADANT (rubriques
 * v10/v11 : accord exact 81,8 % → 75,6 %). On applique donc l'ordre de preference
 * du depot : contrainte dure d'abord, controle serveur ensuite, consigne en
 * dernier.
 *
 * <h2>Ce que ce filet ne touche pas</h2>
 * <b>Ni la note, ni le niveau, ni un seuil, ni un bareme</b> — meme garantie que
 * {@link EvaluationOralArtifactFilter}. Il ne lit que des champs de restitution,
 * apres que la note et le niveau ont ete calcules. Sont hors de son perimetre :
 * <ul>
 *   <li>{@code justification_niveau} : raisonnement INTERNE du correcteur,
 *       expurge avant le front — il n'est jamais lu par le candidat ;</li>
 *   <li>les champs de CITATION ({@code points_a_ameliorer[].exemple.avant},
 *       {@code exemples_corriges[].original}) : ils recopient le candidat mot pour
 *       mot, et sa production contient evidemment des « parce que » ;</li>
 *   <li>{@code scores_criteres[].commentaire} : il CARACTERISE la langue observee,
 *       il ne promet pas de palier.</li>
 * </ul>
 *
 * <h2>Regle de purge — en cas de doute, on ne purge pas</h2>
 * Une phrase n'est retiree que si elle reunit les DEUX conditions :
 * <ol>
 *   <li>elle revendique un palier <b>strictement au-dessus de A2</b> : « B1 » ou
 *       « B2 » nommes, ou une formule relative (« gagner un niveau », « le palier
 *       au-dessus ») quand le niveau CONSTATE est deja A2 ou plus. Une phrase qui
 *       vise A2 depuis A1 est <b>legitime</b> — c'est meme ce qu'ordonne une ancre
 *       de la rubrique active ;</li>
 *   <li>elle DESIGNE un marqueur A2 comme le moyen d'y arriver — jugement
 *       delegue a {@link EvaluationMarqueursA2#designe(String)}, partage avec le
 *       filet des leviers {@code version_ciblee.ce_qui_manque}.</li>
 * </ol>
 *
 * <p>La seconde condition seule ne suffit jamais ici : c'est la promesse de
 * palier qui rend le conseil faux, pas le mot lui-meme.
 *
 * <h2>Frontieres MESUREES sur les donnees reelles</h2>
 * Regle passee sur les <b>707 champs de restitution</b> des 138 evaluations en
 * base : <b>5 phrases purgees, toutes fautives, aucun faux positif</b>. Les
 * variantes plus larges ont ete rejetees sur ces memes donnees, chacune produisant
 * un faux positif coûteux :
 * <ul>
 *   <li>« marqueur A2 present dans une citation, quelle qu'elle soit » aurait
 *       supprime « Pour viser le palier au-dessus, essaie d'envisager une objection
 *       ... 'On pourrait me dire que les grandes villes offrent plus d'activites,
 *       <b>mais</b> a l'ile, la qualite de vie compense largement.' » — c'est-a-dire
 *       le conseil qui decrit EXACTEMENT le test decisif B1 vs B2 de la rubrique ;</li>
 *   <li>« designation + n'importe quel marqueur » aurait supprime « ... tu peux
 *       <b>employer</b> le present, <b>mais</b> pour evoquer un souvenir precis,
 *       utilise le passe compose » — un conseil juste, ou « mais » est une simple
 *       conjonction.</li>
 * </ul>
 * Le sens de l'erreur est assume, comme pour le garde-fou oral (deux faux positifs
 * couteux y ont ete corriges) : une promesse fausse qui passe coute moins cher
 * qu'un vrai conseil efface.
 */
final class EvaluationPalierMarqueurFilter {

    /** Palier nomme, strictement au-dessus de A2. */
    private static final Pattern PALIER_NOMME = Pattern.compile("\\b(b1|b2)\\b");

    /** Palier designe relativement (« le palier au-dessus »). */
    private static final Pattern PALIER_RELATIF = Pattern.compile(
        "gagner un niveau|palier au[- ]dessus|niveau au[- ]dessus|palier superieur"
            + "|niveau superieur|palier suivant|niveau suivant");

    /** Avertissement candidat, pose des qu'au moins une remarque a ete retiree. */
    static final String AVERTISSEMENT_MARQUEUR_PALIER =
        "Une ou plusieurs suggestions présentaient un moyen déjà attendu au niveau A2 "
            + "(« parce que », « mais », « et »…) comme la clé du palier supérieur : elles ont "
            + "été retirées. Ces mots ne suffisent pas à franchir le palier, et les suivre "
            + "n'aurait pas fait monter votre niveau.";

    /** Resultat d'une purge : le feedback est modifie en place. */
    record Resultat(int remarquesRetirees, int entreesRetirees) {
        boolean aPurge() {
            return remarquesRetirees > 0 || entreesRetirees > 0;
        }
    }

    private EvaluationPalierMarqueurFilter() {
    }

    /**
     * Purge en place les champs de restitution qui vendent un marqueur A2 comme
     * un levier vers un palier superieur.
     *
     * @param feedback sortie du correcteur, deja normalisee, note et niveau
     *                 calcules — ce filet ne touche a aucun des deux
     * @param constate niveau REELLEMENT constate sur la tache (celui du serveur,
     *                 apres couplage et plafonds). Null accepte : seules les
     *                 revendications nommant B1 ou B2 sont alors traitees.
     */
    static Resultat purge(Map<String, Object> feedback, NiveauCecrl constate) {
        int remarques = 0;
        int entrees = 0;

        Bilan suggestions = purgeListeDeTextes(feedback, "suggestions", constate);
        remarques += suggestions.remarques();
        entrees += suggestions.entrees();

        Bilan priorites = purgePriorites(feedback, constate);
        remarques += priorites.remarques();
        entrees += priorites.entrees();

        Bilan exemples = purgeExemplesCorriges(feedback, constate);
        remarques += exemples.remarques();
        entrees += exemples.entrees();

        return new Resultat(remarques, entrees);
    }

    private record Bilan(int remarques, int entrees) {
        static final Bilan VIDE = new Bilan(0, 0);

        Bilan plus(int r, int e) {
            return new Bilan(remarques + r, entrees + e);
        }
    }

    // ------------------------------------------------------------- par champ

    /**
     * {@code suggestions} : liste de chaines. La phrase fautive part ; l'entree
     * entierement videe disparait — une suggestion reduite a rien n'a plus rien a
     * dire au candidat.
     */
    private static Bilan purgeListeDeTextes(Map<String, Object> feedback, String champ,
                                            NiveauCecrl constate) {
        if (!(feedback.get(champ) instanceof List<?> valeurs)) return Bilan.VIDE;
        List<Object> gardees = new ArrayList<>();
        Bilan bilan = Bilan.VIDE;
        for (Object raw : valeurs) {
            if (!(raw instanceof String valeur)) {
                gardees.add(raw);
                continue;
            }
            Purge purge = purgerPhrases(valeur, constate);
            if (purge.retirees() == 0) {
                gardees.add(raw);
                continue;
            }
            if (purge.reste().isBlank()) {
                bilan = bilan.plus(purge.retirees(), 1);
            } else {
                gardees.add(purge.reste());
                bilan = bilan.plus(purge.retirees(), 0);
            }
        }
        feedback.put(champ, gardees);
        return bilan;
    }

    /**
     * {@code points_a_ameliorer} : forme normalisee {constat, comment, exemple}.
     * On ne touche jamais {@code exemple.avant}, qui recopie le candidat. Une
     * priorite dont le constat OU la technique est tombee est retiree en entier :
     * un demi-conseil ne s'applique pas.
     */
    @SuppressWarnings("unchecked")
    private static Bilan purgePriorites(Map<String, Object> feedback, NiveauCecrl constate) {
        if (!(feedback.get("points_a_ameliorer") instanceof List<?> points)) return Bilan.VIDE;
        List<Object> gardees = new ArrayList<>();
        Bilan bilan = Bilan.VIDE;
        for (Object raw : points) {
            if (!(raw instanceof Map<?, ?> rawMap)) {
                gardees.add(raw);
                continue;
            }
            Map<String, Object> point = new LinkedHashMap<>((Map<String, Object>) rawMap);
            Purge constat = purgerPhrases(EvaluationTexte.texte(point.get("constat")), constate);
            Purge comment = purgerPhrases(EvaluationTexte.texte(point.get("comment")), constate);
            int retirees = constat.retirees() + comment.retirees();
            if (retirees == 0) {
                gardees.add(raw);
                continue;
            }
            boolean vide = constat.reste().isBlank()
                || (point.get("comment") != null && comment.reste().isBlank());
            if (vide) {
                bilan = bilan.plus(retirees, 1);
                continue;
            }
            point.put("constat", constat.reste());
            if (point.get("comment") != null) point.put("comment", comment.reste());
            gardees.add(point);
            bilan = bilan.plus(retirees, 0);
        }
        feedback.put("points_a_ameliorer", gardees);
        return bilan;
    }

    /**
     * {@code exemples_corriges} : seul {@code gain} est lu — c'est lui qui declare
     * ce que la reformulation demontre, donc lui seul qui peut promettre un
     * palier. {@code original} et {@code corrige} ne sont jamais touches (le
     * premier recopie le candidat, le second est le texte modele). Un gain
     * entierement purge emporte l'entree : le champ est obligatoire cote fronts,
     * et un exemple sans gain n'apprend rien.
     */
    private static Bilan purgeExemplesCorriges(Map<String, Object> feedback, NiveauCecrl constate) {
        if (!(feedback.get("exemples_corriges") instanceof List<?> exemples)) return Bilan.VIDE;
        List<Object> gardes = new ArrayList<>();
        Bilan bilan = Bilan.VIDE;
        for (Object raw : exemples) {
            if (!(raw instanceof Map<?, ?> exemple) || !(exemple.get("gain") instanceof String gain)) {
                gardes.add(raw);
                continue;
            }
            Purge purge = purgerPhrases(gain, constate);
            if (purge.retirees() == 0) {
                gardes.add(raw);
                continue;
            }
            if (purge.reste().isBlank()) {
                bilan = bilan.plus(purge.retirees(), 1);
                continue;
            }
            @SuppressWarnings("unchecked")
            Map<String, Object> copie = new LinkedHashMap<>((Map<String, Object>) exemple);
            copie.put("gain", purge.reste());
            gardes.add(copie);
            bilan = bilan.plus(purge.retirees(), 0);
        }
        feedback.put("exemples_corriges", gardes);
        return bilan;
    }

    // ------------------------------------------------------------- mecanique

    private record Purge(String reste, int retirees) {
    }

    private static Purge purgerPhrases(String texte, NiveauCecrl constate) {
        if (texte == null || texte.isBlank()) return new Purge(texte == null ? "" : texte, 0);
        List<String> gardees = new ArrayList<>();
        int retirees = 0;
        for (String phrase : EvaluationTexte.phrases(texte)) {
            if (vendUnMarqueurA2CommePalierSuperieur(phrase, constate)) {
                retirees++;
            } else {
                gardees.add(phrase.strip());
            }
        }
        if (retirees == 0) return new Purge(texte, 0);
        return new Purge(String.join(" ", gardees).strip(), retirees);
    }

    /** Les DEUX conditions, dans la meme phrase. */
    static boolean vendUnMarqueurA2CommePalierSuperieur(String phrase, NiveauCecrl constate) {
        if (phrase == null || phrase.isBlank()) return false;
        String normalisee = EvaluationTexte.normaliserPourMarqueur(phrase);
        return revendiqueUnPalierAuDessusDeA2(normalisee, constate)
            && EvaluationMarqueursA2.designe(phrase);
    }

    /**
     * Vrai quand la phrase promet un palier strictement au-dessus de A2. Une
     * formule relative n'est resolue que si le niveau constate est connu ET deja
     * au moins A2 : depuis A1, « gagner un niveau » vise A2, et y conseiller
     * « parce que » est exactement ce que demande la rubrique.
     */
    private static boolean revendiqueUnPalierAuDessusDeA2(String normalisee, NiveauCecrl constate) {
        if (PALIER_NOMME.matcher(normalisee).find()) return true;
        if (!PALIER_RELATIF.matcher(normalisee).find()) return false;
        return constate != null && constate.ordinal() >= NiveauCecrl.A2.ordinal();
    }

}
