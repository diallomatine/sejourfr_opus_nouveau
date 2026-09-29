package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;
import com.sejourfr.app.util.SegmentsSurlignage;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Valide la sortie <b>BRUTE</b> du second appel, avant toute normalisation.
 *
 * <p>Le tool-schema borde deja la forme cote fournisseur, mais rien ne garantit
 * qu'il soit respecte : un modele peut renvoyer un numero de phrase qui n'existe
 * pas, un texte vide ou une cle en trop. Sans ce controle, le candidat verrait un
 * bloc « avant / apres » a moitie blanc — sur l'ecran meme qui doit le convaincre.
 *
 * <p><b>Ordre de preference du depot respecte</b> : le tool-schema d'abord
 * ({@code additionalProperties:false}, {@code minimum}, {@code maxLength}), un
 * controle serveur deterministe ensuite, la consigne en dernier. Ce validateur
 * est le deuxieme etage.
 *
 * <h2>Les {@code segments} ne sont pas juges ici</h2>
 * Ils sont un <b>confort de lecture</b>, pas la section (regle du 2026-08-11,
 * partagee avec {@code version_ciblee} et le module Competences) : un extrait
 * introuvable ou un apport trop long fait retirer <b>ce segment</b>
 * ({@link SegmentsSurlignage}), pas tomber la phrase reecrite que le candidat
 * vient voir. Une liste de segments absente, mal typee, vide ou reduite a un
 * element n'est donc pas une violation : c'est un texte sans surlignage.
 *
 * <h2>Deux violations seulement sont MECANIQUES</h2>
 * Le numero hors bornes et la longueur du texte se nomment exactement et se
 * reparent en un message ; tout le reste est structurel et ne vaut aucun appel
 * paye. Toutes les violations sont collectees, jamais la premiere seulement : le
 * message de reparation doit etre complet, sinon on paie un appel par violation.
 */
@Component
public class DiagnosticExempleCibleValidator {

    /**
     * Prefixe de LA violation qui dit « rien n'est exploitable ». Elle permet de
     * compter separement une sortie hors contrat d'un champ fautif — les deux
     * abandonnent le bloc, mais ne se corrigent pas de la meme façon.
     */
    static final String VIOLATION_SORTIE_VIDE = "sortie vide";

    /** Prefixe des violations du numero de phrase — MECANIQUE, donc reparable. */
    static final String VIOLATION_NUMERO = DiagnosticExempleCibleFields.SEGMENT_NUMERO;

    /** Prefixe de la violation de longueur du texte reecrit — reparable. */
    static final String VIOLATION_LONGUEUR = "texte hors bornes";

    /**
     * @param nbSegments nombre de phrases CITABLES du decoupage de la production ;
     *                   un numero valide vaut {@code 1..nbSegments}.
     * @param bornes     bornes de longueur, resolues par {@link ProductionTextBounds}
     * @return la liste des violations, vide si la sortie est conforme.
     */
    public List<String> violations(Map<String, Object> sortie, int nbSegments,
                                   ProductionTextBounds bornes) {
        List<String> violations = new ArrayList<>();
        if (sortie == null || sortie.isEmpty()) {
            violations.add(VIOLATION_SORTIE_VIDE
                + " : segment_numero, texte et segments sont obligatoires");
            return violations;
        }

        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        vues.remove(DiagnosticExempleCibleFields.SEGMENT_NUMERO);
        vues.remove(DiagnosticExempleCibleFields.TEXTE);
        vues.remove(DiagnosticExempleCibleFields.SEGMENTS);

        validerNumero(sortie.get(DiagnosticExempleCibleFields.SEGMENT_NUMERO), nbSegments,
            violations);
        validerTexte(sortie.get(DiagnosticExempleCibleFields.TEXTE), bornes, violations);

        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + enTrop);
        }
        return violations;
    }

    /**
     * LE NUMERO, pas la phrase. Le modele designe, il ne recopie pas : le seul
     * defaut possible est un entier hors bornes, et c'est un entier a comparer a
     * une taille de liste — inventer une phrase du candidat devient impossible par
     * construction, pas « interdit ».
     */
    private static void validerNumero(Object brut, int nbSegments, List<String> violations) {
        if (brut == null) {
            violations.add(VIOLATION_NUMERO + " est absent");
            return;
        }
        Integer numero = entier(brut);
        if (numero == null) {
            violations.add(VIOLATION_NUMERO + " doit etre un entier, recu : " + brut);
            return;
        }
        if (numero < 1 || numero > nbSegments) {
            violations.add(VIOLATION_NUMERO + " vaut " + numero
                + ", les numeros disponibles vont de 1 a " + nbSegments);
        }
    }

    /**
     * LE TEXTE tient la section : sans lui, il n'y a plus d'« apres » a montrer.
     *
     * <p>Les bornes viennent de {@link ProductionTextBounds}, source de verite
     * unique du depot, et seul le PLAFOND s'applique ici : la borne basse decrit
     * une production entiere (100 a 130 mots au diagnostic), alors qu'on reecrit
     * UNE phrase. L'exiger reviendrait a demander une phrase de cent mots. Le
     * plafond, lui, garde son sens : une reecriture de phrase ne peut pas etre plus
     * longue que la production complete la plus longue qu'on accepte de recevoir.
     */
    private static void validerTexte(Object brut, ProductionTextBounds bornes,
                                     List<String> violations) {
        if (brut == null) {
            violations.add(DiagnosticExempleCibleFields.TEXTE + " est absent");
            return;
        }
        if (!(brut instanceof String texte)) {
            violations.add(DiagnosticExempleCibleFields.TEXTE
                + " doit etre une chaine de caracteres");
            return;
        }
        if (texte.isBlank()) {
            violations.add(DiagnosticExempleCibleFields.TEXTE + " est vide");
            return;
        }
        if (bornes == null) return;
        int mots = ProductionPayloadSupport.countWords(texte);
        if (mots > bornes.max()) {
            violations.add(VIOLATION_LONGUEUR + " : " + mots + " mots, le maximum est "
                + bornes.max());
        }
    }

    /**
     * Vrai quand TOUTES les violations sont mecaniques, donc reparables par un
     * message qui nomme l'operation a faire. Une seule violation structurelle
     * suffit a condamner le bloc : payer un second appel pour reconstruire une
     * sortie cassee depenserait l'argent du proprietaire sur du facultatif.
     */
    static boolean toutesReparables(List<String> violations) {
        if (violations == null || violations.isEmpty()) return false;
        return violations.stream().allMatch(DiagnosticExempleCibleValidator::reparable);
    }

    private static boolean reparable(String violation) {
        return violation != null
            && (violation.startsWith(VIOLATION_NUMERO) || violation.startsWith(VIOLATION_LONGUEUR));
    }

    /** Entier tolerant aux types du JSON ({@code Integer}, {@code Long}, {@code Double} entier). */
    static Integer entier(Object brut) {
        if (brut instanceof Integer i) return i;
        if (brut instanceof Long l) return Math.toIntExact(l);
        if (brut instanceof Number n && n.doubleValue() == Math.rint(n.doubleValue())) {
            return n.intValue();
        }
        return null;
    }
}
