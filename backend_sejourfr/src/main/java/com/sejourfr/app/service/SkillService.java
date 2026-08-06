package com.sejourfr.app.service;

import com.sejourfr.app.dto.SkillDetailDto;
import com.sejourfr.app.dto.SkillDto;
import com.sejourfr.app.dto.SkillPromptDto;
import com.sejourfr.app.dto.SkillPromptSummaryDto;
import com.sejourfr.app.dto.SkillReferenceDto;
import com.sejourfr.app.dto.SkillTaskProgressDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillPromptStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.mapper.SkillMapper;
import com.sejourfr.app.mapper.SkillPromptMapper;
import com.sejourfr.app.mapper.SkillReferenceMapper;
import com.sejourfr.app.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Lecture du catalogue de competences, toujours enrichie de la progression du
 * candidat courant.
 *
 * <p>Trois principes structurent ce service :
 * <ul>
 *   <li><b>Le statut d'un sujet est calcule ici, jamais par un front</b> — via
 *       {@link SkillStatusResolver}, a partir de la derniere tentative.</li>
 *   <li><b>Une requete par ecran, pas une par ligne</b> : les tentatives et les
 *       compteurs sont charges en lot pour toute la tache ou toute la
 *       competence, puis croises en memoire.</li>
 *   <li><b>Les references ne sortent qu'apres la production</b> — la garde est
 *       ici, pas seulement dans l'interface.</li>
 * </ul>
 *
 * <p>Le denominateur des compteurs (« X sujets sur Y ») ne retient que les
 * sujets et les competences ACTIFS ; l'historique d'un candidat sur un sujet
 * desactive est conserve en base, il cesse simplement d'etre affiche.
 */
@Service
@RequiredArgsConstructor
public class SkillService {

    private final SkillManager skillManager;
    private final SkillPromptManager promptManager;
    private final UserSkillAttemptManager attemptManager;
    private final SkillStatusResolver statusResolver;
    private final SkillMapper skillMapper;
    private final SkillPromptMapper promptMapper;
    private final SkillReferenceMapper referenceMapper;
    private final CurrentUser currentUser;

    /**
     * Resume des 3 taches d'une epreuve, pour l'ecran de choix. Les 3 entrees
     * sont TOUJOURS presentes, meme sans contenu publie : une tache vide
     * s'affiche a zero, elle ne disparait pas de l'ecran.
     */
    @Transactional(readOnly = true)
    public List<SkillTaskProgressDto> progress(SkillSection section) {
        UUID userId = currentUser.getId();
        List<SkillTaskCode> taskCodes = SkillTaskCode.of(section);

        Map<SkillTaskCode, Long> skillCounts = skillManager.countActiveByTaskCode(taskCodes);
        Map<UUID, Long> promptCountBySkill = promptManager.countActiveBySkillForTaskCodes(taskCodes);
        Map<UUID, UserSkillAttempt> latestByPrompt =
                attemptManager.findLatestPerPromptByTaskCodes(userId, taskCodes);

        // Sujets actifs par tache : somme des sujets de ses competences actives.
        Map<SkillTaskCode, Integer> promptCountByTask = new EnumMap<>(SkillTaskCode.class);
        for (SkillTaskCode code : taskCodes) {
            promptCountByTask.put(code, 0);
        }
        for (Skill skill : skillManager.findActiveBySection(section)) {
            long prompts = promptCountBySkill.getOrDefault(skill.getId(), 0L);
            promptCountByTask.merge(skill.getTaskCode(), (int) prompts, Integer::sum);
        }

        Map<SkillTaskCode, Tally> tallies = new EnumMap<>(SkillTaskCode.class);
        for (SkillTaskCode code : taskCodes) {
            tallies.put(code, new Tally());
        }
        for (UserSkillAttempt attempt : latestByPrompt.values()) {
            SkillPrompt prompt = attempt.getSkillPrompt();
            if (!isVisible(prompt)) continue;
            tallies.get(prompt.getSkill().getTaskCode()).add(statusResolver.resolve(attempt));
        }

        List<SkillTaskProgressDto> out = new ArrayList<>(taskCodes.size());
        for (SkillTaskCode code : taskCodes) {
            Tally tally = tallies.get(code);
            out.add(new SkillTaskProgressDto(
                    code,
                    section,
                    code.getTitle(),
                    code.getTargetLevel(),
                    skillCounts.getOrDefault(code, 0L).intValue(),
                    promptCountByTask.getOrDefault(code, 0),
                    tally.attempted,
                    tally.validated,
                    tally.toReinforce));
        }
        return out;
    }

