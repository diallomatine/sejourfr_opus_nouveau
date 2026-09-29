package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressionMesureDto;
import com.sejourfr.app.dto.ProgressionResumeDto;
import com.sejourfr.app.dto.ProgressionTcfDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.service.attempt.AttemptChrono;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticLevelResolver;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticProgressionResolver;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * <b>Le seul code à règle réellement neuf des écrans de progression</b>
 * (étude de faisabilité §6.1) : ce qu'une liste d'examens dit une fois
 * résumée — dernier, meilleur, premier, écart, sens, série, et la durée
 * fiable d'un examen.
 *
 * <p><b>Composant pur</b> : ni base, ni horloge. Tout ce qui classe un examen
 * (palier, état civique, score) a déjà été servi par son autorité ; ce
 * resolver ne fait que les <b>ordonner et les comparer</b>. Il vit côté serveur
 * pour qu'aucun front ne recalcule un « meilleur » ou un « +148 points ».
 *
 * <p>🛑 Les écarts sont des écarts de <b>score</b>, jamais des pourcentages vers
 * un palier : on ne rend jamais « 68 % vers le B2 ».
 */
@Component
public class ResumeExamensResolver {

    /** Points de la sparkline d'une carte d'épreuve ou de thème (maquette : 7). */
    public static final int SERIE_MAX = 7;

    /**
     * Le résumé d'une liste d'examens <b>du plus récent au plus ancien</b>.
     *
     * <ul>
     *   <li>{@code dernier} : le plus récent, qu'il porte un score ou non ;</li>
     *   <li>{@code meilleur} : le plus haut score ; à égalité, le plus récent ;</li>
     *   <li>{@code premier} : le plus ancien <b>qui porte un score</b> ;</li>
     *   <li>{@code ecart} : {@code dernier − premier}, seulement avec au moins
     *       deux examens distincts qui portent un score — 🛑 jamais « +0 » à un
     *       seul examen ;</li>
     *   <li>{@code sens} : le signe de l'écart, {@code INCONNUE} sans écart ;</li>
     *   <li>{@code serie} : les {@value #SERIE_MAX} derniers scores, du plus
     *       ancien au plus récent.</li>
     * </ul>
     * Un score {@code null} (inconnu) n'entre dans aucune comparaison.
     */
    public ProgressionResumeDto resumer(List<ProgressionMesureDto> recentsDabord) {
        if (recentsDabord == null || recentsDabord.isEmpty()) {
            return new ProgressionResumeDto(0, null, null, null, null, NiveauEvolution.INCONNUE, List.of());
        }
        ProgressionMesureDto dernier = recentsDabord.getFirst();
        ProgressionMesureDto meilleur = null;
        ProgressionMesureDto premier = null;
        List<BigDecimal> serie = new ArrayList<>(SERIE_MAX);
        for (ProgressionMesureDto m : recentsDabord) {
            if (m.score() == null) continue;
            // Strictement supérieur : à égalité, le premier rencontré — donc le
            // plus récent — reste le meilleur.
            if (meilleur == null || m.score().compareTo(meilleur.score()) > 0) meilleur = m;
            premier = m;
            if (serie.size() < SERIE_MAX) serie.add(m.score());
        }
        Collections.reverse(serie);

        BigDecimal ecart = null;
        if (premier != null && dernier.score() != null && premier != dernier) {
            ecart = dernier.score().subtract(premier.score());
        }
        return new ProgressionResumeDto(
                recentsDabord.size(), dernier, meilleur, premier, ecart, sens(ecart), List.copyOf(serie));
    }

    /** Le signe d'un écart ; {@code INCONNUE} sans écart, jamais {@code STABLE}. */
    public static NiveauEvolution sens(BigDecimal ecart) {
        if (ecart == null) return NiveauEvolution.INCONNUE;
        int signe = ecart.signum();
        if (signe > 0) return NiveauEvolution.HAUSSE;
        if (signe < 0) return NiveauEvolution.BAISSE;
        return NiveauEvolution.STABLE;
    }

