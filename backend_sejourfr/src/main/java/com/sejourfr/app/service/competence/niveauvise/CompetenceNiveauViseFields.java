package com.sejourfr.app.service.competence.niveauvise;

/**
 * Noms des champs du contrat « pour viser X », en un seul endroit.
 *
 * <p>Ils voyagent jusqu'aux fronts via
 * {@code user_skill_attempts.analysis_json.pour_viser} : les recopier a la main
 * dans un client, un validateur et un service, c'est exactement la façon dont
 * deux couches finissent par ne plus parler du meme champ.
 */
public final class CompetenceNiveauViseFields {

    /** Sortie du LLM : les 2 a 3 leviers {@code {action, exemple}}. */
    public static final String LEVIERS = "leviers";
    /** Sortie du LLM : {@code {texte, segments}}. */
    public static final String EXEMPLE_CIBLE = "exemple_cible";
    /** Sortie du LLM : {@code {formule, explication}}. */
    public static final String A_RETENIR = "a_retenir";

    /** Levier : ce qu'il faut faire, 6 mots max, a l'imperatif. */
    public static final String ACTION = "action";
    /** Levier : un bout de langue reutilisable tel quel, 5 mots max. */
    public static final String EXEMPLE = "exemple";

    /** Exemple cible : la reponse du candidat reecrite au niveau vise. */
    public static final String TEXTE = "texte";
    /** Exemple cible : les 2 a 3 passages mis en evidence. */
    public static final String SEGMENTS = "segments";
    /** Segment : sous-chaine EXACTE de {@link #TEXTE}, verifiee serveur. */
    public static final String EXTRAIT = "extrait";
    /** Segment : ce que le passage apporte, 3 mots max. */
    public static final String APPORT = "apport";

    /** A retenir : la tournure reutilisable, 8 mots max. */
    public static final String FORMULE = "formule";
    /** A retenir : quand et pourquoi elle sert, 14 mots max. */
    public static final String EXPLICATION = "explication";

    /**
     * Pose par le SERVEUR, jamais par le LLM : le palier vise par le candidat.
     * Le contrat de sortie ne prevoit aucun champ pour l'ecrire — le modele ne
     * doit pas pouvoir renvoyer un niveau que quiconque prendrait pour un
     * verdict.
     */
    public static final String NIVEAU_VISE = "niveau_vise";
    /** Pose par le SERVEUR : le palier reellement demontre par la production. */
    public static final String NIVEAU_CONSTATE = "niveau_constate";

    static final String TOOL_NAME = "submit_competence_niveau_vise";
    static final String TOOL_DESCRIPTION =
        "Soumet le plan d'action d'un candidat vers le niveau qu'il vise : deux a trois leviers, "
        + "sa reponse reecrite au niveau vise avec les passages qui font la difference, et une "
        + "tournure a retenir. Aucune note, aucun verdict, aucun niveau — le serveur les pose "
        + "lui-meme. Utilise systematiquement cette fonction, jamais de texte libre.";

    private CompetenceNiveauViseFields() {
    }
}
