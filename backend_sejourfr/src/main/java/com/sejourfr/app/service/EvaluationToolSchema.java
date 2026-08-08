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
 * <p><b>Les capacites sont CUMULATIVES et derivees du RANG</b>, jamais d'une
 * liste a rallonger : chaque contrat reprend celui qui le precede et y ajoute.
 * C'est l'histoire reelle des sept versions, et c'est ce qui fait qu'ajouter
 * une v8 ne demande que d'ajouter sa constante — pas de retoucher trois
 * ensembles ailleurs. Les marqueurs observables dans les fichiers de schema le
 * confirment un a un ({@code additionalProperties:false} des v4,
 * {@code version_amelioree} des v5, {@code preuve_segment} des v6) ; c'est ce
 * que verrouille {@code EvaluationToolSchemaContractTest}.
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
    V7("v7");

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
