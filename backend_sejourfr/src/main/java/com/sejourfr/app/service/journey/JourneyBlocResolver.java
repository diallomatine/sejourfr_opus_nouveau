package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyCycleDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.dto.JourneyBlocRefDto;
import com.sejourfr.app.enums.JourneyBlocKind;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyBlocStatus;
import com.sejourfr.app.enums.JourneyStepType;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.function.Predicate;

/**
 * <b>Le cycle borne, LU par bloc</b> (arbitrage D-12).
 *
 * <h2>Un bloc est une lecture, pas une table</h2>
 * <p>Un <b>bloc</b> est une <b>epreuve</b> : ses etapes sont les
 * {@code journey_step} du cycle qui portent cet {@code exam_type}, son examen
 * est son etape {@code SECTION_EXAM}. 🛑 {@code journey_step.position} reste
 * <b>monotone et globale</b>, jamais renumerotee — « une renumerotation ferait
 * bouger un parcours que le candidat a sous les yeux » (V066). Le groupement ne
 * reecrit pas la file, il la regarde autrement.
 *
 * <h2>🛑 Rien n'est persiste, et rien n'est mesure ici</h2>
 * <p>Le statut d'un bloc, « bloc termine », « cycle termine » et « cycle de
 * mesure » se recalculent a chaque lecture (D-14). Ce composant ne fait aucune
 * requete : il recoit les etapes deja lues, la fonction de mapping du service de
 * lecture, et un predicat « cette epreuve a-t-elle deja ete mesuree ? » dont
 * l'unique autorite est {@code NiveauActuelEpreuveResolver}.
 *
 * <h2>Quatre blocs, toujours, dans l'ordre du TCF</h2>
 * <p>L'ordre est {@link TcfDomainProfileDto#ORDRE} — <b>CO, CE, EO, EE</b>,
 * autorite unique et <b>non configurable</b> (D-9, D-20). ⚠️ L'ordre des
 * maquettes est illustratif et ne fait pas regle. Un bloc sans etape est servi
 * quand meme : le cycle couvre les quatre epreuves, pas seulement celles que la
 * file a deja peuplees.
 */
@Component
public class JourneyBlocResolver {

    /** Les quatre blocs et l'avancement du cycle, lus d'un seul passage. */
    public record Vue(List<JourneyBlocDto> blocs, JourneyCycleDto cycle) {}

    /**
     * @param numeroDuCycle  rang du cycle : nombre de cycles historises + 1,
     *                       compte par le manager, jamais ici.
     * @param affichables    les etapes du cycle, <b>obsoletes deja exclues</b>,
     *                       dans l'ordre de la file.
     * @param courante       l'etape {@code CURRENT}, ou {@code null}.
     * @param dto            le mapping d'une etape vers son contrat servi.
     * @param jamaisMesuree  « cette epreuve n'a jamais ete mesuree » — relaye de
     *                       {@code NiveauActuelEpreuveResolver.mesure}. 🛑 Il
     *                       n'est interroge que pour les blocs qui peuvent etre
     *                       {@code A_EVALUER} : la question coute des requetes,
     *                       et un bloc qui porte du travail n'en a pas besoin.
     */
    public Vue lire(
            int numeroDuCycle,
            List<JourneyStep> affichables,
            JourneyStep courante,
            Function<JourneyStep, JourneyStepDto> dto,
            Predicate<EpreuveType> jamaisMesuree) {

        Map<EpreuveType, List<JourneyStep>> parEpreuve = new LinkedHashMap<>();
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            parEpreuve.put(epreuve, new ArrayList<>());
        }
        for (JourneyStep step : affichables) {
            List<JourneyStep> bloc = parEpreuve.get(step.getExamType());
            // Une etape DIAGNOSTIC ne porte pas d'epreuve : elle mesure le
            // candidat, pas une epreuve (R11). Elle compte dans l'avancement du
            // cycle, mais elle n'appartient a aucun bloc.
            if (bloc != null) bloc.add(step);
        }

        List<JourneyBlocDto> blocs = new ArrayList<>(TcfDomainProfileDto.ORDRE.size());
        parEpreuve.forEach((epreuve, etapes) ->
                blocs.add(bloc(epreuve, etapes, courante, dto, jamaisMesuree)));

