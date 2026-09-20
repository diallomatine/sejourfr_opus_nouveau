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
 * <p>⚠️ Depuis le 2026-09-20, l'axe <b>TCF</b> que ce composant recoit est
 * {@code ORDRE} <b>relu</b> par {@code JourneyReadService.axeAffiche} : les
 * blocs qui portent une etape {@code TRAIN_SKILL} sont places devant ceux qui
 * n'en portent aucune, {@code ORDRE} etant conserve dans chaque groupe. Ce
 * composant ne le sait pas et n'a pas a le savoir — il sert l'axe qu'on lui
 * donne, exactement comme avant.
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
     * @param courante       l'etape {@code CURRENT}, ou {@code null}. 🛑 Depuis
     *                       le 2026-09-20 elle ne sert plus qu'au <b>repli</b>
     *                       du badge {@code EN_COURS}, quand aucun bloc ne
     *                       porte de travail ouvert
     *                       ({@link #meneur(List, Map, JourneyStep)}).
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

        Map<String, List<JourneyStep>> parBloc = grouper(axe, affichables);

        // 🛑 LE MENEUR SE DESIGNE ICI, UNE FOIS, parce que c'est ICI que
        // l'ordre servi est connu. `bloc(...)` ne voit qu'un bloc : il ne
        // saurait pas dire s'il est le premier.
        String meneur = meneur(axe, parBloc, courante);

        List<JourneyBlocDto> blocs = new ArrayList<>(axe.size());
        for (JourneyBlocRefDto ref : axe) {
            blocs.add(bloc(ref, parBloc.get(ref.code()), ref.code().equals(meneur),
                    dto, jamaisMesure));
        }

        int terminees = (int) affichables.stream().filter(step -> !step.estOuverte()).count();
        boolean complete = affichables.stream().allMatch(step -> !step.estOuverte());
        return new Vue(List.copyOf(blocs), new JourneyCycleDto(
                numeroDuCycle, terminees, affichables.size(), complete,
                cycleDeMesure(affichables)));
    }

    /**
     * <b>Le bloc {@code EN_COURS} : le PREMIER, dans l'ordre servi, qui porte
     * encore une etape {@code TRAIN_SKILL} ouverte</b> — qu'elle soit
     * executable ou non.
     *
     * <h3>Le defaut que cette methode corrige, constate a l'ecran</h3>
     * <p>Le proprietaire, verbatim : « Ici c'est EE qui doit etre en cours, car
     * on commence par lui, commence par ce que le diagnostic a identifie et
     * ensuite on fais l'examen sur les autres epreuves ». Le cycle d'un compte
     * <b>gratuit</b> affichait « Expression ecrite — 3 competences · puis
     * examen — <b>À VENIR</b> » au-dessus de « Comprehension orale — Examen a
     * passer — <b>EN COURS</b> » : deux phrases qui se contredisent.
     *
     * <p>La cause tenait en une composition de deux regles justes.
     * {@code CURRENT} est « la premiere etape non cloturee <b>et
     * executable</b> » (D-1), et D-18 rend <b>toute</b> etape
     * {@code TRAIN_SKILL} inexecutable pour un compte gratuit. La main passait
     * donc au premier examen ouvert — celui d'un bloc <b>sans</b> competence a
     * finir avant lui (D-15) — et le badge le suivait.
     *
     * <h3>🛑 Revocation PARTIELLE d'A37, dont le motif reste tenu</h3>
     * <p>A37 ouvrait la derivation par « le bloc porte {@code current} ». Son
     * motif — « le bloc qui porte l'action gagne toujours l'affichage, sinon
     * deux blocs se disputeraient EN COURS » — est <b>satisfait autrement</b> :
     * un seul bloc peut etre le <b>premier</b> a porter du travail ouvert.
     *
     * <p>🛑 <b>Le badge ne depend plus de {@code CURRENT} — c'est desormais
     * {@code CURRENT} qui depend du badge</b> (D-57, seconde moitie, livree le
     * 2026-09-20) : {@code JourneyReadService.elire} cherche l'etape courante
     * <b>dans le bloc meneur, et dans lui seul</b>, par
     * {@link #meneurParLeTravail(List, List)}. D-1 garde son <b>critere</b>
     * (« non cloturee et executable ») ; c'est l'<b>ensemble</b> ou l'on cherche
     * qui se restreint. 🛑 <b>D-18 est intact</b> : rien ne s'ouvre,
     * {@code locked} est inchange — ce qui change est ce que l'ecran <b>dit</b>,
     * pas ce qu'il <b>ouvre</b>.
     *
     * <h3>⚠️ Le repli n'est pas une precaution de style</h3>
     * <p>Quand <b>aucun</b> bloc ne porte de travail ouvert, le comportement
     * d'A37 est conserve : le badge va au bloc qui porte {@code current}. C'est
     * le <b>cycle de mesure</b> (A80, A33) — quatre ou cinq blocs ne contenant
     * que leur examen — ou un cycle dont tout le travail est fini. « Le bloc qui
     * porte la main » y est la bonne reponse, et la seule disponible : sans ce
     * repli, un cycle de mesure entier n'aurait plus aucun bloc
     * {@code EN_COURS}.
     *
     * <h3>Les deux modules, sans le savoir</h3>
     * <p>Cette methode ne lit que {@code type()} et {@code estOuverte()} : elle
     * vaut pour le civique par construction, et le resolveur continue d'ignorer
     * de quel module il parle (D-47, A61). 🛑 Elle ne <b>trie</b> rien non plus
     * — elle parcourt l'axe <b>deja ordonne</b> par l'appelant (D-56, A101).
     *
     * @return le code du bloc meneur, ou {@code null} quand aucun ne l'est —
     *         un cycle sans travail ouvert et sans {@code current}, ou dont le
     *         {@code current} est un {@code DIAGNOSTIC}, qui n'appartient a
     *         aucun bloc (R11, A45).
     */
    private static String meneur(
            List<JourneyBlocRefDto> axe,
            Map<String, List<JourneyStep>> parBloc,
            JourneyStep courante) {

        // 🛑 LA DESIGNATION PAR LE TRAVAIL EST EXTRAITE, et c'est ce qui CASSE
        // LA BOUCLE (D-57, seconde moitie) : `elire` en a besoin AVANT qu'une
        // etape courante existe. Elle ne voit pas `courante` — elle ne peut donc
        // pas en dependre, et la circularite n'est pas evitee par discipline,
        // elle est impossible a ecrire.
        String parLeTravail = meneurParLeTravail(axe, parBloc);
        if (parLeTravail != null) return parLeTravail;
        if (courante == null) return null;
        for (JourneyBlocRefDto ref : axe) {
            boolean porteLaMain = parBloc.get(ref.code()).stream()
                    .anyMatch(step -> step.getId().equals(courante.getId()));
            if (porteLaMain) return ref.code();
        }
        return null;
    }

    /**
     * <b>Le bloc meneur PAR LE TRAVAIL</b> : le premier de l'axe servi qui porte
     * encore une etape {@code TRAIN_SKILL} ouverte, ou {@code null} quand aucun
     * n'en porte. <b>Une seule autorite, deux lecteurs</b> (D-57).
     *
     * <h3>🛑 Pourquoi cette methode est PUBLIQUE, et pourquoi elle ne voit pas
     * {@code courante}</h3>
     * <p>Depuis D-57, {@code JourneyReadService.elire} cherche {@code CURRENT}
     * <b>dans le bloc meneur, et dans lui seul</b> : « une epreuve en cours,
     * c'est forcement une de ses etapes a faire maintenant » (le proprietaire).
     * Le meneur doit donc etre connu <b>avant</b> l'election, alors que
     * {@link #meneur(List, Map, JourneyStep)} ne s'evalue qu'<b>apres</b> — il
     * prend {@code courante} en second recours.
     *
     * <p>La boucle est cassee <b>par la signature</b>, pas par une convention :
     * cette methode ne recoit pas l'etape courante, donc elle ne peut pas en
     * dependre. L'ordre reel est <b>un DAG</b> : travail ⇒ meneur ⇒
     * {@code CURRENT} ⇒ (seulement si aucun meneur par le travail) repli du
     * badge sur le porteur de {@code CURRENT}. Recopier ce parcours dans le
     * service aurait donne une <b>2<sup>e</sup> occurrence</b> de « quel bloc
     * porte du travail » — le defaut le plus cher du depot.
     *
     * <p>🛑 Le critere reste celui d'<b>A112</b> : {@code TRAIN_SKILL}
     * <b>ouverte</b>, jamais « ouverte et executable ». Lire l'executabilite
     * reintroduirait la dependance D-1 ⇄ D-18 qui a <b>produit</b> le defaut.
     *
     * @param axe    les blocs du module, <b>deja ordonnes</b> par l'appelant
     *               (D-56, A101) : cette methode ne trie rien.
     * @param etapes les etapes du cycle, <b>obsoletes deja exclues</b> — la
     *               meme liste que celle dont les blocs sont batis.
     */
    public static String meneurParLeTravail(
            List<JourneyBlocRefDto> axe, List<JourneyStep> etapes) {
        return meneurParLeTravail(axe, grouper(axe, etapes));
    }

    private static String meneurParLeTravail(
            List<JourneyBlocRefDto> axe, Map<String, List<JourneyStep>> parBloc) {
        for (JourneyBlocRefDto ref : axe) {
            boolean travailOuvert = parBloc.get(ref.code()).stream()
                    .anyMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL
                            && step.estOuverte());
            if (travailOuvert) return ref.code();
        }
        return null;
    }

    /**
     * Les etapes du cycle, <b>rangees par bloc</b>, dans l'ordre de l'axe servi.
     *
     * <p>🛑 Extrait de {@link #lire} le 2026-09-20 : {@link #meneurParLeTravail}
     * a besoin du meme groupement, et « quelle etape appartient a quel bloc »
     * est exactement ce que D-47 a deja concentre en un seul endroit.
     */
    private static Map<String, List<JourneyStep>> grouper(
            List<JourneyBlocRefDto> axe, List<JourneyStep> etapes) {
        Map<String, List<JourneyStep>> parBloc = new LinkedHashMap<>();
        for (JourneyBlocRefDto ref : axe) {
            parBloc.put(ref.code(), new ArrayList<>());
        }
        for (JourneyStep step : etapes) {
            // 🛑 `blocCode()` lit l'axe A LA SOURCE (D-47) : l'epreuve cote TCF,
            // la thematique cote civique, et ce code ne sait pas lequel.
            List<JourneyStep> bloc = parBloc.get(step.blocCode());
            // Une etape DIAGNOSTIC n'appartient a aucun bloc : elle mesure le
            // candidat, pas une epreuve ni une thematique (R11, A45). Elle
            // compte dans l'avancement du cycle, et nulle part ailleurs.
            if (bloc != null) bloc.add(step);
        }
        return parBloc;
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
     *   <li>c'est le <b>meneur</b> ⇒ {@code EN_COURS} ;</li>
     *   <li>il n'a aucune etape ⇒ {@code A_EVALUER} si son epreuve n'a jamais
     *       ete mesuree, sinon {@code TERMINE} — un bloc sans rien a faire sur
     *       une epreuve deja mesuree n'a plus rien a dire ;</li>
     *   <li>toutes ses etapes sont cloturees ⇒ {@code TERMINE} ;</li>
     *   <li>aucune competence <b>et</b> epreuve jamais mesuree ⇒
     *       {@code A_EVALUER} : il n'y a rien a travailler tant que la mesure
     *       n'a pas dit quoi ;</li>
     *   <li>sinon {@code A_VENIR}.</li>
     * </ol>
     *
     * <p>🛑 <b>Seule la premiere question a change</b> (2026-09-20) : elle se
     * lisait « il porte l'etape courante » et se lit « il est le meneur ».
     * Cette methode ne sait toujours pas <b>pourquoi</b> — elle ne voit qu'un
     * bloc, et ne pourrait pas dire s'il est le premier. C'est
     * {@link #meneur(List, Map, JourneyStep)} qui le decide, une fois, la ou
     * l'ordre servi est connu.
     *
     * @param meneur ce bloc est-il celui qui porte le badge ? Un seul l'est.
     */
    private static JourneyBlocDto bloc(
            JourneyBlocRefDto ref,
            List<JourneyStep> etapes,
            boolean meneur,
            Function<JourneyStep, JourneyStepDto> dto,
            Predicate<JourneyBlocRefDto> jamaisMesure) {

        int restantes = (int) etapes.stream()
                .filter(JourneyStep::estOuverte)
                .filter(step -> step.getType() == JourneyStepType.TRAIN_SKILL)
                .count();
        boolean sansCompetence = etapes.stream()
                .noneMatch(step -> step.getType() == JourneyStepType.TRAIN_SKILL);
        boolean toutesCloses = etapes.stream().allMatch(step -> !step.estOuverte());

        JourneyBlocStatus status;
        if (meneur) {
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
