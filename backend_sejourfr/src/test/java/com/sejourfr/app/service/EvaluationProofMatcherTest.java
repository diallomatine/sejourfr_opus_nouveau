package com.sejourfr.app.service;

import com.sejourfr.app.config.ProductionEvaluationProperties;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.util.TranscriptTurnStitcher;
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
    void hesitations_de_la_production_elidees_meme_en_nombre() {
        // Citation parfaitement fidele au propos du candidat : sans elision, trois
        // « euh » suffisaient a la faire echouer, alors que le prompt interdit par
        // ailleurs de fonder quoi que ce soit sur les hesitations.
        String production = "Je euh travaille euh dans une euh entreprise de transport.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je travaille dans une entreprise de transport", EpreuveType.TCF_EO))
            .contains("Je euh travaille euh dans une euh entreprise de transport");
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Heu je hum pense heu que c'est utile.", "je pense que c'est utile",
            EpreuveType.TCF_EO))
            .contains("je hum pense heu que c'est utile");
    }

    @Test
    void une_citation_qui_conserve_les_hesitations_reste_acceptee() {
        String production = "Je euh travaille dans une entreprise de transport.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je euh travaille dans une entreprise", EpreuveType.TCF_EO))
            .contains("Je euh travaille dans une entreprise");
    }

    @Test
    void l_elision_ne_vaut_que_de_la_production_vers_la_citation() {
        // Une hesitation ABSENTE de la production ne peut pas etre ajoutee par la
        // citation : l'elision est a sens unique.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je travaille dans une entreprise de transport.",
            "je euh travaille dans une entreprise", EpreuveType.TCF_EO))
            .isEmpty();
    }

    @Test
    void l_elision_n_autorise_aucun_mot_absent_de_la_production() {
        String production = "Je euh travaille euh dans une entreprise.";

        // Mot porteur invente.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je travaille dans une grande entreprise", EpreuveType.TCF_EO))
            .isEmpty();
        // Mot porteur substitue.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je travaille dans une usine", EpreuveType.TCF_EO))
            .isEmpty();
        // Ordre recompose.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "dans une entreprise je travaille", EpreuveType.TCF_EO))
            .isEmpty();
    }

    @Test
    void une_preuve_qui_enjambe_deux_tours_candidat_reste_refusee_malgre_les_hesitations() {
        String dialogue = "Candidat : Je euh travaille dans une entreprise.\n"
            + "Examinateur : Depuis combien de temps ?\n"
            + "Candidat : Depuis euh trois ans maintenant.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "Candidat : je travaille dans une entreprise depuis trois ans maintenant",
            EpreuveType.TCF_EO))
            .isEmpty();
        // Chaque tour reste citable separement.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "Candidat : je travaille dans une entreprise", EpreuveType.TCF_EO))
            .contains("Je euh travaille dans une entreprise");
        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "Candidat : depuis trois ans maintenant", EpreuveType.TCF_EO))
            .contains("Depuis euh trois ans maintenant");
    }

    @Test
    void une_hesitation_n_ouvre_ni_ne_ferme_jamais_un_passage_restitue() {
        String production = "Euh je travaille ici euh depuis euh trois ans euh.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je travaille ici depuis trois ans", EpreuveType.TCF_EO))
            .contains("je travaille ici euh depuis euh trois ans");
    }

    @Test
    void la_liste_des_hesitations_est_fermee() {
        // « bon », « alors », « voila » sont des mots ordinaires : les elider
        // laisserait une citation sauter un mot du candidat.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je bon travaille dans une entreprise de transport.",
            "je travaille dans une entreprise de transport", EpreuveType.TCF_EO))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je alors travaille dans une entreprise de transport.",
            "je travaille dans une entreprise de transport", EpreuveType.TCF_EO))
            .isEmpty();
    }

    @Test
    void l_elision_laisse_la_tolerance_d_une_edition_intacte_sans_l_elargir() {
        String production = "Les solutions euh proposées restent telles dans ce dossier.";

        // Une hesitation + la flexion explicitement admise : accepte.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "les solutions proposées restent tels dans ce dossier",
            EpreuveType.TCF_EE))
            .contains("Les solutions euh proposées restent telles dans ce dossier");
        // Une hesitation + DEUX editions : toujours refuse.
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "les mesures proposées restent tels dans ce dossier",
            EpreuveType.TCF_EE))
            .isEmpty();
    }

    @Test
    void eo_monologue_sans_marqueur_est_entierement_attribue_au_candidat() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je présente mon travail et mon quartier préféré.",
            "je présente mon travail et mon quartier préféré", EpreuveType.TCF_EO))
            .contains("Je présente mon travail et mon quartier préféré");
    }

    /**
     * Transcript temps reel FRAGMENTE : le meme enonce du candidat est scinde en
     * deux tours consecutifs a une frontiere arbitraire. Tant que la frontiere
     * est la, {@code searchableSegments} construit deux segments et la citation
     * n'est retrouvable dans AUCUN des deux — alors que le candidat a bien
     * prononce la phrase. Recollee, elle l'est.
     */
    @Test
    void une_preuve_a_cheval_sur_deux_tours_est_trouvee_apres_recollage() {
        String fragmente = """
            Examinateur : Bonjour, je vous écoute.
            Candidat : Bonjour, j'aimerais louer une voiture
            Candidat : si vous en avez s'il vous plaît.""";
        String citation = "j'aimerais louer une voiture si vous en avez s'il vous plaît";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            fragmente, citation, EpreuveType.TCF_EO))
            .isEmpty();

        ProductionEvaluationProperties props = new ProductionEvaluationProperties();
        String recolle = new TranscriptTurnStitcher(props).stitch(fragmente);

        assertThat(EvaluationProofMatcher.canonicalPassage(
            recolle, citation, EpreuveType.TCF_EO))
            .contains("j'aimerais louer une voiture si vous en avez s'il vous plaît");
    }

    /**
     * Le recollage ne fusionne jamais a travers un tour de l'examinateur : une
     * citation qui enjambe une relance reste refusee, sinon on validerait une
     * phrase que personne n'a dite d'un trait.
     */
    // ------------------------------------------- mots coupes par la transcription

    /**
     * Cas REEL du corpus {@code EO_T2_B1_01} (piege {@code TRANSCRIPTION_BRUITEE}) :
     * la transcription temps reel coupe les mots au mauvais endroit. Le correcteur
     * cite la forme recomposee — la seule qu'il puisse ecrire — et le matcher la
     * refusait. Comme presque tous les tours candidat de ce cas portent des mots
     * coupes, la consigne « cite un passage propre » y etait impossible a
     * satisfaire.
     */
    @Test
    void recolle_un_mot_coupe_par_la_transcription_reelle() {
        String production = "Examinateur : Bonjour, je peux vous aider ?\n"
            + "Candidat : oui bon jour j'ai ach eté cette ves te chez vous il y a dix jours "
            + "et une cou ture s'est défai te dès le pre mier jour";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "j'ai acheté cette veste chez vous il y a dix jours", EpreuveType.TCF_EO))
            .contains("j'ai ach eté cette ves te chez vous il y a dix jours");
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "une couture s'est défaite dès le premier jour", EpreuveType.TCF_EO))
            .contains("une cou ture s'est défai te dès le pre mier jour");
    }

    /** Second cas reel du corpus ({@code EO_T2_A2_01}), avec hesitations melees. */
    @Test
    void recolle_un_mot_coupe_meme_entoure_d_hesitations() {
        String production = "Candidat : bonjour euh je voudrais réser ver une cham bre pour "
            + "deu personne s'il vous plaît";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je voudrais réserver une chambre", EpreuveType.TCF_EO))
            .contains("je voudrais réser ver une cham bre");
    }

    /**
     * SENS UNIQUE, comme l'elision des hesitations : la PRODUCTION peut etre
     * coupee, la citation jamais. Une citation qui coupe un mot que la production
     * ecrit d'un trait reste refusee.
     */
    @Test
    void le_recollage_ne_vaut_que_de_la_production_vers_la_citation() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "J'ai acheté cette veste chez vous il y a dix jours.",
            "j'ai ach eté cette ves te chez vous il y a dix jours", EpreuveType.TCF_EE))
            .isEmpty();
    }

    /**
     * RISQUE DE FUSION ABUSIVE, dans les deux sens. On ne DECOUPE jamais un token
     * de la production : « les » ne peut pas absorber une partie de « lest », et
     * « lest » ne peut pas se rassembler a partir de « les tuteurs » (la
     * concatenation deborderait la cible).
     */
    @Test
    void la_fusion_abusive_les_tuteurs_lest_uteurs_reste_impossible() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Le bateau prend du lest uteurs pour la traversée.",
            "le bateau prend du les tuteurs pour la traversée", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Le bateau prend du les tuteurs pour la traversée.",
            "le bateau prend du lest uteurs pour la traversée", EpreuveType.TCF_EE))
            .isEmpty();
    }

    /**
     * LIMITE ASSUMEE ET DOCUMENTEE : rien ne distingue « une couture coupee en
     * deux » de « deux mots colles par la citation ». Une citation qui soude deux
     * mots voisins passe donc — et c'est sans consequence : le passage restitue,
     * persiste et affiche reste la sous-chaine ORIGINALE, avec ses deux mots
     * separes. Aucun mot n'est invente, aucun n'est perdu.
     */
    @Test
    void deux_mots_voisins_soudes_par_la_citation_restituent_le_texte_original() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Les tuteurs accompagnent les nouveaux élèves du quartier.",
            "lestuteurs accompagnent les nouveaux élèves du quartier", EpreuveType.TCF_EE))
            .contains("Les tuteurs accompagnent les nouveaux élèves du quartier");
    }

    /**
     * La negation ne se fabrique pas par recollage : « pas sage » ne rend pas
     * citable « passage », et un fragment de negation n'est jamais absorbe.
     */
    @Test
    void le_recollage_ne_fabrique_jamais_une_negation() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Cet enfant n'est pas sage dans notre classe.",
            "cet enfant n'est passage dans notre classe", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je ne veux p as quitter ce quartier calme.",
            "je ne veux pas quitter ce quartier calme", EpreuveType.TCF_EE))
            .isEmpty();
    }

    /** Deux nombres voisins ne se recollent jamais en un troisieme. */
    @Test
    void le_recollage_ne_fabrique_jamais_un_nombre() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "J'ai payé 20 26 euros pour cette veste.",
            "j'ai payé 2026 euros pour cette veste", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "La chambre coûte quatre vingt euros la nuit.",
            "la chambre coûte quatrevingt euros la nuit", EpreuveType.TCF_EE))
            .isEmpty();
    }

    /**
     * Seuls des BLANCS HORIZONTAUX separent deux fragments d'un meme mot. Une
     * apostrophe, un trait d'union, une ponctuation ou un saut de ligne marquent
     * une frontiere REELLE : les enjamber fabriquerait un mot.
     */
    @Test
    void le_recollage_n_enjambe_ni_ponctuation_ni_apostrophe_ni_saut_de_ligne() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je pars demain. Toi aussi tu pars bientôt.",
            "je pars demaintoi aussi tu pars bientôt", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Le grand-père accompagne les enfants du quartier.",
            "le grandpère accompagne les enfants du quartier", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : je pars\nCandidat : demain avec ma famille proche",
            "je parsdemain avec ma famille proche", EpreuveType.TCF_EO))
            .isEmpty();
    }

    /** Au-dela de trois fragments, ce n'est plus un mot coupe : c'est une recomposition. */
    @Test
    void le_recollage_s_arrete_a_trois_fragments() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Ce dossier reste in com pré hen sible pour les familles.",
            "ce dossier reste incompréhensible pour les familles", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Ce dossier reste in com préhensible pour les familles.",
            "ce dossier reste incompréhensible pour les familles", EpreuveType.TCF_EE))
            .contains("Ce dossier reste in com préhensible pour les familles");
    }

    /**
     * Le recollage ne relache RIEN : il ne fait pas passer un mot absent, un mot
     * substitue ni un ordre recompose. Toutes les lettres de la citation restent
     * presentes, contigues et dans le meme ordre.
     */
    @Test
    void le_recollage_n_autorise_aucun_mot_absent_ni_substitue() {
        String production = "Candidat : j'ai ach eté cette ves te chez vous hier matin";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "j'ai acheté cette belle veste chez vous", EpreuveType.TCF_EO))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "j'ai acheté cette jupe chez vous hier", EpreuveType.TCF_EO))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "cette veste j'ai acheté chez vous hier", EpreuveType.TCF_EO))
            .isEmpty();
    }

    /**
     * Le passage restitue reste la SOUS-CHAINE ORIGINALE EXACTE, coupures
     * comprises : le candidat relit ce qu'il a produit, pas ce que le correcteur
     * a recompose.
     */
    @Test
    void le_passage_restitue_reste_la_sous_chaine_originale_coupures_comprises() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : la cou ture s'est défai te dès le début",
            "la couture s'est défaite dès le début", EpreuveType.TCF_EO))
            .hasValueSatisfying(passage -> assertThat(passage)
                .isEqualTo("la cou ture s'est défai te dès le début")
                .doesNotContain("couture"));
    }

    @Test
    void le_recollage_exige_toujours_un_match_unique() {
        String fragment = "Candidat : j'ai ach eté cette ves te chez vous";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            fragment + "\nCandidat : j'ai acheté cette veste chez vous",
            "j'ai acheté cette veste chez vous", EpreuveType.TCF_EO))
            .isEmpty();
    }

    @Test
    void le_recollage_ne_traverse_pas_un_tour_de_l_examinateur() {
        String dialogue = "Candidat : j'ai ach\n"
            + "Examinateur : Pardon ?\n"
            + "Candidat : eté cette veste chez vous hier";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "j'ai acheté cette veste chez vous hier", EpreuveType.TCF_EO))
            .isEmpty();
    }

    @Test
    void le_recollage_ne_traverse_pas_une_hesitation() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : j'ai ach euh eté cette veste chez vous hier",
            "j'ai acheté cette veste chez vous hier", EpreuveType.TCF_EO))
            .isEmpty();
    }

    @Test
    void le_recollage_ne_rend_pas_citable_une_phrase_a_cheval_sur_une_relance() {
        String dialogue = """
            Candidat : je voudrais une voiture
            Examinateur : Pour combien de jours ?
            Candidat : pour trois jours""";

        String recolle = new TranscriptTurnStitcher(new ProductionEvaluationProperties())
            .stitch(dialogue);

        assertThat(EvaluationProofMatcher.canonicalPassage(
            recolle, "je voudrais une voiture pour trois jours", EpreuveType.TCF_EO))
            .isEmpty();
    }

    // ------------------------------------------------ begaiements (mots repetes)

    /**
     * CAS REEL, submission {@code e6f28822-f68b-4e1e-961a-8ddaaf24305a} (EO temps
     * reel, deepseek-v4-flash) : DEUX appels refuses d'affilee, tous deux
     * {@code PREUVE_NON_RATTACHEE}, puis mode degrade — alors que les deux
     * citations etaient JUSTES. Le correcteur avait seulement dedouble les
     * begaiements, ce que la grille lui ordonne par ailleurs de ne pas evaluer.
     * Deux et trois suppressions de token : au-dela de la tolerance d'UNE seule
     * edition, donc refus.
     */
    @Test
    void les_deux_citations_reelles_refusees_sont_desormais_rattachees() {
        String transcription = """
            Examinateur : Bonjour, je suis votre examinateur pour l'épreuve d'expression orale du TCF.
            Candidat : Oui, bonjour. Je me nomme Dialo Mammado, j'ai 21 ans, je suis d'origine guinéenne. Je suis un étudiant en informatique et puis Habite à Lille. Je suis ici d'une famille nombreuse quatre frères et une sœur qui se trouve tous tous chez moi en Guinée et non. Je recule c'est général
            Examinateur : Vous aimez aller au cinéma, dites-vous ? Quel genre de films aimez-vous regarder ?
            Candidat : Alors, vous aimez bien les oui, j'aime bien le cinéma, j'aime bien les les films les films comédies par exemple là dernièrement, on a été voir le film d'Amed Silla.""";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            transcription, "une sœur qui se trouve tous chez moi en Guinée", EpreuveType.TCF_EO))
            .as("un mot repete deux fois : deux suppressions, refusees jusqu'ici")
            .contains("une sœur qui se trouve tous tous chez moi en Guinée");

        assertThat(EvaluationProofMatcher.canonicalPassage(
            transcription, "j'aime bien le cinéma, j'aime bien les films comédies",
            EpreuveType.TCF_EO))
            .as("un GROUPE repete : trois suppressions, refusees jusqu'ici")
            .contains("j'aime bien le cinéma, j'aime bien les les films les films comédies");
    }

    /** Le begaiement n'est pas borne : trois occurrences s'elident comme deux. */
    @Test
    void un_mot_repete_trois_fois_reste_elidable() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je vais vais vais à la gare demain matin.",
            "je vais à la gare demain matin", EpreuveType.TCF_EO))
            .contains("Je vais vais vais à la gare demain matin");
    }

    /**
     * Le passage RESTITUE reste la sous-chaine originale exacte, begaiements
     * compris : le candidat lit ce qu'il a reellement produit, jamais une version
     * nettoyee.
     */
    @Test
    void le_passage_restitue_conserve_le_begaiement() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : je pense que que c'est bien organisé ici.",
            "je pense que c'est bien organisé", EpreuveType.TCF_EO))
            .contains("je pense que que c'est bien organisé");
    }

    /**
     * Quand le begaiement est en TETE de la citation, la lecture stricte trouve
     * deja le passage — sur la seconde occurrence, sans rien elider. La lecture
     * « begaiements elides » ne sert donc qu'aux repetitions INTERNES au passage
     * cite, ce qui est exactement le cas des deux citations reelles ci-dessus.
     */
    @Test
    void un_begaiement_en_tete_est_deja_resolu_par_la_lecture_stricte() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : mon mon frère habite à Lyon depuis longtemps.",
            "mon frère habite à Lyon", EpreuveType.TCF_EO))
            .contains("mon frère habite à Lyon");
    }

    /** SENS UNIQUE : la citation ne peut pas inventer une repetition absente. */
    @Test
    void une_citation_ne_peut_pas_inventer_une_repetition() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Mon frère habite à Lyon depuis longtemps.",
            "mon mon frère habite à Lyon", EpreuveType.TCF_EE))
            .isEmpty();
    }

    /** Une citation qui CONSERVE le begaiement reste evidemment acceptee. */
    @Test
    void une_citation_qui_conserve_le_begaiement_reste_acceptee() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : mon mon frère habite à Lyon depuis longtemps.",
            "mon mon frère habite à Lyon", EpreuveType.TCF_EO))
            .contains("mon mon frère habite à Lyon");
    }

    /**
     * TOKENS IMMUABLES : une repetition portant sur un nombre, un token chiffre
     * ou une negation n'est PAS elidable — un ecart de nombre ou de negation ne
     * peut pas naitre d'un begaiement.
     */
    @Test
    void une_repetition_sur_un_nombre_ou_une_negation_n_est_pas_elidable() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "J'ai payé vingt vingt euros pour ce billet de train.",
            "j'ai payé vingt euros pour ce billet de train", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Le train de 20 20 heures arrive toujours en retard.",
            "le train de 20 heures arrive toujours en retard", EpreuveType.TCF_EE))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Je ne ne veux pas partir en vacances cette année.",
            "je ne veux pas partir en vacances cette année", EpreuveType.TCF_EE))
            .isEmpty();
    }

    /** Aucun mot porteur de sens n'est dispense : l'elision n'ouvre rien d'autre. */
    @Test
    void l_elision_des_repetitions_n_autorise_aucun_mot_absent() {
        String production = "Candidat : je je travaille dans une entreprise de transport.";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je travaille dans une grande entreprise", EpreuveType.TCF_EO))
            .isEmpty();
        assertThat(EvaluationProofMatcher.canonicalPassage(
            production, "je travaille dans une usine de transport", EpreuveType.TCF_EO))
            .isEmpty();
    }

    /**
     * NON-REGRESSION, le point delicat : la lecture « begaiements elides » n'est
     * tentee que si la lecture stricte n'a RIEN trouve. Sans cet ordre, une
     * reprise de phrase ({@code je veux aller à Paris je veux aller à Lyon})
     * ferait apparaitre un second passage possible et rendrait AMBIGUE une
     * citation aujourd'hui acceptee.
     */
    @Test
    void une_reprise_de_phrase_ne_rend_pas_ambigue_une_citation_deja_acceptee() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : je veux aller à Paris je veux aller à Lyon.",
            "je veux aller à Lyon", EpreuveType.TCF_EO))
            .contains("je veux aller à Lyon");
    }

    /**
     * LIMITE ASSUMEE, documentee : une repetition LEGITIME est elidable par cette
     * regle. Sans consequence — le passage affiche reste le texte reel, et rien
     * ne se note sur une citation.
     */
    @Test
    void une_repetition_legitime_est_elidable_et_c_est_assume() {
        assertThat(EvaluationProofMatcher.canonicalPassage(
            "Candidat : c'est très très bien organisé dans cette ville.",
            "c'est très bien organisé dans cette ville", EpreuveType.TCF_EO))
            .contains("c'est très très bien organisé dans cette ville");
    }

    /** Une repetition ne traverse jamais un tour de l'examinateur. */
    @Test
    void l_elision_des_repetitions_ne_traverse_pas_un_tour_examinateur() {
        String dialogue = """
            Candidat : je voudrais une voiture
            Examinateur : je voudrais une voiture ?
            Candidat : oui pour trois jours""";

        assertThat(EvaluationProofMatcher.canonicalPassage(
            dialogue, "je voudrais une voiture oui pour trois jours", EpreuveType.TCF_EO))
            .isEmpty();
    }
}
