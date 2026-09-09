package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.dto.TcfDiagnosticProgressionDto;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService.Section;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * La comparaison de deux diagnostics (lot L7, 10_ §4.6 et 30_ §7).
 *
 * <p><b>Composant pur</b> : on lui donne deux jeux de sections deja recalcules,
 * il rend des sens de variation. Ni base, ni horloge — c'est ce qui permet de
 * le tester exactement aux cas qui font mal : l'epreuve non evaluee avant,
 * l'epreuve non evaluee apres, et le palier plancher.
 *
 * <p>🛑 <b>Une absence de mesure n'est jamais une stabilite.</b> C'est la seule
 * regle difficile de cette classe, et c'est l'incident V040/V041/V042 sous un
 * autre deguisement : un candidat qui n'avait pas passe l'expression orale au
 * premier diagnostic verrait « = » — la lecture naturelle etant « vous avez
 * tenu votre niveau », alors que personne n'a rien mesure.
 */
@Component
@RequiredArgsConstructor
public class TcfDiagnosticProgressionResolver {

    private final TcfDiagnosticLevelResolver levelResolver;

    /**
     * Compare {@code apres} a {@code avant}.
     *
     * <p>L'ordre des epreuves est celui de {@code apres} : c'est le diagnostic
     * qu'on affiche. Une epreuve absente de {@code avant} rend
     * {@link NiveauEvolution#INCONNUE}.
     */
    public TcfDiagnosticProgressionDto comparer(
            UUID previousSessionId,
            Instant previousCompletedAt,
            List<Section> avant,
            List<Section> apres) {

        Map<com.sejourfr.app.enums.EpreuveType, NiveauCecrl> niveauxAvant =
                new EnumMap<>(com.sejourfr.app.enums.EpreuveType.class);
        avant.forEach(s -> niveauxAvant.put(s.epreuve(), s.niveau()));

        List<TcfDiagnosticProgressionDto.EpreuveEvolution> epreuves = apres.stream()
                .map(s -> {
                    NiveauCecrl a = niveauxAvant.get(s.epreuve());
                    return new TcfDiagnosticProgressionDto.EpreuveEvolution(
                            s.epreuve(), a, s.niveau(), evolution(a, s.niveau()));
                })
                .toList();

        NiveauCecrl globalAvant = plancher(avant);
        NiveauCecrl globalApres = plancher(apres);

        return new TcfDiagnosticProgressionDto(
                previousSessionId,
                previousCompletedAt,
                globalAvant,
                evolution(globalAvant, globalApres),
                epreuves);
    }

    /**
     * Le sens d'une variation. {@code null} d'un cote ou de l'autre &rArr;
     * {@link NiveauEvolution#INCONNUE}, jamais {@code STABLE}.
     */
    public static NiveauEvolution evolution(NiveauCecrl avant, NiveauCecrl apres) {
        if (avant == null || apres == null) {
            return NiveauEvolution.INCONNUE;
        }
        int delta = TcfDiagnosticLevelResolver.rang(apres) - TcfDiagnosticLevelResolver.rang(avant);
        if (delta > 0) return NiveauEvolution.HAUSSE;
        if (delta < 0) return NiveauEvolution.BAISSE;
        return NiveauEvolution.STABLE;
    }

    /**
     * Le palier global d'un jeu de sections.
     *
     * <p>🛑 <b>La regle du plancher n'est pas recopiee ici</b> : elle est
     * demandee a {@link TcfDiagnosticLevelResolver}, la meme autorite que
     * {@code TcfDiagnosticReadService.niveauGlobal}. Une seconde copie aurait
     * fini par comparer un diagnostic a un palier que son propre ecran de
     * resultat n'affichait pas.
     */
    private NiveauCecrl plancher(List<Section> sections) {
        return levelResolver
                .niveauGlobal(sections.stream().map(Section::niveau).toList())
                .orElse(null);
    }
}
