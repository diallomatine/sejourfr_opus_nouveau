package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressionMesureDto;
import com.sejourfr.app.dto.ProgressionResumeDto;
import com.sejourfr.app.dto.ProgressionTcfDto;
import com.sejourfr.app.entity.Attempt;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.ProgressionProvenance;
import com.sejourfr.app.enums.ProgressionRapport;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le seul code à règle neuf des écrans de progression, testé aux bornes :
 * 0 / 1 / 2 / N examens, égalité au meilleur, baisse, score inconnu, ordinal,
 * examens complets partiels, durée fiable.
 */
class ResumeExamensResolverTest {

    private final ResumeExamensResolver resolver = new ResumeExamensResolver();

    /** Mesures du plus récent au plus ancien, scores donnés dans cet ordre. */
    private static List<ProgressionMesureDto> recentsDabord(Integer... scores) {
        List<ProgressionMesureDto> out = new ArrayList<>();
        Instant t = Instant.parse("2026-09-20T10:00:00Z");
        for (int i = 0; i < scores.length; i++) {
            out.add(new ProgressionMesureDto(
                    UUID.randomUUID(), ResumeExamensResolver.numero(i, scores.length),
                    t.minusSeconds(86_400L * i),
                    scores[i] == null ? null : BigDecimal.valueOf(scores[i]), 499,
                    NiveauCecrl.A2, null, null, null, null, null,
                    ProgressionProvenance.EPREUVE_SEULE,
                    new ProgressionMesureDto.Rapport(ProgressionRapport.QCM, UUID.randomUUID())));
        }
        return out;
    }

    @Nested
    class Resumer {

        @Test
        void aucunExamen_toutEstInconnuJamaisZero() {
            ProgressionResumeDto r = resolver.resumer(List.of());

            assertThat(r.nombre()).isZero();
            assertThat(r.dernier()).isNull();
            assertThat(r.meilleur()).isNull();
            assertThat(r.premier()).isNull();
            assertThat(r.ecart()).isNull();
            assertThat(r.sens()).isEqualTo(NiveauEvolution.INCONNUE);
            assertThat(r.serie()).isEmpty();
        }

        @Test
        void unSeulExamen_aucunEcart_jamaisPlusZero() {
            ProgressionResumeDto r = resolver.resumer(recentsDabord(233));

            assertThat(r.nombre()).isEqualTo(1);
            assertThat(r.dernier()).isSameAs(r.premier()).isSameAs(r.meilleur());
            assertThat(r.ecart()).isNull();
            assertThat(r.sens()).isEqualTo(NiveauEvolution.INCONNUE);
            assertThat(r.serie()).containsExactly(BigDecimal.valueOf(233));
        }

        @Test
        void deuxExamens_ecartDuPremierAuDernier() {
            List<ProgressionMesureDto> m = recentsDabord(381, 233);

            ProgressionResumeDto r = resolver.resumer(m);

            assertThat(r.dernier()).isSameAs(m.get(0));
            assertThat(r.premier()).isSameAs(m.get(1));
            assertThat(r.ecart()).isEqualByComparingTo("148");
            assertThat(r.sens()).isEqualTo(NiveauEvolution.HAUSSE);
            assertThat(r.serie()).containsExactly(BigDecimal.valueOf(233), BigDecimal.valueOf(381));
        }

        /** 🛑 Une baisse se sert : la masquer rendrait la mesure invendable. */
        @Test
        void baisse_estServie() {
            ProgressionResumeDto r = resolver.resumer(recentsDabord(200, 300));

            assertThat(r.ecart()).isEqualByComparingTo("-100");
            assertThat(r.sens()).isEqualTo(NiveauEvolution.BAISSE);
        }

        @Test
        void memeScore_estStable() {
            assertThat(resolver.resumer(recentsDabord(300, 300)).sens())
                    .isEqualTo(NiveauEvolution.STABLE);
        }

        /** À égalité, le meilleur est le plus récent. */
        @Test
        void egaliteAuMeilleur_lePlusRecentLEmporte() {
            List<ProgressionMesureDto> m = recentsDabord(300, 400, 400, 100);

            assertThat(resolver.resumer(m).meilleur()).isSameAs(m.get(1));
        }

        /**
         * Un score inconnu n'entre dans aucune comparaison — mais l'examen reste
         * le dernier s'il est le plus récent, et l'écart n'est alors pas servi.
         */
        @Test
        void scoreInconnu_neCompteDansAucuneComparaison() {
            List<ProgressionMesureDto> m = recentsDabord(null, 250, 150);

            ProgressionResumeDto r = resolver.resumer(m);

            assertThat(r.nombre()).isEqualTo(3);
            assertThat(r.dernier()).isSameAs(m.get(0));
            assertThat(r.meilleur()).isSameAs(m.get(1));
            assertThat(r.premier()).isSameAs(m.get(2));
            assertThat(r.ecart()).isNull();
            assertThat(r.sens()).isEqualTo(NiveauEvolution.INCONNUE);
            assertThat(r.serie()).containsExactly(BigDecimal.valueOf(150), BigDecimal.valueOf(250));
        }

        /** La sparkline ne garde que les 7 derniers scores, du plus ancien au plus récent. */
        @Test
        void serie_plafonneeAuxSeptDerniers() {
            ProgressionResumeDto r = resolver.resumer(recentsDabord(9, 8, 7, 6, 5, 4, 3, 2, 1));

            assertThat(r.nombre()).isEqualTo(9);
            assertThat(r.serie()).extracting(BigDecimal::intValue).containsExactly(3, 4, 5, 6, 7, 8, 9);
            // Le premier reste le plus ancien de la liste, pas de la série.
            assertThat(r.premier().score()).isEqualByComparingTo("1");
        }
    }

