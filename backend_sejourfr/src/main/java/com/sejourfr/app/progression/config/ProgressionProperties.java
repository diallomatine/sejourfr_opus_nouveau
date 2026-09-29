package com.sejourfr.app.progression.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Les deux seuls reglages du moteur qui vivent dans {@code application.yaml} :
 * <b>quelle version de configuration est active</b> et <b>si le moteur pilote
 * le Plan</b>.
 *
 * <p>Tout le reste — seuils, poids, demi-vie, epoch, gates — vit dans
 * {@code progression-config-vN.json} et nulle part ailleurs (§4, invariant
 * I32). Cette classe ne porte donc <b>aucune</b> valeur metier : la doctrine
 * « valeurs par defaut ici ET dans le YAML » des autres {@code *Properties} du
 * depot ne s'applique pas, parce qu'il n'y a rien a dupliquer.
 *
 * <p>Un retour arriere de calibration est un changement d'{@code engineVersion}
 * ici, suivi d'un replay (§29) — jamais une edition d'un fichier de config
 * deja livre.
 */
@ConfigurationProperties(prefix = "sejourfr.progression")
public class ProgressionProperties {

    /**
     * Le regime d'exploitation. Demarre en {@link ProgressionEngineMode#SHADOW}
     * et n'en sort que sur decision produit (§47).
     */
    private ProgressionEngineMode mode = ProgressionEngineMode.SHADOW;

    /**
     * La version de configuration a charger : le fichier lu est
     * {@code progression/progression-config-v{engineVersion}.json}.
     */
    private int engineVersion = 1;

    public ProgressionEngineMode getMode() {
        return mode;
    }

    public void setMode(ProgressionEngineMode mode) {
        this.mode = mode;
    }

    public int getEngineVersion() {
        return engineVersion;
    }

    public void setEngineVersion(int engineVersion) {
        this.engineVersion = engineVersion;
    }

    /** Le moteur pilote-t-il reellement le Plan servi ? */
    public boolean isActive() {
        return mode == ProgressionEngineMode.ACTIVE;
    }
}
