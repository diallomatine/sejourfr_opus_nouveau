package com.sejourfr.app.dto;

import com.sejourfr.app.enums.SkillCriterionStatus;

/**
 * Retour de l'analyse ciblee, tel qu'il est affiche au candidat.
 *
 * <p><b>Aucune note sur 20</b>, ici comme avant : un micro-exercice de quelques
 * phrases n'en porte pas, et le tool-schema de sortie ne prevoit aucun champ
 * pour en loger une. En revanche le <b>niveau CECRL est desormais rendu</b>
 * (contrat v3) : c'est ce que le candidat vient chercher, et ne rien lui dire le
 * laissait sans reponse a « ou j'en suis ».
 *
 * <h2>Deux generations de champs, aucune migration</h2>
 * Les analyses persistees sous les contrats <b>v1/v2</b> portent
 * {@code successPoint}, {@code improvementPriority} et {@code improvedVersion} ;
 * celles produites sous <b>v3</b> portent {@code strengthTag},
 * {@code focusTag} et {@code levelProgress}. Rien n'a ete migre : les deux jeux
 * cohabitent, <b>tous nullables</b>, et un front doit afficher ce qu'il trouve
 * sans jamais supposer qu'un champ est present.
 *
 * @param status              verdict sur le critere unique. C'est la colonne
 *                            {@code criterion_status} qui fait foi, pas la cle
 *                            JSON — une seule source d'affichage.
 * @param verdict             une phrase : le critere est-il atteint. Present dans
 *                            les deux generations.
 * @param strengthTag         v3 : ce qui est reussi, en 3 mots. Une etiquette,
 *                            pas une phrase. Null sur une analyse ancienne.
 * @param focusTag            v3 : l'axe de progres, en 3 mots. Null sur une
 *                            analyse ancienne.
 * @param levelProgress       v3 : le niveau demontre, l'objectif, la situation et
 *                            la jauge — <b>entierement derive serveur</b>. Null
 *                            sur une analyse ancienne, ou quand le palier vise est
 *                            inconnu.
 * @param niveauVise          le plan d'action du SECOND appel. Null quand
 *                            l'objectif est deja atteint, ou quand l'appel
 *                            best-effort n'a rien produit — cas NORMAL.
 * @param successPoint        legacy v1/v2. Null sur une analyse v3.
 * @param improvementPriority legacy v1/v2. Null sur une analyse v3.
 * @param improvedVersion     legacy v1/v2. Null sur une analyse v3.
 */
public record SkillAnalysisDto(
        SkillCriterionStatus status,
        String verdict,
        String strengthTag,
        String focusTag,
        SkillLevelProgressDto levelProgress,
        SkillNiveauViseDto niveauVise,
        String successPoint,
        String improvementPriority,
        String improvedVersion
) {
}
