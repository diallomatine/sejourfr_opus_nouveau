package com.sejourfr.app.service.versionciblee;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

/**
 * REGISTRE des contrats de sortie du second appel « version au niveau visé »
 * que le code sait APPLIQUER.
 *
 * <p>Même doctrine que {@code EvaluationToolSchema} côté correction : une
 * version <b>inconnue de ce registre n'existe pas</b> — {@link #of(String)}
 * échoue bruyamment au lieu de dégrader en silence. Le boot la résout
 * ({@link VersionCibleeRubricsProvider}), donc une version oubliée empêche
 * l'application de démarrer, avant tout appel payé. C'est exactement ce que le
 * dépôt a payé cher avec le tool-schema v7 de la correction, mis en service sans
 * qu'aucune liste ne le connaisse.
 *
 * <p><b>Les capacités sont DÉRIVÉES DU RANG</b>, jamais d'une liste à
 * rallonger : chaque contrat se lit par rapport à celui qui le précède.
 * Ajouter une version, c'est ajouter sa constante — pas retoucher trois
 * ensembles ailleurs.
 *
 * <p>RÉVERSIBILITÉ : v1 reste ici, donc reste chargeable. Un retour arrière est
 * une paire de variables d'environnement
 * ({@code EVAL_VERSION_CIBLEE_RUBRICS_VERSION} +
 * {@code EVAL_VERSION_CIBLEE_TOOL_SCHEMA_VERSION}), sans migration : le bloc
 * persisté vit dans {@code feedback_json}.
 */
public enum VersionCibleeContrat {

    /**
     * Contrat d'origine, ÉCRIT SEULEMENT : {@code texte} (la réponse réécrite) et
     * {@code ce_qui_manque}, une liste de 2 à 3 leviers en <b>texte libre de 25
     * mots</b>.
     */
    V1("v1"),

    /**
     * Plan d'action : {@code leviers} devient une liste de couples
     * {@code {action, exemple}}, le texte modèle devient
     * {@code exemple_cible {texte, segments}} avec les passages à surligner, et
     * une tournure {@code a_retenir} est ajoutée. <b>Ouvre le second appel à
     * l'ORAL</b>, où le contrat remplace {@code exemple_cible} par des
     * {@code reformulations} désignées par NUMÉRO de segment.
     */
    V2("v2");

    private static final Map<String, VersionCibleeContrat> PAR_CODE = indexer();

    private final String code;

    VersionCibleeContrat(String code) {
        this.code = code;
    }

    private static Map<String, VersionCibleeContrat> indexer() {
        Map<String, VersionCibleeContrat> index = new LinkedHashMap<>();
        for (VersionCibleeContrat contrat : values()) {
            index.put(contrat.code, contrat);
        }
        return Map.copyOf(index);
    }

    public String code() {
        return code;
    }

    /** Vrai si ce contrat est {@code autre} ou une version postérieure. */
    boolean estAuMoins(VersionCibleeContrat autre) {
        return ordinal() >= autre.ordinal();
    }

    /**
     * PLAN D'ACTION structuré (v2 et au-delà) : leviers {@code {action, exemple}},
     * {@code exemple_cible} avec ses segments surlignables, {@code a_retenir}.
     * Sous v1, la sortie est {@code texte} + {@code ce_qui_manque[string]}.
     */
    public boolean planDAction() {
        return estAuMoins(V2);
    }

    /**
     * LE SECOND APPEL EXISTE À L'ORAL (v2 et au-delà), avec un contrat de sortie
     * PROPRE : on n'y réécrit jamais la production — on reformule deux ou trois
     * passages désignés par leur numéro.
     *
     * <p>Sous v1, l'oral ne produit rien du tout : le contrat n'a qu'une forme,
     * celle d'un texte réécrit, et rendre à un candidat un dialogue modèle à la
     * place de ce qu'il a dit serait trompeur.
     */
    public boolean oral() {
        return estAuMoins(V2);
    }

    static Optional<VersionCibleeContrat> find(String code) {
        return code == null ? Optional.empty() : Optional.ofNullable(PAR_CODE.get(code.trim()));
    }

    /**
     * Contrat correspondant au code, ou ÉCHEC BRUYANT. Ne jamais remplacer par un
     * repli tolérant : un mode dégradé muet est précisément ce qui a rendu la mise
     * en service d'un schéma invisible côté correction.
     */
    public static VersionCibleeContrat of(String code) {
        return find(code).orElseThrow(() -> new IllegalStateException(
            "contrat « version au niveau vise » inconnu : " + code
                + " — versions appliquees : " + PAR_CODE.keySet()
                + ". Enregistrer la version dans VersionCibleeContrat avant de la mettre en service."));
    }
}
