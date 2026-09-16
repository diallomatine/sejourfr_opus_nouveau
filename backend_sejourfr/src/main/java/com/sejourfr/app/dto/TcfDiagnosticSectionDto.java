package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.TcfDiagnosticSectionState;

import java.util.UUID;

/**
 * Une section du diagnostic TCF, telle que l'ecran d'accueil l'affiche
 * (30_ §5.1).
 *
 * <p>⚠️ <b>Elle porte son RESULTAT depuis le 2026-09-13</b>, et c'est un
 * arbitrage du proprietaire : « chaque epreuve du diagnostic complet se lance
 * comme un examen blanc complet de l'epreuve — donc si on finit la CO ou la CE,
 * on voit tout de suite le resultat dessus et on peut consulter le rapport
 * comme un examen ». Une section EST un examen blanc de son epreuve : elle en a
 * la composition, la duree, le pipeline de soumission — elle en a desormais
 * aussi la restitution.
 *
 * <p>🛑 <b>REVOQUE 10_ §4.2</b> (« aucun resultat detaille avant la fin — le
 * resultat est le moment de conversion, il ne doit pas etre dilue »). Ce qui
 * reste vrai de cette regle, et qui n'a pas bouge : le <b>resultat d'ensemble</b>
 * — niveau global, priorites, plan personnalise — vit sur
 * {@link TcfDiagnosticResultDto} et nulle part ailleurs. Une epreuve rend son
 * niveau ; elle ne rend ni le plancher des quatre, ni une priorite.
 */
public record TcfDiagnosticSectionDto(
        EpreuveType epreuve,
        /** {@code null} si la section n'existe pas (mode degrade : pas de contenu). */
        UUID attemptId,
        TcfDiagnosticSectionState etat,
        /** Chrono de la section. {@code null} en EO, qui se chronometre par tache. */
        Integer timeLimitSeconds,
        Integer totalQuestions,
        /**
         * Le niveau mesure sur CETTE epreuve.
         *
         * <p>🛑 <b>{@code null} = non evaluee, jamais le palier le plus bas</b> :
         * section jamais commencee, rien d'exploitable, ou correction encore en
         * vol ({@link #analyseEnCours()}). L'ecran la <b>nomme</b>, il n'affiche
         * pas un A1.
         */
        NiveauCecrl niveau,
        /**
         * Score calibre <b>100-499</b> de la section, <b>comprehension
         * seulement</b> et une fois close. C'est la valeur que les examens
         * blancs de module affichent deja, lue chez la meme autorite.
         *
         * <p>{@code null} en production (une production n'a pas de score) et
         * tant que la section n'est pas terminee.
         */
        Integer scoreCalibre,
        /**
         * {@code true} quand des productions ont ete rendues et qu'au moins une
         * attend encore sa correction.
         *
         * <p>Il distingue « on attend l'IA » de « rien d'exploitable » — deux
         * etats qui donnent tous deux {@code niveau == null}. Meme sursis qu'un
         * examen blanc : chaque tache part a la correction des qu'elle est
         * rendue, seule la derniere se fait attendre.
         */
        boolean analyseEnCours,
        /**
         * L'attempt dont le <b>rapport</b> explique {@link #niveau()} — la
         * destination de « Voir le rapport ».
         *
         * <p>C'est {@link #attemptId()} quand la section a elle-meme mesure
         * l'epreuve. Quand l'epreuve a ete mesuree <b>ailleurs</b> (examen blanc
         * isole, examen TCF complet), c'est l'examen qualifiant le plus recent :
         * une section vide n'a pas de rapport, l'examen qui l'a mesuree en a un.
         *
         * <p>🛑 {@code null} = <b>rien de mesure</b>, donc aucun rapport a
         * ouvrir. Les fronts ne proposent alors pas le lien.
         *
         * <p>🛑 <b>Il ne dit PAS la provenance</b>, et ce n'est pas un oubli : le
         * proprietaire refuse tout vocabulaire « mesuree ailleurs » a l'ecran
         * (2026-09-16). Une epreuve mesuree se lit comme <b>faite</b>, point.
         */
        UUID rapportAttemptId
) {
}
