package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.util.ProductionTextBounds;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * « Version au niveau visé » : la réponse du candidat réécrite au palier qu'il
 * VISE, plus deux à trois leviers concrets pour l'atteindre.
 *
 * <p><b>SECOND APPEL LLM, totalement séparé de la correction.</b> C'est la
 * raison d'être de cette classe, pas un détail : le prompt de notation ne change
 * pas d'un octet et le correcteur n'apprend jamais quel niveau vise le candidat
 * — sinon il alignerait sa note dessus. Le dépôt a déjà mesuré qu'ajouter un
 * bloc à la grille dégrade la notation (rubriques v10/v11 : accord exact
 * 81,8 % → 75,6 %). <b>Ne pas fusionner les deux appels</b>, même si ça paraît
 * plus économique.
 *
 * <p><b>Quand ça ne produit rien</b>, et c'est normal :
 * <ul>
 *   <li>épreuve ORALE — EE seulement dans cette passe, en miroir de la règle
 *       {@code version_amelioree} (obligatoire à l'écrit, retirée à l'oral) ;</li>
 *   <li>coupe-circuit {@code version-ciblee.enabled=false} ;</li>
 *   <li>niveau visé <b>inférieur ou égal</b> au niveau constaté : il n'y a rien
 *       à viser, et montrer une « version B1 » à quelqu'un qui écrit déjà du B2
 *       serait un contresens ;</li>
 *   <li>niveau visé introuvable (candidat sans {@code TargetLevel} et tâche sans
 *       {@code niveau_cible} lisible) ;</li>
 *   <li>leviers {@link VersionCibleeLevierFilter purgés} au point qu'il en reste
 *       moins de deux, et la réparation n'a rien réparé.</li>
 * </ul>
 *
 * <p><b>BEST-EFFORT, JAMAIS BLOQUANT — invariant à ne pas casser.</b> Cette
 * méthode ne lève aucune exception : un timeout, une sortie invalide, une clé
 * API absente laissent l'évaluation {@code EVALUATED} et complète, le bloc étant
 * simplement absent. Elle tourne APRÈS que l'évaluation a été persistée,
 * <b>hors de toute transaction englobante</b> — même invariant que
 * {@code ProductionPipelineAsyncRunner} : une transaction autour d'un appel HTTP
 * de plusieurs dizaines de secondes serait un défaut en soi, et une exception
 * d'un service {@code REQUIRED} la marquerait rollback-only.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProductionVersionCibleeService {

    private final ProductionSubmissionManager submissionManager;
    private final AiEvaluationManager aiEvaluationManager;
    private final VersionCibleeLlmClient llmClient;
    private final VersionCibleePromptBuilder promptBuilder;
    private final VersionCibleeValidator validator;
    private final EvaluationPurgeMetrics purgeMetrics;
    private final ProductionEvaluationProperties props;

    /**
     * Enrichit l'évaluation d'une submission avec son bloc {@code version_ciblee}.
     * <b>Ne lève jamais</b> : tout échec est logué et laisse l'évaluation intacte.
     */
    public void enrichir(UUID submissionId) {
        try {
            enrichirOuRien(submissionId);
        } catch (RuntimeException e) {
            // Volontairement large : cet appel est un CONFORT. Aucune de ses
            // defaillances ne doit couter au candidat la correction qu'il a
            // deja obtenue.
            log.warn("Version au niveau vise abandonnee submission={} ({}) — evaluation intacte.",
                submissionId, e.toString());
        }
    }

    private void enrichirOuRien(UUID submissionId) {
        ProductionEvaluationProperties.VersionCiblee cfg = props.getVersionCiblee();
        if (!cfg.isEnabled()) return;

        ProductionSubmission sub = submissionManager.findByIdWithTaskAndUser(submissionId).orElse(null);
        if (sub == null) return;
        ProductionTask task = sub.getProductionTask();
        // EE UNIQUEMENT. A l'oral, on ne rend pas au candidat un dialogue modele
        // — c'est deja la regle de `version_amelioree`, on ne la contredit pas.
        if (task == null || task.getEpreuve() != EpreuveType.TCF_EE) return;
        String production = sub.getTexteSoumis();
        if (production == null || production.isBlank()) return;

        AiEvaluation eval = aiEvaluationManager.findLatestBySubmissionId(submissionId).orElse(null);
        if (eval == null || eval.getFeedbackJson() == null) return;

        NiveauCecrl constate = eval.getNiveauCecrl();
        TargetLevel vise = niveauVise(sub, task);
        if (vise == null || !aQuelqueChoseAViser(constate, vise)) {
            log.debug("Version au niveau vise sans objet submission={} (constate={}, vise={}).",
                submissionId, constate, vise);
            return;
        }

        // BORNES DE LA TACHE, source de verite unique : elles partent dans le
        // prompt ET sont verifiees a la sortie. Aucune valeur en dur nulle part.
        ProductionTextBounds bornes = ProductionTextBounds.of(task.getMotsMin(), task.getMotsMax(),
            props.getMinTextWords(), props.getMaxTextWords());
        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(task, production, constate, vise, bornes);

        VersionCibleeLlmClient.Outcome outcome = llmClient.produire(systemPrompt, userPrompt);
        Sortie sortie = examiner(outcome.sortie(), cfg.getMaxLeviers(), bornes, vise);

        if (!sortie.conforme()) {
            String reparation = messageDeReparation(sortie, userPrompt, bornes, vise);
            if (reparation == null) {
                // Sortie structurellement fausse : pas de reessai. Le bloc est un
                // confort, pas une correction — payer un second appel pour
                // reconstruire une sortie cassee depenserait l'argent du
                // proprietaire sur du facultatif.
                log.warn("Version au niveau vise refusee submission={} modele={} : {}",
                    submissionId, llmClient.getModelName(), sortie.motifs());
                return;
            }
            // UNE seule reparation, quel qu'en soit le motif, avec la violation
            // nommee et l'operation a faire ; toujours refusee ensuite, on
            // abandonne le bloc — les fronts traitent proprement son absence.
            log.info("Version au niveau vise a reparer submission={} ({}) — une reparation.",
                submissionId, sortie.motifs());
            VersionCibleeLlmClient.Outcome reparee = llmClient.produire(systemPrompt, reparation);
            outcome = cumule(outcome, reparee);
            sortie = examiner(reparee.sortie(), cfg.getMaxLeviers(), bornes, vise);
            if (!sortie.conforme()) {
                log.warn("Version au niveau vise abandonnee apres reparation submission={} "
                    + "modele={} : {}", submissionId, llmClient.getModelName(), sortie.motifs());
                return;
            }
        }

        if (!sortie.retires().isEmpty()) {
            log.info("Levier(s) A2 vendu(s) comme la marche vers {} retire(s) submission={} : {}",
                vise, submissionId, sortie.retires());
            purgeMetrics.enregistrer(EvaluationPurgeMetrics.Filtre.MARQUEUR_PALIER_LEVIER,
                0, sortie.retires().size());
        }

        eval.setFeedbackJson(feedbackAvecBloc(eval.getFeedbackJson(), sortie, constate, vise));
        // Le second appel est PAYE : son cout rejoint celui de la correction,
        // sinon le suivi de cout sous-estime ce qu'une tache EE coute vraiment.
        eval.setTokensInput(nz(eval.getTokensInput()) + nz(outcome.inputTokens()));
        eval.setTokensOutput(nz(eval.getTokensOutput()) + nz(outcome.outputTokens()));
        eval.setCoutEstimeCentimes(
            nz(eval.getCoutEstimeCentimes()) + nz(outcome.costEstimateCents()));
        aiEvaluationManager.save(eval);

        log.info("Version au niveau vise ajoutee submission={} : {} -> {} (modele={})",
            submissionId, constate, vise, llmClient.getModelName());
    }

    /**
     * Ce que vaut UNE sortie du modèle, une fois validée puis passée au filet des
     * leviers.
     *
     * @param texte   le texte modèle, tel que rendu
     * @param leviers leviers CONSERVÉS, dans l'ordre rendu
     * @param retires leviers retirés par {@link VersionCibleeLevierFilter}
     * @param violations violations de structure ou de longueur ; non vide ⇒ les
     *                   deux listes de leviers sont vides (rien n'a été inspecté)
     */
    private record Sortie(String texte, List<String> leviers, List<String> retires,
                          List<String> violations) {

        /**
         * Conforme = rien à redire côté validateur, ET il reste assez de leviers
         * après purge. Le contrat en impose deux au minimum : un seul ne montre
         * pas un chemin, il montre un détail.
         */
        boolean conforme() {
            return violations.isEmpty() && leviers.size() >= VersionCibleeValidator.MIN_LEVIERS;
        }

        /** De quoi loguer ce qui n'allait pas, purge comprise. */
        List<String> motifs() {
            if (!violations.isEmpty()) return violations;
            return List.of(retires.size() + " levier(s) retire(s), il n'en reste que "
                + leviers.size());
        }
    }

    /**
     * Valide la sortie BRUTE, puis retire les leviers qui vendent un moyen déjà
     * acquis. L'ordre compte : tant que la structure est fausse, les leviers ne
     * sont pas exploitables, donc rien n'est inspecté ni compté comme purge.
     */
    private Sortie examiner(Map<String, Object> brute, int maxLeviers,
                            ProductionTextBounds bornes, TargetLevel vise) {
        List<String> violations = validator.violations(brute, maxLeviers, bornes);
        String texte = brute == null ? null
            : String.valueOf(brute.get(VersionCibleeFields.TEXTE));
        if (!violations.isEmpty()) {
            return new Sortie(texte, List.of(), List.of(), violations);
        }
        VersionCibleeLevierFilter.Resultat purge = VersionCibleeLevierFilter.purge(
            leviers(brute.get(VersionCibleeFields.CE_QUI_MANQUE), maxLeviers), vise);
        return new Sortie(texte, purge.gardes(), purge.retires(), List.of());
    }

    /**
     * Message de LA seule réparation payée, ou {@code null} quand la sortie n'en
     * vaut pas une.
     *
     * <p>Deux défauts seulement y ouvrent droit, et pour la même raison : ils sont
     * <b>mécaniques et nommables</b>, donc réparables par un message qui dit ce
     * qui a été refusé et l'opération exacte à faire (le dépôt a mesuré qu'un
     * réessai non actionnable répare <b>0 cas sur 8</b>).
     * <ul>
     *   <li>la LONGUEUR du texte modèle — le seul défaut mesuré en production ;</li>
     *   <li>des leviers PURGÉS ramenant la liste sous le minimum. Le bloc est
     *       devenu le texte modèle mis en évidence sur l'écran d'un résultat EE :
     *       l'abandonner parce qu'un levier sur trois était faux coûterait au
     *       candidat la partie la plus visible de son résultat. Le cas est de
     *       surcroît rare — sur les blocs déjà livrés, la purge laissait toujours
     *       assez de leviers.</li>
     * </ul>
     * Une sortie structurellement fausse (clé en trop, levier vide, quatre
     * leviers) n'ouvre droit à aucun second appel : le bloc reste un confort.
     */
    private static String messageDeReparation(Sortie sortie, String userPrompt,
                                              ProductionTextBounds bornes, TargetLevel vise) {
        if (!sortie.violations().isEmpty()) {
            if (!VersionCibleeValidator.uniquementLongueur(sortie.violations())) return null;
            return VersionCibleeRepairPrompt.pourLongueur(userPrompt, sortie.texte(), bornes);
        }
        return VersionCibleeRepairPrompt.pourLeviers(
            userPrompt, sortie.retires(), sortie.leviers(), vise);
    }

    /**
     * Palier VISÉ par le candidat : son {@code TargetLevel} TCF, à défaut le
     * {@code niveau_cible} de la tâche. Null si aucun des deux n'est lisible.
     */
    private static TargetLevel niveauVise(ProductionSubmission sub, ProductionTask task) {
        TargetLevel duCandidat = sub.getUser() == null ? null : sub.getUser().getTargetLevel();
        if (duCandidat != null) return duCandidat;
        return parseTargetLevel(task.getNiveauCible());
    }

    private static TargetLevel parseTargetLevel(String brut) {
        if (brut == null || brut.isBlank()) return null;
        try {
            return TargetLevel.valueOf(brut.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /**
     * Vrai seulement si le palier visé est STRICTEMENT au-dessus du palier
     * constaté. Un niveau constaté inconnu (évaluation en échec) laisse passer :
     * on ne peut pas conclure que la cible est déjà atteinte.
     */
    static boolean aQuelqueChoseAViser(NiveauCecrl constate, TargetLevel vise) {
        if (vise == null) return false;
        if (constate == null) return true;
        return NiveauCecrl.valueOf(vise.name()).ordinal() > constate.ordinal();
    }

    /**
     * Copie du feedback avec le bloc {@code version_ciblee} ajouté à la racine.
     * Le serveur y pose lui-même {@code niveau_vise} et {@code niveau_constate} :
     * le LLM n'a aucun champ pour les écrire, et c'est voulu — il ne doit pas
     * pouvoir renvoyer un niveau que quiconque prendrait pour un verdict.
     */
    private static Map<String, Object> feedbackAvecBloc(Map<String, Object> feedback,
                                                        Sortie sortie,
                                                        NiveauCecrl constate, TargetLevel vise) {
        Map<String, Object> bloc = new LinkedHashMap<>();
        bloc.put(VersionCibleeFields.NIVEAU_VISE, vise.name());
        if (constate != null) {
            bloc.put(VersionCibleeFields.NIVEAU_CONSTATE, constate.name());
        }
        bloc.put(VersionCibleeFields.TEXTE, sortie.texte());
        bloc.put(VersionCibleeFields.CE_QUI_MANQUE, sortie.leviers());

        Map<String, Object> enrichi = new LinkedHashMap<>(feedback);
        enrichi.put(VersionCibleeFields.BLOC, bloc);
        return enrichi;
    }

    /**
     * Tronque la liste des leviers au plafond serveur, dans l'ordre rendu (le
     * plus rentable d'abord, comme demandé par la consigne). Le tool-schema le
     * demande déjà, le validateur le refuse déjà : cette troncature est le
     * troisième filet, celui qui ne dépend d'aucune coopération du modèle.
     */
    private static List<String> leviers(Object brut, int max) {
        List<String> out = new ArrayList<>();
        if (!(brut instanceof List<?> liste)) return out;
        for (Object item : liste) {
            if (out.size() >= max) break;
            if (item != null) out.add(item.toString());
        }
        return out;
    }

    /**
     * Sortie de la REPARATION, mais consommation des DEUX appels : la tentative
     * ratee a ete payee, l'oublier sous-estimerait le cout reel d'une tache EE.
     */
    private static VersionCibleeLlmClient.Outcome cumule(VersionCibleeLlmClient.Outcome premier,
                                                         VersionCibleeLlmClient.Outcome second) {
        return new VersionCibleeLlmClient.Outcome(
            second.sortie(),
            nz(premier.inputTokens()) + nz(second.inputTokens()),
            nz(premier.outputTokens()) + nz(second.outputTokens()),
            nz(premier.costEstimateCents()) + nz(second.costEstimateCents()));
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
