package com.sejourfr.app.controller;

import com.sejourfr.app.dto.SkillAnalysisQuotaDto;
import com.sejourfr.app.dto.SkillDetailDto;
import com.sejourfr.app.dto.SkillDto;
import com.sejourfr.app.dto.SkillPromptDto;
import com.sejourfr.app.dto.SkillReferenceDto;
import com.sejourfr.app.dto.SkillTaskProgressDto;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.SkillAnalysisAccessService;
import com.sejourfr.app.service.SkillService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Lecture du catalogue de competences pour le candidat connecte. Aucune route
 * publique : toute la progression est nominative.
 *
 * <p>Toute la logique vit dans {@link SkillService} ; les endpoints admin sont
 * ailleurs. Les chemins litteraux ({@code /progress}, {@code /analysis-quota})
 * l'emportent sur {@code /{skillId}} : Spring classe un segment fixe avant une
 * variable de chemin.
 */
@RestController
@RequiredArgsConstructor
public class SkillController {

    private final SkillService skillService;
    private final SkillAnalysisAccessService analysisAccessService;
    private final CurrentUser currentUser;

    /**
     * Resume des 3 taches d'une epreuve pour l'ecran de choix : combien de
     * competences, combien de sujets, et ou en est le candidat.
     */
    @GetMapping("/api/skills/progress")
    public List<SkillTaskProgressDto> progress(@RequestParam SkillSection section) {
        return skillService.progress(section);
    }

    /**
     * Etat du quota d'analyses IA du candidat. {@code remaining = -1} signifie
     * illimite : les fronts ne doivent jamais afficher cette valeur brute.
     */
    @GetMapping("/api/skills/analysis-quota")
    public SkillAnalysisQuotaDto analysisQuota() {
        return analysisAccessService.quota(currentUser.getId());
    }

    /**
     * Les competences actives d'une tache ({@code taskCode}) ou d'une epreuve
     * entiere ({@code section}), avec la progression du candidat.
     *
     * <p>Les deux parametres sont facultatifs <b>individuellement</b> ; en
     * fournir au moins un est obligatoire, et l'arbitrage (tache prioritaire,
     * refus des filtres contradictoires) appartient au service — c'est une
     * regle metier, pas une contrainte de transport, et elle doit valoir aussi
     * pour un appelant qui ne passerait pas par HTTP.
     */
    @GetMapping("/api/skills")
    public List<SkillDto> list(@RequestParam(required = false) SkillSection section,
                               @RequestParam(required = false) SkillTaskCode taskCode) {
        return skillService.list(section, taskCode);
    }

    /** Detail d'une competence : sa fiche et ses petits sujets avec leur statut. */
    @GetMapping("/api/skills/{skillId}")
    public SkillDetailDto detail(@PathVariable UUID skillId) {
        return skillService.detail(skillId);
    }

    /**
     * Le sujet complet, pour l'ecran de production. Ne contient jamais les
     * productions de reference — elles ont leur propre route, gardee.
     */
    @GetMapping("/api/skill-prompts/{promptId}")
    public SkillPromptDto prompt(@PathVariable UUID promptId) {
        return skillService.prompt(promptId);
    }

    /**
     * Les 3 productions de reference du sujet. <b>403 tant que le candidat n'a
     * rien produit sur ce sujet</b> : les lire avant transformerait l'exercice
     * en recopie.
     */
    @GetMapping("/api/skill-prompts/{promptId}/references")
    public List<SkillReferenceDto> references(@PathVariable UUID promptId) {
        return skillService.references(promptId);
    }
}
