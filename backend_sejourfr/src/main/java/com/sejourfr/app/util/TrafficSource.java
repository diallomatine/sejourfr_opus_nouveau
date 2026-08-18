package com.sejourfr.app.util;

import java.util.Locale;
import java.util.Set;

/**
 * Allowlist des reseaux de provenance et sa normalisation — <strong>autorite
 * unique</strong>.
 *
 * <p>Extraite a la deuxieme occurrence : la liste vivait dans
 * {@code PageViewService} (agregat anonyme des landings) et le funnel par
 * compte en avait besoin a l'identique. Deux copies auraient fini par
 * diverger, et « tiktok » aurait alors ete range dans deux dimensions
 * differentes selon la surface — exactement le defaut qui rend une mesure
 * inexploitable.
 *
 * <p>La liste est <strong>fermee</strong> : tout ce qui n'y figure pas devient
 * {@link #OTHER}. C'est ce qui borne la cardinalite de {@code page_views} face
 * a un endpoint d'ecriture public, et ce qui empeche un tiers de fabriquer des
 * dimensions a volonte.
 */
public final class TrafficSource {

    /** Provenances normalisees. Une valeur inconnue est rangee dans « autre ». */
    public static final Set<String> KNOWN =
            Set.of("tiktok", "instagram", "whatsapp", "facebook", "youtube", "direct");

    /** Repli d'une provenance hors allowlist. */
    public static final String OTHER = "autre";

    /** Repli d'une provenance absente : personne ne l'a envoyee, c'est un acces direct. */
    public static final String DIRECT = "direct";

    /**
     * Repli de LECTURE quand la base ne porte aucune provenance (comptes
     * anterieurs a la mesure). Distinct de {@link #DIRECT} : « direct » est une
     * provenance observee, « inconnu » est une absence d'observation. Les
     * confondre gonflerait le direct de tout l'historique.
     */
    public static final String UNKNOWN = "inconnu";

    private TrafficSource() {
    }

    /** Provenance normalisee d'une valeur brute recue d'un client. */
    public static String normalize(String raw) {
        if (raw == null || raw.isBlank()) return DIRECT;
        String normalized = raw.trim().toLowerCase(Locale.ROOT);
        return KNOWN.contains(normalized) ? normalized : OTHER;
    }

    /** Provenance affichable d'une valeur lue en base, {@code null} compris. */
    public static String readOrUnknown(String stored) {
        if (stored == null || stored.isBlank()) return UNKNOWN;
        return stored;
    }
}
