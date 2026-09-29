package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanRecommendedExerciseDto;
import com.sejourfr.app.entity.ProductionTask;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.manager.ProductionTaskManager;
import com.sejourfr.app.util.ExerciseDuration;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Choisit LA verification en situation d'une competence : une <b>vraie tache
 * TCF</b> a produire, quand le candidat a assez travaille le moyen en cible.
 *
 * <p><b>Jumelle de {@link RecommendedExerciseSelector}</b>, et pour la meme
 * raison : la regle de choix d'un exercice n'existe qu'a un seul endroit. Celle-ci
 * ne pioche pas dans les micro-sujets d'une competence mais dans les sujets de
 * production <b>deja publies</b> de la tache qui la porte
 * ({@link SkillTaskCode} &rarr; epreuve + numero de tache). Aucun contenu n'est
 * genere, aucune banque n'est creee, aucun appel LLM n'est fait : le choix est
 * entierement deterministe.
 *
 * <p><b>Le diagnostic initial n'est jamais rejoue</b> — ses sujets sont exclus a
 * la source (filtre {@code diagnostic_code IS NULL} des deux cotes, catalogue
 * comme historique). Refaire le diagnostic apporterait memorisation, biais et
 * lassitude ; ce qu'on cherche, c'est le <b>transfert</b> sur du contenu neuf.
 *
 * <h2>La regle</h2>
 * <ol>
 *   <li>le premier sujet <b>jamais rendu</b> par ce candidat, dans son ordre
 *       propre (voir plus bas) — du contenu neuf avant tout ;</li>
 *   <li>tous rendus : le premier de ce meme ordre, en ecartant celui dont la
 *       derniere soumission est la plus recente — on ne resert pas la copie qui
 *       vient d'etre rendue ;</li>
 *   <li>aucun sujet publie sur cette tache : rien n'est propose, et l'etape
 *       retombe simplement sur son micro-exercice.</li>
 * </ol>
 *
 * <h2>Pourquoi un ordre PROPRE a chaque candidat, et pourquoi il ne bouge pas</h2>
 * Servir a tout le monde le premier sujet du catalogue concentrerait tous les
 * candidats sur la meme copie ; tirer au sort a chaque lecture donnerait un sujet
 * different a chaque rafraichissement — illisible pour le candidat, impossible a
 * supporter. L'ordre est donc une <b>permutation semee</b> par le couple
 * (candidat, competence) : reproductible d'un appel a l'autre, d'un serveur a
 * l'autre et d'un redemarrage a l'autre, differente d'un candidat au suivant.
 * Elle porte sur le pool <b>entier</b>, pas sur les seuls sujets restants : jouer
 * un autre sujet de la meme tache ne redistribue donc jamais les cartes.
 */
@Component
@RequiredArgsConstructor
public class ReassessmentExerciseSelector {

    private final ProductionTaskManager taskManager;
    private final ProductionSubmissionManager submissionManager;
    private final ProductionAccessService accessService;

    /** Verification recommandee pour une competence, vide si sa tache n'a aucun sujet publie. */
    public Optional<PlanRecommendedExerciseDto> select(UUID userId, Skill skill) {
        if (skill == null) return Optional.empty();
        return Optional.ofNullable(selectAll(userId, List.of(skill)).get(skill.getId()));
    }

    /**
     * Verification recommandee pour plusieurs competences, indexee par
     * competence. Les competences sans tache connue ou sans sujet publie sont
     * <b>absentes</b> de la map — c'est le cas normal qui fait retomber l'etape
     * sur son micro-exercice, jamais une erreur.
     *
     * <p>Cout borne : une requete d'historique, puis un catalogue par tache
     * distincte (6 au maximum, 3 priorites en pratique) et un test d'acces par
     * epreuve (2 au maximum).
     */
    public Map<UUID, PlanRecommendedExerciseDto> selectAll(UUID userId, Collection<Skill> skills) {
        Map<UUID, Skill> bySkillId = new LinkedHashMap<>();
        for (Skill skill : skills) {
            if (skill != null && skill.getTaskCode() != null) {
                bySkillId.putIfAbsent(skill.getId(), skill);
            }
        }
        Map<UUID, PlanRecommendedExerciseDto> out = new LinkedHashMap<>();
        if (bySkillId.isEmpty()) return out;

        Map<UUID, Instant> lastPlayed = submissionManager.findLastSubmittedAtByTask(userId);
        Map<SkillTaskCode, List<ProductionTask>> pools = new EnumMap<>(SkillTaskCode.class);
        Map<EpreuveType, Boolean> locks = new EnumMap<>(EpreuveType.class);

        for (Skill skill : bySkillId.values()) {
            SkillTaskCode taskCode = skill.getTaskCode();
            List<ProductionTask> pool = pools.computeIfAbsent(taskCode, this::publishedPool);
            if (pool.isEmpty()) continue;
            ProductionTask chosen = choose(pool, userId, skill.getId(), lastPlayed);
            if (chosen == null) continue;
            boolean locked = locks.computeIfAbsent(
                    chosen.getEpreuve(), epreuve -> accessService.isTrainingLocked(userId, epreuve));
            out.put(skill.getId(), PlanRecommendedExerciseDto.reassessment(
                    chosen.getId(), skill.getId(), skill.getCode(),
                    title(chosen, pool.indexOf(chosen) + 1), skill.getSection(),
                    chosen.getTacheNumero(),
                    estimatedMinutes(chosen), locked));
        }
        return out;
    }

