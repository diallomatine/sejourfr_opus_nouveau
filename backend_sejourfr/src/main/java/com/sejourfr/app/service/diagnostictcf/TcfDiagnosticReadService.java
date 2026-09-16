package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.entity.AiEvaluation;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.entity.ProductionSubmission;
import com.sejourfr.app.entity.TcfDiagnosticSession;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProductionEvaluabilite;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.manager.AttemptManager;
import com.sejourfr.app.manager.AttemptQuestionManager;
import com.sejourfr.app.manager.ProductionSubmissionManager;
import com.sejourfr.app.service.NiveauActuelEpreuveResolver;
import com.sejourfr.app.service.ProductionBilanService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Ce que le diagnostic TCF a MESURE, recalcule a la lecture.
 *
 * <p>🛑 <b>Rien de ce que ce service produit n'est persiste.</b> L'etat d'une
 * section est celui de son sous-attempt, le niveau d'une epreuve se relit
 * depuis les reponses (comprehension) ou les evaluations (production).
 * Recalibrer un seuil relit alors tout l'historique au prochain appel, sans
 * migration ni job — c'est le patron des {@code *Resolver} du depot.
 */
@Service
@RequiredArgsConstructor
public class TcfDiagnosticReadService {

    /** Les 4 epreuves, dans l'ordre d'affichage de l'ecran d'accueil (30_ §5.1). */
    public static final List<EpreuveType> EPREUVES = List.of(
            EpreuveType.TCF_CO, EpreuveType.TCF_CE, EpreuveType.TCF_EE, EpreuveType.TCF_EO);

    /**
     * Sessions balayees pour savoir si une epreuve est mesuree ailleurs.
     * <b>Plafond de lecture</b>, jamais la fenetre de calcul — celle-ci vit
     * dans {@code NiveauActuelEpreuveResolver.EXAMENS_RETENUS}. Meme valeur que
     * {@code TcfProfileService}, pour que les deux ecrans voient la meme chose.
     */
    private static final int SCAN_LIMIT = 200;

    private final AttemptManager attemptManager;
    private final AttemptQuestionManager attemptQuestionManager;
    private final ProductionSubmissionManager submissionManager;
    private final ProductionBilanService bilanService;
    private final TcfDiagnosticLevelResolver levelResolver;
    private final NiveauActuelEpreuveResolver niveauActuelResolver;
    private final com.sejourfr.app.mapper.AttemptMapper attemptMapper;

    /**
     * Une section telle que l'ecran la voit — <b>resultat compris</b>.
     *
     * <p>⚠️ <b>REVOQUE 10_ §4.2</b> (« aucun resultat partiel entre les
     * sections, le resultat est le moment de conversion »), arbitrage du
     * proprietaire du 2026-09-13 : une section du diagnostic <b>est</b> un
     * examen blanc de son epreuve, donc elle rend son resultat des qu'elle est
     * close et son rapport se consulte comme celui d'un examen. Le resultat
     * d'ENSEMBLE — niveau global, priorites, plan — reste sur l'ecran de
     * resultat : c'est lui, le moment de conversion, pas le score d'une
     * epreuve isolee.
     */
    public record Section(
            EpreuveType epreuve,
            UUID attemptId,
            TcfDiagnosticSectionState etat,
            Integer timeLimitSeconds,
            /** Niveau mesure, {@code null} tant que la section n'est pas exploitable. */
            NiveauCecrl niveau,
            /**
             * Score calibre 100-499 de la section, <b>compréhension seulement</b>.
             * {@code null} en production et tant que la section n'est pas close :
             * c'est la meme valeur, lue chez la meme autorite, que celle d'un
             * examen blanc d'epreuve.
             */
            Integer scoreCalibre,
            /**
             * {@code true} quand la section est close, des productions ont ete
             * rendues, et <b>au moins une attend encore sa correction</b>.
             *
             * <p>🛑 Il distingue « on attend l'IA » de « rien d'exploitable » —
             * deux etats qui donnent tous deux {@code niveau == null} et que
             * l'ecran ne doit pas confondre. Exactement le meme sursis qu'un
             * examen blanc : les taches partent a la correction des qu'elles
             * sont rendues, seule la derniere se fait attendre.
             */
            boolean analyseEnCours,
            /**
             * L'attempt dont le <b>rapport</b> explique {@link #niveau}.
             *
             * <p>Egal a {@link #attemptId} quand c'est la section elle-meme qui
             * a mesure l'epreuve. Quand l'epreuve est mesuree <b>ailleurs</b>
             * (examen blanc isole, examen TCF complet), c'est l'examen
             * qualifiant le plus recent — cf. {@link #sectionsMesurees}.
             *
             * <p>🛑 {@code null} exactement quand rien n'est mesure : « Voir le
             * rapport » ne doit jamais pointer sur un rapport vide.
             */
            UUID rapportAttemptId) {
    }

