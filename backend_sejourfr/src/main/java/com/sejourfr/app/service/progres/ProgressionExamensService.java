package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.FullTcfExamResponse;
import com.sejourfr.app.dto.LignePartTheme;
import com.sejourfr.app.dto.ProgressionCiviqueDto;
import com.sejourfr.app.dto.ProgressionCtaDto;
import com.sejourfr.app.dto.ProgressionEchelleDto;
import com.sejourfr.app.dto.ProgressionEpreuveDto;
import com.sejourfr.app.dto.ProgressionMesureDto;
import com.sejourfr.app.dto.ProgressionResumeDto;
import com.sejourfr.app.dto.ProgressionTcfDto;
import com.sejourfr.app.dto.ProgressionThemeDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProgressionEtatSource;
import com.sejourfr.app.enums.ProgressionProvenance;
import com.sejourfr.app.enums.ProgressionRapport;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.EpreuvesProductionQualifiantesResolver;
import com.sejourfr.app.service.FullTcfExamResponseBuilder;
import com.sejourfr.app.service.ProductionAccessService;
import com.sejourfr.app.service.TcfLevelEstimatorService;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticThemeResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Les quatre écrans de progression</b> ({@code /api/me/progression/*}) :
 * TCF global, une épreuve TCF, civique global, un thème civique.
 *
 * <h2>Ce que ce service lit, et seulement cela</h2>
 * <p>🛑 <b>Des examens blancs, jamais un diagnostic</b> (arbitrages D1 et D10
 * du propriétaire, 2026-09-24) :
 * <ul>
 *   <li>une épreuve TCF : l'examen de l'épreuve passé seul <b>et</b> la même
 *       épreuve jouée dans un examen complet — même composition, même durée,
 *       donc comparables ;</li>
 *   <li>un thème civique : ses examens de thème (20 questions) ;</li>
 *   <li>le civique global : ses examens globaux (40 questions), découpés par
 *       thème en « x / n posées » (D11).</li>
 * </ul>
 *
 * <h2>Ce que ce service ne calcule pas</h2>
 * <p>🛑 <b>Aucune règle de classement n'est écrite ici</b> : chaque valeur est
 * demandée à son autorité, appelée jamais recopiée — les définitions du
 * « qualifiant » ({@code AttemptManager.findQcmEpreuvesPassees},
 * {@link EpreuvesProductionQualifiantesResolver}), le palier QCM par strates et
 * le score de progression ({@link TcfLevelEstimatorService}), le palier et la
 * note d'épreuve EE/EO ({@code ProductionBilanService}, via le resolver des
 * qualifiantes), l'examen complet et son plancher re-dérivé
 * ({@link FullTcfExamResponseBuilder}, D19), l'état civique
 * ({@link CivicDiagnosticThemeResolver}), le niveau actuel de l'Accueil
 * ({@link TcfProfileService#levelProfileAccueil}), les verrous
 * ({@link ProductionAccessService}, {@link AttemptService}). Le seul code à
 * règle neuf — meilleur, premier, écart, ordinal, durée fiable — vit dans
 * {@link ResumeExamensResolver}.
 *
 * <h2>Freemium</h2>
 * <p>🛑 <b>D20</b> : tout est servi à un compte gratuit, ses propres résultats
 * compris. Seul le bouton « Nouvel examen blanc » porte un {@code locked}.
 *
 * <h2>Coût</h2>
 * <p>🛑 Un nombre de requêtes <b>constant</b>, quel que soit le nombre
 * d'examens : chaque lecture est groupée (niveaux QCM, soumissions,
 * évaluations, sous-épreuves, parts par thème). Verrouillé à l'égalité par
 * {@code ProgressionSansNPlusUnIT}.
 */
@Service
@RequiredArgsConstructor
public class ProgressionExamensService {

    /**
     * Examens lus par liste. Un plafond de LECTURE, pas un budget : il couvre
     * très largement l'historique d'un candidat (la grille compte 20 créneaux
     * par épreuve), et l'écran montre tout ce qu'il lit.
     */
    public static final int LIMITE_EXAMENS = 50;

    /** Examens complets / globaux montrés sur un écran global sans {@code ?tous=true}. */
    public static final int DERNIERS_EXAMENS = 3;

    /** 🛑 Les quatre épreuves du TCF IRN. {@code TCF_STRUCTURE} n'en est pas une. */
    private static final List<EpreuveType> EPREUVES = List.of(
            EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EE, EpreuveType.TCF_EO);

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final ThemeManager themeManager;
    private final TcfLevelEstimatorService levelEstimator;
    private final EpreuvesProductionQualifiantesResolver qualifiantesResolver;
    private final FullTcfExamResponseBuilder fullExamBuilder;
    private final TcfProfileService tcfProfileService;
    private final ProductionAccessService productionAccessService;
    private final AttemptService attemptService;
    private final CivicDiagnosticThemeResolver civicThemeResolver;
    private final ResumeExamensResolver resumeResolver;
    private final ProgressionEchelleResolver echelleResolver;

    // ══════════════════════════════════════════════════════════════════════
    //  TCF
    // ══════════════════════════════════════════════════════════════════════

    /** {@code GET /api/me/progression/tcf/{epreuve}}. */
    @Transactional(readOnly = true)
    public ProgressionEpreuveDto epreuve(UUID userId, EpreuveType epreuve) {
        if (epreuve == null || !EPREUVES.contains(epreuve)) {
            throw new BusinessException(
                    "epreuve doit etre l'une des quatre du TCF IRN : "
                            + "TCF_CO, TCF_CE, TCF_EE ou TCF_EO.");
        }
        List<ProgressionMesureDto> examens = mesuresEpreuve(userId, epreuve);
        return new ProgressionEpreuveDto(
                epreuve,
                echelleResolver.tcf(epreuve),
                resumeResolver.resumer(examens),
                niveauActuel(tcfProfileService.levelProfileAccueil(userId), epreuve),
                examens,
                new ProgressionCtaDto(ctaEpreuveVerrouille(userId, epreuve)));
    }

    /** {@code GET /api/me/progression/tcf}. */
    @Transactional(readOnly = true)
    public ProgressionTcfDto tcf(UUID userId, boolean tous) {
        TcfLevelProfile profil = tcfProfileService.levelProfileAccueil(userId);

        List<ProgressionTcfDto.EpreuveCarte> cartes = new ArrayList<>(EPREUVES.size());
        for (EpreuveType e : EPREUVES) {
            cartes.add(new ProgressionTcfDto.EpreuveCarte(
                    e, echelleResolver.tcf(e), resumeResolver.resumer(mesuresEpreuve(userId, e))));
        }

        List<ProgressionTcfDto.ExamenComplet> complets = examensComplets(userId);
        return new ProgressionTcfDto(
                profil.globalLevel(),
                profil.epreuvesCounted(),
                profil.partial(),
                resumeResolver.resumerExamensComplets(complets),
                cartes,
                tous ? complets : complets.stream().limit(DERNIERS_EXAMENS).toList(),
                // La grille des examens complets est ouverte sans abonnement
                // (docs/regles/freemium.md) : chaque épreuve de production y est
                // incluse tant que sa gratuité n'est pas consommée.
                new ProgressionCtaDto(false));
    }

    /**
     * Les examens blancs d'une épreuve, du plus récent au plus ancien, numérotés.
     * 🛑 Les sections de diagnostic complet sont retirées (D1) : elles sont
     * qualifiantes pour le niveau affiché, pas pour cet écran.
     */
    private List<ProgressionMesureDto> mesuresEpreuve(UUID userId, EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO, TCF_CE -> mesuresQcm(userId, epreuve);
            default -> mesuresProduction(userId, epreuve);
        };
    }

    private List<ProgressionMesureDto> mesuresQcm(UUID userId, EpreuveType epreuve) {
        List<Attempt> examens = attemptManager
                .findQcmEpreuvesPassees(userId, epreuve, LIMITE_EXAMENS).stream()
                .filter(a -> a.getTcfDiagnostic() == null)
                .toList();
        // 🛑 UNE requête pour tous les examens listés : le palier se dérive des
        // réponses, une boucle d'appels unitaires serait un N+1.
        Map<UUID, NiveauCecrl> niveaux = levelEstimator.niveauxQcm(
                examens.stream().map(Attempt::getId).toList());
        List<ProgressionMesureDto> out = new ArrayList<>(examens.size());
        for (int i = 0; i < examens.size(); i++) {
            Attempt a = examens.get(i);
            out.add(mesureTcf(a, ResumeExamensResolver.numero(i, examens.size()),
                    scoreProgression(a), TcfLevelEstimatorService.SCORE_PROGRESSION_MAX,
                    levelEstimator.capB2(niveaux.get(a.getId())), ProgressionRapport.QCM));
        }
        return out;
    }

    private List<ProgressionMesureDto> mesuresProduction(UUID userId, EpreuveType epreuve) {
        List<EpreuvesProductionQualifiantesResolver.EpreuveQualifiante> examens = qualifiantesResolver
                .qualifiantes(userId, epreuve, LIMITE_EXAMENS).stream()
                .filter(q -> q.attempt().getTcfDiagnostic() == null)
                .toList();
        List<ProgressionMesureDto> out = new ArrayList<>(examens.size());
        for (int i = 0; i < examens.size(); i++) {
            EpreuvesProductionQualifiantesResolver.EpreuveQualifiante q = examens.get(i);
            out.add(mesureTcf(q.attempt(), ResumeExamensResolver.numero(i, examens.size()),
                    q.note(), ProgressionEchelleResolver.NOTE_MAX,
                    levelEstimator.capB2(q.niveau()), ProgressionRapport.PRODUCTION));
        }
        return out;
    }

    private static ProgressionMesureDto mesureTcf(
            Attempt a, int numero, BigDecimal score, int max, NiveauCecrl niveau,
            ProgressionRapport rapportSeule) {
        boolean dansUnComplet = a.getParentAttempt() != null;
        ProgressionMesureDto.Rapport rapport = dansUnComplet
                ? new ProgressionMesureDto.Rapport(
                        ProgressionRapport.EXAMEN_COMPLET, a.getParentAttempt().getId())
                : new ProgressionMesureDto.Rapport(rapportSeule, a.getId());
        return new ProgressionMesureDto(
                a.getId(), numero, a.getFinishedAt(), score, max, niveau,
                null, null, null, null,
                ResumeExamensResolver.dureeFiable(a),
                dansUnComplet ? ProgressionProvenance.EXAMEN_COMPLET : ProgressionProvenance.EPREUVE_SEULE,
                rapport);
    }

    /**
     * Score de progression 100-499, chez son autorité. {@code null} sans score
     * pondéré : l'autorité rendrait sa borne basse, et l'écran afficherait
     * « 100 » là où on ne sait rien.
     */
    private BigDecimal scoreProgression(Attempt a) {
        if (a.getWeightedScore() == null || a.getMaxWeightedScore() == null) return null;
        return BigDecimal.valueOf(
                levelEstimator.calibratedScore(a.getWeightedScore(), a.getMaxWeightedScore()));
    }

    /**
     * Les examens complets <b>comptés</b> (D7) : terminés, et au moins une
     * épreuve réellement mesurée. Du plus récent au plus ancien, numérotés.
     * Le palier global est re-dérivé par le builder à la lecture (D19).
     */
    private List<ProgressionTcfDto.ExamenComplet> examensComplets(UUID userId) {
        List<Attempt> parents =
                attemptManager.findByUserAndEpreuve(userId, EpreuveType.TCF_COMPLET, LIMITE_EXAMENS);
        List<FullTcfExamResponse> comptes = fullExamBuilder.buildResponses(parents).stream()
                .filter(r -> r.finishedAt() != null && r.epreuvesCountedInFinalLevel() >= 1)
                .sorted(Comparator.comparing(FullTcfExamResponse::finishedAt).reversed())
                .toList();
        List<ProgressionTcfDto.ExamenComplet> out = new ArrayList<>(comptes.size());
        for (int i = 0; i < comptes.size(); i++) {
            FullTcfExamResponse r = comptes.get(i);
            out.add(new ProgressionTcfDto.ExamenComplet(
                    r.id(), ResumeExamensResolver.numero(i, comptes.size()), r.finishedAt(),
                    r.finalCecrlLevel(), r.finalLevelPartial(), r.epreuvesCountedInFinalLevel(),
                    r.continuite(), parEpreuve(r)));
        }
        return out;
    }

    private static List<ProgressionTcfDto.EpreuveLigne> parEpreuve(FullTcfExamResponse r) {
        Map<EpreuveType, FullTcfExamResponse.SubAttempt> parType = new HashMap<>();
        for (FullTcfExamResponse.SubAttempt s : r.subAttempts()) parType.put(s.epreuve(), s);
        List<ProgressionTcfDto.EpreuveLigne> out = new ArrayList<>(EPREUVES.size());
        for (EpreuveType e : EPREUVES) {
            boolean qcm = e == EpreuveType.TCF_CO || e == EpreuveType.TCF_CE;
            int max = qcm ? TcfLevelEstimatorService.SCORE_PROGRESSION_MAX : ProgressionEchelleResolver.NOTE_MAX;
            FullTcfExamResponse.SubAttempt s = parType.get(e);
            if (s == null) {
                out.add(new ProgressionTcfDto.EpreuveLigne(e, null, null, max, null, false));
                continue;
            }
            // 🛑 Pas de niveau ⇒ pas de score : une épreuve verrouillée, jamais
            // ouverte ou sans verdict vaut « — », jamais « 0 » ni « 100 ».
            BigDecimal score = null;
            if (s.cecrlLevel() != null) {
                score = qcm
                        ? (s.calibratedScore() == null ? null : BigDecimal.valueOf(s.calibratedScore()))
                        : s.noteSur20();
            }
            out.add(new ProgressionTcfDto.EpreuveLigne(
                    e, s.attemptId(), score, max, s.cecrlLevel(), s.locked()));
        }
        return out;
    }

    private static NiveauCecrl niveauActuel(TcfLevelProfile profil, EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO -> profil.co();
            case TCF_CE -> profil.ce();
            case TCF_EE -> profil.ee();
            case TCF_EO -> profil.eo();
            default -> null;
        };
    }

    /**
     * CO / CE : jamais — le créneau 1 est offert et rejouable à volonté
     * ({@code AttemptService.enforceMockExamSlotAccess}). EE / EO : la jumelle
     * en lecture du verrou d'examen de production.
     */
    private boolean ctaEpreuveVerrouille(UUID userId, EpreuveType epreuve) {
        return productionAccessService.isProductionExamLocked(userId, epreuve);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  CIVIQUE
    // ══════════════════════════════════════════════════════════════════════

    /** {@code GET /api/me/progression/civique}. */
    @Transactional(readOnly = true)
    public ProgressionCiviqueDto civique(UUID userId, boolean tous) {
        List<Theme> themes = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);

        List<Attempt> globaux = attemptManager.findCivicExamensGlobauxPasses(userId, LIMITE_EXAMENS);
        List<ProgressionMesureDto> mesuresGlobales = mesuresCiviques(
                globaux, CivicExamFormat.QUESTIONS, CivicExamFormat.SEUIL_REUSSITE,
                ProgressionProvenance.EXAMEN_GLOBAL);

        // Les examens de thème des cinq thèmes, en UNE requête, répartis ici.
        List<UUID> themeIds = themes.stream().map(Theme::getId).toList();
        Map<UUID, List<Attempt>> parTheme = new LinkedHashMap<>();
        for (Attempt a : attemptManager.findCivicExamensThemePasses(
                userId, themeIds, LIMITE_EXAMENS * Math.max(1, themes.size()))) {
            parTheme.computeIfAbsent(a.getLotThemeId(), k -> new ArrayList<>()).add(a);
        }
        List<ProgressionCiviqueDto.ThemeCarte> cartes = new ArrayList<>(themes.size());
        for (Theme t : themes) {
            List<Attempt> examens = parTheme.getOrDefault(t.getId(), List.of());
            cartes.add(new ProgressionCiviqueDto.ThemeCarte(
                    t.getId(), t.getCode(), t.getName(), echelleTheme(),
                    resumeResolver.resumer(mesuresCiviques(
                            examens.size() > LIMITE_EXAMENS ? examens.subList(0, LIMITE_EXAMENS) : examens,
                            CivicExamFormat.QUESTIONS_THEME, CivicExamFormat.SEUIL_REUSSITE_THEME,
                            ProgressionProvenance.EXAMEN_THEME))));
        }

        List<ProgressionMesureDto> affichees = tous
                ? mesuresGlobales
                : mesuresGlobales.stream().limit(DERNIERS_EXAMENS).toList();
        return new ProgressionCiviqueDto(
                echelleResolver.civique(CivicExamFormat.QUESTIONS, CivicExamFormat.SEUIL_REUSSITE),
                resumeResolver.resumer(mesuresGlobales),
                cartes,
                examensGlobaux(affichees, themes),
                new ProgressionCtaDto(attemptService.isGrilleCiviqueGlobaleVerrouillee(userId)));
    }

    /** {@code GET /api/me/progression/civique/themes/{themeId}}. */
    @Transactional(readOnly = true)
    public ProgressionThemeDto theme(UUID userId, UUID themeId) {
        Theme theme = themeManager.findById(themeId)
                .filter(t -> t.getModule() == Module.CIVIQUE)
                .orElseThrow(() -> new NotFoundException("Thème civique introuvable : " + themeId));
        List<ProgressionMesureDto> examens = mesuresCiviques(
                attemptManager.findCivicExamensThemePasses(userId, List.of(themeId), LIMITE_EXAMENS),
                CivicExamFormat.QUESTIONS_THEME, CivicExamFormat.SEUIL_REUSSITE_THEME,
                ProgressionProvenance.EXAMEN_THEME);
        ProgressionResumeDto resume = resumeResolver.resumer(examens);
        // 🛑 D13 : l'état de CET écran est celui du dernier examen du thème, et
        // la source est servie avec lui. L'Accueil garde le sien (diagnostic).
        CivicThemeState etat = resume.dernier() == null ? null : resume.dernier().etat();
        return new ProgressionThemeDto(
                theme.getId(), theme.getCode(), theme.getName(),
                echelleTheme(), resume, etat,
                ProgressionEtatSource.DERNIER_EXAMEN_THEME,
                ProgressionEtatSource.DERNIER_EXAMEN_THEME.getLabel(),
                examens,
                // Le créneau 1 de chaque thème est offert et rejouable
                // (2026-09-24, révoque D-33 sur ce point) : la grille ouverte par
                // ce bouton offre toujours au moins lui — comme CO / CE. Lu chez
                // l'autorité du verrou, jamais recalculé.
                new ProgressionCtaDto(attemptService.isExamenDeThemeVerrouille(userId, 1)));
    }

    private ProgressionEchelleDto echelleTheme() {
        return echelleResolver.civique(CivicExamFormat.QUESTIONS_THEME, CivicExamFormat.SEUIL_REUSSITE_THEME);
    }

    /**
     * Examens civiques (du plus récent au plus ancien) en mesures numérotées.
     * Le total et le seuil sont ceux <b>servis par l'attempt</b> ; le format
     * n'est qu'un repli pour une ligne qui ne les porterait pas.
     */
    private List<ProgressionMesureDto> mesuresCiviques(
            List<Attempt> examens, int totalParDefaut, int seuilParDefaut,
            ProgressionProvenance provenance) {
        List<ProgressionMesureDto> out = new ArrayList<>(examens.size());
        for (int i = 0; i < examens.size(); i++) {
            Attempt a = examens.get(i);
            int total = a.getTotalQuestions() != null ? a.getTotalQuestions() : totalParDefaut;
            int seuil = a.getPassThreshold() != null ? a.getPassThreshold() : seuilParDefaut;
            Integer bonnes = a.getScore();
            out.add(new ProgressionMesureDto(
                    a.getId(), ResumeExamensResolver.numero(i, examens.size()), a.getFinishedAt(),
                    bonnes == null ? null : BigDecimal.valueOf(bonnes), total,
                    null,
                    bonnes == null ? null : civicThemeResolver.etat(bonnes, total),
                    bonnes == null ? null : bonnes >= seuil,
                    bonnes == null ? null : Math.max(0, seuil - bonnes),
                    bonnes == null ? null : CivicDiagnosticThemeResolver.taux(bonnes, total),
                    ResumeExamensResolver.dureeFiable(a),
                    provenance,
                    new ProgressionMesureDto.Rapport(ProgressionRapport.QCM, a.getId())));
        }
        return out;
    }

    /**
     * Les examens globaux affichés et leur répartition par thème, en UNE
     * requête. 🛑 « x / n posées », jamais « / 20 » (D11) ; un thème absent de
     * l'examen vaut 0 / 0 — non posé, pas raté.
     */
    private List<ProgressionCiviqueDto.ExamenGlobal> examensGlobaux(
            List<ProgressionMesureDto> affichees, List<Theme> themes) {
        if (affichees.isEmpty()) return List.of();
        Map<UUID, Map<UUID, LignePartTheme>> parts = new HashMap<>();
        for (LignePartTheme l : attemptQuestionManager.partsParTheme(
                affichees.stream().map(ProgressionMesureDto::attemptId).toList())) {
            parts.computeIfAbsent(l.attemptId(), k -> new HashMap<>()).put(l.themeId(), l);
        }
        List<ProgressionCiviqueDto.ExamenGlobal> out = new ArrayList<>(affichees.size());
        for (ProgressionMesureDto m : affichees) {
            Map<UUID, LignePartTheme> duTheme = parts.getOrDefault(m.attemptId(), Map.of());
            List<ProgressionCiviqueDto.PartTheme> lignes = new ArrayList<>(themes.size());
            for (Theme t : themes) {
                LignePartTheme l = duTheme.get(t.getId());
                lignes.add(new ProgressionCiviqueDto.PartTheme(
                        t.getId(), t.getCode(), t.getName(),
                        l == null ? 0 : l.bonnes(), l == null ? 0 : l.posees()));
            }
            out.add(new ProgressionCiviqueDto.ExamenGlobal(m, lignes));
        }
        return out;
    }
}
