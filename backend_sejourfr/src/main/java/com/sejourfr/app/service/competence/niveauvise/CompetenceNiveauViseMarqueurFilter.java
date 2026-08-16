package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.util.SegmentsSurlignage;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * FILET DES MARQUEURS DU PALIER — ce que le texte modele PROUVE, verifie sur le
 * texte lui-meme.
 *
 * <h2>Deux etages, aucun recopie</h2>
 * <ol>
 *   <li>{@link SegmentsSurlignage}, <b>appele et non recopie</b> : forme de
 *       l'objet, champs non vides, et surtout {@code extrait} retrouve dans le
 *       texte modele apres neutralisation typographique puis <b>remplace par la
 *       sous-chaine ORIGINALE exacte</b>. C'est la meme mecanique que les
 *       passages a surligner, cablee sur d'autres noms de champs — une seconde
 *       copie aurait fini par juger differemment le meme defaut ;</li>
 *   <li>ici, et ici seulement : le {@code type} doit etre un
 *       {@link MarqueurPalier} connu, et il ne doit pas <b>sur-vendre</b> le
 *       palier cible ({@code objection_traitee} n'a rien a faire pour viser
 *       l'A2).</li>
 * </ol>
 *
 * <h2>Un marqueur retire ne fait JAMAIS tomber la section</h2>
 * Meme arbitrage que les segments depuis le 2026-08-12 : <b>le texte est la
 * piece centrale</b>, un marqueur n'est que la preuve qu'on en donne. Un
 * marqueur introuvable, mal forme, de type inconnu ou sur-vendu est retire, le
 * texte reste servi, et cela n'ouvre droit a <b>aucune reparation payee</b>.
 *
 * <p>Ce qui tient reellement la regle, c'est la <b>contrainte dure</b> : le
 * tool-schema v2 exige deux a trois marqueurs, chacun recopie du texte et typé
 * dans une enumeration fermee. Le modele doit donc placer la matiere du palier
 * dans son texte avant de pouvoir la designer. Ce filet, lui, mesure et
 * nettoie.
 */
final class CompetenceNiveauViseMarqueurFilter {

    /**
     * Le filet de passages, cable sur {@code {extrait, type}}. Aucun plafond de
     * mots sur le {@code type} : c'est une valeur d'enumeration, pas une
     * etiquette redigee — la verification porte sur l'appartenance a
     * {@link MarqueurPalier}, ce qu'un comptage de mots ne saurait pas dire.
     */
    private static final SegmentsSurlignage PASSAGES = SegmentsSurlignage.surLesChamps(
        CompetenceNiveauViseFields.EXTRAIT, CompetenceNiveauViseFields.TYPE);

    /** POURQUOI un marqueur est retire. Familles distinctes, motifs distincts. */
    enum Motif {
        /** Objet mal forme, champ absent ou vide, cle en trop. */
        MALFORME,
        /** Extrait absent du texte modele, meme apres neutralisation typographique. */
        EXTRAIT_INTROUVABLE,
        /** Marqueur au-dela du maximum : tronque, pas refuse. */
        EN_TROP,
        /** {@code type} hors de l'enumeration fermee. */
        TYPE_INCONNU,
        /** Procede dont le palier minimum SUR-VEND le palier cible. */
        TYPE_SUR_VENDU
    }

    /** Un marqueur retire, et pourquoi — de quoi loguer et compter. */
    record Retire(String libelle, Motif motif) {
    }

    /**
     * @param gardes  marqueurs conserves, {@code extrait} deja resolu en
     *                sous-chaine originale exacte du texte modele
     * @param retires marqueurs retires, avec leur motif
     */
    record Resultat(List<Map<String, Object>> gardes, List<Retire> retires) {
    }

    private CompetenceNiveauViseMarqueurFilter() {
    }

    /**
     * @param brut        valeur brute de {@code exemple_cible.marqueurs_du_palier}
     * @param texte       texte modele deja valide : c'est en lui qu'on cherche
     * @param palierCible palier que ces marqueurs pretendent demontrer
     */
    static Resultat purge(Object brut, String texte, TargetLevel palierCible) {
        SegmentsSurlignage.Resultat passages = PASSAGES.purge(brut, texte, null);

        List<Map<String, Object>> gardes = new ArrayList<>();
        List<Retire> retires = new ArrayList<>();
        for (SegmentsSurlignage.Retire retire : passages.retires()) {
            retires.add(new Retire(retire.libelle(), motif(retire.motif())));
        }
        for (Map<String, Object> passage : passages.gardes()) {
            Optional<MarqueurPalier> type = MarqueurPalier.de(
                String.valueOf(passage.get(CompetenceNiveauViseFields.TYPE)));
            if (type.isEmpty()) {
                retires.add(new Retire(libelle(passage), Motif.TYPE_INCONNU));
            } else if (!type.get().demontre(palierCible)) {
                // On ne purge QUE la sur-vente : un procede plus modeste que le
                // palier cible reste une preuve legitime de ce que le texte fait.
                retires.add(new Retire(libelle(passage), Motif.TYPE_SUR_VENDU));
            } else {
                gardes.add(passage);
            }
        }
        return new Resultat(List.copyOf(gardes), List.copyOf(retires));
    }

    private static Motif motif(SegmentsSurlignage.Motif motif) {
        return switch (motif) {
            case EXTRAIT_INTROUVABLE -> Motif.EXTRAIT_INTROUVABLE;
            case EN_TROP -> Motif.EN_TROP;
            case MALFORME -> Motif.MALFORME;
        };
    }

    /** Libelle court d'un marqueur, pour un log. */
    static String libelle(Map<String, Object> marqueur) {
        return "« " + marqueur.get(CompetenceNiveauViseFields.EXTRAIT) + " » ("
            + marqueur.get(CompetenceNiveauViseFields.TYPE) + ")";
    }
}
