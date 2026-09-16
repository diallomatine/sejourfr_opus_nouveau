package com.sejourfr.app.service;

import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.manager.AttemptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
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
 * « Voir mes résultats » ({@code EpreuveHistoriqueService}).
 *
 * <p>⚠️ <b>La lecture du PLAN n'est PAS concernée</b>
 * ({@code TcfProfileService.levelProfile}) : elle garde son maximum sur toute
 * observation, entraînement compris — arbitrage du propriétaire du même jour.
 * Ce resolver ne sert que l'<b>affichage</b> du niveau actuel.
 *
 * <h2>Ce qui compte comme « examen qualifiant »</h2>
 * <p>🛑 <b>Aucune définition n'est écrite ici</b> : les deux qui existent sont
 * appelées, et ce sont les mêmes que celles de la page « Voir mes résultats ».
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
 * <h2>On moyenne des SCORES, jamais des labels</h2>
 * <p>Un niveau CECRL est une <b>bande</b>, pas une graduation : « la moyenne de
 * A2 et B2 » n'a pas de sens arithmétique, et la calculer sur les ordinaux d'un
 * enum ferait dépendre le résultat de l'ordre de déclaration. Chaque épreuve a
 * donc son score numérique interne, déjà calculé ailleurs :
 * <ul>
 *   <li><b>CO / CE</b> : le <b>score calibré 100-499</b>
 *       ({@code TcfLevelEstimatorService.calibratedScore}, celui qu'affichent
 *       les cartes d'examen) ;</li>
 *   <li><b>EE / EO</b> : la <b>compétence /20</b> de l'épreuve
 *       ({@code ProductionBilanService.NiveauEpreuve.competence}), l'agrégat
 *       pondéré des 3 tâches dont le palier de session est déjà la bande.</li>
 * </ul>
 * La moyenne est arithmétique et <b>non pondérée</b> : les trois examens
 * retenus mesurent la même épreuve dans les mêmes conditions, rien ne justifie
 * d'en privilégier un.
 *
 * <h2>🛑 La conversion score → CECRL passe par la table EXISTANTE</h2>
 * <p>{@code TcfLevelEstimatorService.niveauDepuisScoreCalibre} pour les QCM,
 * {@code ProductionBilanService.niveauDepuisCompetence} pour les productions.
 * <b>Aucun seuil n'est recopié ici</b> — la table des paliers a déjà vécu en
 * six copies dans ce dépôt.
 *
 * <p><b>Règle de bande</b> : les deux tables sont des <b>bornes basses</b>
 * ({@code >=}), donc une moyenne qui tombe <b>entre deux bandes reste dans la
 * bande BASSE</b> — la convention déjà en vigueur pour les notes de critère.
 * Côté QCM, la moyenne des scores calibrés est ramenée à l'entier
 * <b>inférieur</b> ({@link RoundingMode#FLOOR}) avant conversion, ce qui est
 * exactement la même décision : 399,9 reste B1, 400,0 devient B2.
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
     * <p>Même valeur que {@code EpreuveHistoriqueService.MAX_EVALUATIONS}, et
     * c'est une coïncidence <b>voulue mais pas partagée</b> : là-bas c'est un
     * plafond d'AFFICHAGE, ici une fenêtre de CALCUL. Les lier ferait d'un
     * réglage d'écran un réglage de règle métier.
     */
    public static final int EXAMENS_RETENUS = 3;

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
     * son historique par le plus récent, et « Voir mes résultats »
     * ({@code EpreuveHistoriqueService}) reste l'écran qui les montre tous.
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
     * moyenne des scores calibrés des {@value #EXAMENS_RETENUS} derniers
     * examens qualifiants, puis bande.
     *
     * <p>Le <b>plancher produit</b> « au moins une bonne réponse ⇒ au moins
     * A1 » est réappliqué par-dessus, par sa propre autorité
     * ({@code TcfLevelEstimatorService.plancherA1SiUneBonneReponse}) : il est
     * vrai de la moyenne dès qu'il était vrai d'un des examens retenus.
     *
     * <p>⚠️ Un examen ancien dont le score pondéré n'a pas été enregistré ne
     * porte pas de score moyennable ; il garde son palier persisté et sert de
     * <b>repli</b> si aucun des examens retenus n'a de score. Ce n'est pas une
     * seconde règle : c'est {@code niveauEpreuveQcm}, déjà l'autorité du palier
     * d'UN examen.
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
        final List<Attempt> retenus = new ArrayList<>(EXAMENS_RETENUS);
        // La requête rend déjà les sessions du plus récent au plus ancien : la
        // chronologie n'est pas réinventée ici, elle est consommée.
        for (final Attempt a : attemptManager.findQcmEpreuvesPassees(userId, epreuve, scanLimit)) {
            // Un examen dont rien n'est exploitable n'est pas une mauvaise
            // mesure : il n'en est pas une, et il ne consomme pas une place.
            if (levelEstimator.niveauEpreuveQcm(a) == null) continue;
            retenus.add(a);
            if (retenus.size() == EXAMENS_RETENUS) break;
        }
        if (retenus.isEmpty()) return Mesure.AUCUNE;
        final UUID source = retenus.getFirst().getId();

        final List<BigDecimal> scores = new ArrayList<>(retenus.size());
        boolean auMoinsUneBonneReponse = false;
        for (final Attempt a : retenus) {
            if (a.getWeightedScore() != null && a.getWeightedScore() > 0) {
                auMoinsUneBonneReponse = true;
            }
            if (a.getWeightedScore() == null || a.getMaxWeightedScore() == null) continue;
            scores.add(BigDecimal.valueOf(levelEstimator.calibratedScore(
                    a.getWeightedScore(), a.getMaxWeightedScore())));
        }
        if (scores.isEmpty()) {
            // Aucun score moyennable : le palier du plus récent des examens
            // retenus fait foi — « 1 examen → le niveau de cet examen ».
            return new Mesure(levelEstimator.niveauEpreuveQcm(retenus.getFirst()), source);
        }
        final int moyenne = moyenne(scores).setScale(0, RoundingMode.FLOOR).intValueExact();
        return new Mesure(levelEstimator.plancherA1SiUneBonneReponse(
                levelEstimator.niveauDepuisScoreCalibre(moyenne), auMoinsUneBonneReponse), source);
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
