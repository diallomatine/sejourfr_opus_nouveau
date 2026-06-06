package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

import java.util.List;
import java.util.UUID;

/**
 * Agrégat unique pour le tableau de bord web : un seul appel
 * {@code GET /api/me/dashboard} alimente tout l'écran (stat cards + cards
 * de progression par catégorie + recommandations).
 *
 * <ul>
 *   <li>{@code currentStreakDays} : jours CONSÉCUTIFS d'activité (≥1 attempt
 *       démarré dans la journée, fuseau Europe/Paris) se terminant aujourd'hui
 *       ou hier. 0 si la série est rompue.</li>
 *   <li>{@code recordStreakDays} : plus longue série observée sur tout
 *       l'historique.</li>
 *   <li>{@code activeToday} : true si au moins un attempt démarré aujourd'hui —
 *       permet au front d'adapter le wording ("continuez" vs "reprenez").</li>
 *   <li>{@code mockExamsTotal} : nb d'examens blancs (MOCK_EXAM) finis, tous
 *       modules confondus.</li>
 *   <li>{@code civiqueMockExams} / {@code tcfMockExams} : totaux par module
 *       pour les hubs (TCF : sous-attempts d'un examen complet exclus —
 *       seul le parent TCF_COMPLET compte).</li>
 *   <li>{@code globalSuccessPercent} : progression globale 0-100 = moyenne
 *       des progressions des catégories renseignées (Civique + TCF, EE/EO
 *       inclus). Null si rien travaillé.</li>
 *   <li>{@code estimatedTcfLevel} : niveau CECRL du dernier examen TCF évalué
 *       (examen blanc complet en priorité, sinon examen module). Null si aucun.</li>
 *   <li>{@code civique} / {@code tcf} : une entrée par catégorie, TOUS les
 *       thèmes du module (même jamais travaillés → percent null). Côté TCF,
 *       deux entrées synthétiques {@code TCF_EE} / {@code TCF_EO} sont
 *       ajoutées depuis les évaluations IA.</li>
 * </ul>
 */
public record DashboardSummaryResponse(
        int currentStreakDays,
        int recordStreakDays,
        boolean activeToday,
        int mockExamsTotal,
        int civiqueMockExams,
        int tcfMockExams,
        Integer globalSuccessPercent,
        NiveauCecrl estimatedTcfLevel,
        List<CategoryStat> civique,
        List<CategoryStat> tcf
) {

    /**
     * Stat d'une catégorie du dashboard.
     *
     * <ul>
     *   <li>{@code themeId} : null pour les entrées synthétiques EE/EO.</li>
     *   <li>{@code percent} : progression 0-100 = réussite × confiance
     *       (réussite = réussies/répondues distinctes ; confiance =
     *       min(1, répondues / min(40, pool))). EE/EO : moyenne des notes /20
     *       des 3 dernières soumissions ×5 × min(1, soumissions/3). Null si
     *       jamais travaillée. Cf. UserDashboardService.</li>
     *   <li>{@code answered} / {@code total} : couverture du pool (questions
     *       distinctes tentées / questions actives). 0/0 pour EE/EO.</li>
     *   <li>{@code mockExams} : nb d'examens blancs finis scopés à la
     *       catégorie (civique : examens thématiques ; TCF : examens module
     *       CO/CE/STRUCTURE). 0 pour EE/EO.</li>
     *   <li>{@code bestMockScore} / {@code lastMockScore} /
     *       {@code prevMockScore} : record, dernier et avant-dernier score
     *       brut sur les examens de la catégorie (page Progression : « record
     *       17/20 » + flèche de tendance dernier vs avant-dernier). Null si
     *       pas assez d'examens.</li>
     *   <li>{@code level} : dernier niveau CECRL évalué — renseigné uniquement
     *       pour EE/EO.</li>
     * </ul>
     */
    public record CategoryStat(
            UUID themeId,
            String code,
            String label,
            Integer percent,
            int answered,
            int total,
            int mockExams,
            Integer bestMockScore,
            Integer lastMockScore,
            Integer prevMockScore,
            NiveauCecrl level
    ) {
    }
}