    @Test
    void numero_estChronologique_unEstLePlusAncien() {
        assertThat(ResumeExamensResolver.numero(0, 7)).isEqualTo(7);
        assertThat(ResumeExamensResolver.numero(6, 7)).isEqualTo(1);
    }

    @Nested
    class ExamensComplets {

        private ProgressionTcfDto.ExamenComplet examen(NiveauCecrl niveau, boolean partiel) {
            return new ProgressionTcfDto.ExamenComplet(
                    UUID.randomUUID(), 0, Instant.now(), niveau, partiel, partiel ? 2 : 4, null, List.of());
        }

        @Test
        void aucunExamen_rienAComparer() {
            ProgressionTcfDto.ExamensComplets r = resolver.resumerExamensComplets(List.of());

            assertThat(r.nombre()).isZero();
            assertThat(r.dernier()).isNull();
            assertThat(r.evolution()).isEqualTo(NiveauEvolution.INCONNUE);
        }

        /**
         * 🛑 D7 : le dernier peut être partiel ; le meilleur et le premier ne
         * regardent que les non partiels.
         */
        @Test
        void meilleurEtPremier_neRegardentQueLesNonPartiels() {
            ProgressionTcfDto.ExamenComplet recentPartielB2 = examen(NiveauCecrl.B2, true);
            ProgressionTcfDto.ExamenComplet b1 = examen(NiveauCecrl.B1, false);
            ProgressionTcfDto.ExamenComplet ancienA2 = examen(NiveauCecrl.A2, false);
            ProgressionTcfDto.ExamenComplet tresAncienPartiel = examen(NiveauCecrl.A1, true);

            ProgressionTcfDto.ExamensComplets r = resolver.resumerExamensComplets(
                    List.of(recentPartielB2, b1, ancienA2, tresAncienPartiel));

            assertThat(r.nombre()).isEqualTo(4);
            assertThat(r.dernier()).isSameAs(recentPartielB2);
            assertThat(r.meilleur()).isSameAs(b1);
            assertThat(r.premier()).isSameAs(ancienA2);
            assertThat(r.evolution()).isEqualTo(NiveauEvolution.HAUSSE);
        }

        @Test
        void unSeulNonPartiel_evolutionInconnue_jamaisStable() {
            ProgressionTcfDto.ExamensComplets r = resolver.resumerExamensComplets(
                    List.of(examen(NiveauCecrl.B1, true), examen(NiveauCecrl.B1, false)));

            assertThat(r.meilleur()).isNotNull();
            assertThat(r.evolution()).isEqualTo(NiveauEvolution.INCONNUE);
        }

        /** Un palier en vol (null) n'est ni meilleur ni premier. */
        @Test
        void palierInconnu_horsComparaison() {
            ProgressionTcfDto.ExamensComplets r = resolver.resumerExamensComplets(
                    List.of(examen(null, false)));

            assertThat(r.nombre()).isEqualTo(1);
            assertThat(r.meilleur()).isNull();
            assertThat(r.premier()).isNull();
        }
    }

    @Nested
    class DureeFiable {

        private final Instant debut = Instant.parse("2026-09-20T10:00:00Z");

        private Attempt seule(EpreuveType epreuve, Integer limite, long dureeSecondes) {
            Attempt a = new Attempt();
            a.setEpreuve(epreuve);
            a.setStartedAt(debut);
            a.setTimeLimitSeconds(limite);
            a.setFinishedAt(debut.plusSeconds(dureeSecondes));
            return a;
        }

        @Test
        void closeDansSaLimite_dureeServie() {
            assertThat(ResumeExamensResolver.dureeFiable(seule(EpreuveType.TCF_CO, 1200, 1122)))
                    .isEqualTo(1122);
        }

        @Test
        void dansLaGrace_dureeServie() {
            assertThat(ResumeExamensResolver.dureeFiable(seule(EpreuveType.TCF_CO, 1200, 1250)))
                    .isEqualTo(1250);
        }

        /** Clôture paresseuse : le finishedAt est l'heure du retour, pas de la fin. */
        @Test
        void auDelaDeLaGrace_null() {
            assertThat(ResumeExamensResolver.dureeFiable(seule(EpreuveType.TCF_CO, 1200, 7200)))
                    .isNull();
        }

        @Test
        void expressionOrale_toujoursNull() {
            assertThat(ResumeExamensResolver.dureeFiable(seule(EpreuveType.TCF_EO, 900, 300)))
                    .isNull();
        }

        @Test
        void sansLimite_null() {
            assertThat(ResumeExamensResolver.dureeFiable(seule(EpreuveType.TCF_EE, null, 300)))
                    .isNull();
        }

        /** Sous-épreuve sans ancre de lancement : on ne sait pas quand elle a commencé. */
        @Test
        void sousEpreuveSansAncre_null() {
            Attempt a = seule(EpreuveType.TCF_CE, 2100, 600);
            a.setParentAttempt(new Attempt());

            assertThat(ResumeExamensResolver.dureeFiable(a)).isNull();

            a.setTimerStartedAt(debut.plusSeconds(60));
            assertThat(ResumeExamensResolver.dureeFiable(a)).isEqualTo(540);
        }
    }
}
