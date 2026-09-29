package com.sejourfr.app.service.versionciblee;

/**
 * Noms des champs du contrat « version au niveau visé », en un seul endroit.
 *
 * <p>Ils voyagent jusqu'aux trois fronts via {@code feedback_json.version_ciblee} :
 * les recopier à la main dans un client, un validateur et un service, c'est
 * exactement la façon dont deux couches finissent par ne plus parler du même
 * champ.
 */
public final class VersionCibleeFields {

    /** Clé du bloc ajouté à la racine du feedback persisté. */
    public static final String BLOC = "version_ciblee";

    /**
     * Clé du bloc <b>alternatif</b> : le palier visé est déjà atteint, il n'y a
     * pas de marche au-dessus à montrer.
     *
     * <p>Exclusif de {@link #BLOC} — les deux ne coexistent jamais. Sans lui, un
     * front ne pouvait pas distinguer « objectif atteint » (une victoire, à
     * annoncer) de « le second appel LLM a échoué » (un incident, à taire) : la
     * section disparaissait en silence dans les deux cas, et depuis le retrait de
     * {@code version_amelioree} le candidat se retrouvait sans aucun texte modèle
     * ni la moindre explication. C'est un signal SERVEUR, exactement comme
     * {@code SkillStatusResolver} : aucun front ne le déduit.
     */
    public static final String BLOC_ATTEINT = "niveau_vise_atteint";

    // ------------------------------------------------------------ contrat v1

    /** Sortie du LLM (v1) : la réponse réécrite au niveau visé. */
    public static final String TEXTE = "texte";
    /** Sortie du LLM (v1) : les 2 à 3 leviers, en texte libre. */
    public static final String CE_QUI_MANQUE = "ce_qui_manque";

    // ------------------------------------------------------------ contrat v2

    /** Sortie du LLM (v2) : les 2 à 3 leviers {@code {action, exemple}}. */
    public static final String LEVIERS = "leviers";
    /** Levier : ce qu'il faut faire, 6 mots max, à l'impératif. */
    public static final String ACTION = "action";
    /** Levier : un bout de langue réutilisable tel quel, 5 mots max. */
    public static final String EXEMPLE = "exemple";

    /** Sortie du LLM (v2, ÉCRIT) : {@code {texte, segments}}. */
    public static final String EXEMPLE_CIBLE = "exemple_cible";
    /** Exemple cible : les 2 à 3 passages mis en évidence. */
    public static final String SEGMENTS = "segments";
    /** Segment : sous-chaîne EXACTE de {@link #TEXTE}, vérifiée serveur. */
    public static final String EXTRAIT = "extrait";
    /** Segment / reformulation : ce que le passage apporte, 3 mots max. */
    public static final String APPORT = "apport";

    /**
     * Sortie du LLM (v2, ORAL) : les 2 à 3 passages du candidat redits au niveau
     * visé. La production orale n'est jamais réécrite en entier.
     */
    public static final String REFORMULATIONS = "reformulations";
    /**
     * Reformulation, TEL QUE RENDU PAR LE LLM : le NUMÉRO du segment reformulé.
     * Technique du contrat de correction v12, qui a supprimé la catégorie entière
     * des citations introuvables. <b>Ce champ ne survit pas à la persistance</b> :
     * le serveur le résout en texte, comme {@code resolvePreuveSegments}.
     */
    public static final String SEGMENT_NUMERO = "segment_numero";
    /** Reformulation : le passage du candidat, redit au niveau visé. */
    public static final String REFORMULE = "reformule";
    /**
     * Reformulation, POSÉ PAR LE SERVEUR : le texte exact du segment désigné.
     * Aucun miroir DTO ne transporte jamais un entier — les fronts lisent une
     * chaîne, exactement comme {@code feedback_json.preuve}.
     */
    public static final String ORIGINAL = "original";

    /** Sortie du LLM (v2) : {@code {formule, explication}}. */
    public static final String A_RETENIR = "a_retenir";
    /** À retenir : la tournure réutilisable, 8 mots max. */
    public static final String FORMULE = "formule";
    /** À retenir : quand et pourquoi elle sert, 14 mots max. */
    public static final String EXPLICATION = "explication";

    // ------------------------------------------------------- posés par le serveur

    /** Posé par le SERVEUR, jamais par le LLM : le palier visé par le candidat. */
    public static final String NIVEAU_VISE = "niveau_vise";
    /** Posé par le SERVEUR : le palier réellement observé sur cette tâche. */
    public static final String NIVEAU_CONSTATE = "niveau_constate";

    static final String TOOL_NAME = "submit_version_ciblee";

    /** Description de l'outil, contrat v1 (écrit seulement). */
    static final String TOOL_DESCRIPTION =
        "Soumet la reponse du candidat reecrite au niveau qu'il vise, et les deux a trois "
        + "leviers concrets qui l'en separent. Aucune note, aucun niveau CECRL, aucun verdict. "
        + "Utilise systematiquement cette fonction, jamais de texte libre.";

    /** Description de l'outil, contrat v2 sur une production ECRITE. */
    static final String TOOL_DESCRIPTION_ECRIT =
        "Soumet le plan d'action d'un candidat vers le niveau qu'il vise sur une production "
        + "ECRITE : deux a trois leviers, sa reponse reecrite a ce niveau avec les passages qui "
        + "font la difference, et une tournure a retenir. Aucune note, aucun niveau, aucun "
        + "verdict — le serveur les pose lui-meme. Utilise systematiquement cette fonction, "
        + "jamais de texte libre.";

    /** Description de l'outil, contrat v2 sur une production ORALE. */
    static final String TOOL_DESCRIPTION_ORAL =
        "Soumet le plan d'action d'un candidat vers le niveau qu'il vise sur une production "
        + "ORALE : deux a trois leviers, deux a trois de ses passages redits a ce niveau et "
        + "designes par leur NUMERO, et une tournure a retenir. La production orale n'est jamais "
        + "reecrite en entier. Aucune note, aucun niveau, aucun verdict — le serveur les pose "
        + "lui-meme. Utilise systematiquement cette fonction, jamais de texte libre.";

    /** Description à envoyer au fournisseur pour un contrat et une variante donnés. */
    static String toolDescription(VersionCibleeContrat contrat, VersionCibleeVariante variante) {
        if (!contrat.planDAction()) return TOOL_DESCRIPTION;
        return variante == VersionCibleeVariante.ORAL ? TOOL_DESCRIPTION_ORAL
            : TOOL_DESCRIPTION_ECRIT;
    }

    private VersionCibleeFields() {
    }
}
