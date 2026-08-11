package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.config.CompetenceProperties;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.entity.UserSkillAttempt;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.competence.CompetenceAnalysisFields;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * « Pour viser X » : le plan d'action d'un candidat vers le palier qu'exige sa
 * demarche — deux a trois leviers, sa reponse reecrite a ce niveau avec les
 * passages qui font la difference, et une tournure a retenir.
 *
 * <p><b>SECOND APPEL LLM, totalement separe de l'analyse.</b> C'est la raison
 * d'etre de cette classe, pas un detail : le prompt d'analyse ne change pas d'un
 * octet et le correcteur n'apprend jamais quel niveau vise le candidat — sinon
 * il alignerait son jugement dessus. Le depot a deja mesure qu'ajouter un bloc a
 * une grille degrade la notation (rubriques v10/v11 : accord exact 81,8 % →
 * 75,6 %). <b>Ne pas fusionner les deux appels</b>, meme si ça parait plus
 * economique.
 *
 * <p><b>Quand ça ne produit rien</b>, et c'est normal :
 * <ul>
 *   <li>coupe-circuit {@code sejourfr.competences.niveau-vise.enabled=false} ;</li>
 *   <li>aucune analyse, ou une analyse ANCIENNE (contrat v1/v2, sans
 *       {@code level_reached}) : sans niveau constate, il n'y a rien a comparer
 *       — et on ne paie pas un appel pour un ecran qu'on ne saura pas dessiner ;</li>
 *   <li>niveau vise <b>inferieur ou egal</b> au niveau constate : il n'y a rien
 *       a viser. Aucun appel n'est emis, le bloc est absent, et c'est le derive
 *       serveur {@code SkillLevelProgressResolver} qui annonce la victoire — le
 *       front n'a aucun trou a interpreter ;</li>
 *   <li>niveau vise introuvable (candidat sans demarche ni {@code TargetLevel},
 *       et competence sans palier lisible) ;</li>
 *   <li>leviers {@link CompetenceNiveauViseLevierFilter purges} au point qu'il
 *       en reste moins de deux, et la reparation n'a rien repare ;</li>
 *   <li>un extrait introuvable dans le texte modele, apres la reparation.</li>
 * </ul>
 *
 * <p><b>BEST-EFFORT, JAMAIS BLOQUANT — invariant a ne pas casser.</b> Cette
 * methode ne leve aucune exception : un timeout, une sortie invalide, une cle API
 * absente laissent la tentative {@code EVALUATED} et son analyse complete, le
 * bloc etant simplement absent. Elle tourne APRES que l'analyse a ete persistee,
 * <b>hors de toute transaction englobante</b> — meme invariant que
 * {@code SkillAnalysisAsyncRunner} et {@code ProductionPipelineAsyncRunner} : une
 * transaction autour d'un appel HTTP de plusieurs dizaines de secondes serait un
 * defaut en soi, et une exception d'un service {@code REQUIRED} la marquerait
 * rollback-only.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CompetenceNiveauViseService {

    private final UserSkillAttemptManager attemptManager;
    private final CompetenceNiveauViseLlmClient llmClient;
    private final CompetenceNiveauVisePromptBuilder promptBuilder;
    private final CompetenceNiveauViseValidator validator;
    private final EvaluationPurgeMetrics purgeMetrics;
    private final CompetenceProperties props;

    /**
     * Enrichit une tentative analysee avec son bloc {@code pour_viser}.
     * <b>Ne leve jamais</b> : tout echec est logue et laisse l'analyse intacte.
     */
    public void enrichir(UUID attemptId) {
        try {
            enrichirOuRien(attemptId);
        } catch (RuntimeException e) {
            // Volontairement large : cet appel est un CONFORT. Aucune de ses
            // defaillances ne doit couter au candidat l'analyse qu'il a deja
            // obtenue — et, s'il est gratuit, deja payee de son quota.
            log.warn("Bloc « pour viser » abandonne attempt={} ({}) — analyse intacte.",
                attemptId, e.toString());
        }
    }

    private void enrichirOuRien(UUID attemptId) {
        CompetenceProperties.NiveauVise cfg = props.getNiveauVise();
        if (!cfg.isEnabled()) return;

        UserSkillAttempt attempt = attemptManager.findByIdWithPrompt(attemptId).orElse(null);
        if (attempt == null) return;
        Map<String, Object> analyse = attempt.getAnalysisJson();
        if (analyse == null || analyse.isEmpty()) return;

        NiveauCecrl constate = niveauConstate(analyse);
        if (constate == null) {
            // Analyse produite par un contrat anterieur a v3 : elle ne porte
            // aucun niveau. Rien a comparer, donc aucun appel paye.
            log.debug("Bloc « pour viser » sans objet attempt={} : analyse sans niveau.", attemptId);
            return;
        }

        SkillPrompt prompt = attempt.getSkillPrompt();
        Skill skill = prompt.getSkill();
        TargetLevel vise = niveauVise(attempt.getUser(), skill);
        if (vise == null) {
            log.debug("Bloc « pour viser » sans objet attempt={} : palier vise inconnu.", attemptId);
            return;
        }
        if (!aQuelqueChoseAViser(constate, vise)) {
            log.info("Niveau vise deja atteint attempt={} (constate={}, vise={}) — aucun appel.",
                attemptId, constate, vise);
            return;
        }

        boolean estOral = prompt.getSection() == SkillSection.EO;
        String production = estOral ? attempt.getTranscript() : attempt.getWrittenProduction();
        if (production == null || production.isBlank()) return;

        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(
            prompt, skill, production, estOral, constate, vise);

        CompetenceNiveauViseLlmClient.Outcome outcome = llmClient.produire(systemPrompt, userPrompt);
        Sortie sortie = examiner(outcome.sortie(), cfg.getMaxLeviers(), vise);

        if (!sortie.conforme()) {
            String reparation = messageDeReparation(sortie, userPrompt, vise);
            if (reparation == null) {
                // Sortie structurellement fausse : pas de reessai. Le bloc est un
                // confort, pas une analyse — payer un second appel pour
                // reconstruire une sortie cassee depenserait l'argent du
                // proprietaire sur du facultatif.
                log.warn("Bloc « pour viser » refuse attempt={} modele={} : {}",
                    attemptId, llmClient.getModelName(), sortie.motifs());
                return;
            }
            // UNE seule reparation, quel qu'en soit le motif, avec la violation
            // nommee et l'operation a faire ; toujours refusee ensuite, on
            // abandonne le bloc — les fronts traitent proprement son absence.
            log.info("Bloc « pour viser » a reparer attempt={} ({}) — une reparation.",
                attemptId, sortie.motifs());
            CompetenceNiveauViseLlmClient.Outcome reparee =
                llmClient.produire(systemPrompt, reparation);
            outcome = cumule(outcome, reparee);
            sortie = examiner(reparee.sortie(), cfg.getMaxLeviers(), vise);
            if (!sortie.conforme()) {
                log.warn("Bloc « pour viser » abandonne apres reparation attempt={} modele={} : {}",
                    attemptId, llmClient.getModelName(), sortie.motifs());
                return;
            }
        }

        if (!sortie.retires().isEmpty()) {
            log.info("Levier(s) A2 vendu(s) comme la marche vers {} retire(s) attempt={} : {}",
                vise, attemptId, sortie.retires().stream()
                    .map(CompetenceNiveauViseLevierFilter::libelle).toList());
            purgeMetrics.enregistrer(
                EvaluationPurgeMetrics.Filtre.MARQUEUR_PALIER_LEVIER_COMPETENCE,
                0, sortie.retires().size());
        }

        attempt.setAnalysisJson(analyseAvecBloc(analyse, sortie, constate, vise));
        // Le second appel est PAYE : son cout rejoint celui de l'analyse, sinon
        // le suivi de cout du module sous-estime ce qu'une tentative coute
        // vraiment — exactement sur les cas qui coutent le plus.
        attempt.setTokensInput(nz(attempt.getTokensInput()) + nz(outcome.inputTokens()));
        attempt.setTokensOutput(nz(attempt.getTokensOutput()) + nz(outcome.outputTokens()));
        attempt.setCoutEstimeCentimes(
            nz(attempt.getCoutEstimeCentimes()) + nz(outcome.costEstimateCents()));
        attemptManager.save(attempt);

        log.info("Bloc « pour viser » ajoute attempt={} : {} -> {} (modele={})",
            attemptId, constate, vise, llmClient.getModelName());
    }

    // ------------------------------------------------------------- decisions

    /**
     * Palier VISE par le candidat, a defaut le palier editorial de la
     * competence. Null si aucun des deux n'est lisible.
     *
     * <p><b>La demarche fait plancher</b> ({@link TargetProcedure#niveauVise}),
     * jamais plafond : lire le seul {@code targetLevel} stocke a deja produit le
     * defaut d'origine cote productions — un candidat visant la naturalisation
     * (B2 exige) portait un {@code targetLevel} herite a B1, et le service
     * concluait « objectif atteint » a B1 sans jamais le tirer vers le niveau
     * dont sa demarche a besoin. Cette table ne se reecrit nulle part.
     */
    static TargetLevel niveauVise(User user, Skill skill) {
        TargetLevel duCandidat = user == null
            ? null
            : TargetProcedure.niveauVise(user.getTargetProcedure(), user.getTargetLevel());
        if (duCandidat != null) return duCandidat;
        return parseTargetLevel(skill == null ? null : skill.getTargetLevel());
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

    /** Niveau lu dans l'analyse. Null si absent ou illisible (contrat v1/v2). */
    static NiveauCecrl niveauConstate(Map<String, Object> analyse) {
        Object brut = analyse == null ? null : analyse.get(CompetenceAnalysisFields.LEVEL_REACHED);
        if (brut == null) return null;
        try {
            return NiveauCecrl.valueOf(brut.toString().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static TargetLevel parseTargetLevel(String brut) {
        if (brut == null || brut.isBlank()) return null;
        try {
            return TargetLevel.valueOf(brut.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    // -------------------------------------------------------------- examen

    /**
     * Ce que vaut UNE sortie du modele, une fois validee puis passee au filet des
     * leviers.
     *
     * @param brute      la sortie telle que rendue, pour les messages de reparation
     * @param leviers    leviers CONSERVES, dans l'ordre rendu
     * @param retires    leviers retires par {@link CompetenceNiveauViseLevierFilter}
     * @param violations violations de structure, de longueur ou d'extrait ; non
     *                   vide ⇒ les deux listes de leviers sont vides (rien n'a ete
     *                   inspecte)
     */
    private record Sortie(Map<String, Object> brute, List<Map<String, Object>> leviers,
                          List<Map<String, Object>> retires, List<String> violations) {

        /**
         * Conforme = rien a redire cote validateur, ET il reste assez de leviers
         * apres purge. Le contrat en impose deux au minimum : un seul ne montre
         * pas un chemin, il montre un detail.
         */
        boolean conforme() {
            return violations.isEmpty()
                && leviers.size() >= CompetenceNiveauViseValidator.MIN_LEVIERS;
        }

        List<String> motifs() {
            if (!violations.isEmpty()) return violations;
            return List.of(retires.size() + " levier(s) retire(s), il n'en reste que "
                + leviers.size());
        }
    }

    /**
     * Valide la sortie BRUTE, puis retire les leviers qui vendent un moyen deja
     * acquis. L'ordre compte : tant que la structure est fausse, les leviers ne
     * sont pas exploitables, donc rien n'est inspecte ni compte comme purge.
     */
    private Sortie examiner(Map<String, Object> brute, int maxLeviers, TargetLevel vise) {
        List<String> violations = validator.violations(brute, maxLeviers);
        if (!violations.isEmpty()) {
            return new Sortie(brute, List.of(), List.of(), violations);
        }
        CompetenceNiveauViseLevierFilter.Resultat purge = CompetenceNiveauViseLevierFilter.purge(
            leviers(brute.get(CompetenceNiveauViseFields.LEVIERS), maxLeviers), vise);
        return new Sortie(brute, purge.gardes(), purge.retires(), List.of());
    }

    /**
     * Message de LA seule reparation payee, ou {@code null} quand la sortie n'en
     * vaut pas une.
     *
     * <p>Deux defauts seulement y ouvrent droit, et pour la meme raison : ils sont
     * <b>mecaniques et nommables</b>, donc reparables par un message qui dit ce
     * qui a ete refuse et l'operation exacte a faire (le depot a mesure qu'un
     * reessai non actionnable repare <b>0 cas sur 8</b>).
     * <ul>
     *   <li>un EXTRAIT introuvable dans le texte modele — le modele a le texte
     *       sous les yeux, il lui suffit de recopier ;</li>
     *   <li>des leviers PURGES ramenant la liste sous le minimum : abandonner le
     *       bloc entier parce qu'un levier sur trois etait faux couterait au
     *       candidat toute la partie « comment y arriver » de son ecran.</li>
     * </ul>
     * Une sortie structurellement fausse (cle en trop, champ vide, un seul
     * segment) n'ouvre droit a aucun second appel : le bloc reste un confort.
     */
    private static String messageDeReparation(Sortie sortie, String userPrompt, TargetLevel vise) {
        if (!sortie.violations().isEmpty()) {
            if (!CompetenceNiveauViseValidator.uniquementExtraits(sortie.violations())) return null;
            return CompetenceNiveauViseRepairPrompt.pourExtraits(
                userPrompt, sortie.violations(), texteModele(sortie.brute()));
        }
        return CompetenceNiveauViseRepairPrompt.pourLeviers(
            userPrompt, sortie.retires(), sortie.leviers(), vise);
    }

    // ---------------------------------------------------------- persistance

    /**
     * Copie de l'analyse avec le bloc {@code pour_viser} ajoute a la racine.
     * Le serveur y pose lui-meme {@code niveau_vise} et {@code niveau_constate} :
     * le LLM n'a aucun champ pour les ecrire, et c'est voulu — il ne doit pas
     * pouvoir renvoyer un niveau que quiconque prendrait pour un verdict.
     *
     * <p>Une nouvelle carte est construite plutot que mutee : la valeur est
     * persistee en {@code jsonb} et c'est le remplacement de l'instance qui rend
     * la modification visible au dirty-checking de maniere sûre.
     */
    private static Map<String, Object> analyseAvecBloc(Map<String, Object> analyse, Sortie sortie,
                                                       NiveauCecrl constate, TargetLevel vise) {
        Map<String, Object> bloc = new LinkedHashMap<>();
        bloc.put(CompetenceNiveauViseFields.NIVEAU_VISE, vise.name());
        bloc.put(CompetenceNiveauViseFields.NIVEAU_CONSTATE, constate.name());
        bloc.put(CompetenceNiveauViseFields.LEVIERS, sortie.leviers());
        bloc.put(CompetenceNiveauViseFields.EXEMPLE_CIBLE,
            sortie.brute().get(CompetenceNiveauViseFields.EXEMPLE_CIBLE));
        bloc.put(CompetenceNiveauViseFields.A_RETENIR,
            sortie.brute().get(CompetenceNiveauViseFields.A_RETENIR));

        Map<String, Object> enrichi = new LinkedHashMap<>(analyse);
        enrichi.put(CompetenceAnalysisFields.BLOC_POUR_VISER, bloc);
        return enrichi;
    }

    /**
     * Tronque la liste des leviers au plafond serveur, dans l'ordre rendu (le
     * plus rentable d'abord, comme demande par la consigne). Le tool-schema le
     * demande deja, le validateur le refuse deja : cette troncature est le
     * troisieme filet, celui qui ne depend d'aucune cooperation du modele.
     */
    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> leviers(Object brut, int max) {
        List<Map<String, Object>> out = new ArrayList<>();
        if (!(brut instanceof List<?> liste)) return out;
        for (Object item : liste) {
            if (out.size() >= max) break;
            if (item instanceof Map<?, ?> m) out.add((Map<String, Object>) m);
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    private static String texteModele(Map<String, Object> brute) {
        if (brute == null) return "";
        Object bloc = brute.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        if (!(bloc instanceof Map<?, ?> m)) return "";
        Object texte = ((Map<String, Object>) m).get(CompetenceNiveauViseFields.TEXTE);
        return texte == null ? "" : texte.toString();
    }

    /**
     * Sortie de la REPARATION, mais consommation des DEUX appels : la tentative
     * ratee a ete payee, l'oublier sous-estimerait le cout reel du module.
     */
    private static CompetenceNiveauViseLlmClient.Outcome cumule(
            CompetenceNiveauViseLlmClient.Outcome premier,
            CompetenceNiveauViseLlmClient.Outcome second) {
        return new CompetenceNiveauViseLlmClient.Outcome(
            second.sortie(),
            nz(premier.inputTokens()) + nz(second.inputTokens()),
            nz(premier.outputTokens()) + nz(second.outputTokens()),
            nz(premier.costEstimateCents()) + nz(second.costEstimateCents()));
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
