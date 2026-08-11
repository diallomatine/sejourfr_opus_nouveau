package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.AiEvaluationManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.TranscriptionManager;
import com.sejourfr.app.service.EvaluationProductionSegments;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.TranscriptionQualityAudit;
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
 * « Version au niveau visé » : le plan d'action d'un candidat vers le palier
 * qu'exige sa démarche — deux à trois leviers, un modèle de langue, et une
 * tournure à retenir.
 *
 * <p><b>Deux formes, parce que l'écrit et l'oral ne se rendent pas pareil</b>
 * (contrat v2) :
 * <ul>
 *   <li><b>ÉCRIT</b> : sa réponse RÉÉCRITE au niveau visé, plus les deux ou trois
 *       passages où se joue la différence, que le front surligne ;</li>
 *   <li><b>ORAL</b> : deux ou trois de ses passages REDITS à ce niveau, et rien
 *       d'autre. On ne réécrit jamais une production orale : ce que nous lisons
 *       est une transcription automatique, et en refaire un beau texte
 *       tromperait le candidat sur ce qu'il a réellement dit.</li>
 * </ul>
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
 *   <li>coupe-circuit {@code version-ciblee.enabled=false} ;</li>
 *   <li>épreuve ORALE sous un contrat qui ne l'ouvre pas
 *       ({@link VersionCibleeContrat#oral()}, faux en v1) ;</li>
 *   <li>niveau visé <b>inférieur ou égal</b> au niveau constaté : il n'y a rien
 *       à viser, et montrer une « version B1 » à quelqu'un qui écrit déjà du B2
 *       serait un contresens. Ce cas-là <b>ne se tait pas</b> : le serveur pose
 *       {@code niveau_vise_atteint} pour que les fronts annoncent la victoire au
 *       lieu de laisser un trou (cf. {@link VersionCibleeFields#BLOC_ATTEINT}) ;</li>
 *   <li>niveau visé introuvable (candidat sans démarche ni {@code TargetLevel},
 *       et tâche sans {@code niveau_cible} lisible) ;</li>
 *   <li><b>ORAL — transcription DÉGRADÉE</b> ({@link TranscriptionQualityAudit}) :
 *       aucun appel n'est émis. Le texte lu n'est pas celui qui a été dit ;
 *       reformuler dessus reviendrait à reprocher au candidat ce que notre
 *       machine a cassé, et ce serait payé. C'est net, gratuit et honnête ;</li>
 *   <li><b>ORAL — moins de deux passages citables</b> : on ne peut pas montrer un
 *       chemin avec un seul ;</li>
 *   <li>leviers {@link VersionCibleeLevierFilter purgés} au point qu'il en reste
 *       moins de deux, et la réparation n'a rien réparé.</li>
 * </ul>
 *
 * <p><b>UNE SECTION QUI TOMBE N'EMPORTE PAS LE BLOC.</b> L'illustration
 * (l'{@code exemple_cible} de l'écrit, les {@code reformulations} de l'oral) et
 * la tournure {@code a_retenir} sont <b>facultatives</b> : quand l'une d'elles
 * reste inexploitable après l'unique réparation, elle seule est abandonnée, le
 * reste est servi. Seuls les <b>leviers</b> portent le bloc — un plan d'action
 * sans levier n'a aucun intérêt. Motif, constaté sur une tâche 1 d'EO en temps
 * réel : sur une transcription hachée, les reformulations sont légitimement
 * purgées (elles ne corrigeraient qu'un artefact de notre machine) et le
 * candidat perdait <b>aussi</b> ses leviers et son « à retenir », qui ne
 * dépendent d'aucune citation. La fragilité des citations à l'oral ne doit pas
 * emporter des contenus qui n'en dépendent pas.
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
    private final TranscriptionManager transcriptionManager;
    private final VersionCibleeLlmClient llmClient;
    private final VersionCibleePromptBuilder promptBuilder;
    private final VersionCibleeValidator validator;
    private final VersionCibleeRubricsProvider rubrics;
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
        VersionCibleeContrat contrat = rubrics.contrat();

        ProductionSubmission sub = submissionManager.findByIdWithTaskAndUser(submissionId).orElse(null);
        if (sub == null) return;
        ProductionTask task = sub.getProductionTask();
        if (task == null) return;
        EpreuveType epreuve = task.getEpreuve();
        boolean oral = epreuve == EpreuveType.TCF_EO;
        if (epreuve != EpreuveType.TCF_EE && !oral) return;
        // Sous le contrat v1, la sortie n'a qu'une forme — un texte reecrit — et
        // rendre a un candidat un dialogue modele a la place de ce qu'il a dit
        // serait trompeur. L'oral n'y produit donc rien.
        if (oral && !contrat.oral()) return;

        AiEvaluation eval = aiEvaluationManager.findLatestBySubmissionId(submissionId).orElse(null);
        if (eval == null || eval.getFeedbackJson() == null) return;

        NiveauCecrl constate = eval.getNiveauCecrl();
        TargetLevel vise = niveauVise(sub, task);
        if (vise == null) {
            log.debug("Version au niveau vise sans objet submission={} : palier vise inconnu.",
                submissionId);
            return;
        }
        if (!aQuelqueChoseAViser(constate, vise)) {
            // OBJECTIF ATTEINT. On ne se contente pas de ne rien produire : le
            // serveur le DIT, sinon la section disparait en silence et le
            // candidat croit a une panne (cf. VersionCibleeFields.BLOC_ATTEINT).
            eval.setFeedbackJson(feedbackAvecBlocAtteint(eval.getFeedbackJson(), constate, vise));
            aiEvaluationManager.save(eval);
            log.info("Niveau vise deja atteint submission={} (constate={}, vise={}).",
                submissionId, constate, vise);
            return;
        }

        Materiau materiau = oral
            ? materiauOral(submissionId, task, constate, vise)
            : materiauEcrit(sub, task, constate, vise);
        if (materiau == null) return;

        String systemPrompt = promptBuilder.buildSystemPrompt();
        VersionCibleeLlmClient.Outcome outcome =
            llmClient.produire(systemPrompt, materiau.userPrompt(), materiau.variante());
        Sortie sortie = examiner(outcome.sortie(), cfg.getMaxLeviers(), materiau, vise);

        // UNE seule reparation par bloc, quel qu'en soit le motif et quel que
        // soit le nombre de sections en defaut : c'est un confort, il ne doit pas
        // devenir cher. Une sortie qu'aucun message actionnable ne peut reparer
        // n'en vaut aucune (mesure : un reessai non actionnable repare 0 cas / 8).
        String reparation = messageDeReparation(sortie, materiau, vise);
        if (reparation != null) {
            log.info("Version au niveau vise a reparer submission={} ({}) — une reparation.",
                submissionId, sortie.motifs());
            VersionCibleeLlmClient.Outcome reparee =
                llmClient.produire(systemPrompt, reparation, materiau.variante());
            outcome = cumule(outcome, reparee);
            sortie = examiner(reparee.sortie(), cfg.getMaxLeviers(), materiau, vise);
        }

        if (!sortie.leviersUtilisables()) {
            // Le bloc n'est abandonne EN ENTIER que la : plus rien a montrer.
            log.warn("Version au niveau vise abandonnee submission={} modele={} : {}",
                submissionId, llmClient.getModelName(), sortie.motifs());
            return;
        }
        if (!sortie.complet()) {
            // Une section tombe, le reste est servi : la fragilite des citations
            // ne doit pas emporter des contenus qui n'en dependent pas.
            log.info("Version au niveau vise servie sans {} submission={} : {}",
                sortie.sectionsAbandonnees(), submissionId, sortie.motifs());
        }

        compterPurges(sortie, submissionId, vise);

        eval.setFeedbackJson(feedbackAvecBloc(eval.getFeedbackJson(), sortie, constate, vise));
        // Le second appel est PAYE : son cout rejoint celui de la correction,
        // sinon le suivi de cout sous-estime ce qu'une tache coute vraiment.
        eval.setTokensInput(nz(eval.getTokensInput()) + nz(outcome.inputTokens()));
        eval.setTokensOutput(nz(eval.getTokensOutput()) + nz(outcome.outputTokens()));
        eval.setCoutEstimeCentimes(
            nz(eval.getCoutEstimeCentimes()) + nz(outcome.costEstimateCents()));
        aiEvaluationManager.save(eval);

        log.info("Version au niveau vise ajoutee submission={} ({}) : {} -> {} (modele={})",
            submissionId, materiau.variante(), constate, vise, llmClient.getModelName());
    }

    // ------------------------------------------------------------- materiau

    /**
     * Ce qui part au modèle pour UNE production, et ce qui servira à relire sa
     * sortie.
     *
     * @param variante  écrit ou oral : deux contrats de sortie distincts
     * @param userPrompt prompt de l'appel, réutilisé tel quel par la réparation
     * @param bornes    bornes de longueur du texte modèle ; {@code null} à l'oral,
     *                  où l'on ne rend aucun texte complet
     * @param segments  découpage numéroté de la production orale ; {@code null} à
     *                  l'écrit
     */
    private record Materiau(VersionCibleeVariante variante, String userPrompt,
                            ProductionTextBounds bornes, EvaluationProductionSegments segments) {

        int nbSegments() {
            return segments == null ? 0 : segments.taille();
        }
    }

    private Materiau materiauEcrit(ProductionSubmission sub, ProductionTask task,
                                   NiveauCecrl constate, TargetLevel vise) {
        String production = sub.getTexteSoumis();
        if (production == null || production.isBlank()) return null;
        // BORNES DE LA TACHE, source de verite unique : elles partent dans le
        // prompt ET sont verifiees a la sortie. Aucune valeur en dur nulle part.
        ProductionTextBounds bornes = ProductionTextBounds.of(task.getMotsMin(), task.getMotsMax(),
            props.getMinTextWords(), props.getMaxTextWords());
        return new Materiau(VersionCibleeVariante.ECRIT,
            promptBuilder.buildUserPrompt(task, production, constate, vise, bornes), bornes, null);
    }

    /**
     * Matériau ORAL, et ses deux garde-fous, tous deux GRATUITS — ils tombent
     * avant le moindre appel payé.
     *
     * <ol>
     *   <li><b>transcription dégradée</b> : le texte lu n'est pas celui qui a été
     *       dit. Une reformulation y porterait sur ce que la machine a cassé, pas
     *       sur ce que le candidat a dit ;</li>
     *   <li><b>moins de deux passages citables</b> : le contrat en demande deux au
     *       minimum, et un seul ne montre pas un chemin.</li>
     * </ol>
     *
     * <p>La transcription vient de {@code TranscriptionManager
     * .findLatestTexteBySubmissionId} — l'unique accesseur au texte, tours
     * recollés compris. C'est ce qui garantit que le passage montré au candidat
     * EST celui qu'il a lu sur son écran de résultat.
     */
    private Materiau materiauOral(UUID submissionId, ProductionTask task,
                                  NiveauCecrl constate, TargetLevel vise) {
        String production = transcriptionManager.findLatestTexteBySubmissionId(submissionId)
            .orElse(null);
        if (production == null || production.isBlank()) return null;
        if (TranscriptionQualityAudit.degradee(production)) {
            log.info("Version au niveau vise ignoree submission={} : transcription degradee — "
                + "on ne reformule pas ce que la machine a casse.", submissionId);
            return null;
        }
        EvaluationProductionSegments segments =
            EvaluationProductionSegments.of(production, EpreuveType.TCF_EO);
        if (segments.taille() < VersionCibleeValidator.MIN_REFORMULATIONS) {
            log.info("Version au niveau vise ignoree submission={} : {} passage(s) citable(s), "
                + "il en faut {}.", submissionId, segments.taille(),
                VersionCibleeValidator.MIN_REFORMULATIONS);
            return null;
        }
        return new Materiau(VersionCibleeVariante.ORAL,
            promptBuilder.buildUserPromptOral(task, segments, constate, vise), null, segments);
    }

    // -------------------------------------------------------------- examen

    /**
     * Ce que vaut UNE sortie du modèle, une fois validée puis passée aux filets.
     *
     * <p><b>Chaque section se juge SÉPARÉMENT</b>, et c'est tout l'objet de ce
     * record : une illustration inexploitable ne doit pas emporter des contenus
     * qui n'en dépendent pas. Deux sections seulement condamnent le bloc entier
     * — la racine (sortie hors contrat) et les leviers (un plan d'action sans
     * levier n'a aucun intérêt).
     *
     * @param brute       la sortie telle que rendue, pour la persistance et les
     *                    messages de réparation
     * @param rapport     violations rangées par section
     * @param leviers     leviers CONSERVÉS, dans l'ordre rendu
     * @param leviersRetires leviers retirés par {@link VersionCibleeLevierFilter}
     * @param reformulations reformulations CONSERVÉES, numéro déjà résolu en texte
     * @param reformulationsRetirees reformulations retirées par
     *                    {@link VersionCibleeReformulationFilter}
     */
    private record Sortie(VersionCibleeVariante variante, Map<String, Object> brute,
                          VersionCibleeValidator.Rapport rapport,
                          List<Object> leviers, List<Object> leviersRetires,
                          List<Map<String, Object>> reformulations,
                          List<Map<String, Object>> reformulationsRetirees) {

        private boolean racineSaine() {
            return rapport.de(VersionCibleeValidator.Section.RACINE).isEmpty();
        }

        /**
         * LA section qui porte le bloc : elle est valide et il en reste assez
         * après purge. Fausse ⇒ le bloc entier est abandonné, comme avant.
         */
        boolean leviersUtilisables() {
            return racineSaine()
                && rapport.de(VersionCibleeValidator.Section.LEVIERS).isEmpty()
                && leviers.size() >= VersionCibleeValidator.MIN_LEVIERS;
        }

        /**
         * L'illustration ({@code exemple_cible} à l'écrit, {@code reformulations}
         * à l'oral) est servable. Fausse ⇒ <b>cette section seule</b> tombe : le
         * contrat en impose deux au minimum, et une seule ne montre pas un
         * chemin, elle montre un détail.
         */
        boolean illustrationUtilisable() {
            if (!racineSaine()) return false;
            if (!rapport.de(VersionCibleeValidator.Section.ILLUSTRATION).isEmpty()) return false;
            return variante != VersionCibleeVariante.ORAL
                || reformulations.size() >= VersionCibleeValidator.MIN_REFORMULATIONS;
        }

        /** La tournure à retenir est servable. Fausse ⇒ cette section seule tombe. */
        boolean aRetenirUtilisable() {
            return racineSaine()
                && rapport.de(VersionCibleeValidator.Section.A_RETENIR).isEmpty();
        }

        /** Rien à réparer et rien à abandonner. */
        boolean complet() {
            return leviersUtilisables() && illustrationUtilisable() && aRetenirUtilisable();
        }

        /** Sections servables perdues alors que le bloc, lui, est servi. */
        List<String> sectionsAbandonnees() {
            List<String> out = new ArrayList<>();
            if (!illustrationUtilisable()) {
                out.add(variante == VersionCibleeVariante.ORAL
                    ? VersionCibleeFields.REFORMULATIONS : VersionCibleeFields.EXEMPLE_CIBLE);
            }
            if (!aRetenirUtilisable()) out.add(VersionCibleeFields.A_RETENIR);
            return out;
        }

        /** De quoi loguer ce qui n'allait pas, purges comprises. */
        List<String> motifs() {
            List<String> motifs = new ArrayList<>(rapport.toutes());
            if (!leviersRetires.isEmpty()) {
                motifs.add(leviersRetires.size() + " levier(s) retire(s), il n'en reste que "
                    + leviers.size());
            }
            if (!reformulationsRetirees.isEmpty()) {
                motifs.add(reformulationsRetirees.size()
                    + " reformulation(s) retiree(s), il n'en reste que " + reformulations.size());
            }
            return motifs;
        }
    }

    /**
     * Valide la sortie BRUTE, puis retire les leviers qui vendent un moyen déjà
     * acquis et les reformulations qui ne changent que la forme d'un mot.
     *
     * <p>L'ordre compte : une section dont la STRUCTURE est fausse n'est pas
     * inspectée — il n'y a rien d'exploitable à purger, et compter une purge sur
     * une sortie illisible fausserait le compteur. Mais une section fausse
     * n'empêche plus les AUTRES d'être filtrées : sans quoi une tournure à
     * retenir malformée priverait le candidat de ses leviers.
     */
    private Sortie examiner(Map<String, Object> brute, int maxLeviers, Materiau materiau,
                            TargetLevel vise) {
        VersionCibleeValidator.Rapport rapport = validator.violations(brute, maxLeviers,
            materiau.bornes(), materiau.variante(), materiau.nbSegments());
        boolean racineSaine = rapport.de(VersionCibleeValidator.Section.RACINE).isEmpty();

        VersionCibleeLevierFilter.Resultat leviers =
            racineSaine && rapport.de(VersionCibleeValidator.Section.LEVIERS).isEmpty()
                ? VersionCibleeLevierFilter.purge(leviers(brute, maxLeviers), vise)
                : new VersionCibleeLevierFilter.Resultat(List.of(), List.of());

        VersionCibleeReformulationFilter.Resultat reformulations =
            racineSaine && materiau.variante() == VersionCibleeVariante.ORAL
                && rapport.de(VersionCibleeValidator.Section.ILLUSTRATION).isEmpty()
                ? VersionCibleeReformulationFilter.purge(resoudre(brute, materiau.segments()))
                : new VersionCibleeReformulationFilter.Resultat(List.of(), List.of());

        return new Sortie(materiau.variante(), brute, rapport, leviers.gardes(), leviers.retires(),
            reformulations.gardes(), reformulations.retires());
    }

    /**
     * Message de LA seule réparation payée, ou {@code null} quand la sortie n'en
     * vaut pas une.
     *
     * <p>Y ouvrent droit les seuls défauts <b>mécaniques et nommables</b>, donc
     * réparables par un message qui dit ce qui a été refusé et l'opération exacte
     * à faire (le dépôt a mesuré qu'un réessai non actionnable répare <b>0 cas
     * sur 8</b>) : longueur du texte modèle, extrait introuvable, numéro de
     * passage hors bornes, leviers purgés, reformulations purgées. Une sortie
     * structurellement fausse (clé en trop, champ vide, quatre leviers) n'ouvre
     * droit à aucun second appel : le bloc reste un confort.
     *
     * <p><b>Une seule réparation par bloc, tous motifs confondus</b> : les motifs
     * présents tiennent dans le même message. Elle est tentée pour une section
     * <b>facultative</b> comme pour les leviers — réparer l'illustration vaut
     * mieux que la perdre —, mais jamais quand les <b>leviers</b> sont
     * structurellement faux : le bloc est alors condamné, payer un appel de plus
     * ne rachèterait rien.
     */
    private static String messageDeReparation(Sortie sortie, Materiau materiau, TargetLevel vise) {
        if (sortie.complet()) return null;
        if (!sortie.rapport().de(VersionCibleeValidator.Section.LEVIERS).isEmpty()) return null;

        List<String> violations = sortie.rapport().toutes();
        if (!violations.isEmpty()) {
            if (!VersionCibleeValidator.uniquementReparables(violations)) return null;
            return VersionCibleeRepairPrompt.pourViolations(materiau.userPrompt(),
                violations, texteModele(sortie.brute()), materiau.bornes());
        }
        if (sortie.leviersRetires().isEmpty() && sortie.reformulationsRetirees().isEmpty()) {
            // Rien de nommable a redemander : un message sans grief ne repare rien.
            return null;
        }
        return VersionCibleeRepairPrompt.pourPurges(materiau.userPrompt(), sortie.leviersRetires(),
            sortie.leviers(), sortie.reformulationsRetirees(), vise);
    }

    private void compterPurges(Sortie sortie, UUID submissionId, TargetLevel vise) {
        if (!sortie.leviersRetires().isEmpty()) {
            log.info("Levier(s) A2 vendu(s) comme la marche vers {} retire(s) submission={} : {}",
                vise, submissionId,
                sortie.leviersRetires().stream().map(VersionCibleeLevierFilter::libelle).toList());
            purgeMetrics.enregistrer(EvaluationPurgeMetrics.Filtre.MARQUEUR_PALIER_LEVIER,
                0, sortie.leviersRetires().size());
        }
        if (!sortie.reformulationsRetirees().isEmpty()) {
            log.info("Reformulation(s) portant sur la forme d'un mot retiree(s) submission={} : {}",
                submissionId, sortie.reformulationsRetirees().stream()
                    .map(VersionCibleeReformulationFilter::libelle).toList());
            purgeMetrics.enregistrer(EvaluationPurgeMetrics.Filtre.REFORMULATION_ORALE_FORME,
                0, sortie.reformulationsRetirees().size());
        }
    }

    // ------------------------------------------------------------- decisions

    /**
     * Palier VISÉ par le candidat, à défaut le {@code niveau_cible} de la tâche.
     * Null si aucun des deux n'est lisible.
     *
     * <p><b>La démarche fait plancher</b> ({@link TargetProcedure#niveauVise}) :
     * lire le seul {@code targetLevel} stocké a produit le défaut d'origine — un
     * candidat visant la <b>naturalisation</b> (B2 exigé) portait un
     * {@code targetLevel} hérité à B1, le service concluait « objectif atteint »
     * à B1 et ne le tirait jamais vers le B2 dont sa démarche a besoin.
     */
    private static TargetLevel niveauVise(ProductionSubmission sub, ProductionTask task) {
        var user = sub.getUser();
        TargetLevel duCandidat = user == null
            ? null
            : TargetProcedure.niveauVise(user.getTargetProcedure(), user.getTargetLevel());
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

    // ---------------------------------------------------------- persistance

    /**
     * Copie du feedback avec le bloc {@code version_ciblee} ajouté à la racine.
     * Le serveur y pose lui-même {@code niveau_vise} et {@code niveau_constate} :
     * le LLM n'a aucun champ pour les écrire, et c'est voulu — il ne doit pas
     * pouvoir renvoyer un niveau que quiconque prendrait pour un verdict.
     *
     * <p>Trois formes, une seule clé : contrat v1 ({@code texte} +
     * {@code ce_qui_manque}), contrat v2 écrit ({@code leviers} +
     * {@code exemple_cible} + {@code a_retenir}), contrat v2 oral
     * ({@code leviers} + {@code reformulations} + {@code a_retenir}). Un front
     * distingue l'écrit de l'oral à la présence de {@code exemple_cible} ou de
     * {@code reformulations}.
     *
     * <p><b>Sous v2, seuls les {@code leviers} sont garantis</b> : l'illustration
     * et la tournure à retenir sont posées <b>si elles sont exploitables</b>. Les
     * trois fronts masquent déjà chaque section indépendamment — un plan sans
     * « à retenir » reste un plan.
     */
    private Map<String, Object> feedbackAvecBloc(Map<String, Object> feedback, Sortie sortie,
                                                 NiveauCecrl constate, TargetLevel vise) {
        Map<String, Object> bloc = new LinkedHashMap<>();
        bloc.put(VersionCibleeFields.NIVEAU_VISE, vise.name());
        if (constate != null) {
            bloc.put(VersionCibleeFields.NIVEAU_CONSTATE, constate.name());
        }
        if (!rubrics.contrat().planDAction()) {
            bloc.put(VersionCibleeFields.TEXTE, texteModele(sortie.brute()));
            bloc.put(VersionCibleeFields.CE_QUI_MANQUE, sortie.leviers());
        } else {
            bloc.put(VersionCibleeFields.LEVIERS, sortie.leviers());
            if (sortie.illustrationUtilisable()) {
                if (sortie.variante() == VersionCibleeVariante.ORAL) {
                    bloc.put(VersionCibleeFields.REFORMULATIONS, sortie.reformulations());
                } else {
                    bloc.put(VersionCibleeFields.EXEMPLE_CIBLE,
                        sortie.brute().get(VersionCibleeFields.EXEMPLE_CIBLE));
                }
            }
            if (sortie.aRetenirUtilisable()) {
                bloc.put(VersionCibleeFields.A_RETENIR,
                    sortie.brute().get(VersionCibleeFields.A_RETENIR));
            }
        }

        Map<String, Object> enrichi = new LinkedHashMap<>(feedback);
        enrichi.put(VersionCibleeFields.BLOC, bloc);
        return enrichi;
    }

    /**
     * Copie du feedback avec le bloc {@code niveau_vise_atteint} — la victoire,
     * dite explicitement.
     *
     * <p><b>Aucun appel LLM ici</b>, et c'est le point : il n'y a rien à
     * rédiger, seulement un constat que le serveur est seul à pouvoir faire (il
     * connaît la démarche du candidat, le front ne connaît pas la raison de
     * l'absence du bloc). Les deux blocs sont mutuellement exclusifs.
     */
    private static Map<String, Object> feedbackAvecBlocAtteint(Map<String, Object> feedback,
                                                               NiveauCecrl constate,
                                                               TargetLevel vise) {
        Map<String, Object> bloc = new LinkedHashMap<>();
        bloc.put(VersionCibleeFields.NIVEAU_VISE, vise.name());
        if (constate != null) {
            bloc.put(VersionCibleeFields.NIVEAU_CONSTATE, constate.name());
        }

        Map<String, Object> enrichi = new LinkedHashMap<>(feedback);
        enrichi.remove(VersionCibleeFields.BLOC);
        enrichi.put(VersionCibleeFields.BLOC_ATTEINT, bloc);
        return enrichi;
    }

    /**
     * RÉSOUT LE NUMÉRO EN TEXTE, avant toute persistance et avant toute purge —
     * exactement comme {@code AiEvaluationService.resolvePreuveSegments}. Aucun
     * miroir DTO ne transporte jamais un entier : les fronts lisent
     * {@code original}, une chaîne, qui est la sous-chaîne ORIGINALE exacte du
     * passage désigné.
     *
     * <p>Le numéro a déjà été validé comme existant : un trou ici ne devrait pas
     * arriver, et le passage est alors laissé de côté plutôt que rendu vide.
     */
    private static List<Map<String, Object>> resoudre(Map<String, Object> brute,
                                                      EvaluationProductionSegments segments) {
        List<Map<String, Object>> out = new ArrayList<>();
        if (!(brute.get(VersionCibleeFields.REFORMULATIONS) instanceof List<?> liste)) return out;
        for (Object item : liste) {
            if (!(item instanceof Map<?, ?> m)) continue;
            Object numero = m.get(VersionCibleeFields.SEGMENT_NUMERO);
            if (!(numero instanceof Number n)) continue;
            var original = segments.texte(n.intValue());
            if (original.isEmpty()) continue;
            Map<String, Object> resolue = new LinkedHashMap<>();
            resolue.put(VersionCibleeFields.ORIGINAL, original.get());
            resolue.put(VersionCibleeFields.REFORMULE, m.get(VersionCibleeFields.REFORMULE));
            resolue.put(VersionCibleeFields.APPORT, m.get(VersionCibleeFields.APPORT));
            out.add(resolue);
        }
        return out;
    }

    /**
     * Tronque la liste des leviers au plafond serveur, dans l'ordre rendu (le
     * plus rentable d'abord, comme demandé par la consigne). Le tool-schema le
     * demande déjà, le validateur le refuse déjà : cette troncature est le
     * troisième filet, celui qui ne dépend d'aucune coopération du modèle.
     */
    private List<Object> leviers(Map<String, Object> brute, int max) {
        Object brut = brute.get(rubrics.contrat().planDAction()
            ? VersionCibleeFields.LEVIERS : VersionCibleeFields.CE_QUI_MANQUE);
        List<Object> out = new ArrayList<>();
        if (!(brut instanceof List<?> liste)) return out;
        for (Object item : liste) {
            if (out.size() >= max) break;
            if (item != null) out.add(item);
        }
        return out;
    }

    /** Texte modèle rendu, ou chaîne vide : il n'y en a aucun à l'oral. */
    @SuppressWarnings("unchecked")
    private static String texteModele(Map<String, Object> brute) {
        if (brute == null) return "";
        Object direct = brute.get(VersionCibleeFields.TEXTE);
        if (direct != null) return direct.toString();
        if (!(brute.get(VersionCibleeFields.EXEMPLE_CIBLE) instanceof Map<?, ?> m)) return "";
        Object texte = ((Map<String, Object>) m).get(VersionCibleeFields.TEXTE);
        return texte == null ? "" : texte.toString();
    }

    /**
     * Sortie de la REPARATION, mais consommation des DEUX appels : la tentative
     * ratee a ete payee, l'oublier sous-estimerait le cout reel d'une tache.
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
