package com.sejourfr.app.service.versionciblee;

import java.util.Map;

/**
 * Les contrats de sortie CHARGÉS, un par variante, plus la description d'outil
 * qui va avec.
 *
 * <p>Un contrat de sortie ne peut pas être un champ unique du client depuis que
 * l'écrit et l'oral n'attendent pas la même sortie : à l'écrit
 * {@code exemple_cible}, à l'oral {@code reformulations}. Les fusionner en un
 * seul schéma aurait demandé des champs facultatifs — c'est-à-dire de retirer au
 * contrat ce qui fait sa valeur.
 *
 * <p>Chargés UNE fois au démarrage ({@code VersionCibleeLlmConfig}) : un fichier
 * de schéma absent doit faire échouer le boot, pas se manifester au premier
 * appel en production sous la forme d'un bloc silencieusement manquant.
 *
 * @param contrat contrat actif, qui décide des variantes existantes
 * @param schemas schéma JSON par variante ; l'ORAL est absent sous un contrat
 *                qui ne l'ouvre pas ({@link VersionCibleeContrat#oral()})
 */
public record VersionCibleeTools(VersionCibleeContrat contrat,
                                 Map<VersionCibleeVariante, Map<String, Object>> schemas) {

    public VersionCibleeTools {
        schemas = Map.copyOf(schemas);
    }

    /** Schéma de la variante, ou ÉCHEC BRUYANT : un appel sans contrat n'existe pas. */
    Map<String, Object> schema(VersionCibleeVariante variante) {
        Map<String, Object> schema = schemas.get(variante);
        if (schema == null) {
            throw new IllegalStateException("aucun tool-schema « version au niveau vise » pour "
                + variante + " sous le contrat " + contrat.code());
        }
        return schema;
    }

    String description(VersionCibleeVariante variante) {
        return VersionCibleeFields.toolDescription(contrat, variante);
    }
}
