package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.SkillPromptManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * <b>Une action n'existe que si elle est EXECUTABLE.</b>
 *
 * <p>Le Plan est passe de deux actions servies a un pool complet. Sans ce
 * filtre, il proposerait des competences <b>sans contenu rattache</b> : le
 * candidat tape sur une carte et tombe sur un ecran vide — pire que l'etat
 * d'avant, parce qu'il a fait confiance a la carte.
 *
 * <h2>Deux branches, jamais la meme requete</h2>
 * <ul>
 *   <li><b>expression</b> (EE/EO) : la competence a-t-elle au moins un
 *       <b>petit sujet actif</b> ? Le micro-exercice se joue sur un sujet
 *       publie, il n'y a pas de repli ;</li>
 *   <li><b>comprehension</b> (CO/CE) : y a-t-il des <b>questions actives a ce
 *       palier</b> ? La serie ciblee ne choisit aucun contenu a l'avance — son
 *       tirage vit au demarrage de la session —, donc ce qu'on verifie est le
 *       <b>stock</b>, pas un rattachement.</li>
 * </ul>
 *
 * <h2>Cout : deux requetes agregees, constantes</h2>
 * Une pour les competences d'expression qui ont un sujet, une pour le stock de
 * questions par (type, palier). 🛑 <b>Jamais un compte par competence</b> :
 * c'est exactement le N+1 que ce composant existe pour eviter, et la condition
 * posee par le proprietaire (2026-08-26) pour accepter que le budget de
 * requetes du Plan augmente.
 *
 * <h2>Le compteur de coupe</h2>
 * {@link Disponibilite#nonExecutables()} dit ce que le filtre a ecarte. Il est
 * <b>logue a chaque coupe</b>, et c'est volontaire : aujourd'hui il ne coupe
 * rien (48/48 competences d'expression ont 15 sujets, les six paliers de
 * comprehension ont entre 134 et 214 questions), donc toute ligne dans les logs
 * signale un <b>pourrissement du catalogue</b> — une desactivation de contenu
 * qui va priver des candidats d'actions. Mieux vaut l'apprendre par un log que
 * par un candidat.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class PlanContentAvailability {

    /** Les deux familles de questions qui alimentent une serie ciblee. */
    private static final List<QuestionType> TYPES_COMPREHENSION =
            List.of(QuestionType.CO, QuestionType.CO_IMAGE, QuestionType.CE);

    private final SkillPromptManager promptManager;
    private final QuestionManager questionManager;

    /** Le stock disponible, lu en deux requetes agregees. */
    public Disponibilite charger() {
        return new Catalogue(
                promptManager.findSkillIdsWithActivePrompt(),
                questionManager.countActiveByTypeAndDifficulty(TYPES_COMPREHENSION));
    }

    /**
     * Ce que le catalogue permet de proposer aujourd'hui.
     *
     * <p><b>Une interface, pas un record</b> : c'est la couture que les tests du
     * moteur remplacent par « tout est disponible », sans avoir a fabriquer un
     * catalogue entier pour decrire une regle de selection.
     */
    public interface Disponibilite {

        /**
         * Cette competence peut-elle porter une action <b>a ce palier</b> ?
         *
         * @param palier le palier travaille — il ne sert qu'en comprehension,
         *               ou le stock est indexe par palier. En expression, le
         *               palier vit deja sur la competence.
         */
        boolean estExecutable(Skill skill, TargetLevel palier);

        /**
         * Ecarte ce qui n'est pas executable et <b>logue ce qui a ete coupe</b>.
         *
         * @param palierParCompetence le palier travaille de chaque competence —
         *                            seule la comprehension s'en sert
         */
        List<Skill> filtrer(List<Skill> candidates, Map<UUID, TargetLevel> palierParCompetence);
    }

    /**
     * Le catalogue reel, tel que les deux requetes agregees l'ont lu.
     *
     * @param competencesAvecSujet competences d'expression ayant au moins un
     *                             sujet actif
     * @param stockComprehension   nombre de questions actives par (type, palier)
     */
    public record Catalogue(
            Set<UUID> competencesAvecSujet,
            Map<QuestionType, Map<Difficulty, Long>> stockComprehension)
            implements Disponibilite {

        @Override
        public boolean estExecutable(Skill skill, TargetLevel palier) {
            if (skill == null || skill.getSection() == null) return false;
            SkillSection section = skill.getSection();
            if (section.isComprehension()) {
                if (palier == null) return false;
                QuestionType type = section == SkillSection.CO
                        ? QuestionType.CO : QuestionType.CE;
                Difficulty difficulte = difficulte(palier);
                return difficulte != null
                        && stockComprehension.getOrDefault(type, Map.of())
                        .getOrDefault(difficulte, 0L) > 0;
            }
            return competencesAvecSujet.contains(skill.getId());
        }

        @Override
        public List<Skill> filtrer(
                List<Skill> candidates, Map<UUID, TargetLevel> palierParCompetence) {
            List<Skill> executables = candidates.stream()
                    .filter(skill -> estExecutable(skill, palierParCompetence.get(skill.getId())))
                    .toList();
            if (executables.size() != candidates.size()) {
                List<String> coupees = candidates.stream()
                        .filter(skill -> !executables.contains(skill))
                        .map(Skill::getCode)
                        .toList();
                log.warn("Plan : {} competence(s) ecartee(s) faute de contenu publie — {}. "
                        + "Le catalogue prive ces candidats d'une action.",
                        coupees.size(), coupees);
            }
            return executables;
        }

        /** {@code A2}/{@code B1}/{@code B2} portent le meme nom des deux cotes. */
        private static Difficulty difficulte(TargetLevel palier) {
            for (Difficulty valeur : Difficulty.values()) {
                if (valeur.name().equals(palier.name())) return valeur;
            }
            return null;
        }
    }
}
