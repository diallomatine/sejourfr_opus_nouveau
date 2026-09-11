package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.enums.CivicThemeState;
import com.sejourfr.app.enums.PlanRecentChangesWindow;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * « PROGRESSION DETECTEE » — ce qui a bouge depuis peu dans le plan civique.
 *
 * <p>Ce que ce test verrouille, et pourquoi chacun compte :
 * <ul>
 *   <li>🛑 <b>rien ne s'affiche quand rien n'a bouge</b>. C'est le cas NORMAL,
 *       et de loin le plus frequent : un bloc qui s'afficherait vide ne dirait
 *       rien et userait la seule surface ou le candidat voit son plan bouger ;</li>
 *   <li>🛑 <b>le temps seul n'est pas un changement</b>. Sans reponse nouvelle,
 *       une cible est ignoree — sinon une echeance Leitner qui se franchit toute
 *       seule s'annoncerait comme une progression ;</li>
 *   <li>🛑 <b>le rabat au grain THEME s'applique aux DEUX bouts</b>. Sans lui on
 *       annoncerait « passe a Maitrisee » sur un theme, palier que le plan
 *       lui-meme refuse ;</li>
 *   <li>🛑 <b>une baisse est servie comme une transition</b>, avec
 *       {@code progres = false} : le plan dit ce qui s'est passe, il ne raconte
 *       pas que des bonnes nouvelles ;</li>
 *   <li>la fenetre retenue est la <b>plus courte</b> qui contienne quelque chose.</li>
 * </ul>
 */
class CivicChangementsResolverTest {

    private static final Instant MAINTENANT = Instant.parse("2026-09-20T10:00:00Z");
    private static final Duration FENETRE_ERREURS = Duration.ofDays(30);

    private static final UUID NOTION = UUID.randomUUID();
    private static final UUID THEME = UUID.randomUUID();

    private final CivicChangementsResolver resolver =
            new CivicChangementsResolver(new CivicLeitnerResolver());

    // ------------------------------------------------------------------ rien

    @Test
    @DisplayName("🛑 aucune cible ⇒ rien, jamais un bloc vide")
    void sansCible() {
        assertThat(resolver.resoudre(
                List.of(), Map.of(), null, FENETRE_ERREURS, MAINTENANT))
                .isEmpty();
    }

    @Test
    @DisplayName("🛑 le TEMPS SEUL n'est pas un changement : rien de neuf ⇒ rien")
    void sansReponseNouvelle() {
        // Deux reponses justes, mais il y a deux mois : l'etat n'a pas bouge
        // depuis, meme si une echeance Leitner s'est franchie entre-temps.
        List<CivicReponse> vieilles = List.of(
                reponse(true, MAINTENANT.minus(Duration.ofDays(60))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(59))));

        Optional<CivicPlanDto.Changements> out = resolver.resoudre(
                List.of(cible(CivicMaitrise.EN_PROGRESSION, CivicPlanGrain.NOTION)),
                Map.of(NOTION, vieilles),
                null, FENETRE_ERREURS, MAINTENANT);

