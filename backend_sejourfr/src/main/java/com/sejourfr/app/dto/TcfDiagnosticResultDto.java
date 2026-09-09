package com.sejourfr.app.dto;

import com.sejourfr.app.enums.NiveauCecrl;

import java.time.Instant;
import java.util.List;

/**
 * L'ecran de resultat du diagnostic TCF (10_ §4.5).
 *
 * <p>🛑 <b>Aucun resultat n'est masque derriere le paywall</b> : « le paywall
 * porte sur le plan, pas sur le constat » (10_ §4.5). Ce DTO ne porte donc
 * aucun {@code locked}.
 *
 * <p>🛑 <b>{@code niveauGlobal} peut etre {@code null}</b> — aucune epreuve
 * evaluee — et une epreuve non evaluee porte un {@code niveau} nul. C'est
 * « inconnu », jamais le palier le plus bas : l'ecran doit le signaler
 * explicitement (« Comprehension orale : non evaluee »), pas afficher un A1.
 */
public record TcfDiagnosticResultDto(
        java.util.UUID sessionId,
        NiveauCecrl niveauGlobal,
        NiveauCecrl cible,
        /** Les 4 epreuves avec leur niveau, dans l'ordre d'affichage. */
        List<EpreuveNiveau> epreuves,
        List<TcfDiagnosticPriorityDto> priorites,
        /** Epreuves deja au niveau cible — le bloc « Deja au niveau attendu ». */
        List<EpreuveNiveau> dejaAuNiveau,
        Instant completedAt,
        /**
         * <b>Ce qui a bouge depuis le diagnostic precedent</b> (L7).
         *
         * <p>🛑 <b>{@code null} est le cas NORMAL</b> : c'est le premier
         * diagnostic, il n'y a rien a comparer. L'ecran n'affiche alors aucun
         * bloc de progression — il n'en fabrique pas un vide.
         */
        TcfDiagnosticProgressionDto progression
) {
    /** Le niveau d'une epreuve. {@code niveau} nul = non evaluee. */
    public record EpreuveNiveau(
            com.sejourfr.app.enums.EpreuveType epreuve,
            NiveauCecrl niveau) {
    }
}
