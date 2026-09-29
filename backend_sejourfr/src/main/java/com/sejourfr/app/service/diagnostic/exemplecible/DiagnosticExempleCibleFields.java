package com.sejourfr.app.service.diagnostic.exemplecible;

/**
 * Noms des champs du bloc « avant / apres » du diagnostic initial, en un seul
 * endroit.
 *
 * <p>Ils voyagent jusqu'aux fronts via
 * {@code diagnostic_production_analyses.analysis_json.exemple_cible} : les
 * recopier a la main dans un client, un validateur et un service, c'est
 * exactement la façon dont deux couches finissent par ne plus parler du meme
 * champ.
 */
public final class DiagnosticExempleCibleFields {

    /**
     * Sortie du LLM : le NUMERO de la phrase du candidat qu'il reecrit.
     *
     * <p>Le modele ne recopie jamais cette phrase — il la DESIGNE. Technique du
     * contrat v12 des productions, qui a supprime la categorie entiere des
     * « citations introuvables ». Le serveur resout le numero en texte AVANT
     * persistance, donc aucun miroir DTO ne transporte d'entier.
     */
    public static final String SEGMENT_NUMERO = "segment_numero";

    /** Sortie du LLM : la meme phrase, reecrite au niveau vise. */
    public static final String TEXTE = "texte";

    /** Sortie du LLM : les 2 a 3 passages de {@link #TEXTE} a mettre en evidence. */
    public static final String SEGMENTS = "segments";

    /** Segment : sous-chaine EXACTE de {@link #TEXTE}, verifiee serveur. */
    public static final String EXTRAIT = "extrait";

    /** Segment : ce que le passage apporte, 3 mots max. */
    public static final String APPORT = "apport";

    /**
     * Pose par le SERVEUR : la phrase du candidat, resolue depuis
     * {@link #SEGMENT_NUMERO}. Sous-chaine originale exacte de sa production —
     * le modele n'a aucun champ pour l'ecrire lui-meme.
     */
    public static final String ORIGINAL = "original";

    /**
     * Pose par le SERVEUR, jamais par le LLM : le palier vise par le candidat.
     * Le contrat de sortie ne prevoit aucun champ pour l'ecrire — le modele ne
     * doit pas pouvoir renvoyer un niveau que quiconque prendrait pour un
     * verdict.
     */
    public static final String NIVEAU_VISE = "niveau_vise";

    /** Pose par le SERVEUR : le palier constate par l'analyse diagnostique. */
    public static final String NIVEAU_CONSTATE = "niveau_constate";

    /** Cle du bloc a la racine de {@code analysis_json}. */
    public static final String BLOC = "exemple_cible";

    static final String TOOL_NAME = "submit_diagnostic_exemple_cible";
    static final String TOOL_DESCRIPTION =
        "Soumet l'avant / apres du diagnostic initial : le numero de la phrase ecrite du candidat "
        + "que tu reecris, cette phrase reecrite au niveau qu'il vise, et les deux ou trois "
        + "passages qui font la difference. Aucune note, aucun verdict, aucun niveau — le serveur "
        + "les pose lui-meme. Utilise systematiquement cette fonction, jamais de texte libre.";

    private DiagnosticExempleCibleFields() {
    }
}
