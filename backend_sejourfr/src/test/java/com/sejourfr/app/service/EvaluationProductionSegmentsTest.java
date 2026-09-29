package com.sejourfr.app.service;

import com.sejourfr.app.enums.EpreuveType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La DECOUPE NUMEROTEE servie au correcteur sous le contrat v6. Ce qu'elle doit
 * garantir, et que ces tests verrouillent :
 * <ul>
 *   <li>a l'oral, un numero = un tour {@code Candidat :}, et l'examinateur n'en
 *       porte AUCUN — c'est ce qui rend structurellement impossible de citer
 *       l'examinateur comme preuve du candidat ;</li>
 *   <li>a l'ecrit, un numero = une phrase ;</li>
 *   <li>le texte d'un segment est la sous-chaine ORIGINALE exacte : c'est lui
 *       qui finira dans {@code preuve}, donc sous les yeux du candidat.</li>
 * </ul>
 */
class EvaluationProductionSegmentsTest {

    @Test
    void a_l_oral_seuls_les_tours_du_candidat_sont_numerotes() {
        String dialogue = """
            Examinateur : Bonjour, pourquoi souhaitez-vous déménager ?
            Candidat : je veux habiter plus près de mon travail
            Examinateur : Et les transports ?
            Candidat : il y a le tramway juste en bas""";

        EvaluationProductionSegments segments =
            EvaluationProductionSegments.of(dialogue, EpreuveType.TCF_EO);

        assertThat(segments.taille()).isEqualTo(2);
        assertThat(segments.texte(1)).contains("je veux habiter plus près de mon travail");
        assertThat(segments.texte(2)).contains("il y a le tramway juste en bas");
        assertThat(segments.rendu())
            .contains("[1] Candidat : je veux habiter plus près de mon travail")
            .contains("[2] Candidat : il y a le tramway juste en bas")
            .as("l'examinateur est MONTRE (le deroule de l'echange compte) mais pas numerote")
            .contains("Examinateur : Et les transports ?")
            .doesNotContain("] Examinateur");
    }

    @Test
    void un_numero_hors_bornes_ne_resout_rien() {
        EvaluationProductionSegments segments = EvaluationProductionSegments.of(
            "Candidat : bonjour je voudrais une chambre", EpreuveType.TCF_EO);

        assertThat(segments.taille()).isEqualTo(1);
        assertThat(segments.texte(0)).isEmpty();
        assertThat(segments.texte(2)).isEmpty();
    }

    @Test
    void a_l_ecrit_un_segment_est_une_phrase() {
        String texte = "Salut Marie ! J'ai déménagé samedi dernier. "
            + "Mon appartement est lumineux, il donne sur un petit jardin. Viens le voir ?";

        EvaluationProductionSegments segments =
            EvaluationProductionSegments.of(texte, EpreuveType.TCF_EE);

        assertThat(segments.segments()).hasSize(4);
        assertThat(segments.texte(1)).contains("Salut Marie !");
        assertThat(segments.texte(2)).contains("J'ai déménagé samedi dernier.");
        assertThat(segments.texte(3))
            .contains("Mon appartement est lumineux, il donne sur un petit jardin.");
        assertThat(segments.texte(4)).contains("Viens le voir ?");
        assertThat(segments.rendu()).startsWith("[1] Salut Marie !");
    }

    /**
     * Une production sans aucune ponctuation forte reste un seul segment. C'est
     * une preuve peu precise, jamais une preuve fausse — et c'est preferable a
     * une coupure arbitraire que le correcteur ne saurait pas designer.
     */
    @Test
    void un_texte_sans_ponctuation_forte_forme_un_seul_segment() {
        EvaluationProductionSegments segments = EvaluationProductionSegments.of(
            "salut marie j'ai demenage samedi et mon appartement est lumineux",
            EpreuveType.TCF_EE);

        assertThat(segments.taille()).isEqualTo(1);
        assertThat(segments.texte(1))
            .contains("salut marie j'ai demenage samedi et mon appartement est lumineux");
    }

    /**
     * Un fragment sans le moindre mot ne devient jamais un segment a lui seul :
     * offrir au correcteur un numero qui ne designe aucun mot serait lui offrir
     * une preuve vide.
     */
    @Test
    void un_fragment_sans_aucun_mot_ne_forme_pas_un_segment() {
        EvaluationProductionSegments segments = EvaluationProductionSegments.of(
            "J'aime beaucoup Lyon. . . . Je veux y rester.", EpreuveType.TCF_EE);

        assertThat(segments.taille()).isEqualTo(2);
        // Rattache au precedent, jamais supprime : la decoupe retire des
        // FRONTIERES, elle ne retire jamais de contenu.
        assertThat(segments.texte(1)).contains("J'aime beaucoup Lyon. . . .");
        assertThat(segments.texte(2)).contains("Je veux y rester.");
    }

    /** Sans marqueur de tour, la transcription orale est un monologue du candidat. */
    @Test
    void une_transcription_orale_sans_marqueur_se_decoupe_en_phrases() {
        EvaluationProductionSegments segments = EvaluationProductionSegments.of(
            "bonjour je m'appelle Samuel. j'ai vingt-cinq ans et j'habite à Lille.",
            EpreuveType.TCF_EO);

        assertThat(segments.taille()).isEqualTo(2);
        assertThat(segments.texte(2)).contains("j'ai vingt-cinq ans et j'habite à Lille.");
    }

    /**
     * INVARIANT : le texte d'un segment est la production TELLE QUELLE. Les
     * begaiements et les artefacts de transcription y restent, comme ils
     * restaient dans le passage restitue par le rapprochement litteral.
     */
    @Test
    void le_texte_d_un_segment_est_la_production_telle_quelle() {
        String dialogue = "Candidat : une sœur qui se trouve tous tous chez moi en Guinée";

        assertThat(EvaluationProductionSegments.of(dialogue, EpreuveType.TCF_EO).texte(1))
            .contains("une sœur qui se trouve tous tous chez moi en Guinée");
    }

    @Test
    void une_production_vide_ne_produit_aucun_segment() {
        assertThat(EvaluationProductionSegments.of("   ", EpreuveType.TCF_EE).taille()).isZero();
        assertThat(EvaluationProductionSegments.of(null, EpreuveType.TCF_EO).taille()).isZero();
    }

    /** Un dialogue ou le candidat n'a rien dit n'offre aucun segment citable. */
    @Test
    void un_dialogue_sans_tour_candidat_n_offre_aucun_segment() {
        EvaluationProductionSegments segments = EvaluationProductionSegments.of(
            "Examinateur : Bonjour, je vous écoute.\nExaminateur : Vous m'entendez ?",
            EpreuveType.TCF_EO);

        assertThat(segments.taille()).isZero();
        assertThat(segments.rendu()).doesNotContain("[1]");
    }
}
