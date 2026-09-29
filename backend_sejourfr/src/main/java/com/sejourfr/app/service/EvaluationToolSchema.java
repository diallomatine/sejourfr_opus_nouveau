package com.sejourfr.app.service;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/**
 * REGISTRE des contrats de sortie (tool-schema) que le code sait APPLIQUER.
 *
 * <p>Il existait jusqu'ici trois listes figees, ecrites a trois endroits
 * differents ({@code SCHEMAS_STRICTS}, {@code SCHEMAS_RESTITUTION},
 * {@code SCHEMA_PREUVE_PAR_NUMERO}), plus une egalite litterale dans
 * {@code AiEvaluationService}. Une version pouvait donc entrer en service —
 * fichier livre, matrice de paires a jour, boot vert — sans qu'aucune de ces
 * listes ne la connaisse : le validateur retombait alors <b>silencieusement</b>
 * en mode tolerant. C'est exactement ce qui s'est produit avec le tool-schema
 * v7 (rubriques v13) : plus aucune validation stricte, plus aucun controle de
 * restitution, et une production servie <b>non decoupee</b> a un correcteur a
 * qui le schema reclamait pourtant un numero de segment.
 *
 * <p>Doctrine du depot : ce qui tient la qualite, ce sont les contraintes
 * dures. Ici, la contrainte dure est qu'une version <b>inconnue de ce registre
 * n'existe pas</b> — {@link #of(String)} echoue bruyamment au lieu de degrader.
 * Le boot la resout ({@link ProductionRubricsProvider}), donc une version
 * oubliee empeche l'application de demarrer, avant tout appel paye.
 *
 * <p><b>Les capacites sont DERIVEES DU RANG</b>, jamais d'une liste a
 * rallonger : chaque contrat se lit par rapport a celui qui le precede. Elles
 * sont presque toujours cumulatives — une version ajoute — mais rien n'y
 * oblige : {@link #versionAmelioree()} s'ouvre en v5 et se REFERME en v8,
 * {@link #exemplesEtSuggestions()} vaut depuis toujours et se referme en v9, et
 * cela reste une comparaison de rangs. C'est ce qui fait qu'ajouter une version
 * ne demande que d'ajouter sa constante, pas de retoucher trois ensembles
 * ailleurs. Les marqueurs observables dans les fichiers de schema le confirment
 * un a un ({@code additionalProperties:false} des v4, {@code version_amelioree}
 * des v5 — retire en v8 —, {@code preuve_segment} des v6,
 * {@code exemples_corriges}/{@code suggestions} jusqu'a v8) ; c'est ce que
 * verrouille {@code EvaluationToolSchemaContractTest}.
 *
 * <p>REVERSIBILITE : toutes les versions encore chargeables sont ici, y compris
 * les plus anciennes. Un retour arriere reste une paire de variables
 * d'environnement, sans migration.
 */
enum EvaluationToolSchema {

    /** Contrat historique (rubriques v3 a v4.2) : structure non verifiee. */
    V2("v2"),
    /** Rubriques v5/v6 : {@code points_a_ameliorer} devient un objet. */
    V3("v3"),
    /** Rubriques v7 : profil TCF IRN strict, schema ferme, structure verifiee. */
    V4("v4"),
    /** Rubriques v8 a v11 : restitution (verdict, version amelioree, plafonds). */
    V5("v5"),
    /** Rubriques v12 : la preuve devient un NUMERO de segment. */
    V6("v6"),
    /** Rubriques v13 : memes regles que v6, descriptions reaccentuees. */
    V7("v7"),
    /** Rubriques v14 : v7 sans {@code version_amelioree}. */
    V8("v8"),
    /** Rubriques v15 : v8 sans {@code exemples_corriges} ni {@code suggestions}. */
    V9("v9");

    private static final Map<String, EvaluationToolSchema> PAR_CODE = indexer();

    private final String code;

    EvaluationToolSchema(String code) {
        this.code = code;
    }

    private static Map<String, EvaluationToolSchema> indexer() {
        Map<String, EvaluationToolSchema> index = new LinkedHashMap<>();
        for (EvaluationToolSchema schema : values()) {
            index.put(schema.code, schema);
        }
        return Map.copyOf(index);
    }

    String code() {
        return code;
    }

    /** Vrai si ce contrat est {@code autre} ou une version posterieure. */
    boolean estAuMoins(EvaluationToolSchema autre) {
        return ordinal() >= autre.ordinal();
    }