        int terminees = (int) affichables.stream().filter(step -> !step.estOuverte()).count();
        boolean complete = affichables.stream().allMatch(step -> !step.estOuverte());
        return new Vue(List.copyOf(blocs), new JourneyCycleDto(
                numeroDuCycle, terminees, affichables.size(), complete,
                cycleDeMesure(affichables)));
    }

    /**
     * <b>Un cycle de mesure : des examens, et rien d'autre</b> (spec §6).
     *
     * <p>🛑 <b>DERIVE, pas une colonne</b> : un cycle dont <b>aucune</b> etape
     * n'est {@code TRAIN_SKILL} est un cycle de mesure. Le persister aurait
     * ajoute un drapeau que deux ecritures auraient pu contredire, alors que la
     * structure le dit deja.
     *
     * <p>⚠️ <b>Un examen au moins est exige</b>, et ce n'est pas une precaution
     * de style : un cycle <b>vide</b> (tout est fait, rien de nouveau) et un
     * cycle qui ne porte qu'un diagnostic (amorce C) n'ont pas de
     * {@code TRAIN_SKILL} non plus. Les appeler « cycles de mesure » leur
     * refuserait l'examen blanc complet en fin de cycle, alors qu'ils n'ont
     * justement mesure personne.
     *
     * @param affichables les etapes du cycle, <b>obsoletes exclues</b> : une
     *                    etape que la file a rendue caduque ne dit rien de la
     *                    nature du cycle.
     */
    public static boolean cycleDeMesure(List<JourneyStep> affichables) {
        boolean examen = false;
        for (JourneyStep step : affichables) {
            if (step.getType() == JourneyStepType.TRAIN_SKILL) return false;
            if (step.getType() == JourneyStepType.SECTION_EXAM) examen = true;
        }
        return examen;
    }

    /**
     * Le statut d'un bloc, dans l'ordre ou les questions se posent :
     * <ol>
     *   <li>il porte l'etape courante ⇒ {@code EN_COURS} ;</li>
     *   <li>il n'a aucune etape ⇒ {@code A_EVALUER} si son epreuve n'a jamais
     *       ete mesuree, sinon {@code TERMINE} — un bloc sans rien a faire sur
     *       une epreuve deja mesuree n'a plus rien a dire ;</li>
     *   <li>toutes ses etapes sont cloturees ⇒ {@code TERMINE} ;</li>
     *   <li>aucune competence <b>et</b> epreuve jamais mesuree ⇒
     *       {@code A_EVALUER} : il n'y a rien a travailler tant que la mesure
     *       n'a pas dit quoi ;</li>
     *   <li>sinon {@code A_VENIR}.</li>
     * </ol>
     */
    private static JourneyBlocDto bloc(
            EpreuveType epreuve,
            List<JourneyStep> etapes,
            JourneyStep courante,
            Function<JourneyStep, JourneyStepDto> dto,
            Predicate<EpreuveType> jamaisMesuree) {

        boolean porteLaMain = courante != null && etapes.stream()
                .anyMatch(step -> step.getId().equals(courante.getId()));
        int restantes = (int) etapes.stream()
                .filter(JourneyStep::estOuverte)
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .count();
        boolean sansCompetence = etapes.stream()
                .noneMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL);
        boolean toutesCloses = etapes.stream().allMatch(step -> !step.estOuverte());

        JourneyBlocStatus status;
        if (porteLaMain) {
            status = JourneyBlocStatus.EN_COURS;
        } else if (etapes.isEmpty()) {
            status = jamaisMesuree.test(epreuve)
                    ? JourneyBlocStatus.A_EVALUER
                    : JourneyBlocStatus.TERMINE;
        } else if (toutesCloses) {
            status = JourneyBlocStatus.TERMINE;
        } else if (sansCompetence && jamaisMesuree.test(epreuve)) {
            status = JourneyBlocStatus.A_EVALUER;
        } else {
            status = JourneyBlocStatus.A_VENIR;
        }

        List<JourneyStepDto> steps = etapes.stream()
                .filter(step -> step.getType() != JourneyStepType.SECTION_EXAM)
                .map(dto)
                .toList();
        JourneyStep examen = examenDuBloc(etapes);
        return new JourneyBlocDto(
                new JourneyBlocRefDto(
                        JourneyBlocKind.EPREUVE, epreuve.name(), epreuve.getLabel()),
                status, restantes, steps, examen == null ? null : dto.apply(examen));
    }

    /**
     * <b>L'examen du bloc</b> : le {@code SECTION_EXAM} <b>ouvert</b> s'il y en
     * a un, sinon le <b>dernier cloture</b>.
     *
     * <p>Deux examens du meme bloc coexistent legitimement — un « Évaluer mon
     * niveau » deja passe et le point d'etape d'un lot plus recent. L'ecran n'en
     * montre qu'un : celui qui reste a faire, ou, quand tout est fait, celui qui
     * a clos le bloc. Preferer le plus ancien ferait afficher un examen deja
     * passe alors qu'un autre attend.
     */
    private static JourneyStep examenDuBloc(List<JourneyStep> etapes) {
        JourneyStep dernierClos = null;
        for (JourneyStep step : etapes) {
            if (step.getType() != JourneyStepType.SECTION_EXAM) continue;
            if (step.estOuverte()) return step;
            dernierClos = step;
        }
        return dernierClos;
    }
}
