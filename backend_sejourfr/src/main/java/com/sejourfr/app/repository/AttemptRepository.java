package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * IMPORTANT : recopier uniquement les méthodes manquantes si tu as déjà
 * un AttemptRepository.
 */
@Repository
public interface AttemptRepository extends JpaRepository<Attempt, UUID> {

    @Query("""
            SELECT COUNT(a) FROM Attempt a
            WHERE a.user.id = :userId
              AND a.tcfDiagnostic IS NULL
              AND a.civicDiagnostic IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM DiagnosticSession d
                  WHERE d.writtenAttempt = a OR d.oralAttempt = a
              )
            """)
    long countStandardByUserId(@Param("userId") UUID userId);

    @Query("""
            SELECT COUNT(a) FROM Attempt a
            WHERE a.user.id = :userId AND a.module = :module
              AND a.tcfDiagnostic IS NULL
              AND a.civicDiagnostic IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM DiagnosticSession d
                  WHERE d.writtenAttempt = a OR d.oralAttempt = a
              )
            """)
    long countStandardByUserIdAndModule(
            @Param("userId") UUID userId, @Param("module") Module module);

    long countByExamTemplateId(UUID examTemplateId);

    List<Attempt> findByUserIdOrderByStartedAtDesc(UUID userId);

    /**
     * Purge de tous les attempts d'un user (suppression de compte). Le DELETE
     * SQL déclenche les FK cascade base : {@code attempt_questions} → {@code
     * answers}, {@code production_submissions} → {@code transcriptions} /
     * {@code ai_evaluations}, et les sous-attempts ({@code parent_attempt_id}).
     */
    @Modifying
    @Query("DELETE FROM Attempt a WHERE a.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);


    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND (:type IS NULL OR a.type = :type)
              AND (:module IS NULL OR a.module = :module)
              AND (:moduleExamQuestionType IS NULL OR a.moduleExamQuestionType = :moduleExamQuestionType)
              AND (:themeId IS NULL OR a.lotThemeId = :themeId)
              AND a.tcfDiagnostic IS NULL
              AND a.civicDiagnostic IS NULL
              AND NOT EXISTS (
                  SELECT 1 FROM DiagnosticSession d
                  WHERE d.writtenAttempt = a OR d.oralAttempt = a
              )
            ORDER BY a.startedAt DESC
            """)
    List<Attempt> findByUserFiltered(
            @Param("userId") UUID userId,
            @Param("type") AttemptType type,
            @Param("module") Module module,
            @Param("moduleExamQuestionType") QuestionType moduleExamQuestionType,
            @Param("themeId") UUID themeId,
            Pageable pageable
    );

    // Quota guest (countByClientIp...AndStartedAtAfter) supprimé 2026-05-17 :
    // la démo est désormais illimitée. L'index partiel idx_attempts_demo_quota
    // est laissé en base (cf. V092) au cas où on rétablit un quota plus tard.

    /**
     * Ids des attempts <b>invités</b> ({@code user_id IS NULL}) démarrés avant
     * {@code cutoff}, plafonnés par la page — lot d'une passe de purge (cf.
     * {@code GuestAttemptPurgeJob}). Le filtre est celui que couvre déjà
     * l'index partiel {@code idx_attempts_demo_quota} (V006), dont la clause
     * {@code WHERE user_id IS NULL} est exactement notre prédicat.
     *
     * <p>Le tri sur {@code startedAt} rend les lots déterministes : une passe
     * traite toujours les plus anciens d'abord, donc deux passes successives ne
     * repassent pas sur le même sous-ensemble.
     */
    @Query("""
            SELECT a.id FROM Attempt a
            WHERE a.user IS NULL AND a.startedAt < :cutoff
            ORDER BY a.startedAt ASC
            """)
    List<UUID> findGuestAttemptIdsStartedBefore(@Param("cutoff") Instant cutoff, Pageable pageable);

    /**
     * Supprime un lot d'attempts invités. Le {@code a.user IS NULL} est
     * <b>redondant</b> avec la sélection ci-dessus et c'est volontaire : un
     * attempt rattaché à un compte est l'historique du candidat et la source de
     * vérité du freemium, il ne doit pouvoir être emporté par aucune passe de
     * purge, même sur une liste d'ids fausse.
     *
     * <p>Les tables filles partent en cascade <b>base</b>
     * ({@code attempt_questions} → {@code answers}, V006) : aucune suppression
     * manuelle à écrire ici.
     */
    @Modifying
    @Query("DELETE FROM Attempt a WHERE a.id IN :ids AND a.user IS NULL")
    int deleteGuestAttemptsByIds(@Param("ids") Collection<UUID> ids);

    /**
     * Lookup sécurisé d'un attempt guest : exige que l'attempt soit bien
     * démo (user IS NULL) ET appartienne à la même IP que le caller.
     */
    Optional<Attempt> findByIdAndClientIpAndUserIsNull(UUID id, String clientIp);

    /**
     * Pour chaque lot d'un (module, questionType, difficulty) que l'utilisateur
     * a déjà terminé, renvoie son <b>dernier attempt fini</b> trié par lot
     * croissant. Sert à enrichir `GET /api/lots` avec le score précédent affiché
     * sur les cards des lots déjà faits.
     *
     * <p>Plusieurs attempts pour un même lot → on prend le plus récent via
     * {@code DISTINCT ON (lot_numero)} simulé en JPQL par un sous-ordre +
     * une déduplication côté service. La query renvoie ici tous les attempts
     * finis triés (date desc, puis numero asc) — `LotService` filtre le premier
     * de chaque lot.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.module = :module
              AND a.lotQuestionType = :questionType
              AND a.lotDifficulty = :difficulty
              AND a.lotNumero IS NOT NULL
              AND a.finishedAt IS NOT NULL
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findFinishedByUserAndLot(
            @Param("userId") UUID userId,
            @Param("module") Module module,
            @Param("questionType") QuestionType questionType,
            @Param("difficulty") Difficulty difficulty
    );

    /**
     * Variante Civique de {@link #findFinishedByUserAndLot} : filtre par
     * {@code lotThemeId} au lieu de difficulty/questionType. Sert à enrichir
     * `GET /api/lots?module=CIVIQUE&themeId=...` avec le dernier score du user
     * sur chaque lot.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.module = com.sejourfr.app.enums.Module.CIVIQUE
              AND a.lotThemeId = :themeId
              AND a.lotNumero IS NOT NULL
              AND a.finishedAt IS NOT NULL
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findFinishedByUserAndLotCivique(
            @Param("userId") UUID userId,
            @Param("themeId") UUID themeId
    );

    /**
     * Liste les sous-attempts d'un examen blanc TCF complet (parent
     * {@code TCF_COMPLET}). Ordonnés par {@code startedAt asc} — l'ordre de
     * création correspond à l'ordre des épreuves (CO, CE, EE, EO).
     */
    List<Attempt> findByParentAttemptIdOrderByStartedAtAsc(UUID parentAttemptId);

    /**
     * Les sous-attempts de PLUSIEURS examens blancs d'un coup — la forme de
     * liste. Le parent est {@code JOIN FETCH}é : l'appelant regroupe par
     * {@code parentAttempt.getId()}, et le lire en lazy referait un N+1 sur la
     * relation, exactement celui qu'on vient de retirer sur les requêtes.
     */
    @Query("""
            SELECT a FROM Attempt a
                     JOIN FETCH a.parentAttempt p
            WHERE p.id IN :parentAttemptIds
            ORDER BY a.startedAt ASC
            """)
    List<Attempt> findByParentAttemptIds(
            @Param("parentAttemptIds") Collection<UUID> parentAttemptIds);

    /**
     * Lookup d'un attempt avec son parent eager-loaded (LEFT JOIN FETCH).
     * Utilisé hors transaction longue (ex: {@code ProductionEvaluationService})
     * pour pouvoir lire {@code parentAttempt.epreuve} sans déclencher de
     * {@code LazyInitializationException}.
     */
    @Query("SELECT a FROM Attempt a LEFT JOIN FETCH a.parentAttempt WHERE a.id = :id")
    Optional<Attempt> findByIdWithParent(@Param("id") UUID id);

    /**
     * Historique des examens blancs TCF complets d'un utilisateur (parent
     * uniquement, tri descendant). Utilisé par {@code GET /api/me/full-tcf-exams}.
     *
     * <p>🛑 <b>Les diagnostics TCF sont exclus</b> ({@code tcfDiagnostic IS NULL},
     * V049) : ils partagent le parent {@code TCF_COMPLET} mais ne sont pas des
     * examens blancs — 10_ §4.1 l'interdit explicitement. Sans ce filtre, un
     * diagnostic occuperait un slot de la grille des 20 examens.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.epreuve = :epreuve
              AND a.tcfDiagnostic IS NULL
              AND a.civicDiagnostic IS NULL
            ORDER BY a.startedAt DESC
            """)
    List<Attempt> findByUserAndEpreuve(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable
    );