    /**
     * <b>Ce que CETTE session a mesure</b>, et rien d'autre.
     *
     * <p>🛑 <b>Lecture HISTORIQUE, a ne pas confondre avec
     * {@link #sectionsMesurees}</b> (2026-09-16). Elle est la source de tout ce
     * qui date un diagnostic : la comparaison de deux diagnostics
     * ({@code TcfDiagnosticProgressionResolver}), le palier INITIAL et la
     * courbe de l'ecran Progres ({@code ProgressService.tcf}), le
     * « votre niveau estime etait B1 » de la reevaluation
     * ({@code TcfReassessmentService}) et le cache {@code final_cecrl_level}
     * pose a la cloture. Les enrichir avec le niveau d'aujourd'hui rendrait
     * toute evolution STABLE — c'est-a-dire mensongere.
     *
     * <p>🛑 <b>Le niveau n'est PAS servi aux ecrans de passation</b> : 10_ §4.2
     * interdit tout resultat partiel entre les sections — « le resultat est le
     * moment de conversion, il ne doit pas etre dilue ». C'est l'appelant qui
     * decide de le montrer, et seul l'ecran de resultat le fait.
     */
    @Transactional(readOnly = true)
    public List<Section> sections(TcfDiagnosticSession session) {
        List<Attempt> sousEpreuves = attemptManager.findSubAttempts(session.getParentAttempt().getId());
        List<Section> out = new ArrayList<>(EPREUVES.size());

        for (EpreuveType epreuve : EPREUVES) {
            Attempt sub = sousEpreuves.stream()
                    .filter(a -> a.getEpreuve() == epreuve)
                    .findFirst()
                    .orElse(null);
            if (sub == null) {
                // Section absente du tirage (mode degrade 10_ §9 : aucun audio
                // CO, aucun sujet EO). Elle n'existe pas, elle n'a pas echoue.
                out.add(new Section(epreuve, null, TcfDiagnosticSectionState.A_FAIRE,
                        null, null, null, false, null));
                continue;
            }
            NiveauCecrl niveau = niveauDe(epreuve, sub).orElse(null);
            out.add(new Section(
                    epreuve,
                    sub.getId(),
                    etatDe(sub),
                    sub.getTimeLimitSeconds(),
                    niveau,
                    scoreCalibre(epreuve, sub, niveau),
                    analyseEnCours(epreuve, sub),
                    // Le rapport d'une section n'existe que si elle a mesure
                    // quelque chose : un examen a zero reponse n'en a aucun.
                    niveau == null ? null : sub.getId()));
        }
        return out;
    }

