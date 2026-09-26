package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.JourneyManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * <b>Le cycle d'AFFINAGE</b> — l'autorite unique de « ce cycle est-il le premier
 * cycle issu du diagnostic rapide ? » (decision du proprietaire, 2026-09-27,
 * D-64 de {@code docs/decisions/plan-parcours-tcf.md}).
 *
 * <h2>La definition, lue sur des faits persistes</h2>
 * <p>Un cycle est d'affinage quand il est :
 * <ol>
 *   <li>un cycle <b>TCF</b> — le cycle civique n'a pas de lanceur d'examen
 *       depuis le cycle (A86), la regle ne s'y transpose pas ;</li>
 *   <li>le <b>premier</b> du candidat sur ce module : {@link JourneyCycleRank}
 *       vaut 1 (aucun cycle historise) ;</li>
 *   <li><b>amorce par le diagnostic RAPIDE</b> : au moins un de ses lots a pour
 *       source le {@code QUICK_DIAGNOSTIC} que ce cycle a journalise
 *       ({@code JourneyManager.amorceParLeDiagnosticRapide}).</li>
 * </ol>
 *
 * <p>🛑 <b>Pourquoi la 3e condition, et pas le rang seul.</b> Un premier cycle
 * amorce par un <b>examen</b> (amorce B) porte deja des priorites mesurees par
 * un examen : il n'a rien a affiner. Et son lot se termine par un examen
 * {@code REASSESS} de l'epreuve qu'on vient de passer — le rendre obligatoire
 * et prioritaire ferait repasser au candidat, tout de suite, l'examen qu'il
 * vient de finir.
 *
 * <h2>Ce que le cycle d'affinage change — et RIEN d'autre</h2>
 * <ul>
 *   <li>l'examen d'un bloc n'est <b>pas</b> verrouille par ses competences
 *       (D-15 ne s'applique pas) — le verrou d'ACCES, lui, est intact ;</li>
 *   <li>ses etapes {@code TRAIN_SKILL} sont <b>facultatives</b> : le cycle est
 *       termine (et s'actualise) quand ses etapes <b>obligatoires</b> — examens
 *       et diagnostic — sont closes ({@link #termine}) ;</li>
 *   <li>l'examen blanc est l'action <b>principale</b> : {@code CURRENT} se
 *       choisit d'abord parmi les examens executables.</li>
 * </ul>
 *
 * <p>🛑 <b>Derive, jamais persiste</b> : un drapeau sur {@code journey} aurait
 * pu contredire l'historique. Le rang est compte, le lot du diagnostic est lu.
 */
@Component
@RequiredArgsConstructor
public class JourneyCycleAffinage {

    private final JourneyManager journeyManager;

    /**
     * Ce cycle <b>EN COURS</b> est-il un cycle d'affinage ? Compte son rang.
     */
    public boolean pour(Journey journey) {
        if (journey.getModule() != Module.TCF) return false;
        int rang = JourneyCycleRank.rang(journeyManager.compterHistorises(
                journey.getUser().getId(), journey.getModule()));
        return pour(journey, rang);
    }

    /**
     * Meme question, le rang <b>deja compte</b> par l'appelant : la lecture du
     * parcours le sert deja, et le recompter coûterait une requete de plus.
     * La requete sur les lots n'est posee que sur un premier cycle TCF.
     */
    public boolean pour(Journey journey, int rang) {
        if (journey.getModule() != Module.TCF || rang != 1) return false;
        return journeyManager.amorceParLeDiagnosticRapide(journey.getId());
    }

    /**
     * Cette etape compte-t-elle pour la <b>fin</b> du cycle ? Toutes, hors
     * affinage ; les examens et le diagnostic seulement, en affinage.
     */
    public static boolean obligatoire(JourneyStep step, boolean affinage) {
        return !affinage || step.getType() != JourneyStepType.TRAIN_SKILL;
    }

    /**
     * <b>Le cycle est-il termine ?</b> — l'autorite unique, lue par la lecture
     * ({@code JourneyCycleDto.complete}, l'etat {@code CYCLE_COMPLETED}) et par
     * le refus serveur de l'actualisation ({@code JourneyCycleService}) : le
     * bouton servi et le 409 ne peuvent pas diverger.
     *
     * @param etapes les etapes du cycle, obsoletes exclues ou non (une etape
     *               {@code SUPERSEDED} est close, elle ne change rien ici)
     */
    public static boolean termine(List<JourneyStep> etapes, boolean affinage) {
        return etapes.stream()
                .filter(step -> obligatoire(step, affinage))
                .noneMatch(JourneyStep::estOuverte);
    }
}