    /** Les competences actives d'une tache, avec la progression du candidat. */
    @Transactional(readOnly = true)
    public List<SkillDto> listByTaskCode(SkillTaskCode taskCode) {
        UUID userId = currentUser.getId();
        List<SkillTaskCode> scope = List.of(taskCode);

        Map<UUID, Long> promptCountBySkill = promptManager.countActiveBySkillForTaskCodes(scope);
        Map<UUID, UserSkillAttempt> latestByPrompt =
                attemptManager.findLatestPerPromptByTaskCodes(userId, scope);

        Map<UUID, Tally> tallyBySkill = new HashMap<>();
        for (UserSkillAttempt attempt : latestByPrompt.values()) {
            SkillPrompt prompt = attempt.getSkillPrompt();
            if (!isVisible(prompt)) continue;
            tallyBySkill.computeIfAbsent(prompt.getSkill().getId(), k -> new Tally())
                    .add(statusResolver.resolve(attempt));
        }

        List<SkillDto> out = new ArrayList<>();
        for (Skill skill : skillManager.findActiveByTaskCode(taskCode)) {
            Tally tally = tallyBySkill.getOrDefault(skill.getId(), new Tally());
            out.add(skillMapper.toDto(
                    skill,
                    promptCountBySkill.getOrDefault(skill.getId(), 0L).intValue(),
                    tally.attempted,
                    tally.validated,
                    tally.toReinforce));
        }
        return out;
    }

    /** Detail d'une competence : sa fiche et ses sujets avec leur statut. */
    @Transactional(readOnly = true)
    public SkillDetailDto detail(UUID skillId) {
        UUID userId = currentUser.getId();
        Skill skill = loadActiveSkill(skillId);

        List<SkillPrompt> prompts = promptManager.findActiveBySkillId(skillId);
        Map<UUID, UserSkillAttempt> latestByPrompt =
                attemptManager.findLatestPerPromptBySkill(userId, skillId);
        Map<UUID, Long> attemptCounts = attemptManager.countPerPromptBySkill(userId, skillId);

        Tally tally = new Tally();
        List<SkillPromptSummaryDto> summaries = new ArrayList<>(prompts.size());
        for (SkillPrompt prompt : prompts) {
            UserSkillAttempt latest = latestByPrompt.get(prompt.getId());
            SkillPromptStatus status = statusResolver.resolve(latest);
            tally.add(status);
            summaries.add(promptMapper.toSummaryDto(
                    prompt,
                    status,
                    attemptCounts.getOrDefault(prompt.getId(), 0L).intValue(),
                    latest == null ? null : latest.getCreatedAt()));
        }

        SkillDto dto = skillMapper.toDto(
                skill, prompts.size(), tally.attempted, tally.validated, tally.toReinforce);
        return new SkillDetailDto(dto, summaries);
    }