    /**
     * <b>Les 4 epreuves telles que le PRODUIT les connait</b> — la lecture des
     * ecrans.
     *
     * <h2>La regle, tranchee par le proprietaire le 2026-09-16</h2>
     * <p>Verbatim : « <i>un diagnostic complet, chaque epreuve est un examen
     * blanc de l'epreuve. Donc si un examen blanc est fait ailleurs, directement
     * on considere que le diagnostic de cette epreuve est fait, et les priorites
     * a travailler identifiees. Donc ce n'est pas normal qu'on dise qu'une
     * epreuve est "mesuree ailleurs" : si c'est mesure, c'est okay, sur le
     * diagnostic.</i> »
     *
     * <p>🛑 <b>Il n'existe donc qu'UNE notion de « cette epreuve est
     * mesuree »</b>, et ce n'est pas une nouvelle : c'est celle du niveau actuel
     * ({@link NiveauActuelEpreuveResolver}), la meme que l'Accueil, le Profil et
     * « Voir mes resultats ». {@code niveau == null} ⇒ non mesuree,
     * {@code niveau != null} ⇒ mesuree. Rien d'autre n'est demande.
     *
     * <h2>L'enrichissement ne fait que COMBLER, jamais remplacer</h2>
     * <p>Une section que la session a reellement mesuree garde <b>exactement</b>
     * son resultat — son niveau, son score calibre, son rapport. C'est la regle
     * « une section rend SON resultat » et elle ne bouge pas. Seule une section
     * qui n'a <b>rien</b> mesure interroge le produit :
     * <ul>
     *   <li>epreuve mesuree ailleurs ⇒ la section devient {@code TERMINEE},
     *       porte le niveau du produit et pointe son rapport sur l'examen
     *       qualifiant ;</li>
     *   <li>epreuve mesuree nulle part ⇒ <b>rien n'est invente</b> : elle reste
     *       honnetement non mesuree, et le candidat peut la passer.</li>
     * </ul>
     *
     * <p>🛑 <b>Pas de score calibre sur une section comblee</b> : le niveau
     * servi est une <b>moyenne</b> de plusieurs examens, il n'a pas de « /499 ».
     * En afficher un serait celui d'un seul des trois.
     *
     * <p>🛑 <b>Aucun vocabulaire « mesuree ailleurs » ne sort d'ici</b>, et
     * c'est un refus explicite du proprietaire : le DTO ne porte aucun drapeau
     * de provenance, une section mesuree se lit comme <b>faite</b>.
     *
     * <p>⚠️ <b>Une correction en vol l'emporte</b> : tant qu'une production de
     * cette session attend l'IA ({@code analyseEnCours}), on l'attend. Sa mesure
     * arrive, et c'est celle de la session.
     *
     * <p><b>Cout</b> : une session sans trou ne coute rien de plus. Un trou
     * coute une requete (CO/CE) ou trois (EE/EO), et seulement pour l'epreuve
     * concernee.
     */
    @Transactional(readOnly = true)
    public List<Section> sectionsMesurees(TcfDiagnosticSession session) {
        List<Section> propres = sections(session);
        if (session.getUser() == null) {
            return propres;
        }
        UUID userId = session.getUser().getId();

        List<Section> out = new ArrayList<>(propres.size());
        for (Section s : propres) {
            if (s.niveau() != null || s.analyseEnCours()) {
                out.add(s);
                continue;
            }
            NiveauActuelEpreuveResolver.Mesure mesure = mesureProduit(userId, s.epreuve());
            if (!mesure.mesuree()) {
                out.add(s);
                continue;
            }
            out.add(new Section(
                    s.epreuve(),
                    s.attemptId(),
                    TcfDiagnosticSectionState.TERMINEE,
                    s.timeLimitSeconds(),
                    mesure.niveau(),
                    null,
                    false,
                    mesure.attemptId()));
        }
        return out;
    }

