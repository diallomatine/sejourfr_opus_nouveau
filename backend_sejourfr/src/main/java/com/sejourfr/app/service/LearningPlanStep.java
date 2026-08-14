package com.sejourfr.app.service;

import com.sejourfr.app.entity.SkillPrompt;

import java.util.List;

/**
 * <b>Ce qu'est une etape du Plan</b> : son perimetre et son achevement, ecrits
 * une seule fois.
 *
 * <p>Une etape (une priorite du Plan), ce ne sont PAS les 15 sujets de sa
 * competence : ce sont les {@value #PROMPTS_PAR_ETAPE} premiers sujets
 * <b>actifs</b>, par rang d'affichage croissant. Personne n'allait au bout de 15
 * sujets, et « 2/15 » faisait paraitre l'etape suivante inatteignable.
 *
 * <p><b>Derive, jamais persiste.</b> Aucune table, aucune colonne, aucune
 * migration : le perimetre se relit a chaque appel depuis le rang d'affichage.
 * Ce sont les memes cinq sujets pour tous les candidats et ils ne bougent
 * jamais — meme philosophie que {@link SkillStatusResolver}, qui derive le
 * statut d'un sujet sans le stocker.
 *
 * <p><b>Pas de mecanisme d'unicite entre etapes</b> : il serait mort-ne.
 * {@code LearningPlanPriorityResolver.latestObservedBySkill} ne garde qu'une
 * observation par competence, donc deux etapes ne designent jamais la meme
 * competence, et les cinq sujets d'une etape sont distincts par leur rang.
 */
public final class LearningPlanStep {

    /**
     * Sujets d'une etape du Plan. <b>A ne pas confondre avec</b>
     * {@code SkillAccessService.FREE_PROMPTS_PER_SKILL} (2) : celui-la dit ce
     * qu'un compte gratuit peut jouer, celui-ci ce qu'il faut faire pour
     * terminer l'etape. Consequence assumee : un compte gratuit plafonne a 2/5
     * et aucune etape n'est finissable sans abonnement.
     */
    public static final int PROMPTS_PAR_ETAPE = 5;

    private LearningPlanStep() {
    }

    /**
     * Les sujets de l'etape, a partir des sujets <b>actifs</b> d'une competence
     * <b>deja tries par rang d'affichage croissant</b> (ce que rend
     * {@code SkillPromptManager.findActiveBySkillIds}).
     *
     * <p>Une competence qui publie moins de {@value #PROMPTS_PAR_ETAPE} sujets
     * a une etape plus courte : le perimetre vaut ce qui existe, on n'invente
     * jamais un denominateur.
     */
    public static List<SkillPrompt> scope(List<SkillPrompt> activeByDisplayOrder) {
        return activeByDisplayOrder.size() <= PROMPTS_PAR_ETAPE
                ? activeByDisplayOrder
                : activeByDisplayOrder.subList(0, PROMPTS_PAR_ETAPE);
    }

    /**
     * Progression sur les seuls sujets de l'etape.
     *
     * <p><b>Distincte des compteurs de competence</b>, qui portent sur les 15
     * sujets et gardent la semantique de {@code SkillDto} : le Plan afficherait
     * « /5 » et la fiche de competence « /15 » pour une meme competence si l'on
     * detournait les seconds.
     */
    public record Progress(int promptCount, int attemptedCount, int validatedCount) {

        public static final Progress EMPTY = new Progress(0, 0, 0);

        /**
         * L'etape est <b>terminee</b> quand tous ses sujets ont ete traites —
         * traites, pas valides : on peut terminer une etape sans tout valider,
         * et {@link #validatedCount()} reste l'information distincte.
         *
         * <p>Une etape sans aucun sujet actif n'est jamais terminee : il n'y a
         * rien a faire, le dire « fini » serait un contresens.
         *
         * <p><b>C'est aussi la seconde condition de la bascule vers la
         * verification en situation</b> ({@code LearningPlanService}) : le
         * signal du moteur de maitrise ne suffit pas, l'etape doit etre finie.
         * Le perimetre est ici l'<b>editorial</b> — les
         * {@value #PROMPTS_PAR_ETAPE} sujets, ceux que les fronts affichent —
         * et non ce que l'acces du candidat lui ouvre. Un compte gratuit,
         * plafonne a 2 sujets sur 5, ne bascule donc jamais : c'est un
         * <b>arbitrage produit</b> (la verification est premium), pas une
         * propriete du moteur. Ne pas le « reparer » en comptant les sujets
         * ouverts.
         */
        public boolean completed() {
            return promptCount > 0 && attemptedCount >= promptCount;
        }
    }
}
