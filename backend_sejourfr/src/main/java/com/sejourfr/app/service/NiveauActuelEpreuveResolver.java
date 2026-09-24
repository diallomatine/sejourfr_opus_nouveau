package com.sejourfr.app.service;

import com.sejourfr.app.dto.StrateQcm;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Le niveau ACTUEL estimé d'une épreuve : la moyenne des
 * {@value #EXAMENS_RETENUS} derniers examens qualifiants.</b> Une seule fois
 * pour tout le dépôt.
 *
 * <h2>La règle, tranchée par le propriétaire le 2026-09-16</h2>
 * <p>Verbatim : « <i>moyenne des 3 derniers examens qualifiants. Le niveau
 * affiché doit représenter le niveau actuel estimé, donc il peut monter comme
 * descendre. 1 examen qualifiant → niveau de cet examen ; 2 examens → moyenne
 * des 2 ; 3 examens ou plus → moyenne des 3 derniers uniquement. […] Si on
 * dispose d'un score numérique interne, moyenne d'abord les scores puis
 * transforme le résultat en niveau CECRL. Évite de faire une moyenne directe des
 * labels A2/B1/B2. On retire donc la règle du maximum monotone et la protection
 * "le niveau ne redescend jamais". Le meilleur niveau atteint peut rester
 * visible plus tard dans l'historique, mais il ne doit pas être confondu avec le
 * niveau actuel affiché.</i> »
 *
 * <p>🛑 <b>Ce qui est RÉVOQUÉ ici</b> : le <b>maximum monotone</b> de la lecture
 * d'affichage, posé le matin même. Un mauvais examen récent <b>fait</b>
 * désormais redescendre le palier affiché — c'est précisément le comportement
 * que l'ancienne règle interdisait, et c'est celui que le propriétaire veut :
 * un niveau affiché est une <b>estimation d'aujourd'hui</b>, pas un trophée.
 * Le <b>meilleur</b> niveau reste lisible ailleurs, dans la chronologie de
 * l'écran de progression d'une épreuve ({@code ProgressionExamensService}).
 *
 * <p>⚠️ <b>La lecture du PLAN n'est PAS concernée</b>
 * ({@code TcfProfileService.levelProfile}) : elle garde son maximum sur toute
 * observation, entraînement compris — arbitrage du propriétaire du même jour.
 * Ce resolver ne sert que l'<b>affichage</b> du niveau actuel.
 *
 * <h2>Ce qui compte comme « examen qualifiant »</h2>
 * <p>🛑 <b>Aucune définition n'est écrite ici</b> : les deux qui existent sont
 * appelées, et ce sont les mêmes que celles de l'écran de progression d'une épreuve.
 * <ul>
 *   <li><b>CO / CE</b> : {@code AttemptManager.findQcmEpreuvesPassees} —
 *       l'épreuve passée seule, dans un examen blanc complet ou comme
 *       sous-épreuve du diagnostic complet, à l'exclusion des sessions sans
 *       aucune réponse ;</li>
 *   <li><b>EE / EO</b> : {@link EpreuvesProductionQualifiantesResolver} — les
 *       trois provenances d'examen complet, à l'exclusion de l'entraînement
 *       libre.</li>
 * </ul>
 * L'entraînement n'entre donc jamais dans la moyenne, quelle que soit
 * l'épreuve.
 *
 * <h2>On moyenne des MESURES, jamais des labels</h2>
 * <p>Un niveau CECRL est une <b>bande</b>, pas une graduation : « la moyenne de
 * A2 et B2 » n'a pas de sens arithmétique, et la calculer sur les ordinaux d'un
 * enum ferait dépendre le résultat de l'ordre de déclaration. Chaque épreuve
 * moyenne donc ce qu'elle a mesuré :
 * <ul>
 *   <li><b>CO / CE</b> : les <b>items eux-mêmes</b>. Les strates A2/B1/B2 des
 *       examens retenus sont <b>cumulées</b>, puis le palier se relit chez
 *       l'autorité unique ({@code TcfLevelEstimatorService.niveauParStrates}).
 *       🛑 Depuis le 2026-09-20 <b>aucune table « score → niveau » n'existe
 *       plus</b> : le score 100-499 est un score de <b>progression</b>, pas un
 *       palier, et il ne classe rien ;</li>
 *   <li><b>EE / EO</b> : la <b>compétence /20</b> de l'épreuve
 *       ({@code ProductionBilanService.NiveauEpreuve.competence}), l'agrégat
 *       pondéré des 3 tâches dont le palier de session est déjà la bande, via
 *       {@code ProductionBilanService.niveauDepuisCompetence}. <b>Aucun seuil
 *       n'est recopié ici</b> — la table des paliers a déjà vécu en six copies
 *       dans ce dépôt.</li>
 * </ul>
 *
 * <p>⚠️ <b>Le cumul d'items est une moyenne pondérée par la mesure</b>, et
 * c'est voulu : trente items A2 observés sur trois examens disent mieux où en
 * est le candidat que trois paliers moyennés. Un examen plus fourni pèse donc
 * un peu plus — les examens d'une même épreuve ayant la même composition, la
 * différence ne se produit qu'en mode dégradé.
 *
 * <p><b>Règle de bande</b> (EE/EO) : la table est une suite de <b>bornes
 * basses</b> ({@code >=}), donc une moyenne qui tombe <b>entre deux bandes
 * reste dans la bande BASSE</b> — la convention déjà en vigueur pour les notes
 * de critère.
 *
 * <h2>Aucun examen qualifiant ⇒ {@code null}</h2>
 * <p>« À évaluer », jamais un plancher fabriqué : <b>{@code null} = inconnu,
 * jamais mauvais</b>. Le repli sur la baseline du diagnostic rapide, lui, reste
 * là où il a toujours été ({@code TcfProfileService}).
 */
@Service
@RequiredArgsConstructor
public class NiveauActuelEpreuveResolver {

    /**
     * Combien d'examens qualifiants entrent dans la moyenne. Demande du
     * propriétaire : les trois derniers, et seulement eux — au-delà, un examen
     * d'il y a six mois ne décrit plus le niveau d'aujourd'hui.
     *
     * <p>Même valeur que l'ancien plafond de « Voir mes résultats » (supprimé le 2026-09-24), et
     * c'est une coïncidence <b>voulue mais pas partagée</b> : là-bas c'est un
     * plafond d'AFFICHAGE, ici une fenêtre de CALCUL. Les lier ferait d'un
     * réglage d'écran un réglage de règle métier.
     */
    public static final int EXAMENS_RETENUS = 3;

    /**
     * Sessions balayees en base pour repondre sur une epreuve.
     *
     * <p>🛑 <b>Un plafond de LECTURE, jamais la fenetre de calcul</b> — celle-ci
     * est {@link #EXAMENS_RETENUS}. La requete filtre deja les epreuves non
     * passees, ce qui borne le volume reel.
     *
     * <p><b>Extrait ici le 2026-09-17</b>, ou il vivait en deux copies privees
     * ({@code TcfProfileService.SCAN_LIMIT},
     * {@code TcfDiagnosticReadService.SCAN_LIMIT}) avec un commentaire disant de
     * part et d'autre « meme valeur que l'autre, pour que les deux ecrans voient
     * la meme chose ». Le parcours TCF en aurait fait une troisieme : a la
     * deuxieme occurrence, on extrait.
     */
    public static final int SCAN_LIMIT = 200;

    private final AttemptManager attemptManager;
    private final EpreuvesProductionQualifiantesResolver qualifiantesResolver;
    private final TcfLevelEstimatorService levelEstimator;
    private final ProductionBilanService bilanService;

    /**
     * Le niveau actuel d'une épreuve, <b>et l'examen qui l'explique</b>.
     *
     * <h2>À quoi sert {@code attemptId}</h2>
     * <p>🛑 <b>Il ne modifie pas la règle</b> : le niveau reste la moyenne des
     * {@value #EXAMENS_RETENUS} derniers examens qualifiants. {@code attemptId}
     * désigne le <b>plus récent</b> d'entre eux — c'est-à-dire l'examen dont le
     * rapport existe déjà et que le candidat peut ouvrir.
     *
     * <p>Il a été ajouté le <b>2026-09-16</b> pour le diagnostic 4 épreuves :
     * une section dont l'épreuve est mesurée <b>ailleurs</b> est une section
     * FAITE, et son « Voir le rapport » doit pointer sur quelque chose qui
     * existe — pas sur un sous-attempt vide.
     * Cf. {@code TcfDiagnosticReadService.sectionsMesurees}.
     *
     * <p>⚠️ <b>Une moyenne n'a pas de rapport</b> : sur trois examens retenus,
     * {@code attemptId} n'en nomme qu'un. C'est assumé — le candidat entre dans
     * son historique par le plus récent, et l'écran de progression d'une épreuve
     * ({@code ProgressionExamensService}) reste l'écran qui les montre tous.
     *
     * @param niveau    {@code null} = <b>aucun examen qualifiant</b>, donc
     *                  épreuve non mesurée. Jamais un plancher fabriqué.
     * @param attemptId {@code null} exactement quand {@code niveau} l'est
     */
    public record Mesure(NiveauCecrl niveau, UUID attemptId) {

        /** Aucun examen qualifiant : l'épreuve n'est pas mesurée. */
        public static final Mesure AUCUNE = new Mesure(null, null);

        /** L'épreuve est-elle mesurée ? La seule question, et sa seule réponse. */
        public boolean mesuree() {
            return niveau != null;
        }
    }

    /**
     * Niveau actuel estimé d'une épreuve de <b>compréhension</b> (CO / CE) :
     * les strates des {@value #EXAMENS_RETENUS} derniers examens qualifiants,
     * <b>cumulées</b>, relues par l'autorité unique du palier
     * ({@code TcfLevelEstimatorService.niveauParStrates}).
     *
     * <p>🛑 Il n'y a <b>pas de seconde règle</b> ici, et il n'y a plus de
     * conversion « score → niveau » nulle part : le palier se lit strate par
     * strate, exactement comme sur un examen isolé — seule la matière change
     * (les items de trois examens au lieu d'un).
     *
     * <p>⚠️ Un examen ancien reste parfaitement lisible : ses réponses sont en
     * base, donc ses strates aussi. C'est l'intérêt d'un dérivé qui ne se
     * persiste pas — le changement de règle relit tout l'historique.
     *
     * @param scanLimit sessions balayées en base ; un plafond de lecture, pas
     *                  la fenêtre de calcul
     */
    public NiveauCecrl qcm(UUID userId, EpreuveType epreuve, int scanLimit) {
        return mesureQcm(userId, epreuve, scanLimit).niveau();
    }

    /**
     * Le même calcul que {@link #qcm}, mais qui rend <b>aussi</b> l'examen
     * qualifiant le plus récent — cf. {@link Mesure}.
     */
    public Mesure mesureQcm(UUID userId, EpreuveType epreuve, int scanLimit) {
        // La requête rend déjà les sessions du plus récent au plus ancien : la
        // chronologie n'est pas réinventée ici, elle est consommée.
        final List<Attempt> passees =
                attemptManager.findQcmEpreuvesPassees(userId, epreuve, scanLimit);
        // 🛑 UNE requête pour toute la fenêtre balayée — le niveau n'étant plus
        // persisté, une boucle d'appels unitaires ferait un N+1 sur l'Accueil.
        final Map<UUID, Map<QuestionType, List<StrateQcm>>> strates =
                levelEstimator.stratesParAttempt(
                        passees.stream().map(Attempt::getId).toList());

        final List<Attempt> retenus = new ArrayList<>(EXAMENS_RETENUS);
        for (final Attempt a : passees) {
            // Un examen dont rien n'est exploitable n'est pas une mauvaise
            // mesure : il n'en est pas une, et il ne consomme pas une place.
            final Map<QuestionType, List<StrateQcm>> parEpreuve = strates.get(a.getId());
            if (parEpreuve == null || levelEstimator.niveauParEpreuves(parEpreuve) == null) {
                continue;
            }
            retenus.add(a);
            if (retenus.size() == EXAMENS_RETENUS) break;
        }
        if (retenus.isEmpty()) return Mesure.AUCUNE;

        // Moyenne des MESURES, jamais des labels : on CUMULE les items des
        // examens retenus strate par strate, et on relit le palier chez
        // l'autorité unique. Trente items A2 observés valent une meilleure
        // estimation que trois paliers moyennés — et surtout, il n'existe plus
        // nulle part de table « score → niveau » à recopier.
        final List<StrateQcm> cumul = new ArrayList<>();
        for (final Attempt a : retenus) {
            strates.get(a.getId()).values().forEach(cumul::addAll);
        }
        return new Mesure(levelEstimator.niveauParStrates(cumul), retenus.getFirst().getId());
    }

    /**
     * Niveau actuel estimé d'une épreuve de <b>production</b> (EE / EO) :
     * moyenne des compétences d'épreuve des {@value #EXAMENS_RETENUS} derniers
     * examens complets, puis bande.
     *
     * <p>⚠️ Même repli que pour les QCM : une session dont le palier vient des
     * niveaux persistés n'a pas de compétence moyennable ; si aucune des
     * sessions retenues n'en a, le palier de la plus récente fait foi.
     *
     * @param scanLimit sessions balayées en base ; un plafond de lecture, pas
     *                  la fenêtre de calcul
     */
    public NiveauCecrl production(UUID userId, EpreuveType epreuve, int scanLimit) {
        return mesureProduction(userId, epreuve, scanLimit).niveau();
    }

    /**
     * Le même calcul que {@link #production}, mais qui rend <b>aussi</b>
     * l'examen complet le plus récent — cf. {@link Mesure}.
     */
    /**
     * <b>« Cette epreuve est-elle mesuree, et a quel niveau ? »</b> — la question
     * posee telle quelle, sans que l'appelant ait a savoir si l'epreuve se
     * mesure par un QCM ou par des productions.
     *
     * <p>🛑 <b>Il n'existe qu'UNE notion de « mesuree »</b> dans le depot
     * (arbitrage du proprietaire, 2026-09-16) : un examen qualifiant existe, donc
     * {@code Mesure.mesuree()}. Cette methode est le point d'entree de cette
     * notion, et le plafond de lecture ({@link #SCAN_LIMIT}) y est applique une
     * fois pour toutes — un appelant qui choisirait le sien ferait dire a deux
     * ecrans deux choses differentes du meme candidat.
     *
     * <p>🛑 {@code CIVIQUE}, {@code TCF_STRUCTURE} et {@code TCF_COMPLET} ne sont
     * pas des epreuves du TCF IRN : ils rendent {@link Mesure#AUCUNE} plutot
     * qu'une exception, parce que « non mesuree » est la reponse juste — aucune
     * de ces trois valeurs ne peut porter un niveau d'epreuve.
     */
    public Mesure mesure(UUID userId, EpreuveType epreuve) {
        return switch (epreuve) {
            case TCF_CO, TCF_CE -> mesureQcm(userId, epreuve, SCAN_LIMIT);
            case TCF_EE, TCF_EO -> mesureProduction(userId, epreuve, SCAN_LIMIT);
            case CIVIQUE, TCF_STRUCTURE, TCF_COMPLET -> Mesure.AUCUNE;
        };
    }

    public Mesure mesureProduction(UUID userId, EpreuveType epreuve, int scanLimit) {
        // Le resolver rend déjà ses sessions de la plus récente à la plus
        // ancienne, et toutes portent un niveau non nul.
        final List<EpreuvesProductionQualifiantesResolver.EpreuveQualifiante> retenues =
                qualifiantesResolver.qualifiantes(userId, epreuve, scanLimit)
                        .stream().limit(EXAMENS_RETENUS).toList();
        if (retenues.isEmpty()) return Mesure.AUCUNE;
        final UUID source = retenues.getFirst().attempt().getId();

        final List<BigDecimal> competences = new ArrayList<>(retenues.size());
        for (final EpreuvesProductionQualifiantesResolver.EpreuveQualifiante q : retenues) {
            if (q.competence() != null) competences.add(q.competence());
        }
        if (competences.isEmpty()) {
            return new Mesure(levelEstimator.capB2(retenues.getFirst().niveau()), source);
        }
        return new Mesure(levelEstimator.capB2(
                bilanService.niveauDepuisCompetence(moyenne(competences))), source);
    }

    /** Moyenne arithmétique non pondérée, à l'échelle 4 comme les compétences. */
    private static BigDecimal moyenne(List<BigDecimal> valeurs) {
        BigDecimal somme = BigDecimal.ZERO;
        for (final BigDecimal v : valeurs) somme = somme.add(v);
        return somme.divide(BigDecimal.valueOf(valeurs.size()), 4, RoundingMode.HALF_UP);
    }
}
