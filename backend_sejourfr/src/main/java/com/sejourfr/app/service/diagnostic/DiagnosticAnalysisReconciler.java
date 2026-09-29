package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.ObservationConfidence;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * LE SERVEUR DÉRIVE, IL NE REFUSE PLUS — étape déterministe appliquée à la
 * sortie du correcteur <b>avant</b> {@link DiagnosticAnalysisValidator}.
 *
 * <p>Deux motifs de refus ont détruit un diagnostic réel en production, donc les
 * deux productions du candidat :
 * <ol>
 *   <li>« priority et status PRIORITY divergent » — un invariant <b>qui n'était
 *       écrit nulle part dans le prompt</b>, sur un champ entièrement
 *       <b>redondant</b> : {@code priority} ne porte aucune information que
 *       {@code status} n'ait déjà. C'est {@code status} qui est persisté sur
 *       {@code learning_plan_observations}, contraint en base et lu par tout le
 *       moteur du Plan : il fait foi, {@code priority} s'en déduit ;</li>
 *   <li>« maximum 2 priorités par production » — un plafond, donc une
 *       <b>troncature</b>, comme {@code capListe} côté évaluation : plafond
 *       déclaré au contrat, troncature serveur.</li>
 * </ol>
 *
 * <p>Deux motifs de plus l'ont fait ensuite, le 2026-08-25, sur une production
 * orale réelle (submission {@code 3136658f}) : {@code « summary dépasse 280
 * caractères »} et {@code « une compétence non observée doit avoir une
 * confiance LOW »}. Même nature, même remède :
 * <ol start="3">
 *   <li><b>les plafonds de longueur</b> ({@code summary}, un item de
 *       {@code strengths} / {@code weaknesses}, une {@code explanation}) et le
 *       plafond de trois items par liste sont des <b>troncatures</b>. Ils sont
 *       déclarés au tool-schema en {@code maxLength} / {@code maxItems}, mais
 *       <b>aucun fournisseur ne les applique</b> : contrairement à
 *       {@code enum}, {@code required} et {@code additionalProperties}, une
 *       longueur n'est pour le modèle qu'une indication. Le seul endroit où
 *       elle peut devenir dure, c'est ici ;</li>
 *   <li><b>la confiance d'une compétence non observée</b> est {@code LOW} par
 *       construction : {@code observed=false} ne porte aucune information sur
 *       le candidat, donc aucune confiance à graduer. C'est une dérivation,
 *       exactement comme {@code priority}.</li>
 * </ol>
 *
 * <p><b>Ce qui reste un refus</b>, et doit le rester : ce que le serveur ne
 * peut pas inventer sans mentir — un {@code skill_code} hors allowlist, une
 * compétence manquante, un {@code evidence_segment} hors bornes, un enum
 * invalide, un champ hors contrat. Une preuve posée sur une compétence
 * déclarée non observée n'est pas non plus effacée ici : c'est une
 * contradiction du correcteur, pas une mise en forme.
 *
 * <p>Le contrat v1 ne bouge pas (ni rubriques, ni tool-schema) : le retrait du
 * champ à la source est une passe v2 séparée. Ici, on cesse simplement de punir
 * ce qu'on sait recalculer.
 *
 * <p><b>Le serveur n'abaisse jamais qu'un cran et ne relève jamais</b> — même
 * philosophie que {@code applyCouplage} / {@code applyPlafonds} /
 * {@code applyConfiance} / {@code CompetenceLevelEvidenceGuard}.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DiagnosticAnalysisReconciler {

    private final DiagnosticReconciliationMetrics metrics;

    /**
     * Rend une copie de la sortie où les champs dérivés sont recalculés
     * ({@code priority} depuis {@code status}, la confiance d'une compétence
     * non observée) et où les plafonds du contrat sont appliqués par troncature
     * (priorités, longueurs, taille des listes). Ce qui n'est pas
     * structurellement exploitable est laissé tel quel : c'est le validateur qui
     * le refusera, et lui seul.
     *
     * @param allowedSkills allowlist du sujet, <b>déjà triée</b> par
     *                      {@code display_order} (l'ordre éditorial
     *                      d'importance) — son index sert de rang de départage.
     */
    public Map<String, Object> reconcile(Map<String, Object> output, List<Skill> allowedSkills) {
        if (output == null) return null;

        Map<String, Object> normalized = new LinkedHashMap<>(output);
        tronqueTexte(normalized, "summary",
                DiagnosticAnalysisValidator.MAX_SUMMARY_LENGTH,
                DiagnosticReconciliationMetrics.Motif.SYNTHESE_TRONQUEE);
        tronqueListe(normalized, "strengths");
        tronqueListe(normalized, "weaknesses");
        if (!(output.get("skills") instanceof List<?> skills)) return normalized;

        List<Object> reconciled = new ArrayList<>(skills.size());
        List<Map<String, Object>> priorities = new ArrayList<>();
        for (Object raw : skills) {
            if (!(raw instanceof Map<?, ?> skill)) {
                reconciled.add(raw);
                continue;
            }
            Map<String, Object> item = copy(skill);
            tronqueTexte(item, "explanation",
                    DiagnosticAnalysisValidator.MAX_EXPLANATION_LENGTH,
                    DiagnosticReconciliationMetrics.Motif.TEXTE_TRONQUE);
            // Une compétence non observée n'a rien à graduer : sa confiance est
            // LOW par construction, elle ne se déduit d'aucune preuve.
            if (Boolean.FALSE.equals(item.get("observed"))
                    && !ObservationConfidence.LOW.name().equals(item.get("confidence"))) {
                item.put("confidence", ObservationConfidence.LOW.name());
                metrics.enregistrer(
                        DiagnosticReconciliationMetrics.Motif.CONFIANCE_NON_OBSERVEE_DERIVEE);
            }
            boolean declared = Boolean.TRUE.equals(item.get("priority"));
            // Une compétence non observée n'est jamais prioritaire : le
            // validateur exige par ailleurs qu'elle soit NOT_OBSERVED.
            boolean observed = !Boolean.FALSE.equals(item.get("observed"));
            boolean derived = observed && LearningPlanSkillStatus.PRIORITY.name()
                    .equals(String.valueOf(item.get("status")).trim());
            if (declared != derived) {
                metrics.enregistrer(derived
                        ? DiagnosticReconciliationMetrics.Motif.PRIORITE_DERIVEE_POSEE
                        : DiagnosticReconciliationMetrics.Motif.PRIORITE_DERIVEE_RETIREE);
            }
            item.put("priority", derived);
            if (derived) priorities.add(item);
            reconciled.add(item);
        }
        tronque(priorities, allowedSkills);

        normalized.put("skills", reconciled);
        return normalized;
    }

    /**
     * Coupe un champ trop long sur une limite de mot, en marquant la coupe.
     *
     * <p>La longueur est la seule contrainte du contrat qu'un fournisseur ne
     * sait pas tenir : {@code maxLength} n'est pas opposable au modèle. Refuser
     * dessus revenait à payer une réparation entière — puis à perdre les deux
     * productions du candidat — pour une phrase de vingt caractères de trop.
     */
    private void tronqueTexte(
            Map<String, Object> porteur, String cle, int plafond,
            DiagnosticReconciliationMetrics.Motif motif) {
        if (!(porteur.get(cle) instanceof String texte) || texte.length() <= plafond) return;
        String coupe = couper(texte, plafond);
        porteur.put(cle, coupe);
        metrics.enregistrer(motif);
        log.info("Champ diagnostic tronqué {} : {} -> {} caractères (plafond {})",
                cle, texte.length(), coupe.length(), plafond);
    }

    /**
     * Applique les deux plafonds d'une liste de retour : trois items au plus,
     * chacun borné en longueur. Même patron que le plafond de priorités —
     * plafond déclaré au contrat, troncature serveur.
     */
    private void tronqueListe(Map<String, Object> porteur, String cle) {
        if (!(porteur.get(cle) instanceof List<?> liste)) return;
        List<Object> items = new ArrayList<>(liste);
        if (items.size() > DiagnosticAnalysisValidator.MAX_LIST_ITEMS) {
            items = new ArrayList<>(items.subList(0, DiagnosticAnalysisValidator.MAX_LIST_ITEMS));
            metrics.enregistrer(DiagnosticReconciliationMetrics.Motif.LISTE_TRONQUEE);
            log.info("Liste diagnostic tronquée {} : {} -> {} items",
                    cle, liste.size(), DiagnosticAnalysisValidator.MAX_LIST_ITEMS);
        }
        for (int index = 0; index < items.size(); index++) {
            if (!(items.get(index) instanceof String texte)
                    || texte.length() <= DiagnosticAnalysisValidator.MAX_LIST_ITEM_LENGTH) {
                continue;
            }
            items.set(index, couper(texte, DiagnosticAnalysisValidator.MAX_LIST_ITEM_LENGTH));
            metrics.enregistrer(DiagnosticReconciliationMetrics.Motif.TEXTE_TRONQUE);
        }
        porteur.put(cle, items);
    }

    /**
     * Coupe sur le dernier espace de la moitié haute, sinon en dur, et pose une
     * ellipse — un point final inventé ferait passer une phrase coupée pour une
     * phrase finie. Le résultat tient dans le plafond, ellipse comprise.
     */
    private static String couper(String texte, int plafond) {
        String coupe = texte.substring(0, plafond - 1);
        int espace = coupe.lastIndexOf(' ');
        if (espace > plafond / 2) coupe = coupe.substring(0, espace);
        return coupe.stripTrailing() + "…";
    }

    /**
     * Garde les deux meilleures priorités et abaisse le surplus d'un cran.
     *
     * <p>Départage : {@link DiagnosticPriorityRanking}, la règle partagée avec
     * l'assemblage des deux productions — confiance décroissante puis rang
     * d'allowlist, <b>jamais</b> l'alphabet du code.
     */
    private void tronque(List<Map<String, Object>> priorities, List<Skill> allowedSkills) {
        int plafond = DiagnosticAnalysisValidator.MAX_PRIORITIES_PER_PRODUCTION;
        if (priorities.size() <= plafond) return;
        Map<String, Integer> order = new HashMap<>();
        for (int rank = 0; rank < allowedSkills.size(); rank++) {
            order.put(allowedSkills.get(rank).getCode(), rank);
        }
        List<DiagnosticPriorityRanking.Ranked> ranked =
                DiagnosticPriorityRanking.ranked(priorities, order);
        for (DiagnosticPriorityRanking.Ranked surplus
                : ranked.subList(plafond, ranked.size())) {
            surplus.item().put("status", LearningPlanSkillStatus.TO_REINFORCE.name());
            surplus.item().put("priority", false);
            metrics.enregistrer(DiagnosticReconciliationMetrics.Motif.PRIORITE_TRONQUEE);
            log.info("Priorité diagnostic tronquée skill={} : PRIORITY -> TO_REINFORCE",
                    surplus.skillCode());
        }
    }

    /** Copie à plat, clés d'origine comprises : le validateur juge le contrat entier. */
    private static Map<String, Object> copy(Map<?, ?> skill) {
        Map<String, Object> item = new LinkedHashMap<>();
        skill.forEach((key, value) -> item.put(String.valueOf(key), value));
        return item;
    }
}
