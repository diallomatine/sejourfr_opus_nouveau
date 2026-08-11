package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.SkillAnalysisDto;
import com.sejourfr.app.dto.SkillAttemptDto;
import com.sejourfr.app.dto.SkillNiveauViseDto;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.ProductionAudioStorageService;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import com.sejourfr.app.service.competence.SkillLevelProgressResolver;
import com.sejourfr.app.service.competence.niveauvise.CompetenceNiveauViseFields;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Mapper {@link UserSkillAttempt} -&gt; {@link SkillAttemptDto}.
 *
 * <p>{@link #toDto} laisse {@code audioUrl} a {@code null} : la cle d'objet R2
 * brute ne doit jamais sortir du backend. {@link #toDtoWithSignedAudio} est la
 * seule variante qui expose l'audio, via une URL presignee a TTL court —
 * meme decoupage que {@code ProductionSubmissionMapper}, pour ne pas payer un
 * aller-retour R2 quand l'appelant n'a pas besoin d'ecouter.
 *
 * <p><b>Deux generations d'analyses cohabitent en base</b>, et rien n'a ete
 * migre : le contrat v1/v2 ({@code success_point},
 * {@code improvement_priority}, {@code improved_version}) et le contrat v3
 * ({@code level_reached}, {@code strength_tag}, {@code focus_tag}). Ce mapper
 * traduit ce qu'il trouve, champ par champ, et ne suppose jamais qu'une cle est
 * presente : une ligne ancienne doit continuer de s'afficher, pas de faire
 * echouer la requete.
 */
@Component
@RequiredArgsConstructor
public class SkillAttemptMapper {

    private final ProductionAudioStorageService audioStorage;

    public SkillAttemptDto toDto(UserSkillAttempt attempt) {
        return build(attempt, null);
    }

    /** Variante qui expose l'audio via une URL signee (TTL court). */
    public SkillAttemptDto toDtoWithSignedAudio(UserSkillAttempt attempt) {
        String key = attempt.getAudioObjectKey();
        if (key == null || key.isBlank()) {
            return build(attempt, null);
        }
        return build(attempt, audioStorage.presignGet(key));
    }

    private SkillAttemptDto build(UserSkillAttempt attempt, String audioUrl) {
        return new SkillAttemptDto(
                attempt.getId(),
                attempt.getSkillPrompt().getId(),
                attempt.getSkillPrompt().getCode(),
                attempt.getStatut(),
                attempt.isAnalysisRequested(),
                attempt.getWrittenProduction(),
                audioUrl,
                attempt.getAudioDurationSec(),
                attempt.getTranscript(),
                attempt.getWordsCount(),
                attempt.getSelfEvaluation(),
                attempt.getCriterionStatus(),
                toAnalysisDto(attempt),
                attempt.getErrorMessage(),
                attempt.getCreatedAt());
    }

    /**
     * Traduit le JSON persiste en DTO. Renvoie {@code null} tant qu'aucune
     * analyse n'a abouti — cas nominal du parcours gratuit, pas une erreur.
     *
     * <p>Le verdict expose est la colonne {@code criterion_status} et non la
     * cle {@code status} du JSON : c'est la colonne qui fait foi (c'est elle qui
     * derive le statut du sujet), et une seule source d'affichage evite qu'un
     * front lise une valeur et le calcul de progression une autre.
     *
     * <p>La jauge, elle, n'est pas lue du JSON : elle est <b>calculee ici a
     * partir du niveau persiste et de la demarche du candidat</b>
     * ({@link SkillLevelProgressResolver}). Le palier vise peut changer — un
     * candidat qui passe de CR a NAT vise soudain le B2 — et le figer dans
     * l'analyse aurait affiche un objectif perime sur toutes ses tentatives
     * anterieures.
     */
    private SkillAnalysisDto toAnalysisDto(UserSkillAttempt attempt) {
        Map<String, Object> json = attempt.getAnalysisJson();
        if (json == null || json.isEmpty()) return null;
        SkillCriterionStatus status = attempt.getCriterionStatus() != null
                ? attempt.getCriterionStatus()
                : SkillCriterionStatus.parse(json.get(CompetenceAnalysisFields.STATUS));
        NiveauCecrl niveau = niveauCecrl(json.get(CompetenceAnalysisFields.LEVEL_REACHED));
        return new SkillAnalysisDto(
                status,
                text(json, CompetenceAnalysisFields.VERDICT),
                text(json, CompetenceAnalysisFields.STRENGTH_TAG),
                text(json, CompetenceAnalysisFields.FOCUS_TAG),
                SkillLevelProgressResolver.resolve(
                        niveau, attempt.getUser(), attempt.getSkillPrompt().getSkill()),
                toNiveauViseDto(json.get(CompetenceAnalysisFields.BLOC_POUR_VISER)),
                text(json, CompetenceAnalysisFields.SUCCESS_POINT),
                text(json, CompetenceAnalysisFields.IMPROVEMENT_PRIORITY),
                text(json, CompetenceAnalysisFields.IMPROVED_VERSION));
    }

    /**
     * Bloc du SECOND appel. {@code null} des que le bloc est absent ou
     * inexploitable : il est best-effort, son absence est un cas normal que les
     * fronts traitent, et une traduction partielle afficherait un encart a moitie
     * blanc.
     */
    private static SkillNiveauViseDto toNiveauViseDto(Object brut) {
        Map<String, Object> bloc = asMap(brut);
        if (bloc == null) return null;

        List<SkillNiveauViseDto.Levier> leviers = new ArrayList<>();
        for (Map<String, Object> levier : asList(bloc.get(CompetenceNiveauViseFields.LEVIERS))) {
            leviers.add(new SkillNiveauViseDto.Levier(
                    text(levier, CompetenceNiveauViseFields.ACTION),
                    text(levier, CompetenceNiveauViseFields.EXEMPLE)));
        }

        SkillNiveauViseDto.ExempleCible exemple = null;
        Map<String, Object> exempleBrut = asMap(bloc.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE));
        if (exempleBrut != null) {
            List<SkillNiveauViseDto.Segment> segments = new ArrayList<>();
            for (Map<String, Object> segment
                    : asList(exempleBrut.get(CompetenceNiveauViseFields.SEGMENTS))) {
                segments.add(new SkillNiveauViseDto.Segment(
                        text(segment, CompetenceNiveauViseFields.EXTRAIT),
                        text(segment, CompetenceNiveauViseFields.APPORT)));
            }
            exemple = new SkillNiveauViseDto.ExempleCible(
                    text(exempleBrut, CompetenceNiveauViseFields.TEXTE), List.copyOf(segments));
        }

        SkillNiveauViseDto.ARetenir aRetenir = null;
        Map<String, Object> aRetenirBrut = asMap(bloc.get(CompetenceNiveauViseFields.A_RETENIR));
        if (aRetenirBrut != null) {
            aRetenir = new SkillNiveauViseDto.ARetenir(
                    text(aRetenirBrut, CompetenceNiveauViseFields.FORMULE),
                    text(aRetenirBrut, CompetenceNiveauViseFields.EXPLICATION));
        }

        return new SkillNiveauViseDto(
                targetLevel(bloc.get(CompetenceNiveauViseFields.NIVEAU_VISE)),
                niveauCecrl(bloc.get(CompetenceNiveauViseFields.NIVEAU_CONSTATE)),
                List.copyOf(leviers),
                exemple,
                aRetenir);
    }

    private static String text(Map<String, Object> json, String key) {
        Object raw = json.get(key);
        return raw == null ? null : raw.toString();
    }

    private static NiveauCecrl niveauCecrl(Object raw) {
        if (raw == null) return null;
        try {
            return NiveauCecrl.valueOf(raw.toString().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static TargetLevel targetLevel(Object raw) {
        if (raw == null) return null;
        try {
            return TargetLevel.valueOf(raw.toString().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> asMap(Object raw) {
        return raw instanceof Map<?, ?> m ? (Map<String, Object>) m : null;
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> asList(Object raw) {
        List<Map<String, Object>> out = new ArrayList<>();
        if (!(raw instanceof List<?> liste)) return out;
        for (Object item : liste) {
            if (item instanceof Map<?, ?> m) out.add((Map<String, Object>) m);
        }
        return out;
    }
}
