package com.sejourfr.app.service.competence;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.util.PlafondMots;
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
 * <p><b>Ce que ce validateur ne fait PAS</b> : chercher une note sur 20 cachee
 * dans les champs texte. Le contrat de sortie ne prevoit aucun champ pour ca, et
 * une detection par mots-cles produirait trop de faux positifs (« 20 » apparait
 * legitimement dans une heure de rendez-vous). L'interdiction de la note est
 * portee par le schema et par les consignes, pas par une expression reguliere.
 *
 * <p>Le <b>niveau CECRL</b>, lui, est desormais un champ du contrat
 * ({@code level_reached}, depuis v3) et il est verifie comme un enum : borne aux
 * cinq valeurs du profil TCF IRN, jamais C1 ni C2.
 *
 * <p><b>La PREUVE du niveau ({@code level_evidence}, depuis v4) n'est pas
 * verifiee ici</b>, et c'est un choix. Ce validateur a le pouvoir de faire
 * echouer l'analyse (deuxieme sortie encore invalide → {@code FAILED}) ; une
 * preuve manquante, elle, ne doit jamais couter au candidat sa production et son
 * quota. Elle est donc traitee par {@link CompetenceLevelEvidenceGuard}, qui
 * abaisse le niveau d'un palier au lieu de rejeter.
 *
 * <p>⚠️ <b>Cet invariant survit au contrat v5</b>, qui met pourtant
 * {@code level_evidence} dans le {@code required} du tool-schema : c'est le
 * fournisseur qui l'exige, jamais nous. Recopier ce {@code required} dans le jeu
 * de cles verifie ici aurait fait rejeter des analyses parfaitement servables —
 * le piege exact de {@code EvaluationOutputValidator.CHAMPS_V4}.
 *
 * <p>Toutes les violations sont collectees, jamais la premiere seulement : le
 * message de reessai doit etre complet, sinon on paie un appel par violation.
 */
@Component
public class CompetenceAnalysisValidator {

    /**
     * Tolerance appliquee aux plafonds de longueur avant rejet, resolue par
     * {@link PlafondMots#tolere(int)}. Les plafonds sont une consigne pedagogique
     * (« une phrase courte »), pas un contrat machine : perdre une analyse deja
     * payee parce qu'un verdict fait 21 mots au lieu de 20 serait absurde.
     *
     * <p>⚠️ L'ancienne formule {@code floor(plafond * 1,2)} n'accordait AUCUNE
     * marge sur les petits plafonds : {@code strength_tag} et {@code focus_tag}
     * valent <b>3 mots</b> sous le contrat actif, et 3 x 1,2 arrondi vers le bas
     * fait 3. La tolerance n'existait donc pas la ou elle etait le plus
     * necessaire.
     */
    static final double TOLERANCE_LONGUEUR = PlafondMots.TOLERANCE;

    /** Les seuls niveaux du profil TCF IRN : C1 et C2 n'existent pas ici. */
    static final List<NiveauCecrl> NIVEAUX_TCF_IRN = List.of(
        NiveauCecrl.A1_NON_ATTEINT, NiveauCecrl.A1, NiveauCecrl.A2,
        NiveauCecrl.B1, NiveauCecrl.B2);

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

        String contrat = rubrics.getToolSchemaVersion();
        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        for (String cle : cles()) {
            vues.remove(cle);
            // LA PREUVE DU NIVEAU N'EST PAS VALIDEE ICI, VOLONTAIREMENT. Ce
            // validateur fait echouer l'analyse quand sa deuxieme sortie est
            // encore mauvaise ; or une preuve manquante ne doit JAMAIS couter
            // son analyse au candidat — elle abaisse le niveau d'un palier
            // (cf. CompetenceLevelEvidenceGuard). Le champ est seulement
            // reconnu comme etant DANS le contrat, pour ne pas etre compte
            // « cle hors contrat ». Vaut aussi sous v5, ou le tool-schema la
            // rend pourtant REQUISE : ce qu'on refuse ici fait echouer, et une
            // preuve manquante ne doit jamais couter une analyse.
            if (CompetenceAnalysisFields.estExclueDuValidateur(contrat, cle)) continue;
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
            } else if (CompetenceAnalysisFields.LEVEL_REACHED.equals(cle)) {
                validerNiveau(texte, violations);
            } else {
                validerLongueur(cle, texte, violations);
            }
        }

        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + enTrop);
        }
        return violations;
    }

    /**
     * Cles attendues pour le CONTRAT DE SORTIE actif. Lues a chaque appel et non
     * figees a la construction : c'est ce qui rend le retour arriere reel, un
     * {@code COMPETENCE_TOOL_SCHEMA_VERSION=v2} devant reclamer les champs de v2.
     */
    private List<String> cles() {
        return CompetenceAnalysisFields.cles(rubrics.getToolSchemaVersion());
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

    /**
     * NIVEAU CECRL, borne au profil TCF IRN. C1 et C2 existent dans
     * {@link NiveauCecrl} (les productions completes en ont besoin) mais n'ont
     * aucun sens ici : le TCF IRN plafonne au B2, et un micro-exercice n'est de
     * toute façon pas le lieu pour les distinguer. Le tool-schema les exclut
     * deja par son {@code enum} ; ce controle est le deuxieme etage, celui qui
     * ne depend d'aucune cooperation du fournisseur.
     */
    private void validerNiveau(String texte, List<String> violations) {
        String brut = texte.trim();
        for (NiveauCecrl niveau : NIVEAUX_TCF_IRN) {
            if (niveau.name().equals(brut)) return;
        }
        violations.add(CompetenceAnalysisFields.LEVEL_REACHED + " doit valoir exactement "
            + "A1_NON_ATTEINT, A1, A2, B1 ou B2 (recu : " + brut + ")");
    }

    private void validerLongueur(String cle, String texte, List<String> violations) {
        Integer max = rubrics.contraintesLongueur().get(cle);
        if (max == null) return; // Pas de plafond declare pour ce champ (improved_version).
        int plafond = PlafondMots.tolere(max);
        int mots = compterMots(texte);
        if (mots > plafond) {
            violations.add(cle + " fait " + mots + " mots, le maximum est " + max
                + " (tolere jusqu'a " + plafond + ") : recris-le plus court");
        }
    }

    static int compterMots(String texte) {
        return PlafondMots.compter(texte);
    }
}
