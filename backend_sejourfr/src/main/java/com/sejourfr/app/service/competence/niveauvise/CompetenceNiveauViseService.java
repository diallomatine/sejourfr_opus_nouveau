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
 *       en reste moins de deux, et la reparation n'a rien repare.</li>
 * </ul>
 *
 * <p><b>LE TEXTE MODELE VISE LA MARCHE SUIVANTE, PAS L'OBJECTIF LOINTAIN</b>
 * (contrat v2) : {@link #palierCible} pose {@code min(constate + 1, vise)}. Un
 * micro-exercice de quelques phrases ne demontre pas deux paliers d'un coup — et
 * on l'a mesure : un candidat a recopie tel quel le texte servi comme « version
 * pour viser le B2 », l'a resoumis, et le correcteur l'a reevalue A2. Le palier
 * annonce devient en outre <b>exigible</b> : le texte est borne par la fourchette
 * de mots du sujet, et il doit designer des {@code marqueurs_du_palier} recopies
 * de lui-meme ({@link CompetenceNiveauViseMarqueurFilter}).
 *
 * <p><b>UN LEVIER NOMME UNE OPERATION DE LANGUE</b> (contrat v3) : chaque levier
 * declare son {@code procede} dans la meme enumeration fermee que les marqueurs
 * ({@link MarqueurPalier}). C'est le <b>schema</b> qui tient la regle — le
 * modele ne peut plus rendre « rends ton invitation plus chaleureuse » sans le
 * rattacher a un moyen de langue reel. 🛑 <b>Un levier n'est JAMAIS purge a cause
 * de son procede</b> : manquant, inconnu ou sur-vendu, il est servi tel quel,
 * l'anomalie est comptee et le procede fautif n'est pas persiste
 * ({@link CompetenceNiveauViseProcedeAudit}). Les leviers portent le bloc
 * entier ; les purger pour une etiquette viderait l'ecran du candidat.
 *
 * <p><b>UNE SECTION QUI TOMBE N'EMPORTE PAS LE BLOC.</b>
 * {@code exemple_cible} et {@code a_retenir} sont facultatives : inexploitables
 * apres l'unique reparation, elles tombent <b>seules</b> et le reste est servi.
 * Seuls la sortie elle-meme et les <b>leviers</b> portent le bloc — un plan
 * d'action sans levier n'a aucun interet. Meme contrat que
 * {@code VersionCibleeValidator.Section}, qui porte le meme plan d'action sur
 * l'ecran des productions.
 *
 * <p><b>UN SEGMENT QUI TOMBE N'EMPORTE PAS SON TEXTE</b> (2026-08-12, alignement
 * sur les productions). Les {@code segments} de l'{@code exemple_cible} sont un
 * confort de lecture : un extrait introuvable ou mal forme est <b>retire</b>
 * ({@link SegmentsSurlignage}), le bloc survit des que le {@code texte} est
 * valide, et un extrait introuvable n'ouvre plus droit a une reparation payee —
 * il ne coute que son surlignage. La regle etait plus dure ici que sur les
 * productions, qui portent pourtant le meme bloc : un seul extrait introuvable
 * emportait tout, y compris les leviers et la tournure a retenir, qui ne
 * dependent d'aucune citation.
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

    /**
     * Filet des passages a surligner, cable sur les champs de ce contrat. La
     * mecanique est <b>partagee</b> avec le second appel des productions, qui
     * porte le meme bloc {@code exemple_cible} : deux copies ont deja diverge une
     * fois, l'une restant dure apres que l'autre a ete assouplie.
     */
    private static final SegmentsSurlignage SEGMENTS = SegmentsSurlignage.surLesChamps(
        CompetenceNiveauViseFields.EXTRAIT, CompetenceNiveauViseFields.APPORT);

    /**
     * Sections qui tombent SEULES, sans emporter le bloc : elles ne dependent
     * d'aucune des autres, et un ecran ampute d'une section reste utile la ou un
     * ecran vide ne l'est pas.
     */
    private static final List<CompetenceNiveauViseValidator.Section> FACULTATIVES = List.of(
        CompetenceNiveauViseValidator.Section.EXEMPLE_CIBLE,
        CompetenceNiveauViseValidator.Section.A_RETENIR);

    private final UserSkillAttemptManager attemptManager;
    private final CompetenceNiveauViseLlmClient llmClient;
    private final CompetenceNiveauVisePromptBuilder promptBuilder;
    private final CompetenceNiveauViseValidator validator;
    private final CompetenceNiveauViseRubricsProvider rubrics;
    private final EvaluationPurgeMetrics purgeMetrics;
    private final CompetenceNiveauViseMetrics metrics;
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
        TargetLevel cible = palierCible(constate, vise);
        if (cible == null) {
            log.info("Niveau vise deja atteint attempt={} (constate={}, vise={}) — aucun appel.",
                attemptId, constate, vise);
            return;
        }

        boolean estOral = prompt.getSection() == SkillSection.EO;
        String production = estOral ? attempt.getTranscript() : attempt.getWrittenProduction();
        if (production == null || production.isBlank()) return;

        ProductionTextBounds bornes = bornesDuSujet(prompt);
        String systemPrompt = promptBuilder.buildSystemPrompt();
        String userPrompt = promptBuilder.buildUserPrompt(
            prompt, skill, production, estOral, constate, cible, bornes);

        CompetenceNiveauViseLlmClient.Outcome outcome = llmClient.produire(systemPrompt, userPrompt);
        Sortie sortie = examiner(outcome.sortie(), cfg.getMaxLeviers(), cible, bornes);

        String reparation = messageDeReparation(sortie, userPrompt, cible, bornes);
        if (reparation != null) {
            // UNE seule reparation par bloc, tous motifs confondus, avec la
            // violation nommee et l'operation a faire.
            metrics.reparationPayee(CompetenceNiveauViseMetrics.motif(sortie.reparables()));
            log.info("Bloc « pour viser » a reparer attempt={} ({}) — une reparation.",
                attemptId, sortie.motifs());
            CompetenceNiveauViseLlmClient.Outcome reparee =
                llmClient.produire(systemPrompt, reparation);
            outcome = cumule(outcome, reparee);
            sortie = examiner(reparee.sortie(), cfg.getMaxLeviers(), cible, bornes);
        }

        if (sortie.blocPerdu()) {
            // Sortie structurellement fausse, ou plan d'action sans levier : le
            // bloc n'a plus rien a montrer. Les fronts traitent proprement son
            // absence — ni message d'echec, ni spinner.
            metrics.blocAbandonne(CompetenceNiveauViseMetrics.motif(sortie.violationsFatales()));
            log.warn("Bloc « pour viser » abandonne attempt={} modele={} : {}",
                attemptId, llmClient.getModelName(), sortie.motifs());
            return;
        }

        // UNE SECTION FACULTATIVE TOMBE SEULE — elle ne vide jamais l'ecran. Les
        // leviers et la tournure a retenir ne dependent d'aucun texte modele ;
        // les perdre parce qu'une reecriture etait trop longue couterait au
        // candidat toute la partie « comment y arriver ».
        for (CompetenceNiveauViseValidator.Section section : FACULTATIVES) {
            List<String> violations = sortie.rapport().de(section);
            if (violations.isEmpty()) continue;
            metrics.sectionAbandonnee(section, CompetenceNiveauViseMetrics.motif(violations));
            log.info("Section {} abandonnee attempt={} — le reste du bloc est servi : {}",
                section, attemptId, violations);
        }

        if (!sortie.segmentsRetires().isEmpty()) {
            // Le texte modele, lui, est servi : un segment ne coute que son
            // surlignage.
            log.info("Passage(s) a surligner retire(s) attempt={} — le texte modele reste "
                    + "servi : {}", attemptId,
                sortie.segmentsRetires().stream().map(SegmentsSurlignage.Retire::libelle).toList());
            sortie.segmentsRetires().forEach(retire -> metrics.segmentRetire(retire.motif()));
        }

        if (!sortie.marqueursRetires().isEmpty()) {
            log.info("Marqueur(s) de palier retire(s) attempt={} (cible={}) : {}",
                attemptId, cible, sortie.marqueursRetires().stream()
                    .map(CompetenceNiveauViseMarqueurFilter.Retire::libelle).toList());
            sortie.marqueursRetires().forEach(retire -> metrics.marqueurRetire(retire.motif()));
        }

        if (!sortie.procedes().isEmpty()) {
            // AUCUN levier n'a ete retire ici : ils sont tous servis. On mesure
            // seulement combien d'entre eux ne nommaient pas une operation de
            // langue opposable — sans ce compte, la contrainte de schema serait
            // invisible et ne pourrait ni se durcir ni se desarmer.
            log.info("Levier(s) sans procédé opposable attempt={} (cible={}) — servis quand "
                    + "même : {}", attemptId, cible, sortie.procedes().stream()
                    .map(CompetenceNiveauViseProcedeAudit.Anomalie::libelle).toList());
            sortie.procedes().forEach(anomalie -> metrics.procedeAnormal(anomalie.motif()));
        }

        if (!sortie.retires().isEmpty()) {
            log.info("Levier(s) A2 vendu(s) comme la marche vers {} retire(s) attempt={} : {}",
                cible, attemptId, sortie.retires().stream()
                    .map(CompetenceNiveauViseLevierFilter::libelle).toList());
            purgeMetrics.enregistrer(
                EvaluationPurgeMetrics.Filtre.MARQUEUR_PALIER_LEVIER_COMPETENCE,
                0, sortie.retires().size());
        }

        attempt.setAnalysisJson(analyseAvecBloc(analyse, sortie, constate, cible));
        // Le second appel est PAYE : son cout rejoint celui de l'analyse, sinon
        // le suivi de cout du module sous-estime ce qu'une tentative coute
        // vraiment — exactement sur les cas qui coutent le plus.
        attempt.setTokensInput(nz(attempt.getTokensInput()) + nz(outcome.inputTokens()));
        attempt.setTokensInputCacheHit(
            nz(attempt.getTokensInputCacheHit()) + nz(outcome.cachedInputTokens()));
        attempt.setTokensOutput(nz(attempt.getTokensOutput()) + nz(outcome.outputTokens()));
        attempt.setCoutMicroUsd(
            nz(attempt.getCoutMicroUsd()) + nz(outcome.costEstimateMicroUsd()));
        attemptManager.save(attempt);

        log.info("Bloc « pour viser » ajoute attempt={} : {} -> {} (objectif {}, modele={})",
            attemptId, constate, cible, vise, llmClient.getModelName());
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

    /**
     * LE PALIER QUE LE BLOC DOIT REELLEMENT FAIRE ATTEINDRE — <b>seule autorite</b>,
     * a cote de la garde ci-dessus, et jamais recopiee ailleurs.
     *
     * <p>{@code min(constate + 1, vise)}, ramene dans l'echelle des paliers
     * visables : le texte modele vise <b>la marche suivante</b>, pas l'objectif
     * lointain de la demarche.
     *
     * <p><b>Pourquoi.</b> Mesure en base sur un cas reel : un candidat constate A2
     * visant le B2 recevait un « exemple pour viser B2 » qu'il a recopie tel quel
     * et resoumis — le correcteur l'a reevalue <b>A2</b>. Sur un micro-exercice de
     * vingt-huit mots, deux paliers d'un coup ne se demontrent pas, et les deux
     * ancres de la grille n'enseignaient que des sauts d'UN palier (A2→B1, B1→B2) :
     * le cas le plus frequent n'avait donc aucun exemple. Avec cette regle, les
     * ancres couvrent tous les cas.
     *
     * <p>Le palier VISE du candidat n'est pas perdu pour autant : il reste
     * l'<b>objectif</b>, il devient le <b>plafond</b> de l'ambition d'un exercice.
     * C'est {@code SkillLevelProgressResolver} qui continue de situer le candidat
     * par rapport a lui, sur un autre ecran et sans rien devoir a cet appel.
     *
     * <p>Plancher A2 et plafond B2 par construction : le vise est un
     * {@link TargetLevel}, donc entre A2 et B2, et la cible est bornee par lui.
     * Depuis A1 ou en dessous, la marche suivante est donc l'A2 — le plus bas
     * palier qu'une demarche puisse exiger.
     *
     * @return {@code null} quand il n'y a rien a viser : aucun appel n'est emis.
     */
    static TargetLevel palierCible(NiveauCecrl constate, TargetLevel vise) {
        if (!aQuelqueChoseAViser(constate, vise)) return null;
        int marcheSuivante = constate.ordinal() + 1;
        int plancher = NiveauCecrl.A2.ordinal();
        int plafond = NiveauCecrl.valueOf(vise.name()).ordinal();
        int cible = Math.min(Math.max(marcheSuivante, plancher), plafond);
        return TargetLevel.valueOf(NiveauCecrl.values()[cible].name());
    }

    /**
     * BORNES DE LONGUEUR DU TEXTE MODELE, lues sur le sujet
     * ({@code skill_prompts.recommended_min_words / recommended_max_words}) et
     * croisees avec le garde-fou anti-abus de la configuration.
     *
     * <p>{@code null} quand le sujet n'en declare pas — c'est le cas des sujets
     * <b>ORAUX</b>, qui portent une duree conseillee et non une fourchette de
     * mots : on ne fabrique pas une borne a partir d'un debit de parole suppose.
     * {@code null} aussi sous le contrat <b>v1</b>, ou rien de ce chantier n'existe :
     * le retour arriere doit etre reel, pas partiel.
     */
    private ProductionTextBounds bornesDuSujet(SkillPrompt prompt) {
        if (!rubrics.marqueursDuPalierExiges()) return null;
        Integer max = prompt.getRecommendedMaxWords();
        if (max == null || max <= 0) return null;
        return ProductionTextBounds.of(prompt.getRecommendedMinWords(), max,
            0, props.getAnalysis().getMaxTextWords());
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
     * Ce que vaut UNE sortie du modele, une fois validee puis passee aux filets.
     *
     * @param brute      la sortie telle que rendue, pour les messages de reparation
     * @param leviers    leviers CONSERVES, dans l'ordre rendu, procede deja
     *                   normalise (et retire quand il n'etait pas opposable)
     * @param retires    leviers retires par {@link CompetenceNiveauViseLevierFilter}
     * @param procedes   anomalies de procede constatees sur des leviers
     *                   <b>CONSERVES</b> : elles se comptent, elles ne retirent
     *                   jamais rien ({@link CompetenceNiveauViseProcedeAudit})
     * @param segments   passages a surligner CONSERVES, extrait deja resolu en
     *                   sous-chaine originale exacte du texte modele
     * @param segmentsRetires passages retires par {@link SegmentsSurlignage} — ils
     *                   ne coutent QUE leur surlignage, jamais le texte
     * @param marqueurs  marqueurs du palier CONSERVES, extrait resolu de meme
     * @param marqueursRetires marqueurs retires — ils ne coutent QUE leur preuve
     * @param rapport    violations rangees par section ; une section en defaut
     *                   tombe seule, sauf {@code RACINE} et {@code LEVIERS}
     */
    private record Sortie(Map<String, Object> brute, List<Map<String, Object>> leviers,
                          List<Map<String, Object>> retires,
                          List<CompetenceNiveauViseProcedeAudit.Anomalie> procedes,
                          List<Map<String, Object>> segments,
                          List<SegmentsSurlignage.Retire> segmentsRetires,
                          List<Map<String, Object>> marqueurs,
                          List<CompetenceNiveauViseMarqueurFilter.Retire> marqueursRetires,
                          CompetenceNiveauViseValidator.Rapport rapport) {

        /**
         * Rien ne sera servi : la sortie est hors contrat, ou il ne reste pas
         * assez de leviers apres purge. Le contrat en impose deux au minimum : un
         * seul ne montre pas un chemin, il montre un detail.
         *
         * <p><b>Ni les segments, ni les marqueurs, ni meme le texte modele
         * n'entrent dans ce jugement</b> : ils tombent seuls, sans emporter le
         * reste.
         */
        boolean blocPerdu() {
            return rapport.fatale()
                || leviers.size() < CompetenceNiveauViseValidator.MIN_LEVIERS;
        }

        /** Violations des sections FATALES, pour le comptage d'un bloc abandonne. */
        List<String> violationsFatales() {
            List<String> out = new ArrayList<>(
                rapport.de(CompetenceNiveauViseValidator.Section.RACINE));
            out.addAll(rapport.de(CompetenceNiveauViseValidator.Section.LEVIERS));
            return out;
        }

        /** Violations qui ouvrent droit a la reparation payee, s'il y en a. */
        List<String> reparables() {
            List<String> exemple =
                rapport.de(CompetenceNiveauViseValidator.Section.EXEMPLE_CIBLE);
            return CompetenceNiveauViseValidator.uniquementReparables(exemple)
                ? exemple : List.of();
        }

        List<String> motifs() {
            List<String> motifs = new ArrayList<>(rapport.toutes());
            if (leviers.size() < CompetenceNiveauViseValidator.MIN_LEVIERS) {
                motifs.add(retires.size() + " levier(s) retire(s), il n'en reste que "
                    + leviers.size());
            }
            for (SegmentsSurlignage.Retire retire : segmentsRetires) {
                motifs.add("segment retire (" + retire.motif() + ") : " + retire.libelle());
            }
            for (CompetenceNiveauViseMarqueurFilter.Retire retire : marqueursRetires) {
                motifs.add("marqueur retire (" + retire.motif() + ") : " + retire.libelle());
            }
            return motifs;
        }
    }

    /**
     * Valide la sortie BRUTE, puis retire les leviers qui vendent un moyen deja
     * acquis, les passages qu'on ne saurait pas surligner et les marqueurs qui
     * sur-vendent le palier. L'ordre compte : tant que la structure d'une section
     * est fausse, son contenu n'est pas exploitable, donc rien n'y est inspecte ni
     * compte comme purge.
     */
    private Sortie examiner(Map<String, Object> brute, int maxLeviers, TargetLevel cible,
                            ProductionTextBounds bornes) {
        CompetenceNiveauViseValidator.Rapport rapport =
            validator.violations(brute, maxLeviers, bornes);

        CompetenceNiveauViseLevierFilter.Resultat purge =
            rapport.de(CompetenceNiveauViseValidator.Section.LEVIERS).isEmpty()
                ? CompetenceNiveauViseLevierFilter.purge(
                    leviers(brute.get(CompetenceNiveauViseFields.LEVIERS), maxLeviers), cible)
                : new CompetenceNiveauViseLevierFilter.Resultat(List.of(), List.of());

        // LE PROCEDE NE RETIRE RIEN — il inspecte ce qui sera servi et compte
        // l'ecart. Sous les contrats v1/v2 le champ n'existe pas : l'audit ne
        // tourne pas, et les leviers sont servis exactement comme avant.
        CompetenceNiveauViseProcedeAudit.Resultat procedes =
            rubrics.leviersPortentUnProcede()
                ? CompetenceNiveauViseProcedeAudit.inspecter(purge.gardes(), cible)
                : new CompetenceNiveauViseProcedeAudit.Resultat(purge.gardes(), List.of());

        SegmentsSurlignage.Resultat segments = new SegmentsSurlignage.Resultat(List.of(), List.of());
        CompetenceNiveauViseMarqueurFilter.Resultat marqueurs =
            new CompetenceNiveauViseMarqueurFilter.Resultat(List.of(), List.of());
        if (rapport.de(CompetenceNiveauViseValidator.Section.EXEMPLE_CIBLE).isEmpty()) {
            String texte = texteModele(brute);
            segments = SEGMENTS.purge(sousChamp(brute, CompetenceNiveauViseFields.SEGMENTS), texte,
                rubrics.contraintesLongueur().get(CompetenceNiveauViseFields.APPORT));
            marqueurs = CompetenceNiveauViseMarqueurFilter.purge(
                sousChamp(brute, CompetenceNiveauViseFields.MARQUEURS_PALIER), texte, cible);
        }
        return new Sortie(brute, procedes.leviers(), purge.retires(), procedes.anomalies(),
            segments.gardes(), segments.retires(),
            marqueurs.gardes(), marqueurs.retires(), rapport);
    }

    /** Valeur brute d'un champ de {@code exemple_cible}, ou {@code null}. */
    private static Object sousChamp(Map<String, Object> brute, String cle) {
        if (brute == null
            || !(brute.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE) instanceof Map<?, ?> m)) {
            return null;
        }
        return m.get(cle);
    }

    /**
     * Message de LA seule reparation payee, tous motifs confondus, ou {@code null}
     * quand la sortie n'en vaut pas une.
     *
     * <p>Deux defauts y ouvrent droit, et ils partent dans le MEME message :
     * <ul>
     *   <li>des leviers <b>purges</b> ramenant la liste sous le minimum — abandonner
     *       le bloc parce qu'un levier sur trois etait faux couterait au candidat
     *       toute la partie « comment y arriver » de son ecran ;</li>
     *   <li>un <b>texte modele hors des bornes du sujet</b> — le candidat est invite
     *       a rejouer l'exercice avec ce modele sous les yeux.</li>
     * </ul>
     * Les deux sont <b>mecaniques et nommables</b>, donc reparables par un message
     * qui dit ce qui a ete refuse et l'operation exacte a faire (le depot a mesure
     * qu'un reessai non actionnable repare <b>0 cas sur 8</b>).
     *
     * <p>N'y ouvrent droit ni une sortie structurellement fausse (cle en trop,
     * champ vide) — le bloc reste un confort —, ni un <b>extrait introuvable</b>,
     * ni un <b>marqueur retire</b> : ces deux-la ne coutent que leur propre mise en
     * evidence, et payer un appel pour un surlignage serait disproportionne.
     */
    private static String messageDeReparation(Sortie sortie, String userPrompt, TargetLevel cible,
                                              ProductionTextBounds bornes) {
        if (!sortie.rapport().de(CompetenceNiveauViseValidator.Section.RACINE).isEmpty()) {
            return null;
        }
        boolean leviers = !sortie.rapport().de(CompetenceNiveauViseValidator.Section.LEVIERS)
            .isEmpty();
        if (leviers) return null;

        List<Map<String, Object>> leviersRefuses =
            sortie.leviers().size() < CompetenceNiveauViseValidator.MIN_LEVIERS
                ? sortie.retires() : List.of();
        String texteRefuse = sortie.reparables().isEmpty() ? null : texteModele(sortie.brute());
        return CompetenceNiveauViseRepairPrompt.pour(userPrompt, leviersRefuses, sortie.leviers(),
            cible, texteRefuse, texteRefuse == null ? null : bornes);
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
    private Map<String, Object> analyseAvecBloc(Map<String, Object> analyse, Sortie sortie,
                                                NiveauCecrl constate, TargetLevel cible) {
        Map<String, Object> bloc = new LinkedHashMap<>();
        // NIVEAU_VISE porte le palier CIBLE — celui que le texte modele demontre
        // vraiment, pas l'objectif lointain de la demarche. C'est ce que les
        // fronts nomment dans leur intertitre ; annoncer un palier que le texte
        // n'atteint pas etait exactement le defaut mesure. L'objectif du candidat,
        // lui, reste dit par SkillLevelProgressResolver, sur son propre ecran.
        bloc.put(CompetenceNiveauViseFields.NIVEAU_VISE, cible.name());
        bloc.put(CompetenceNiveauViseFields.NIVEAU_CONSTATE, constate.name());
        bloc.put(CompetenceNiveauViseFields.LEVIERS, sortie.leviers());
        // Une section facultative en defaut est simplement ABSENTE : les fronts
        // traitent deja `exempleCible` et `aRetenir` comme nullables.
        if (sortie.rapport().de(CompetenceNiveauViseValidator.Section.EXEMPLE_CIBLE).isEmpty()) {
            bloc.put(CompetenceNiveauViseFields.EXEMPLE_CIBLE, exempleCible(sortie));
        }
        if (sortie.rapport().de(CompetenceNiveauViseValidator.Section.A_RETENIR).isEmpty()) {
            bloc.put(CompetenceNiveauViseFields.A_RETENIR,
                sortie.brute().get(CompetenceNiveauViseFields.A_RETENIR));
        }

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

    /**
     * EXEMPLE CIBLE SERVI AUX FRONTS — <b>reconstruit</b>, jamais recopie tel quel.
     *
     * <p>Le texte est celui du modele ; les segments sont ceux que le filet a
     * gardes, leur {@code extrait} deja resolu en <b>sous-chaine ORIGINALE
     * exacte</b> du texte (meme technique que
     * {@code AiEvaluationService.resolvePreuveSegments}). Sans cette resolution, un
     * extrait accepte apres neutralisation typographique pourrait ne pas etre
     * litteralement present dans le texte que le front affiche, et le surlignage —
     * une simple recherche de chaine — echouerait en silence.
     *
     * <p>La liste peut etre <b>vide</b> : un texte sans surlignage reste un texte
     * modele.
     */
    private Map<String, Object> exempleCible(Sortie sortie) {
        Map<String, Object> exemple = new LinkedHashMap<>();
        exemple.put(CompetenceNiveauViseFields.TEXTE, texteModele(sortie.brute()));
        exemple.put(CompetenceNiveauViseFields.SEGMENTS, sortie.segments());
        if (rubrics.marqueursDuPalierExiges()) {
            // PERSISTE, mais expose a AUCUN front (aucun ecran ne l'affiche, et
            // une API morte est une dette) : c'est ce qui permettra de repondre en
            // une requete SQL a « sur quoi ce B1 etait-il fonde ? ». Meme
            // arbitrage que `level_evidence` cote analyse.
            exemple.put(CompetenceNiveauViseFields.MARQUEURS_PALIER, sortie.marqueurs());
        }
        return exemple;
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
            nz(premier.cachedInputTokens()) + nz(second.cachedInputTokens()),
            nz(premier.outputTokens()) + nz(second.outputTokens()),
            nz(premier.costEstimateMicroUsd()) + nz(second.costEstimateMicroUsd()));
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