    /**
     * STRUCTURE verifiee champ par champ (v4 et au-dela). Les contrats
     * anterieurs restent volontairement tolerants : un retour arriere ne doit
     * rien casser.
     */
    boolean strict() {
        return estAuMoins(V4);
    }

    /**
     * Controles de RESTITUTION (v5 et au-dela) : verdict {@code accomplissement
     * .objectif}, {@code version_amelioree} en EE, plafonds de points forts et
     * d'exemples corriges.
     */
    boolean restitution() {
        return estAuMoins(V5);
    }

    /**
     * {@code version_amelioree} FAIT PARTIE DU CONTRAT (v5 a v7) : le champ
     * existe dans le schema, et le serveur l'exige sur une tache ECRITE.
     *
     * <p>C'est la premiere capacite qu'un rang POSTERIEUR retire au lieu
     * d'ajouter — le registre reste derive du rang, pas d'une liste a
     * rallonger : elle s'ouvre en v5 et se referme en v8. Motif : les fronts
     * n'affichent plus ce texte (le modele rendu au candidat est
     * {@code version_ciblee}, produit par un appel separe), et il reecrivait la
     * production AU MEME NIVEAU que le candidat. On payait des tokens de sortie
     * a chaque correction ecrite pour un champ que personne ne lit.
     *
     * <p>Sous v8 le champ n'est plus dans le schema, donc un correcteur qui
     * respecte {@code additionalProperties:false} ne peut plus le produire ; le
     * serveur le retire quand meme, exactement comme il le faisait deja a
     * l'oral. Sa presence n'est jamais une violation : perdre une soumission
     * entiere pour un champ ignore couterait plus cher que de l'ignorer.
     */
    boolean versionAmelioree() {
        return restitution() && !estAuMoins(V8);
    }

    /**
     * {@code exemples_corriges} et {@code suggestions} FONT PARTIE DU CONTRAT
     * (jusqu'a v8 inclus) : les deux champs existent dans le schema, le serveur
     * les exige a la racine d'une sortie stricte et leur applique ses controles
     * (plafond de trois exemples, listes de chaines).
     *
     * <p>DEUXIEME capacite qu'un rang POSTERIEUR retire, apres
     * {@link #versionAmelioree()} : elle se referme en v9. Motif : ces deux
     * champs n'etaient affiches que dans le bloc replie « Voir l'analyse
     * complete » de l'ecran de resultat, qui disparait. On cesse donc de payer
     * des tokens de sortie pour des paves que personne ne lit, et la place
     * gagnee finance un second appel plus utile.
     *
     * <p>Sous v9 ils ne sont plus dans le schema, donc un correcteur qui
     * respecte {@code additionalProperties:false} ne peut plus les produire ; le
     * serveur les retire quand meme. Leur presence n'est jamais une violation :
     * perdre une soumission entiere pour deux champs ignores couterait plus cher
     * que de les ignorer — meme arbitrage que {@link #versionAmelioree()}.
     */
    boolean exemplesEtSuggestions() {
        return !estAuMoins(V9);
    }

    /**
     * PREUVE PAR NUMERO (v6 et au-dela) : la production part decoupee en
     * segments numerotes et le correcteur ne renvoie qu'un entier, resolu en
     * texte par le serveur avant persistance.
     */
    boolean preuveParNumero() {
        return estAuMoins(V6);
    }

    /**
     * Profil TCF IRN strict exige des RUBRIQUES qui portent ce contrat (v4 et
     * au-dela, c'est-a-dire rubriques v7+) : {@code profile: TCF_IRN} et
     * {@code niveau_max: B2} declares dans le fichier.
     */
    boolean profilTcfIrnRequis() {
        return estAuMoins(V4);
    }

    static Optional<EvaluationToolSchema> find(String code) {
        return code == null ? Optional.empty() : Optional.ofNullable(PAR_CODE.get(code.trim()));
    }

    /**
     * Contrat correspondant au code, ou ECHEC BRUYANT. Ne jamais remplacer par
     * un repli tolerant : un mode degrade muet est precisement ce qui a rendu
     * la mise en service du schema v7 invisible.
     */
    static EvaluationToolSchema of(String code) {
        return find(code).orElseThrow(() -> new IllegalStateException(
            "contrat de sortie inconnu du validateur : " + code
                + " — versions appliquees : " + PAR_CODE.keySet()
                + ". Enregistrer la version dans EvaluationToolSchema avant de la mettre en service."));
    }
}
