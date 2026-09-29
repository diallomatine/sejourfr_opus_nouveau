package com.sejourfr.app.mapper;

import com.sejourfr.app.dto.EvaluationResultDto;
import com.sejourfr.app.dto.ProductionSubmissionDto;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SituationDansNiveau;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.ProductionRubricsProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class ProductionSubmissionMapper {

    /**
     * Rappel affiché sous le niveau observé d'une tâche. Le niveau qui fait foi
     * est celui du bilan d'épreuve, pas celui d'une tâche isolée.
     */
    static final String AVERTISSEMENT_NIVEAU =
        "Estimation pédagogique portant sur cette seule tâche. Le niveau qui fait foi "
            + "est celui du bilan des trois tâches de l'épreuve.";

    private final AiEvaluationManager aiEvaluationManager;
    private final TranscriptionManager transcriptionManager;
    /**
     * Bornes de bande de la GRILLE ACTIVE (bloc {@code commun.niveau}). Ce n'est
     * ni un repository ni un manager : c'est le porteur de configuration deja
     * utilise partout ailleurs pour lire une note. Les figer en dur ici ferait
     * derailler la situation dans le palier au prochain changement d'echelle.
     */
    private final ProductionRubricsProvider rubrics;

    public ProductionSubmissionDto toDto(ProductionSubmission s) {
        EvaluationResultDto eval = aiEvaluationManager
            .findLatestBySubmissionId(s.getId())
            .map(this::toEvaluationDto)
            .orElse(null);

        // Transcription (EO uniquement, null sinon). Le manager rend le texte
        // RECOLLE : c'est exactement celui qui est envoye au correcteur et sur
        // lequel les preuves sont verifiees, donc une citation est toujours
        // relisible telle quelle dans ce champ.
        String transcription = transcriptionManager
            .findLatestTexteBySubmissionId(s.getId())
            .orElse(null);

        return new ProductionSubmissionDto(
            s.getId(),
            s.getAttempt() != null ? s.getAttempt().getId() : null,
            s.getProductionTask() != null ? s.getProductionTask().getId() : null,
            s.getProductionTask() != null ? s.getProductionTask().getTacheNumero() : null,
            s.getStatut(),
            s.getTexteSoumis(),
            s.getMotsCount(),
            s.getMediaDurationSec(),
            s.getRetryCount(),
            s.getErreurMessage(),
            s.getSubmittedAt(),
            eval,
            transcription,
            // Le changement de Plan est resolu par le service, a la lecture d'un
            // detail : un mapper ne le calcule pas, et une liste d'historique
            // n'a aucune raison de le payer.
            null
        );
    }

    /**
     * Le niveau par tache est expose sous une forme PRUDENTE, via des champs
     * typés — jamais via le feedback brut : {@code niveau_cecrl} et
     * {@code justification_niveau} en sont expurgés pour qu'il n'existe qu'une
     * seule source d'affichage.
     *
     * <p><b>Garde-fou</b> : pas de niveau sans confiance. Une évaluation
     * antérieure au schéma v2 (aucune {@code confiance} persistée) sort donc
     * avec les trois champs à null — exactement le comportement d'avant.
     */
    private EvaluationResultDto toEvaluationDto(AiEvaluation e) {
        Map<String, Object> feedback = e.getFeedbackJson();
        ConfianceEvaluation confiance = feedback == null
            ? null
            : ConfianceEvaluation.parse(feedback.get("confiance"));
        if (feedback != null) {
            Map<String, Object> sanitized = new LinkedHashMap<>(feedback);
            sanitized.remove("niveau_cecrl");
            sanitized.remove("justification_niveau");
            feedback = sanitized;
        }
        NiveauCecrl niveauObserve = confiance == null ? null : e.getNiveauCecrl();
        // SITUATION DANS LE PALIER — ce qui remplace, sur une tache isolee, la
        // note /20 qui n'y est plus affichee. Derivee SERVEUR : aucun front ne
        // doit refaire ce calcul, sinon trois implementations divergeront des
        // que l'echelle bougera.
        SituationDansNiveau situation = SituationDansNiveau.of(
            e.getNoteSur20(), niveauObserve, rubrics.niveauCecrl());
        return new EvaluationResultDto(
            e.getEvaluabilite(),
            e.getNoteSur20(),
            niveauObserve,
            confiance,
            niveauObserve == null ? null : AVERTISSEMENT_NIVEAU,
            situation,
            situation == null ? null : situation.libelleAvecNiveau(niveauObserve),
            feedback);
    }
}
