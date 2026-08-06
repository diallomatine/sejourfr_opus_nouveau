package com.sejourfr.app.enums;

/**
 * Difficulte relative d'un petit sujet A L'INTERIEUR de sa competence : le
 * premier sujet met le pied a l'etrier, le dernier demande plus d'autonomie.
 * Purement indicatif — aucune regle serveur ne s'y appuie, et l'analyse IA ne
 * le recoit pas.
 *
 * <p><b>Pourquoi pas {@link Difficulty}.</b> Le contrat annonce reutiliser
 * l'enum existant, mais {@code Difficulty} vaut {@code CSP/CR/NAT/A2/B1/B2} :
 * c'est l'axe « procedure visee / palier CECRL » des questions QCM, il ne
 * contient pas {@code EASY/MEDIUM/HARD}. Y ajouter ces trois valeurs les
 * exposerait a tous les DTO de questions, d'examens et de lots — donc aux trois
 * fronts — pour un besoin qui ne concerne que ce module. Un enum dedie garde
 * l'axe editorial local et laisse la contrainte {@code chk_skill_prompts_difficulty}
 * du schema inchangee.
 *
 * <p>Libelles = contrat gele, partage avec les trois fronts et verrouille par
 * {@code SkillLabelsTest}. {@code EASY} se dit « Accessible » et non « Facile » :
 * un sujet annonce facile puis rate humilie le candidat, alors qu'« accessible »
 * decrit le sujet sans juger celui qui le traite (meme ton bienveillant que le
 * verdict de critere).
 */
public enum SkillDifficulty {
    EASY("Accessible"),
    MEDIUM("Intermédiaire"),
    HARD("Exigeant");

    private final String label;

    SkillDifficulty(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}
