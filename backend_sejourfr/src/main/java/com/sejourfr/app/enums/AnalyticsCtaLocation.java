package com.sejourfr.app.enums;

/**
 * Emplacement d'un CTA au moment ou il est clique.
 *
 * <p>C'est la dimension qui repond a « quel bouton amene reellement au
 * paiement ». Elle est <b>fermee</b> : l'endpoint d'ingestion est public, et
 * une valeur libre laisserait n'importe qui creer autant d'emplacements qu'il
 * veut — le tableau deviendrait une liste de variantes d'orthographe.
 *
 * <p><b>Les libelles FR sont geles par {@code AnalyticsLabelsTest}</b> : ils ne
 * transitent pas par le reseau, chaque front en tient sa propre copie a la main
 * (patron {@code SkillLabelsTest}). Un libelle qui bouge, ce sont quatre
 * fichiers a changer dans la meme passe.
 */
public enum AnalyticsCtaLocation {

    /** Depuis le rapport de diagnostic. */
    DIAGNOSTIC_REPORT("Rapport diagnostic"),

    /** Depuis une carte verrouillee du Plan. */
    LOCKED_PLAN("Plan verrouillé"),

    /** Depuis la page tarifs. */
    PRICING("Page tarifs"),

    /** Depuis un ecran de correction IA. */
    AI_CORRECTION("Correction IA"),

    /** Depuis un examen blanc. */
    MOCK_EXAM("Examen blanc"),

    /** Bandeau haut d'une landing. */
    HERO("Hero"),

    /** Milieu de page d'une landing. */
    MIDDLE("Milieu de page"),

    /** Barre collante d'une landing. */
    STICKY("Barre collante"),

    /** Pied de page d'une landing. */
    FOOTER("Pied de page"),

    /** Emplacement non couvert par les precedents. */
    OTHER("Autre");

    private final String label;

    AnalyticsCtaLocation(String label) {
        this.label = label;
    }

    /** Libelle FR affiche. Gele par test. */
    public String getLabel() {
        return label;
    }
}
