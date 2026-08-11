package com.sejourfr.app.service.competence;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SkillAttemptStatut;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.exception.AiEvaluationException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.EvaluationProductionSegments;
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
 * reutilisation : <b>pas de note sur 20</b>, pas de quatre criteres, pas de
 * preuve citee. Le contrat de sortie ne prevoit <b>aucun champ</b> ou loger une
 * note, et c'est ce qui tient la regle — pas une consigne.
 *
 * <p><b>Le NIVEAU CECRL, lui, est rendu depuis le contrat v3</b>
 * ({@code level_reached}). L'ancienne regle « ni note, ni niveau » est revoquee
 * sur ce point : le candidat vient chercher « ou j'en suis », et ne rien lui
 * dire le laissait sans reponse. Le niveau reste independant du verdict — un
 * critere peut etre valide en A2.
 *
 * <p><b>Depuis le contrat v4, ce niveau est OPPOSABLE</b> : un B1 ou un B2 doit
 * etre demontre par le numero d'un segment reel de la production
 * ({@code level_evidence}), faute de quoi le serveur l'abaisse d'un palier
 * ({@link CompetenceLevelEvidenceGuard}). Sous v3 il etait nomme a vue, sans
 * aucun controle en aval, alors qu'une production complete derive le sien d'une
 * note contrainte serveur : deux grandeurs portaient le nom de la meme echelle
 * sans etre commensurables.
 *
 * <p><b>Ce service ne connait PAS le niveau vise par le candidat</b>, et c'est
 * l'invariant du montage : la question « pour viser B2, que faut-il ? » est
 * traitee par un SECOND appel separe
 * ({@code service.competence.niveauvise}), declenche apres coup par
 * {@link SkillAnalysisAsyncRunner}. Ne pas fusionner les deux : le depot a
 * mesure qu'un correcteur qui apprend l'objectif aligne son jugement dessus.
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
    private final CompetenceLevelEvidenceGuard evidenceGuard;

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

        EvaluationProductionSegments segments = segments(production, estOral);
        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(
                prompt, skill, production, estOral, segments);

        CompetenceAnalysisLlmClient.Outcome outcome =
                analyseValidee(systemPrompt, userPrompt, segments, attemptId);

        persister(attempt, outcome, segments);
    }

    /**
     * DECOUPAGE NUMEROTE de la production, sous le contrat v4 seulement.
     *
     * <p>La classe est celle des productions completes
     * ({@link EvaluationProductionSegments}) : elle n'est pas recopiee ici, elle
     * est appelee. Deux decoupages differents d'une meme production seraient
     * exactement le defaut que la preuve par numero supprime.
     *
     * <p>{@code null} sous v1..v3 : rien ne doit changer d'un octet dans le
     * prompt d'une version anterieure, sinon le retour arriere n'est plus reel.
     */
    private EvaluationProductionSegments segments(String production, boolean estOral) {
        if (!CompetenceAnalysisFields.porteLaPreuveDuNiveau(rubrics.getToolSchemaVersion())) {
            return null;
        }
        return EvaluationProductionSegments.of(
                production, estOral ? EpreuveType.TCF_EO : EpreuveType.TCF_EE);
    }

    /**
     * Appelle le correcteur et n'accepte qu'une sortie conforme. Un seul
     * reessai : au-dela, on paierait des appels en boucle pour un correcteur qui
     * ne respecte pas son contrat.
     *
     * <p><b>Les deux familles de reproche partagent CE reessai</b>, elles n'en
     * declenchent pas un chacune : une sortie malformee et une preuve de niveau
     * non retenue partent dans le meme message de reparation. Doubler les appels
     * doublerait le cout sans rien ameliorer.
     *
     * <p>Elles ne se terminent pas de la meme facon, en revanche : une sortie
     * encore malformee fait <b>echouer</b> l'analyse (il n'y a rien a servir),
     * une preuve encore manquante ne fait <b>jamais</b> echouer — elle rend le
     * niveau prudent.
     */
    private CompetenceAnalysisLlmClient.Outcome analyseValidee(
            String systemPrompt, String userPrompt,
            EvaluationProductionSegments segments, UUID attemptId) {
        CompetenceAnalysisLlmClient.Outcome premiere = client.analyse(systemPrompt, userPrompt);
        List<String> violations = validator.violations(premiere.analysis());
        List<String> preuve = evidenceGuard.violations(premiere.analysis(), segments);
        if (violations.isEmpty() && preuve.isEmpty()) return premiere;

        log.warn("Analyse de competence a reprendre attempt={} modele={} — reessai unique : "
                        + "contrat={} preuve={}",
                attemptId, client.getModelName(), violations, preuve);

        String repairPrompt = promptBuilder.buildRepairPrompt(
                userPrompt, violations, premiere.analysis(), preuve, segments);
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

    private void persister(UserSkillAttempt attempt, CompetenceAnalysisLlmClient.Outcome outcome,
                           EvaluationProductionSegments segments) {
        Map<String, Object> analyse = normaliser(outcome.analysis());
        // PREUVE DU NIVEAU : le numero devient le passage exact (rien en base ne
        // porte l'entier), ou le niveau descend d'un palier. Ce garde-fou ne
        // peut qu'abaisser, il ne releve jamais, et il ne rejette rien.
        evidenceGuard.applique(analyse, segments);

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
     * Ne conserve QUE les cinq cles du contrat ACTIF, trimees. Le tool-schema
     * refuse deja tout le reste et le validateur aussi, mais ce qui est persiste
     * est lu tel quel par le mapper : on ne veut aucune cle inattendue en base.
     *
     * <p>Le jeu de cles suit la version du contrat de sortie : un retour arriere
     * en v2 doit persister les champs de v2, pas des trous nommes comme ceux de
     * v3.
     *
     * <p>Le bloc du SECOND appel ({@code pour_viser}) n'est jamais concerne : il
     * est ajoute apres coup par {@code CompetenceNiveauViseService}, sur une
     * analyse deja persistee. Une NOUVELLE analyse le fait donc disparaitre, et
     * c'est le comportement voulu — un bloc « pour viser B2 » calcule sur une
     * production precedente n'a plus de sens.
     */
    private Map<String, Object> normaliser(Map<String, Object> brut) {
        Map<String, Object> propre = new LinkedHashMap<>();
        for (String cle : CompetenceAnalysisFields.cles(rubrics.getToolSchemaVersion())) {
            Object valeur = brut.get(cle);
            // Une cle absente ne devient pas un TROU NOMME : sous v4,
            // `level_evidence` est legitimement absent des qu'on est en dessous
            // du B1. Sous v1..v3 toutes les cles sont validees non nulles, donc
            // cette garde n'y change rien.
            if (valeur == null) continue;
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
