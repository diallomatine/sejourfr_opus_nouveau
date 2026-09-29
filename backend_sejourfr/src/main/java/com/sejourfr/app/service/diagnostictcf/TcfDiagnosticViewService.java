package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.dto.TcfDiagnosticDto;
import com.sejourfr.app.dto.TcfDiagnosticProgressionDto;
import com.sejourfr.app.dto.TcfDiagnosticPriorityDto;
import com.sejourfr.app.dto.TcfDiagnosticResultDto;
import com.sejourfr.app.dto.TcfDiagnosticSectionDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
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
    private final TcfDiagnosticSessionManager sessionManager;
    private final TcfDiagnosticProgressionResolver progressionResolver;

    /**
     * L'ecran d'accueil : les 4 sections, leur etat <b>et leur resultat</b>.
     *
     * <p>⚠️ <b>Le niveau y transite depuis le 2026-09-13</b> — cf.
     * {@link TcfDiagnosticSectionDto}. Ce qui n'y transite toujours pas : le
     * niveau GLOBAL, les priorites et le plan, qui restent l'affaire de
     * {@link #resultat}.
     *
     * <p>🛑 <b>{@code sectionsMesurees}, pas {@code sections}</b> (2026-09-16) :
     * une epreuve deja mesuree par un examen blanc isole ou par un examen TCF
     * complet est une section <b>faite</b>. Le candidat ne doit pas se voir
     * redemander une epreuve que le produit sait mesuree.
     */
    @Transactional(readOnly = true)
    public TcfDiagnosticDto vue(TcfDiagnosticSession session) {
        List<Section> sections = readService.sectionsMesurees(session);
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
                                        .map(Attempt::getTotalQuestions).orElse(null),
                        s.niveau(),
                        s.scoreCalibre(),
                        s.analyseEnCours(),
                        s.rapportAttemptId()))
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
     *
     * <p>🛑 <b>{@code sectionsMesurees}</b> (2026-09-16) : une epreuve mesuree
     * ailleurs rend son niveau <b>et ses priorites</b>, comme si elle avait ete
     * jouee ici. C'est ce qui permet a un diagnostic de se clore et de rendre
     * son resultat quand les 4 epreuves sont mesurees, meme si certaines ne
     * l'ont pas ete dans la session.
     *
     * <p>⚠️ <b>La progression, elle, compare des sections PROPRES</b> — cf.
     * {@link #progression}.
     */
    @Transactional(readOnly = true)
    public TcfDiagnosticResultDto resultat(TcfDiagnosticSession session, NiveauCecrl cible) {
        List<Section> sections = readService.sectionsMesurees(session);

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
                session.getCompletedAt(),
                progression(session),
                tachesSousLaCible(session, sections, cible));
    }

    /**
     * Combien de taches d'expression <b>mesurees</b> restent sous la cible.
     *
     * <p>🛑 <b>Non plafonne</b>, contrairement aux priorites : c'est le compte
     * reel, celui que l'ecran annonce (« 4 competences ciblees detectees »).
     * Le lire sur la liste des priorites, bornee a trois, afficherait « 3 »
     * quel que soit le nombre veritable.
     *
     * <p>🛑 <b>Une tache non mesuree ne compte pas.</b> Elle n'est pas « en
     * dessous de la cible » : elle est inconnue, et {@code null} n'est jamais
     * un verdict.
     *
     * <p>Sans cible connue (demarche non declaree), le compte est nul : « sous
     * la cible » n'a alors aucun sens.
     */
    private int tachesSousLaCible(
            TcfDiagnosticSession session, List<Section> sections, NiveauCecrl cible) {
        if (cible == null) {
            return 0;
        }
        return (int) readService.tachesMesurees(session, sections).stream()
                .filter(t -> t.niveauTache() != null)
                .filter(t -> TcfDiagnosticLevelResolver.ecart(t.niveauTache(), cible) > 0)
                .count();
    }

    /**
     * La comparaison au diagnostic clos precedent (L7, 10_ §4.6).
     *
     * <p>🛑 <b>{@code null} est le cas normal</b> : c'est le premier
     * diagnostic. On ne fabrique pas un bloc « +0 » pour remplir l'ecran.
     *
     * <p>Les sections du diagnostic precedent sont <b>recalculees</b>, pas
     * relues d'un cache : c'est ce qui permet a un recalibrage de se refleter
     * des deux cotes de la comparaison au lieu d'opposer une mesure ancienne a
     * une mesure neuve.
     *
     * <p>🛑 <b>Les DEUX cotes sont des sections PROPRES</b>
     * ({@code readService.sections}), jamais {@code sectionsMesurees}
     * (2026-09-16). Comparer deux jeux enrichis reviendrait a comparer le niveau
     * d'aujourd'hui a lui-meme : toute epreuve non jouee dans l'un ou l'autre
     * diagnostic sortirait {@code STABLE} — « vous avez tenu votre niveau »,
     * alors que ces deux diagnostics-la n'ont rien mesure. C'est l'incident
     * V040/V041/V042 sous un autre deguisement, et c'est pour ca que cette
     * methode recalcule le cote « apres » au lieu de recevoir celui du resultat.
     */
    private TcfDiagnosticProgressionDto progression(TcfDiagnosticSession session) {
        if (session.getUser() == null) {
            return null;
        }
        return sessionManager
                .findPreviousCompleted(session.getUser().getId(), session)
                .map(precedent -> progressionResolver.comparer(
                        precedent.getId(),
                        precedent.getCompletedAt(),
                        readService.sections(precedent),
                        readService.sections(session)))
                .orElse(null);
    }
}
