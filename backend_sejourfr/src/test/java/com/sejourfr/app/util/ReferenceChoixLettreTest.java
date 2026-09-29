package com.sejourfr.app.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Remappage des lettres A-D citées par l'explication d'une question QCM quand
 * les propositions sont mélangées à l'affichage.
 *
 * <p>Les cas « à ne pas transformer » ne sont pas théoriques : ils ont tous été
 * relevés dans les 2 339 explications de questions mélangées de la base.
 */
class ReferenceChoixLettreTest {

    /** A→C, B→A, C→D, D→B. */
    private static final int[] PERMUTATION = {2, 0, 3, 1};
    private static final int[] IDENTITE = {0, 1, 2, 3};

    @Nested
    @DisplayName("ce qui NE doit PAS être transformé")
    class NonTransforme {

        @Test
        void paliersCecrl() {
            // Le cas qui a motivé la règle : « Piège B1 » vit dans les explications CO.
            String texte = "Seule B « en suivant la notice » y répond. Piège B1 : les quatre "
                    + "réponses parlent du montage. Niveau A2 attendu, B2 hors de portée.";

            String remappe = ReferenceChoixLettre.remappe(texte, PERMUTATION);

            assertThat(remappe).contains("Piège B1 :").contains("Niveau A2").contains("B2 hors de portée");
            assertThat(remappe).startsWith("Seule A "); // seule la référence bouge
        }

        @Test
        void siglesEtMotsAvecTiretOuApostrophe() {
            String texte = "C'est la CMU-C, devenue Complémentaire santé solidaire. "
                    + "Le débarquement (D-Day) date de 1944, l'amphithéâtre du Ier siècle après J.-C.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION)).isEqualTo(texte);
        }

        @Test
        void verbeAvoirCapitaliseDansUneFormeCitee() {
            // 33 occurrences en STRUCTURE : « A allé » est le verbe « a », pas la proposition A.
            String texte = "La réponse C est correcte. « A allé » est incorrect car « aller » "
                    + "se conjugue avec « être ».";

            String remappe = ReferenceChoixLettre.remappe(texte, PERMUTATION);

            assertThat(remappe).contains("« A allé »");
            assertThat(remappe).startsWith("La réponse D est correcte.");
        }

        @Test
        void nomsDeLieuSuivisDUneLettre() {
            // 24 occurrences en CE : bâtiment / salle / allée / escalier / permis.
            String texte = "Le plan indique « Consultations : bâtiment B, 1er étage ». "
                    + "Le bâtiment A abrite les urgences et l'escalier B mène au sous-sol. "
                    + "La réponse D inverse le lieu : la salle A n'est plus utilisée.";

            String remappe = ReferenceChoixLettre.remappe(texte, PERMUTATION);

            assertThat(remappe).contains("bâtiment B, 1er étage")
                    .contains("Le bâtiment A abrite")
                    .contains("l'escalier B mène")
                    .contains("la salle A n'est plus");
            assertThat(remappe).contains("La réponse B inverse le lieu"); // D→B
        }

        @Test
        void prepositionAEcriteSansAccent() {
            String texte = "Le collège dure 4 ans : 6e, 5e, 4e, 3e. A la fin de la 3e, "
                    + "les élèves passent le brevet.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION)).isEqualTo(texte);
        }

        @Test
        void texteSansAucuneLettre() {
            String texte = "Liberté, Égalité, Fraternité est la devise de la République française.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION)).isEqualTo(texte);
        }

        @Test
        void permutationIdentiteOuAbsente() {
            String texte = "La réponse A contredit le texte.";

            assertThat(ReferenceChoixLettre.remappe(texte, IDENTITE)).isEqualTo(texte);
            assertThat(ReferenceChoixLettre.remappe(texte, null)).isEqualTo(texte);
            assertThat(ReferenceChoixLettre.remappe(texte, new int[0])).isEqualTo(texte);
            assertThat(ReferenceChoixLettre.remappe(null, PERMUTATION)).isNull();
        }
    }

