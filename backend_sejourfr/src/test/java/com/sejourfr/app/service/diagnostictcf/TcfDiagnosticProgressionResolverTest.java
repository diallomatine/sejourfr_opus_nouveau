package com.sejourfr.app.service.diagnostictcf;

import com.sejourfr.app.config.TcfDiagnosticProperties;
import com.sejourfr.app.dto.TcfDiagnosticProgressionDto;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;
import com.sejourfr.app.service.diagnostictcf.TcfDiagnosticReadService.Section;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La comparaison de deux diagnostics (L7).
 *
 * <p>Ce qui est verrouille ici est <b>une seule chose</b>, et c'est celle qui
 * fait mal : une epreuve non evaluee d'un cote ne devient jamais « stable ».
 */
class TcfDiagnosticProgressionResolverTest {

    private final TcfDiagnosticProgressionResolver resolver =
            new TcfDiagnosticProgressionResolver(
                    new TcfDiagnosticLevelResolver(new TcfDiagnosticProperties()));

    private static Section section(EpreuveType epreuve, NiveauCecrl niveau) {
        return new Section(epreuve, UUID.randomUUID(),
                TcfDiagnosticSectionState.TERMINEE, null, niveau);
    }

    @Test
    @DisplayName("Une épreuve montée d'un palier remonte HAUSSE, et le global suit son plancher")
    void hausse() {
        List<Section> avant = List.of(
                section(EpreuveType.TCF_CO, NiveauCecrl.B1),
                section(EpreuveType.TCF_EE, NiveauCecrl.A2));
        List<Section> apres = List.of(
                section(EpreuveType.TCF_CO, NiveauCecrl.B1),
                section(EpreuveType.TCF_EE, NiveauCecrl.B1));

        TcfDiagnosticProgressionDto p = resolver.comparer(
                UUID.randomUUID(), Instant.parse("2026-03-12T10:00:00Z"), avant, apres);

        assertThat(p.epreuves()).extracting(
                        TcfDiagnosticProgressionDto.EpreuveEvolution::epreuve,
                        TcfDiagnosticProgressionDto.EpreuveEvolution::evolution)
                .containsExactly(
                        org.assertj.core.groups.Tuple.tuple(
                                EpreuveType.TCF_CO, NiveauEvolution.STABLE),
                        org.assertj.core.groups.Tuple.tuple(
                                EpreuveType.TCF_EE, NiveauEvolution.HAUSSE));
        // Le plancher passe de A2 a B1 : c'est ce que l'ecran annonce.
        assertThat(p.previousNiveauGlobal()).isEqualTo(NiveauCecrl.A2);
        assertThat(p.niveauGlobal()).isEqualTo(NiveauEvolution.HAUSSE);
    }

    @Test
    @DisplayName("🛑 Non évaluée AVANT ⇒ INCONNUE, jamais STABLE ni HAUSSE")
    void nonEvalueeAvant() {
        List<Section> avant = List.of(section(EpreuveType.TCF_EO, null));
        List<Section> apres = List.of(section(EpreuveType.TCF_EO, NiveauCecrl.B1));

        TcfDiagnosticProgressionDto p =
                resolver.comparer(UUID.randomUUID(), Instant.now(), avant, apres);

        assertThat(p.epreuves()).singleElement()
                .extracting(TcfDiagnosticProgressionDto.EpreuveEvolution::evolution)
                .isEqualTo(NiveauEvolution.INCONNUE);
    }

    @Test
    @DisplayName("🛑 Non évaluée MAINTENANT ⇒ INCONNUE, jamais BAISSE")
    void nonEvalueeApres() {
        List<Section> avant = List.of(section(EpreuveType.TCF_EO, NiveauCecrl.B2));
        List<Section> apres = List.of(section(EpreuveType.TCF_EO, null));

        TcfDiagnosticProgressionDto p =
                resolver.comparer(UUID.randomUUID(), Instant.now(), avant, apres);

        assertThat(p.epreuves()).singleElement()
                .extracting(TcfDiagnosticProgressionDto.EpreuveEvolution::evolution)
                .isEqualTo(NiveauEvolution.INCONNUE);
    }

    @Test
    @DisplayName("Une baisse réelle se dit : la masquer rendrait la mesure invendable")
    void baisse() {
        List<Section> avant = List.of(section(EpreuveType.TCF_CE, NiveauCecrl.B2));
        List<Section> apres = List.of(section(EpreuveType.TCF_CE, NiveauCecrl.B1));

        TcfDiagnosticProgressionDto p =
                resolver.comparer(UUID.randomUUID(), Instant.now(), avant, apres);

        assertThat(p.epreuves()).singleElement()
                .extracting(TcfDiagnosticProgressionDto.EpreuveEvolution::evolution)
                .isEqualTo(NiveauEvolution.BAISSE);
        assertThat(p.niveauGlobal()).isEqualTo(NiveauEvolution.BAISSE);
    }

    @Test
    @DisplayName("Une épreuve absente du diagnostic précédent est INCONNUE, pas une nouveauté")
    void epreuveAbsenteAvant() {
        List<Section> avant = List.of(section(EpreuveType.TCF_CO, NiveauCecrl.B1));
        List<Section> apres = List.of(
                section(EpreuveType.TCF_CO, NiveauCecrl.B1),
                section(EpreuveType.TCF_CE, NiveauCecrl.B2));

        TcfDiagnosticProgressionDto p =
                resolver.comparer(UUID.randomUUID(), Instant.now(), avant, apres);

        assertThat(p.epreuves()).hasSize(2);
        assertThat(p.epreuves().get(1).evolution()).isEqualTo(NiveauEvolution.INCONNUE);
        assertThat(p.epreuves().get(1).avant()).isNull();
    }

    @Test
    @DisplayName("Aucune épreuve évaluée des deux côtés : global INCONNUE, aucun A1 inventé")
    void aucuneMesure() {
        List<Section> avant = List.of(section(EpreuveType.TCF_CO, null));
        List<Section> apres = List.of(section(EpreuveType.TCF_CO, null));

        TcfDiagnosticProgressionDto p =
                resolver.comparer(UUID.randomUUID(), Instant.now(), avant, apres);

        assertThat(p.previousNiveauGlobal()).isNull();
        assertThat(p.niveauGlobal()).isEqualTo(NiveauEvolution.INCONNUE);
    }
}
