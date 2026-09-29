package com.sejourfr.app.util;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * LES PASSAGES A SURLIGNER — un CONFORT DE LECTURE, jamais la piece maitresse.
 *
 * <h2>La decision produit, arbitree le 2026-08-11</h2>
 * <b>Afficher le texte sans surlignage vaut mieux que ne rien afficher.</b> Le
 * texte reecrit au niveau vise est ce que le candidat vient chercher ; les
 * {@code segments} ne font qu'y attirer l'oeil.
 *
 * <p>Ce filet <b>retire</b> donc un segment inexploitable au lieu de condamner la
 * section : un extrait introuvable, un apport de douze mots, un objet mal forme,
 * un quatrieme segment. La section {@code exemple_cible} ne tombe plus que si son
 * <b>texte</b> est fautif (absent, vide, hors des bornes de la tache).
 *
 * <p>⚠️ Ceci <b>revoque</b> l'invariant « deux segments au minimum, sinon ce n'est
 * pas un chemin » : il valait pour les {@code reformulations} ORALES des
 * productions, qui SONT la section (sans elles il ne reste rien a montrer), et il
 * avait ete recopie a l'ecrit ou il coutait le texte entier.
 *
 * <h2>Une seule mecanique pour DEUX surfaces</h2>
 * Le meme bloc {@code exemple_cible {texte, segments[{extrait, apport}]}} existe
 * dans le second appel des <b>productions</b>
 * ({@code service/versionciblee}, ecrit) et dans celui du module
 * <b>Competences</b> ({@code service/competence/niveauvise}). Deux copies de ce
 * filet auraient fini par juger differemment le meme defaut — c'est exactement ce
 * qui s'est produit avec l'ancienne regle, restee dure d'un cote apres avoir ete
 * assouplie de l'autre. Les <b>noms de champs</b> sont donc parametres
 * ({@link #surLesChamps}) et le <b>comptage</b> reste chez l'appelant : chaque
 * surface garde sa propre famille de compteurs.
 *
 * <h2>Ce qui n'est PAS relache</h2>
 * Un extrait reste une <b>sous-chaine du texte</b> : on ne surligne jamais une
 * phrase que le modele n'a pas ecrite. La comparaison se fait apres
 * <b>neutralisation typographique</b> ({@link TexteNormalise}) — apostrophe
 * courbe contre apostrophe droite, espace insecable, tiret long — et l'extrait
 * conserve est <b>remplace par la sous-chaine ORIGINALE exacte</b>, comme
 * {@code resolvePreuveSegments} resout un numero en texte. Le front recoit donc
 * toujours un extrait qui existe litteralement dans le texte qu'il affiche.
 */
public final class SegmentsSurlignage {

    /**
     * Plafond de passages surlignes. Au-dela, le texte modele n'est plus mis en
     * evidence, il est barbouille — les segments en trop sont tronques, jamais
     * refuses (troisieme filet, celui qui ne depend d'aucune cooperation du
     * modele, comme la troncature des leviers).
     */
    public static final int MAX_SEGMENTS = 3;

    /**
     * POURQUOI un passage est retire. Volontairement grossier : chaque surface le
     * traduit dans SES compteurs, et ce qu'on veut lire tient en trois cas.
     */
    public enum Motif {
        /** Extrait ou apport absent, vide, mal type, trop long, cle en trop. */
        MALFORME,
        /** Extrait introuvable dans le texte modele, meme apres normalisation. */
        EXTRAIT_INTROUVABLE,
        /** Segment au-dela du maximum : tronque, pas refuse. */
        EN_TROP
    }

    /** Un passage retire, et pourquoi — de quoi loguer et compter. */
    public record Retire(String libelle, Motif motif) {
    }

    /**
     * @param gardes  segments conserves, {@code extrait} deja resolu en
     *                sous-chaine originale exacte du texte
     * @param retires segments retires, avec leur motif
     */
    public record Resultat(List<Map<String, Object>> gardes, List<Retire> retires) {
    }

    private final String cleExtrait;
    private final String cleApport;

    private SegmentsSurlignage(String cleExtrait, String cleApport) {
        this.cleExtrait = cleExtrait;
        this.cleApport = cleApport;
    }

    /**
     * Filet cable sur les noms de champs d'un contrat.
     *
     * @param cleExtrait nom du champ portant le passage a surligner
     * @param cleApport  nom du champ portant son etiquette
     */
    public static SegmentsSurlignage surLesChamps(String cleExtrait, String cleApport) {
        return new SegmentsSurlignage(cleExtrait, cleApport);
    }

    /**
     * @param brut          valeur brute de {@code exemple_cible.segments}
     * @param texte         texte modele DEJA valide : c'est en lui qu'on cherche
     * @param plafondApport plafond de mots de l'etiquette, declare par la grille ;
     *                      {@code null} quand la grille n'en declare pas
     */
    public Resultat purge(Object brut, String texte, Integer plafondApport) {
        List<Map<String, Object>> gardes = new ArrayList<>();
        List<Retire> retires = new ArrayList<>();
        if (texte == null || texte.isBlank() || !(brut instanceof List<?> liste)) {
            return new Resultat(gardes, retires);
        }
        TexteNormalise modele = TexteNormalise.de(texte);
        for (Object item : liste) {
            if (gardes.size() >= MAX_SEGMENTS) {
                retires.add(new Retire(libelle(item), Motif.EN_TROP));
                continue;
            }
            Retire refus = examiner(item, modele, plafondApport, gardes);
            if (refus != null) retires.add(refus);
        }
        return new Resultat(gardes, retires);
    }

    /** Ajoute le segment aux gardes, ou rend le motif de son retrait. */
    private Retire examiner(Object item, TexteNormalise modele, Integer plafondApport,
                            List<Map<String, Object>> gardes) {
        if (!(item instanceof Map<?, ?> brut)) {
            return new Retire(libelle(item), Motif.MALFORME);
        }
        Set<String> cles = new LinkedHashSet<>();
        brut.keySet().forEach(cle -> cles.add(String.valueOf(cle)));
        cles.remove(cleExtrait);
        cles.remove(cleApport);
        if (!cles.isEmpty()) {
            return new Retire(libelle(item), Motif.MALFORME);
        }

        String extrait = chaine(brut.get(cleExtrait));
        String apport = chaine(brut.get(cleApport));
        if (extrait == null || apport == null) {
            return new Retire(libelle(item), Motif.MALFORME);
        }
        if (plafondApport != null && PlafondMots.depasse(apport, plafondApport)) {
            return new Retire(libelle(item), Motif.MALFORME);
        }

        Optional<String> original = modele.sousChaineOriginale(extrait);
        if (original.isEmpty()) {
            return new Retire(libelle(item), Motif.EXTRAIT_INTROUVABLE);
        }

        Map<String, Object> garde = new LinkedHashMap<>();
        // LA SOUS-CHAINE ORIGINALE, pas celle rendue par le modele : le front
        // surligne par simple recherche de chaine dans le texte qu'il affiche.
        garde.put(cleExtrait, original.get());
        garde.put(cleApport, apport);
        gardes.add(garde);
        return null;
    }

    private static String chaine(Object valeur) {
        if (!(valeur instanceof String texte) || texte.isBlank()) return null;
        return texte;
    }

    /** Libelle court d'un segment, pour un log. */
    public String libelle(Object item) {
        if (item instanceof Map<?, ?> m) {
            Object extrait = m.get(cleExtrait);
            if (extrait != null) return "« " + extrait + " »";
        }
        return String.valueOf(item);
    }
}
