package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.JourneyDto;
import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.enums.JourneyFinDeCycle;
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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * <b>Les deux transitions d'un cycle</b> — la fin de cycle et le jalon.
 *
 * <ol>
 *   <li><b>Actualiser mon plan</b> ({@link #actualiser}) : la <b>seule</b>
 *       issue de fin de cycle depuis D-66 (2026-09-27). Le cycle en cours est
 *       historise, le cycle <b>en attente</b> devient le cycle courant, et le
 *       prochain cycle en attente reste <b>paresseux</b> ;</li>
 *   <li><b>Faire un examen blanc complet</b> ({@link #creerCycleDeMesure}) : un
 *       <b>jalon propose</b>, plus une etape de fin de cycle (D-68). Offert quand
 *       {@link JourneyJalonExamenComplet} le propose — le cycle en cours peut
 *       alors etre inacheve : il est <b>mis de cote</b> ({@code INTERROMPU}) et
 *       un <b>cycle d'examens</b> devient courant, un bloc par epreuve ou
 *       thematique, chacun ne portant que son examen. Le cycle en attente est
 *       laisse tel quel.</li>
 * </ol>
 *
 * <h2>🛑 Ce service ne DEMARRE aucun examen</h2>
 * <p>{@link #creerCycleDeMesure} <b>cree le cycle</b>, rien de plus. L'examen
 * blanc complet reste lance par {@code POST /api/full-tcf-exams}, son unique
 * point d'entree : deux facons de demarrer un examen auraient fini par en
 * demarrer deux.
 *
 * <h2>Pourquoi un refus, et lequel</h2>
 * <p>Ces deux gestes <b>historisent</b> le cycle en cours. Le refus est donc
 * opposable <b>serveur</b> :
 * <ul>
 *   <li><b>409</b> ({@code IllegalStateException}, convention du
 *       {@code GlobalExceptionHandler}) quand l'etat du cycle interdit le
 *       geste — actualisation d'un cycle inacheve, jalon non propose ;
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
    // 🛑 L'UNIQUE facon d'historiser un cycle, partagee avec le lancement (D-69 ter).
    private final JourneyHistorisation historisation;
    // 🛑 La MEME autorite que `JourneyDto.examenComplet` (D-68) : le jalon servi
    // et ce refus serveur ne peuvent pas dire deux choses differentes.
    private final JourneyJalonExamenComplet jalonExamenComplet;
    // 🛑 La MEME autorite que `cycle.complete` et `nextStep` servis : le bouton
    // « Actualiser » et le 409 ne peuvent pas dire deux choses differentes.
    private final JourneyCycleAffinage cycleAffinage;

    /**
     * <b>Actualiser mon plan</b> (spec §6).
     *
     * <p>Le cycle en attente devient le cycle courant, et son <b>niveau
     * d'entree</b> est le niveau de sortie de celui qu'il remplace : c'est ce
     * qui rend l'historique lisible d'un cycle au suivant sans jamais recalculer
     * un niveau passe.
     *
     * <p><b>Cas vide</b> : s'il n'y a rien en attente, un cycle neuf est
     * ouvert. 🛑 <b>D-70 (2026-10-03)</b> : aucun de ses blocs ne reste vide —
     * une comprehension mesuree sous l'objectif recoit son palier a acquerir
     * (un seul depuis D-72), toute autre epreuve son examen blanc
     * ({@code JourneyService.completerLesBlocsVides}). Un bloc vide se lisait
     * « termine » sans qu'on y ait rien fait.
     */
    @Transactional
    public JourneyDto actualiser(UUID userId, Module module) {
        Journey enCours = cycleTermine(userId, module);
        if (module == Module.CIVIQUE) return actualiserLeCycleCivique(userId, enCours);

        TargetLevel sortie = historiser(enCours, userId, JourneyFinDeCycle.ACTUALISATION);

        Journey promu = journeyManager
                .find(userId, enCours.getModule(), JourneyStatus.EN_ATTENTE)
                .orElseGet(() -> nouveauCycle(enCours));
        promu.setStatus(JourneyStatus.EN_COURS);
        promu.setEntryLevel(sortie);
        promu.setTargetLevel(enCours.getTargetLevel());
        Journey suivant = journeyManager.saveEtFlush(promu);
        // D-72 — en CO/CE, le cycle ne travaille qu'un palier, le plus bas a
        // acquerir, relu maintenant : ce qui en sort est ecarte, et un bloc
        // ainsi vide est recompose par D-70 juste en dessous.
        journeyService.retenirLePalierDuCycle(suivant);
        // R12 — chaque bloc finit par son examen, y compris ceux qu'aucune
        // priorite n'a peuples. Le cycle promu ne portait jusqu'ici que des
        // lots : il lui manquait ses « Évaluer mon niveau ».
        journeyService.ajouterLesEpreuvesNonMesurees(suivant, userId);
        // D-70 — aucun bloc ne reste vide : la comprehension sous l'objectif
        // recoit ses paliers, toute autre epreuve son examen blanc.
        journeyService.completerLesBlocsVides(suivant, stepManager.findAll(suivant.getId()));

        log.info("Cycle {} historise (sortie={}), cycle {} promu en cours",
                enCours.getId(), sortie, suivant.getId());
        return journeyService.lire(userId, module);
    }

    /**
     * <b>Faire un examen blanc complet</b> — le jalon (D-68) : le cycle en cours
     * est mis de cote et un <b>cycle d'examens</b> devient le cycle courant.
     *
     * <p>Un bloc par epreuve (TCF) ou par thematique (civique), chacun ne
     * portant que son examen, <b>tous debloques</b> — le verrou du bloc (D-15)
     * ne se pose que sur une competence restante, et il n'y en a aucune. ⚠️ Les
     * verrous <b>commerciaux</b> (gratuite d'examen de production) continuent
     * de s'appliquer, servis en {@code lockReason = ACCESS} : le jalon ne
     * change pas le freemium.
     *
     * <p>🛑 <b>Le mode de cloture est ECRIT</b> ({@code journey.fin_de_cycle},
     * V078) : {@code INTERROMPU} quand des etapes obligatoires restaient
     * ouvertes, {@code EXAMEN_COMPLET} quand le cycle etait deja termine — un
     * cycle fini n'a pas ete interrompu.
     *
     * <p>🛑 <b>Rien a reporter a la main</b> : les priorites non terminees du
     * cycle mis de cote sont historisees telles quelles, et les examens du cycle
     * d'examens les <b>recalculent</b> — chaque examen depose ses priorites dans
     * le cycle en attente ({@code JourneyService.mettreEnAttente}), au plus
     * trois par epreuve (D-67). Cote civique, l'amorce du cycle suivant relit le
     * plan derive, qui a vu les memes examens.
     *
     * <p>🛑 <b>Le cycle en attente est laisse tel quel</b> : les resultats des
     * examens viendront l'enrichir (D-13).
     *
     * <p>🛑 <b>Ce service ne demarre aucun examen</b> : chaque examen du cycle se
     * lance depuis son bloc, par son chemin existant.
     */
    @Transactional
    public JourneyDto creerCycleDeMesure(UUID userId, Module module) {
        Journey enCours = verrouille(userId, module);
        List<JourneyStep> etapes = nonObsoletes(enCours);
        boolean affinage = cycleAffinage.pour(enCours);
        // 🛑 LA MEME AUTORITE QUE LE JALON SERVI : sans lui, le geste est refuse.
        if (jalonExamenComplet.pour(enCours, etapes, affinage) == null) {
            throw new IllegalStateException(
                    "L'examen blanc complet n'est pas encore propose sur ce cycle.");
        }
        JourneyFinDeCycle geste = JourneyCycleAffinage.termine(etapes, affinage)
                ? JourneyFinDeCycle.EXAMEN_COMPLET
                : JourneyFinDeCycle.INTERROMPU;
        if (module == Module.CIVIQUE) return creerLeCycleDeMesureCivique(userId, enCours, geste);

        TargetLevel sortie = historiser(enCours, userId, geste);

        Journey neuf = nouveauCycle(enCours);
        neuf.setStatus(JourneyStatus.EN_COURS);
        neuf.setEntryLevel(sortie);
        Journey mesure = journeyManager.saveEtFlush(neuf);
        // La MEME construction que le Plan par defaut (D-69) : une seule autorite.
        journeyService.poserLeCycleDExamens(mesure, userId);

        log.info("Cycle {} historise ({}, sortie={}), cycle d'examens {} ouvert",
                enCours.getId(), geste, sortie, mesure.getId());
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
     * <p>🛑 <b>{@code REASSESS} sur les cinq</b> : le jalon ne s'ouvre qu'apres
     * du travail ou un objectif mesure — le geste est « <b>vérifier mes
     * progrès</b> », jamais « évaluer mon niveau ».
     *
     * <p>⚠️ <b>Aucune unité n'est posée</b>, et c'est la définition même du
     * cycle de mesure : {@code JourneyBlocResolver.cycleDeMesure} le reconnaît à
     * l'absence de {@code TRAIN_SKILL}. Les cinq examens sont donc ouverts
     * d'emblée (D-15 n'a rien à verrouiller), et passables thème par thème.
     */
    private JourneyDto creerLeCycleDeMesureCivique(
            UUID userId, Journey enCours, JourneyFinDeCycle geste) {
        Short sortie = historiserLeCycleCivique(enCours, geste);

        Journey neuf = nouveauCycle(enCours);
        neuf.setStatus(JourneyStatus.EN_COURS);
        neuf.setEntryScore(sortie);
        Journey mesure = journeyManager.saveEtFlush(neuf);

        // La MEME construction que le lancement (D-69 ter) : une seule autorite.
        journeyService.poserLeCycleDExamensCivique(mesure);

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
        Short sortie = historiserLeCycleCivique(enCours, JourneyFinDeCycle.ACTUALISATION);

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
    private Short historiserLeCycleCivique(Journey enCours, JourneyFinDeCycle geste) {
        return historisation.historiserCivique(enCours, geste);
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
        Journey enCours = verrouille(userId, module);
        // 🛑 « Termine » a UNE autorite, `JourneyCycleAffinage.termine` : hors
        // affinage, plus rien d'ouvert ; en affinage (D-64), plus aucun examen
        // ouvert — les competences facultatives restantes sont historisees
        // telles quelles, et les priorites que les examens ont confirmees
        // attendent deja dans le cycle suivant.
        boolean termine = JourneyCycleAffinage.termine(
                stepManager.findAll(enCours.getId()), cycleAffinage.pour(enCours));
        if (!termine) {
            throw new IllegalStateException(
                    "Votre parcours n'est pas termine : il reste des etapes a faire.");
        }
        return enCours;
    }

    /** Le cycle en cours du module, sous verrou pessimiste (R14). */
    private Journey verrouille(UUID userId, Module module) {
        return journeyService.getOrCreate(userId, module)
                .flatMap(journey -> journeyManager.findForUpdate(journey.getId()))
                .orElseThrow(() -> new BusinessException(
                        "Aucun parcours : declarez d'abord votre objectif."));
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
    private TargetLevel historiser(Journey enCours, UUID userId, JourneyFinDeCycle geste) {
        return historisation.historiserTcf(enCours, geste);
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