    /**
     * Jours d'activité distincts du user (date locale Europe/Paris du
     * {@code started_at} de chaque attempt), triés du plus récent au plus
     * ancien. Sert au calcul de la série de jours consécutifs (streak) du
     * dashboard — le calcul de la série elle-même vit côté service.
     *
     * <p>Les diagnostics TCF sont ici <b>comptés</b>, et c'est voulu : passer
     * une section de diagnostic EST un jour de travail. Le filtre
     * {@code tcfDiagnostic IS NULL} des autres requêtes protège les compteurs
     * d'examens blancs, pas la mesure d'activité.
     */
    @Query(value = """
            SELECT DISTINCT CAST(a.started_at AT TIME ZONE 'Europe/Paris' AS date)
            FROM attempts a
            WHERE a.user_id = :userId
            ORDER BY 1 DESC
            """, nativeQuery = true)
    List<LocalDate> findDistinctActivityDates(@Param("userId") UUID userId);

    /**
     * Examens blancs terminés d'un user. 🛑 Les diagnostics TCF en sont exclus :
     * ce compteur alimente « examens blancs passés » du tableau de bord, et un
     * diagnostic n'en est pas un.
     */
    @Query("""
            SELECT COUNT(a) FROM Attempt a
            WHERE a.user.id = :userId
              AND a.type = :type
              AND a.finishedAt IS NOT NULL
              AND a.tcfDiagnostic IS NULL
              AND a.civicDiagnostic IS NULL
            """)
    long countByUserIdAndTypeAndFinishedAtIsNotNull(
            @Param("userId") UUID userId, @Param("type") AttemptType type);

