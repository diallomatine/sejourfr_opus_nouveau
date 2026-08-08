package com.sejourfr.app.service;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

/**
 * CALIBRATION de l'indicateur de qualite de transcription, sur des extraits
 * REELS de la base.
 *
 * <p>Ce que cette classe verrouille, c'est le fosse : les transcriptions de la
 * fenetre du bug « mot coupe en deux » (28 juin → 4 juillet 2026) doivent
 * ressortir DEGRADEES, celles du regime actuel doivent ressortir SAINES, et une
 * production ecrite propre ne doit jamais etre declaree degradee. Si un jour ce
 * test devient rouge parce que le seuil a bouge, c'est le seuil qu'il faut
 * justifier, pas le test qu'il faut ajuster.
 *
 * <p>Reperes mesures sur les 123 productions mesurables de la base : pire cas
 * sain 4,84 %, plus doux cas abime 18,29 %. Le seuil est a 10 %, au milieu d'un
 * intervalle ou il n'existe AUCUNE observation.
 */
class TranscriptionQualityAuditTest {

    /**
     * Extrait REEL du 2026-06-28 (temps reel, fenetre du bug) : le transcripteur
     * coupe les mots en morceaux — {@code emplo yé}, {@code age nce},
     * {@code voi ture}, {@code Bo njour}.
     */
    private static final String DIALOGUE_DEGRADE = """
        Examinateur : Voici la deuxième partie. Je suis l'employé d'une agence de location \
        de voitures.
        Candidat : Bo njour. Je suis l' emplo yé de l' age nce de location de voi ture.
        Examinateur : Vous souhaitez louer une voiture pour aller voir votre ami Diego.
        Candidat : Oui , bon jour , j'ai mera is lou er une peti te voi ture cita di ne .
        Candidat : Est-ce que vou s en avez de dis po nible là immédiatement.
        Examinateur : Pour combien de jours souhaitez-vous la louer ?
        Candidat : J' ai merais la lou er pour 5 jours s'il vous plaît, c'est pour un
        Candidat : week-end à Perpignan avec ma fami lle et mes deux enfa nts.
        """;

    /**
     * Extrait REEL du 2026-08-08 (temps reel, apres correction du bug) : la meme
     * source, le meme modele, mais le texte tient debout. C'est exactement le cas
     * que l'indicateur ne doit PAS declarer degrade.
     */
    private static final String DIALOGUE_SAIN = """
        Examinateur : Bonjour, pouvez-vous vous présenter ?
        Candidat : Oui, bonjour, je me nomme Diallo, j'ai 21 ans et je suis d'origine
        Candidat : guinéenne. Je suis un étudiant en informatique à licence 3 et puis
        Candidat : j'habite à Lille et j'étudie également à l'université de Lille.
        Examinateur : Et après votre master, quels sont vos projets ?
        Candidat : Après le master j'aimerais travailler, chercher de l'expérience en CDI
        Candidat : peut-être 2 à 3 ans et ensuite j'aimerais bien rentrer en Guinée pour
        Candidat : pouvoir aider mon pays à se développer.
        """;

    /** Production ECRITE propre : la reference saine du corpus. */
    private static final String TEXTE_ECRIT = """
        Salut Paul ! J'ai une bonne nouvelle : j'ai enfin déménagé la semaine dernière. \
        Mon logement se trouve près de la gare, il est lumineux et il y a un petit jardin \
        derrière la maison. Le quartier est calme et les commerces sont tout près. \
        Viens passer le week-end quand tu veux, il y a de la place pour toi.
        """;

    // ------------------------------------------------------------ le fosse

    @Test
    void declare_degradee_une_transcription_de_la_fenetre_du_bug_mot_coupe() {
        var mesure = TranscriptionQualityAudit.mesurer(DIALOGUE_DEGRADE);

        assertThat(mesure.mesurable()).isTrue();
        assertThat(mesure.degradee()).isTrue();
        assertThat(mesure.tauxFormesSuspectes())
            .as("la fenetre du bug mesure 18,29 %% a 26,94 %% en base")
            .isGreaterThan(TranscriptionQualityAudit.SEUIL_FORMES_SUSPECTES);
        // Les debris reellement produits par le transcripteur : « l' age nce »,
        // « voi ture », « lou er », « dis po nible ».
        assertThat(mesure.formes()).contains("nce", "voi", "lou", "er", "po", "di");
    }

