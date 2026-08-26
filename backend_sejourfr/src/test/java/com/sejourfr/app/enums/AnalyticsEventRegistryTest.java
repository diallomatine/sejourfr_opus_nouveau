package com.sejourfr.app.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Verrouille le registre d'evenements : ce qu'il contient, ce qu'il ne doit
 * jamais contenir, et ce que chaque evenement a le droit de porter.
 */
class AnalyticsEventRegistryTest {

    /**
     * 🛑 Le test le plus important du fichier.
     *
     * <p>Chacun de ces faits a deja une source exacte en base
     * ({@code users.created_at}, {@code user_subscriptions},
     * {@code diagnostic_sessions.status}). En doubler un par un evenement
     * client creerait deux compteurs pour une meme chose — et c'est celui qu'on
     * regarde le moins qui finit par mentir. V036 l'a ecrit noir sur blanc ; ce
     * test le rend opposable.
     */
    @Test
    @DisplayName("Aucun fait déjà porté par une vraie table n'est un événement")
    void aucuneSecondeVerite() {
        List<String> interdits = List.of(
                "USER_REGISTERED", "LOGIN_SUCCEEDED",
                "PAYMENT_SUCCEEDED", "PAYMENT_FAILED",
                "SUBSCRIPTION_CREATED", "SUBSCRIPTION_CANCELLED",
                "DIAGNOSTIC_COMPLETED");
        List<String> presents = Arrays.stream(AnalyticsEvent.values()).map(Enum::name).toList();
        assertThat(presents).doesNotContainAnyElementsOf(interdits);
    }

    @Test
    @DisplayName("CHECKOUT_STARTED est le seul événement posé par le serveur")
    void seulCheckoutEstServeur() {
        List<AnalyticsEvent> serveur = Arrays.stream(AnalyticsEvent.values())
                .filter(e -> !e.isEmisParLeClient())
                .toList();
        assertThat(serveur).containsExactly(AnalyticsEvent.CHECKOUT_STARTED);
    }

    @Test
    @DisplayName("Chaque événement borne ses propriétés, et rien d'autre n'y entre")
    void proprietesBornees() {
        assertThat(AnalyticsEvent.LANDING_VIEWED.getAllowedProperties())
                .containsExactlyInAnyOrder(
                        AnalyticsProperty.LANDING_PATH, AnalyticsProperty.LANDING_VARIANT);
        assertThat(AnalyticsEvent.PREMIUM_CTA_CLICKED.getAllowedProperties())
                .containsExactlyInAnyOrder(AnalyticsProperty.CTA_LOCATION,
                        AnalyticsProperty.PLAN_CODE, AnalyticsProperty.SCREEN);
        // Un événement sans propriété n'en accepte AUCUNE : c'est ce qui empêche
        // un front d'y déposer du contenu « au cas où ».
        assertThat(AnalyticsEvent.PRICING_VIEWED.getAllowedProperties()).isEmpty();
        assertThat(AnalyticsEvent.PRICING_VIEWED.allows(AnalyticsProperty.PLAN_CODE)).isFalse();
        assertThat(AnalyticsEvent.LANDING_VIEWED.allows(AnalyticsProperty.CTA_LOCATION)).isFalse();
    }

