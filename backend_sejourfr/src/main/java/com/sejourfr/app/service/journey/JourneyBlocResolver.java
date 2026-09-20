package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyBlocDto;
import com.sejourfr.app.dto.JourneyCycleDto;
import com.sejourfr.app.dto.JourneyStepDto;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.dto.JourneyBlocRefDto;
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
 * <h2>🛑 L'AXE EST RECU, IL N'EST PLUS UN ENUM</h2>
 * <p>Ce composant recevait {@code TcfDomainProfileDto.ORDRE} en dur — quatre
 * epreuves. L'axe d'un cycle civique est <b>les cinq thematiques</b>, qui sont
 * une <b>donnee</b> de {@code themes} et non des valeurs d'enum : il se lit dans
 * l'ordre de {@code display_order}. L'appelant fournit donc l'axe, deja ordonne,
 * sous la forme de {@link JourneyBlocRefDto} — le <b>bloc servi</b> (D-47).
 *
 * <p>🛑 {@code TcfDomainProfileDto.ORDRE} reste l'autorite <b>TCF</b> — CO, CE,
 * EO, EE, non configurable (D-9, D-20). On ne la touche pas : on lui ajoute un
 * axe a cote, et c'est {@code JourneyReadService} qui choisit selon le module.
 * ⚠️ L'ordre des maquettes est illustratif et ne fait pas regle.
 *
 * <p>Un bloc <b>sans etape est servi quand meme</b> : le cycle couvre tout son
 * axe, pas seulement ce que la file a deja peuple.
 */
@Component
public class JourneyBlocResolver {

    /** Les quatre blocs et l'avancement du cycle, lus d'un seul passage. */
    public record Vue(List<JourneyBlocDto> blocs, JourneyCycleDto cycle) {}

    /**
     * @param numeroDuCycle  rang du cycle : nombre de cycles historises + 1,
     *                       compte par le manager, jamais ici.
     * @param axe            les blocs du module, <b>deja ordonnes</b> : les
     *                       quatre epreuves cote TCF, les cinq thematiques cote
     *                       civique. 🛑 Ce composant ne le fabrique pas et ne le
     *                       trie pas — il ne saurait pas de quel module il
     *                       parle, et c'est exactement le but.
     * @param affichables    les etapes du cycle, <b>obsoletes deja exclues</b>,
     *                       dans l'ordre de la file.
     * @param courante       l'etape {@code CURRENT}, ou {@code null}.
     * @param dto            le mapping d'une etape vers son contrat servi.
     * @param jamaisMesure   « ce bloc n'a jamais ete mesure » — cote TCF,
     *                       relaye de {@code NiveauActuelEpreuveResolver.mesure},
     *                       son <b>unique autorite</b>. 🛑 Il n'est interroge que
     *                       pour les blocs qui peuvent etre {@code A_EVALUER} :
     *                       la question coute des requetes, et un bloc qui porte
     *                       du travail n'en a pas besoin.
     */
    public Vue lire(
            int numeroDuCycle,
            List<JourneyBlocRefDto> axe,
            List<JourneyStep> affichables,
            JourneyStep courante,
            Function<JourneyStep, JourneyStepDto> dto,
            Predicate<JourneyBlocRefDto> jamaisMesure) {

        Map<String, List<JourneyStep>> parBloc = new LinkedHashMap<>();
        for (JourneyBlocRefDto ref : axe) {
            parBloc.put(ref.code(), new ArrayList<>());
        }
        for (JourneyStep step : affichables) {
            // 🛑 `blocCode()` lit l'axe A LA SOURCE (D-47) : l'epreuve cote TCF,
            // la thematique cote civique, et ce code ne sait pas lequel.
            List<JourneyStep> bloc = parBloc.get(step.blocCode());
            // Une etape DIAGNOSTIC n'appartient a aucun bloc : elle mesure le
            // candidat, pas une epreuve ni une thematique (R11, A45). Elle
            // compte dans l'avancement du cycle, et nulle part ailleurs.
            if (bloc != null) bloc.add(step);
        }

        List<JourneyBlocDto> blocs = new ArrayList<>(axe.size());
        for (JourneyBlocRefDto ref : axe) {
            blocs.add(bloc(ref, parBloc.get(ref.code()), courante, dto, jamaisMesure));
        }

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
            JourneyBlocRefDto ref,
            List<JourneyStep> etapes,
            JourneyStep courante,
            Function<JourneyStep, JourneyStepDto> dto,
            Predicate<JourneyBlocRefDto> jamaisMesure) {

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
            status = jamaisMesure.test(ref)
                    ? JourneyBlocStatus.A_EVALUER
                    : JourneyBlocStatus.TERMINE;
        } else if (toutesCloses) {
            status = JourneyBlocStatus.TERMINE;
        } else if (sansCompetence && jamaisMesure.test(ref)) {
            status = JourneyBlocStatus.A_EVALUER;
        } else {
            status = JourneyBlocStatus.A_VENIR;
        }

        List<JourneyStepDto> steps = etapes.stream()
                .filter(step -> step.getType() != JourneyStepType.SECTION_EXAM)
                .map(dto)
                .toList();
        JourneyStep examen = examenDuBloc(etapes);
        JourneyStepDto examenServi = examen == null ? null : dto.apply(examen);
        return new JourneyBlocDto(
                ref, status, restantes,
                // 🛑 LA PHRASE EST SERVIE (D-50 §4) : le mot depend du grain du
                // module, et un front qui le choisirait le choisirait seul.
                JourneyBlocMeta.pour(ref, status, restantes, !steps.isEmpty(),
                        examenServi != null && !examenServi.locked()),
                steps, examenServi);
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
