package com.sejourfr.app.service.competence;

import com.sejourfr.app.enums.SkillCriterionStatus;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Valide la sortie <b>BRUTE</b> du correcteur, avant toute normalisation.
 *
 * <p>Le tool-schema borde deja la forme cote fournisseur, mais rien ne garantit
 * qu'il soit respecte : un modele peut renvoyer un champ vide, un
 * {@code status} inconnu, une cle en trop, ou un verdict de trois lignes. Ce qui
 * arriverait sans ce controle : une carte de resultat servie au candidat avec un
 * champ blanc, ou un {@code criterion_status} nul qui ferait basculer le sujet
 * en « Fait » alors qu'une analyse a bien ete payee.
 *
 * <p><b>Ce que ce validateur ne fait PAS</b> : chercher une note sur 20 ou un
 * niveau CECRL dans les champs texte. Le contrat de sortie ne prevoit aucun
 * champ pour ca, et une detection par mots-cles produirait trop de faux positifs
 * (« B1 » apparait legitimement dans un sujet, « 20 » dans une heure de
 * rendez-vous). L'interdiction est portee par les consignes, pas par une
 * expression reguliere.
 *
 * <p>Toutes les violations sont collectees, jamais la premiere seulement : le
 * message de reessai doit etre complet, sinon on paie un appel par violation.
 */
@Component
public class CompetenceAnalysisValidator {

    /** Les cinq cles attendues, et aucune autre. */
    static final List<String> CLES = List.of(
        CompetenceAnalysisFields.STATUS,
        CompetenceAnalysisFields.VERDICT,
        CompetenceAnalysisFields.SUCCESS_POINT,
        CompetenceAnalysisFields.IMPROVEMENT_PRIORITY,
        CompetenceAnalysisFields.IMPROVED_VERSION);

    /**
     * Tolerance appliquee aux plafonds de longueur avant rejet. Les plafonds
     * sont une consigne pedagogique (« une phrase courte »), pas un contrat
     * machine : perdre une analyse deja payee parce qu'un verdict fait 21 mots
     * au lieu de 20 serait absurde. Au-dela de cette marge, en revanche, le
     * correcteur ne respecte plus la forme demandee et on le lui redemande.
     */
    static final double TOLERANCE_LONGUEUR = 1.2;

    private final CompetenceRubricsProvider rubrics;

    public CompetenceAnalysisValidator(CompetenceRubricsProvider rubrics) {
        this.rubrics = rubrics;
    }

    /** @return la liste des violations, vide si la sortie est conforme. */
    public List<String> violations(Map<String, Object> sortie) {
        List<String> violations = new ArrayList<>();
        if (sortie == null || sortie.isEmpty()) {
            violations.add("sortie vide : les cinq champs sont obligatoires");
            return violations;
        }

        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        for (String cle : CLES) {
            vues.remove(cle);
            if (!sortie.containsKey(cle)) {
                violations.add(cle + " est absent");
                continue;
            }
            Object valeur = sortie.get(cle);
            if (!(valeur instanceof String texte)) {
                violations.add(cle + " doit etre une chaine de caracteres");
                continue;
            }
            if (texte.isBlank()) {
                violations.add(cle + " est vide");
                continue;
            }
            if (CompetenceAnalysisFields.STATUS.equals(cle)) {
                validerStatus(texte, violations);
            } else {
                validerLongueur(cle, texte, violations);
            }
        }

        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + enTrop);
        }
        return violations;
    }

    private void validerStatus(String texte, List<String> violations) {
        String brut = texte.trim();
        boolean connu = false;
        for (SkillCriterionStatus s : SkillCriterionStatus.values()) {
            if (s.name().equals(brut)) { connu = true; break; }
        }
        if (!connu) {
            violations.add(CompetenceAnalysisFields.STATUS + " doit valoir exactement "
                + "VALIDATED, PARTIAL ou NOT_VALIDATED (recu : " + brut + ")");
        }
    }

    private void validerLongueur(String cle, String texte, List<String> violations) {
        Integer max = rubrics.contraintesLongueur().get(cle);
        if (max == null) return; // Pas de plafond declare pour ce champ (improved_version).
        int plafond = (int) Math.floor(max * TOLERANCE_LONGUEUR);
        int mots = compterMots(texte);
        if (mots > plafond) {
            violations.add(cle + " fait " + mots + " mots, le maximum est " + max
                + " (tolere jusqu'a " + plafond + ") : recris-le plus court");
        }
    }

    static int compterMots(String texte) {
        String normalise = texte.trim();
        if (normalise.isEmpty()) return 0;
        return normalise.split("\\s+").length;
    }
}