    /**
     * Sessions d'examen blanc production (EE/EO) d'un user — attempts marqués
     * {@code slotNumber} non null à la création, en ne comptant que celles où
     * au moins une tâche a été soumise (un start abandonné sans soumission ne
     * consomme rien : le coût réel est l'évaluation IA). Sert au budget
     * freemium : 1 examen gratuit, le 2ᵉ consomme les essais d'entraînement
     * restants, ensuite 403.
     */
    @Query("""
            SELECT COUNT(a) FROM Attempt a
            WHERE a.user.id = :userId
              AND a.epreuve IN :epreuves
              AND a.slotNumber IS NOT NULL
              AND EXISTS (SELECT 1 FROM ProductionSubmission s WHERE s.attempt = a)
            """)
    long countProductionExamSessions(
            @Param("userId") UUID userId,
            @Param("epreuves") java.util.Collection<EpreuveType> epreuves);

    /**
     * Épreuves QCM TCF (CO ou CE) <b>réellement passées</b> par le user :
     * examen blanc fini portant <b>au moins une réponse enregistrée</b>, du
     * plus récent au plus ancien.
     *
     * <p><b>Définition d'une épreuve « abandonnée sans rien rendre » : zéro
     * réponse.</b> Elle est exclue d'office par le {@code EXISTS} — au niveau
     * d'un candidat, « aucune preuve » n'est pas « mauvaise preuve ». (À ne pas
     * confondre avec le résultat d'UN examen donné, où une épreuve abandonnée
     * sans verrou reste comptée {@code A1_NON_ATTEINT} : c'est le résultat de
     * cet examen-là.)
     *
     * <p>Le filtre porte sur {@code epreuve}, pas sur
     * {@code moduleExamQuestionType} : il couvre ainsi les examens module
     * standalone, les sous-attempts d'un examen blanc complet et les anciens
     * diagnostics où cette colonne est nulle.
     *
     * <p>🛑 <b>Les sous-épreuves d'un diagnostic TCF comptent</b> (2026-09-16,
     * <b>révoque l'exclusion V049</b>). L'exclusion se justifiait par une
     * différence de composition : le score calibré 100-499 s'établit sur 25
     * items, quand une section de diagnostic en comptait 15. Cette différence
     * <b>n'existe plus depuis le 2026-09-13</b> — {@code
     * TcfDiagnosticSectionStarter.creerComprehension} appelle le même {@code
     * composeModuleExam} que l'examen de module : mêmes 25 items (10 A2 / 8 B1 /
     * 7 B2), même tirage, même durée. Une CE passée dans le diagnostic complet
     * est, ligne pour ligne, la même mesure qu'une CE passée seule ; la garder
     * dehors privait le profil de la seule mesure que beaucoup de candidats
     * avaient. Journal : {@code docs/decisions/diagnostic.md}.
     *
     * <p>Aucun double comptage n'en découle, et c'est une propriété des
     * <b>appelants</b>, pas de la requête : {@code TcfProfileService.bestQcm}
     * retient le <b>meilleur</b> résultat par épreuve — jamais une somme ni une
     * moyenne, donc une même épreuve mesurée deux fois n'est comptée qu'une, à
     * sa meilleure valeur. ⚠️ <b>Second appelant depuis le 2026-09-16</b> :
     * {@code ProgressionExamensService} (écran de progression d'une épreuve), qui en garde la <b>chronologie</b>
     * (les 3 plus récentes) pour expliquer ce niveau au candidat. Il n'agrège
     * rien non plus. 🛑 Tout appelant futur qui <b>sommerait</b> ces lignes
     * rouvrirait la question que la révocation de V049 avait fermée.
     *
     * <p>🛑 <b>Les examens pilotés par un {@code ExamTemplate} sont exclus</b>
     * (D18, 2026-09-24). Un template TCF ({@code tcf-diagnostic},
     * {@code tcf-mix-*}) compose un examen de <b>50 à 60 questions mêlant CO,
     * CE et STRUCTURE</b>, et {@code Attempt.prePersist} lui pose
     * {@code epreuve = TCF_CO} <b>par défaut</b> ({@code deriveEpreuveFromModule}) :
     * son {@code epreuve} ne dit donc rien de ce qu'il mesure. Le compter comme
     * une CO versait des items de CE et de STRUCTURE dans le niveau affiché de
     * la CO ({@code NiveauActuelEpreuveResolver} cumule les strates) et dans
     * l'historique de l'épreuve. Mesuré sur la base locale : 3 attempts de ce
     * type répondaient au prédicat. Le chemin reste ouvert côté web (briefing
     * {@code /examens-blancs/[slug]}, démo invitée), l'exclusion vaut donc aussi
     * pour l'avenir. Les examens d'épreuve ({@code moduleExamQuestionType}),
     * les sous-épreuves d'examen complet et de diagnostic n'ont jamais de
     * template : ils ne sont pas touchés.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.type = com.sejourfr.app.enums.AttemptType.MOCK_EXAM
              AND a.epreuve = :epreuve
              AND a.finishedAt IS NOT NULL
              AND a.civicDiagnostic IS NULL
              AND a.examTemplate IS NULL
              AND EXISTS (SELECT 1 FROM Answer an WHERE an.attemptQuestion.attempt = a)
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findQcmEpreuvesPassees(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable);

    /**
     * Épreuves de production TCF (EE/EO) <b>réellement passées</b> : session
     * d'examen blanc terminée portant <b>au moins une soumission</b>, du plus
     * récent au plus ancien.
     *
     * <p>🛑 <b>Le prédicat est celui de
     * {@code ProductionAccessService.isExamSession}</b>, écrit ici en JPQL
     * parce qu'une méthode Java ne se pousse pas dans une requête :
     * {@code slotNumber} posé au démarrage (épreuve jouée seule) <b>ou</b>
     * {@code parentAttempt} (sous-épreuve d'un examen complet, diagnostic TCF
     * complet inclus). Les deux conditions doivent rester synchronisées avec
     * ce prédicat — {@code ProgressionExamensServiceIT} le vérifie sur les deux
     * provenances.
     *
     * <p>🛑 <b>L'entraînement libre est exclu, et c'est voulu</b> : une tâche
     * d'entraînement ne porte aucun niveau d'épreuve
     * ({@code ProductionBilanService} n'agrège que sur une session d'examen —
     * « jamais de niveau en entraînement libre »). L'y faire entrer inventerait
     * un palier là où le produit n'en calcule pas.
     *
     * <p>🛑 <b>Les productions du diagnostic RAPIDE n'y sont pas</b> : leurs
     * attempts n'ont ni slot ni parent, et leur verdict vit dans
     * {@code diagnostic_production_analyses}. Elles sont lues à part, par
     * {@code DiagnosticProductionAnalysisRepository}.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.epreuve = :epreuve
              AND a.finishedAt IS NOT NULL
              AND (a.slotNumber IS NOT NULL OR a.parentAttempt IS NOT NULL)
              AND EXISTS (SELECT 1 FROM ProductionSubmission s WHERE s.attempt = a)
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findProductionEpreuvesPassees(
            @Param("userId") UUID userId,
            @Param("epreuve") EpreuveType epreuve,
            Pageable pageable);

    /**
     * Parmi ces sessions, lesquelles sont des <b>examens blancs</b> ?
     *
     * <p>C'est la question du filtre R1 du parcours TCF (D-6) : en comprehension,
     * une observation porte l'identifiant de sa session mais <b>pas</b> son type,
     * et le parcours doit distinguer un examen — qui peut creer des etapes —
     * d'une serie ciblee, qui ne peut que les faire avancer.
     *
     * <p><b>Une requete pour tout un historique</b>, jamais une par observation :
     * un candidat assidu en aligne des centaines, et {@code findById} par ligne
     * serait un N+1 pur a chaque lecture du parcours.
     */
    @Query("""
            SELECT a.id FROM Attempt a
            WHERE a.id IN :ids
              AND a.type = com.sejourfr.app.enums.AttemptType.MOCK_EXAM
            """)
    List<UUID> findMockExamIdsAmong(@Param("ids") Collection<UUID> ids);

