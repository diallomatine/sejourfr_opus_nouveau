package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Question;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface QuestionRepository
        extends JpaRepository<Question, UUID>, JpaSpecificationExecutor<Question> {

    // ------------------------------------------------------------------------
    // Sélection aléatoire pour le runner
    //
    // NB : filtrer sur questionType = CO inclut AUSSI les questions CO_IMAGE
    // (image + 4 propositions lues) — c'est un format de Compréhension orale,
    // tiré dans les mêmes pools (entraînement, lots, examen module, examen
    // complet) que les CO classiques. La recherche admin passe par les
    // Specifications (QuestionSpecifications.hasType) et reste, elle, précise.
    // ------------------------------------------------------------------------

    /**
     * Tire des questions actives au hasard pour un module, avec filtres
     * optionnels (themeId / difficulty / questionType : null = pas de filtre).
     * <p>
     * On utilise JPQL (et non du natif + SpEL) pour deux raisons :
     *   - Hibernate convertit proprement les enums @Enumerated(STRING) et les
     *     UUID null, là où PostgreSQL en natif réclame des CAST explicites.
     *   - Pas de SpEL : la lisibilité est meilleure et il n'y a plus de
     *     parameter binding qui dépend d'une expression dynamique.
     * <p>
     * La limite est portée par le {@link Pageable} (passer
     * {@code PageRequest.of(0, size)} depuis le service).
     */
    @Query("""
            SELECT q FROM Question q
            WHERE q.active = true
              AND q.module = :module
              AND (:themeId IS NULL OR q.theme.id = :themeId)
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
              AND (:questionType IS NULL
                   OR q.questionType = :questionType
                   OR (:questionType = com.sejourfr.app.enums.QuestionType.CO
                       AND q.questionType = com.sejourfr.app.enums.QuestionType.CO_IMAGE))
            ORDER BY function('random')
            """)
    List<Question> findRandom(
            @Param("module") Module module,
            @Param("themeId") UUID themeId,
            @Param("difficulty") Difficulty difficulty,
            @Param("questionType") QuestionType questionType,
            Pageable pageable
    );

    /**
     * Variante de {@link #findRandom} qui exclut un ensemble d'ids déjà tirés.
     * Utilisée par la génération d'examens blancs basés sur ExamTemplateRule :
     * on applique les règles l'une après l'autre en gardant trace des questions
     * déjà sélectionnées, pour garantir l'unicité intra-attempt.
     * <p>
     * Hibernate refuse un {@code NOT IN (...)} avec une collection vide : la
     * méthode publique {@link #findRandomExcluding} dispatche vers
     * {@link #findRandom} dans ce cas.
     */
    @Query("""
            SELECT q FROM Question q
            WHERE q.active = true
              AND q.module = :module
              AND (:themeId IS NULL OR q.theme.id = :themeId)
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
              AND (:questionType IS NULL
                   OR q.questionType = :questionType
                   OR (:questionType = com.sejourfr.app.enums.QuestionType.CO
                       AND q.questionType = com.sejourfr.app.enums.QuestionType.CO_IMAGE))
              AND q.id NOT IN :excludeIds
            ORDER BY function('random')
            """)
    List<Question> findRandomExcludingInternal(
            @Param("module") Module module,
            @Param("themeId") UUID themeId,
            @Param("difficulty") Difficulty difficulty,
            @Param("questionType") QuestionType questionType,
            @Param("excludeIds") Collection<UUID> excludeIds,
            Pageable pageable
    );

    default List<Question> findRandomExcluding(
            Module module,
            UUID themeId,
            Difficulty difficulty,
            QuestionType questionType,
            Collection<UUID> excludeIds,
            Pageable pageable
    ) {
        if (excludeIds == null || excludeIds.isEmpty()) {
            return findRandom(module, themeId, difficulty, questionType, pageable);
        }
        return findRandomExcludingInternal(module, themeId, difficulty, questionType, excludeIds, pageable);
    }

    /**
     * Sélection déterministe pour le mode démo (TRAINING, utilisateur non
     * abonné). Toujours la même série de questions pour un module donné,
     * indépendamment du thème ou de la difficulté : on garantit ainsi un
     * aperçu reproductible avant l'abonnement.
     * <p>
     * Tri par {@code created_at, id} (ordre stable, indépendant des seeds DB).
     */
    @Query("""
            SELECT q FROM Question q
            WHERE q.active = true
              AND q.module = :module
            ORDER BY q.createdAt ASC, q.id ASC
            """)
    List<Question> findDemoPool(
            @Param("module") Module module,
            Pageable pageable
    );

    /**
     * Variante déterministe de {@link #findRandomExcludingInternal} : même
     * signature, mais ORDER BY {@code created_at ASC, id ASC} au lieu de
     * {@code random()}. Utilisée par la composition d'un ExamTemplate côté
     * démo / non-premium pour garantir que rejouer un template free redonne
     * exactement la même série de questions.
     */
    @Query("""
            SELECT q FROM Question q
            WHERE q.active = true
              AND q.module = :module
              AND (:themeId IS NULL OR q.theme.id = :themeId)
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
              AND (:questionType IS NULL
                   OR q.questionType = :questionType
                   OR (:questionType = com.sejourfr.app.enums.QuestionType.CO
                       AND q.questionType = com.sejourfr.app.enums.QuestionType.CO_IMAGE))
              AND q.id NOT IN :excludeIds
            ORDER BY q.createdAt ASC, q.id ASC
            """)
    List<Question> findOrderedExcludingInternal(
            @Param("module") Module module,
            @Param("themeId") UUID themeId,
            @Param("difficulty") Difficulty difficulty,
            @Param("questionType") QuestionType questionType,
            @Param("excludeIds") Collection<UUID> excludeIds,
            Pageable pageable
    );

    @Query("""
            SELECT q FROM Question q
            WHERE q.active = true
              AND q.module = :module
              AND (:themeId IS NULL OR q.theme.id = :themeId)
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
              AND (:questionType IS NULL
                   OR q.questionType = :questionType
                   OR (:questionType = com.sejourfr.app.enums.QuestionType.CO
                       AND q.questionType = com.sejourfr.app.enums.QuestionType.CO_IMAGE))
            ORDER BY q.createdAt ASC, q.id ASC
            """)
    List<Question> findOrdered(
            @Param("module") Module module,
            @Param("themeId") UUID themeId,
            @Param("difficulty") Difficulty difficulty,
            @Param("questionType") QuestionType questionType,
            Pageable pageable
    );

    default List<Question> findOrderedExcluding(
            Module module,
            UUID themeId,
            Difficulty difficulty,
            QuestionType questionType,
            Collection<UUID> excludeIds,
            Pageable pageable
    ) {
        if (excludeIds == null || excludeIds.isEmpty()) {
            return findOrdered(module, themeId, difficulty, questionType, pageable);
        }
        return findOrderedExcludingInternal(module, themeId, difficulty, questionType, excludeIds, pageable);
    }

    /**
     * Tirage d'une <b>serie ciblee</b> : les questions du bon domaine et du bon
     * niveau que ce candidat a vues <b>le moins recemment</b>, jamais vues
     * d'abord.
     *
     * <p>C'est la reponse aux quatre exigences du brief §14 en une seule
     * clause : <i>privilegier les questions jamais vues</i> (elles n'ont pas de
     * derniere vue, donc {@code NULLS FIRST} les met en tete), <i>eviter de
     * remettre immediatement la meme</i> et <i>permettre la repetition apres
     * epuisement de la banque, avec une distance temporelle raisonnable</i>
     * (une fois le stock neuf epuise, ce sont les plus anciennes qui
     * reviennent, jamais celles de la serie precedente). Il n'y a donc <b>pas de
     * fenetre de refroidissement a regler</b> : l'ordre s'en charge, et aucune
     * valeur arbitraire n'a a etre choisie.
     *
     * <p>{@code random()} n'est que le departage <b>a l'interieur</b> d'un meme
     * rang de fraicheur : deux series successives ne redonnent pas les memes
     * vingt questions jamais vues, mais aucune question deja vue ne peut passer
     * devant une question neuve.
     *
     * <p>Requete native : la sous-requete de derniere vue et le
     * {@code NULLS FIRST} n'ont pas d'equivalent portable en JPQL. La jointure
     * est bornee par l'historique du seul candidat.
     *
     * <p>{@code CO} inclut {@code CO_IMAGE}, comme partout ailleurs dans le
     * depot : c'est un format de question de comprehension orale, pas un
     * domaine a part.
     */
    @Query(value = """
            SELECT q.* FROM questions q
            LEFT JOIN (
                SELECT aq.question_id AS question_id, MAX(a.started_at) AS last_seen
                FROM attempt_questions aq
                JOIN attempts a ON a.id = aq.attempt_id
                WHERE a.user_id = :userId
                GROUP BY aq.question_id
            ) vu ON vu.question_id = q.id
            WHERE q.is_active = true
              AND q.module = :module
              AND q.difficulty = :difficulty
              AND (q.question_type = :questionType
                   OR (:questionType = 'CO' AND q.question_type = 'CO_IMAGE'))
            ORDER BY vu.last_seen ASC NULLS FIRST, random()
            LIMIT :size
            """, nativeQuery = true)
    List<Question> findLeastRecentlySeen(
            @Param("userId") UUID userId,
            @Param("module") String module,
            @Param("difficulty") String difficulty,
            @Param("questionType") String questionType,
            @Param("size") int size
    );

    /**
     * Le meme tirage, <b>restreint a une bande de difficulte</b> — la brique du
     * blueprint qualifiant 6 EASY / 10 MEDIUM / 4 HARD (moteur de progression
     * V4.2 §6.2, §7).
     *
     * <p>Les questions non taguees ({@code difficulty_band IS NULL}) sont
     * exclues, jamais rangees dans une bande par defaut : leur affecter
     * « MEDIUM » affirmerait une mesure qui n'a pas eu lieu. Une bande qui ne
     * peut pas etre remplie fait simplement echouer la composition calibree, et
     * la serie retombe en {@code UNCALIBRATED} — ce qui est la verite.
     */
    @Query(value = """
            SELECT q.* FROM questions q
            LEFT JOIN (
                SELECT aq.question_id AS question_id, MAX(a.started_at) AS last_seen
                FROM attempt_questions aq
                JOIN attempts a ON a.id = aq.attempt_id
                WHERE a.user_id = :userId
                GROUP BY aq.question_id
            ) vu ON vu.question_id = q.id
            WHERE q.is_active = true
              AND q.module = :module
              AND q.difficulty = :difficulty
              AND q.difficulty_band = :band
              AND (q.question_type = :questionType
                   OR (:questionType = 'CO' AND q.question_type = 'CO_IMAGE'))
            ORDER BY vu.last_seen ASC NULLS FIRST, random()
            LIMIT :size
            """, nativeQuery = true)
    List<Question> findLeastRecentlySeenInBand(
            @Param("userId") UUID userId,
            @Param("module") String module,
            @Param("difficulty") String difficulty,
            @Param("questionType") String questionType,
            @Param("band") String band,
            @Param("size") int size
    );

    /**
     * Les questions TCF de comprehension d'un perimetre, pour l'export de
     * calibration (§7). Les deux filtres sont facultatifs et se cumulent.
     */
    @Query(value = """
            SELECT q.* FROM questions q
            WHERE q.is_active = true
              AND q.module = 'TCF'
              AND q.difficulty IN ('A2', 'B1', 'B2')
              AND (
                    (:section IS NULL AND q.question_type IN ('CO', 'CO_IMAGE', 'CE'))
                 OR (:section = 'CO' AND q.question_type IN ('CO', 'CO_IMAGE'))
                 OR (:section = 'CE' AND q.question_type = 'CE')
              )
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
            ORDER BY q.difficulty, q.question_type, q.created_at
            """, nativeQuery = true)
    List<Question> findForCalibration(@Param("section") String section,
                                      @Param("difficulty") String difficulty);

    /** Combien de questions taguees d'une bande sont disponibles (§12 bis.5). */
    @Query(value = """
            SELECT COUNT(*) FROM questions q
            WHERE q.is_active = true
              AND q.module = :module
              AND q.difficulty = :difficulty
              AND q.difficulty_band = :band
              AND (q.question_type = :questionType
                   OR (:questionType = 'CO' AND q.question_type = 'CO_IMAGE'))
            """, nativeQuery = true)
    long countInBand(
            @Param("module") String module,
            @Param("difficulty") String difficulty,
            @Param("questionType") String questionType,
            @Param("band") String band
    );

    // ------------------------------------------------------------------------
    // Stats / agrégations
    // ------------------------------------------------------------------------

    long countByModule(Module module);

    long countByModuleAndActive(Module module, boolean active);

    long countByThemeId(UUID themeId);

    long countByThemeIdAndActiveTrue(UUID themeId);

    long countByPassageId(UUID passageId);

    /**
     * Stock de questions actives par (type, palier), <b>en une seule requête
     * agrégée</b>. Sert le filtre de faisabilité du Plan côté compréhension :
     * une compétence de palier dont le stock est vide ne peut porter aucune
     * série ciblée, donc aucune action.
     *
     * <p>Renvoie {@code [questionType, difficulty, count]}. `CO_IMAGE` est
     * rendu tel quel — au caller de le replier sur `CO`, comme partout ailleurs
     * dans le dépôt.
     */
    @Query("""
            SELECT q.questionType, q.difficulty, COUNT(q)
            FROM Question q
            WHERE q.active = true
              AND q.questionType IN :types
            GROUP BY q.questionType, q.difficulty
            """)
    List<Object[]> countActiveByTypeAndDifficulty(
            @Param("types") Collection<QuestionType> types);

    /**
     * Compte les questions actives matchant les contraintes (les paramètres
     * null sont ignorés). Utilisé par le suggesteur de composition côté admin
     * pour exposer le stock réellement disponible avant de proposer une règle,
     * et par LotService pour déterminer combien de lots peuvent être formés.
     */
    @Query("""
            SELECT COUNT(q) FROM Question q
            WHERE q.active = true
              AND q.module = :module
              AND (:themeId IS NULL OR q.theme.id = :themeId)
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
              AND (:questionType IS NULL
                   OR q.questionType = :questionType
                   OR (:questionType = com.sejourfr.app.enums.QuestionType.CO
                       AND q.questionType = com.sejourfr.app.enums.QuestionType.CO_IMAGE))
            """)
    long countActiveMatching(
            @Param("module") Module module,
            @Param("themeId") UUID themeId,
            @Param("difficulty") Difficulty difficulty,
            @Param("questionType") QuestionType questionType
    );
}
