package com.sejourfr.app.enums;

/**
 * Une production du diagnostic a-t-elle pu etre <b>observee</b> ?
 *
 * <p>C'est un fait sur la production, jamais un verdict sur le candidat. Une
 * production {@link #NON_EVALUABLE} n'a produit <b>aucun</b> niveau, aucun
 * accomplissement, aucun statut de communication : les trois colonnes
 * correspondantes valent {@code NULL} — <b>null = inconnu, jamais mauvais</b>,
 * le principe qui gouverne deja {@code FullTcfExamResponseBuilder} (epreuve
 * jamais ouverte) et {@code TcfProfileService} (epreuve abandonnee sans rien
 * rendre).
 *
 * <p><b>Pourquoi ce champ existe en plus des trois colonnes devenues
 * nullables.</b> L'absence d'une ligne
 * {@code diagnostic_production_analyses} signifie « pas encore analysee » ; une
 * ligne {@code NON_EVALUABLE} signifie « rendue, mais il n'y avait rien a
 * observer ». Les deux etats se disent differemment au candidat, et un front ne
 * doit pas avoir a les distinguer en testant la nullite de trois champs — ce
 * serait deduire un fait d'un trou.
 *
 * <p>Le serveur ne rend <b>aucune phrase</b> avec ce champ : il expose le fait,
 * la formulation appartient aux fronts.
 */
public enum DiagnosticEvaluabilite {

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
