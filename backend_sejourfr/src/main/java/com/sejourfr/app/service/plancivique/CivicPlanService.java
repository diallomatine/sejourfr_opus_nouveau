package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.config.CivicPlanProperties;
import com.sejourfr.app.dto.CivicDiagnosticResultDto;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.CivicOfficialUnit;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptMode;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.CivicNotionManager;
import com.sejourfr.app.manager.CivicOfficialUnitManager;
import com.sejourfr.app.manager.CivicPlanManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.mapper.AttemptMapper;
import com.sejourfr.app.service.SubscriptionService;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticViewService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Le plan civique</b> (L10, {@code 20_} §5 et §6) : ce qu'il reste a
 * travailler, dans quel ordre, et quand y revenir.
 *
 * <h2>Trois decisions qui expliquent tout le reste</h2>
 *
 * <p>🛑 <b>1. Rien n'est persiste.</b> Ni {@code civic_plan}, ni
 * {@code civic_plan_item}, ni {@code user_civic_notion_progress} — les trois
 * tables que {@code 20_} §10 prevoyait. L'etat Leitner se <b>replie</b> sur
 * l'historique des reponses a chaque lecture ({@link CivicLeitnerResolver}), ce
 * qui a rapporte le <b>tagging retroactif</b> : la campagne du 2026-09-11 a
 * tague 783 questions d'un coup, et <b>toutes</b> les reponses deja donnees ont
 * compte pour leur notion le jour meme. Une table de progression serait nee vide
 * et le serait restee.
 *
 * <p>🛑 <b>2. Le grain se mesure, thème par thème.</b> Tant qu'un theme n'a pas
 * franchi le seuil de tagging, le plan y travaille <b>par theme</b> — le mode
 * degrade que {@code 20_} §3.3 prevoit noir sur blanc, pas une panne. Attendre
 * le tagging complet pour offrir quoi que ce soit priverait le candidat de ce
 * qui est deja mesurable.
 *
 * <p>⚠️ <b>Au 2026-09-19, les cinq themes sont au grain NOTION</b> (97 — 98,6 %).
 * Le mode degrade n'est plus emprunte ; il reste code pour un theme neuf.
 *
 * <p>🛑 <b>3. Un theme n'est jamais « maitrise ».</b> Une notion se tient sur
 * quelques questions ; un theme en porte deux cents. Repondre juste quatre fois
 * de suite sur un theme ne prouve rien, et l'annoncer « maitrise » reproduirait
 * exactement le defaut que le depot nomme « NON FRAGILE ≠ PLUS RIEN A
 * APPRENDRE ». Le garde-fou ne peut qu'<b>abaisser</b> : il rabat
 * {@code MAITRISEE} sur {@code EN_PROGRESSION} au grain theme, jamais l'inverse.
 *
 * <p>🛑 <b>Aucun cout LLM</b> : le civique est du QCM deterministe.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CivicPlanService {

    private final UserManager userManager;
    private final ThemeManager themeManager;
    private final CivicNotionManager notionManager;
    private final CivicPlanManager planManager;
    private final CivicDiagnosticSessionManager sessionManager;
    private final CivicDiagnosticViewService diagnosticViewService;
    private final CivicLeitnerResolver leitnerResolver;
    private final CivicChangementsResolver changementsResolver;
    private final CivicPrioriteScorer scorer;
    private final SubscriptionService subscriptionService;
    private final AttemptMapper attemptMapper;
    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final QuestionManager questionManager;
    private final CivicOfficialUnitManager unitManager;
    private final CivicPlanProperties props;

    /**
     * <b>Le calcul complet</b> : TOUTES les cibles, classees, avant toute
     * troncature d'affichage.
     *
     * <p>🛑 <b>Il existe parce que deux lecteurs en ont besoin, et qu'ils n'ont
     * pas le meme droit de couper</b> : {@link #plan} tronque pour l'ecran,
     * {@link #compteurs} ne tronque <b>jamais</b>. Faire lire les compteurs dans
     * le DTO deja tronque, c'etait servir un plafond d'affichage comme budget de
     * mesure — le defaut qui a prive trois domaines sur quatre de toute action
     * cote TCF (2026-08-25).
     *
     * @param cibles toutes les cibles du plan, dans l'ordre du plan
     */
    private record Calcul(
            boolean disponible,
            Difficulty mention,
            CivicDiagnosticResultDto resultat,
            List<CivicPlanDto.Cible> cibles,
            List<Theme> themes,
            Map<UUID, List<CivicReponse>> reponsesParCible,
            Map<UUID, long[]> taggage,
            Instant maintenant) {

        static Calcul indisponible(Difficulty mention, Instant maintenant) {
            return new Calcul(false, mention, null, List.of(), List.of(),
                    Map.of(), Map.of(), maintenant);
        }
    }

    @Transactional(readOnly = true)
    public CivicPlanDto plan(UUID userId) {
        Calcul calcul = calculer(userId);
        if (!calcul.disponible()) {
            return new CivicPlanDto(
                    false, calcul.mention(), null, null, List.of(), 0, List.of(), List.of(),
                    List.of(), grain(Map.of()), null, calcul.maintenant());
        }
        return mettreEnForme(calcul);
    }

    /**
     * <b>L'ordre du plan derive, SANS plafond d'affichage</b> — pour le cycle.
     *
     * <p>🛑 <b>Le cycle NE RECLASSE RIEN</b> (D-36 : il se superpose au plan
     * derive). Il lit <b>cet</b> ordre, celui de {@link CivicPrioriteScorer}, et
     * le projette sur les unites officielles. Un second ordre — « mieux adapte
     * au cycle » — aurait fait dire deux choses differentes au meme candidat
     * selon l'ecran qu'il regarde.
     *
     * <p>🛑 <b>Et il lit {@code proposables}, pas {@code priorites}</b> : les
     * deux ont la meme tete, mais {@code priorites} est <b>plafonnee a
     * l'affichage</b> (trois). Batir un cycle dessus reviendrait a servir un
     * plafond d'ecran comme un budget pedagogique — le defaut qui a prive trois
     * domaines sur quatre de toute action cote TCF (2026-08-25).
     *
     * @return l'evaluation source et les cibles dans l'ordre. <b>Vide</b> quand
     *         aucun diagnostic n'est termine : le plan n'existe pas encore, et
     *         il n'y a donc rien a projeter.
     */
    @Transactional(readOnly = true)
    public OrdreDuPlan ordrePourLeCycle(UUID userId) {
        return ordre(calculer(userId));
    }

    /**
     * <b>Le meme ordre, mais celui du diagnostic NOMME</b> — ce que le cycle
     * lit quand une evaluation {@code CIVIC_DIAGNOSTIC} vient de se terminer.
     *
     * <h3>🛑 Pourquoi il ne peut pas passer par {@link #ordrePourLeCycle}</h3>
     * <p>{@code ordrePourLeCycle} lit « le <b>dernier</b> diagnostic
     * <b>COMPLETED</b> ». Or ⟦SQL⟧ sur la base de dev : un diagnostic civique
     * passe a {@code COMPLETED} a l'appel de
     * {@code POST /api/civic-diagnostics/{id}/result}, <b>apres</b>
     * {@code POST /api/attempts/{id}/finish} qui est ce qui porte l'evaluation
     * au cycle (mesure : {@code civic_diagnostic_sessions.completed_at} est
     * <b>egal a la microseconde</b> a {@code attempts.finished_at}, donc recopie
     * par la cloture paresseuse du {@code /result}, et
     * {@code journey_assessment_event.processed_at} lui est <b>posterieur</b>).
     * Au moment ou le cycle traite le diagnostic, la session est donc encore
     * {@code IN_PROGRESS} en base, et « le dernier termine » ne rend
     * <b>rien</b>.
     *
     * <p>🛑 <b>Et c'est plus juste, pas seulement plus pratique</b> :
     * l'evaluation <b>dit</b> de quel diagnostic elle parle (son
     * {@code sourceAssessmentId}, A08). « Le dernier termine » est une
     * <b>seconde</b> definition de la meme chose, qui peut designer une AUTRE
     * session — celle qu'un candidat vient d'ouvrir pendant qu'une correction
     * traine.
     *
     * <p>⚠️ <b>Le statut de la session n'est pas relu ici</b>, et c'est
     * volontaire : la seule autorite de « cette session est-elle finie ? » est
     * {@code CivicDiagnosticService}, et le fait qui compte est deja porte par
     * l'appelant — une {@code JourneyEvaluation} n'existe que pour une
     * evaluation <b>terminee</b>. Le resultat, lui, se calcule sur ce qui a ete
     * <b>pose et repondu</b>, exactement comme l'ecran de resultat.
     *
     * @param sessionId la {@code civic_diagnostic_sessions} nommee par
     *                  l'evaluation. <b>Vide</b> si elle n'existe pas ou si elle
     *                  n'appartient pas a ce candidat — une cle tiree ailleurs ne
     *                  peut jamais construire le cycle d'un tiers.
     */
    @Transactional(readOnly = true)
    public OrdreDuPlan ordreDuDiagnostic(UUID userId, UUID sessionId) {
        return ordre(calculer(userId, diagnosticNomme(userId, sessionId)));
    }

    private OrdreDuPlan ordre(Calcul calcul) {
        if (!calcul.disponible()) return OrdreDuPlan.VIDE;
        return new OrdreDuPlan(
                calcul.resultat().sessionId(), proposables(calcul.cibles()));
    }

    private Optional<CivicDiagnosticResultDto> diagnosticNomme(UUID userId, UUID sessionId) {
        if (sessionId == null) return Optional.empty();
        return sessionManager.findById(sessionId)
                .filter(session -> session.getUser() != null
                        && session.getUser().getId().equals(userId))
                .map(this::resultat);
    }

    /**
     * @param sourceAssessmentId le diagnostic qui a produit cet ordre — ce que
     *                           le lot du cycle journalise comme sa source.
     * @param cibles             dans l'ordre du plan, sans plafond.
     */
    public record OrdreDuPlan(UUID sourceAssessmentId, List<CivicPlanDto.Cible> cibles) {
        static final OrdreDuPlan VIDE = new OrdreDuPlan(null, List.of());

        public boolean estVide() {
            return cibles.isEmpty();
        }
    }

    /**
     * Le calcul de l'ecran : il se batit sur <b>le dernier diagnostic
     * termine</b>.
     *
     * <p>🛑 <b>Le plan ne se batit pas sur une mesure qui n'existe pas.</b> Sans
     * diagnostic termine, on ne sert AUCUNE cible : l'ecran ouvre la seule porte
     * qui debloque, il n'affiche pas un plan vide.
     */
    private Calcul calculer(UUID userId) {
        return calculer(userId, dernierDiagnostic(userId));
    }

    /**
     * Le meme calcul, sur <b>le diagnostic qu'on lui donne</b>.
     *
     * <p>🛑 <b>Extrait pour qu'il n'existe qu'UN classement de cibles</b> : le
     * cycle lit celui du diagnostic qu'il traite ({@link #ordreDuDiagnostic}),
     * l'ecran celui du dernier termine, et c'est <b>le meme code</b>. Une
     * seconde version « pour le cycle » aurait fait dire deux choses
     * differentes au meme candidat selon l'ecran qu'il regarde (D-36).
     */
    private Calcul calculer(UUID userId, Optional<CivicDiagnosticResultDto> diagnostic) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        Difficulty mention = TargetProcedure.mentionCivique(user.getTargetProcedure());
        Instant maintenant = Instant.now();

        if (diagnostic.isEmpty()) {
            return Calcul.indisponible(mention, maintenant);
        }
        CivicDiagnosticResultDto resultat = diagnostic.get();

        Map<UUID, long[]> taggage = planManager.taggageParTheme();
        List<Theme> themes = themeManager.findByModuleOrderedByDisplayOrder(Module.CIVIQUE);
        List<CivicReponse> reponses = planManager.reponses(userId);
        boolean abonne = subscriptionService.hasCivique(userId);
        // 🛑 Charges UNE fois, pas une fois par theme. Ce sont des lectures de
        // catalogue : les repeter par theme multiplierait le cout par cinq sans
        // rien changer au resultat.
        // ⚠️ P8.2b : plus de filtre de mention. Ces comptes restent utiles au
        // GRAIN du plan derive (combien une cible peut servir), mais ils ne
        // DECIDENT plus rien -- `CivicDotation` a disparu avec le filtre.
        Map<UUID, Long> stockParNotion = planManager.questionsParNotion();
        Map<UUID, Long> stockParTheme = planManager.questionsParTheme();
        List<CivicNotion> notions = notionManager.findAllOrdonnees();
        Map<UUID, List<CivicReponse>> reponsesParNotion = grouperParNotion(reponses);

        List<CivicPlanDto.Cible> cibles = new ArrayList<>();
        // Les reponses de chaque cible, gardees pour le bloc « progression
        // detectee » : il rejoue l'etat d'il y a une semaine sur exactement les
        // memes reponses, plutot que de persister un snapshot.
        Map<UUID, List<CivicReponse>> reponsesParCible = new HashMap<>();
        for (Theme theme : themes) {
            CivicThemeState etatDuTheme = etatDuTheme(resultat, theme.getId());
            boolean pointeParLeDiagnostic = resultat.priorites().stream()
                    .anyMatch(p -> p.themeId().equals(theme.getId()));

            if (grainDuTheme(taggage.get(theme.getId())) == CivicPlanGrain.NOTION) {
                List<CivicPlanDto.Cible> duTheme = ciblesNotions(theme, etatDuTheme,
                        notions, stockParNotion, reponsesParNotion, maintenant, abonne);
                cibles.addAll(duTheme);
                for (CivicPlanDto.Cible cible : duTheme) {
                    reponsesParCible.put(cible.id(),
                            reponsesParNotion.getOrDefault(cible.id(), List.of()));
                }
            } else {
                CivicPlanDto.Cible cible = cibleTheme(theme, etatDuTheme,
                        pointeParLeDiagnostic, stockParTheme, reponses, maintenant, abonne);
                cibles.add(cible);
                reponsesParCible.put(cible.id(), reponses.stream()
                        .filter(r -> theme.getId().equals(r.themeId()))
                        .toList());
            }
        }

        // 🛑 L'ordre du plan est SERVI : les fronts ne retrient jamais. Score
        // decroissant, puis les departages de 20_ §5.3 — ce qui a ete vu et
        // rate passe devant ce qui n'a jamais ete touche.
        cibles.sort(ORDRE_DU_PLAN);

        return new Calcul(true, mention, resultat, List.copyOf(cibles), List.copyOf(themes),
                reponsesParCible, taggage, maintenant);
    }

    /**
     * Du calcul complet a l'ecran : c'est <b>ici</b>, et nulle part ailleurs,
     * que les plafonds d'affichage s'appliquent.
     */
    private CivicPlanDto mettreEnForme(Calcul calcul) {
        List<CivicPlanDto.Cible> cibles = calcul.cibles();
        CivicDiagnosticResultDto resultat = calcul.resultat();
        Instant maintenant = calcul.maintenant();

        List<CivicPlanDto.Cible> proposables = proposables(cibles);
        // 🛑 Plafond d'AFFICHAGE, jamais un budget de calcul : le moteur a
        // classe TOUTES les cibles, l'ecran en montre trois et COMPTE le reste.
        List<CivicPlanDto.Cible> priorites =
                proposables.stream().limit(props.getPrioritesVisibles()).toList();

        List<CivicPlanDto.Cible> aRevoir = cibles.stream()
                .filter(c -> c.maitrise() == CivicMaitrise.MAITRISEE)
                .filter(CivicPlanDto.Cible::aRevoir)
                .sorted(Comparator.comparing(
                        CivicPlanDto.Cible::prochaineRevue,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .limit(props.getRevisionsVisibles())
                .toList();

        // ⚠️ Le filtre par dotation a disparu avec P8.2b, et le cas qu'il
        // protegeait AUSSI : « une cible maitrisee puis devenue non servable
        // parce que le candidat change de mention » ne peut plus exister --
        // la mention ne filtre plus rien.
        List<CivicPlanDto.Cible> solides = cibles.stream()
                .filter(c -> c.maitrise() == CivicMaitrise.MAITRISEE)
                .filter(c -> !c.aRevoir())
                .toList();

        CivicPlanDto.Cible prochaine = prochaine(proposables);

        // 🛑 `null` est le cas NORMAL : servi seulement si quelque chose a
        // vraiment bouge. Le temps qui passe n'est pas un changement.
        // 🛑 « Progression detectee » ne parle que de cibles SERVABLES. Une
        // notion non servable touchee pendant le diagnostic pouvait y etre
        // nommee alors qu'elle n'a de carte NULLE PART ailleurs dans le plan :
        // le candidat lisait un progres sur un point qu'il ne peut pas
        // travailler, et sur lequel il ne peut pas revenir.
        List<CivicPlanDto.Cible> servables = cibles.stream()
                .toList();
        CivicPlanDto.Changements changements = changementsResolver
                .resoudre(servables, calcul.reponsesParCible(), prochaine,
                        CivicPrioriteScorer.FENETRE_REPETEE, maintenant)
                .orElse(null);

        return new CivicPlanDto(
                true,
                calcul.mention(),
                new CivicPlanDto.Resultat(
                        resultat.bonnes(), resultat.posees(),
                        resultat.seuilReussite(), resultat.formatQuestions(),
                        resultat.completedAt()),
                prochaine,
                priorites,
                Math.max(0, proposables.size() - priorites.size()),
                aRevoir,
                solides,
                themeLignes(calcul, prochaine),
                grain(calcul.taggage()),
                changements,
                maintenant);
    }

    /**
     * Les cibles que le plan peut <b>proposer</b>, dans l'ordre servi.
     *
     * <p>🛑 Seul SERVABLE est propose. {@code NON_APPLICABLE} n'est pas un cran
     * de plus dans le manque : la notion n'est pas au programme de cette
     * demarche, elle n'a rien a faire dans un plan.
     *
     * <p>Extrait a sa 2ᵉ occurrence : {@code mettreEnForme} (l'ecran Plan) et
     * {@code compteurs} (l'ecran Progres) designent ainsi <b>la meme</b> cible
     * du moment — deux filtres recopies auraient fini par en designer deux.
     */
    private static List<CivicPlanDto.Cible> proposables(List<CivicPlanDto.Cible> cibles) {
        return cibles.stream()
                .filter(c -> c.maitrise() != CivicMaitrise.MAITRISEE)
                .toList();
    }

    /**
     * La cible que le plan travaille <b>maintenant</b>, ou {@code null}.
     *
     * <p>Se lit sur {@code proposables} et non sur {@code priorites} : les deux
     * ont la meme tete, mais {@code priorites} est <b>plafonnee a
     * l'affichage</b> — s'appuyer dessus ferait dependre une designation d'un
     * reglage d'ecran.
     */
    private static CivicPlanDto.Cible prochaine(List<CivicPlanDto.Cible> proposables) {
        return proposables.isEmpty() ? null : proposables.getFirst();
    }

    /**
     * <b>Les cinq themes, vus de l'ecran Reviser.</b>
     *
     * <p>🛑 Les compteurs se prennent sur {@code calcul.cibles()} — <b>toutes</b>
     * les cibles classees —, jamais sur {@code priorites} / {@code aRevoir} /
     * {@code solides}, qui sont plafonnees juste au-dessus. Compter dans une
     * liste tronquee servirait un plafond d'affichage comme un budget de mesure.
     *
     * <p>Les cinq themes sont <b>toujours</b> rendus, dans l'ordre d'affichage
     * du module : un theme sans aucune cible servable n'est pas absent de
     * l'ecran, il est a zero.
     */
    private List<CivicPlanDto.ThemeLigne> themeLignes(
            Calcul calcul, CivicPlanDto.Cible prochaine) {
        Map<UUID, List<CivicPlanDto.Cible>> parTheme = new LinkedHashMap<>();
        for (CivicPlanDto.Cible cible : calcul.cibles()) {
            parTheme.computeIfAbsent(cible.themeId(), k -> new ArrayList<>()).add(cible);
        }

        List<CivicPlanDto.ThemeLigne> lignes = new ArrayList<>();
        for (Theme theme : calcul.themes()) {
            List<CivicPlanDto.Cible> cibles = parTheme.getOrDefault(theme.getId(), List.of());
            int maitrisees = 0;
            int travaillees = 0;
            for (CivicPlanDto.Cible cible : cibles) {
                if (cible.maitrise() == CivicMaitrise.MAITRISEE) maitrisees++;
                if (cible.reponses() > 0) travaillees++;
            }
            // Au plus un theme porte la cible du moment : c'est `prochaine`,
            // lue chez la meme autorite que le Plan. L'ecran Reviser ne peut
            // donc pas designer une autre notion que lui.
            CivicPlanDto.CibleRef enCours =
                    prochaine != null && theme.getId().equals(prochaine.themeId())
                            ? new CivicPlanDto.CibleRef(prochaine.id(), prochaine.code(),
                                    prochaine.label(), prochaine.grain())
                            : null;
            lignes.add(new CivicPlanDto.ThemeLigne(
                    theme.getId(),
                    theme.getCode(),
                    theme.getName(),
                    etatDuTheme(calcul.resultat(), theme.getId()),
                    grainDuTheme(calcul.taggage().get(theme.getId())),
                    cibles.size(),
                    maitrisees,
                    travaillees,
                    enCours));
        }
        return List.copyOf(lignes);
    }



    /**
     * Ce que l'ecran <b>Progres</b> (T28) compte : combien de cibles ont ete
     * travaillees, et combien sont tenues.
     *
     * <p>🛑 <b>Compte sur TOUTES les cibles, jamais sur {@code priorites}</b> :
     * cette liste est plafonnee a trois par regle d'affichage, et compter dessus
     * afficherait « 3 » quel que soit le nombre reel. C'est exactement le defaut
     * qui a prive trois domaines sur quatre de toute action cote TCF
     * (2026-08-25).
     *
     * <p>🛑 <b>« Travaillee » veut dire TRAVAILLEE</b> : au moins une reponse
     * sur cette cible. Le compteur a d'abord ete derive du DTO
     * ({@code solides + aRevoir} pour les tenues, {@code priorites +
     * autresPriorites} pour le reste), ce qui comptait comme travaillee toute
     * cible <b>proposable</b> — y compris celles que le candidat n'a jamais
     * vues. Au grain THEME le defaut etait presque invisible (un diagnostic de
     * 40 questions touche les cinq themes) ; <b>au grain NOTION il devient
     * faux de plein fouet</b> : le meme diagnostic laisse la plupart des
     * 46 notions sans une seule reponse, et l'ecran Progres annoncait
     * « 2 maitrisees sur 30 travaillees » a quelqu'un qui en avait vu huit.
     * Le compteur se lit donc sur les <b>faits d'historique</b>, jamais sur
     * l'eligibilite.
     *
     * <p>🛑 Et il se lit sur <b>toutes</b> les cibles, jamais sur les listes du
     * DTO : {@code priorites} est plafonnee a trois et {@code aRevoir} aussi —
     * compter dessus faisait servir un plafond d'affichage comme budget de
     * mesure, exactement le defaut qui a prive trois domaines sur quatre de
     * toute action cote TCF (2026-08-25).
     *
     * <p>Tout a zero quand aucun diagnostic n'est clos : rien n'a ete mesure.
     *
     * @param travaillees cibles portant au moins une reponse
     * @param maitrisees  dont l'etat servi est {@code MAITRISEE}
     * @param grainNotion le plan travaille-t-il deja par notion ? L'ecran doit
     *                    pouvoir <b>nommer</b> ce qu'il compte
     * @param themes      le <b>detail par theme</b> — exactement les lignes du
     *                    Plan / de Reviser, {@code CivicThemeState} brut. 🛑
     *                    Aucun second calcul de maitrise : on <b>reexpose</b>
     *                    ce que le moteur vient de produire, dans le meme
     *                    {@code calculer(userId)}, donc sans une requete de
     *                    plus. Vide quand aucun diagnostic n'est clos
     */
    public record Compteurs(
            int travaillees,
            int maitrisees,
            boolean grainNotion,
            List<CivicPlanDto.ThemeLigne> themes) {
    }

    @Transactional(readOnly = true)
    public Compteurs compteurs(UUID userId) {
        Calcul calcul = calculer(userId);
        if (!calcul.disponible()) return new Compteurs(0, 0, false, List.of());

        int travaillees = (int) calcul.cibles().stream()
                .filter(c -> c.reponses() > 0)
                .count();
        // `maitrisees` est un sous-ensemble par construction : MAITRISEE exige
        // deux reponses (CivicMaitrise.of), donc les deux compteurs ne peuvent
        // plus se croiser.
        int maitrisees = (int) calcul.cibles().stream()
                .filter(c -> c.maitrise() == CivicMaitrise.MAITRISEE)
                .count();
        return new Compteurs(
                travaillees, maitrisees,
                grain(calcul.taggage()).courant() == CivicPlanGrain.NOTION,
                // La MEME autorite que l'ecran Plan, appelee sur le MEME calcul
                // — deux lectures du meme candidat ne peuvent donc pas rendre
                // deux etats differents pour un theme.
                themeLignes(calcul, prochaine(proposables(calcul.cibles()))));
    }

    // ------------------------------------------------------------------------
    // La serie ciblee
    // ------------------------------------------------------------------------

    /**
     * Ouvre la <b>serie ciblee</b> d'une cible du plan ({@code 20_} §6 bloc 2).
     *
     * <p>🛑 <b>C'est un {@code TRAINING} ordinaire</b> : le candidat le joue
     * dans le runner de questions existant, avec correction immediate. Aucun
     * ecran de passation n'est cree, et aucun slot d'examen blanc n'est
     * consomme.
     *
     * <p>🛑 <b>Le verrou est opposable ici</b>, pas seulement affiche : le
     * {@code locked} du plan et ce refus sont la MEME regle. Un ecran dont le
     * statut premium en cache est perime recoit un 403 la ou son interface
     * croyait la serie ouverte — c'est un refus attendu, que les fronts routent
     * vers l'offre.
     *
     * @param grain {@code NOTION} ou {@code THEME} — c'est le plan qui l'a dit,
     *              l'appelant le renvoie tel quel plutot que de deviner la
     *              nature d'un identifiant
     */
    /**
     * <b>Une serie ciblee sur une UNITE OFFICIELLE</b> — l'action d'une etape du
     * cycle civique (D-48, P8.7).
     *
     * <p>🛑 <b>Pourquoi elle ne passe pas par {@link #demarrerSerie}</b> : celle-la
     * travaille une <b>cible du plan derive</b> — une notion, ou un theme en
     * mode degrade. Une etape du <b>cycle</b>, elle, porte une <b>unite
     * officielle</b> : c'est le grain de l'arrete, et une unite regroupe
     * jusqu'a 8 notions. Faire passer un id d'unite pour un id de cible aurait
     * rate la cible dans le plan et rendu un 404 incomprehensible.
     *
     * <p>🛑 <b>Le tirage est celui du PROGRAMME</b> ({@code D-48}) : les
     * questions de l'unite, plus les mises en situation de sa thematique quand
     * l'unite EST celle des mises en situation. C'est le meme tirage que la
     * composition d'examen — <b>une seule autorite</b> sur « quelles questions
     * appartiennent a cette unite ».
     *
     * <p>🛑 <b>Premium</b> (D-33) : travailler une unite depuis le Plan fait
     * partie de l'abonnement. Meme refus, meme phrase que la serie ciblee.
     */
    @Transactional
    public AttemptResponse demarrerSerieSurUnite(UUID userId, String uniteCode) {
        return demarrerSerieSurUnite(userId, uniteCode, AttemptMode.ENTRAINEMENT);
    }

    /**
     * La <b>meme</b> serie, dans le regime de passation demande.
     *
     * <p>🛑 <b>Une seule composition, deux appelants</b> : le Plan civique
     * (correction immediate) et la <b>carte d'etape du cycle</b>
     * ({@link AttemptMode#EXAMEN} — aucune correction pendant la passation).
     * Dupliquer le tirage pour changer un enum aurait fait deux series qui
     * n'ont pas le meme contenu sous le meme nom.
     */
    @Transactional
    public AttemptResponse demarrerSerieSurUnite(
            UUID userId, String uniteCode, AttemptMode mode) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        if (!subscriptionService.hasCivique(userId)) {
            throw new AccessDeniedException(
                    "Les series ciblees font partie de l'abonnement. "
                            + "Votre plan, lui, reste entier.");
        }
        // 🛑 Par CODE, pas par id : le code est l'identifiant STABLE du
        // referentiel (`P2_LAICITE`), celui que le contrat sert deja dans
        // `JourneyUniteRefDto`. Servir un uuid en plus aurait ajoute un second
        // identifiant de la meme chose sur le fil.
        CivicOfficialUnit unite = unitManager.findAllDansLOrdreDuProgramme().stream()
                .filter(u -> u.getCode().equals(uniteCode))
                .findFirst()
                .orElseThrow(() -> new NotFoundException(
                        "Cette unite ne fait pas partie du programme."));

        int taille = props.getQuestionsParSerie();
        List<Question> questions = new ArrayList<>(
                unite.getQuestionType() == QuestionType.MISE_SITUATION
                        ? questionManager.findRandomMisesEnSituationExcluding(
                                unite.getThemeCode(), null, List.of(), taille)
                        : questionManager.findRandomByOfficialUnitExcluding(
                                unite.getId(), null, List.of(), taille));
        completerParLaThematique(questions, unite, taille);
        if (questions.isEmpty()) {
            // 🛑 On le DIT, on ne rend jamais une serie vide : un runner sans
            // question est pire qu'un refus.
            throw new BusinessException(
                    "Aucune question disponible sur cette unité pour l'instant.");
        }

        Attempt attempt = nouvelleSerie(user, questions, mode);
        log.info("Serie civique sur unite : attempt={} user={} unite={} questions={}",
                attempt.getId(), userId, unite.getCode(), questions.size());
        List<AttemptQuestion> lignes =
                attemptQuestionManager.findByAttemptOrderedByPosition(attempt.getId());
        return attemptMapper.toResponse(attempt, lignes, false);
    }

    /**
     * <b>Completer une serie trop mince par les questions de la MEME
     * THEMATIQUE</b> (2026-09-20).
     *
     * <p>🛑 <b>Priorite absolue aux questions de l'unite</b> : le complement
     * n'intervient qu'apres, et n'entame jamais la place des questions de
     * l'unite. Il existe parce qu'une unite officielle peut porter moins de 20
     * questions — servir une serie de 12 la ou l'ecran a annonce 20, et ou le
     * seuil de reussite est calcule sur 20, aurait rendu la carte
     * <b>impossible a valider</b>.
     *
     * <p>Les questions deja tirees sont exclues : une serie ne montre jamais
     * deux fois la meme question. Le tirage reste <b>aleatoire</b>, donc varie
     * d'un essai a l'autre — c'est ce qui fait qu'un « refaire » n'est pas un
     * rejeu a l'identique.
     *
     * <p>Une thematique introuvable ne fait rien echouer : la serie reste celle
     * de l'unite, plus courte, ce qui est exactement ce qui se passait avant.
     */
    private void completerParLaThematique(
            List<Question> questions, CivicOfficialUnit unite, int taille) {
        int manquant = taille - questions.size();
        if (manquant <= 0) return;
        Theme thematique = themeManager.findByCode(unite.getThemeCode()).orElse(null);
        if (thematique == null) return;
        List<UUID> dejaTirees = questions.stream().map(Question::getId).toList();
        questions.addAll(questionManager.findRandomExcluding(
                Module.CIVIQUE, thematique.getId(), null, null, dejaTirees, manquant));
    }

    /**
     * L'attempt d'une serie ciblee, quel que soit son grain. Extrait a sa
     * 2e occurrence : deux copies auraient pu diverger sur le type, le module ou
     * l'ordre des questions.
     *
     * @param mode le <b>regime de passation</b> : {@code ENTRAINEMENT} (le Plan,
     *             correction immediate) ou {@code EXAMEN} (une carte d'etape du
     *             cycle, aucune correction). Pose ici, a la creation, parce que
     *             c'est lui que {@code AttemptResponse.mode} sert et que
     *             {@code doSubmitAnswer} oppose.
     */
    private Attempt nouvelleSerie(User user, List<Question> questions, AttemptMode mode) {
        Instant now = Instant.now();
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setMode(mode);
        attempt.setModule(Module.CIVIQUE);
        attempt.setStatus(AttemptStatus.EN_COURS);
        attempt.setTotalQuestions(questions.size());
        attempt.setStartedAt(now);
        Attempt enregistre = attemptManager.save(attempt);
        for (int i = 0; i < questions.size(); i++) {
            AttemptQuestion aq = new AttemptQuestion();
            aq.setAttempt(enregistre);
            aq.setQuestion(questions.get(i));
            aq.setPosition(i);
            attemptQuestionManager.save(aq);
        }
        return enregistre;
    }

    @Transactional
    public AttemptResponse demarrerSerie(UUID userId, UUID cibleId, CivicPlanGrain grain) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        if (!subscriptionService.hasCivique(userId)) {
            throw new AccessDeniedException(
                    "Les series ciblees font partie de l'abonnement. "
                            + "Votre plan, lui, reste entier.");
        }
        Difficulty mention = TargetProcedure.mentionCivique(user.getTargetProcedure());

        // 🛑 LE GRAIN ANNONCE PAR LE CLIENT N'EST PAS UNE AUTORITE. Le serveur
        // recalcule le plan et va chercher la cible dedans : c'est lui qui sait
        // a quel grain ce theme est passe, et si la cible est servable. Avant,
        // un appel direct sur une notion CONTENU_INSUFFISANT ouvrait une serie
        // de une a quatre questions au lieu de dix, en silence. Le parametre
        // reste accepte pour ne rien casser cote fronts, mais il est ignore.
        CivicPlanDto.Cible cible = calculer(userId).cibles().stream()
                .filter(c -> c.id().equals(cibleId))
                .findFirst()
                .orElseThrow(() -> new NotFoundException(
                        "Cette cible ne fait pas partie de votre plan."));
        // ⚠️ P8.2b : le pre-controle de dotation a disparu avec `CivicDotation`.
        // Le tirage vide juste en dessous DIT la meme chose, et il la dit sur ce
        // que la base contient VRAIMENT -- pas sur un compte fait ailleurs.

        UUID notionId = cible.grain() == CivicPlanGrain.NOTION ? cibleId : null;
        UUID themeId = cible.grain() == CivicPlanGrain.THEME ? cibleId : null;
        List<UUID> ids = planManager.tirageSerieCiblee(
                userId, notionId, themeId, props.getQuestionsParSerie());
        if (ids.isEmpty()) {
            // Arriver ici veut dire que le catalogue a bouge entre l'affichage
            // et le clic -- ou qu'une cible n'a plus aucune question. On le DIT,
            // on ne rend jamais une serie vide.
            throw new BusinessException(
                    "Aucune question disponible sur ce point pour votre démarche.");
        }

        // 🛑 L'ordre du tirage est celui du plan (rate d'abord, jamais vu
        // ensuite) : `findAllById` ne le garantit pas, on le retablit.
        Map<UUID, Question> parId = questionManager.findAllById(ids).stream()
                .collect(java.util.stream.Collectors.toMap(Question::getId, q -> q));
        List<Question> questions = ids.stream().map(parId::get).filter(java.util.Objects::nonNull).toList();

        Instant now = Instant.now();
        Attempt attempt = new Attempt();
        attempt.setUser(user);
        attempt.setType(AttemptType.TRAINING);
        attempt.setModule(Module.CIVIQUE);
        attempt.setStatus(AttemptStatus.EN_COURS);
        attempt.setTotalQuestions(questions.size());
        attempt.setStartedAt(now);
        attempt = attemptManager.save(attempt);

        for (int i = 0; i < questions.size(); i++) {
            AttemptQuestion aq = new AttemptQuestion();
            aq.setAttempt(attempt);
            aq.setQuestion(questions.get(i));
            aq.setPosition(i);
            attemptQuestionManager.save(aq);
        }

        log.info("Serie civique ciblee : attempt={} user={} grain={} cible={} questions={}",
                attempt.getId(), userId, grain, cibleId, questions.size());
        // Lu DANS la transaction : l'attempt vient d'etre ecrit, ses questions
        // aussi, et le mapper touche des associations paresseuses.
        //
        // 🛑 LE MAPPER, PAS `AttemptService`. Ce service passait par
        // `attemptService.readAttempt(...)`, qui ne fait que deleguer a
        // `AttemptInteractionService` -- lequel depend de `JourneyService`. Le
        // jour ou le cycle civique a eu besoin de LIRE l'ordre du plan derive
        // (D-36), la boucle s'est refermee et le contexte Spring a refuse de
        // demarrer : CivicPlan -> Attempt -> AttemptInteraction -> Journey ->
        // CivicPlan. Un `@Lazy` l'aurait CACHEE ; appeler le mapper la SUPPRIME,
        // et c'est aussi ce que la convention de couches demande -- un service
        // n'appelle pas un autre service pour mapper.
        // `revealCorrect = false` : l'attempt vient de naitre, rien n'est fini.
        List<AttemptQuestion> lignes =
                attemptQuestionManager.findByAttemptOrderedByPosition(attempt.getId());
        return attemptMapper.toResponse(attempt, lignes, false);
    }

    // ------------------------------------------------------------------------
    // Cibles
    // ------------------------------------------------------------------------

    private static Map<UUID, List<CivicReponse>> grouperParNotion(List<CivicReponse> reponses) {
        Map<UUID, List<CivicReponse>> out = new LinkedHashMap<>();
        for (CivicReponse reponse : reponses) {
            if (reponse.notionId() == null) continue;
            out.computeIfAbsent(reponse.notionId(), k -> new ArrayList<>()).add(reponse);
        }
        return out;
    }

    private List<CivicPlanDto.Cible> ciblesNotions(
            Theme theme,
            CivicThemeState etatDuTheme,
            List<CivicNotion> notions,
            Map<UUID, Long> questionsParNotion,
            Map<UUID, List<CivicReponse>> parNotion,
            Instant maintenant,
            boolean abonne) {

        List<CivicPlanDto.Cible> out = new ArrayList<>();
        for (CivicNotion notion : notions) {
            if (!notion.isActive()) continue;
            if (!theme.getCode().equals(notion.getThemeCode())) continue;

            CivicEtatCible etat = leitnerResolver.resoudre(
                    parNotion.getOrDefault(notion.getId(), List.of()),
                    CivicPrioriteScorer.FENETRE_REPETEE, maintenant);
            // 🛑 Au grain notion, le diagnostic n'a rien pointe : il mesure des
            // THEMES. Le signal du diagnostic passe donc par le poids du theme,
            // et pas une seconde fois par un « pointee par le diagnostic » qui
            // le compterait deux fois pour toutes les notions d'un theme faible.
            int score = scorer.score(etat, etatDuTheme, false, maintenant);

            out.add(cible(notion.getId(), notion.getCode(), notion.getLabel(),
                    CivicPlanGrain.NOTION, theme, etatDuTheme, etat, score,
                    questionsParNotion.getOrDefault(notion.getId(), 0L),
                    abonne, maintenant));
        }
        return out;
    }

    private CivicPlanDto.Cible cibleTheme(
            Theme theme,
            CivicThemeState etatDuTheme,
            boolean pointeParLeDiagnostic,
            Map<UUID, Long> questionsParTheme,
            List<CivicReponse> reponses,
            Instant maintenant,
            boolean abonne) {

        List<CivicReponse> siennes = reponses.stream()
                .filter(r -> theme.getId().equals(r.themeId()))
                .toList();
        CivicEtatCible etat = leitnerResolver.resoudre(
                siennes, CivicPrioriteScorer.FENETRE_REPETEE, maintenant);

        // 🛑 Un theme n'est JAMAIS « maitrise ». Quatre bonnes reponses sur deux
        // cents questions ne prouvent rien, et l'annoncer acquis est exactement
        // le defaut « NON FRAGILE ≠ PLUS RIEN A APPRENDRE ». Le garde-fou ne
        // peut qu'ABAISSER.
        etat = rabattre(etat);

        int score = scorer.score(etat, etatDuTheme, pointeParLeDiagnostic, maintenant);

        return cible(theme.getId(), theme.getCode(), theme.getName(),
                CivicPlanGrain.THEME, theme, etatDuTheme, etat, score,
                questionsParTheme.getOrDefault(theme.getId(), 0L),
                abonne, maintenant);
    }

    /**
     * @param stock le nombre de questions que cette cible peut REELLEMENT
     *              servir. 🛑 Il <b>borne</b> la serie : depuis P8.2b, la taille
     *              annoncee est {@code min(questionsParSerie, stock)} et non
     *              plus le quota nu. Le plan ne promet donc plus une serie de 10
     *              sur une cible qui n'en a que 8 ({@code DETTE-C1}).
     */
    private CivicPlanDto.Cible cible(
            UUID id, String code, String label, CivicPlanGrain grain,
            Theme theme, CivicThemeState etatDuTheme, CivicEtatCible etat,
            int score, long stock, boolean abonne, Instant maintenant) {

        int questionsSerie = (int) Math.min(props.getQuestionsParSerie(), stock);

        return new CivicPlanDto.Cible(
                id, code, label, grain,
                theme.getId(), theme.getCode(), theme.getName(),
                etatDuTheme,
                etat.maitrise(), etat.boite(),
                CivicLeitner.parcours(
                        etat.boite(), etat.maitrise() == CivicMaitrise.MAITRISEE),
                etat.reponses(), etat.correctes(),
                etat.erreursRecentes(), etat.derniereErreur(), etat.prochaineRevue(),
                etat.aRevoir(maintenant),
                score,
                questionsSerie,
                questionsSerie * props.getSecondesParQuestion(),
                // 🛑 Le verrou porte sur l'ACTION, jamais sur le constat : les
                // priorites restent entierement lisibles pour un compte gratuit
                // (20_ §6, variante non abonne).
                !abonne);
    }

    /** Le rabat de maitrise au grain theme. Il ne peut qu'abaisser. */
    private static CivicEtatCible rabattre(CivicEtatCible etat) {
        CivicMaitrise rabattue = etat.maitrise().rabattueAuGrainTheme();
        if (rabattue == etat.maitrise()) return etat;
        return new CivicEtatCible(
                etat.boite(), etat.reponses(), etat.correctes(),
                etat.consecutivesJustes(), etat.derniereVue(), etat.derniereErreur(),
                etat.erreursRecentes(), etat.prochaineRevue(),
                rabattue);
    }

    // ------------------------------------------------------------------------
    // Grain
    // ------------------------------------------------------------------------

    /**
     * Le grain d'un theme, mesure sur SON tagging ({@code 20_} §3.3).
     *
     * <p>🛑 Un theme sans question active reste au grain THEME : diviser par
     * zero pour conclure « 100 % tague » basculerait un theme vide en mode
     * notion, ou il n'y a rien.
     */
    private CivicPlanGrain grainDuTheme(long[] taggage) {
        if (taggage == null || taggage[0] <= 0) return CivicPlanGrain.THEME;
        double part = (double) taggage[1] / taggage[0];
        return part >= props.getSeuilTagging() ? CivicPlanGrain.NOTION : CivicPlanGrain.THEME;
    }

    /** L'etat d'ensemble du tagging, pour que l'ecran DISE a quel grain il parle. */
    private CivicPlanDto.Grain grain(Map<UUID, long[]> taggage) {
        long total = taggage.values().stream().mapToLong(t -> t[0]).sum();
        long taguees = taggage.values().stream().mapToLong(t -> t[1]).sum();
        int parNotion = (int) taggage.values().stream()
                .filter(t -> grainDuTheme(t) == CivicPlanGrain.NOTION).count();
        // 🛑 NOTION seulement quand TOUS les themes ont bascule : le plan ne se
        // dit jamais plus precis qu'il ne l'est.
        boolean tousBascules = !taggage.isEmpty() && parNotion == taggage.size();
        return new CivicPlanDto.Grain(
                tousBascules ? CivicPlanGrain.NOTION : CivicPlanGrain.THEME,
                parNotion, taggage.size(), taguees, total);
    }

    // ------------------------------------------------------------------------
    // Diagnostic
    // ------------------------------------------------------------------------

    /**
     * Le dernier diagnostic <b>termine</b>.
     *
     * <p>Un diagnostic en cours ne sert a rien ici : ses themes n'ont pas encore
     * d'etat, et batir un plan dessus reviendrait a mesurer a mi-parcours.
     */
    private Optional<CivicDiagnosticResultDto> dernierDiagnostic(UUID userId) {
        return sessionManager.findLatest(userId)
                .filter(s -> s.getStatus() == TcfDiagnosticStatus.COMPLETED)
                .map(this::resultat);
    }

    private CivicDiagnosticResultDto resultat(CivicDiagnosticSession session) {
        return diagnosticViewService.resultat(session);
    }

    private static CivicThemeState etatDuTheme(CivicDiagnosticResultDto resultat, UUID themeId) {
        return resultat.themes().stream()
                .filter(t -> t.themeId().equals(themeId))
                .map(CivicDiagnosticResultDto.ThemeResultat::etat)
                .findFirst()
                // 🛑 Absent du diagnostic ⇒ NON_EVALUE, jamais FAIBLE : « pas
                // mesure » n'est pas « rate ».
                .orElse(CivicThemeState.NON_EVALUE);
    }

    /**
     * L'ordre du plan ({@code 20_} §5.3).
     *
     * <p>Score decroissant d'abord. A score egal, les departages de la spec, dans
     * l'ordre : ce qui a ete <b>vu et rate</b>, puis ce qui rate de facon
     * <b>repetee</b>, puis ce qui progresse, puis ce qui n'a <b>jamais</b> ete
     * touche. Un ordre stable clot le tri (le code) : sans lui, deux appels
     * successifs pourraient rendre deux plans differents pour un meme etat.
     */
    private static final Comparator<CivicPlanDto.Cible> ORDRE_DU_PLAN =
            Comparator.comparingInt(CivicPlanDto.Cible::score).reversed()
                    .thenComparing(c -> c.reponses() == 0)
                    .thenComparing(Comparator.comparingInt(
                            CivicPlanDto.Cible::erreursRecentes).reversed())
                    .thenComparing(CivicPlanDto.Cible::code);
}
