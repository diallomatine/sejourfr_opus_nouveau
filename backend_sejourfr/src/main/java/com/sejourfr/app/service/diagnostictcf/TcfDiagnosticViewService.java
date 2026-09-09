package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.dto.TcfDiagnosticDto;
import com.sejourfr.app.dto.TcfDiagnosticPriorityDto;
import com.sejourfr.app.dto.TcfDiagnosticResultDto;
import com.sejourfr.app.dto.TcfDiagnosticSectionDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService.Section;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Les vues du diagnostic TCF servies aux fronts.
 *
 * <p>Separe de {@link TcfDiagnosticService}, qui orchestre le parcours : ici on
 * ne fait qu'assembler ce que {@link TcfDiagnosticReadService} a recalcule.
 */
@Service
@RequiredArgsConstructor
public class TcfDiagnosticViewService {

    private final TcfDiagnosticReadService readService;
    private final TcfDiagnosticPriorityResolver priorityResolver;
    private final AttemptManager attemptManager;

    /**
     * L'ecran d'accueil : les 4 sections et leur etat.
     *
     * <p>🛑 <b>Aucun niveau n'y transite</b> : 10_ §4.2 interdit tout resultat
     * partiel entre les sections.
     */
    @Transactional(readOnly = true)
    public TcfDiagnosticDto vue(TcfDiagnosticSession session) {
        List<Section> sections = readService.sections(session);
        Map<java.util.UUID, Attempt> parId =
                attemptManager.findSubAttempts(session.getParentAttempt().getId()).stream()
                        .collect(Collectors.toMap(Attempt::getId, Function.identity(), (a, b) -> a));

        List<TcfDiagnosticSectionDto> dto = sections.stream()
                .map(s -> new TcfDiagnosticSectionDto(
                        s.epreuve(),
                        s.attemptId(),
                        s.etat(),
                        s.timeLimitSeconds(),
                        s.attemptId() == null ? null
                                : Optional.ofNullable(parId.get(s.attemptId()))
                                        .map(Attempt::getTotalQuestions).orElse(null)))
                .toList();

        return new TcfDiagnosticDto(
                session.getId(),
                session.getStatus(),
                session.getStartedAt(),
                session.getExpiresAt(),
                session.getCompletedAt(),
                session.repriseEcoulee(Instant.now()),
                dto);
    }

    /**
     * L'ecran de resultat (10_ §4.5).
     *
     * <p>🛑 Une epreuve <b>non evaluee</b> figure dans {@code epreuves} avec un
     * niveau nul, et n'entre ni dans le plancher global ni dans « deja au
     * niveau ». Elle doit etre nommee a l'ecran, pas escamotee.
     */
    @Transactional(readOnly = true)
    public TcfDiagnosticResultDto resultat(TcfDiagnosticSession session, NiveauCecrl cible) {
        List<Section> sections = readService.sections(session);

        List<TcfDiagnosticResultDto.EpreuveNiveau> epreuves = sections.stream()
                .map(s -> new TcfDiagnosticResultDto.EpreuveNiveau(s.epreuve(), s.niveau()))
                .toList();

        List<TcfDiagnosticPriorityDto> priorites = priorityResolver
                .priorites(readService.tachesMesurees(session, sections), cible)
                .stream()
                .map(p -> new TcfDiagnosticPriorityDto(
                        p.rang(), p.epreuve(), p.taskCode(),
                        p.niveauTache(), p.niveauEpreuve()))
                .toList();

        // « Deja au niveau attendu » : mesurees ET a la cible ou au-dessus.
        List<TcfDiagnosticResultDto.EpreuveNiveau> dejaAuNiveau = epreuves.stream()
                .filter(e -> e.niveau() != null
                        && TcfDiagnosticLevelResolver.ecart(e.niveau(), cible) == 0)
                .toList();

        return new TcfDiagnosticResultDto(
                session.getId(),
                readService.niveauGlobal(sections).orElse(null),
                cible,
                epreuves,
                priorites,
                dejaAuNiveau,
                session.getCompletedAt());
    }
}
