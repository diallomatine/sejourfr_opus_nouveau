package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.dto.TcfDomainProfileDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.JourneyStepPurpose;
import com.sejourfr.app.enums.JourneyStepResolution;
import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.manager.JourneyManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.attempt.AttemptScoringService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * <b>Les deux transitions de fin de cycle</b> (spec §6).
 *
 * <p>Quand le cycle est termine — ses quatre blocs le sont —, le Plan affiche
 * « Prochaine étape » et deux issues, et deux seulement :
 * <ol>
 *   <li><b>Actualiser mon plan</b> ({@link #actualiser}) : le cycle en cours est
 *       historise, le cycle <b>en attente</b> devient le cycle courant, et le
 *       prochain cycle en attente reste <b>paresseux</b> ;</li>
 *   <li><b>Passer l'examen blanc complet</b> ({@link #creerCycleDeMesure}) : le
 *       cycle en attente est laisse de cote, le cycle en cours est historise, et
 *       un <b>cycle de mesure</b> devient courant — quatre blocs, chacun ne
 *       portant que son examen.</li>
 * </ol>
 *
 * <h2>🛑 Ce service ne DEMARRE aucun examen</h2>
 * <p>{@link #creerCycleDeMesure} <b>cree le cycle</b>, rien de plus. L'examen
 * blanc complet reste lance par {@code POST /api/full-tcf-exams}, son unique
 * point d'entree : deux facons de demarrer un examen auraient fini par en
 * demarrer deux.
 *
 * <h2>Pourquoi un refus, et lequel</h2>
 * <p>Ces deux gestes <b>historisent</b> le cycle en cours. Les autoriser sur un
 * cycle inachieve reviendrait a jeter, sur un appel malformé ou un double tap,
 * le plan que le candidat a sous les yeux. Le refus est donc opposable
 * <b>serveur</b> :
 * <ul>
 *   <li><b>409</b> ({@code IllegalStateException}, convention du
 *       {@code GlobalExceptionHandler}) quand l'etat du cycle interdit le
 *       geste — cycle inachieve, ou cycle de mesure qu'on voudrait enchainer ;
 *   </li>
 *   <li><b>422</b> ({@code BusinessException}) quand il n'y a <b>pas de
 *       parcours du tout</b> : aucune demarche declaree (D-3). Ce n'est pas un
 *       conflit d'etat, c'est un prealable manquant.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class JourneyCycleService {

    private final JourneyService journeyService;
    private final ThemeManager themeManager;
    private final JourneyManager journeyManager;
    private final JourneyStepManager stepManager;
    private final TcfProfileService profileService;
    private final NiveauActuelEpreuveResolver mesureResolver;

    /**
     * <b>Actualiser mon plan</b> (spec §6).
     *
     * <p>Le cycle en attente devient le cycle courant, et son <b>niveau
     * d'entree</b> est le niveau de sortie de celui qu'il remplace : c'est ce
     * qui rend l'historique lisible d'un cycle au suivant sans jamais recalculer
     * un niveau passe.
     *
     * <p><b>Cas vide</b> : s'il n'y a rien en attente, un cycle neuf est
     * ouvert — il portera les examens des epreuves non mesurees (R12), et rien
     * du tout si elles le sont toutes. L'etat servi est alors le
     * {@code UP_TO_DATE} existant, « plus rien a faire » ; 🛑 aucun second etat
     * n'a ete invente pour dire la meme chose.
     */
    @Transactional
    public JourneyDto actualiser(UUID userId, Module module) {
        Journey enCours = cycleTermine(userId, module);
        if (module == Module.CIVIQUE) return actualiserLeCycleCivique(userId, enCours);

        TargetLevel sortie = historiser(enCours, userId);

        Journey promu = journeyManager
                .find(userId, enCours.getModule(), JourneyStatus.EN_ATTENTE)
                .orElseGet(() -> nouveauCycle(enCours));
        promu.setStatus(JourneyStatus.EN_COURS);
        promu.setEntryLevel(sortie);
        promu.setTargetLevel(enCours.getTargetLevel());
        Journey suivant = journeyManager.saveEtFlush(promu);
        // R12 — chaque bloc finit par son examen, y compris ceux qu'aucune
        // priorite n'a peuples. Le cycle promu ne portait jusqu'ici que des
        // lots : il lui manquait ses « Évaluer mon niveau ».
        journeyService.ajouterLesEpreuvesNonMesurees(suivant, userId);

        log.info("Cycle {} historise (sortie={}), cycle {} promu en cours",
                enCours.getId(), sortie, suivant.getId());
        return journeyService.lire(userId, module);
    }

    /**
     * <b>Passer l'examen blanc complet</b> (spec §6) : un <b>cycle de
     * mesure</b> devient le cycle courant.
     *
     * <p>Quatre blocs, chacun ne portant que son examen, <b>tous debloques</b> —
     * le verrou du bloc (D-15) ne se pose que sur une competence restante, et il
     * n'y en a aucune. ⚠️ Les verrous <b>commerciaux</b> (quota d'examen blanc
     * de production) continuent de s'appliquer : ils ne relevent pas du cycle.
     *
     * <p>🛑 <b>Le cycle en attente est laisse tel quel</b> : c'est tout l'objet
     * de cette issue. Le candidat veut se mesurer avant de reprendre le travail
     * qui l'attend, et les resultats de cette mesure viendront l'enrichir
     * (D-13).
     */
    @Transactional
    public JourneyDto creerCycleDeMesure(UUID userId, Module module) {
        Journey enCours = cycleTermine(userId, module);
        if (module == Module.CIVIQUE) return creerLeCycleDeMesureCivique(userId, enCours);
        if (JourneyBlocResolver.cycleDeMesure(nonObsoletes(enCours))) {
            // Enchainer deux examens complets sans travail entre eux ne mesure
            // rien de nouveau — c'est le « cas particulier » de la spec §6.
            throw new IllegalStateException(
                    "Ce cycle est deja un cycle de mesure : actualisez votre plan.");
        }
        TargetLevel sortie = historiser(enCours, userId);

        Journey neuf = nouveauCycle(enCours);
        neuf.setStatus(JourneyStatus.EN_COURS);
        neuf.setEntryLevel(sortie);
        Journey mesure = journeyManager.saveEtFlush(neuf);
        for (EpreuveType epreuve : TcfDomainProfileDto.ORDRE) {
            JourneyStep step = new JourneyStep();
            step.setJourney(mesure);
            step.setType(JourneyStepType.SECTION_EXAM);
            // La MEME action, deux intentions : « Évaluer mon niveau » sur une
            // epreuve jamais mesuree, « Vérifier mes progrès » ensuite. Lu chez
            // son unique autorite, jamais recompte ici.
            step.setPurpose(mesureResolver.mesure(userId, epreuve).mesuree()
                    ? JourneyStepPurpose.REASSESS
                    : JourneyStepPurpose.INITIAL_ASSESSMENT);
            step.setExamType(epreuve);
            journeyService.ajouter(mesure, step);
        }

        log.info("Cycle {} historise (sortie={}), cycle de mesure {} ouvert",
                enCours.getId(), sortie, mesure.getId());
        return journeyService.lire(userId, module);
    }

    /**
     * <b>Le cycle de mesure CIVIQUE</b> : cinq blocs de thématique, un examen
     * chacun, <b>tous débloqués</b> (spec §2, « Fin de cycle »).
     *
     * <p>🛑 <b>Cinq, pas quatre.</b> C'est toute la raison du garde qui vivait
     * ici avant : la boucle TCF pose les quatre épreuves, et la poser sur un
     * cycle civique aurait fabriqué un cycle de mesure TCF dans un parcours
     * civique.
     *
     * <p>🛑 <b>{@code REASSESS} sur les cinq</b> : un cycle de mesure ne s'ouvre
     * qu'à la fin d'un cycle entier — tout a été travaillé ou mesuré. Le geste
     * est « <b>vérifier mes progrès</b> », jamais « évaluer mon niveau ».
     *
     * <p>⚠️ <b>Aucune unité n'est posée</b>, et c'est la définition même du
     * cycle de mesure : {@code JourneyBlocResolver.cycleDeMesure} le reconnaît à
     * l'absence de {@code TRAIN_SKILL}. Les cinq examens sont donc ouverts
     * d'emblée (D-15 n'a rien à verrouiller), et passables thème par thème.
     */
    private JourneyDto creerLeCycleDeMesureCivique(UUID userId, Journey enCours) {
        if (JourneyBlocResolver.cycleDeMesure(nonObsoletes(enCours))) {
            throw new IllegalStateException(
                    "Ce cycle est deja un cycle de mesure : actualisez votre plan.");
        }
        Short sortie = historiserLeCycleCivique(enCours);

        Journey neuf = nouveauCycle(enCours);
        neuf.setStatus(JourneyStatus.EN_COURS);
        neuf.setEntryScore(sortie);
        Journey mesure = journeyManager.saveEtFlush(neuf);

        for (Theme thematique : themeManager
                .findByModuleOrderedByDisplayOrder(Module.CIVIQUE)) {
            JourneyStep step = new JourneyStep();
            step.setJourney(mesure);
            step.setType(JourneyStepType.SECTION_EXAM);
            step.setPurpose(JourneyStepPurpose.REASSESS);
            step.poserBloc(thematique);
            journeyService.ajouter(mesure, step);
        }

        log.info("Cycle civique {} historise (sortie={}), cycle de mesure {} ouvert",
                enCours.getId(), sortie, mesure.getId());
        return journeyService.lire(userId, Module.CIVIQUE);
    }

    /**
     * <b>Actualiser un cycle CIVIQUE</b> — historiser, puis <b>ré-amorcer</b>.
     *
     * <h3>🛑 Il n'y a PAS de cycle en attente civique, et c'est une conséquence
     * de D-36</h3>
     * <p>Côté TCF, le cycle en attente existe parce que les priorités naissent
     * d'<b>évaluations datées</b> : celles qui arrivent pendant qu'un cycle est
     * en cours doivent être mises quelque part, sinon elles se perdent.
     *
     * <p>Côté civique, les priorités sont <b>dérivées</b> — le plan les
     * recalcule à chaque lecture depuis les réponses. Il n'y a donc rien à
     * stocker : le cycle suivant s'amorce sur le plan <b>tel qu'il est au moment
     * où on l'ouvre</b>, ce qui est plus juste qu'une liste figée des semaines
     * plus tôt.
     *
     * <p>⚠️ Conséquence assumée : {@code JourneyStatus.EN_ATTENTE} n'existe
     * jamais côté civique. L'index partiel de V067 l'autorise — il ne l'exige
     * pas.
     */
    private JourneyDto actualiserLeCycleCivique(UUID userId, Journey enCours) {
        Short sortie = historiserLeCycleCivique(enCours);

        Journey suivant = nouveauCycle(enCours);
        suivant.setStatus(JourneyStatus.EN_COURS);
        // Le score de sortie devient le score d'ENTREE du suivant : c'est d'ou
        // le candidat repart, et c'est le meme fait vu des deux cotes.
        suivant.setEntryScore(sortie);
        suivant = journeyManager.saveEtFlush(suivant);
        journeyService.amorcerCycleCivique(suivant, enCours.getUser());

        log.info("Cycle civique {} historise (sortie={}), cycle {} ouvert",
                enCours.getId(), sortie, suivant.getId());
        return journeyService.lire(userId, Module.CIVIQUE);
    }

    /**
     * <b>Le score de sortie d'un cycle civique</b> : celui du <b>dernier examen
     * complet</b> passé pendant ce cycle.
     *
     * <p>🛑 <b>C'est un FAIT DEJA VU, pas un verdict nouveau</b> — le candidat a
     * vu ce score à la fin de cet examen. Le cycle ne le recalcule pas, ne le
     * pondère pas et n'en fabrique pas un second : il le <b>recopie</b>.
     *
     * <p>🛑 <b>{@code null} quand aucun examen complet n'a été passé</b>, et
     * c'est le cas normal d'un cycle de travail. <b>{@code null} = inconnu,
     * jamais mauvais</b> : un cycle sans mesure n'a pas un score de zéro.
     *
     * <p>⚠️ Un examen de <b>thème</b> ne compte pas : il porte 20 questions, pas
     * les 40 de l'arrêté. Mélanger les deux échelles ferait un chiffre qui ne
     * veut rien dire.
     */
    private Short historiserLeCycleCivique(Journey enCours) {
        Short sortie = journeyManager.dernierScoreDExamenComplet(enCours.getId());
        enCours.setStatus(JourneyStatus.HISTORISE);
        enCours.setHistoriseAt(Instant.now());
        enCours.setExitScore(sortie);
        journeyManager.saveEtFlush(enCours);
        return sortie;
    }

    // ------------------------------------------------------------------ outils

    /**
     * Le cycle en cours, <b>verrouille</b> et <b>termine</b> — sinon le geste est
     * refuse.
     *
     * <p>Le verrou pessimiste est le meme que celui de toute ecriture du
     * parcours (R14) : une evaluation qui se termine au moment ou le candidat
     * actualise doit attendre son tour, pas ecrire dans un cycle qu'on
     * historise.
     */
    private Journey cycleTermine(UUID userId, Module module) {
        Journey enCours = journeyService.getOrCreate(userId, module)
                .flatMap(journey -> journeyManager.findForUpdate(journey.getId()))
                .orElseThrow(() -> new BusinessException(
                        "Aucun parcours : declarez d'abord votre objectif."));
        boolean ouvertes = stepManager.findAll(enCours.getId()).stream()
                .anyMatch(JourneyStep::estOuverte);
        if (ouvertes) {
            throw new IllegalStateException(
                    "Votre parcours n'est pas termine : il reste des etapes a faire.");
        }
        return enCours;
    }

    /**
     * Historise le cycle et <b>ecrit son niveau de sortie</b> (D-12).
     *
     * <p>🛑 <b>Le niveau est LU chez l'autorite du Plan</b>
     * ({@code TcfProfileService.levelProfile}, arbitrage D-2) et converti par
     * {@code AttemptScoringService.toTargetLevel}, la seule table CECRL →
     * palier du depot. Aucun plancher n'est recalcule ici : « le niveau global
     * est le plancher des epreuves reellement passees » est une regle qui a deja
     * une autorite, et en ecrire une seconde ferait diverger l'historique des
     * cycles de ce que l'ecran affiche.
     *
     * <p>🛑 <b>{@code null} = INCONNU, jamais mauvais.</b> Un cycle ferme sans
     * qu'aucune epreuve n'ait ete mesuree n'a pas de niveau de sortie — et
     * surtout pas « le palier le plus bas » : c'est la confusion exacte qui a
     * produit les faux {@code A1_NON_ATTEINT} (V040/V041/V042). Un niveau
     * mesure <b>sous l'A2</b> ne rentre pas non plus dans la colonne (elle ne
     * connait que A2/B1/B2), et c'est assume : l'historique dit « pas encore de
     * palier », pas « A1 ».
     *
     * <p>Une fois ecrit, il n'est <b>jamais recalcule</b> : un recalibrage de
     * seuils ne doit pas reecrire l'histoire du candidat. Meme argument que
     * {@code journey_step.resolution}.
     */
    private TargetLevel historiser(Journey enCours, UUID userId) {
        TargetLevel sortie = AttemptScoringService.toTargetLevel(
                profileService.levelProfile(userId).globalLevel());
        enCours.setStatus(JourneyStatus.HISTORISE);
        enCours.setHistoriseAt(Instant.now());
        enCours.setExitLevel(sortie);
        journeyManager.saveEtFlush(enCours);
        return sortie;
    }

    /** Un cycle neuf pour le meme candidat, le meme module et le meme objectif. */
    private Journey nouveauCycle(Journey precedent) {
        Journey cycle = new Journey();
        cycle.setUser(precedent.getUser());
        cycle.setModule(precedent.getModule());
        // 🛑 L'OBJECTIF SE POSE, il ne se copie pas champ par champ :
        // `chk_journey_objectif` (V069) exige EXACTEMENT un des deux, et un
        // `setTargetLevel(null)` sur un cycle civique aurait produit une ligne
        // sans objectif -- refusee au flush, loin d'ici.
        if (precedent.getTargetProcedure() != null) {
            cycle.poserObjectif(precedent.getTargetProcedure());
        } else {
            cycle.poserObjectif(precedent.getTargetLevel());
        }
        return cycle;
    }

    /** Les etapes du cycle, obsoletes exclues — ce que « cycle de mesure » regarde. */
    private List<JourneyStep> nonObsoletes(Journey journey) {
        return stepManager.findAll(journey.getId()).stream()
                .filter(step -> step.getResolution() != JourneyStepResolution.SUPERSEDED)
                .toList();
    }
}
