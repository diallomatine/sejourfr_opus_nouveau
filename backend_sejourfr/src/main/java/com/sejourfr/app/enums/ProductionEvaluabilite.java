package com.sejourfr.app.enums;

/**
 * Une production rendue a-t-elle pu etre <b>observee</b> ?
 *
 * <p>C'est un fait sur la production, jamais un verdict sur le candidat. Une
 * production {@link #NON_EVALUABLE} n'a produit <b>aucun</b> niveau, aucune
 * note, aucun accomplissement : les colonnes correspondantes valent
 * {@code NULL} — <b>null = inconnu, jamais mauvais</b>, le principe qui gouverne
 * deja {@code FullTcfExamResponseBuilder} (epreuve jamais ouverte) et
 * {@code TcfProfileService} (epreuve abandonnee sans rien rendre).
 *
 * <p><b>Une seule enum pour les DEUX voies</b> — l'analyse du diagnostic
 * ({@code diagnostic_production_analyses.evaluabilite}) et la correction
 * standard ({@code ai_evaluations.evaluabilite}). Le fait est le meme, le juge
 * est le meme ({@code ProductionValidityService}) : deux copies auraient fini
 * par nommer differemment le meme etat.
 *
 * <p><b>Pourquoi ce champ existe en plus des colonnes nullables.</b> L'absence
 * de ligne signifie « pas encore analysee » ; une ligne {@link #NON_EVALUABLE}
 * signifie « rendue, mais il n'y avait rien a observer ». Les deux etats ne se
 * disent pas pareil au candidat, et un front ne doit pas avoir a les distinguer
 * en testant la nullite de plusieurs champs — ce serait deduire un fait d'un
 * trou.
 *
 * <p>Le serveur ne rend <b>aucune phrase</b> avec ce champ : il expose le fait,
 * la formulation appartient aux fronts.
 */
public enum ProductionEvaluabilite {

    /** La production portait assez de matiere : elle a ete analysee. */
    EVALUABLE,

    /**
     * Rien a observer (production vide ou quasi vide, langue non francaise,
     * recopiage de la consigne). <b>Aucun appel au correcteur n'a ete emis</b> :
     * on ne demande pas a un modele de nommer un palier quand on n'a pas la
     * matiere pour en juger — il en nommerait un quand meme.
     */
    NON_EVALUABLE
}
