package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Valide la sortie BRUTE du second appel, avant toute normalisation.
 *
 * <p>Le tool-schema borde déjà la forme côté fournisseur, mais rien ne garantit
 * qu'il soit respecté : un modèle peut renvoyer un champ vide, une clé en trop,
 * un seul levier ou un levier de trois lignes. Sans ce contrôle, le candidat
 * verrait un encart à moitié blanc.
 *
 * <p><b>Ordre de préférence du dépôt respecté</b> : le tool-schema d'abord
 * ({@code additionalProperties:false}, {@code minItems}/{@code maxItems},
 * {@code maxLength}), un contrôle serveur déterministe ensuite, la consigne en
 * dernier. Ce validateur est le deuxième étage.
 *
 * <p>Toutes les violations sont collectées, jamais la première seulement — même
 * si, ici, il n'y a pas de réessai : le log doit dire tout ce qui n'allait pas.
 */
@Component
public class VersionCibleeValidator {

    /** Nombre minimal de leviers : un seul ne montre pas un chemin, il montre un détail. */
    static final int MIN_LEVIERS = 2;

    /**
     * Tolérance appliquée aux plafonds de longueur avant rejet, identique à
     * celle du module Compétences : un plafond est une consigne pédagogique
     * (« une phrase courte »), pas un contrat machine. Perdre le bloc parce
     * qu'un levier fait 26 mots au lieu de 25 serait absurde.
     */
    static final double TOLERANCE_LONGUEUR = 1.2;

    /**
     * Prefixe des violations de LONGUEUR DU TEXTE MODELE. Il permet de les
     * distinguer des violations de structure, seules les premieres ouvrant droit
     * a une reparation (cf. {@link #uniquementLongueur(List)}).
     */
    static final String VIOLATION_LONGUEUR = "texte fait ";

    private final VersionCibleeRubricsProvider rubrics;

    public VersionCibleeValidator(VersionCibleeRubricsProvider rubrics) {
        this.rubrics = rubrics;
    }

    /**
     * @param bornes bornes de la tache ({@code production_tasks.mots_min/mots_max}
     *               croisees avec les garde-fous de configuration). Jamais null
     *               en production : c'est ce qui garantit qu'un texte modele est
     *               SOUMETTABLE sur la plateforme qui l'affiche.
     * @return la liste des violations, vide si la sortie est conforme.
     */
    public List<String> violations(Map<String, Object> sortie, int maxLeviers,
                                   ProductionTextBounds bornes) {
        List<String> violations = new ArrayList<>();
        if (sortie == null || sortie.isEmpty()) {
            violations.add("sortie vide : texte et ce_qui_manque sont obligatoires");
            return violations;
        }

        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        vues.remove(VersionCibleeFields.TEXTE);
        vues.remove(VersionCibleeFields.CE_QUI_MANQUE);

        Object texte = sortie.get(VersionCibleeFields.TEXTE);
        if (!(texte instanceof String s)) {
            violations.add(VersionCibleeFields.TEXTE + " doit etre une chaine de caracteres");
        } else if (s.isBlank()) {
            violations.add(VersionCibleeFields.TEXTE + " est vide");
        } else {
            validerLongueurTexte(s, bornes, violations);
        }

        Object leviers = sortie.get(VersionCibleeFields.CE_QUI_MANQUE);
        if (!(leviers instanceof List<?> liste)) {
            violations.add(VersionCibleeFields.CE_QUI_MANQUE + " doit etre une liste");
        } else {
            validerLeviers(liste, maxLeviers, violations);
        }

        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + enTrop);
        }
        return violations;
    }

    /**
     * LONGUEUR DU TEXTE MODELE — controle DUR, sans tolerance.
     *
     * <p>La tolerance de 20 % appliquee aux leviers ne vaut PAS ici : un levier
     * est une consigne pedagogique, le texte modele est une PRODUCTION, et
     * {@code ProductionEvaluationService.validateTextWordCount} refuse la
     * soumission d'un candidat au mot pres depuis que la tolerance historique a
     * ete supprimee (bornes EE strictes TCF IRN). Accorder ici 20 % de marge
     * reviendrait a rendre au candidat un modele que la plateforme refuserait de
     * recevoir — le defaut exact que ce controle corrige (63 et 64 mots rendus
     * sur une tache plafonnee a 60).
     *
     * <p>Le comptage est celui de la soumission ({@link ProductionPayloadSupport#countWords}) :
     * deux comptages differents suffiraient a laisser passer un texte refuse.
     */
    private static void validerLongueurTexte(String texte, ProductionTextBounds bornes,
                                             List<String> violations) {
        if (bornes == null) return;
        int mots = ProductionPayloadSupport.countWords(texte);
        if (bornes.accepte(mots)) return;
        violations.add(VIOLATION_LONGUEUR + mots + " mots, la tache en attend " + bornes.libelle());
    }

    /**
     * Vrai quand TOUTES les violations portent sur la longueur du texte modele.
     * C'est le seul cas ou une reparation est tentee : la longueur est un defaut
     * MECANIQUE, que le modele sait corriger si on lui dit le compte obtenu et le
     * compte attendu. Une sortie structurellement fausse (cle en trop, levier
     * manquant) n'ouvre droit a aucun second appel — le bloc reste un confort.
     */
    static boolean uniquementLongueur(List<String> violations) {
        return !violations.isEmpty()
            && violations.stream().allMatch(v -> v != null && v.startsWith(VIOLATION_LONGUEUR));
    }

    private void validerLeviers(List<?> liste, int maxLeviers, List<String> violations) {
        if (liste.size() < MIN_LEVIERS) {
            violations.add(VersionCibleeFields.CE_QUI_MANQUE + " compte " + liste.size()
                + " element(s), il en faut au moins " + MIN_LEVIERS);
        }
        if (liste.size() > maxLeviers) {
            violations.add(VersionCibleeFields.CE_QUI_MANQUE + " compte " + liste.size()
                + " elements, le maximum est " + maxLeviers);
        }
        Integer plafond = rubrics.contraintesLongueur().get(VersionCibleeFields.CE_QUI_MANQUE);
        int i = 0;
        for (Object levier : liste) {
            i++;
            if (!(levier instanceof String texte)) {
                violations.add(VersionCibleeFields.CE_QUI_MANQUE + "[" + i
                    + "] doit etre une chaine de caracteres");
                continue;
            }
            if (texte.isBlank()) {
                violations.add(VersionCibleeFields.CE_QUI_MANQUE + "[" + i + "] est vide");
                continue;
            }
            if (plafond == null) continue;
            int max = (int) Math.floor(plafond * TOLERANCE_LONGUEUR);
            int mots = compterMots(texte);
            if (mots > max) {
                violations.add(VersionCibleeFields.CE_QUI_MANQUE + "[" + i + "] fait " + mots
                    + " mots, le maximum est " + plafond + " (tolere jusqu'a " + max + ")");
            }
        }
    }

    static int compterMots(String texte) {
        String normalise = texte.trim();
        if (normalise.isEmpty()) return 0;
        return normalise.split("\\s+").length;
    }
}