    /**
     * Examens civiques <b>globaux</b> réellement passés (écran de progression
     * civique, D10/D11) : {@code MOCK_EXAM} civique terminé, hors diagnostic,
     * sans thème, portant au moins une réponse — du plus récent au plus ancien.
     *
     * <p>« Au moins une réponse » : même définition du « qualifiant » que
     * {@link #findQcmEpreuvesPassees} — un examen ouvert puis abandonné sans
     * rien rendre n'est pas un mauvais résultat, il n'est pas une mesure.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.type = com.sejourfr.app.enums.AttemptType.MOCK_EXAM
              AND a.module = com.sejourfr.app.enums.Module.CIVIQUE
              AND a.finishedAt IS NOT NULL
              AND a.civicDiagnostic IS NULL
              AND a.lotThemeId IS NULL
              AND EXISTS (SELECT 1 FROM Answer an WHERE an.attemptQuestion.attempt = a)
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findCivicExamensGlobauxPasses(
            @Param("userId") UUID userId,
            Pageable pageable);

    /**
     * Examens civiques <b>de thème</b> réellement passés, pour les thèmes
     * demandés (un seul : écran de thème ; les cinq : écran global) — même
     * prédicat que {@link #findCivicExamensGlobauxPasses}, du plus récent au
     * plus ancien. Une requête pour tous les thèmes, jamais une par thème.
     */
    @Query("""
            SELECT a FROM Attempt a
            WHERE a.user.id = :userId
              AND a.type = com.sejourfr.app.enums.AttemptType.MOCK_EXAM
              AND a.module = com.sejourfr.app.enums.Module.CIVIQUE
              AND a.finishedAt IS NOT NULL
              AND a.civicDiagnostic IS NULL
              AND a.lotThemeId IN :themeIds
              AND EXISTS (SELECT 1 FROM Answer an WHERE an.attemptQuestion.attempt = a)
            ORDER BY a.finishedAt DESC
            """)
    List<Attempt> findCivicExamensThemePasses(
            @Param("userId") UUID userId,
            @Param("themeIds") Collection<UUID> themeIds,
            Pageable pageable);
}
