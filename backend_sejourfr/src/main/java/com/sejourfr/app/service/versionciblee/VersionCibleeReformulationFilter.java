package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.service.EvaluationOralForme;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * FILET DETERMINISTE sur les reformulations ORALES : <b>on reformule une
 * PHRASE, jamais la forme d'un mot</b>.
 *
 * <h2>Le defaut qu'il empeche</h2>
 * A l'oral, le texte lu par le modele n'est pas ecrit par le candidat : c'est
 * une transcription automatique, et elle se trompe. Le cas reel du 2026-08-08 :
 * le candidat avait dit « j'habite a Lille », la machine avait ecrit
 * « abit a Lille », et le correcteur le lui a reproche. Si une reformulation ne
 * fait que remettre « j'habite » a la place de « abit », on rend au candidat une
 * correction de NOTRE erreur en la lui presentant comme la sienne. Elle est donc
 * retiree — elle n'apporte rien, et elle ment.
 *
 * <h2>La regle, partagee, jamais recopiee</h2>
 * C'est exactement le seuil du volet FORME de
 * {@code EvaluationOralArtifactFilter}, extrait dans {@link EvaluationOralForme}
 * a sa deuxieme occurrence : <b>un ou deux</b> mots pleins REMPLACES SUR PLACE
 * caracterisent une reparation de FORME, et elle est retiree.
 *
 * <p>« Sur place » est le coeur de la regle : une reformulation qui fait monter
 * le niveau DEPLACE les mots — elle subordonne, elle reordonne, elle ajoute un
 * connecteur, elle construit une question. Des que la suite des mots pleins
 * change de longueur ou d'ordre, on ne purge rien. Le comptage est celui du
 * controle de preuve : mots-outils, hesitations et elisions exclus.
 *
 * <p><b>Frontiere assumee, dans le sens SÛR.</b> Une reparation de mot noyee
 * dans une vraie reecriture passe : elle est alors indiscernable d'un travail de
 * structure, et l'inventer supprimerait de VRAIS conseils. Meme arbitrage que le
 * volet FORME, qui ne reconnait qu'un reproche ne nommant qu'un seul mot.
 *
 * <h2>La reformulation tombe en ENTIER, la SECTION aussi — pas le bloc</h2>
 * Un demi-conseil ne s'applique pas. S'il en reste moins de deux, le service paie
 * UNE reparation nommee, puis abandonne la seule section {@code reformulations}.
 * Les leviers et la tournure a retenir ne dependent d'aucune citation : ils sont
 * servis. Sur une transcription hachee, purger ici faisait perdre au candidat
 * tout son plan d'action, alors que le probleme venait de notre machine.
 *
 * <p><b>Ce filet ne touche ni la note, ni le niveau, ni un seuil</b> : il agit
 * sur un bloc de confort produit par un appel separe, apres que l'evaluation est
 * persistee. Aucune campagne de banc n'est requise, par construction.
 */
final class VersionCibleeReformulationFilter {

    /**
     * @param gardes  reformulations conservees, dans l'ordre rendu
     * @param retires reformulations retirees, pour le log, le compteur de purges
     *                et le message de reparation (qui les nomme une par une)
     */
    record Resultat(List<Map<String, Object>> gardes, List<Map<String, Object>> retires) {
    }

    private VersionCibleeReformulationFilter() {
    }

    /**
     * @param reformulations reformulations deja validees et deja RESOLUES : leur
     *                       {@code original} porte le texte exact du passage
     *                       designe, sans quoi il n'y a rien a comparer.
     */
    static Resultat purge(List<Map<String, Object>> reformulations) {
        if (reformulations == null || reformulations.isEmpty()) {
            return new Resultat(List.of(), List.of());
        }
        List<Map<String, Object>> gardes = new ArrayList<>();
        List<Map<String, Object>> retires = new ArrayList<>();
        for (Map<String, Object> reformulation : reformulations) {
            if (neChangeQuUneForme(reformulation)) {
                retires.add(reformulation);
            } else {
                gardes.add(reformulation);
            }
        }
        return new Resultat(gardes, retires);
    }

    /** Vrai quand tout l'apport de la reformulation tient a un ou deux mots pleins. */
    static boolean neChangeQuUneForme(Map<String, Object> reformulation) {
        String original = texte(reformulation.get(VersionCibleeFields.ORIGINAL));
        String reformule = texte(reformulation.get(VersionCibleeFields.REFORMULE));
        if (original.isEmpty() || reformule.isEmpty()) return false;
        return EvaluationOralForme.estFormeIsolee(
            EvaluationOralForme.motsPorteursRemplacesEnPlace(original, reformule));
    }

    /** Libelle court, pour un log ou un message de reparation. */
    static String libelle(Map<String, Object> reformulation) {
        return "« " + texte(reformulation.get(VersionCibleeFields.ORIGINAL)) + " » → « "
            + texte(reformulation.get(VersionCibleeFields.REFORMULE)) + " »";
    }

    private static String texte(Object valeur) {
        return valeur == null ? "" : valeur.toString().trim();
    }
}
