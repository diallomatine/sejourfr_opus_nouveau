package com.sejourfr.app.service.journey;

import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.JourneySerieDto;
import com.sejourfr.app.dto.JourneyStepDetailDto;
import com.sejourfr.app.dto.JourneyUniteDetailDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.JourneyStep;
import com.sejourfr.app.entity.JourneyStepSeries;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.JourneyStepManager;
import com.sejourfr.app.manager.JourneyStepSeriesManager;
import com.sejourfr.app.service.AttemptService;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import com.sejourfr.app.enums.AttemptMode;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>L'ecran d'ETAPE et ses cartes de serie</b> (2026-09-20).
 *
 * <p>Une etape de comprehension (CO/CE) ou une unite officielle civique se
 * valide par <b>{@code trainSeriesQuota} series reussies</b>. Jusqu'ici, le Plan
 * lancait directement une serie ciblee : le candidat ne voyait ni combien il lui
 * en restait, ni ce qu'il avait deja obtenu. Cet ecran montre les cartes, leur
 * etat et leur dernier score, et permet de les lancer ou de les refaire.
 *
 * <h2>🛑 Ce service ne COMPOSE aucune serie</h2>
 * <p>Il <b>delegue</b> aux deux autorites existantes —
 * {@code AttemptService.demarrerSerieDeCarte} cote TCF,
 * {@code CivicPlanService.demarrerSerieSurUnite} cote civique. Elles portent le
 * tirage, la taille, le verrou freemium et le refus « banque vide ». Ce service
 * n'ajoute que ce qui releve du <b>parcours</b> : le verrou de carte, et
 * l'ecriture du lien {@code journey_step_series}.
 *
 * <h2>🛑 Un seul endpoint pour les deux modules</h2>
 * <p>Le module se <b>resout depuis l'etape</b> (competence XOR unite officielle,
 * exclusivite verrouillee en base par {@code chk_journey_step_train_skill}). Un
 * lanceur par grain aurait duplique cote fronts la question « de quel module
 * suis-je ? », que le serveur est seul a savoir repondre.
 *
 * <h2>🛑 Le verdict a UNE autorite</h2>
 * <p>{@link JourneySerieVerdict} — 16 bonnes reponses sur les 20 de la serie,
 * lues sur l'attempt. C'est la <b>meme</b> fonction qui decide de
 * {@code validee}, du {@code seuilReussite} servi, du verrou de la carte
 * suivante et de la cloture de l'etape ({@code JourneyReadService.etapesAuQuota}).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class JourneyStepDetailService {

    private final JourneyStepManager stepManager;
    private final JourneyStepSeriesManager seriesManager;
    private final AttemptManager attemptManager;
    private final JourneyReadService readService;
    private final JourneySerieVerdict verdict;
    private final TcfJourneyConfig config;
    private final AttemptService attemptService;
    private final CivicPlanService civicPlanService;

    // ------------------------------------------------------------------ lecture

    /** L'ecran d'etape, tel que les deux fronts le lisent. */
    @Transactional(readOnly = true)
    public JourneyStepDetailDto lire(UUID userId, UUID stepId) {
        JourneyStep step = etapeDuCandidat(userId, stepId);
        Module module = step.getJourney().getModule();
        Skill skill = step.getSkill();

        List<JourneyStep> duCycle = stepManager.findAll(step.getJourney().getId());
        boolean locked = readService.verrouDeLEtape(userId, step, duCycle, module);
        List<JourneySerieDto> cartes = cartes(step);

        return new JourneyStepDetailDto(
                step.getId(),
                step.getType(),
                // 🛑 LE BLOC EST SERVI DANS LES DEUX MODULES (D-47) : une epreuve
                // TCF ou une thematique civique, meme chemin d'affichage. C'est
                // `blocRef()` qui porte cette uniformite, a la source.
                step.blocRef(),
                unite(step),
                skill == null ? null : skill.getSection(),
                // 🛑 L'OBJECTIF EST SERVI AVEC SON LIBELLE, palier OU mention
                // (D-47 / A47) : un `TargetLevel` aurait prive l'ecran civique
                // de son « Plan — Naturalisation ».
                step.getJourney().objectifRef(),
                step.getSeverityRank() != null,
                config.trainSeriesQuota(),
                // 🛑 Le compte des cartes reussies est SERVI, pas recompte par
                // l'ecran : c'est le meme nombre que le moteur compare au quota.
                (int) cartes.stream().filter(JourneySerieDto::validee).count(),
                verdict.questionsParSerie(module),
                verdict.seuilReussite(module),
                verdict.dureeEstimeeMin(module, step.getExamType()),
                locked,
                cartes);
    }

    /**
     * <b>Les cartes de l'etape</b> — toujours {@code trainSeriesQuota}, meme
     * celles qui n'ont jamais ete jouees : sans elles, l'ecran ne saurait pas
     * combien il en reste.
     *
     * <h3>🛑 « Validee » est DEFINITIF</h3>
     * <p>Une carte reussie une fois le reste, meme si un essai ulterieur echoue :
     * le travail acquis reste acquis (arbitrage du proprietaire). Le
     * {@code dernierScore} servi est en revanche <b>celui du dernier essai</b>,
     * reussi ou non — c'est ce que le candidat vient de faire, et le lui cacher
     * serait mentir.
     *
     * <h3>🛑 Le verrou de carte porte sur la REUSSITE, pas sur le fait de jouer</h3>
     * <p>« La serie 2 ne se debloque qu'apres REUSSITE de la serie 1 ». Une
     * serie 1 jouee et ratee laisse donc la serie 2 verrouillee — c'est la
     * consequence directe de la suppression du filet, assumee et validee.
     */
    private List<JourneySerieDto> cartes(JourneyStep step) {
        Map<Integer, List<JourneyStepSeries>> parCarte = essaisParCarte(step);
        List<JourneySerieDto> cartes = new ArrayList<>(config.trainSeriesQuota());
        boolean precedenteValidee = true;
        for (int index = 1; index <= config.trainSeriesQuota(); index++) {
            List<JourneyStepSeries> essais = parCarte.getOrDefault(index, List.of());
            boolean validee = essais.stream().anyMatch(e -> verdict.reussie(e.getAttempt()));
            JourneyStepSeries dernier = essais.isEmpty() ? null : essais.getLast();
            cartes.add(new JourneySerieDto(
                    index,
                    !precedenteValidee,
                    validee,
                    dernier == null ? null : verdict.score(dernier.getAttempt()),
                    dernier == null ? null : dernier.getAttempt().getId(),
                    dernier == null ? null : dernier.getCreatedAt()));
            precedenteValidee = validee;
        }
        return List.copyOf(cartes);
    }

    // ------------------------------------------------------------------ lancement

    /**
     * <b>Lancer (ou refaire) la serie {@code index} de cette etape.</b>
     *
     * <p>Refuse en <b>403</b> quand l'etape est verrouillee (freemium) ou quand
     * la carte l'est (la precedente n'est pas reussie). 🛑 Le refus est
     * <b>serveur</b>, opposable : un ecran dont l'etat en cache est perime recoit
     * un 403 la ou son interface croyait la carte ouverte, et c'est un refus
     * attendu.
     *
     * <p>Refuse en <b>422</b> quand l'index sort du quota : une carte 3 n'existe
     * pas, et l'accepter aurait cree une ligne que l'ecran ne montrerait jamais.
     *
     * <p>🛑 <b>Le lien s'ecrit APRES la composition</b> : si le tirage echoue
     * (banque vide), rien n'est rattache. Un lien vers une serie qui n'a pas
     * demarre aurait compte comme un essai.
     */
    @Transactional
    public AttemptResponse demarrer(UUID userId, UUID stepId, int index) {
        JourneyStep step = etapeDuCandidat(userId, stepId);
        if (index < 1 || index > config.trainSeriesQuota()) {
            throw new BusinessException(
                    "Cette etape ne compte que " + config.trainSeriesQuota() + " series.");
        }
        Module module = step.getJourney().getModule();
        List<JourneyStep> duCycle = stepManager.findAll(step.getJourney().getId());
        if (readService.verrouDeLEtape(userId, step, duCycle, module)) {
            throw new AccessDeniedException(
                    "Cette etape fait partie de l'abonnement. "
                            + "Votre plan, lui, reste entier.");
        }
        if (carteVerrouillee(step, index)) {
            throw new AccessDeniedException(
                    "Reussissez d'abord la serie " + (index - 1) + ".");
        }

        // 🛑 DELEGATION, JAMAIS RECOPIE : le tirage, la taille, le verrou de
        // competence et le refus « banque vide » restent chez leur autorite. Le
        // regime de passation (EXAMEN : aucune correction, audio une fois) est
        // pose par elles, a la creation de l'attempt.
        Skill skill = step.getSkill();
        AttemptResponse serie = skill != null
                ? attemptService.demarrerSerieDeCarte(userId, skill.getId())
                : civicPlanService.demarrerSerieSurUnite(
                        userId, step.getOfficialUnit().getCode(), AttemptMode.EXAMEN);

        Attempt attempt = attemptManager.findById(serie.id())
                .orElseThrow(() -> new EntityNotFoundException(
                        "Session introuvable juste apres sa creation : " + serie.id()));
        seriesManager.lier(step, index, attempt);
        log.info("Serie {} de l'etape {} lancee : attempt={} user={}",
                index, stepId, attempt.getId(), userId);
        return serie;
    }

    // ------------------------------------------------------------------ outils

    /**
     * L'etape, <b>si elle appartient bien a ce candidat</b> et si elle se
     * travaille par series.
     *
     * <p>🛑 <b>404 sur l'etape d'un autre</b>, jamais 403 : repondre « interdit »
     * confirmerait l'existence de l'etape, donc du cycle d'un tiers.
     */
    private JourneyStep etapeDuCandidat(UUID userId, UUID stepId) {
        JourneyStep step = stepManager.findDetail(stepId)
                .filter(s -> s.getJourney().getUser().getId().equals(userId))
                .orElseThrow(() -> new NotFoundException("Etape introuvable : " + stepId));
        if (!JourneyReadService.seTravailleParSeries(step)) {
            // Une competence d'expression se travaille par petits sujets, un
            // examen se passe : ni l'un ni l'autre n'a de cartes. On le DIT.
            throw new BusinessException(
                    "Cette etape ne se travaille pas par series de questions.");
        }
        return step;
    }

    /** La carte precedente est-elle reussie ? La carte 1 n'attend personne. */
    private boolean carteVerrouillee(JourneyStep step, int index) {
        if (index <= 1) return false;
        return essaisParCarte(step).getOrDefault(index - 1, List.<JourneyStepSeries>of())
                .stream()
                .noneMatch(essai -> verdict.reussie(essai.getAttempt()));
    }

    /**
     * Les essais de cette etape, groupes par carte, du plus ancien au plus
     * recent. <b>Une requete</b> (l'ordre vient du repository, pas d'un tri ici).
     */
    private Map<Integer, List<JourneyStepSeries>> essaisParCarte(JourneyStep step) {
        Map<Integer, List<JourneyStepSeries>> parCarte = new LinkedHashMap<>();
        for (JourneyStepSeries essai : seriesManager.findDesEtapes(List.of(step.getId()))) {
            parCarte.computeIfAbsent(essai.index(), cle -> new ArrayList<>()).add(essai);
        }
        return parCarte;
    }

    /**
     * L'unite travaillable en <b>detail</b> : code, libelle et la phrase
     * d'explication affichee sous le titre.
     *
     * <p>🛑 <b>La description est NULLABLE, et son absence n'invente rien.</b>
     * Cote TCF elle vient de {@code skills.description} ; cote <b>civique elle
     * n'existe pas</b> — {@code civic_official_units} ne porte pas la colonne,
     * et le libelle de l'annexe I est deja la phrase du programme. L'ecran
     * n'affiche alors rien, plutot qu'un texte fabrique.
     */
    private static JourneyUniteDetailDto unite(JourneyStep step) {
        Skill skill = step.getSkill();
        return new JourneyUniteDetailDto(
                skill != null ? skill.getCode() : step.getOfficialUnit().getCode(),
                step.uniteLabel(),
                skill == null ? null : skill.getDescription());
    }
}
