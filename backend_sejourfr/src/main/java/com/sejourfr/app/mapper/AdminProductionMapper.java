package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.AdminActeurDto;
import com.sejourfr.app.dto.AdminProductionCompteursDto;
import com.sejourfr.app.dto.AdminProductionDetailDto;
import com.sejourfr.app.dto.AdminProductionFlagDto;
import com.sejourfr.app.dto.AdminProductionListItemDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.AiEvaluationFlag;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AdminProductionContexte;
import com.sejourfr.app.enums.AdminProductionStatutIa;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.EtatSignalement;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionSubmissionSource;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.repository.AdminProductionReadRepository;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Mapper PUR de la console « Productions IA » : il reçoit les lignes et les
 * entités déjà chargées par le service, il ne lit rien.
 */
@Component
public class AdminProductionMapper {

    static final String AUDIO_MOTIF =
            "Audio non conservé : l'enregistrement ne sert qu'à produire la transcription, "
                    + "puis il est supprimé (décision de consentement).";

    public AdminProductionCompteursDto compteurs(AdminProductionReadRepository.Compteurs c) {
        return new AdminProductionCompteursDto(
                n(c.getTotal()), n(c.getEe()), n(c.getEo()), n(c.getAvecExaminateur()),
                n(c.getEvaluees()), n(c.getNonEvaluables()), n(c.getEnEchec()), n(c.getEnCours()),
                n(c.getSignalees()));
    }

    private static long n(Number value) {
        return value == null ? 0 : value.longValue();
    }

    public AdminProductionListItemDto listItem(AdminProductionReadRepository.Ligne l) {
        AdminProductionContexte contexte = AdminProductionContexte.of(
                Boolean.TRUE.equals(l.getExamenComplet()), Boolean.TRUE.equals(l.getExamenBlanc()));
        AdminProductionStatutIa statut = AdminProductionStatutIa.valueOf(l.getStatutIa());
        EtatSignalement etat = EtatSignalement.valueOf(l.getEtatSignalement());
        return new AdminProductionListItemDto(
                l.getId(),
                l.getSubmittedAt(),
                l.getUserId(),
                l.getUserEmail(),
                Boolean.TRUE.equals(l.getUserInternal()),
                EpreuveType.valueOf(l.getEpreuve()),
                l.getTache() == null ? 0 : l.getTache().intValue(),
                ProductionSubmissionSource.valueOf(l.getSource()),
                contexte,
                contexte.label(),
                l.getNiveau() == null ? null : NiveauCecrl.valueOf(l.getNiveau()),
                statut,
                statut.label(),
                etat,
                etat.label(),
                Boolean.TRUE.equals(l.getAnnotee()));
    }

    public AdminProductionDetailDto.Sujet sujet(ProductionTask t) {
        return new AdminProductionDetailDto.Sujet(
                t.getId(), t.getTitre(), t.getConsigne(), t.getContexte(), t.getNiveauCible(),
                t.getMotsMin(), t.getMotsMax(), t.getDureeMinSec(), t.getDureeMaxSec());
    }

    /**
     * @param transcription texte recollé (EO), {@code null} en EE
     * @param meta          métadonnées de la transcription, {@code null} sans transcription
     */
    public AdminProductionDetailDto.Reponse reponse(ProductionSubmission s, String transcription,
                                                    TranscriptionManager.TranscriptionMeta meta) {
        AdminProductionDetailDto.TranscriptionInfo info = meta == null ? null
                : new AdminProductionDetailDto.TranscriptionInfo(
                        meta.modeleUtilise(), meta.langueDetectee(), meta.audioDurationSec(),
                        meta.qualiteDegradee(), meta.tauxFormesSuspectes(), meta.tauxCollages(),
                        meta.avgLogprob(), meta.noSpeechProb(), meta.compressionRatio(), meta.coutMicroUsd());
        boolean oral = s.getProductionTask() != null && s.getProductionTask().getEpreuve() == EpreuveType.TCF_EO;
        return new AdminProductionDetailDto.Reponse(
                s.getTexteSoumis(),
                s.getMotsCount(),
                transcription,
                s.getMediaDurationSec(),
                false,
                oral ? AUDIO_MOTIF : null,
                info);
    }

