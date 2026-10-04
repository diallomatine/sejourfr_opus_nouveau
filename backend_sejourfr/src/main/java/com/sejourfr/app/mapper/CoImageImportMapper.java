package com.sejourfr.app.mapper;

import com.sejourfr.app.audioquestion.entity.AudioDraftStatus;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft;
import com.sejourfr.app.audioquestion.entity.AudioQuestionDraft.DraftChoice;
import com.sejourfr.app.dto.CoImageImportQuestionReport;
import com.sejourfr.app.dto.CoImageImportQuestionReport.ChoicePreview;
import com.sejourfr.app.dto.CoImageImportReport;
import com.sejourfr.app.service.questionimport.QuestionAnalysee;
import com.sejourfr.app.service.questionimport.ResultatValidation;
import com.sejourfr.app.util.PropositionsLuesCoImage;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Mapping pur de l'import CO image : question validee → brouillon
 * {@code audio_question_draft}, et verdict → rapport. Aucune lecture.
 *
 * <p>🛑 Les libelles des choix restent les LETTRES A-D : le texte de la
 * proposition part dans {@code text} (brouillon) puis dans la transcription de
 * l'audio, jamais dans {@code choices.label}, qui part dans le JSON du runner.
 */
@Component
public class CoImageImportMapper {

    /** Consigne affichee par le player, celle des 70 CO image existantes (V802-V814). */
    public static final String CONSIGNE =
            "Écoutez les propositions et choisissez celle qui correspond à l'image.";

    /** Code de competence des CO image existantes (V802-V814). */
    public static final String COMPETENCE = "co_image_proposition";

    /**
     * Brouillon {@code TEXT_VALIDATED} pret pour la synthese batch. L'URL de
     * l'image est posee par le service apres l'envoi R2 (la cle porte l'id du
     * brouillon).
     */
    public AudioQuestionDraft versBrouillon(QuestionAnalysee q) {
        AudioQuestionDraft d = new AudioQuestionDraft();
        d.setExternalId(q.externalId());
        d.setDifficulty(q.niveau());
        d.setCompetenceCode(COMPETENCE);
        d.setTheme(q.theme());
        d.setStatement(CONSIGNE);
        d.setExplanation(q.explication());
        d.setTranscriptText(PropositionsLuesCoImage.transcription(q.propositions()));
        d.setSsmlText(PropositionsLuesCoImage.ssml(q.propositions()));
        d.setVoiceRecommended(PropositionsLuesCoImage.VOIX);
        d.setImageAltText(q.descriptionScene());
        d.setChoices(choix(q));
        d.setStatus(AudioDraftStatus.TEXT_VALIDATED);
        return d;
    }

    /**
     * @param crees brouillons crees, par index de question (vide pour une analyse
     *              ou un import refuse)
     */
    public CoImageImportReport rapport(ResultatValidation r, String format, String charteVersion,
                                       int maxQuestions, Map<Integer, AudioQuestionDraft> crees) {
        List<CoImageImportQuestionReport> questions = r.questions().stream()
                .map(q -> rapportQuestion(q, crees.get(q.index())))
                .toList();
        return new CoImageImportReport(
                r.ok(),
                !crees.isEmpty(),
                format,
                charteVersion,
                maxQuestions,
                r.questions().size(),
                r.erreursLot(),
                questions);
    }

    private CoImageImportQuestionReport rapportQuestion(QuestionAnalysee q, AudioQuestionDraft cree) {
        var brut = q.brut();
        return new CoImageImportQuestionReport(
                q.index(),
                brut == null ? null : brut.externalId(),
                q.ok(),
                q.niveau() == null ? (brut == null ? null : brut.level()) : q.niveau().name(),
                q.theme() == null ? (brut == null ? null : brut.themeCode()) : q.theme().getCode(),
                q.theme() == null ? null : q.theme().getName(),
                brut == null ? null : brut.image(),
                q.format() == null ? null : q.format().extension(),
                q.dimensions() == null ? null : q.dimensions().largeur(),
                q.dimensions() == null ? null : q.dimensions().hauteur(),
                q.image() == null ? null : (long) q.image().octets().length,
                q.descriptionScene(),
                apercuChoix(q),
                brut == null ? null : brut.correctAnswer(),
                q.explication(),
                q.propositions() == null ? null : PropositionsLuesCoImage.transcription(q.propositions()),
                q.erreurs(),
                cree == null ? null : cree.getId(),
                cree == null ? null : cree.getImageUrl());
    }

    private List<ChoicePreview> apercuChoix(QuestionAnalysee q) {
        if (q.brut() == null || q.brut().choices() == null) return List.of();
        List<String> textes = q.propositions() != null ? q.propositions() : q.brut().choices();
        List<ChoicePreview> apercu = new ArrayList<>(textes.size());
        for (int i = 0; i < textes.size(); i++) {
            String lettre = i < PropositionsLuesCoImage.LETTRES.size() ? PropositionsLuesCoImage.LETTRES.get(i) : null;
            boolean correcte = q.indexBonneReponse() != null && q.indexBonneReponse() == i;
            apercu.add(new ChoicePreview(lettre, textes.get(i), correcte));
        }
        return apercu;
    }

    private static List<DraftChoice> choix(QuestionAnalysee q) {
        List<DraftChoice> choix = new ArrayList<>(q.propositions().size());
        for (int i = 0; i < q.propositions().size(); i++) {
            choix.add(new DraftChoice(PropositionsLuesCoImage.LETTRES.get(i), i == q.indexBonneReponse(),
                    i + 1, q.propositions().get(i)));
        }
        return choix;
    }
}