    /**
     * « Cette epreuve est-elle mesuree, et a quel niveau ? » — <b>l'autorite
     * existante</b>, jamais une seconde definition.
     */
    private NiveauActuelEpreuveResolver.Mesure mesureProduit(UUID userId, EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO, TCF_CE -> niveauActuelResolver.mesureQcm(userId, epreuve, SCAN_LIMIT);
            case TCF_EE, TCF_EO -> niveauActuelResolver.mesureProduction(userId, epreuve, SCAN_LIMIT);
            default -> NiveauActuelEpreuveResolver.Mesure.AUCUNE;
        };
    }

    /**
     * Severite mesuree sur une tache : combien de criteres sont fragiles,
     * combien sont en cours d'acquisition.
     *
     * <p>🛑 <b>Derivee des bandes que le correcteur sert deja</b>
     * ({@code scores_criteres[].bande}), jamais d'une seconde notation. La
     * correspondance est directe et volontairement prudente :
     * <ul>
     *   <li>{@code FRAGILE} ⇒ « a travailler » (poids 2) ;</li>
     *   <li>{@code EN_COURS_ACQUISITION} ⇒ « fragile » (poids 1) ;</li>
     *   <li>{@code SATISFAISANT} et {@code TRES_BONNE_MAITRISE} ⇒ rien ;</li>
     *   <li>{@code NON_EVALUABLE} ⇒ rien — une absence de mesure n'est pas une
     *       faiblesse.</li>
     * </ul>
     */
    record Severite(int aTravailler, int fragiles) {
        static final Severite AUCUNE = new Severite(0, 0);
    }

    /**
     * Les priorites du diagnostic : les taches qui bloquent le candidat, triees
     * et bornees a trois.
     *
     * <p>En comprehension, la « tache » n'existe pas : la priorite porte sur
     * l'epreuve entiere ({@code taskCode} nul), comme 10_ §4.4 le prevoit.
     *
     * <p>🛑 <b>Les taches se lisent sur l'attempt qui a MESURE l'epreuve</b>
     * ({@code section.rapportAttemptId}), pas sur le sous-attempt de la session
     * (2026-09-16). C'est ce qui donne ses priorites a une EE/EO mesuree par un
     * examen blanc isole : sans cela, l'epreuve etait declaree faite et rendait
     * son niveau, mais ne proposait aucune tache a travailler — exactement la
     * moitie de ce que le proprietaire demande (« <i>et les priorites a
     * travailler identifiees</i> »). Sur une section jouee dans la session, les
     * deux identifiants sont le meme : rien ne change.
     */
    @Transactional(readOnly = true)
    public List<TcfDiagnosticPriorityResolver.TacheMesuree> tachesMesurees(
            TcfDiagnosticSession session, List<Section> sections) {

        List<TcfDiagnosticPriorityResolver.TacheMesuree> out = new ArrayList<>();

        for (Section section : sections) {
            switch (section.epreuve()) {
                case TCF_CO, TCF_CE -> {
                    if (section.niveau() != null) {
                        // Une epreuve de comprehension n'a pas de detail par
                        // critere : sa severite est nulle, seul l'ecart compte.
                        out.add(new TcfDiagnosticPriorityResolver.TacheMesuree(
                                section.epreuve(), null,
                                section.niveau(), section.niveau(), 0, 0));
                    }
                }
                case TCF_EE, TCF_EO -> {
                    if (section.rapportAttemptId() == null) continue;
                    out.addAll(tachesDeProduction(section.rapportAttemptId(), section));
                }
                default -> { }
            }
        }
        return out;
    }

    /** Une entree par tache REELLEMENT evaluee de l'epreuve productive. */
    private List<TcfDiagnosticPriorityResolver.TacheMesuree> tachesDeProduction(
            UUID attemptId, Section section) {

        List<ProductionSubmission> submissions = submissionManager.findByAttemptId(attemptId);
        Map<Integer, AiEvaluation> parTache = bilanService.latestEvalsByTache(submissions);
        String prefixe = section.epreuve() == EpreuveType.TCF_EE ? "EE" : "EO";

        List<TcfDiagnosticPriorityResolver.TacheMesuree> out = new ArrayList<>();
        for (Map.Entry<Integer, AiEvaluation> e : parTache.entrySet()) {
            AiEvaluation eval = e.getValue();
            if (eval == null
                    || eval.getEvaluabilite() == ProductionEvaluabilite.NON_EVALUABLE
                    || eval.getNiveauCecrl() == null) {
                // Tache non rendue ou inexploitable : elle ne peut pas devenir
                // une priorite. Le resolver le redit, on ne la propose meme pas.
                continue;
            }
            Severite sev = severiteDe(eval);
            out.add(new TcfDiagnosticPriorityResolver.TacheMesuree(
                    section.epreuve(),
                    prefixe + e.getKey(),
                    eval.getNiveauCecrl(),
                    section.niveau(),
                    sev.aTravailler(),
                    sev.fragiles()));
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    Severite severiteDe(AiEvaluation eval) {
        Object brut = eval.getFeedbackJson() == null
                ? null : eval.getFeedbackJson().get("scores_criteres");
        if (!(brut instanceof List<?> criteres)) {
            return Severite.AUCUNE;
        }
        int aTravailler = 0;
        int fragiles = 0;
        for (Object c : criteres) {
            if (!(c instanceof Map<?, ?> critere)) continue;
            Object bande = critere.get("bande");
            if (bande == null) continue;
            switch (bande.toString()) {
                case "FRAGILE" -> aTravailler++;
                case "EN_COURS_ACQUISITION" -> fragiles++;
                default -> { }
            }
        }
        return new Severite(aTravailler, fragiles);
    }

    /**
     * Niveau global : le plancher des epreuves EVALUEES (A7). Les autres sont
     * exclues, jamais comptees au plus bas.
     */
    public Optional<NiveauCecrl> niveauGlobal(List<Section> sections) {
        return levelResolver.niveauGlobal(
                sections.stream().map(Section::niveau).toList());
    }

    /**
     * Etat d'une section, <b>derive</b> du sous-attempt.
     *
     * <p>« Commencee » = le chrono est lance ({@code timerStartedAt}), le meme
     * discriminant que l'examen complet utilise deja pour dire si une epreuve
     * peut encore etre reprise. Ne pas en inventer un second.
     */
    private static TcfDiagnosticSectionState etatDe(Attempt sub) {
        if (sub.getFinishedAt() != null) {
            return TcfDiagnosticSectionState.TERMINEE;
        }
        return sub.getTimerStartedAt() != null
                ? TcfDiagnosticSectionState.EN_COURS
                : TcfDiagnosticSectionState.A_FAIRE;
    }

    /**
     * Le score calibre 100-499 d'une section de comprehension close.
     *
     * <p>🛑 <b>Lu chez {@code AttemptMapper}</b>, l'autorite qui le sert deja
     * aux examens blancs : le recalculer ici ferait exister un second
     * « /499 » dans le depot, et les deux finiraient par diverger.
     */
    private Integer scoreCalibre(EpreuveType epreuve, Attempt sub, NiveauCecrl niveau) {
        if (epreuve != EpreuveType.TCF_CO && epreuve != EpreuveType.TCF_CE) return null;
        if (sub.getFinishedAt() == null) return null;
        // 🛑 PAS DE SCORE SANS NIVEAU. Le score calibre se derive du score
        // pondere, qui vaut 0 sur une epreuve ou rien n'a ete repondu — donc
        // 100/499, le plancher de l'echelle. Un plancher affiche seul se lit
        // comme un resultat ; ce n'en est pas un.
        if (niveau == null) return null;
        return attemptMapper.calibratedScoreOf(sub);
    }

    /**
     * « Cette epreuve attend-elle encore une correction ? » — production
     * seulement, et seulement une fois la section close.
     *
     * <p>Une tache rendue sans evaluation est une correction <b>en vol</b> :
     * le pipeline tourne en arriere-plan depuis la soumission. Une tache
     * jamais rendue n'attend rien, et une section sans aucune soumission non
     * plus.
     */
    private boolean analyseEnCours(EpreuveType epreuve, Attempt sub) {
        if (epreuve != EpreuveType.TCF_EE && epreuve != EpreuveType.TCF_EO) return false;
        List<ProductionSubmission> submissions = submissionManager.findByAttemptId(sub.getId());
        if (submissions.isEmpty()) return false;
        return bilanService.latestEvalsByTache(submissions).values().stream()
                .anyMatch(java.util.Objects::isNull);
    }

    private Optional<NiveauCecrl> niveauDe(EpreuveType epreuve, Attempt sub) {
        return switch (epreuve) {
            case TCF_CO, TCF_CE -> niveauComprehension(sub);
            case TCF_EE, TCF_EO -> niveauProduction(sub);
            default -> Optional.empty();
        };
    }

    /** Comprehension : taux par palier, calcule sur les items REELLEMENT poses. */
    private Optional<NiveauCecrl> niveauComprehension(Attempt sub) {
        // Une section jamais commencee n'a rien mesure. On ne conclut pas.
        if (sub.getTimerStartedAt() == null) {
            return Optional.empty();
        }
        Map<Difficulty, Integer> poses = new EnumMap<>(Difficulty.class);
        Map<Difficulty, Integer> bonnes = new EnumMap<>(Difficulty.class);
        int repondues = 0;

        for (Object[] ligne : attemptQuestionManager.aggregateByDifficulty(sub.getId())) {
            Difficulty palier = (Difficulty) ligne[0];
            if (palier == null) continue;
            poses.put(palier, ((Number) ligne[1]).intValue());
            bonnes.put(palier, ligne[2] == null ? 0 : ((Number) ligne[2]).intValue());
            repondues += ligne[3] == null ? 0 : ((Number) ligne[3]).intValue();
        }
        // 🛑 AUCUNE REPONSE = AUCUNE MESURE, jamais un A1.
        //
        // C'est exactement la confusion que V040/V041/V042 ont payee : une
        // absence de donnee devenue le verdict le plus bas. Une epreuve ouverte
        // puis quittee sans repondre a une seule question sortait ici en
        // « A1 · 100/499 » — un verdict que personne n'a rendu, sur une epreuve
        // que personne n'a passee.
        //
        // ⚠️ A ne pas confondre avec une epreuve PARTIELLEMENT repondue : la,
        // ne pas repondre EST une reponse, comme au TCF, et le niveau se
        // calcule normalement. La frontiere est a zero, pas a un seuil.
        if (repondues == 0) {
            return Optional.empty();
        }
        return levelResolver.niveauComprehension(bonnes, poses);
    }

    /**
     * Production : le minimum des niveaux des 3 taches.
     *
     * <p>🛑 Une tache <b>inexploitable</b> ({@code NON_EVALUABLE}) n'a pas de
     * niveau et sort du calcul — elle ne tire pas l'epreuve vers le bas. C'est
     * la contrainte de base {@code chk_ai_eval_aucun_verdict_si_non_evaluable}
     * rendue lisible ici : une absence de preuve n'est pas la preuve du niveau
     * le plus faible.
     */
    private Optional<NiveauCecrl> niveauProduction(Attempt sub) {
        List<ProductionSubmission> submissions = submissionManager.findByAttemptId(sub.getId());
        if (submissions.isEmpty()) {
            return Optional.empty();
        }
        Map<Integer, AiEvaluation> parTache = bilanService.latestEvalsByTache(submissions);

        List<NiveauCecrl> niveaux = parTache.values().stream()
                .filter(e -> e != null
                        && e.getEvaluabilite() != ProductionEvaluabilite.NON_EVALUABLE)
                .map(AiEvaluation::getNiveauCecrl)
                .filter(java.util.Objects::nonNull)
                .toList();

        return levelResolver.niveauProduction(niveaux);
    }
}