    /**
     * Ordinal chronologique d'un examen dans une liste <b>du plus récent au
     * plus ancien</b> de {@code total} examens : 1 = le plus ancien. 🛑 Jamais
     * le {@code slotNumber}, créneau de grille réutilisé à chaque rejeu (D8).
     */
    public static int numero(int indexRecentsDabord, int total) {
        return total - indexRecentsDabord;
    }

    /**
     * 🛑 <b>D7</b> — les encarts des examens complets, sur une liste <b>déjà
     * restreinte</b> aux examens terminés dont au moins une épreuve est
     * mesurée, du plus récent au plus ancien.
     *
     * <ul>
     *   <li>{@code dernier} : le plus récent, partiel ou non ;</li>
     *   <li>{@code meilleur} / {@code premier} : parmi les seuls examens
     *       <b>non partiels</b> portant un palier — le plus haut palier (à
     *       égalité, le plus récent) et le plus ancien ;</li>
     *   <li>{@code evolution} : du premier au dernier non partiel, par
     *       l'autorité existante des comparaisons de paliers ;
     *       {@code INCONNUE} avec moins de deux examens non partiels.</li>
     * </ul>
     */
    public ProgressionTcfDto.ExamensComplets resumerExamensComplets(
            List<ProgressionTcfDto.ExamenComplet> recentsDabord) {
        if (recentsDabord == null || recentsDabord.isEmpty()) {
            return new ProgressionTcfDto.ExamensComplets(0, null, null, null, NiveauEvolution.INCONNUE);
        }
        ProgressionTcfDto.ExamenComplet dernierComplet = null;
        ProgressionTcfDto.ExamenComplet meilleur = null;
        ProgressionTcfDto.ExamenComplet premier = null;
        int nonPartiels = 0;
        for (ProgressionTcfDto.ExamenComplet e : recentsDabord) {
            if (e.partiel() || e.niveau() == null) continue;
            nonPartiels++;
            if (dernierComplet == null) dernierComplet = e;
            if (meilleur == null
                    || TcfDiagnosticLevelResolver.rang(e.niveau())
                    > TcfDiagnosticLevelResolver.rang(meilleur.niveau())) {
                meilleur = e;
            }
            premier = e;
        }
        NiveauEvolution evolution = nonPartiels < 2
                ? NiveauEvolution.INCONNUE
                : TcfDiagnosticProgressionResolver.evolution(premier.niveau(), dernierComplet.niveau());
        return new ProgressionTcfDto.ExamensComplets(
                recentsDabord.size(), recentsDabord.getFirst(), meilleur, premier, evolution);
    }

    /**
     * 🛑 <b>D9</b> — durée d'un examen, <b>seulement si elle est fiable</b>.
     *
     * <p>Une épreuve dépassée est clôturée « à la lecture suivante »
     * ({@code docs/regles/examens-temps.md}) : son {@code finishedAt} est alors
     * l'heure du <b>retour</b> du candidat, pas celle où il a fini. On ne sert
     * donc une durée que si l'examen s'est clos <b>dans sa limite + la grâce de
     * soumission</b>, à partir d'une ancre connue ({@link AttemptChrono}, la
     * seule autorité du chrono). {@code null} sinon — et toujours en EO, qui n'a
     * pas de chrono d'épreuve (son garde-fou de session n'en est pas un).
     */
    public static Integer dureeFiable(Attempt attempt) {
        if (attempt == null || attempt.getEpreuve() == EpreuveType.TCF_EO) return null;
        Instant fin = attempt.getFinishedAt();
        Instant ancre = AttemptChrono.ancre(attempt);
        Instant limite = AttemptChrono.echeanceAvecGrace(attempt);
        if (fin == null || ancre == null || limite == null) return null;
        if (fin.isAfter(limite) || fin.isBefore(ancre)) return null;
        return Math.toIntExact(Duration.between(ancre, fin).getSeconds());
    }
}
