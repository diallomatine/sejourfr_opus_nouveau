package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * LE PROCEDE D'UN LEVIER — inspecte, compte, et <b>ne retire jamais un levier</b>.
 *
 * <h2>Le defaut d'origine</h2>
 * Mesure sur un cas reel : les trois leviers servis vers le B2 etaient « Rends
 * ton invitation plus chaleureuse », « Propose une alternative concrete »,
 * « Termine par une formule engageante ». Ce sont des conseils de <b>ton</b>,
 * pas de <b>palier</b> — on peut etre tres chaleureux en A2, et le candidat qui
 * les applique a la lettre reste exactement ou il est. Le filet des marqueurs A2
 * ({@link CompetenceNiveauViseLevierFilter}) ne pouvait rien y voir : il
 * reconnait une liste fermee de six mots-outils cites, or aucun de ces trois
 * leviers n'en cite un seul, et l'elargir a deja ete mesure et rejete cote
 * productions pour faux positifs.
 *
 * <h2>Ce qui tient la regle, c'est le SCHEMA — pas cette classe</h2>
 * La reponse suit l'ordre de preference du depot : le contrat <b>v3</b> exige un
 * {@code procede} sur chaque levier, dans la meme enumeration fermee que les
 * marqueurs du palier ({@link MarqueurPalier}). Le modele ne peut donc plus
 * produire un conseil de ton sans le rattacher a une operation de langue reelle.
 * Un champ absent du schema ne peut pas etre produit ; un champ requis et type
 * force le contenu.
 *
 * <h2>🛑 Un levier n'est JAMAIS purge a cause de son procede</h2>
 * Les leviers portent le <b>bloc entier</b> : sous leur minimum et sans
 * reparation, tout est abandonne. Purger sur ce motif viderait l'ecran du
 * candidat — ce qui est exactement le contraire du but. Donc, procede
 * <b>manquant</b>, <b>inconnu</b> ou qui <b>sur-vend</b> le palier cible :
 * <ul>
 *   <li>le levier est <b>conserve</b> et servi tel quel ;</li>
 *   <li>l'anomalie est <b>comptee</b>
 *       ({@code CompetenceNiveauViseMetrics.procedeAnormal}) ;</li>
 *   <li>le procede fautif n'est <b>pas persiste</b> — voir ci-dessous ;</li>
 *   <li><b>aucune reparation payee</b> n'est declenchee : ce motif ne coute rien
 *       a l'affichage.</li>
 * </ul>
 *
 * <h2>Pourquoi le procede fautif n'est pas persiste</h2>
 * Le procede n'est expose a aucun front (aucun ecran ne l'affiche, et une API
 * morte est une dette) : il est persiste pour repondre en <b>une requete SQL</b>
 * a « ce levier nommait-il un vrai moyen de langue ? ». Une colonne qui peut
 * contenir n'importe quelle chaine du modele ne repond a rien ; un procede
 * absent, lui, dit exactement « ce levier n'etait pas verifiable ». Meme
 * arbitrage que {@code level_evidence} cote analyse : on persiste ce qui est
 * <b>opposable</b>, et l'anomalie vit dans le compteur.
 *
 * <h2>La table de compatibilite n'est pas recopiee</h2>
 * C'est {@link MarqueurPalier#demontre(TargetLevel)} qui tranche la sur-vente,
 * la meme methode que {@link CompetenceNiveauViseMarqueurFilter} — une seule
 * autorite. Deux tables ecrites separement finiraient par classer le meme
 * procede a deux paliers differents.
 */
final class CompetenceNiveauViseProcedeAudit {

    /** POURQUOI un procede n'est pas opposable. Aucun de ces motifs ne purge. */
    enum Motif {
        /** Champ absent, vide, ou d'un autre type qu'une chaine. */
        ABSENT,
        /** Valeur hors de l'enumeration fermee {@link MarqueurPalier}. */
        INCONNU,
        /** Procede dont le palier minimum SUR-VEND le palier cible. */
        SUR_VENDU
    }

    /** Une anomalie constatee sur un levier CONSERVE — de quoi loguer et compter. */
    record Anomalie(String libelle, Motif motif) {
    }

    /**
     * @param leviers   les MEMES leviers, dans le meme ordre, jamais moins : seul
     *                  un procede fautif a ete retire de l'objet servi
     * @param anomalies ce qui n'etait pas opposable, avec son motif
     */
    record Resultat(List<Map<String, Object>> leviers, List<Anomalie> anomalies) {
    }

    private CompetenceNiveauViseProcedeAudit() {
    }

    /**
     * @param leviers     leviers deja valides et deja passes au filet des
     *                    marqueurs A2 — on n'inspecte que ce qui sera servi
     * @param palierCible palier que le bloc doit faire atteindre
     */
    static Resultat inspecter(List<Map<String, Object>> leviers, TargetLevel palierCible) {
        if (leviers == null || leviers.isEmpty()) return new Resultat(List.of(), List.of());

        List<Map<String, Object>> servis = new ArrayList<>();
        List<Anomalie> anomalies = new ArrayList<>();
        for (Map<String, Object> levier : leviers) {
            Object brut = levier.get(CompetenceNiveauViseFields.PROCEDE);
            String code = brut == null ? "" : brut.toString().trim();
            if (code.isEmpty()) {
                anomalies.add(new Anomalie(libelle(levier, code), Motif.ABSENT));
                servis.add(sansProcede(levier));
                continue;
            }
            Optional<MarqueurPalier> procede = MarqueurPalier.de(code);
            if (procede.isEmpty()) {
                anomalies.add(new Anomalie(libelle(levier, code), Motif.INCONNU));
                servis.add(sansProcede(levier));
            } else if (!procede.get().demontre(palierCible)) {
                // On ne compte QUE la sur-vente : un procede plus modeste que le
                // palier cible reste un moyen de langue legitime a travailler.
                anomalies.add(new Anomalie(libelle(levier, code), Motif.SUR_VENDU));
                servis.add(sansProcede(levier));
            } else {
                servis.add(avecProcede(levier, procede.get()));
            }
        }
        return new Resultat(List.copyOf(servis), List.copyOf(anomalies));
    }

    /** Le levier sans son procede : le reste est servi a l'identique. */
    private static Map<String, Object> sansProcede(Map<String, Object> levier) {
        Map<String, Object> copie = new LinkedHashMap<>(levier);
        copie.remove(CompetenceNiveauViseFields.PROCEDE);
        return copie;
    }

    /** Le levier avec son procede NORMALISE au code de l'enumeration. */
    private static Map<String, Object> avecProcede(Map<String, Object> levier,
                                                   MarqueurPalier procede) {
        Map<String, Object> copie = new LinkedHashMap<>(levier);
        copie.put(CompetenceNiveauViseFields.PROCEDE, procede.name());
        return copie;
    }

    /** Libelle court d'un levier et de son procede fautif, pour un log. */
    private static String libelle(Map<String, Object> levier, String code) {
        String procede = code.isEmpty() ? "aucun procédé" : code;
        return CompetenceNiveauViseLevierFilter.libelle(levier) + " (" + procede + ")";
    }
}