    /** Le sujet complet pour l'ecran de production. Ne contient jamais les references. */
    @Transactional(readOnly = true)
    public SkillPromptDto prompt(UUID promptId) {
        UUID userId = currentUser.getId();
        SkillPrompt prompt = loadActivePrompt(promptId);
        Skill skill = prompt.getSkill();

        Map<UUID, UserSkillAttempt> latestByPrompt =
                attemptManager.findLatestPerPromptBySkill(userId, skill.getId());
        UserSkillAttempt latest = latestByPrompt.get(promptId);
        long attemptCount = attemptManager.countByUserAndPrompt(userId, promptId);

        // Les sujets freres servent DEUX fois : leur nombre est le denominateur
        // du fil d'Ariane « Sujet i/5 », et leur parcours donne le sujet suivant.
        // Les charger une fois evite a l'ecran de production un second appel a
        // GET /api/skills/{skillId} pour ces seules informations.
        List<SkillPrompt> siblings = promptManager.findActiveBySkillId(skill.getId());

        return promptMapper.toDto(
                prompt,
                skill,
                siblings.size(),
                statusResolver.resolve(latest),
                (int) attemptCount,
                latest == null ? null : latest.getCreatedAt(),
                latest == null ? null : latest.getId(),
                nextTodoPromptId(siblings, promptId, latestByPrompt));
    }

    /**
     * Les 3 references d'un sujet.
     *
     * <p><b>403 si le candidat n'a aucune tentative sur ce sujet</b> : les
     * references sont des productions modeles, les lire avant de produire
     * transformerait l'exercice en recopie. La garde vit ici et pas seulement
     * dans l'interface — sinon un appel direct a l'API suffirait a la
     * contourner.
     */
    @Transactional(readOnly = true)
    public List<SkillReferenceDto> references(UUID promptId) {
        UUID userId = currentUser.getId();
        SkillPrompt prompt = loadActivePrompt(promptId);
        if (!attemptManager.hasAttempted(userId, prompt.getId())) {
            throw new AccessDeniedException(
                    "Les productions de référence ne s'affichent qu'après votre propre réponse "
                            + "à ce sujet.");
        }
        return promptManager.findReferencesByPromptId(prompt.getId()).stream()
                .map(referenceMapper::toDto)
                .toList();
    }

    // ------------------------------------------------------------------------
    // Interne
    // ------------------------------------------------------------------------

    /**
     * Premier sujet encore {@code TODO} de la competence, sujet courant exclu.
     * L'exclusion est volontaire : proposer « sujet suivant » vers celui qu'on
     * est en train de faire n'aurait aucun sens. {@code null} quand il n'en
     * reste aucun — le bouton se desactive, il ne bloque jamais.
     */
    private UUID nextTodoPromptId(List<SkillPrompt> siblings, UUID currentPromptId,
                                  Map<UUID, UserSkillAttempt> latestByPrompt) {
        for (SkillPrompt candidate : siblings) {
            if (candidate.getId().equals(currentPromptId)) continue;
            if (statusResolver.resolve(latestByPrompt.get(candidate.getId()))
                    == SkillPromptStatus.TODO) {
                return candidate.getId();
            }
        }
        return null;
    }

    private Skill loadActiveSkill(UUID skillId) {
        return skillManager.findActiveById(skillId)
                .orElseThrow(() -> new NotFoundException("Compétence introuvable : " + skillId));
    }

    private SkillPrompt loadActivePrompt(UUID promptId) {
        return promptManager.findActiveByIdWithSkill(promptId)
                .orElseThrow(() -> new NotFoundException("Sujet introuvable : " + promptId));
    }

    /** Un sujet ne compte dans la progression que s'il est encore affichable. */
    private static boolean isVisible(SkillPrompt prompt) {
        return prompt.isActive() && prompt.getSkill().isActive();
    }

    /** Compteurs de progression accumules sur un ensemble de sujets. */
    private static final class Tally {
        private int attempted;
        private int validated;
        private int toReinforce;

        void add(SkillPromptStatus status) {
            if (!status.isAttempted()) return;
            attempted++;
            if (status == SkillPromptStatus.VALIDATED) validated++;
            if (status == SkillPromptStatus.TO_REINFORCE) toReinforce++;
        }
    }
}
