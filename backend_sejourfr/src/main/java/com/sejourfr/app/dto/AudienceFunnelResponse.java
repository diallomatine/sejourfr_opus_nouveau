package com.sejourfr.app.dto;

import java.util.List;

/**
 * Funnel d'acquisition d'une cohorte d'inscription, servi a la console admin.
 *
 * <p>Contrat miroir a tenir a la main cote fronts (le web et l'admin le lisent).
 * Les compteurs sont des <strong>comptes distincts</strong>, jamais des lignes
 * brutes : un candidat qui ouvre trois fois l'ecran Premium compte une fois.
 *
 * @param cohortFrom  premier jour de la fenetre (Europe/Paris, {@code YYYY-MM-DD})
 * @param cohortTo    dernier jour de la fenetre, inclus
 * @param stages      les 7 etapes, toujours servies, toujours dans l'ordre du parcours
 * @param bySource    une ligne par reseau de provenance d'inscription
 * @param byPlatform  une ligne par plateforme d'inscription
 * @param daily       serie continue : un point par jour de la fenetre, meme a zero
 * @param integrity   controle « un seul diagnostic par compte », sur toute la base
 */
public record AudienceFunnelResponse(
        int days,
        String cohortFrom,
        String cohortTo,
        List<StageCount> stages,
        List<SourceFunnel> bySource,
        List<PlatformFunnel> byPlatform,
        List<DailyPoint> daily,
        Integrity integrity
) {

    /** Une etape du parcours et le nombre de comptes de la cohorte qui l'ont franchie. */
    public record StageCount(String stage, long count) {
    }

    /**
     * Funnel d'un reseau de provenance. {@code source} vaut « inconnu » pour les
     * comptes anterieurs a la mesure : ils sont montres, jamais caches — les
     * masquer ferait mentir les totaux.
     */
    public record SourceFunnel(
            String source,
            long signups,
            long diagnosticsStarted,
            long diagnosticsCompleted,
            long paywallViewed,
            long subscribeClicked,
            long checkoutStarted,
            long purchases
    ) {
    }

    /** Meme funnel, ventile par plateforme d'inscription (WEB / MOBILE / UNKNOWN). */
    public record PlatformFunnel(
            String platform,
            long signups,
            long diagnosticsStarted,
            long diagnosticsCompleted,
            long paywallViewed,
            long subscribeClicked,
            long checkoutStarted,
            long purchases
    ) {
    }

    /**
     * Un jour de la fenetre. Ici les comptes sont <strong>bruts par jour
     * d'occurrence</strong>, pas rattaches a la cohorte : c'est une courbe
     * d'activite, a ne pas diviser l'une par l'autre pour en tirer un taux.
     */
    public record DailyPoint(
            String day,
            long signups,
            long diagnosticsStarted,
            long diagnosticsCompleted,
            long purchases
    ) {
    }

    /**
     * Reponse a « un compte ne fait-il qu'un seul diagnostic ? ».
     * {@code accountsWithMultipleDiagnosticSessions} doit valoir 0.
     */
    public record Integrity(
            long accountsWithDiagnostic,
            long diagnosticSessionsTotal,
            long accountsWithMultipleDiagnosticSessions
    ) {
    }
}