    /**
     * @param poidsParCode         poids de la grille de l'évaluation (vide si non traçable)
     * @param niveauMontreAuCandidat le DTO candidat porte-t-il un niveau
     */
    public AdminProductionDetailDto.EvaluationIa evaluationIa(AiEvaluation e, long nbEvaluations,
                                                              Map<String, BigDecimal> poidsParCode,
                                                              boolean niveauMontreAuCandidat) {
        Map<String, Object> f = e.getFeedbackJson() == null ? Map.of() : e.getFeedbackJson();
        List<AdminProductionDetailDto.CritereRetenu> criteres = new ArrayList<>();
        if (f.get("scores_criteres") instanceof List<?> scores) {
            for (Object o : scores) {
                if (!(o instanceof Map<?, ?> m)) continue;
                String code = texte(m.get("code"));
                criteres.add(new AdminProductionDetailDto.CritereRetenu(
                        code,
                        texte(m.get("label")),
                        m.get("note_sur_20") instanceof Number n ? new BigDecimal(n.toString()) : null,
                        code == null ? null : poidsParCode.get(code),
                        texte(m.get("bande")),
                        texte(m.get("commentaire")),
                        texte(m.get("preuve"))));
            }
        }
        NiveauCecrl ia = e.getNiveauCecrlIa();
        NiveauCecrl retenu = e.getNiveauCecrl();
        return new AdminProductionDetailDto.EvaluationIa(
                e.getId(),
                e.getEvaluabilite(),
                e.getEvaluatedAt(),
                nbEvaluations,
                criteres,
                e.getNoteSur20(),
                ia,
                retenu,
                ia == null || retenu == null ? null : retenu.ordinal() - ia.ordinal(),
                niveauMontreAuCandidat,
                texte(f.get("confiance")),
                textes(f.get("confiance_raisons")),
                texte(f.get("justification_niveau")),
                textes(f.get("avertissements")));
    }

    public AdminProductionDetailDto.Technique technique(ProductionSubmission s, AiEvaluation e) {
        Long delai = e == null || e.getEvaluatedAt() == null || s.getSubmittedAt() == null ? null
                : Duration.between(s.getSubmittedAt(), e.getEvaluatedAt()).getSeconds();
        return new AdminProductionDetailDto.Technique(
                e == null ? null : e.getModeleUtilise(),
                e == null ? null : e.getPromptVersion(),
                e == null ? null : e.getRubricsVersion(),
                e == null ? null : e.getTokensInput(),
                e == null ? null : e.getTokensInputCacheHit(),
                e == null ? null : e.getTokensOutput(),
                e == null ? null : e.getCoutMicroUsd(),
                e == null ? null : e.getCoutEstimeCentimesLegacy(),
                s.getSubmittedAt(),
                e == null ? null : e.getEvaluatedAt(),
                delai,
                s.getRetryCount(),
                s.getErreurMessage());
    }

    /** @param acteurs comptes des admins cités, par id (un compte absent sort sans email) */
    public AdminProductionFlagDto flag(AiEvaluationFlag f, Map<UUID, User> acteurs) {
        EtatSignalement etat = etat(f);
        return new AdminProductionFlagDto(
                f.getId(), f.getSubmissionId(), f.getEvaluationId(),
                f.getMotif(), f.getMotif().label(), f.getCommentaire(),
                etat, etat.label(),
                f.getCreatedAt(), acteur(f.getCreatedBy(), acteurs),
                f.getVerifiedAt(), acteur(f.getVerifiedBy(), acteurs),
                f.getRemovedAt(), acteur(f.getRemovedBy(), acteurs));
    }

    public static EtatSignalement etat(AiEvaluationFlag f) {
        if (f.getRemovedAt() != null) return EtatSignalement.RETIRE;
        if (f.getVerifiedAt() != null) return EtatSignalement.VERIFIE;
        return EtatSignalement.SIGNALE;
    }

    private static AdminActeurDto acteur(UUID id, Map<UUID, User> acteurs) {
        if (id == null) return null;
        User u = acteurs.get(id);
        if (u == null) return new AdminActeurDto(id, null, null);
        String nom = String.join(" ",
                u.getFirstName() == null ? "" : u.getFirstName().trim(),
                u.getLastName() == null ? "" : u.getLastName().trim()).trim();
        return new AdminActeurDto(id, u.getEmail(), nom.isEmpty() ? null : nom);
    }

    private static String texte(Object o) {
        return o == null ? null : o.toString();
    }

    private static List<String> textes(Object o) {
        if (!(o instanceof List<?> l)) return List.of();
        List<String> out = new ArrayList<>();
        for (Object x : l) if (x != null) out.add(x.toString());
        return out;
    }
}