    @Nested
    @DisplayName("ce qui DOIT être transformé")
    class Transforme {

        @Test
        void designationExpliciteDUneProposition() {
            String texte = "La réponse A inverse la cause et l'effet. Le choix D reprend le texte. "
                    + "Seule C est correcte.";

            String remappe = ReferenceChoixLettre.remappe(texte, PERMUTATION);

            assertThat(remappe).isEqualTo(
                    "La réponse C inverse la cause et l'effet. Le choix B reprend le texte. "
                            + "Seule D est correcte.");
        }

        @Test
        void lettreEnTeteDePhraseSuivieDUnVerbe() {
            String texte = "Seule B « en suivant la notice étape par étape » y répond. "
                    + "A indique une durée. C indique une cause. D indique un lieu.";

            String remappe = ReferenceChoixLettre.remappe(texte, PERMUTATION);

            assertThat(remappe).isEqualTo(
                    "Seule A « en suivant la notice étape par étape » y répond. "
                            + "C indique une durée. D indique une cause. B indique un lieu.");
        }

        @Test
        void enumerationReliee() {
            String texte = "Les réponses A et B contredisent la restriction.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION))
                    .isEqualTo("Les réponses C et A contredisent la restriction.");
        }

        @Test
        void enumerationEnTeteAncreeParSonVerbe() {
            String texte = "Piège B1 : B, C, D restent crédibles dans une conversation.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION))
                    .isEqualTo("Piège B1 : A, D, B restent crédibles dans une conversation.");
        }

        @Test
        void repriseApresUnMotOutil() {
            String texte = "La préposition « à » se retrouve aussi dans D, ce qui peut tromper, "
                    + "mais D ne décrit pas un état mental.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION))
                    .isEqualTo("La préposition « à » se retrouve aussi dans B, ce qui peut tromper, "
                            + "mais B ne décrit pas un état mental.");
        }
    }

    @Nested
    @DisplayName("tout ou rien : une occurrence indécidable laisse le texte intact")
    class ToutOuRien {

        @Test
        void uneOccurrenceIndecidableAnnuleLeRemappageDeTouteLExplication() {
            // « le hangar C » : nom commun hors liste → indécidable. Un remappage partiel
            // ferait dire deux choses différentes à la même lettre dans le même texte.
            String texte = "La réponse A contredit le texte. Le hangar C n'est pas concerné.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION)).isEqualTo(texte);
            assertThat(ReferenceChoixLettre.abstention(texte)).isTrue();
        }

        @Test
        void lettreHorsDuNombreDePropositions() {
            // 3 propositions servies, mais l'explication cite « D » : on ne sait pas ce
            // qu'elle désigne, on ne touche à rien.
            String texte = "La réponse D contredit le texte.";

            assertThat(ReferenceChoixLettre.remappe(texte, new int[] {2, 0, 1})).isEqualTo(texte);
        }

        @Test
        void aucuneReferenceDetecteeLaisseLeTexteIntact() {
            String texte = "Le bâtiment A abrite les urgences.";

            assertThat(ReferenceChoixLettre.remappe(texte, PERMUTATION)).isEqualTo(texte);
            assertThat(ReferenceChoixLettre.referencesDetectees(texte)).isEmpty();
            assertThat(ReferenceChoixLettre.abstention(texte)).isFalse();
        }
    }

    @Test
    void leRemappageEstSimultane_pasUneSuiteDeRemplacements() {
        // A→B et B→A : un remplacement séquentiel rendrait « A » partout.
        String texte = "La réponse A est correcte, la réponse B est fausse.";

        assertThat(ReferenceChoixLettre.remappe(texte, new int[] {1, 0, 2, 3}))
                .isEqualTo("La réponse B est correcte, la réponse A est fausse.");
    }
}
