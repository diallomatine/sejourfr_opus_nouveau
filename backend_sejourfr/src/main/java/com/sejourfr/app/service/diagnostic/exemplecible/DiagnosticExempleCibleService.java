package com.sejourfr.app.service.diagnostic.exemplecible;

import com.sejourfr.app.config.DiagnosticProperties;
import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.DiagnosticProductionAnalysis;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.DiagnosticProductionAnalysisManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.EvaluationMarqueursA2;
import com.sejourfr.app.service.EvaluationProductionSegments;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.util.ProductionTextBounds;
import com.sejourfr.app.util.SegmentsSurlignage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * « AVANT / APRES » DU DIAGNOSTIC : la phrase du candidat, et la meme phrase
 * reecrite au palier qu'il vise.
 *
 * <p>C'est la piece de conversion de l'ecran de resultat. On ne dit pas au
 * candidat qu'il a un probleme : on lui montre a quoi ressemblerait SA propre
 * phrase un cran plus haut.
 *
 * <p><b>SECOND APPEL LLM, totalement separe de l'analyse.</b> C'est la raison
 * d'etre de cette classe, pas un detail : le contrat d'analyse
 * ({@code diagnostic-analysis-rubrics-v1} / {@code -tool-schema-v1}) ne bouge pas
 * d'un octet, et le correcteur du diagnostic n'apprend JAMAIS qu'on va reecrire
 * quoi que ce soit. Le depot a mesure qu'ajouter un bloc a une grille qui juge
 * degrade sa notation (rubriques v10/v11 : accord exact 81,8 % → 75,6 %).
 * <b>Ne pas fusionner les deux appels</b>, meme si ça parait plus economique.
 *
 * <p><b>🛑 ECRIT SEULEMENT.</b> Aucun appel n'est emis pour l'oral, et aucun bloc
 * n'est produit pour lui. Rendre un beau texte a la place d'une transcription
 * serait trompeur : le candidat n'a pas dit ça, il a dit ce que la machine a
 * transcrit. C'est la meme regle que {@code version_ciblee}, qui ne reecrit jamais
 * une production orale et se contente de reformuler des passages designes.
 *
 * <p><b>Quand ça ne produit rien</b>, et c'est normal :
 * <ul>
 *   <li>coupe-circuit {@code sejourfr.diagnostic.exemple-cible.enabled=false} ;</li>
 *   <li>production ORALE, ou tache non diagnostique ;</li>
 *   <li>aucune analyse diagnostique persistee : il n'y a pas encore de niveau
 *       constate, donc rien a comparer — et on ne paie pas un appel pour un ecran
 *       qu'on ne saura pas dessiner ;</li>
 *   <li>bloc DEJA present : l'enrichissement est idempotent, un rejeu du pipeline
 *       ne repaie jamais l'appel ;</li>
 *   <li>niveau vise <b>inferieur ou egal</b> au niveau constate : il n'y a rien a
 *       viser. Aucun appel n'est emis, le bloc est absent, et le front n'a aucun
 *       trou a interpreter ;</li>
 *   <li>niveau vise introuvable (candidat sans demarche ni {@code TargetLevel}, et
 *       tache sans palier lisible) ;</li>
 *   <li>production vide, ou dont le decoupage ne rend aucune phrase citable.</li>
 * </ul>
 *
 * <p><b>UN SEGMENT QUI TOMBE N'EMPORTE PAS SON TEXTE</b> (regle du 2026-08-11,
 * partagee avec {@code version_ciblee} et le module Competences). Les
 * {@code segments} sont un confort de lecture : un extrait introuvable, un apport
 * trop long ou un objet mal forme est <b>retire</b> ({@link SegmentsSurlignage}),
 * le bloc survit des que le {@code texte} est valide, et un extrait introuvable
 * n'ouvre droit a <b>aucune reparation payee</b> — il ne coute que son surlignage.
 *
 * <p><b>BEST-EFFORT, JAMAIS BLOQUANT — invariant a ne pas casser.</b> Cette
 * methode ne leve aucune exception : un timeout, une sortie invalide, une cle API
 * absente laissent l'analyse diagnostique complete et la session {@code COMPLETED},
 * le bloc etant simplement absent. Elle tourne APRES que l'analyse a ete persistee
 * et la session assemblee, <b>hors de toute transaction englobante</b> — meme
 * invariant que {@code ProductionPipelineAsyncRunner} : une transaction autour
 * d'un appel HTTP de plusieurs dizaines de secondes serait un defaut en soi, et
 * une exception d'un service {@code REQUIRED} la marquerait rollback-only.
 *
 * <p><b>Aucun rejeu.</b> C'est un confort, pas une correction.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DiagnosticExempleCibleService {

    /**
     * Filet des passages a surligner, cable sur les champs de ce contrat. La
     * mecanique est <b>partagee</b> avec les deux autres surfaces qui portent le
     * meme bloc : deux copies ont deja diverge une fois, l'une restant dure apres
     * que l'autre a ete assouplie.
     */
    private static final SegmentsSurlignage SEGMENTS = SegmentsSurlignage.surLesChamps(
        DiagnosticExempleCibleFields.EXTRAIT, DiagnosticExempleCibleFields.APPORT);

    private final ProductionSubmissionManager submissionManager;
    private final DiagnosticProductionAnalysisManager analysisManager;
    private final DiagnosticExempleCibleLlmClient llmClient;
    private final DiagnosticExempleCiblePromptBuilder promptBuilder;
    private final DiagnosticExempleCibleValidator validator;
    private final DiagnosticExempleCibleRubricsProvider rubrics;
    private final DiagnosticExempleCibleMetrics metrics;
    private final EvaluationPurgeMetrics purgeMetrics;
    private final DiagnosticProperties props;
    private final ProductionEvaluationProperties evalProps;

    /**
     * Enrichit l'analyse d'une production diagnostique ECRITE avec son bloc
     * {@code exemple_cible}. <b>Ne leve jamais</b> : tout echec est logue et laisse
     * l'analyse et la session intactes.
     */
    public void enrichir(UUID submissionId) {
        try {
            enrichirOuRien(submissionId);
        } catch (RuntimeException e) {
            // Volontairement large : cet appel est un CONFORT. Aucune de ses
            // defaillances ne doit couter au candidat le diagnostic qu'il vient
            // de passer, ni retrograder une session deja COMPLETED.
            log.warn("Bloc « avant / apres » abandonne submission={} ({}) — diagnostic intact.",
                submissionId, e.toString());
        }
    }

    private void enrichirOuRien(UUID submissionId) {
        DiagnosticProperties.ExempleCible cfg = props.getExempleCible();
        if (!cfg.isEnabled()) return;

        ProductionSubmission submission =
            submissionManager.findByIdWithTaskAndUser(submissionId).orElse(null);
        if (submission == null) return;
        ProductionTask task = submission.getProductionTask();
        if (task == null || !task.isDiagnostic()) return;
        if (task.getEpreuve() != EpreuveType.TCF_EE) {
            // 🛑 ECRIT SEULEMENT. Pas « pas de bloc » : pas d'appel PAYE.
            log.debug("Bloc « avant / apres » sans objet submission={} : epreuve {}.",
                submissionId, task.getEpreuve());
            return;
        }

        DiagnosticProductionAnalysis analyse =
            analysisManager.findBySubmissionId(submissionId).orElse(null);
        if (analyse == null || analyse.getAnalysisJson() == null) return;
        if (analyse.getAnalysisJson().containsKey(DiagnosticExempleCibleFields.BLOC)) {
            // Idempotent : un rejeu du pipeline ne repaie jamais l'appel.
            return;
        }

        NiveauCecrl constate = analyse.getLevelEstimate();
        TargetLevel vise = niveauVise(submission.getUser(), task);
        if (constate == null || vise == null) {
            log.debug("Bloc « avant / apres » sans objet submission={} : palier inconnu.",
                submissionId);
            return;
        }
        if (!aQuelqueChoseAViser(constate, vise)) {
            log.info("Niveau vise deja atteint submission={} (constate={}, vise={}) — aucun appel.",
                submissionId, constate, vise);
            return;
        }

        String production = submission.getTexteSoumis();
        if (production == null || production.isBlank()) return;
        // DECOUPAGE NUMEROTE, la classe des productions completes — appelee,
        // jamais recopiee. Le modele DESIGNE la phrase du candidat au lieu de la
        // recopier : inventer une phrase devient impossible par construction.
        EvaluationProductionSegments segments =
            EvaluationProductionSegments.of(production, EpreuveType.TCF_EE);
        if (segments.taille() == 0) return;

        // BORNES DE LA TACHE, source de verite unique : elles partent dans le
        // prompt ET sont revalidees a la sortie. Aucune valeur en dur nulle part.
        ProductionTextBounds bornes = ProductionTextBounds.of(task.getMotsMin(), task.getMotsMax(),
            evalProps.getMinTextWords(), evalProps.getMaxTextWords());

        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(task, segments, constate, vise, bornes);

        DiagnosticExempleCibleLlmClient.Outcome outcome =
            llmClient.produire(systemPrompt, userPrompt);
        Sortie sortie = examiner(outcome.sortie(), segments, bornes, vise);

        if (!sortie.conforme()) {
            if (!DiagnosticExempleCibleValidator.toutesReparables(sortie.violations())) {
                // Sortie structurellement fausse : pas de reessai. Le bloc est un
                // confort, pas une analyse — payer un second appel pour
                // reconstruire une sortie cassee depenserait l'argent du
                // proprietaire sur du facultatif.
                metrics.blocAbandonne(DiagnosticExempleCibleMetrics.motif(sortie.violations()));
                log.warn("Bloc « avant / apres » refuse submission={} modele={} : {}",
                    submissionId, llmClient.getModelName(), sortie.violations());
                return;
            }
            // UNE seule reparation, quel qu'en soit le motif, avec la violation
            // nommee et l'operation a faire ; toujours refusee ensuite, on
            // abandonne le bloc — les fronts traitent proprement son absence.
            metrics.reparationPayee(DiagnosticExempleCibleMetrics.motif(sortie.violations()));
            log.info("Bloc « avant / apres » a reparer submission={} ({}) — une reparation.",
                submissionId, sortie.violations());
            String reparation = DiagnosticExempleCibleRepairPrompt.pourViolations(
                userPrompt, sortie.violations(), texteModele(sortie.brute()),
                segments.taille(), bornes);
            DiagnosticExempleCibleLlmClient.Outcome reparee =
                llmClient.produire(systemPrompt, reparation);
            outcome = cumule(outcome, reparee);
            sortie = examiner(reparee.sortie(), segments, bornes, vise);
            if (!sortie.conforme()) {
                metrics.blocAbandonne(DiagnosticExempleCibleMetrics.motif(sortie.violations()));
                log.warn("Bloc « avant / apres » abandonne apres reparation submission={} "
                    + "modele={} : {}", submissionId, llmClient.getModelName(),
                    sortie.violations());
                return;
            }
        }

        if (!sortie.segmentsRetires().isEmpty()) {
            // Le texte reecrit, lui, est servi : un segment ne coute que son
            // surlignage.
            log.info("Passage(s) a surligner retire(s) submission={} — la phrase reecrite reste "
                    + "servie : {}", submissionId,
                sortie.segmentsRetires().stream().map(SegmentsSurlignage.Retire::libelle).toList());
            sortie.segmentsRetires().forEach(retire -> metrics.segmentRetire(retire.motif()));
        }
        if (sortie.apportsA2() > 0) {
            log.info("Etiquette(s) vendant un moyen A2 comme la marche vers {} retiree(s) "
                + "submission={}", vise, submissionId);
            purgeMetrics.enregistrer(
                EvaluationPurgeMetrics.Filtre.MARQUEUR_PALIER_APPORT_DIAGNOSTIC,
                0, sortie.apportsA2());
        }

        String original = segments.texte(numero(sortie.brute())).orElse(null);
        if (original == null || original.isBlank()) {
            // Ceinture et bretelles : le validateur a deja borne le numero.
            metrics.blocAbandonne(DiagnosticExempleCibleMetrics.Motif.SEGMENT_NUMERO);
            return;
        }

        analyse.setAnalysisJson(analyseAvecBloc(
            analyse.getAnalysisJson(), sortie, original, constate, vise));
        // Le second appel est PAYE : son cout rejoint celui de l'analyse, sinon
        // le suivi de cout du diagnostic sous-estime ce qu'un candidat coute
        // vraiment — exactement sur les cas qui coutent le plus.
        analyse.setTokensInput(nz(analyse.getTokensInput()) + nz(outcome.inputTokens()));
        analyse.setTokensInputCacheHit(
            nz(analyse.getTokensInputCacheHit()) + nz(outcome.cachedInputTokens()));
        analyse.setTokensOutput(nz(analyse.getTokensOutput()) + nz(outcome.outputTokens()));
        analyse.setCostMicroUsd(
            nz(analyse.getCostMicroUsd()) + nz(outcome.costEstimateMicroUsd()));
        analysisManager.save(analyse);

        log.info("Bloc « avant / apres » ajoute submission={} : {} -> {} (modele={})",
            submissionId, constate, vise, llmClient.getModelName());
    }

    // ------------------------------------------------------------- decisions

    /**
     * Palier VISE par le candidat, a defaut le palier editorial de la tache. Null
     * si aucun des deux n'est lisible.
     *
     * <p><b>La demarche fait plancher</b> ({@link TargetProcedure#niveauVise}),
     * jamais plafond : un candidat visant la naturalisation (B2 exige) peut porter
     * un {@code targetLevel} herite a B1 ; lire le seul niveau declare le priverait
     * du palier dont sa demarche a besoin. Cette table ne se reecrit nulle part.
     */
    static TargetLevel niveauVise(User user, ProductionTask task) {
        TargetLevel duCandidat = user == null
            ? null
            : TargetProcedure.niveauVise(user.getTargetProcedure(), user.getTargetLevel());
        if (duCandidat != null) return duCandidat;
        return parseTargetLevel(task == null ? null : task.getNiveauCible());
    }

    /**
     * Vrai seulement si le palier vise est STRICTEMENT au-dessus du palier
     * constate. Sinon, aucun appel n'est emis : montrer une « version B1 » a
     * quelqu'un qui ecrit deja du B2 serait un contresens, et le payer le serait
     * deux fois.
     */
    static boolean aQuelqueChoseAViser(NiveauCecrl constate, TargetLevel vise) {
        if (vise == null || constate == null) return false;
        return NiveauCecrl.valueOf(vise.name()).ordinal() > constate.ordinal();
    }

    private static TargetLevel parseTargetLevel(String brut) {
        if (brut == null || brut.isBlank()) return null;
        try {
            return TargetLevel.valueOf(brut.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    // --------------------------------------------------------------- examen

    /**
     * Ce que vaut UNE sortie du modele, une fois validee puis passee aux filets.
     *
     * @param brute           la sortie telle que rendue, pour le message de reparation
     * @param segments        passages a surligner CONSERVES, extrait deja resolu en
     *                        sous-chaine originale exacte du texte reecrit
     * @param segmentsRetires passages retires par {@link SegmentsSurlignage}
     * @param apportsA2       passages retires parce que leur etiquette vendait un
     *                        moyen deja acquis
     * @param violations      violations de structure, de numero ou de longueur ;
     *                        non vide ⇒ rien n'a ete inspecte
     */
    private record Sortie(Map<String, Object> brute, List<Map<String, Object>> segments,
                          List<SegmentsSurlignage.Retire> segmentsRetires, int apportsA2,
                          List<String> violations) {

        /**
         * Conforme = rien a redire cote validateur.
         *
         * <p><b>Les segments n'entrent pas dans ce jugement</b> : ils peuvent tous
         * avoir ete retires sans que le bloc cesse d'etre servable — une phrase
         * reecrite sans surlignage reste un avant / apres.
         */
        boolean conforme() {
            return violations.isEmpty();
        }
    }

    /**
     * Valide la sortie BRUTE, puis retire les passages qu'on ne saurait pas
     * surligner et ceux dont l'etiquette vend un moyen deja acquis. L'ordre compte :
     * tant que la structure est fausse, rien n'est exploitable, donc rien n'est
     * inspecte ni compte comme purge.
     */
    private Sortie examiner(Map<String, Object> brute, EvaluationProductionSegments production,
                            ProductionTextBounds bornes, TargetLevel vise) {
        List<String> violations = validator.violations(brute, production.taille(), bornes);
        if (!violations.isEmpty()) {
            return new Sortie(brute, List.of(), List.of(), 0, violations);
        }
        SegmentsSurlignage.Resultat surlignage = SEGMENTS.purge(
            brute.get(DiagnosticExempleCibleFields.SEGMENTS), texteModele(brute),
            rubrics.contraintesLongueur().get(DiagnosticExempleCibleFields.APPORT));

        // FILET MARQUEURS A2, quatrieme surface du meme defaut : la detection est
        // celle du depot (EvaluationMarqueursA2), jamais une copie locale.
        List<Map<String, Object>> gardes = new ArrayList<>();
        int apportsA2 = 0;
        for (Map<String, Object> segment : surlignage.gardes()) {
            String apport = String.valueOf(segment.get(DiagnosticExempleCibleFields.APPORT));
            if (EvaluationMarqueursA2.sousLeNiveauVise(vise)
                && (EvaluationMarqueursA2.designe(apport)
                    || EvaluationMarqueursA2.estUnMarqueur(apport))) {
                apportsA2++;
                continue;
            }
            gardes.add(segment);
        }
        return new Sortie(brute, gardes, surlignage.retires(), apportsA2, List.of());
    }

    // ---------------------------------------------------------- persistance

    /**
     * Copie de l'analyse avec le bloc {@code exemple_cible} ajoute a la racine.
     *
     * <p><b>Aucune migration</b> : il se loge dans le {@code jsonb} deja persiste,
     * exactement comme {@code version_ciblee} se loge dans {@code feedback_json}.
     * Il est range sur l'analyse de la production ECRITE — celle dont il reecrit
     * une phrase — et non dans le {@code summary_json} de la session, que
     * {@code DiagnosticSessionCoordinator} remet a null puis reconstruit
     * integralement a chaque assemblage : un bloc paye y serait efface au premier
     * retry.
     *
     * <p>Le serveur pose lui-meme {@code original}, {@code niveau_vise} et
     * {@code niveau_constate} : le LLM n'a aucun champ pour les ecrire, et c'est
     * voulu — il ne doit pouvoir ni recopier la phrase du candidat, ni renvoyer un
     * niveau que quiconque prendrait pour un verdict.
     *
     * <p>Une nouvelle carte est construite plutot que mutee : la valeur est
     * persistee en {@code jsonb} et c'est le remplacement de l'instance qui rend la
     * modification visible au dirty-checking de maniere sûre.
     */
    private static Map<String, Object> analyseAvecBloc(Map<String, Object> analyse, Sortie sortie,
                                                       String original, NiveauCecrl constate,
                                                       TargetLevel vise) {
        Map<String, Object> bloc = new LinkedHashMap<>();
        // LA SOUS-CHAINE ORIGINALE EXACTE, resolue depuis le numero designe —
        // meme technique que AiEvaluationService.resolvePreuveSegments. Aucun
        // miroir DTO ne transporte donc d'entier.
        bloc.put(DiagnosticExempleCibleFields.ORIGINAL, original);
        bloc.put(DiagnosticExempleCibleFields.TEXTE, texteModele(sortie.brute()));
        bloc.put(DiagnosticExempleCibleFields.SEGMENTS, sortie.segments());
        bloc.put(DiagnosticExempleCibleFields.NIVEAU_VISE, vise.name());
        bloc.put(DiagnosticExempleCibleFields.NIVEAU_CONSTATE, constate.name());

        Map<String, Object> enrichi = new LinkedHashMap<>(analyse);
        enrichi.put(DiagnosticExempleCibleFields.BLOC, bloc);
        return enrichi;
    }

    private static int numero(Map<String, Object> brute) {
        Integer numero = DiagnosticExempleCibleValidator.entier(
            brute == null ? null : brute.get(DiagnosticExempleCibleFields.SEGMENT_NUMERO));
        return numero == null ? 0 : numero;
    }

    private static String texteModele(Map<String, Object> brute) {
        if (brute == null) return "";
        Object texte = brute.get(DiagnosticExempleCibleFields.TEXTE);
        return texte == null ? "" : texte.toString();
    }

    /**
     * Sortie de la REPARATION, mais consommation des DEUX appels : la tentative
     * ratee a ete payee, l'oublier sous-estimerait le cout reel du diagnostic.
     */
    private static DiagnosticExempleCibleLlmClient.Outcome cumule(
            DiagnosticExempleCibleLlmClient.Outcome premier,
            DiagnosticExempleCibleLlmClient.Outcome second) {
        return new DiagnosticExempleCibleLlmClient.Outcome(
            second.sortie(),
            nz(premier.inputTokens()) + nz(second.inputTokens()),
            nz(premier.cachedInputTokens()) + nz(second.cachedInputTokens()),
            nz(premier.outputTokens()) + nz(second.outputTokens()),
            nz(premier.costEstimateMicroUsd()) + nz(second.costEstimateMicroUsd()));
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
