package com.sejourfr.app.service.competence.niveauvise;

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
 * qu'il soit respecte : un modele peut renvoyer un levier vide, un seul segment,
 * une etiquette de douze mots ou une cle en trop. Sans ce controle, le candidat
 * verrait un encart a moitie blanc.
 *
 * <p><b>Ordre de preference du depot respecte</b> : le tool-schema d'abord
 * ({@code additionalProperties:false}, {@code minItems}/{@code maxItems},
 * {@code maxLength}), un controle serveur deterministe ensuite, la consigne en
 * dernier. Ce validateur est le deuxieme etage.
 *
 * <h2>Le controle qui n'existe nulle part ailleurs : l'extrait est DANS le texte</h2>
 * Le front SURLIGNE chaque {@code segments[].extrait} dans
 * {@code exemple_cible.texte}. Un extrait qui n'y figure pas ne se surligne pas :
 * au mieux il ne s'affiche nulle part, au pire il s'affiche comme une citation du
 * texte modele alors qu'il n'en fait pas partie — c'est-a-dire une phrase
 * inventee presentee comme un extrait. Le serveur exige donc une <b>sous-chaine
 * exacte</b>, et cette violation-la ouvre droit a la seule reparation payee.
 *
 * <p>Toutes les violations sont collectees, jamais la premiere seulement : le
 * message de reparation doit etre complet, sinon on paie un appel par violation.
 */
@Component
public class CompetenceNiveauViseValidator {

    /** Deux leviers au minimum : un seul ne montre pas un chemin, il montre un detail. */
    static final int MIN_LEVIERS = 2;
    /** Deux segments au minimum : un seul ne montre pas une difference, il montre un mot. */
    static final int MIN_SEGMENTS = 2;
    static final int MAX_SEGMENTS = 3;

    /**
     * Tolerance appliquee aux plafonds de longueur avant rejet, identique a
     * celle du reste du module : un plafond est une consigne pedagogique (« trois
     * mots »), pas un contrat machine. Perdre le bloc parce qu'une etiquette fait
     * quatre mots au lieu de trois serait absurde ; a huit mots, en revanche, ce
     * n'est plus une etiquette.
     */
    static final double TOLERANCE_LONGUEUR = 1.2;

    /**
     * Prefixe des violations « extrait introuvable dans le texte ». Il permet de
     * les distinguer des violations de structure : seules celles-ci ouvrent droit
     * a une reparation (cf. {@link #uniquementExtraits(List)}).
     */
    static final String VIOLATION_EXTRAIT = "extrait introuvable";

    private final CompetenceNiveauViseRubricsProvider rubrics;

    public CompetenceNiveauViseValidator(CompetenceNiveauViseRubricsProvider rubrics) {
        this.rubrics = rubrics;
    }