        assertThat(out).isEmpty();
    }

    @Test
    @DisplayName("une reponse recente qui ne change pas l'etat ne fait pas une transition")
    void reponseRecenteSansTransition() {
        // Trois justes anciennes (etat deja haut), une juste recente : l'etat
        // courant est le meme qu'au debut de la fenetre.
        List<CivicReponse> reponses = List.of(
                reponse(true, MAINTENANT.minus(Duration.ofDays(40))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(39))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(38))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(1))));

        Optional<CivicPlanDto.Changements> out = resolver.resoudre(
                List.of(cible(CivicMaitrise.MAITRISEE, CivicPlanGrain.NOTION)),
                Map.of(NOTION, reponses),
                null, FENETRE_ERREURS, MAINTENANT);

        assertThat(out).isEmpty();
    }

    // ------------------------------------------------------- une transition

    @Test
    @DisplayName("A_TRAVAILLER → EN_PROGRESSION est servie, et comptee comme un progres")
    void progression() {
        // Avant la fenetre : une juste (boite 2 ⇒ A_TRAVAILLER).
        // Dans la fenetre : deux justes de plus (boite 4 + derniere juste).
        List<CivicReponse> reponses = List.of(
                reponse(true, MAINTENANT.minus(Duration.ofDays(20))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(19))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(2))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(1))));

        Optional<CivicPlanDto.Changements> out = resolver.resoudre(
                List.of(cible(CivicMaitrise.MAITRISEE, CivicPlanGrain.NOTION)),
                Map.of(NOTION, reponses),
                null, FENETRE_ERREURS, MAINTENANT);

        assertThat(out).isPresent();
        List<CivicPlanDto.Transition> transitions = out.orElseThrow().transitions();
        assertThat(transitions).hasSize(1);
        assertThat(transitions.getFirst().apres()).isEqualTo(CivicMaitrise.MAITRISEE);
        assertThat(transitions.getFirst().avant()).isNotEqualTo(CivicMaitrise.MAITRISEE);
        assertThat(transitions.getFirst().progres()).isTrue();
        assertThat(transitions.getFirst().label()).isEqualTo("Le Parlement");
    }

    @Test
    @DisplayName("🛑 une BAISSE est servie aussi, avec progres = false")
    void baisse() {
        // Avant la fenetre : trois justes (etat haut). Dans la fenetre : une
        // erreur, qui renvoie en boite 1.
        List<CivicReponse> reponses = List.of(
                reponse(true, MAINTENANT.minus(Duration.ofDays(20))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(19))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(18))),
                reponse(false, MAINTENANT.minus(Duration.ofDays(1))));

        Optional<CivicPlanDto.Changements> out = resolver.resoudre(
                List.of(cible(CivicMaitrise.A_TRAVAILLER, CivicPlanGrain.NOTION)),
                Map.of(NOTION, reponses),
                null, FENETRE_ERREURS, MAINTENANT);

        assertThat(out).isPresent();
        CivicPlanDto.Transition t = out.orElseThrow().transitions().getFirst();
        assertThat(t.apres()).isEqualTo(CivicMaitrise.A_TRAVAILLER);
        assertThat(t.progres()).isFalse();
    }

    @Test
    @DisplayName("🛑 au grain THEME, aucune transition ne mene a MAITRISEE")
    void themeJamaisMaitrise() {
        List<CivicReponse> reponses = List.of(
                reponse(true, MAINTENANT.minus(Duration.ofDays(20))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(2))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(1))),
                reponse(true, MAINTENANT.minus(Duration.ofHours(2))));

        Optional<CivicPlanDto.Changements> out = resolver.resoudre(
                // La cible est deja rabattue par le service : au grain theme,
                // l'etat courant ne peut pas etre MAITRISEE.
                List.of(cibleTheme(CivicMaitrise.EN_PROGRESSION)),
                Map.of(THEME, reponses),
                null, FENETRE_ERREURS, MAINTENANT);

        assertThat(out).isPresent();
        assertThat(out.orElseThrow().transitions())
                .extracting(CivicPlanDto.Transition::avant, CivicPlanDto.Transition::apres)
                .doesNotContain(org.assertj.core.groups.Tuple.tuple(
                        CivicMaitrise.MAITRISEE, CivicMaitrise.MAITRISEE));
        assertThat(out.orElseThrow().transitions())
                .noneMatch(t -> t.avant() == CivicMaitrise.MAITRISEE
                        || t.apres() == CivicMaitrise.MAITRISEE);
    }

    // ------------------------------------------------------------- fenetres

    @Test
    @DisplayName("la fenetre retenue est la plus COURTE qui contienne quelque chose")
    void plusCourteFenetre() {
        List<CivicReponse> reponses = List.of(
                reponse(true, MAINTENANT.minus(Duration.ofDays(20))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(2))),
                reponse(true, MAINTENANT.minus(Duration.ofDays(1))));

        Optional<CivicPlanDto.Changements> out = resolver.resoudre(
                List.of(cible(CivicMaitrise.MAITRISEE, CivicPlanGrain.NOTION)),
                Map.of(NOTION, reponses),
                null, FENETRE_ERREURS, MAINTENANT);

        assertThat(out).isPresent();
        assertThat(out.orElseThrow().fenetre())
                .isEqualTo(PlanRecentChangesWindow.CETTE_SEMAINE);
        assertThat(out.orElseThrow().depuis())
                .isEqualTo(MAINTENANT.minus(Duration.ofDays(7)));
    }

    // --------------------------------------------------- nouvelle priorite

    @Test
    @DisplayName("la priorite n°1 n'est « nouvelle » que si elle vient d'etre travaillee")
    void nouvellePrioriteSeulementSiRecente() {
        CivicPlanDto.Cible prochaine = cible(CivicMaitrise.A_TRAVAILLER, CivicPlanGrain.NOTION);

        // Travaillee il y a deux mois : en tete, mais pas une nouvelle.
        Optional<CivicPlanDto.Changements> ancienne = resolver.resoudre(
                List.of(prochaine),
                Map.of(NOTION, List.of(reponse(false, MAINTENANT.minus(Duration.ofDays(60))))),
                prochaine, FENETRE_ERREURS, MAINTENANT);
        assertThat(ancienne).isEmpty();

        // Travaillee hier : le plan vient de la designer.
        Optional<CivicPlanDto.Changements> fraiche = resolver.resoudre(
                List.of(prochaine),
                Map.of(NOTION, List.of(reponse(false, MAINTENANT.minus(Duration.ofDays(1))))),
                prochaine, FENETRE_ERREURS, MAINTENANT);
        assertThat(fraiche).isPresent();
        assertThat(fraiche.orElseThrow().nouvellePriorite()).isNotNull();
        assertThat(fraiche.orElseThrow().nouvellePriorite().label()).isEqualTo("Le Parlement");
    }

    // ---------------------------------------------------------------- outils

    private static CivicReponse reponse(boolean correcte, Instant quand) {
        return new CivicReponse(NOTION, THEME, correcte, quand);
    }

    private static CivicPlanDto.Cible cible(CivicMaitrise maitrise, CivicPlanGrain grain) {
        return cible(NOTION, maitrise, grain);
    }

    private static CivicPlanDto.Cible cibleTheme(CivicMaitrise maitrise) {
        return cible(THEME, maitrise, CivicPlanGrain.THEME);
    }

    private static CivicPlanDto.Cible cible(
            UUID id, CivicMaitrise maitrise, CivicPlanGrain grain) {
        return new CivicPlanDto.Cible(
                id, "CIV_PARLEMENT", "Le Parlement", grain,
                THEME, "CIV_INSTITUTIONS", "Système institutionnel et politique",
                CivicThemeState.A_RENFORCER,
                maitrise, 3, List.of(), 0, 0, 0,
                null, null, false, 0, false, 10, 240, false);
    }
}
