package com.sejourfr.app.service.competence;

import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Cles du JSON d'analyse ciblee, telles qu'elles sont demandees au correcteur
 * et telles qu'elles sont persistees dans
 * {@code user_skill_attempts.analysis_json}.
 *
 * <p>Ce fichier est le <b>point de rendez-vous</b> entre l'implementation de
 * l'analyse (qui produit le JSON) et le mapper qui le sert aux fronts. Sans
 * lui, les deux cotes redeclareraient les memes chaines, et un renommage d'un
 * seul cote passerait silencieusement : le mapper renverrait simplement des
 * champs nuls.
 *
 * <p>Convention {@code snake_case} pour rester aligne sur les tool-schemas
 * existants ({@code production-evaluation-tool-schema-*.json}) ; la traduction
 * vers le {@code camelCase} du DTO est faite par
 * {@code SkillAttemptMapper}.
 *
 * <h2>Trois jeux de cles, parce qu'on versionne sans jamais migrer</h2>
 * Le contrat <b>v5</b> rend exactement les memes cles que v4 ; ce qui change,
 * c'est que {@link #LEVEL_EVIDENCE} y est <b>requis a tous les paliers</b> et
 * plus seulement sur un B1/B2. Le contrat
 * <b>v4</b> rend ceux de v3 plus {@link #LEVEL_EVIDENCE}. Le contrat
 * <b>v3</b> rend {@code status}, {@code level_reached},
 * {@code verdict}, {@code strength_tag} et {@code focus_tag}. Le contrat
 * <b>v1/v2</b> rendait {@code status}, {@code verdict}, {@code success_point},
 * {@code improvement_priority} et {@code improved_version}. Les analyses deja
 * persistees sous v1/v2 <b>ne sont pas migrees</b> : le mapper expose les deux
 * jeux, en nullable, et rien ne doit planter sur une ligne ancienne.
 *
 * <p>Le jeu ATTENDU d'une nouvelle sortie depend donc de la version du contrat
 * configuree ({@link #cles(String)}) : sans ca, un retour arriere
 * {@code COMPETENCE_TOOL_SCHEMA_VERSION=v2} produirait des sorties valides pour
 * le fournisseur et systematiquement refusees par notre validateur.
 *
 * <h2>Ce qu'il n'y a toujours pas, et n'y aura pas</h2>
 * <b>Aucune cle de note</b> — ni sur 20, ni sur une autre echelle, ni en
 * pourcentage : une micro-production de quelques phrases n'en porte pas, et le
 * tool-schema ne prevoit aucun champ ou la loger. Le <b>niveau CECRL</b>, lui,
 * existe depuis v3 ({@link #LEVEL_REACHED}) : c'est ce que le candidat vient
 * chercher, et le refuser le laissait sans reponse a « ou j'en suis ».
 */
public final class CompetenceAnalysisFields {

    /** Verdict sur le critere unique : {@code VALIDATED|PARTIAL|NOT_VALIDATED}. */
    public static final String STATUS = "status";

    /** Une phrase qui dit ce que la production accomplit ou manque. */
    public static final String VERDICT = "verdict";

    // --- contrat v3 ---------------------------------------------------------

    /**
     * Niveau CECRL demontre par CETTE production, borne au profil TCF IRN
     * ({@code A1_NON_ATTEINT|A1|A2|B1|B2}). Independant du verdict : un critere
     * peut etre valide en A2.
     */
    public static final String LEVEL_REACHED = "level_reached";

    // --- contrat v4 ---------------------------------------------------------

    /**
     * PREUVE DU NIVEAU. Le correcteur y met le <b>NUMERO</b> (entier &ge; 1) du
     * segment de la production qui demontre {@code level_reached}. Le serveur le
     * <b>resout en texte avant persistance</b> : sur une ligne de base, cette
     * cle porte donc le passage lui-meme, jamais l'entier — exactement comme
     * {@code preuve_segment} devient {@code preuve} cote productions completes.
     *
     * <p><b>Sous v4</b> : cle optionnelle, seuls B1 et B2 ayant quelque chose a
     * demontrer. <b>Sous v5</b> : cle <b>requise a tous les paliers</b> — le
     * cout de nommer un palier cesse d'etre asymetrique (cf.
     * {@link #exigeLaPreuveSurTousLesPaliers(String)}).
     */
    public static final String LEVEL_EVIDENCE = "level_evidence";

    /** Ce qui est reussi, en 3 mots — une etiquette affichee telle quelle. */
    public static final String STRENGTH_TAG = "strength_tag";

    /** L'axe de progres, en 3 mots — meme forme d'etiquette. */
    public static final String FOCUS_TAG = "focus_tag";

    /**
     * Bloc du SECOND appel (« pour viser X »), pose a la racine de
     * {@code analysis_json} apres coup. Absent tant que le second appel n'a pas
     * abouti — il est best-effort, jamais bloquant.
     */
    public static final String BLOC_POUR_VISER = "pour_viser";

    // --- contrat v1/v2 (legacy, encore lu) ----------------------------------

    /** Ce qui est reussi — toujours renseigne, meme sur une production faible. */
    public static final String SUCCESS_POINT = "success_point";

    /** LA priorite de progression, une seule, actionnable. */
    public static final String IMPROVEMENT_PRIORITY = "improvement_priority";

    /** Reformulation qui conserve l'idee DU CANDIDAT, pas un modele de substitution. */
    public static final String IMPROVED_VERSION = "improved_version";

    /**
     * Contrat v4 et v5 : celles de v3, plus la preuve du niveau, dans l'ordre du
     * tool-schema. Les deux rangs demandent les <b>memes six cles</b> ; seule
     * l'obligation de {@link #LEVEL_EVIDENCE} change.
     */
    static final List<String> CLES_V4 =
        List.of(STATUS, LEVEL_REACHED, LEVEL_EVIDENCE, VERDICT, STRENGTH_TAG, FOCUS_TAG);

    /**
     * Contrats qui portent {@link #LEVEL_EVIDENCE}. <b>Allowlist explicite</b>,
     * jamais un {@code != v3} : une version future ne doit pas heriter d'un
     * comportement par accident, et un retour arriere doit reproduire l'ancien
     * au bit pres.
     */
    private static final Set<String> CONTRATS_AVEC_PREUVE = Set.of("v4", "v5");

    /**
     * Contrats qui exigent la preuve <b>a TOUS les paliers</b>. Meme patron
     * d'allowlist, pour la meme raison.
     */
    private static final Set<String> CONTRATS_AVEC_PREUVE_PARTOUT = Set.of("v5");

    /** Contrat v3 : cinq cles, dans l'ordre du tool-schema. */
    static final List<String> CLES_V3 =
        List.of(STATUS, LEVEL_REACHED, VERDICT, STRENGTH_TAG, FOCUS_TAG);

    /** Contrat v1/v2 : cinq cles, dans l'ordre du tool-schema d'origine. */
    static final List<String> CLES_LEGACY =
        List.of(STATUS, VERDICT, SUCCESS_POINT, IMPROVEMENT_PRIORITY, IMPROVED_VERSION);

    private CompetenceAnalysisFields() {
    }

    /**
     * Cles attendues d'une sortie, pour la version de contrat donnee. C'est ce
     * qui garde le retour arriere reel : {@code v1}/{@code v2} restent
     * chargeables, et le validateur leur demande alors leurs propres champs.
     */
    public static List<String> cles(String toolSchemaVersion) {
        if (CONTRATS_AVEC_PREUVE.contains(toolSchemaVersion)) return CLES_V4;
        return "v3".equals(toolSchemaVersion) ? CLES_V3 : CLES_LEGACY;
    }

    /**
     * Le contrat donne porte-t-il {@link #LEVEL_EVIDENCE} ? Vrai a partir de v4 :
     * sous v1..v3 le champ n'existe pas, et tout ce qui l'entoure (decoupage
     * numerote du prompt, reparation dediee, abaissement d'un palier) doit
     * rester <b>inerte</b> — c'est ce qui garde le retour arriere reel.
     */
    public static boolean porteLaPreuveDuNiveau(String toolSchemaVersion) {
        return CONTRATS_AVEC_PREUVE.contains(toolSchemaVersion);
    }

    /**
     * LE COUT DE NOMMER UN PALIER EST-IL LE MEME PARTOUT ? Vrai a partir de v5.
     *
     * <p><b>Le defaut que ce rang corrige.</b> Sous v4, annoncer un B1 ou un B2
     * coutait quelque chose — il fallait produire un numero de segment, et un
     * numero absent ou faux faisait abaisser le verdict d'un palier ; annoncer un
     * A2 ne coutait <b>rien</b> et ne risquait <b>rien</b>. Le mecanisme lui-meme
     * rendait le A2 confortable et le B2 risque, quelles que soient les ancres du
     * prompt. Mesure en base : <b>zero B2 sur 18 tentatives</b>.
     *
     * <p>A partir de v5, le correcteur designe <b>toujours</b> le segment sur
     * lequel il fonde son verdict, palier bas compris : l'<b>effort</b> devient
     * symetrique, c'est-a-dire la ou vit l'incitation. La <b>sanction</b>, elle,
     * ne bouge pas — {@code CompetenceLevelEvidenceGuard} n'abaisse toujours que
     * sur un B1/B2 mal etaye : punir la prudence serait exactement l'inverse du
     * but recherche.
     */
    public static boolean exigeLaPreuveSurTousLesPaliers(String toolSchemaVersion) {
        return CONTRATS_AVEC_PREUVE_PARTOUT.contains(toolSchemaVersion);
    }

    /**
     * Cles que {@code CompetenceAnalysisValidator} ne verifie <b>jamais</b>.
     *
     * <p>⚠️ CE N'EST PAS « facultatif dans le tool-schema ». Depuis v5,
     * {@link #LEVEL_EVIDENCE} est bel et bien dans le {@code required} du JSON
     * Schema — le fournisseur l'exige. Mais le validateur, lui, a le pouvoir de
     * faire echouer l'analyse (seconde sortie encore mauvaise ⇒ {@code FAILED}),
     * et <b>une preuve manquante ne doit JAMAIS couter au candidat sa production
     * et son quota</b> : elle est traitee par
     * {@code CompetenceLevelEvidenceGuard}, qui abaisse au lieu de rejeter.
     *
     * <p>C'est exactement le piege documente de {@code
     * EvaluationOutputValidator.CHAMPS_V4} — une redeclaration en dur des champs
     * requis, en doublon du {@code required} du JSON. Recopier ici le
     * {@code required} du schema aurait fait rejeter des analyses valides pour un
     * champ qui, par decision, ne peut pas en faire echouer une.
     */
    public static boolean estExclueDuValidateur(String toolSchemaVersion, String cle) {
        return porteLaPreuveDuNiveau(toolSchemaVersion) && LEVEL_EVIDENCE.equals(cle);
    }

    /**
     * Ce qu'on ecrit dans l'explication d'une observation du Plan, quelle que
     * soit la version qui a produit l'analyse : la priorite d'amelioration
     * (v1/v2), a defaut l'axe de progres (v3), a defaut le verdict.
     *
     * <p>Sans ce repli, la bascule v3 aurait vide en silence l'explication de
     * toutes les observations issues des micro-exercices — la colonne serait
     * restee nulle sans qu'aucun test fonctionnel ne bronche.
     */
    public static String explication(Map<String, Object> analyse) {
        if (analyse == null) return null;
        for (String cle : List.of(IMPROVEMENT_PRIORITY, FOCUS_TAG, VERDICT)) {
            Object valeur = analyse.get(cle);
            if (valeur == null) continue;
            String texte = valeur.toString().trim();
            if (!texte.isEmpty()) return texte;
        }
        return null;
    }
}