    /**
     * 🛑 <b>Le rideau se mesure en TROIS gestes distincts</b>, et les fondre
     * effacerait exactement ce qu'on veut savoir : combien de fois il s'affiche,
     * combien de fois le candidat le déplie, et combien de fois l'offre est
     * <b>vue</b> — pas cliquée. {@code PREMIUM_CTA_CLICKED}, lui, reste une
     * intention.
     */
    @Test
    @DisplayName("Le rideau freemium porte ses trois gestes, et un compteur borné")
    void leRideauPorteSesTroisGestes() {
        assertThat(AnalyticsEvent.PLAN_CURTAIN_SHOWN.getAllowedProperties())
                .containsExactlyInAnyOrder(AnalyticsProperty.CTA_LOCATION,
                        AnalyticsProperty.EPREUVE, AnalyticsProperty.VISIBLE_COUNT,
                        AnalyticsProperty.TOTAL_COUNT);
        assertThat(AnalyticsEvent.PLAN_CURTAIN_EXPANDED.getAllowedProperties())
                .as("la dimension commune est ce qui rend un taux de dépliage lisible")
                .contains(AnalyticsProperty.EPREUVE);
        assertThat(AnalyticsEvent.PLAN_PAYWALL_VIEWED.getAllowedProperties())
                .containsExactly(AnalyticsProperty.CTA_LOCATION);
        // Une vue n'est pas un clic : les deux ne portent pas les mêmes clés et
        // ne peuvent pas se confondre dans une requête.
        assertThat(AnalyticsEvent.PLAN_PAYWALL_VIEWED.allows(AnalyticsProperty.PLAN_CODE))
                .isFalse();
    }

