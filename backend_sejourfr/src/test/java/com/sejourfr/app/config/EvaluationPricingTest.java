package com.sejourfr.app.config;

import com.sejourfr.app.config.EvaluationConfigFixture.BlocProvider;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.Properties;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FIGE la COHERENCE du couple « modele correcteur ⇄ tarif », jamais le CHOIX du
 * modele.
 *
 * <p>Le cout estime d'une correction est <b>persiste</b> dans
 * {@code ai_evaluations} : un tarif faux y reste faux pour toujours, et il
 * n'existe aucun moyen de le recalculer a posteriori (les tokens sont stockes,
 * le prix du jour ne l'est pas). Le defaut vecu : le bloc {@code openai} portait
 * encore les tarifs de gpt-4o-mini (0,15 / 0,60) alors qu'on s'appretait a
 * appeler gpt-5.4, soit un facteur 17 en entree et 25 en sortie.
 *
 * <p><b>Ce que ce test ne fait plus.</b> Il portait une table fermee
 * « tel modele vaut tel prix ». Cette table transformait un changement de
 * modele — une decision d'exploitation, qui doit tenir en une ligne de
 * {@code .env} — en modification de code suivie d'une recompilation. Le premier
 * modele absent de la table faisait echouer le build alors que rien n'etait
 * casse.
 *
 * <p><b>Ce qu'il verifie a la place</b>, sans jamais nommer un modele :
 * <ol>
 *   <li>chaque bloc declare son modele ET ses deux tarifs en variables
 *       d'environnement — donc changer de modele ne demande pas d'editer ce
 *       fichier de configuration ;</li>
 *   <li>les tarifs effectivement resolus existent, sont strictement positifs et
 *       plausibles (entree ≤ sortie, ordres de grandeur d'une API publique) ;</li>
 *   <li>le tarif d'entree SERVIE PAR LE CACHE, quand il est declare, est
 *       inferieur ou egal au tarif d'entree plein : un cache plus cher que le
 *       plein tarif est une inversion, jamais une grille reelle. Il est
 *       FACULTATIF (0 = non declare, on facture plein tarif), sinon brancher un
 *       modele inedit exigerait une variable de plus ;</li>
 *   <li><b>le tarif voyage avec le modele</b> : un modele choisi ailleurs que
 *       dans {@code application.yaml} doit apporter ses deux tarifs depuis la
 *       MEME source. C'est exactement l'incident de gpt-4o-mini, exprime comme
 *       une regle et non comme une liste.</li>
 * </ol>
 */
class EvaluationPricingTest {

    /**
     * Un tarif au-dela de ce seuil (USD / 1M tokens) denonce une erreur d'unite
     * — un prix « par millier » recopie dans un champ « par million ». Aucune
     * API publique n'a jamais approche ce montant.
     */
    private static final double PLAFOND_PLAUSIBLE = 1_000.0;

    /**
     * <b>Aucun plancher n'est oppose a un tarif.</b> Le tarif d'entree servie
     * par le cache de DeepSeek vaut <b>0,007</b> $ / 1M : trois millimes de
     * dollar le million de tokens est une valeur PUBLIEE, pas une faute de
     * saisie. Toute borne basse posee ici retomberait le jour ou un fournisseur
     * baisse ses prix — et la regle du depot est de figer une COHERENCE, pas un
     * ordre de grandeur d'epoque.
     */
    private static final String NOTE_PAS_DE_PLANCHER =
        "aucun plancher : DeepSeek publie 0,007 $/1M en entree cache";

    /** {@code ${VAR:defaut}} — la forme qui rend une cle surchargeable sans editer le yaml. */
    private static final Pattern PLACEHOLDER = Pattern.compile("^\\$\\{[A-Za-z_][A-Za-z0-9_]*:.*}$");

    @Test
    void chaque_bloc_declare_son_modele_et_ses_tarifs_en_variables_d_environnement() {
        Properties yaml = EvaluationConfigFixture.yamlBrut();

        for (String provider : EvaluationConfigFixture.PROVIDERS) {
            String prefixe = EvaluationConfigFixture.PREFIXE + "." + provider;
            for (String cle : new String[] {
                ".model", ".cost-per-million-input-tokens", ".cost-per-million-output-tokens"}) {
                String brut = yaml.getProperty(prefixe + cle);
                assertThat(brut).as("propriete absente : %s%s", prefixe, cle).isNotNull();
                assertThat(brut.strip())
                    .as("%s%s doit rester surchargeable par variable d'environnement "
                        + "(forme ${VAR:defaut}) : sans cela, changer de modele ou de tarif "
                        + "obligerait a editer application.yaml, ce que le proprietaire refuse.",
                        prefixe, cle)
                    .matches(PLACEHOLDER.asMatchPredicate());
            }
        }
    }

    @Test
    void le_tarif_effectif_de_chaque_bloc_est_present_positif_et_plausible() {
        ProductionEvaluationProperties props = EvaluationConfigFixture.resolue();

        for (String provider : EvaluationConfigFixture.PROVIDERS) {
            verifieTarif(EvaluationConfigFixture.bloc(props, provider));
        }
    }

    @Test
    void un_modele_choisi_hors_du_yaml_apporte_ses_deux_tarifs() {
        ProductionEvaluationProperties effective = EvaluationConfigFixture.resolue();
        ProductionEvaluationProperties defauts = EvaluationConfigFixture.defautsYaml();
        // NOMS seuls : cet environnement porte toutes les cles d'API du projet,
        // et un message d'echec finit dans les journaux de build.
        java.util.Set<String> horsYaml = EvaluationConfigFixture.nomsVariablesHorsYaml();

        for (String provider : EvaluationConfigFixture.PROVIDERS) {
            String modeleEffectif = EvaluationConfigFixture.bloc(effective, provider).modele();
            String modeleYaml = EvaluationConfigFixture.bloc(defauts, provider).modele();
            if (modeleEffectif == null || modeleEffectif.equals(modeleYaml)) continue;

            for (String variable : new String[] {
                EvaluationConfigFixture.varCoutEntree(provider),
                EvaluationConfigFixture.varCoutSortie(provider)}) {
                assertThat(horsYaml.contains(variable))
                    .as("%s vaut '%s' au lieu du defaut '%s' : le modele a ete choisi hors "
                        + "d'application.yaml, ses TARIFS doivent l'etre aussi, dans la meme "
                        + "source. Poser %s a cote de %s. Le cout d'une correction est persiste "
                        + "dans ai_evaluations : un tarif reste de l'ancien modele y reste faux "
                        + "pour toujours (defaut vecu : facteur 17 en entree).",
                        EvaluationConfigFixture.varModele(provider), modeleEffectif, modeleYaml,
                        variable, EvaluationConfigFixture.varModele(provider))
                    .isTrue();
            }
        }
    }

    /**
     * Les trois regles de plausibilite d'un tarif, partagees avec
     * {@link EvaluationProviderSwapTest} : ce sont elles qui doivent continuer
     * de passer quand on branche un modele qui n'existe pas encore.
     */
    static void verifieTarif(BlocProvider bloc) {
        assertThat(bloc.modele())
            .as("%s : aucun modele configure", bloc.provider())
            .isNotNull().isNotBlank();

        assertThat(bloc.coutEntree())
            .as("%s (modele %s) : tarif d'entree absent ou nul — un cout de 0 est enregistre "
                + "tel quel dans ai_evaluations et rend toute analyse de depense fausse.",
                bloc.provider(), bloc.modele())
            .isGreaterThan(0.0).isFinite().isLessThan(PLAFOND_PLAUSIBLE);

        assertThat(bloc.coutSortie())
            .as("%s (modele %s) : tarif de sortie absent ou nul.", bloc.provider(), bloc.modele())
            .isGreaterThan(0.0).isFinite().isLessThan(PLAFOND_PLAUSIBLE);

        assertThat(bloc.coutSortie())
            .as("%s (modele %s) : la sortie coute %s et l'entree %s. Aucun fournisseur ne "
                + "facture la sortie moins cher que l'entree — les deux valeurs sont "
                + "probablement inversees. (%s)",
                bloc.provider(), bloc.modele(), bloc.coutSortie(), bloc.coutEntree(),
                NOTE_PAS_DE_PLANCHER)
            .isGreaterThanOrEqualTo(bloc.coutEntree());

        // FACULTATIF : 0 = ce fournisseur ne declare pas de tarif de cache, et
        // ses tokens d'entree sont alors factures au plein tarif — on surestime,
        // jamais l'inverse. On ne verifie donc QUE le sens quand il est declare.
        if (bloc.coutEntreeCache() > 0) {
            assertThat(bloc.coutEntreeCache())
                .as("%s (modele %s) : l'entree servie par le CACHE coute %s, soit plus que "
                    + "l'entree pleine (%s). Un cache plus cher que le plein tarif n'existe "
                    + "chez aucun fournisseur — les deux valeurs sont probablement inversees. "
                    + "(%s)",
                    bloc.provider(), bloc.modele(), bloc.coutEntreeCache(), bloc.coutEntree(),
                    NOTE_PAS_DE_PLANCHER)
                .isLessThanOrEqualTo(bloc.coutEntree())
                .isFinite()
                .isLessThan(PLAFOND_PLAUSIBLE);
        }
    }
}
