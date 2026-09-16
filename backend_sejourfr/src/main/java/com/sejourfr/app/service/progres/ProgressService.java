package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressDto;
import com.sejourfr.app.dto.TcfLevelProfile;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.LearningPlanSkillStatus;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.TcfDiagnosticSessionManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.PlanDomainAssessmentResolver;
import com.sejourfr.app.service.PlanFoundationResolver;
import com.sejourfr.app.service.SkillMasteryEngine;
import com.sejourfr.app.service.SkillMasteryResolver;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.TcfProfileService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticProgressionResolver;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticService;
import com.sejourfr.app.service.plancivique.CivicPlanService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Progrès</b> (T28, {@code 30_} §7) — « montrer le MOUVEMENT, pas un tableau
 * de bord ».
 *
 * <h2>Ce que ce service ne fait pas, et pourquoi</h2>
 *
 * <p>🛑 <b>Il ne calcule aucun niveau.</b> Le niveau TCF actuel vient de
 * {@link TcfProfileService} — « le SEUL endroit d'où sort ce niveau », règle du
 * dépôt — et l'objectif de {@link TcfDiagnosticService#cible(User)}, seule
 * autorité de la table démarche → palier. Le sens d'une évolution vient de
 * {@link TcfDiagnosticProgressionResolver#evolution}, écrit pour cet écran (L7).
 * Le statut d'une épreuve <b>face à l'objectif</b> vient de
 * {@link StatutObjectifResolver} — une comparaison de deux paliers déjà servis,
 * faite <b>serveur</b> pour qu'aucun front ne classe un niveau CECRL. Le détail
 * civique par thème vient du moteur du plan civique (L10), qui le produit déjà
 * pour l'écran Réviser. Cet écran <b>assemble</b>, il ne mesure pas.
 *
 * <p>🛑 <b>Il ne sert aucun pourcentage de progression vers un palier</b>
 * ({@code 30_} §7, règle explicite) : un palier CECRL n'est pas une barre.
 *
 * <p>🛑 <b>Il ne sert aucune série de flammes</b> ({@code 30_} §7). L'activité
 * se dit en jours travaillés, sans record à battre.
 *
 * <p>🛑 <b>Il ne re-liste pas l'historique</b> (bloc 5). Les écrans d'historique
 * existants le portent déjà ; le redupliquer créerait une seconde vérité.
 *
 * <p>🛑 <b>Il n'invente aucun parcours de mesure.</b> « Par quoi mesurer une
 * épreuve jamais évaluée » vient de {@link PlanDomainAssessmentResolver#pour},
 * la même autorité que « Compléter mon profil » et que la ligne
 * {@code A_EVALUER} de la séance ; et « le diagnostic est-il terminé ? » de
 * {@link PlanFoundationResolver}, la même que le Plan. Cet écran <b>assemble</b>,
 * il ne décide pas.
 *
 * <p>🛑 <b>Aucun appel LLM</b> : tout est relu.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProgressService {

    /** L'ordre d'affichage des 4 épreuves ({@code 30_} §7 bloc 2). */
    private static final List<EpreuveType> EPREUVES = List.of(
            EpreuveType.TCF_CO, EpreuveType.TCF_CE,
            EpreuveType.TCF_EE, EpreuveType.TCF_EO);

    /** Compétences tenues servies dans le bloc 3. Plafond d'AFFICHAGE. */
    private static final int DERNIERES_ACQUISES = 5;

    /** Le fuseau des jours travaillés — le même que le streak du tableau de bord. */
    private static final ZoneId PARIS = ZoneId.of("Europe/Paris");

    private final UserManager userManager;
    private final AttemptManager attemptManager;
    private final TcfDiagnosticSessionManager tcfSessionManager;
    private final TcfDiagnosticReadService tcfReadService;
    private final TcfDiagnosticService tcfDiagnosticService;
    private final TcfProfileService tcfProfileService;
    private final CivicDiagnosticSessionManager civicSessionManager;
    private final CivicDiagnosticViewService civicViewService;
    private final CivicPlanService civicPlanService;
    private final LearningPlanObservationManager observationManager;
    private final SkillMasteryResolver masteryResolver;
    private final SubscriptionService subscriptionService;
    private final ActiviteResolver activiteResolver;
    private final StatutObjectifResolver statutObjectifResolver;
    private final PlanFoundationResolver foundationResolver;
    private final PlanDomainAssessmentResolver assessmentResolver;

    @Transactional(readOnly = true)
    public ProgressDto progres(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));

        return new ProgressDto(
                activiteResolver.resoudre(
                        attemptManager.findActivityDates(userId), LocalDate.now(PARIS)),
                tcf(user),
                civique(userId));
    }

    // ------------------------------------------------------------------------
    // TCF
    // ------------------------------------------------------------------------

    private ProgressDto.Tcf tcf(User user) {
        NiveauCecrl objectif = tcfDiagnosticService.cible(user).orElse(null);

        // Du plus ANCIEN au plus recent : c'est le sens de lecture d'une courbe,
        // et l'ecran ne doit pas avoir a la retourner.
        List<TcfDiagnosticSession> clos =
                tcfSessionManager.findAllByUser(user.getId()).stream()
                        .filter(s -> s.getStatus() == TcfDiagnosticStatus.COMPLETED)
                        .sorted(Comparator.comparing(
                                TcfDiagnosticSession::getCompletedAt,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                        .toList();

        // 🛑 LA COURBE depend du diagnostic 4 epreuves, LES EPREUVES NON
        // (2026-09-16). Aucun diagnostic clos : il n'y a ni courbe ni palier
        // INITIAL a servir — mais les 4 epreuves existent quand meme, avec ce
        // qui a ete mesure par ailleurs (un examen blanc de module, une
        // section de diagnostic close isolement). Le verrou `clos.isEmpty()`
        // masquait la section « Ou vous en etes » de l'ACCUEIL en entier chez
        // un candidat qui avait pourtant deja une CO et une CE mesurees.
        List<ProgressDto.Estimation> historique = new ArrayList<>();
        Map<EpreuveType, NiveauCecrl> auPremier = new LinkedHashMap<>();
        for (int i = 0; i < clos.size(); i++) {
            TcfDiagnosticSession session = clos.get(i);
            List<TcfDiagnosticReadService.Section> sections = tcfReadService.sections(session);
            historique.add(new ProgressDto.Estimation(
                    session.getId(),
                    tcfReadService.niveauGlobal(sections).orElse(null),
                    session.getCompletedAt()));
            if (i == 0) {
                for (TcfDiagnosticReadService.Section section : sections) {
                    auPremier.put(section.epreuve(), section.niveau());
                }
            }
        }

        // 🛑 Le niveau ACTUEL d'une epreuve vient du profil TCF, pas du dernier
        // diagnostic : c'est le meilleur resultat toutes sources confondues, et
        // c'est la seule autorite du depot sur ce niveau.
        TcfLevelProfile profil = tcfProfileService.levelProfile(user.getId());
        // 🛑 « Le diagnostic est-il termine ? » a DEJA son autorite, partagee
        // avec le Plan et avec `PreparationDto.planDisponible` : on l'appelle,
        // on ne la recopie pas. C'est elle que `LearningPlanService` passe a ce
        // meme resolveur, donc la carte de l'Accueil et la carte du Plan ne
        // peuvent pas designer deux parcours differents pour le meme domaine.
        boolean diagnosticTermine = foundationResolver.resolve(user.getId()).exists();
        List<ProgressDto.Epreuve> epreuves = new ArrayList<>(EPREUVES.size());
        for (EpreuveType epreuve : EPREUVES) {
            NiveauCecrl actuel = actuel(profil, epreuve);
            NiveauCecrl initial = auPremier.get(epreuve);
            epreuves.add(new ProgressDto.Epreuve(
                    epreuve, actuel, initial,
                    // 🛑 INCONNUE n'est pas STABLE : une epreuve non evaluee
                    // d'un cote n'a ni progresse ni tenu.
                    TcfDiagnosticProgressionResolver.evolution(initial, actuel),
                    // 🛑 Le statut vers l'objectif est DERIVE SERVEUR, a partir
                    // des deux paliers deja servis : aucun front ne compare des
                    // niveaux CECRL lui-meme.
                    statutObjectifResolver.resoudre(actuel, objectif),
                    // 🛑 Rien a lancer sur une epreuve DEJA mesuree : on ne
                    // propose pas de refaire une mesure qui existe.
                    actuel == null
                            ? assessmentResolver.pour(epreuve, diagnosticTermine)
                            : null));
        }

        return new ProgressDto.Tcf(
                // 🛑 Fidele a son sens : « un diagnostic 4 epreuves est clos ».
                // Il commande la courbe et le palier global de l'ecran Progres,
                // plus la liste des epreuves.
                !clos.isEmpty(), profil.globalLevel(), objectif, historique, epreuves,
                competences(user.getId()));
    }

    private static NiveauCecrl actuel(TcfLevelProfile profil, EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO -> profil.co();
            case TCF_CE -> profil.ce();
            case TCF_EE -> profil.ee();
            case TCF_EO -> profil.eo();
            default -> null;
        };
    }

    // ------------------------------------------------------------------------
    // Bloc 3 — les competences
    // ------------------------------------------------------------------------

    /**
     * « 4 compétences maîtrisées sur 11 travaillées ».
     *
     * <p>🛑 <b>Les compteurs sont servis MÊME verrouillés.</b> C'est le
     * <b>détail</b> qui est premium, pas le fait d'avoir progressé : cacher le
     * nombre reviendrait à cacher au candidat ce qu'il a lui-même produit.
     *
     * <p>🛑 <b>« Travaillée » = observée</b>, pas « affichée dans un plan ». Une
     * compétence sortie des priorités parce que son transfert est prouvé reste
     * travaillée — elle est même le cas le plus intéressant.
     */
    private ProgressDto.Competences competences(UUID userId) {
        // Lu UNE fois : le verrou sert les deux sorties de cette methode, et
        // `hasTcf` est une lecture d'abonnement, pas un booleen en memoire.
        boolean locked = !subscriptionService.hasTcf(userId);

        List<LearningPlanObservation> observations =
                observationManager.findAllByUserWithSkill(userId);
        if (observations.isEmpty()) {
            return new ProgressDto.Competences(0, 0, List.of(), locked);
        }

        Map<UUID, Skill> parSkill = new LinkedHashMap<>();
        Map<UUID, Instant> dernierePreuve = new LinkedHashMap<>();
        for (LearningPlanObservation observation : observations) {
            Skill skill = observation.getSkill();
            if (skill == null) continue;
            parSkill.putIfAbsent(skill.getId(), skill);
            if (observation.getStatus() != LearningPlanSkillStatus.SOLID) continue;
            Instant quand = observation.getObservedAt();
            if (quand == null) continue;
            dernierePreuve.merge(skill.getId(), quand,
                    (a, b) -> a.isAfter(b) ? a : b);
        }

        Map<UUID, SkillMasteryEngine.SkillMastery> maitrise =
                masteryResolver.bySkillIds(userId, parSkill.keySet());

        // 🛑 « Maitrisee » se lit sur transferProven, la MEME autorite que
        // `completedSteps` et que `PlanSkillStepState.ACQUIS` — pas sur
        // `state() == SOLID`. Le parcours normal (5 petits sujets puis une
        // verification reussie) plafonne autour de 0,68 et n'atteint jamais
        // SOLID : cet ecran annoncait « 0 competence maitrisee » pendant que le
        // Plan de la meme app cochait les memes competences « acquises ».
        List<ProgressDto.CompetenceAcquise> tenues = parSkill.values().stream()
                .filter(s -> {
                    SkillMasteryEngine.SkillMastery m = maitrise.get(s.getId());
                    return m != null && m.transferProven();
                })
                .map(s -> new ProgressDto.CompetenceAcquise(
                        s.getId(), s.getCode(), s.getTitle(), s.getSection(),
                        dernierePreuve.get(s.getId())))
                .sorted(Comparator.comparing(
                        ProgressDto.CompetenceAcquise::preuveA,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();

        return new ProgressDto.Competences(
                parSkill.size(),
                tenues.size(),
                // 🛑 Verrouille : les compteurs restent, le DETAIL disparait.
                locked ? List.of() : tenues.stream().limit(DERNIERES_ACQUISES).toList(),
                locked);
    }

    // ------------------------------------------------------------------------
    // Civique
    // ------------------------------------------------------------------------

    private ProgressDto.Civique civique(UUID userId) {
        List<CivicDiagnosticSession> clos =
                civicSessionManager.findAllByUser(userId).stream()
                        .filter(s -> s.getStatus() == TcfDiagnosticStatus.COMPLETED)
                        .sorted(Comparator.comparing(
                                CivicDiagnosticSession::getCompletedAt,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                        .toList();

        if (clos.isEmpty()) {
            return new ProgressDto.Civique(false, List.of(), 0, 0, false, List.of());
        }

        List<ProgressDto.Score> historique = clos.stream()
                .map(civicViewService::resultat)
                .map(r -> new ProgressDto.Score(
                        r.sessionId(), r.bonnes(), r.posees(),
                        r.seuilReussite(), r.formatQuestions(), r.completedAt()))
                .toList();

        // 🛑 Les compteurs viennent du moteur du plan (L10), sur TOUTES les
        // cibles : les recompter ici en ferait une seconde verite, et compter
        // sur les priorites servies afficherait « 3 » quel que soit le reel.
        // Le DETAIL par theme sort du MEME appel : le moteur civique se relit
        // en entier a chaque lecture, et le rappeler une seconde fois pour la
        // meme requete HTTP doublerait son cout sans rien changer au resultat.
        CivicPlanService.Compteurs compteurs = civicPlanService.compteurs(userId);

        return new ProgressDto.Civique(
                true, historique,
                compteurs.travaillees(), compteurs.maitrisees(),
                compteurs.grainNotion(), compteurs.themes());
    }
}
