package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.JourneyStatus;
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
        return journeyManager.find(userId, courant.getModule(), JourneyStatus.EN_ATTENTE)
                .map(attente -> stepManager.compterEntrainementsOuverts(attente.getId()))
                .orElse(0);
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