    @Test
    void ne_declare_pas_degradee_une_transcription_temps_reel_du_regime_actuel() {
        var mesure = TranscriptionQualityAudit.mesurer(DIALOGUE_SAIN);

        assertThat(mesure.mesurable()).isTrue();
        assertThat(mesure.degradee())
            .as("apres correction du bug, aucune session ne depasse 4,84 %%")
            .isFalse();
        assertThat(mesure.tauxFormesSuspectes())
            .isLessThan(TranscriptionQualityAudit.SEUIL_FORMES_SUSPECTES);
    }

    @Test
    void ne_declare_jamais_degradee_une_production_ecrite_propre() {
        var mesure = TranscriptionQualityAudit.mesurer(TEXTE_ECRIT);

        assertThat(mesure.mesurable()).isTrue();
        assertThat(mesure.degradee()).isFalse();
        assertThat(mesure.tauxFormesSuspectes()).isEqualTo(0.0, within(0.02));
    }

    // -------------------------------------------------------- garde-fous

    /**
     * Les mots-outils courants ({@code je}, {@code les}, {@code des}, {@code aux},
     * {@code toi}) ne sont JAMAIS suspects. Sans cette garantie, mesure faite, la
     * mediane des productions ecrites saines passait de 0,00 % a 5,26 % et
     * l'indicateur devenait inutilisable.
     */
    @Test
    void les_mots_outils_courants_ne_sont_jamais_comptes_suspects() {
        var mesure = TranscriptionQualityAudit.mesurer("""
            Je les ai vus aux alentours de la gare, et toi tu es venu avec des amis ; \
            on a mangé au restaurant du coin puis je suis rentré chez moi vers dix heures \
            parce que le lendemain je travaillais très tôt le matin.
            """);

        assertThat(mesure.mesurable()).isTrue();
        assertThat(mesure.formes()).isEmpty();
        assertThat(mesure.tauxFormesSuspectes()).isZero();
    }

    /** Une production trop courte n'est pas mesurable : un token y pese 2,5 %. */
    @Test
    void une_production_trop_courte_n_est_ni_mesurable_ni_degradee() {
        var mesure = TranscriptionQualityAudit.mesurer(
            "Candidat : Bo njour , je m'appe lle Ab dul et j' ai 2 5 an s.");

        assertThat(mesure.mesurable()).isFalse();
        assertThat(mesure.degradee())
            .as("en dessous du plancher, on ne conclut rien — surtout pas au pire")
            .isFalse();
    }

    /**
     * Seuls les tours {@code Candidat :} sont mesures : les mots de l'examinateur
     * ne sont pas la production. Un examinateur hache ne doit pas plafonner la
     * confiance du candidat.
     */
    @Test
    void ne_mesure_que_les_tours_du_candidat() {
        String dialogue = """
            Examinateur : Bo njour , je su is l' exa mi na teur de l' epr eu ve d' expr
            Examinateur : ess ion or ale du T C F pou r au jour d' hui mon si eur.
            """ + DIALOGUE_SAIN;

        assertThat(TranscriptionQualityAudit.mesurer(dialogue).degradee()).isFalse();
    }

    @Test
    void une_production_vide_ou_absente_n_est_pas_mesurable() {
        assertThat(TranscriptionQualityAudit.mesurer(null).mesurable()).isFalse();
        assertThat(TranscriptionQualityAudit.mesurer("   ").mesurable()).isFalse();
    }

    /**
     * Les seuils sont des CHIFFRES MESURES, pas des reglages d'humeur : les
     * deplacer sans refaire la mesure doit se voir dans une revue.
     */
    @Test
    void les_seuils_restent_ceux_qui_ont_ete_mesures() {
        assertThat(TranscriptionQualityAudit.SEUIL_FORMES_SUSPECTES).isEqualTo(0.10);
        assertThat(TranscriptionQualityAudit.SEUIL_COLLAGES).isEqualTo(0.02);
        assertThat(TranscriptionQualityAudit.MOTS_MIN).isEqualTo(40);
    }
}
