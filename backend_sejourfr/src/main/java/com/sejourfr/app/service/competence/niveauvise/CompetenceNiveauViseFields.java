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
    /**
     * Levier, <b>contrat v3</b> : le procede de langue que l'action met en œuvre,
     * valeur de {@link MarqueurPalier} — la MEME enumeration fermee que
     * {@link #TYPE}. C'est lui qui separe un levier d'un conseil de ton.
     */
    public static final String PROCEDE = "procede";

    /** Exemple cible : la reponse du candidat reecrite au niveau vise. */
    public static final String TEXTE = "texte";
    /** Exemple cible : les 2 a 3 passages mis en evidence. */
    public static final String SEGMENTS = "segments";
    /**
     * Exemple cible, <b>contrat v2</b> : les 2 a 3 passages qui DEMONTRENT le
     * palier cible, {@code {extrait, type}}. Ce sont eux qui rendent le palier
     * exigible au lieu de le souhaiter — cf. {@link MarqueurPalier}.
     */
    public static final String MARQUEURS_PALIER = "marqueurs_du_palier";
    /** Segment ou marqueur : sous-chaine EXACTE de {@link #TEXTE}, verifiee serveur. */
    public static final String EXTRAIT = "extrait";
    /** Segment : ce que le passage apporte, 3 mots max. */
    public static final String APPORT = "apport";
    /** Marqueur de palier : le procede illustre, valeur de {@link MarqueurPalier}. */
    public static final String TYPE = "type";

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

    /**
     * Le contrat donne exige-t-il que le palier annonce soit <b>demontre</b> par
     * des marqueurs recopies du texte modele ? Vrai a partir de v2 seulement :
     * sous v1 le champ n'existe pas, et tout ce qui l'entoure (bornes de longueur
     * du texte, filet des marqueurs, reparation dediee) doit rester <b>inerte</b>
     * — c'est ce qui garde le retour arriere reel.
     */
    public static boolean porteLesMarqueursDuPalier(String toolSchemaVersion) {
        return !"v1".equals(toolSchemaVersion);
    }

    /**
     * Contrats de sortie dont chaque levier declare son {@link #PROCEDE}.
     *
     * <p><b>Allowlist</b>, et non un test sur v3 : un retour arriere
     * {@code COMPETENCE_NIVEAU_VISE_TOOL_SCHEMA_VERSION=v2} doit reproduire le
     * comportement d'avant <b>au bit pres</b> — champ ni demande dans le prompt,
     * ni admis par le validateur, ni compte —, et une version future ne doit pas
     * heriter du champ par accident. Meme patron que
     * {@code CompetenceRubricsProvider.envoieLeNiveauCibleDeLaCompetence}.
     */
    private static final java.util.Set<String> CONTRATS_AVEC_PROCEDE_DE_LEVIER =
        java.util.Set.of("v3");

    /**
     * Le contrat donne exige-t-il que chaque levier nomme le <b>procede de
     * langue</b> qu'il met en œuvre ? Vrai a partir de v3 seulement.
     *
     * <p>Sous v2 et v1, tout ce qui entoure ce champ reste <b>inerte</b> : le
     * prompt ne le demande pas, le validateur le refuserait comme une cle hors
     * contrat (comportement d'avant, conserve tel quel), et aucun compteur
     * d'anomalie n'existe.
     */
    public static boolean porteLeProcedeDesLeviers(String toolSchemaVersion) {
        return CONTRATS_AVEC_PROCEDE_DE_LEVIER.contains(toolSchemaVersion);
    }

    static final String TOOL_NAME = "submit_competence_niveau_vise";
    static final String TOOL_DESCRIPTION =
        "Soumet le plan d'action d'un candidat vers le niveau qu'il vise : deux a trois leviers, "
        + "sa reponse reecrite au niveau vise avec les passages qui font la difference, et une "
        + "tournure a retenir. Aucune note, aucun verdict, aucun niveau — le serveur les pose "
        + "lui-meme. Utilise systematiquement cette fonction, jamais de texte libre.";

    private CompetenceNiveauViseFields() {
    }
}