    /**
     * @param maxLeviers plafond SERVEUR du nombre de leviers.
     * @return la liste des violations, vide si la sortie est conforme.
     */
    public List<String> violations(Map<String, Object> sortie, int maxLeviers) {
        List<String> violations = new ArrayList<>();
        if (sortie == null || sortie.isEmpty()) {
            violations.add("sortie vide : leviers, exemple_cible et a_retenir sont obligatoires");
            return violations;
        }

        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        vues.remove(CompetenceNiveauViseFields.LEVIERS);
        vues.remove(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        vues.remove(CompetenceNiveauViseFields.A_RETENIR);

        validerLeviers(sortie.get(CompetenceNiveauViseFields.LEVIERS), maxLeviers, violations);
        validerExempleCible(sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE), violations);
        validerARetenir(sortie.get(CompetenceNiveauViseFields.A_RETENIR), violations);

        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + enTrop);
        }
        return violations;
    }

    /**
     * Vrai quand TOUTES les violations portent sur un extrait introuvable dans le
     * texte modele. C'est le seul cas de violation de contenu ou une reparation
     * est tentee : le defaut est MECANIQUE et nommable (on peut citer l'extrait
     * refuse et rappeler la regle), donc reparable par un message actionnable —
     * le depot a mesure qu'un reessai non actionnable repare zero cas sur huit.
     *
     * <p>Une sortie structurellement fausse (cle en trop, levier vide, un seul
     * segment) n'ouvre droit a aucun second appel paye : le bloc reste un
     * confort.
     */
    static boolean uniquementExtraits(List<String> violations) {
        return !violations.isEmpty()
            && violations.stream().allMatch(v -> v != null && v.startsWith(VIOLATION_EXTRAIT));
    }

    // ------------------------------------------------------------- leviers

    private void validerLeviers(Object brut, int maxLeviers, List<String> violations) {
        if (!(brut instanceof List<?> liste)) {
            violations.add(CompetenceNiveauViseFields.LEVIERS + " doit etre une liste");
            return;
        }
        if (liste.size() < MIN_LEVIERS) {
            violations.add(CompetenceNiveauViseFields.LEVIERS + " compte " + liste.size()
                + " element(s), il en faut au moins " + MIN_LEVIERS);
        }
        if (liste.size() > maxLeviers) {
            violations.add(CompetenceNiveauViseFields.LEVIERS + " compte " + liste.size()
                + " elements, le maximum est " + maxLeviers);
        }
        int i = 0;
        for (Object item : liste) {
            i++;
            String prefixe = CompetenceNiveauViseFields.LEVIERS + "[" + i + "]";
            Map<String, Object> levier = asMap(item, prefixe, violations);
            if (levier == null) continue;
            champTexte(levier, CompetenceNiveauViseFields.ACTION, prefixe, violations);
            champTexte(levier, CompetenceNiveauViseFields.EXEMPLE, prefixe, violations);
            clesEnTrop(levier, prefixe, violations,
                CompetenceNiveauViseFields.ACTION, CompetenceNiveauViseFields.EXEMPLE);
        }
    }

    // ------------------------------------------------------- exemple cible

    private void validerExempleCible(Object brut, List<String> violations) {
        String prefixe = CompetenceNiveauViseFields.EXEMPLE_CIBLE;
        Map<String, Object> bloc = asMap(brut, prefixe, violations);
        if (bloc == null) return;
        clesEnTrop(bloc, prefixe, violations,
            CompetenceNiveauViseFields.TEXTE, CompetenceNiveauViseFields.SEGMENTS);

        String texte = champTexte(bloc, CompetenceNiveauViseFields.TEXTE, prefixe, violations);

        Object segments = bloc.get(CompetenceNiveauViseFields.SEGMENTS);
        if (!(segments instanceof List<?> liste)) {
            violations.add(prefixe + "." + CompetenceNiveauViseFields.SEGMENTS
                + " doit etre une liste");
            return;
        }
        if (liste.size() < MIN_SEGMENTS || liste.size() > MAX_SEGMENTS) {
            violations.add(prefixe + "." + CompetenceNiveauViseFields.SEGMENTS + " compte "
                + liste.size() + " element(s), il en faut " + MIN_SEGMENTS + " a " + MAX_SEGMENTS);
        }
        int i = 0;
        for (Object item : liste) {
            i++;
            String p = prefixe + "." + CompetenceNiveauViseFields.SEGMENTS + "[" + i + "]";
            Map<String, Object> segment = asMap(item, p, violations);
            if (segment == null) continue;
            clesEnTrop(segment, p, violations,
                CompetenceNiveauViseFields.EXTRAIT, CompetenceNiveauViseFields.APPORT);
            String extrait = champTexte(
                segment, CompetenceNiveauViseFields.EXTRAIT, p, violations);
            champTexte(segment, CompetenceNiveauViseFields.APPORT, p, violations);
            // LE controle central : le front surligne cet extrait DANS le texte.
            // On ne compare ni a la casse pres relachee, ni apres normalisation :
            // le surlignage se fait sur la chaine exacte, la verification aussi.
            if (extrait != null && texte != null && !texte.contains(extrait)) {
                violations.add(VIOLATION_EXTRAIT + " dans le texte modele — " + p + " : \""
                    + extrait + "\"");
            }
        }
    }

    // ----------------------------------------------------------- a retenir

    private void validerARetenir(Object brut, List<String> violations) {
        String prefixe = CompetenceNiveauViseFields.A_RETENIR;
        Map<String, Object> bloc = asMap(brut, prefixe, violations);
        if (bloc == null) return;
        clesEnTrop(bloc, prefixe, violations,
            CompetenceNiveauViseFields.FORMULE, CompetenceNiveauViseFields.EXPLICATION);
        champTexte(bloc, CompetenceNiveauViseFields.FORMULE, prefixe, violations);
        champTexte(bloc, CompetenceNiveauViseFields.EXPLICATION, prefixe, violations);
    }

    // -------------------------------------------------------------- outils

    /**
     * Verifie qu'un champ terminal est une chaine non vide et sous son plafond de
     * mots, et le retourne. Null quand il est absent, mal type ou vide — l'appelant
     * n'a alors plus rien a en faire.
     */
    private String champTexte(Map<String, Object> parent, String cle, String prefixe,
                              List<String> violations) {
        Object valeur = parent.get(cle);
        String chemin = prefixe + "." + cle;
        if (valeur == null) {
            violations.add(chemin + " est absent");
            return null;
        }
        if (!(valeur instanceof String texte)) {
            violations.add(chemin + " doit etre une chaine de caracteres");
            return null;
        }
        if (texte.isBlank()) {
            violations.add(chemin + " est vide");
            return null;
        }
        Integer plafond = rubrics.contraintesLongueur().get(cle);
        if (plafond != null) {
            int max = (int) Math.floor(plafond * TOLERANCE_LONGUEUR);
            int mots = compterMots(texte);
            if (mots > max) {
                violations.add(chemin + " fait " + mots + " mots, le maximum est " + plafond
                    + " (tolere jusqu'a " + max + ")");
            }
        }
        return texte;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> asMap(Object brut, String chemin, List<String> violations) {
        if (brut == null) {
            violations.add(chemin + " est absent");
            return null;
        }
        if (!(brut instanceof Map<?, ?> m)) {
            violations.add(chemin + " doit etre un objet");
            return null;
        }
        return (Map<String, Object>) m;
    }

    private static void clesEnTrop(Map<String, Object> bloc, String chemin,
                                   List<String> violations, String... attendues) {
        Set<String> vues = new LinkedHashSet<>(bloc.keySet());
        for (String attendue : attendues) {
            vues.remove(attendue);
        }
        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + chemin + "." + enTrop);
        }
    }

    static int compterMots(String texte) {
        String normalise = texte.trim();
        if (normalise.isEmpty()) return 0;
        return normalise.split("\\s+").length;
    }
}
