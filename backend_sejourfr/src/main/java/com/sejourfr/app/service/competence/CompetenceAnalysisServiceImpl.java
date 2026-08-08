package com.sejourfr.app.service.competence;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Analyse ciblee d'une production de competence : un appel au correcteur, une
 * validation stricte, une persistance.
 *
 * <p><b>Voie PARALLELE a la notation des productions completes</b>, jamais une
 * reutilisation : pas de note sur 20, pas de niveau CECRL, pas de quatre
 * criteres. Un micro-exercice de quelques phrases ne porte ni l'un ni l'autre —
 * les afficher donnerait au candidat une certitude que sa production ne permet
 * pas. Le contrat de sortie ne prevoit donc <b>aucun champ</b> pour les loger.
 *
 * <p><b>Une sortie invalide est rejouee UNE SEULE fois</b>, avec la liste des
 * violations. Si le second essai echoue aussi, l'analyse echoue franchement et
 * l'exception remonte a {@link SkillAnalysisAsyncRunner}, qui la rend durable en
 * {@code FAILED} : jamais d'analyse partielle servie comme si elle etait
 * complete. Le candidat garde son bouton « relancer », et son quota gratuit
 * n'est pas re-consomme (il l'a ete a l'acceptation).
 *
 * <p><b>Garde-fou oral.</b> En EO, c'est la TRANSCRIPTION qui est envoyee, sous
 * une cle qui le dit ; la duree de l'enregistrement n'est jamais transmise (cf.
 * {@link CompetenceAnalysisPromptBuilder}), et les consignes interdisent de
 * fonder le verdict sur la prononciation, l'accent, le debit, la fluidite, les
 * hesitations, l'intonation, l'orthographe ou la ponctuation. Meme regle que
 * celle deja en vigueur sur les productions completes.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CompetenceAnalysisServiceImpl implements CompetenceAnalysisService {

    private final UserSkillAttemptManager attemptManager;
    private final CompetenceAnalysisPromptBuilder promptBuilder;
    private final CompetenceAnalysisLlmClient client;
    private final CompetenceAnalysisValidator validator;
    private final CompetenceRubricsProvider rubrics;

    @Override
    @Transactional
    public void analyse(UUID attemptId) {
        UserSkillAttempt attempt = attemptManager.findByIdWithPrompt(attemptId)
                .orElseThrow(() -> new NotFoundException("Tentative introuvable : " + attemptId));

        SkillPrompt prompt = attempt.getSkillPrompt();
        Skill skill = prompt.getSkill();
        boolean estOral = prompt.getSection() == SkillSection.EO;

        String production = estOral ? attempt.getTranscript() : attempt.getWrittenProduction();
        if (production == null || production.isBlank()) {
            throw new AiEvaluationException(estOral
                    ? "Aucune transcription disponible pour la tentative " + attemptId
                    : "Aucune production ecrite sur la tentative " + attemptId);
        }

        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(prompt, skill, production, estOral);

        CompetenceAnalysisLlmClient.Outcome outcome =
                analyseValidee(systemPrompt, userPrompt, attemptId);

        persister(attempt, outcome);
    }

    /**
     * Appelle le correcteur et n'accepte qu'une sortie conforme. Un seul
     * reessai : au-dela, on paierait des appels en boucle pour un correcteur qui
     * ne respecte pas son contrat.
     */
    private CompetenceAnalysisLlmClient.Outcome analyseValidee(
            String systemPrompt, String userPrompt, UUID attemptId) {
        CompetenceAnalysisLlmClient.Outcome premiere = client.analyse(systemPrompt, userPrompt);
        List<String> violations = validator.violations(premiere.analysis());
        if (violations.isEmpty()) return premiere;

        log.warn("Analyse de competence invalide attempt={} modele={} — reessai unique : {}",
                attemptId, client.getModelName(), violations);

        String repairPrompt = promptBuilder.buildRepairPrompt(
                userPrompt, violations, premiere.analysis());
        CompetenceAnalysisLlmClient.Outcome seconde = client.analyse(systemPrompt, repairPrompt);
        List<String> restantes = validator.violations(seconde.analysis());
        if (!restantes.isEmpty()) {
            throw new AiEvaluationException(
                    "Analyse de competence invalide apres une tentative de reparation : "
                            + String.join(" ; ", restantes));
        }
        // Les deux appels ont ete factures : on additionne, sinon le cout reel
        // du module est sous-estime exactement sur les cas qui coutent le plus.
        return new CompetenceAnalysisLlmClient.Outcome(
                seconde.analysis(),
                somme(premiere.inputTokens(), seconde.inputTokens()),
                somme(premiere.outputTokens(), seconde.outputTokens()),
                somme(premiere.costEstimateCents(), seconde.costEstimateCents()));
    }

    private void persister(UserSkillAttempt attempt, CompetenceAnalysisLlmClient.Outcome outcome) {
        Map<String, Object> analyse = normaliser(outcome.analysis());

        SkillCriterionStatus statut = SkillCriterionStatus.parse(
                analyse.get(CompetenceAnalysisFields.STATUS));
        if (statut == null) {
            // Impossible apres validation ; garde-fou, car c'est CETTE colonne
            // (et non la cle JSON) qui derive le statut du sujet cote fronts.
            throw new AiEvaluationException("Verdict de critere illisible apres validation");
        }

        attempt.setCriterionStatus(statut);
        attempt.setAnalysisJson(analyse);
        attempt.setAiModel(client.getModelName());
        attempt.setPromptVersion(client.getToolSchemaVersion());
        attempt.setRubricsVersion(rubrics.getVersion());
        attempt.setTokensInput(outcome.inputTokens());
        attempt.setTokensOutput(outcome.outputTokens());
        attempt.setCoutEstimeCentimes(outcome.costEstimateCents());
        attempt.setErrorMessage(null);
        attempt.setStatut(SkillAttemptStatut.EVALUATED);
        attemptManager.save(attempt);

        log.info("Analyse de competence persistee attempt={} statut={} model={} tokens={}/{}",
                attempt.getId(), statut, client.getModelName(),
                outcome.inputTokens(), outcome.outputTokens());

        // MESURE SEULE : on compte le francais desaccentue rendu au candidat,
        // on ne refuse jamais l'analyse pour ca (cf. EvaluationAccentAudit).
        var accents = com.sejourfr.app.service.EvaluationAccentAudit.analyser(analyse);
        if (accents.aDetecte()) {
            log.warn("Francais desaccentue rendu au candidat attempt={} : {} occurrence(s) "
                    + "dans {} champ(s), formes={}",
                attempt.getId(), accents.occurrences(), accents.champsTouches(),
                accents.formes());
        }
    }

    /**
     * Ne conserve QUE les cinq cles du contrat, trimees. Le tool-schema refuse
     * deja tout le reste et le validateur aussi, mais ce qui est persiste est
     * lu tel quel par le mapper : on ne veut aucune cle inattendue en base.
     */
    private static Map<String, Object> normaliser(Map<String, Object> brut) {
        Map<String, Object> propre = new LinkedHashMap<>();
        for (String cle : CompetenceAnalysisValidator.CLES) {
            Object valeur = brut.get(cle);
            propre.put(cle, valeur instanceof String s ? s.trim() : valeur);
        }
        return propre;
    }

    private static Integer somme(Integer a, Integer b) {
        if (a == null) return b;
        if (b == null) return a;
        return a + b;
    }
}
