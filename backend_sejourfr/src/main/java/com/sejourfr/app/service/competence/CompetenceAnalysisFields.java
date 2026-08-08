package com.sejourfr.app.service.competence;

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
 * <p><b>Cinq cles, et aucune autre.</b> Il n'existe volontairement aucune cle
 * de note ni de niveau CECRL : un micro-exercice de quelques phrases ne permet
 * ni l'un ni l'autre.
 */
public final class CompetenceAnalysisFields {

    /** Verdict sur le critere unique : {@code VALIDATED|PARTIAL|NOT_VALIDATED}. */
    public static final String STATUS = "status";

    /** Une phrase qui dit ce que la production accomplit ou manque. */
    public static final String VERDICT = "verdict";

    /** Ce qui est reussi — toujours renseigne, meme sur une production faible. */
    public static final String SUCCESS_POINT = "success_point";

    /** LA priorite de progression, une seule, actionnable. */
    public static final String IMPROVEMENT_PRIORITY = "improvement_priority";

    /** Reformulation qui conserve l'idee DU CANDIDAT, pas un modele de substitution. */
    public static final String IMPROVED_VERSION = "improved_version";

    private CompetenceAnalysisFields() {
    }
}
