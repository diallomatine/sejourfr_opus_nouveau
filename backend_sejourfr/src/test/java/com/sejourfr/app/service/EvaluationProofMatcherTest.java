package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class EvaluationProofMatcherTest {

    @Test
    void exact_normalise_unicode_ligatures_apostrophes_tirets_et_espaces() {
        String production = "« Mon cœur œuvre dans un curriculum vitæ — à l’école. »";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production,
            "mon coeur  oeuvre dans un curriculum vitae - a l'ecole",
            EpreuveType.TCF_EE))
            .contains("Mon cœur œuvre dans un curriculum vitæ — à l’école");
    }

    @Test
    void exact_applique_nfkc_avant_la_decomposition_des_accents() {
        String production = "Ａlice prépare un café dans son quartier.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "Alice prepare un cafe dans son quartier", EpreuveType.TCF_EE))
            .contains("Ａlice prépare un café dans son quartier");
    }

    @Test
    void exact_garde_un_mot_decompose_nfd_dans_un_seul_token() {
        String production = "Mon e\u0301cole accueille les enfants du quartier.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "mon école accueille les enfants du quartier", EpreuveType.TCF_EE))
            .contains("Mon e\u0301cole accueille les enfants du quartier");
    }

    @Test
    void fallback_accepte_la_flexion_telles_tels() {
        String production = "Les solutions proposées restent telles dans ce dossier.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "les solutions proposées restent tels dans ce dossier",
            EpreuveType.TCF_EE))
            .contains("Les solutions proposées restent telles dans ce dossier");
    }

    @Test
    void fallback_refuse_une_flexion_non_explicitement_autorisee() {
        String production = "Les mesures proposées restent utiles dans ce dossier.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "les mesures proposées restent utile dans ce dossier",
            EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_refuse_un_antonyme_ou_un_verbe_porteur_different() {
        String production = "Cette mesure protège durablement notre environnement local.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "cette mesure détruit durablement notre environnement local",
            EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "cette mesure améliore durablement notre environnement local",
            EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette personne parle souvent avec ses voisins locaux.",
            "cette personne parte souvent avec ses voisins locaux",
            EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_refuse_les_mots_distincts_meme_a_une_edition() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette ville accueille durablement les familles du quartier.",
            "cette villa accueille durablement les familles du quartier",
            EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette voie dessert facilement les habitants du quartier.",
            "cette voix dessert facilement les habitants du quartier",
            EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Notre cour accueille souvent les nouveaux élèves du quartier.",
            "notre cours accueille souvent les nouveaux élèves du quartier",
            EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_accepte_seulement_un_mot_outil_ajoute_ou_omis() {
        String avecArticle = "Cette solution protège la nature locale durablement.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            avecArticle, "cette solution protège nature locale durablement",
            EpreuveType.TCF_EE))
            .contains("Cette solution protège la nature locale durablement");
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette solution protège nature locale durablement.",
            "cette solution protège la nature locale durablement",
            EpreuveType.TCF_EE))
            .contains("Cette solution protège nature locale durablement");
    }

    @Test
    void fallback_refuse_omission_ou_ajout_de_verbe_ou_nom_porteur() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette solution protège notre environnement local.",
            "cette solution notre environnement local",
            EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette protège notre environnement local durablement.",
            "cette solution protège notre environnement local durablement",
            EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette solution protège vraiment notre environnement local.",
            "cette solution protège notre environnement local",
            EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_exige_au_moins_quatre_tokens_dans_la_citation() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Les solutions restent telles.", "solutions restent tels", EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_exige_trois_tokens_significatifs_identiques() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Ces choses sont telles ici.", "ces choses sont tels ici", EpreuveType.TCF_EE))
            .isEmpty();

        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Ces solutions restent telles ici.", "ces solutions restent tels ici",
            EpreuveType.TCF_EE))
            .contains("Ces solutions restent telles ici");
    }

    @Test
    void fallback_refuse_deux_editions_de_tokens() {
        String production = "Cette solution protège vraiment notre environnement local.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "cette méthode améliore vraiment notre environnement local",
            EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_ne_fait_ni_recherche_de_synonymes_ni_reordonnancement() {
        String production = "Le véhicule avance rapidement sur cette route locale.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "l'automobile roule vite sur cette route locale", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cette solution protège notre environnement local.",
            "cette solution notre environnement protège local", EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_refuse_tout_ecart_sur_un_nombre() {
        String production = "Le trajet coûte quinze euros pour trois personnes.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "le trajet coûte seize euros pour trois personnes", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "le trajet coûte 15 euros pour trois personnes", EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_refuse_tout_ecart_sur_un_token_alphanumerique_chiffre() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Le rendez-vous commence à 10h dans notre mairie locale.",
            "le rendez-vous commence à 11h dans notre mairie locale",
            EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Ce candidat prépare le niveau A2 avec son professeur.",
            "ce candidat prépare le niveau B2 avec son professeur",
            EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_refuse_tout_ecart_sur_la_negation() {
        String production = "Je ne veux pas quitter ce quartier calme.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je veux quitter ce quartier calme", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je veux encore habiter dans ce quartier calme.",
            "je ne veux encore habiter dans ce quartier calme", EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void exact_repete_accepte_la_meme_valeur_brute_mais_pas_deux_graphies_distinctes() {
        String exact = "Cette solution protège notre environnement local.";
        assertThat(EvaluationProofMatcher.canonicalPassage(
            exact + " Puis, " + exact,
            "cette solution protège notre environnement local", EpreuveType.TCF_EE))
            .contains("Cette solution protège notre environnement local");
        assertThat(EvaluationProofMatcher.canonicalPassage(
            exact + " Puis, cette solution protège notre environnement local.",
            "cette solution protège notre environnement local", EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void fallback_exige_un_match_unique() {
        String fuzzy = "Les solutions proposées restent telles dans ce dossier.";
        assertThat(EvaluationProofMatcher.canonicalPassage(
            fuzzy + " Puis, " + fuzzy,
            "les solutions proposées restent tels dans ce dossier", EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void eo_ne_cherche_que_dans_les_tours_du_candidat() {
        String dialogue = "Examinateur : Votre logement est près de la gare.\n"
            + "Candidat : Mon appartement se trouve près du grand parc.\n"
            + "Examinateur : Le grand parc est-il loin ?";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "votre logement est près de la gare", EpreuveType.TCF_EO))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "Candidat : mon appartement se trouve pres du grand parc",
            EpreuveType.TCF_EO))
            .contains("Mon appartement se trouve près du grand parc");
        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "Examinateur : le grand parc est-il loin", EpreuveType.TCF_EO))
            .isEmpty();
    }

    @Test
    void eo_monologue_sans_marqueur_est_entierement_attribue_au_candidat() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je présente mon travail et mon quartier préféré.",
            "je présente mon travail et mon quartier préféré", EpreuveType.TCF_EO))
            .contains("Je présente mon travail et mon quartier préféré");
    }
}
