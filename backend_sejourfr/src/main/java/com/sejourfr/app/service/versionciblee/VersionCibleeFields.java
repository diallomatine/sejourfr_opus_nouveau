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

    /** Sortie du LLM : la réponse réécrite au niveau visé. */
    public static final String TEXTE = "texte";
    /** Sortie du LLM : les 2 à 3 leviers pour y arriver. */
    public static final String CE_QUI_MANQUE = "ce_qui_manque";

    /** Posé par le SERVEUR, jamais par le LLM : le palier visé par le candidat. */
    public static final String NIVEAU_VISE = "niveau_vise";
    /** Posé par le SERVEUR : le palier réellement observé sur cette tâche. */
    public static final String NIVEAU_CONSTATE = "niveau_constate";

    static final String TOOL_NAME = "submit_version_ciblee";
    static final String TOOL_DESCRIPTION =
        "Soumet la reponse du candidat reecrite au niveau qu'il vise, et les deux a trois "
        + "leviers concrets qui l'en separent. Aucune note, aucun niveau CECRL, aucun verdict. "
        + "Utilise systematiquement cette fonction, jamais de texte libre.";

    private VersionCibleeFields() {
    }
}
