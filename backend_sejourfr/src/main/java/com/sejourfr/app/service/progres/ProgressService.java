package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticProgressionResolver;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>« Où vous en êtes »</b> de l'Accueil ({@code GET /api/me/progress}).
 *
 * <p>🛑 <b>Élagué le 2026-09-24</b> : l'ancien écran « Votre progression »
 * ({@code /statistiques} ⇄ {@code ProgresScreen}), qui lisait aussi ce service
 * (activité, courbe des diagnostics, palier global, compteurs de compétences et
 * civiques), est remplacé par les écrans de {@code /api/me/progression/*}
 * ({@link ProgressionExamensService}). Il ne reste ici que ce que l'Accueil lit.
 *
 * <h2>Ce que ce service ne fait pas, et pourquoi</h2>
 *
 * <p>🛑 <b>Il ne calcule aucun niveau.</b> Le niveau TCF actuel vient de
 * {@link TcfProfileService} dans sa lecture d'<b>Accueil</b>
 * ({@link TcfProfileService#levelProfileAccueil}) — et l'objectif de
 * {@link TcfDiagnosticService#cible(User)}, seule autorité de la table
 * démarche → palier. Le sens d'une évolution vient de
 * {@link TcfDiagnosticProgressionResolver#evolution}. Le statut d'une épreuve
 * <b>face à l'objectif</b> vient de {@link StatutObjectifResolver}. Le détail
 * civique par thème vient du moteur du plan civique. Ce service <b>assemble</b>,
 * il ne mesure pas.
 *
 * <p>🛑 <b>Il n'invente aucun parcours de mesure.</b> « Par quoi mesurer une
 * épreuve jamais évaluée » vient de {@link PlanDomainAssessmentResolver#pour}.
 *
 * <p>🛑 <b>Aucun appel LLM</b> : tout est relu.
 */
@Service
@RequiredArgsConstructor
public class ProgressService {

    /** 🛑 Les quatre épreuves du TCF IRN. {@code TCF_STRUCTURE} n'en est pas une. */
    private static final List<EpreuveType> EPREUVES = List.of(
            EpreuveType.TCF_CO, EpreuveType.TCF_CE,
            EpreuveType.TCF_EE, EpreuveType.TCF_EO);

    private final UserManager userManager;
    private final TcfDiagnosticSessionManager tcfSessionManager;
    private final TcfDiagnosticReadService tcfReadService;
    private final TcfDiagnosticService tcfDiagnosticService;
    private final TcfProfileService tcfProfileService;
    private final CivicDiagnosticSessionManager civicSessionManager;
    private final CivicDiagnosticViewService civicViewService;
    private final CivicPlanService civicPlanService;
    private final StatutObjectifResolver statutObjectifResolver;
    private final PlanDomainAssessmentResolver assessmentResolver;

    @Transactional(readOnly = true)
    public ProgressDto progres(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        return new ProgressDto(tcf(user), civique(userId));
    }

    private ProgressDto.Tcf tcf(User user) {
        NiveauCecrl objectif = tcfDiagnosticService.cible(user).orElse(null);

        // Le palier INITIAL d'une épreuve est celui du PREMIER diagnostic clos :
        // c'est lui, et lui seul, qui donne un sens à l'évolution. Sans
        // diagnostic clos, `niveauInitial` reste null et l'évolution INCONNUE.
        TcfDiagnosticSession premier = tcfSessionManager.findAllByUser(user.getId()).stream()
                .filter(s -> s.getStatus() == TcfDiagnosticStatus.COMPLETED)
                .min(Comparator.comparing(
                        TcfDiagnosticSession::getCompletedAt,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .orElse(null);
        Map<EpreuveType, NiveauCecrl> auPremier = new LinkedHashMap<>();
        if (premier != null) {
            for (TcfDiagnosticReadService.Section section : tcfReadService.sections(premier)) {
                auPremier.put(section.epreuve(), section.niveau());
            }
        }

        // 🛑 Le palier ACTUEL d'une épreuve ne vient PAS du diagnostic : il vient
        // de la lecture d'Accueil du profil TCF (moyenne des 3 derniers examens
        // qualifiants). Les 4 épreuves sont toujours servies.
        TcfLevelProfile profil = tcfProfileService.levelProfileAccueil(user.getId());
        List<ProgressDto.Epreuve> epreuves = new ArrayList<>(EPREUVES.size());
        for (EpreuveType epreuve : EPREUVES) {
            NiveauCecrl actuel = actuel(profil, epreuve);
            NiveauCecrl initial = auPremier.get(epreuve);
            epreuves.add(new ProgressDto.Epreuve(
                    epreuve, actuel, initial,
                    TcfDiagnosticProgressionResolver.evolution(initial, actuel),
                    statutObjectifResolver.resoudre(actuel, objectif),
                    // « Par quoi mesurer » n'a de sens que tant qu'aucun palier
                    // n'existe : au-delà, il n'y a plus rien à lancer.
                    actuel == null
                            ? assessmentResolver.pour(epreuve)
                            : null));
        }
        return new ProgressDto.Tcf(objectif, epreuves);
    }

    private static NiveauCecrl actuel(TcfLevelProfile profil, EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO -> profil.co();
            case TCF_CE -> profil.ce();
            case TCF_EE -> profil.ee();
            case TCF_EO -> profil.eo();
            default -> null;
        };
    }

    private ProgressDto.Civique civique(UUID userId) {
        List<CivicDiagnosticSession> clos =
                civicSessionManager.findAllByUser(userId).stream()
                        .filter(s -> s.getStatus() == TcfDiagnosticStatus.COMPLETED)
                        .sorted(Comparator.comparing(
                                CivicDiagnosticSession::getCompletedAt,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                        .toList();
        if (clos.isEmpty()) {
            return new ProgressDto.Civique(List.of(), List.of());
        }
        List<ProgressDto.Score> historique = clos.stream()
                .map(civicViewService::resultat)
                .map(r -> new ProgressDto.Score(
                        r.sessionId(), r.bonnes(), r.posees(),
                        r.seuilReussite(), r.formatQuestions(), r.completedAt()))
                .toList();
        return new ProgressDto.Civique(historique, civicPlanService.themesAccueil(userId));
    }
}
