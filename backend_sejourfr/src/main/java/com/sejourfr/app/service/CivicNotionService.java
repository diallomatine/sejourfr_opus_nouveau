package com.sejourfr.app.service;

import com.sejourfr.app.dto.CivicNotionDto;
import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.CivicNotionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Le referentiel de notions civiques et son tagging</b> (lot L8).
 *
 * <h2>Ce que ce service refuse de faire</h2>
 * <ul>
 *   <li>🛑 <b>Appliquer un seuil de couverture.</b> La regle de {@code 50_}
 *       §6.1 degrade <b>par notion ET par mention</b> : une notion peut etre
 *       pleinement utilisable pour un candidat NAT et seulement visible en
 *       revision pour un CSP. Rendre un verdict global effacerait exactement
 *       cette nuance. On sert les comptes ; l'appelant tranche pour SA
 *       mention.</li>
 *   <li>🛑 <b>Compter une suggestion comme une couverture.</b> Une proposition
 *       de machine n'est pas un tag. Elles sont servies a part, et c'est
 *       volontairement visible.</li>
 *   <li>🛑 <b>Fusionner ou scinder tout seul.</b> {@code 50_} §6.1.3 :
 *       « Aucune fusion ni scission n'est appliquee automatiquement : le job
 *       propose, un humain valide. »</li>
 *   <li>🛑 <b>Appeler un LLM.</b> Rien ici n'en emet, et la table de
 *       suggestions reste vide tant que le proprietaire n'a pas autorise la
 *       depense.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CivicNotionService {

    private final CivicNotionManager manager;

    /** Le referentiel, avec la couverture <b>mesuree</b> de chaque notion. */
    @Transactional(readOnly = true)
    public List<CivicNotionDto> referentiel() {
        Map<UUID, Map<String, Long>> couverture = new LinkedHashMap<>();
        for (Object[] row : manager.couvertureParNotionEtMention()) {
            UUID notionId = (UUID) row[0];
            couverture.computeIfAbsent(notionId, k -> new LinkedHashMap<>())
                    .merge(String.valueOf(row[1]), ((Number) row[2]).longValue(), Long::sum);
        }
        Map<UUID, Long> suggestions = new LinkedHashMap<>();
        for (Object[] row : manager.suggestionsParNotion()) {
            suggestions.put((UUID) row[0], ((Number) row[1]).longValue());
        }

        List<CivicNotionDto> out = new ArrayList<>();
        for (CivicNotion notion : manager.findAllOrdonnees()) {
            Map<String, Long> parMention =
                    couverture.getOrDefault(notion.getId(), Map.of());
            List<CivicNotionDto.CouvertureMention> mentions = parMention.entrySet().stream()
                    .map(e -> new CivicNotionDto.CouvertureMention(e.getKey(), e.getValue()))
                    .sorted(java.util.Comparator.comparing(
                            CivicNotionDto.CouvertureMention::mention))
                    .toList();
            out.add(new CivicNotionDto(
                    notion.getId(),
                    notion.getCode(),
                    notion.getLabel(),
                    notion.getThemeCode(),
                    notion.getDisplayOrder(),
                    notion.isActive(),
                    notion.getMergedInto() == null ? null : notion.getMergedInto().getCode(),
                    mentions.stream()
                            .mapToLong(CivicNotionDto.CouvertureMention::questions).sum(),
                    mentions,
                    suggestions.getOrDefault(notion.getId(), 0L)));
        }
        return out;
    }

    /**
     * La file de tagging : ce qu'il reste a faire, et ce qu'une machine
     * proposait le cas echeant.
     *
     * <p>🛑 Les suggestions accompagnent, elles ne decident pas. Aucune n'est
     * pre-selectionnee : un tag valide est toujours un geste humain.
     *
     * @param theme  code de theme, ou {@code null} pour tous
     * @param tagged {@code false} = la file de travail ; {@code null} = les deux
     */
    @Transactional(readOnly = true)
    public FileDeTagging fileDeTagging(String theme, Boolean tagged, int limit, int offset) {
        List<Object[]> rows = manager.fileDeTagging(theme, tagged, limit, offset);
        List<UUID> ids = rows.stream().map(r -> (UUID) r[0]).toList();

        Map<UUID, List<com.sejourfr.app.dto.QuestionTaggingDto.Suggestion>> suggestions =
                new LinkedHashMap<>();
        for (Object[] row : manager.suggestionsParQuestions(ids)) {
            suggestions.computeIfAbsent((UUID) row[0], k -> new ArrayList<>())
                    .add(new com.sejourfr.app.dto.QuestionTaggingDto.Suggestion(
                            String.valueOf(row[1]), String.valueOf(row[2]),
                            ((Number) row[3]).doubleValue()));
        }

        List<com.sejourfr.app.dto.QuestionTaggingDto> questions = rows.stream()
                .map(row -> new com.sejourfr.app.dto.QuestionTaggingDto(
                        (UUID) row[0],
                        String.valueOf(row[1]),
                        String.valueOf(row[2]),
                        String.valueOf(row[3]),
                        row[4] == null ? null : String.valueOf(row[4]),
                        row[5] == null ? null : String.valueOf(row[5]),
                        suggestions.getOrDefault((UUID) row[0], List.of())))
                .toList();

        return new FileDeTagging(questions, manager.resteATaguer());
    }

    /** @param resteATaguer questions civiques actives encore sans notion, TOUS themes */
    public record FileDeTagging(
            List<com.sejourfr.app.dto.QuestionTaggingDto> questions,
            long resteATaguer) {}

    /**
     * Pose ou efface le tag <b>valide</b> d'une question.
     *
     * <p>🛑 <b>{@code notionCode} nul efface</b> : se tromper doit rester
     * rattrapable depuis l'ecran, sans passer par la base. Effacer ne dit pas
     * « cette question n'a pas de notion », mais « elle attend a nouveau ».
     *
     * <p>Une notion <b>desactivee</b> (fusionnee) est refusee : la poser
     * recreerait du travail a defaire au tour suivant.
     */
    @Transactional
    public void taguer(UUID questionId, String notionCode) {
        CivicNotion notion = null;
        if (notionCode != null && !notionCode.isBlank()) {
            notion = manager.findByCode(notionCode)
                    .orElseThrow(() -> new NotFoundException("Notion inconnue : " + notionCode));
            if (!notion.isActive()) {
                throw new com.sejourfr.app.exception.BusinessException(
                        "La notion « " + notion.getLabel() + " » a été fusionnée : "
                                + "choisissez celle qui la reprend.");
            }
        }
        int touchees = manager.poserNotion(questionId, notion);
        if (touchees == 0) {
            throw new NotFoundException("Question introuvable : " + questionId);
        }
        log.info("Tagging civique : question={} notion={}", questionId, notionCode);
    }
}
