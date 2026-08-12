package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TargetLevel;

import java.util.List;

/**
 * Le plan d'action « pour viser X » d'une micro-production, produit par un
 * SECOND appel LLM separe de l'analyse.
 *
 * <p><b>Entierement nullable cote {@link SkillAnalysisDto}</b> : cet appel est
 * best-effort. Il est absent quand l'objectif est deja atteint (la victoire est
 * alors annoncee par {@link SkillLevelProgressDto}), quand le palier vise est
 * inconnu, quand le fournisseur n'a pas repondu, ou quand sa sortie a ete
 * refusee. Un front doit traiter son absence comme un cas NORMAL, jamais comme
 * une erreur.
 *
 * <p>{@code niveauVise} et {@code niveauConstate} sont poses par le SERVEUR : le
 * contrat de sortie du modele ne prevoit aucun champ ou les ecrire.
 *
 * @param niveauVise     le palier qu'exige la demarche du candidat
 * @param niveauConstate le palier demontre par cette production
 * @param leviers        2 a 3 leviers, du plus rentable au moins rentable
 * @param exempleCible   sa reponse reecrite au niveau vise, avec les passages
 *                       a mettre en evidence
 * @param aRetenir       la tournure a emporter ailleurs
 */
public record SkillNiveauViseDto(
        TargetLevel niveauVise,
        NiveauCecrl niveauConstate,
        List<Levier> leviers,
        ExempleCible exempleCible,
        ARetenir aRetenir
) {

    /**
     * Un levier : ce qu'on fait, et avec quels mots.
     *
     * @param action  6 mots maximum, a l'imperatif deuxieme personne
     * @param exemple 5 mots maximum, un bout de langue recopiable tel quel
     */
    public record Levier(String action, String exemple) {
    }

    /**
     * La reponse reecrite, et les endroits ou se joue la difference.
     *
     * @param texte    la reponse du candidat reecrite au niveau vise
     * @param segments 2 a 3 passages a surligner DANS {@code texte}
     */
    public record ExempleCible(String texte, List<Segment> segments) {
    }

    /**
     * Un passage a surligner.
     *
     * <p><b>{@code extrait} est garanti sous-chaine exacte de
     * {@code ExempleCible.texte}</b> : le serveur refuse le bloc entier sinon
     * (une reparation, puis abandon). Un front peut donc surligner par simple
     * recherche de chaine, sans normalisation ni approximation.
     *
     * @param extrait sous-chaine exacte du texte
     * @param apport  ce qu'il apporte, 3 mots maximum
     */
    public record Segment(String extrait, String apport) {
    }

    /**
     * La tournure a retenir.
     *
     * @param formule     8 mots maximum, ecrite comme un patron
     * @param explication 14 mots maximum, quand et pourquoi elle sert
     */
    public record ARetenir(String formule, String explication) {
    }
}
