package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.CivicNotionManager;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * <b>La composition du CYCLE SUIVANT</b> — combien de priorites il portera, et
 * lesquelles (2026-09-27, D-67, decision du proprietaire).
 *
 * <h2>🛑 La regle : au plus {@code maxPrioritiesPerLot} par epreuve / thematique</h2>
 * <p>Le moteur continue de calculer <b>toutes</b> les priorites vraies — le
 * Plan les sert entieres ({@code plan.domaines}, « Débloquer mon plan »). Le
 * cycle suivant, lui, en <b>retient</b> au plus trois par epreuve (TCF : CO, CE,
 * EE, EO) et au plus trois par thematique (civique), les plus urgentes dans
 * l'ordre du moteur. C'est un choix <b>pedagogique</b> : un cycle est borne, et
 * sa charge doit rester tenable.
 *
 * <p>⚠️ <b>Ce n'est pas un plafond d'affichage recycle en budget</b> (l'invariant
 * racine « un plafond d'AFFICHAGE n'est jamais un budget PEDAGOGIQUE ») : le
 * calcul reste complet, et le plafond est une regle de <b>composition du
 * cycle</b>, par epreuve — aucune epreuve n'est privee au profit d'une autre,
 * contrairement a l'incident du 2026-08-25.
 *
 * <h2>Ou la regle s'applique</h2>
 * <ul>
 *   <li><b>TCF</b> : le cycle en attente recoit, par epreuve, le lot de la
 *       derniere evaluation — au plus trois priorites
 *       ({@code JourneyLotBuilder}, {@code PAR_GRAVITE}) —, et un seul lot
 *       ouvert par epreuve ({@code uq_journey_lot_open_par_epreuve}, un lot plus
 *       recent remplace le precedent). Le nombre servi est donc celui des etapes
 *       d'entrainement ouvertes du cycle en attente ;</li>
 *   <li><b>civique</b> : il n'y a pas de cycle en attente (D-36, les priorites
 *       sont derivees) ; l'amorce du cycle suivant lit l'ordre du plan derive
 *       ({@code CivicPlanService.ordrePourLeCycleSuivant} : le diagnostic, sinon
 *       les examens blancs, A177) et retient au plus trois unites officielles
 *       par thematique
 *       ({@link #unitesRetenues}, <b>la meme fonction</b> que l'amorce). Le
 *       nombre servi est donc celui que l'actualisation poserait maintenant.</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class JourneyCycleSuivant {

    private final JourneyManager journeyManager;
    private final JourneyStepManager stepManager;
    private final CivicPlanService civicPlanService;
    private final CivicNotionManager notionManager;
    private final ThemeManager themeManager;
    private final TcfJourneyConfig config;
    // 🛑 La MEME lecture que l'actualisation (D-72, D-70) : le nombre annonce est
    // ce qui sera pose, ni plus ni moins.
    private final JourneyPalierDuCycle palierDuCycle;

    /** Une thematique et les unites officielles que le cycle y retient, dans l'ordre. */
    public record ThematiqueRetenue(Theme thematique, List<CivicOfficialUnit> unites) {}

    /**
     * <b>Combien de priorites le cycle suivant portera</b> — servi sous
     * « Actualiser mon plan » ({@code JourneyCycleDto.prioritesCycleSuivant}).
     */
    public int prioritesIdentifiees(Journey courant) {
        UUID userId = courant.getUser().getId();
        if (courant.getModule() == Module.CIVIQUE) {
            return unitesRetenues(civicPlanService.ordrePourLeCycleSuivant(userId)).stream()
                    .mapToInt(retenue -> retenue.unites().size())
                    .sum();
        }
        return entrainementsTcf(courant);
    }

    /**
     * <b>TCF — les etapes d'entrainement que l'actualisation POSERA</b>, epreuve
     * par epreuve, avec les MEMES fonctions qu'elle :
     * <ol>
     *   <li>les entrainements ouverts du cycle en attente que le palier du cycle
     *       garde (D-72 : tout hors CO/CE ; en CO/CE, le seul palier a acquerir —
     *       {@code JourneyService.retenirLePalierDuCycle}) ;</li>
     *   <li>s'il n'en reste aucun en CO/CE, le bloc sera vide et D-70 le
     *       completera ({@code JourneyService.completerLesBlocsVides}) : on compte
     *       ce complement.</li>
     * </ol>
     * Avant D-72, le complement D-70 n'etait pas compte : un cycle d'examens fini
     * a A1 en CO annoncait N priorites et en posait N + 3.
     */
    private int entrainementsTcf(Journey courant) {
        UUID userId = courant.getUser().getId();
        List<JourneyStep> attente = journeyManager
                .find(userId, courant.getModule(), JourneyStatus.EN_ATTENTE)
                .map(cycle -> stepManager.findAll(cycle.getId()))
                .orElse(List.of());
        JourneyPalierDuCycle.Lecture lecture = palierDuCycle.lire(userId, courant.getTargetLevel());
        int total = 0;
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            long gardees = attente.stream()
                    .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                    .filter(JourneyStep::estOuverte)
                    .filter(step -> step.getExamType() == epreuve)
                    .filter(lecture::garde)
                    .count();
            if (gardees > 0) {
                total += (int) gardees;
            } else if (lecture.palier(epreuve) != null
                    && !porteUneEtapeGardee(attente, epreuve)) {
                total += palierDuCycle.complement(lecture, epreuve).entrainements();
            }
        }
        return total;
    }

    /**
     * Le bloc garde-t-il une etape apres la relecture du palier ? Seules les
     * etapes CLOSES (hors {@code SUPERSEDED}) d'un lot qui reste ouvert le
     * peuvent encore — un cycle en attente n'en porte normalement aucune.
     */
    private static boolean porteUneEtapeGardee(
            List<JourneyStep> attente, EpreuveType epreuve) {
        return attente.stream()
                .filter(step -> step.getExamType() == epreuve)
                .filter(step -> step.getResolution() != JourneyStepResolution.SUPERSEDED)
                .anyMatch(step -> !step.estOuverte());
    }

    /**
     * <b>Les unites qu'un cycle civique retient</b>, groupees par thematique,
     * dans l'ordre du plan derive — au plus {@code maxPrioritiesPerLot} par
     * thematique (D-20, D-67).
     *
     * <p>🛑 <b>Le grain est l'UNITE OFFICIELLE</b> (D-48) : une cible du plan
     * derive est une <b>notion</b>, et plusieurs notions tombent dans la meme
     * unite. On garde alors le <b>meilleur rang</b> — la premiere rencontree,
     * puisque la liste arrive deja ordonnee. Une cible au grain THEME ne devient
     * pas une priorite : elle ne nomme aucune unite (null = inconnu).
     *
     * <p>🛑 <b>Une seule autorite, deux lecteurs</b> : l'amorce du cycle
     * ({@code JourneyService.creerLotsCiviques}) et le nombre servi
     * ({@link #prioritesIdentifiees}). Le nombre annonce ne peut pas dire autre
     * chose que ce que l'actualisation posera.
     */
    public List<ThematiqueRetenue> unitesRetenues(CivicPlanService.OrdreDuPlan ordre) {
        if (ordre.estVide()) return List.of();

        Map<UUID, CivicOfficialUnit> unitesParNotion = notionManager.findAllOrdonnees().stream()
                .filter(notion -> notion.getOfficialUnit() != null)
                .collect(Collectors.toMap(
                        CivicNotion::getId, CivicNotion::getOfficialUnit, (a, b) -> a));

        // LinkedHashMap : l'ordre des thematiques est celui de la premiere
        // priorite rencontree -- donc l'ordre du plan derive, pas un tri de plus.
        Map<UUID, List<CivicOfficialUnit>> parThematique = new LinkedHashMap<>();
        Map<UUID, Theme> thematiques = new LinkedHashMap<>();
        Set<UUID> dejaPrises = new LinkedHashSet<>();
        for (CivicPlanDto.Cible cible : ordre.cibles()) {
            CivicOfficialUnit unite = unitesParNotion.get(cible.id());
            if (unite == null) continue;
            if (!dejaPrises.add(unite.getId())) continue;
            Theme thematique = thematiques.computeIfAbsent(cible.themeId(),
                    id -> themeManager.findById(id).orElse(null));
            if (thematique == null) {
                thematiques.remove(cible.themeId());
                continue;
            }
            List<CivicOfficialUnit> unites = parThematique
                    .computeIfAbsent(thematique.getId(), cle -> new ArrayList<>());
            // 🛑 D-67 — au plus trois par thematique, la MEME borne que cote TCF :
            // une seconde valeur ferait deux regles la ou il n'y en a qu'une.
            if (unites.size() >= config.maxPrioritiesPerLot()) continue;
            unites.add(unite);
        }

        List<ThematiqueRetenue> retenues = new ArrayList<>();
        parThematique.forEach((themeId, unites) -> {
            if (!unites.isEmpty()) {
                retenues.add(new ThematiqueRetenue(thematiques.get(themeId), List.copyOf(unites)));
            }
        });
        return List.copyOf(retenues);
    }
}