    /**
     * Duree estimee d'une verification, <b>derivee du sujet</b> par la meme
     * regle que celle d'un micro-exercice ({@link ExerciseDuration}) : une
     * verification n'est pas un micro-sujet de trois minutes, et ce n'est pas
     * une constante non plus.
     */
    static int estimatedMinutes(ProductionTask task) {
        return task.getEpreuve() == EpreuveType.TCF_EO
                ? ExerciseDuration.oral(task.getDureeMaxSec())
                : ExerciseDuration.written(task.getMotsMin(), task.getMotsMax());
    }

    /**
     * Catalogue publie de la tache, dans son ordre de <b>publication</b> (niveau
     * cible puis anciennete, avec l'identifiant comme dernier depart pour que
     * l'ordre soit total). Cet ordre-la ne sert qu'a numeroter le repli
     * « Sujet N » ; le choix, lui, se fait sur la permutation semee.
     */
    private List<ProductionTask> publishedPool(SkillTaskCode taskCode) {
        List<ProductionTask> pool = new ArrayList<>(taskManager.findActive(
                epreuve(taskCode.getSection()), null, (short) taskCode.getTacheNumero()));
        pool.sort(Comparator
                .comparing(ProductionTask::getNiveauCible, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(ProductionTask::getCreatedAt, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(ProductionTask::getId));
        return pool;
    }

    /**
     * Le module Competences et les epreuves completes ont deux enums distincts,
     * volontairement (cf. {@link SkillSection}). C'est ici, et nulle part
     * ailleurs, que les deux mondes se rejoignent : une micro-competence
     * s'accroche a une tache, une tache appartient a une epreuve.
     */
    private static EpreuveType epreuve(SkillSection section) {
        return section == SkillSection.EO ? EpreuveType.TCF_EO : EpreuveType.TCF_EE;
    }

    private static ProductionTask choose(
            List<ProductionTask> pool, UUID userId, UUID skillId, Map<UUID, Instant> lastPlayed) {
        List<ProductionTask> ordered = new ArrayList<>(pool);
        ordered.sort(Comparator
                .comparingLong((ProductionTask task) -> shuffleKey(userId, skillId, task.getId()))
                .thenComparing(ProductionTask::getId));

        for (ProductionTask task : ordered) {
            if (!lastPlayed.containsKey(task.getId())) return task;
        }
        // Tous rendus : on garde le meme ordre seme — donc la meme reponse d'une
        // lecture a l'autre — en ecartant seulement la copie la plus recente.
        UUID mostRecent = ordered.stream()
                .max(Comparator.comparing(task -> lastPlayed.get(task.getId())))
                .map(ProductionTask::getId)
                .orElse(null);
        return ordered.stream()
                .filter(task -> ordered.size() == 1 || !task.getId().equals(mostRecent))
                .findFirst()
                .orElse(null);
    }

    /**
     * Cle de tri pseudo-aleatoire mais <b>reproductible</b> : melangeur
     * splitmix64 sur les bits des trois identifiants. Ni {@code Random} non seme
     * ni {@code hashCode} d'objet — les deux rendraient un sujet different d'un
     * appel ou d'un processus a l'autre.
     */
    private static long shuffleKey(UUID userId, UUID skillId, UUID taskId) {
        long seed = mix(bits(userId));
        seed = mix(seed ^ bits(skillId));
        return mix(seed ^ bits(taskId));
    }

    private static long bits(UUID id) {
        return id.getMostSignificantBits() * 31 + id.getLeastSignificantBits();
    }

    private static long mix(long value) {
        long z = value + 0x9E3779B97F4A7C15L;
        z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9L;
        z = (z ^ (z >>> 27)) * 0x94D049BB133111EBL;
        return z ^ (z >>> 31);
    }

    /**
     * Titre editorial du sujet, ou le repli commun aux trois fronts : « Sujet N »
     * ou {@code N} est le rang de publication. La colonne {@code titre} est
     * nullable, aucun ecran ne suppose qu'elle est renseignee.
     */
    private static String title(ProductionTask task, int rank) {
        String titre = task.getTitre();
        return titre == null || titre.isBlank() ? "Sujet " + rank : titre.strip();
    }
}
