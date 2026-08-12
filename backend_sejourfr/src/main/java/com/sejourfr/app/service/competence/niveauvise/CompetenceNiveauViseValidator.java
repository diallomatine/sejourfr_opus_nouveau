package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.util.PlafondMots;
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
 * qu'il soit respecte : un modele peut renvoyer un levier vide, un seul segment,
 * une etiquette de douze mots ou une cle en trop. Sans ce controle, le candidat
 * verrait un encart a moitie blanc.
 *
 * <p><b>Ordre de preference du depot respecte</b> : le tool-schema d'abord
 * ({@code additionalProperties:false}, {@code minItems}/{@code maxItems},
 * {@code maxLength}), un controle serveur deterministe ensuite, la consigne en
 * dernier. Ce validateur est le deuxieme etage.
 *
 * <h2>Les {@code segments} ne sont plus juges ici</h2>
 * (2026-08-12, alignement sur les productions.) Ils sont un <b>confort de
 * lecture</b>, pas la section : un extrait introuvable ou un apport trop long
 * fait retirer <b>ce segment</b> ({@link SegmentsSurlignage}), pas tomber le
 * texte modele que le candidat vient chercher. L'{@code exemple_cible} se joue
 * donc sur son <b>texte</b> et sur la forme du bloc, et sur eux seuls : une liste
 * de segments absente, mal typee, vide ou reduite a un element n'est plus une
 * violation, c'est un texte sans surlignage.
 *
 * <p>⚠️ L'ancienne regle — un seul extrait introuvable emportait tout le bloc, et
 * ouvrait droit a la reparation payee — est <b>revoquee</b>. Elle etait plus dure
 * ici que sur les productions, qui portent pourtant le meme bloc.
 *
 * <p>Toutes les violations sont collectees, jamais la premiere seulement : le
 * message de reparation doit etre complet, sinon on paie un appel par violation.
 */
@Component
public class CompetenceNiveauViseValidator {

    /** Deux leviers au minimum : un seul ne montre pas un chemin, il montre un detail. */
    static final int MIN_LEVIERS = 2;

    /**
     * Tolerance appliquee aux plafonds de longueur avant rejet, resolue par
     * {@link PlafondMots#tolere(int)} — identique au reste du depot : un plafond
     * est une consigne pedagogique (« trois mots »), pas un contrat machine.
     * Perdre le bloc parce qu'une etiquette fait quatre mots au lieu de trois
     * serait absurde ; a huit mots, en revanche, ce n'est plus une etiquette.
     *
     * <p>⚠️ L'ancienne formule {@code floor(plafond * 1,2)} ne tolerait RIEN sur
     * {@code apport}, declare a 3 mots par la grille.
     */
    static final double TOLERANCE_LONGUEUR = PlafondMots.TOLERANCE;

    /**
     * Prefixe de LA violation qui dit « rien n'est exploitable ». Elle permet de
     * compter separement une sortie hors contrat d'un champ fautif — les deux
     * abandonnent le bloc, mais ne se corrigent pas de la meme facon.
     */
    static final String VIOLATION_SORTIE_VIDE = "sortie vide";

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
            violations.add(VIOLATION_SORTIE_VIDE
                + " : leviers, exemple_cible et a_retenir sont obligatoires");
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

    /**
     * L'EXEMPLE CIBLE SE JOUE SUR SON TEXTE, ET SUR LUI SEUL.
     *
     * <p>Seuls le texte modele et la forme du bloc sont juges ici : c'est le texte
     * que le candidat vient chercher, et lui seul doit pouvoir faire tomber la
     * section. Les {@code segments} passent par {@link SegmentsSurlignage}, qui
     * retire ceux qu'il ne peut pas surligner et laisse le texte servi.
     */
    private void validerExempleCible(Object brut, List<String> violations) {
        String prefixe = CompetenceNiveauViseFields.EXEMPLE_CIBLE;
        Map<String, Object> bloc = asMap(brut, prefixe, violations);
        if (bloc == null) return;
        clesEnTrop(bloc, prefixe, violations,
            CompetenceNiveauViseFields.TEXTE, CompetenceNiveauViseFields.SEGMENTS);

        champTexte(bloc, CompetenceNiveauViseFields.TEXTE, prefixe, violations);
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
            int max = PlafondMots.tolere(plafond);
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
        return PlafondMots.compter(texte);
    }
}
