package com.sejourfr.app.enums;

/**
 * <b>Ce que le Plan demande de faire</b> sur une entree — la pastille d'une
 * carte « Aujourd'hui » et d'une carte « Mes priorites ».
 *
 * <p>Le Plan n'est pas seulement un moteur de <b>remediation</b> : c'est un
 * moteur de <b>progression vers le niveau cible</b>. Il savait reparer ce qui
 * etait fragile ; il ne savait pas <b>enseigner</b> ce qui n'avait jamais ete
 * travaille. {@link #A_ACQUERIR} est exactement cette troisieme categorie, et
 * elle repond a deux constats jumeaux :
 * <ul>
 *   <li><i>non observe &ne; faible</i> — une competence jamais mesuree n'est pas
 *       une faiblesse ;</li>
 *   <li><i>non fragile &ne; plus rien a apprendre</i> — un candidat A2 qui vise
 *       le B2 a un palier entier devant lui, meme sans une seule fragilite
 *       mesuree.</li>
 * </ul>
 *
 * <p>🛑 <b>{@link #A_ACQUERIR} ne se dit JAMAIS « a renforcer ».</b> Renforcer
 * suppose un constat negatif ; ici il n'y en a aucun. C'est une distinction de
 * fond, pas de vocabulaire : rien n'a ete observe, donc rien n'a echoue.
 *
 * <h2>Trois vocabulaires, trois grains — ils ne se remplacent pas</h2>
 * <table>
 *   <caption>Ou vit chaque enum</caption>
 *   <tr><th>enum</th><th>grain</th><th>persiste ?</th><th>surface</th></tr>
 *   <tr><td>{@link LearningPlanSkillStatus}</td>
 *       <td>le verdict d'<b>une production</b></td>
 *       <td>oui, sur chaque observation</td>
 *       <td>aucune, il n'a pas de libelle</td></tr>
 *   <tr><td>{@link SkillMasteryState}</td>
 *       <td>l'etat <b>agrege</b> d'une competence, tout l'historique confondu</td>
 *       <td>non, derive</td><td>la fiche d'une competence</td></tr>
 *   <tr><td>{@code PlanActionNature}</td>
 *       <td>l'<b>action a faire maintenant</b> sur cette entree du Plan</td>
 *       <td>non, derive</td><td>la carte du Plan et l'item de seance</td></tr>
 * </table>
 * {@code SkillMasteryState.TO_REINFORCE} et {@link #A_RENFORCER} portent le meme
 * libelle FR, et c'est <b>voulu</b> : quand les deux s'appliquent, ils disent la
 * meme chose. Ils ne s'affichent simplement pas au meme endroit — l'etat sur la
 * fiche de la competence, la nature sur la carte du Plan. {@link PlanDomainPriority},
 * lui, qualifie un <b>domaine</b> (une des quatre lignes du profil TCF), jamais
 * une action : c'est pourquoi « A travailler » et « Entretien » vivent la-bas et
 * ne sont pas repris ici.
 *
 * <p><b>L'ordre de declaration EST l'ordre de choix</b> des actions d'une
 * seance (patron {@link PlanDomainPriority} et {@link SkillReferenceLevel}) :
 * mesurer ce qui manque, reparer ce qui est fragile, verifier ce qui est pret,
 * apprendre ce qui vient. Ne pas le reordonner.
 *
 * <p><b>Libelles geles</b> par {@code SkillLabelsTest} et recopies a la main
 * dans les fronts.
 */
public enum PlanActionNature {

    /**
     * <b>Une mesure manque, et elle est indispensable</b> : le candidat a rendu
     * une production sur ce domaine et le correcteur n'a rien pu y observer.
     * L'action n'est pas un exercice, c'est une <b>evaluation</b>
     * ({@code PlanDomainAssessmentDto}).
     *
     * <p>A distinguer d'un domaine simplement jamais mesure, qui vit dans
     * {@code LearningPlanDto.domainesAEvaluer} : ici le candidat a deja
     * travaille, et c'est notre mesure qui a echoue — lui proposer des
     * micro-exercices sans jamais le mesurer le laisserait tourner en rond.
     */
    A_EVALUER("À évaluer"),

    /** Une fragilite <b>reellement observee</b> : c'est ce qui bloque maintenant. */
    A_RENFORCER("À renforcer"),

    /**
     * La competence a assez ete travaillee en cible et son etape est terminee :
     * le Plan cesse d'empiler les micro-sujets et demande une <b>verification en
     * situation</b>.
     */
    A_VERIFIER("À vérifier"),

    /**
     * <b>Une competence du palier en construction, jamais travaillee.</b> Aucun
     * constat negatif ne la designe : elle est la parce qu'elle appartient au
     * palier que le cycle construit et que le candidat ne l'a pas encore
     * abordee.
     *
     * <p>Elle n'est <b>pas</b> une observation : elle n'entre ni dans le score
     * du moteur de maitrise, ni dans une moyenne, ni dans un compte de
     * fragilites. Son {@code masteryState} vaut {@code null} — <i>null =
     * inconnu, jamais mauvais</i>.
     */
    A_ACQUERIR("À acquérir");

    private final String label;

    PlanActionNature(String label) {
        this.label = label;
    }

    /** Libelle FR rendu au candidat, tel quel. */
    public String getLabel() {
        return label;
    }
}
