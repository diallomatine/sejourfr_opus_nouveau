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
        TcfDiagnosticProgressionDto progression,
        /**
         * Combien de taches d'expression mesurees sont <b>sous la cible</b>.
         *
         * <p>🛑 <b>Ce compte n'est PAS plafonne</b>, a la difference de
         * {@link #priorites()} qui l'est a trois par regle produit. C'est lui,
         * et lui seul, qui fait le « N competences ciblees detectees » de
         * l'ecran : le calculer sur une liste deja tronquee afficherait « 3 »
         * quel que soit le nombre reel.
         *
         * <p>🛑 <b>{@code 0} est un etat NORMAL</b> — toutes les taches
         * mesurees sont a la cible. Les fronts ne rendent alors aucune ligne.
         * Une tache <b>non mesuree</b> n'entre pas dans ce compte : elle n'est
         * pas « en dessous », elle est inconnue.
         */
        int tachesSousLaCible
) {
    /** Le niveau d'une epreuve. {@code niveau} nul = non evaluee. */
    public record EpreuveNiveau(
            com.sejourfr.app.enums.EpreuveType epreuve,
            NiveauCecrl niveau) {
    }
}
