package com.sejourfr.app.service;

import com.sejourfr.app.dto.LigneStrateQcm;
import com.sejourfr.app.dto.QcmAnswerResult;
import com.sejourfr.app.dto.StrateQcm;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.Difficulty;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.QuestionType;
import com.sejourfr.app.manager.AttemptQuestionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 🛑 <b>Autorité UNIQUE du niveau CECRL d'un QCM TCF (CO / CE).</b>
 * {@code AttemptScoringService}, {@code AttemptMapper}, {@code TcfProfileService},
 * {@code NiveauActuelEpreuveResolver}, {@code EpreuveHistoriqueService} et
 * {@code FullTcfExamResponseBuilder} en héritent <b>sans une ligne de règle</b>.
 *
 * <h2>La règle : le plus haut palier MAÎTRISÉ, sans saut (2026-09-20)</h2>
 * <p>Le niveau rendu est le plus haut palier tel que <b>tous les paliers
 * inférieurs sont également maîtrisés</b>. Une strate est maîtrisée à
 * <b>{@value #SEUIL_MAITRISE_STRATE_PCT} %</b> de ses items, <b>arrondi à
 * l'entier supérieur</b>. <b>Pas de saut de palier</b> : si l'A2 n'est pas
 * tenu, le résultat est {@code A1} même si le B1 passe. Zéro bonne réponse sur
 * l'épreuve entière ⇒ {@code A1_NON_ATTEINT} ; au moins une, sans strate
 * maîtrisée ⇒ {@code A1}.
 *
 * <p>Sur la composition 10 A2 / 8 B1 / 7 B2, cela donne <b>6/10</b>,
 * <b>5/8</b> et <b>5/7</b>.
 *
 * <p><b>Pourquoi 60 % et pas 50, ni 70</b> (arbitrage du propriétaire) : le
 * seuil se choisit sur la probabilité de décrocher le palier <b>en cliquant au
 * hasard</b>, parce qu'un niveau affiché pousse quelqu'un à s'inscrire au vrai
 * TCF, qui est payant. À 5/10 (50 %) un débutant qui répond au hasard décroche
 * A2 <b>une fois sur treize</b> ; à 6/10, une fois sur cinquante (1,97 % ;
 * 2,73 % pour 5/8 ; 1,29 % pour 5/7). À 70 % il fallait la quasi-perfection
 * (0,35 %). Le seuil est <b>le même pour les trois strates</b>.
 *
 * <p><b>Ce que cela répare.</b> Le niveau venait d'un score pondéré (A2=1,
 * B1=2, B2=3) corrigé du hasard à 25 %, puis d'une bande (≥400 B2 · ≥300 B1 ·
 * ≥200 A2 · ≥101 A1). Sur un examen stratifié 8 A2 / 9 B1 / 8 B2, la strate A2
 * ne pesait que 8/50 = 16 % du pondéré, donc <b>sous la ligne de hasard</b> :
 * maîtriser tout l'A2 et rien d'autre donnait 100/499, soit « A1 non atteint ».
 * <b>La bande A2 était inatteignable par un candidat A2</b> — il fallait toute
 * la strate A2 <i>plus</i> 7 B1 sur 9, c'est-à-dire être B1. Mesuré : B1 et B2
 * sortaient juste, seule la bande A2 était morte. Le plancher A1 du 2026-08-17
 * ({@code plancherA1SiUneBonneReponse}) traitait le symptôme ; il est
 * <b>supprimé</b>, le modèle par strate rendant déjà {@code A1} à qui a au
 * moins une bonne réponse sans strate maîtrisée.
 *
 * <h2>Dérivation À LA LECTURE</h2>
 * <p>🛑 {@code attempts.cecrl_level} n'est <b>plus écrit ni lu</b> : le niveau
 * est une <b>fonction pure des réponses</b> (doctrine du dépôt — un dérivé se
 * relit, il ne se persiste pas). C'est ce qui fait qu'un changement de règle
 * relit tout l'historique sans migration ni recalcul.
 *
 * <p>⚠️ Corollaire : tout écran de <b>liste</b> passe par la forme groupée
 * ({@link #niveauxQcm(Collection)}), jamais par une boucle sur
 * {@link #niveauEpreuveQcm(Attempt)} — une requête pour la page, pas une par
 * ligne.
 *
 * <h2>Le score 100-499 n'est PAS un niveau</h2>
 * <p>{@link #calibratedScore} survit comme <b>score de progression</b> : une
 * mesure continue qui dit si on avance. Il ne <b>dérive plus aucun palier</b> —
 * la bande et la correction du hasard ne servent plus à classer, et il n'existe
 * plus nulle part de conversion « score → niveau ». Le vrai relevé TCF a une
 * échelle officielle que nous n'avons pas, et les fronts le présentent en
 * conséquence.
 */
@Service
@RequiredArgsConstructor
public class TcfLevelEstimatorService {

    /** Poids par strate pour le score de progression (A2=1, B1=2, B2=3). */
    private static final Map<Difficulty, Integer> WEIGHTS =
            Map.of(Difficulty.A2, 1, Difficulty.B1, 2, Difficulty.B2, 3);

    /** Base et amplitude du score de progression (100 → 499). */
    private static final int SCORE_BASE = 100;
    private static final int SCORE_SPAN = 399;

    /**
     * Ligne de base du hasard d'un QCM à 4 choix : ~25 % de réussite pondérée
     * sans aucune connaissance. Le score de progression est mesuré au-dessus de
     * cette ligne — sans correction, un passage 100 % aléatoire atteignait ~200.
     */
    private static final double GUESS_BASELINE = 0.25;

    /**
     * Part des items d'une strate à réussir pour la dire maîtrisée,
     * <b>arrondie à l'entier supérieur</b> (cf. {@link #itemsRequis}).
     */
    public static final int SEUIL_MAITRISE_STRATE_PCT = 60;

    /**
     * Les paliers observables d'un QCM TCF, <b>du plus bas au plus haut</b>.
     * L'ordre EST la règle : la montée s'arrête au premier palier non maîtrisé.
     */
    private static final List<Difficulty> PALIERS =
            List.of(Difficulty.A2, Difficulty.B1, Difficulty.B2);

    private final AttemptQuestionManager attemptQuestionManager;

    // ══════════════════════════════════════════════════════════════════════
    //  LA RÈGLE
    // ══════════════════════════════════════════════════════════════════════

    /**
     * <b>LA règle du niveau QCM</b>, et le seul endroit du dépôt où elle
     * s'écrit : le plus haut palier maîtrisé sans saut.
     *
     * <p>Une strate est maîtrisée quand elle porte au moins un item <b>et</b>
     * qu'au moins {@link #itemsRequis} d'entre eux sont réussis. La montée
     * s'arrête au premier palier non maîtrisé : un candidat qui rate l'A2 reste
     * {@code A1}, même s'il tient le B1.
     *
     * <p>⚠️ <b>Une strate sans item n'est pas maîtrisée</b> — elle n'a rien
     * démontré, et la montée s'y arrête. Ce n'est pas la traiter comme un
     * échec : sans elle, on ne peut pas <i>affirmer</i> le palier suivant, et
     * un garde-fou ne peut qu'abaisser. Le cas ne se produit pas sur un examen
     * stratifié, dont les trois strates sont garanties à la composition.
     *
     * @return {@code null} si <b>aucun</b> item de palier CECRL n'a été posé —
     *         inconnu, jamais {@code A1_NON_ATTEINT} (doctrine du dépôt :
     *         <i>null = inconnu, jamais mauvais</i>)
     */
    public NiveauCecrl niveauParStrates(Collection<StrateQcm> strates) {
        if (strates == null || strates.isEmpty()) return null;
        Map<Difficulty, StrateQcm> parPalier = new EnumMap<>(Difficulty.class);
        int posesTotal = 0;
        int reussisTotal = 0;
        for (StrateQcm s : strates) {
            if (s == null || !PALIERS.contains(s.palier())) continue;
            StrateQcm deja = parPalier.get(s.palier());
            StrateQcm cumul = deja == null ? s : new StrateQcm(
                    s.palier(),
                    deja.poses() + s.poses(),
                    deja.repondus() + s.repondus(),
                    deja.reussis() + s.reussis());
            parPalier.put(s.palier(), cumul);
            posesTotal += s.poses();
            reussisTotal += s.reussis();
        }
        if (posesTotal == 0) return null;

        NiveauCecrl atteint = null;
        for (Difficulty palier : PALIERS) {
            StrateQcm s = parPalier.get(palier);
            if (s == null || !maitrisee(s)) break;
            atteint = palierCecrl(palier);
        }
        if (atteint != null) return atteint;

        // Au moins une bonne réponse, mais aucune strate tenue : A1 est le
        // plancher réel du dispositif.
        if (reussisTotal > 0) return NiveauCecrl.A1;

        // ════════════════════════════════════════════════════════════════
        // 🛑 DEUX SITUATIONS TOMBENT ICI, ET CE N'EST PAS LA MÊME CHOSE
        // ════════════════════════════════════════════════════════════════
        // `repondus > 0` : le candidat a répondu, tout est faux. Là,
        //     `A1_NON_ATTEINT` est bien un verdict de langue.
        // `repondus == 0` : la session a été OUVERTE PUIS ABANDONNÉE. Ce n'est
        //     pas un verdict, c'est une absence de mesure.
        //
        // Les deux rendent le même `A1_NON_ATTEINT` — c'est le comportement
        // d'avant, conservé tel quel, et ce n'est PAS arbitré. La donnée qui
        // les sépare est déjà portée (`StrateQcm.repondus`, et l'agrégat SQL
        // qui l'alimente) : le jour où l'abandon doit rendre `null`, il n'y a
        // qu'ici à brancher. Cf. docs/regles/qcm.md.
        return NiveauCecrl.A1_NON_ATTEINT;
    }

    /** Une strate est-elle maîtrisée ? {@link #itemsRequis} réussis, au moins. */
    private static boolean maitrisee(StrateQcm s) {
        return s.poses() > 0 && s.reussis() >= itemsRequis(s.poses());
    }

    /**
     * Items à réussir pour maîtriser une strate de {@code poses} items :
     * {@value #SEUIL_MAITRISE_STRATE_PCT} % <b>arrondis à l'entier
     * supérieur</b>, en arithmétique entière — une strate de 8 ou de 7 items ne
     * tombe pas sur un compte rond, et un arrondi flottant y jouerait le palier
     * à l'ulp près. Donne 6/10, 5/8 et 5/7 sur la composition d'un examen.
     */
    public static int itemsRequis(int poses) {
        return (poses * SEUIL_MAITRISE_STRATE_PCT + 99) / 100;
    }

    /**
     * Niveau CECRL d'<b>une</b> épreuve QCM à partir de ses réponses en
     * mémoire — la même règle que {@link #niveauParStrates}, à laquelle elle
     * délègue après avoir replié les réponses en strates.
     *
     * @return {@code null} si rien d'exploitable n'a été posé
     */
    public NiveauCecrl estimateQcm(List<QcmAnswerResult> answers) {
        if (answers == null || answers.isEmpty()) return null;
        Map<Difficulty, int[]> acc = new EnumMap<>(Difficulty.class);
        for (QcmAnswerResult a : answers) {
            if (a.difficulty() == null) continue;
            int[] c = acc.computeIfAbsent(a.difficulty(), k -> new int[2]);
            c[0]++;
            if (a.correct()) c[1]++;
        }
        // ⚠️ `QcmAnswerResult` ne dit pas si la question a reçu une réponse :
        // il ne porte que « juste / pas juste ». Les items sont donc comptés
        // comme répondus. Ce chemin sert la notation d'une session qu'on vient
        // de terminer, où la distinction « abandon » ne se pose pas — la forme
        // qui la porte est l'agrégat SQL.
        List<StrateQcm> strates = new ArrayList<>(acc.size());
        acc.forEach((d, c) -> strates.add(StrateQcm.mesuree(d, c[0], c[1])));
        return niveauParStrates(strates);
    }

    /**
     * Niveau d'une tentative qui peut porter <b>plusieurs épreuves</b>
     * (diagnostic TCF sectionné CO puis CE) : le niveau de chaque épreuve, puis
     * leur <b>plancher</b> — règle du TCF IRN, il faut le niveau partout.
     * {@code CO_IMAGE} est repliée sous {@code CO} : c'est la même épreuve.
     */
    public NiveauCecrl niveauParEpreuves(Map<QuestionType, List<StrateQcm>> parEpreuve) {
        if (parEpreuve == null || parEpreuve.isEmpty()) return null;
        List<NiveauCecrl> niveaux = new ArrayList<>(parEpreuve.size());
        for (List<StrateQcm> strates : parEpreuve.values()) {
            niveaux.add(niveauParStrates(strates));
        }
        return floor(niveaux);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  LECTURE — dérivée des réponses, jamais d'une colonne
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Niveau CECRL d'<b>une</b> épreuve QCM passée (CO/CE), dérivé de ses
     * réponses. {@code attempts.cecrl_level} n'est plus lu : un niveau se
     * recalcule, il ne se relit pas.
     *
     * <p>⚠️ <b>Une requête.</b> Sur une liste, passer par
     * {@link #niveauxQcm(Collection)} — une boucle ici est un N+1.
     *
     * @return {@code null} si la tentative ne porte aucun item exploitable —
     *         inconnu, jamais {@code A1_NON_ATTEINT}
     */
    public NiveauCecrl niveauEpreuveQcm(Attempt attempt) {
        if (attempt == null || attempt.getId() == null) return null;
        return niveauxQcm(List.of(attempt.getId())).get(attempt.getId());
    }

    /**
     * 🛑 <b>La forme à utiliser sur tout écran de LISTE</b> : les niveaux de
     * toutes les tentatives de la page en <b>une seule requête agrégée</b>
     * (historique, profil TCF, « Voir mes résultats », liste des examens
     * blancs, bilan d'examen complet).
     *
     * @return une entrée par tentative <b>qui porte un niveau</b> ; une
     *         tentative sans item exploitable est absente de la map —
     *         {@code get()} y rend {@code null}, c'est-à-dire inconnu
     */
    public Map<UUID, NiveauCecrl> niveauxQcm(Collection<UUID> attemptIds) {
        Map<UUID, Map<QuestionType, List<StrateQcm>>> parAttempt =
                stratesParAttempt(attemptIds);
        Map<UUID, NiveauCecrl> out = new HashMap<>(parAttempt.size());
        parAttempt.forEach((id, parEpreuve) -> {
            NiveauCecrl niveau = niveauParEpreuves(parEpreuve);
            if (niveau != null) out.put(id, niveau);
        });
        return out;
    }

    /**
     * Les strates des tentatives demandées, ventilées par épreuve
     * ({@code CO_IMAGE} repliée sous {@code CO}) — <b>une seule requête</b>.
     * Publique parce que deux lecteurs ont besoin des strates elles-mêmes et
     * pas seulement du palier : {@code NiveauActuelEpreuveResolver}, qui les
     * <b>cumule</b> sur les derniers examens, et les tests qui gèlent la règle.
     */
    public Map<UUID, Map<QuestionType, List<StrateQcm>>> stratesParAttempt(
            Collection<UUID> attemptIds) {
        Map<UUID, Map<QuestionType, List<StrateQcm>>> out = new LinkedHashMap<>();
        for (LigneStrateQcm ligne : attemptQuestionManager.stratesParAttempt(attemptIds)) {
            QuestionType epreuve = ligne.epreuve() == QuestionType.CO_IMAGE
                    ? QuestionType.CO
                    : ligne.epreuve();
            out.computeIfAbsent(ligne.attemptId(), k -> new LinkedHashMap<>())
                    .computeIfAbsent(epreuve, k -> new ArrayList<>())
                    .add(ligne.strate());
        }
        return out;
    }

    // ══════════════════════════════════════════════════════════════════════
    //  SCORE DE PROGRESSION — une mesure continue, pas un palier
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Score de progression 100-499 d'un QCM, dérivé du poids obtenu / poids
     * max. 🛑 <b>Ce n'est pas un niveau, et rien n'en dérive de palier</b> :
     * c'est une mesure continue qui dit si on avance.
     */
    public int calibratedScore(List<QcmAnswerResult> answers) {
        int maxW = answers.stream().mapToInt(a -> weight(a.difficulty())).sum();
        int gotW = answers.stream()
                .filter(QcmAnswerResult::correct)
                .mapToInt(a -> weight(a.difficulty())).sum();
        return calibratedScore(gotW, maxW);
    }

    /**
     * Variante depuis un score pondéré déjà calculé (weighted / maxWeighted).
     * Le ratio est corrigé du hasard : {@code (ratio − 0.25) / 0.75}, borné à
     * [0, 1]. Hasard pur → 100 ; sans-faute → 499.
     */
    public int calibratedScore(Integer weighted, Integer maxWeighted) {
        if (weighted == null || maxWeighted == null || maxWeighted <= 0) return SCORE_BASE;
        double ratio = Math.min(1.0, (double) weighted / maxWeighted);
        double net = Math.max(0.0, (ratio - GUESS_BASELINE) / (1.0 - GUESS_BASELINE));
        return (int) Math.round(SCORE_BASE + net * SCORE_SPAN);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  ALGÈBRE DES PALIERS
    // ══════════════════════════════════════════════════════════════════════

    /** Plafonne tout niveau à B2 (cadre IRN). C1/C2 → B2. */
    public NiveauCecrl capB2(NiveauCecrl level) {
        if (level == null) return null;
        return level.ordinal() > NiveauCecrl.B2.ordinal() ? NiveauCecrl.B2 : level;
    }

    /** Plancher (le plus faible) de plusieurs niveaux, en ignorant les null, plafonné B2. */
    public NiveauCecrl floor(List<NiveauCecrl> levels) {
        NiveauCecrl floor = null;
        for (NiveauCecrl l : levels) {
            floor = min(floor, l);
        }
        return capB2(floor);
    }

    /** Min ordinal, en tolérant les null (un null est « inconnu », pas un plancher). */
    public NiveauCecrl min(NiveauCecrl a, NiveauCecrl b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.ordinal() <= b.ordinal() ? a : b;
    }

    /**
     * Max ordinal, en tolérant les null (miroir de {@link #min} : un null est
     * « inconnu », pas un plafond). Sert au « meilleur résultat » d'une épreuve
     * dans le profil de niveau du candidat.
     */
    public NiveauCecrl max(NiveauCecrl a, NiveauCecrl b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.ordinal() >= b.ordinal() ? a : b;
    }

    private static NiveauCecrl palierCecrl(Difficulty palier) {
        return switch (palier) {
            case A2 -> NiveauCecrl.A2;
            case B1 -> NiveauCecrl.B1;
            case B2 -> NiveauCecrl.B2;
            default -> null;
        };
    }

    private static int weight(Difficulty d) {
        return d == null ? 0 : WEIGHTS.getOrDefault(d, 0);
    }
}
