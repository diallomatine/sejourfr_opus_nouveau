package com.sejourfr.app.service.progres;

import com.sejourfr.app.config.CivicDiagnosticProperties;
import com.sejourfr.app.dto.ProgressionEchelleDto;
import com.sejourfr.app.enums.CivicExamFormat;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ProgressionEtatSource;
import com.sejourfr.app.enums.ProgressionUnite;
import com.sejourfr.app.service.diagnosticcivique.CivicDiagnosticThemeResolver;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;

/**
 * Les axes servis des écrans de progression : aucune bande en CO/CE (D2), les
 * bandes officielles en EE/EO (D3), les bandes d'état civiques DÉRIVÉES des
 * seuils du resolver (D12) — la borne « Solide » tombant sur le seuil de
 * réussite.
 */
class ProgressionEchelleResolverTest {

    private final ProgressionEchelleResolver resolver = new ProgressionEchelleResolver(
            new CivicDiagnosticThemeResolver(new CivicDiagnosticProperties()));

    /** 🛑 D2 : aucune bande CECRL sur le score de progression. */
    @Test
    void comprehension_scoreDeProgressionSansAucuneBande() {
        for (EpreuveType e : new EpreuveType[]{EpreuveType.TCF_CO, EpreuveType.TCF_CE}) {
            ProgressionEchelleDto ech = resolver.tcf(e);

            assertThat(ech.unite()).isEqualTo(ProgressionUnite.PROGRESSION_499);
            assertThat(ech.min()).isEqualTo(100);
            assertThat(ech.max()).isEqualTo(499);
            assertThat(ech.bandes()).isEmpty();
            assertThat(ech.seuil()).isNull();
        }
    }

    /** D3 : la note /20 et ses bandes officielles 0 · 1 · 2–5 · 6–9 · 10–20. */
    @Test
    void expression_noteSur20AvecLesBandesOfficielles() {
        ProgressionEchelleDto ech = resolver.tcf(EpreuveType.TCF_EO);

        assertThat(ech.unite()).isEqualTo(ProgressionUnite.NOTE_20);
        assertThat(ech.max()).isEqualTo(20);
        assertThat(ech.bandes())
                .extracting(ProgressionEchelleDto.Bande::niveau,
                        ProgressionEchelleDto.Bande::min, ProgressionEchelleDto.Bande::max)
                .containsExactly(
                        tuple(NiveauCecrl.A1_NON_ATTEINT, 0, 0),
                        tuple(NiveauCecrl.A1, 1, 1),
                        tuple(NiveauCecrl.A2, 2, 5),
                        tuple(NiveauCecrl.B1, 6, 9),
                        tuple(NiveauCecrl.B2, 10, 20));
    }

    /** D12 : Faible 0–10 · À renforcer 11–15 · Solide 16–20, seuil 16. */
    @Test
    void examenDeTheme_bandesDEtatSur20() {
        ProgressionEchelleDto ech = resolver.civique(
                CivicExamFormat.QUESTIONS_THEME, CivicExamFormat.SEUIL_REUSSITE_THEME);

        assertThat(ech.unite()).isEqualTo(ProgressionUnite.QUESTIONS);
        assertThat(ech.seuil()).isEqualTo(16);
        assertThat(ech.bandes())
                .extracting(ProgressionEchelleDto.Bande::etat,
                        ProgressionEchelleDto.Bande::min, ProgressionEchelleDto.Bande::max)
                .containsExactly(
                        tuple(CivicThemeState.FAIBLE, 0, 10),
                        tuple(CivicThemeState.A_RENFORCER, 11, 15),
                        tuple(CivicThemeState.SOLIDE, 16, 20));
        // La borne « Solide » est le seuil de réussite.
        assertThat(ech.bandes().getLast().min()).isEqualTo(ech.seuil());
    }

    /** D12 : Faible 0–21 · À renforcer 22–31 · Solide 32–40, seuil 32. */
    @Test
    void examenGlobal_bandesDEtatSur40() {
        ProgressionEchelleDto ech = resolver.civique(CivicExamFormat.QUESTIONS, CivicExamFormat.SEUIL_REUSSITE);

        assertThat(ech.max()).isEqualTo(40);
        assertThat(ech.bandes())
                .extracting(ProgressionEchelleDto.Bande::etat,
                        ProgressionEchelleDto.Bande::min, ProgressionEchelleDto.Bande::max)
                .containsExactly(
                        tuple(CivicThemeState.FAIBLE, 0, 21),
                        tuple(CivicThemeState.A_RENFORCER, 22, 31),
                        tuple(CivicThemeState.SOLIDE, 32, 40));
        assertThat(ech.bandes().getLast().min()).isEqualTo(ech.seuil());
    }

    /** Libellé recopié à la main dans les fronts : gelé ici. */
    @Test
    void libelleDeLaSourceDeLEtat_estGele() {
        assertThat(ProgressionEtatSource.DERNIER_EXAMEN_THEME.getLabel())
                .isEqualTo("D'après votre dernier examen de ce thème");
    }
}