    /**
     * Un compteur d'écran est une <b>taille d'affichage</b>, jamais une donnée du
     * candidat — et la borne est ce qui empêche cette clé de devenir un champ
     * libre numérique.
     */
    @Test
    @DisplayName("Un compteur d'affichage est borné à quatre chiffres")
    void unCompteurEstBorne() {
        assertThat(AnalyticsProperty.VISIBLE_COUNT.normalizeOrThrow(" 12 ")).isEqualTo("12");
        assertThat(AnalyticsProperty.TOTAL_COUNT.normalizeOrThrow("0")).isEqualTo("0");
        assertThatThrownBy(() -> AnalyticsProperty.VISIBLE_COUNT.normalizeOrThrow("-1"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("visibleCount");
        assertThatThrownBy(() -> AnalyticsProperty.TOTAL_COUNT.normalizeOrThrow("12345"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> AnalyticsProperty.TOTAL_COUNT.normalizeOrThrow("douze"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    /**
     * 🛑 Les deux portes d'entrée de {@code /reussir} ne se confondent pas.
     * « Passer l'examen découverte » ne mène ni à une production, ni à un niveau
     * CECRL, ni à un diagnostic : les fondre gonflerait la mesure du diagnostic
     * de clics qui n'y mènent pas.
     */
    @Test
    @DisplayName("Le clic civique est un événement à part entière, distinct du diagnostic")
    void civiqueEstDistinctDuDiagnostic() {
        assertThat(AnalyticsEvent.CIVIQUE_CTA_CLICKED)
                .isNotEqualTo(AnalyticsEvent.DIAGNOSTIC_CTA_CLICKED);
        assertThat(AnalyticsEvent.CIVIQUE_CTA_CLICKED.isEmisParLeClient()).isTrue();
        assertThat(AnalyticsEvent.CIVIQUE_CTA_CLICKED.getAllowedProperties())
                .containsExactly(AnalyticsProperty.CTA_LOCATION);
        // Le civique n'a pas de variante de diagnostic : lui en donner une
        // ouvrirait la porte a le compter comme un diagnostic.
        assertThat(AnalyticsEvent.CIVIQUE_CTA_CLICKED.allows(AnalyticsProperty.DIAGNOSTIC_TYPE))
                .isFalse();
    }

    /**
     * « Le compte est demandé » n'est pas « l'oral est terminé » : entre les
     * deux se joue toute la décision de créer un compte, et c'est la seule
     * marche du parcours invité qui ne laisse aucune trace en base.
     */
    @Test
    @DisplayName("La demande de compte du diagnostic est mesurée, et n'est pas la fin de l'oral")
    void demandeDeCompteEstMesuree() {
        assertThat(AnalyticsEvent.DIAGNOSTIC_ACCOUNT_REQUIRED.isEmisParLeClient()).isTrue();
        assertThat(AnalyticsEvent.DIAGNOSTIC_ACCOUNT_REQUIRED.getAllowedProperties())
                .containsExactly(AnalyticsProperty.DIAGNOSTIC_TYPE);
        assertThat(AnalyticsEvent.DIAGNOSTIC_ACCOUNT_REQUIRED)
                .isNotEqualTo(AnalyticsEvent.DIAGNOSTIC_EO_COMPLETED);
    }

    /**
     * Ces deux-la ne servent aucun bloc de la maquette : ils existent pour ne
     * pas perdre, en changeant d'outil, une mesure que {@code page_views}
     * portait deja.
     */
    @Test
    @DisplayName("Les deux mesures du Plan survivent à la migration depuis page_views")
    void lesMesuresDuPlanSurvivent() {
        assertThat(AnalyticsEvent.PLAN_OPENED.getAllowedProperties()).isEmpty();
        assertThat(AnalyticsEvent.PLAN_EXERCISE_STARTED.getAllowedProperties())
                .containsExactly(AnalyticsProperty.EXERCISE_KIND);
        assertThat(AnalyticsProperty.EXERCISE_KIND.normalizeOrThrow("micro_training"))
                .isEqualTo(PlanExerciseKind.MICRO_TRAINING.name());
        // La nature d'exercice reprend l'enum du Plan : une seconde liste
        // aurait fini par nommer differemment le meme exercice.
        assertThatThrownBy(() -> AnalyticsProperty.EXERCISE_KIND.normalizeOrThrow("autre_chose"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("exerciseKind")
                .hasMessageContaining(PlanExerciseKind.REASSESSMENT.name());
    }

    @Test
    @DisplayName("Une valeur d'énumération inconnue est refusée en nommant ce qui était attendu")
    void valeurEnumInconnueEstNommee() {
        assertThatThrownBy(() -> AnalyticsProperty.CTA_LOCATION.normalizeOrThrow("footer_bis"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ctaLocation")
                .hasMessageContaining("footer_bis")
                .hasMessageContaining("DIAGNOSTIC_REPORT");
    }

    @Test
    @DisplayName("Les valeurs d'énumération sont normalisées en majuscules, jamais devinées")
    void valeursNormalisees() {
        assertThat(AnalyticsProperty.CTA_LOCATION.normalizeOrThrow("hero")).isEqualTo("HERO");
        assertThat(AnalyticsProperty.DIAGNOSTIC_TYPE.normalizeOrThrow(" Rapid "))
                .isEqualTo("RAPID");
        assertThat(AnalyticsProperty.REGISTRATION_CONTEXT.normalizeOrThrow("mobile_app"))
                .isEqualTo("MOBILE_APP");
    }

    @Test
    @DisplayName("Un code de plan est un code, jamais une phrase où loger n'importe quoi")
    void codePlanBorne() {
        assertThat(AnalyticsProperty.PLAN_CODE.normalizeOrThrow("integral_pass_2m"))
                .isEqualTo("INTEGRAL_PASS_2M");
        assertThatThrownBy(() -> AnalyticsProperty.PLAN_CODE
                .normalizeOrThrow("contact@exemple.fr"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("planCode");
    }

    @Test
    @DisplayName("Un slug ne peut pas transporter une adresse, un espace ni une phrase")
    void slugBorne() {
        assertThat(AnalyticsProperty.SCREEN.normalizeOrThrow("Diagnostic_Result"))
                .isEqualTo("diagnostic_result");
        assertThatThrownBy(() -> AnalyticsProperty.SCREEN
                .normalizeOrThrow("j'ai écrit toute ma production ici"))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> AnalyticsProperty.LANDING_VARIANT.normalizeOrThrow("a".repeat(41)))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("Une clé inconnue ne correspond à aucune propriété")
    void cleInconnue() {
        assertThat(AnalyticsProperty.byKey("password")).isNull();
        assertThat(AnalyticsProperty.byKey(null)).isNull();
        assertThat(AnalyticsProperty.byKey("ctaLocation")).isEqualTo(AnalyticsProperty.CTA_LOCATION);
    }
}
