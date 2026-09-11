package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.config.CivicPlanProperties;
import com.sejourfr.app.dto.CivicDiagnosticResultDto;
import com.sejourfr.app.dto.AttemptResponse;
import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.AttemptQuestion;
import com.sejourfr.app.entity.CivicDiagnosticSession;
import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.entity.Theme;
import com.sejourfr.app.entity.Question;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.AttemptStatus;
import com.sejourfr.app.enums.AttemptType;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.enums.TcfDiagnosticStatus;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.CivicDiagnosticSessionManager;
import com.sejourfr.app.manager.CivicNotionManager;
import com.sejourfr.app.manager.CivicPlanManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.ThemeManager;
import com.sejourfr.app.manager.UserManager;
import com.sejourfr.app.service.AttemptService;
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
 * qui rapporte le <b>tagging retroactif</b> : au lancement de ce lot, 0 question
 * sur 1 016 est taguee, et une table de progression serait nee vide pour tout
 * l'historique deja produit.
 *
 * <p>🛑 <b>2. Le grain se mesure, thème par thème.</b> Tant qu'un theme n'a pas
 * franchi le seuil de tagging, le plan y travaille <b>par theme</b> — le mode
 * degrade que {@code 20_} §3.3 prevoit noir sur blanc, pas une panne. Attendre
 * le tagging complet pour offrir quoi que ce soit priverait le candidat de ce
 * qui est deja mesurable.
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
    private final AttemptService attemptService;
    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final QuestionManager questionManager;
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
            Map<UUID, List<CivicReponse>> reponsesParCible,
            Map<UUID, long[]> taggage,
            Instant maintenant) {

        static Calcul indisponible(Difficulty mention, Instant maintenant) {
            return new Calcul(false, mention, null, List.of(), Map.of(), Map.of(), maintenant);
        }
    }

    @Transactional(readOnly = true)
    public CivicPlanDto plan(UUID userId) {
        Calcul calcul = calculer(userId);
        if (!calcul.disponible()) {
            return new CivicPlanDto(
                    false, calcul.mention(), null, null, List.of(), 0, List.of(), List.of(),
                    grain(Map.of()), null, calcul.maintenant());
        }
        return mettreEnForme(calcul);
    }

    private Calcul calculer(UUID userId) {
        User user = userManager.findById(userId)
                .orElseThrow(() -> new NotFoundException("User introuvable : " + userId));
        Difficulty mention = TargetProcedure.mentionCivique(user.getTargetProcedure());
        Instant maintenant = Instant.now();

        // 🛑 Le plan ne se batit pas sur une mesure qui n'existe pas. Sans
        // diagnostic termine, on ne sert AUCUNE cible : l'ecran ouvre la seule
        // porte qui debloque, il n'affiche pas un plan vide.
        Optional<CivicDiagnosticResultDto> diagnostic = dernierDiagnostic(userId);
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
        Map<UUID, Long> dotationNotions = planManager.questionsParNotion(mention);
        Map<UUID, Long> dotationThemes = planManager.questionsParTheme(mention);
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
                        notions, dotationNotions, reponsesParNotion, maintenant, abonne);
                cibles.addAll(duTheme);
                for (CivicPlanDto.Cible cible : duTheme) {
                    reponsesParCible.put(cible.id(),
                            reponsesParNotion.getOrDefault(cible.id(), List.of()));
                }
            } else {
                CivicPlanDto.Cible cible = cibleTheme(theme, etatDuTheme,
                        pointeParLeDiagnostic, dotationThemes, reponses, maintenant, abonne);
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

        return new Calcul(true, mention, resultat, List.copyOf(cibles),
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

        // 🛑 Seul SERVABLE est propose. `NON_APPLICABLE` n'est pas un cran de
        // plus dans le manque : la notion n'est pas au programme de cette
        // demarche, elle n'a rien a faire dans un plan.
        List<CivicPlanDto.Cible> proposables = cibles.stream()
                .filter(c -> c.dotation().estServable())
                .filter(c -> c.maitrise() != CivicMaitrise.MAITRISEE)
                .toList();
        // 🛑 Plafond d'AFFICHAGE, jamais un budget de calcul : le moteur a
        // classe TOUTES les cibles, l'ecran en montre trois et COMPTE le reste.
        List<CivicPlanDto.Cible> priorites =
                proposables.stream().limit(props.getPrioritesVisibles()).toList();

        List<CivicPlanDto.Cible> aRevoir = cibles.stream()
                .filter(c -> c.maitrise() == CivicMaitrise.MAITRISEE)
                .filter(CivicPlanDto.Cible::aRevoir)
                .filter(c -> c.dotation().estServable())
                .sorted(Comparator.comparing(
                        CivicPlanDto.Cible::prochaineRevue,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .limit(props.getRevisionsVisibles())
                .toList();

        // 🛑 `solides` se filtre par dotation comme `priorites` et `aRevoir`.
        // Une cible maitrisee puis devenue non servable — le candidat change de
        // `targetProcedure`, et la notion n'a plus de question dans sa nouvelle
        // mention — s'affichait comme un acquis. Le plan annoncait donc un
        // acquis sur un point qu'il ne sait plus enseigner.
        List<CivicPlanDto.Cible> solides = cibles.stream()
                .filter(c -> c.maitrise() == CivicMaitrise.MAITRISEE)
                .filter(c -> !c.aRevoir())
                .filter(c -> c.dotation().estServable())
                .toList();

        CivicPlanDto.Cible prochaine = priorites.isEmpty() ? null : priorites.getFirst();

        // 🛑 `null` est le cas NORMAL : servi seulement si quelque chose a
        // vraiment bouge. Le temps qui passe n'est pas un changement.
        // 🛑 « Progression detectee » ne parle que de cibles SERVABLES. Une
        // notion non servable touchee pendant le diagnostic pouvait y etre
        // nommee alors qu'elle n'a de carte NULLE PART ailleurs dans le plan :
        // le candidat lisait un progres sur un point qu'il ne peut pas
        // travailler, et sur lequel il ne peut pas revenir.
        List<CivicPlanDto.Cible> servables = cibles.stream()
                .filter(c -> c.dotation().estServable())
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
                grain(calcul.taggage()),
                changements,
                maintenant);
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
     */
    public record Compteurs(int travaillees, int maitrisees, boolean grainNotion) {
    }

    @Transactional(readOnly = true)
    public Compteurs compteurs(UUID userId) {
        Calcul calcul = calculer(userId);
        if (!calcul.disponible()) return new Compteurs(0, 0, false);

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
                grain(calcul.taggage()).courant() == CivicPlanGrain.NOTION);
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
        if (!cible.dotation().estServable()) {
            throw new BusinessException(
                    "Aucune question disponible sur ce point pour votre démarche.");
        }

        UUID notionId = cible.grain() == CivicPlanGrain.NOTION ? cibleId : null;
        UUID themeId = cible.grain() == CivicPlanGrain.THEME ? cibleId : null;
        List<UUID> ids = planManager.tirageSerieCiblee(
                userId, mention, notionId, themeId, props.getQuestionsParSerie());
        if (ids.isEmpty()) {
            // 🛑 Le plan ne propose jamais une cible qui ne soit pas SERVABLE :
            // arriver ici veut dire que le catalogue a bouge entre l'affichage
            // et le clic. On le DIT, on ne rend pas une serie vide.
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
        return attemptService.readAttempt(attempt);
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
            // 🛑 UNE SEULE derivation, chez l'enum : le plan ne recompare pas
            // un compte a un seuil.
            CivicDotation dotation = CivicDotation.depuis(
                    questionsParNotion.getOrDefault(notion.getId(), 0L),
                    props.getQuestionsMinParNotion());

            // 🛑 Au grain notion, le diagnostic n'a rien pointe : il mesure des
            // THEMES. Le signal du diagnostic passe donc par le poids du theme,
            // et pas une seconde fois par un « pointee par le diagnostic » qui
            // le compterait deux fois pour toutes les notions d'un theme faible.
            int score = scorer.score(etat, etatDuTheme, false, dotation, maintenant);

            out.add(cible(notion.getId(), notion.getCode(), notion.getLabel(),
                    CivicPlanGrain.NOTION, theme, etatDuTheme, etat, score,
                    dotation, abonne, maintenant));
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

        // 🛑 Le seuil du grain THEME reste `questionsParSerie`, pas
        // `questionsMinParNotion` : ce qu'on proposerait la, c'est une serie
        // entiere, et une cible qui ne peut pas la remplir n'est pas servable.
        CivicDotation dotation = CivicDotation.depuis(
                questionsParTheme.getOrDefault(theme.getId(), 0L),
                props.getQuestionsParSerie());
        int score = scorer.score(
                etat, etatDuTheme, pointeParLeDiagnostic, dotation, maintenant);

        return cible(theme.getId(), theme.getCode(), theme.getName(),
                CivicPlanGrain.THEME, theme, etatDuTheme, etat, score,
                dotation, abonne, maintenant);
    }

    private CivicPlanDto.Cible cible(
            UUID id, String code, String label, CivicPlanGrain grain,
            Theme theme, CivicThemeState etatDuTheme, CivicEtatCible etat,
            int score, CivicDotation dotation, boolean abonne, Instant maintenant) {

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
                score, dotation,
                props.getQuestionsParSerie(),
                props.getQuestionsParSerie() * props.getSecondesParQuestion(),
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
