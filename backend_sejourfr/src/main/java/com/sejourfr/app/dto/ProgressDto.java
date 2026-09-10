package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.NiveauEvolution;
import com.sejourfr.app.enums.SkillSection;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * <b>Progrès</b> (T28, {@code 30_} §7) — « montrer le MOUVEMENT, pas un tableau
 * de bord ».
 *
 * <h2>Ce que ce DTO refuse de servir</h2>
 * <ul>
 *   <li>🛑 <b>Aucun pourcentage de progression vers un niveau</b> ({@code 30_}
 *       §7, règle explicite). Un palier CECRL n'est pas une barre : « 68 % vers
 *       le B2 » n'a aucun sens mesurable et se lit pourtant comme une
 *       promesse. On sert des <b>paliers</b> et des <b>sens d'évolution</b>.</li>
 *   <li>🛑 <b>Aucune série de flammes, aucune gamification</b> ({@code 30_} §7).
 *       L'activité se dit en <b>jours travaillés</b> et en semaines, sans
 *       record à battre et sans rien à « perdre ». Le streak existe déjà sur le
 *       tableau de bord ; le ramener ici en ferait un enjeu.</li>
 *   <li>🛑 <b>Aucune liste d'historique</b>. Le bloc 5 de la spec (« productions
 *       et rapports, consultables à vie ») est <b>déjà</b> servi par les écrans
 *       d'historique existants : le redupliquer ici créerait une seconde
 *       vérité. On sert de quoi <b>ouvrir</b> l'existant, rien de plus.</li>
 * </ul>
 *
 * <h2>Freemium</h2>
 * <p>🛑 <b>Le verrou porte sur les COMPÉTENCES, pas sur les paliers</b>
 * ({@code 30_} §7 : « blocs 1 et 2 visibles, 3 et 5 verrouillés »). Un candidat
 * gratuit voit toujours où il en est ; ce qu'il n'a pas, c'est le détail de ce
 * qu'il a acquis. Le {@code locked} est servi, jamais déduit d'un rang.
 *
 * @param activite  <b>transverse</b>, et volontairement : les jours de travail
 *                  ne se répartissent pas par module — une séance civique et une
 *                  production TCF sont le même effort du même jour
 */
public record ProgressDto(
        Activite activite,
        Tcf tcf,
        Civique civique
) {

    /**
     * L'activité récente. Des <b>faits</b> : des jours, des semaines.
     *
     * <p>🛑 Ni flamme, ni record, ni objectif hebdomadaire. La spec l'interdit
     * en toutes lettres, et un compteur qu'on peut « casser » transforme une
     * mesure en dette.
     *
     * @param joursActifs  jours travaillés sur la fenêtre
     * @param fenetreJours la fenêtre elle-même (30), servie pour que l'écran le
     *                     DISE sans le connaître
     * @param semaines     de la plus ancienne à la plus récente
     */
    public record Activite(int joursActifs, int fenetreJours, List<Semaine> semaines) {
    }

    /** Une semaine de la fenêtre. {@code jours} vaut 0 à 7. */
    public record Semaine(LocalDate debut, int jours) {
    }

    /**
     * Le mouvement côté <b>TCF</b>.
     *
     * @param disponible    {@code false} tant qu'aucun diagnostic n'est clos —
     *                      l'écran ouvre alors la seule porte qui débloque, il
     *                      n'affiche pas des blocs vides
     * @param niveauActuel  le niveau TCF <b>estimé</b>, plancher des épreuves
     *                      réellement passées. 🛑 {@code null} = inconnu, jamais
     *                      « &lt; A1 »
     * @param objectif      le palier visé, ou {@code null} si aucune démarche
     *                      n'est déclarée — on ne devine jamais à la place du
     *                      candidat
     * @param historique    les diagnostics clos, du <b>plus ancien au plus
     *                      récent</b>. 🛑 Une courbe ne se dessine qu'à partir de
     *                      deux points : c'est au front de ne rien tracer avec
     *                      un seul, et le DTO lui sert la liste telle quelle
     * @param epreuves      les 4 épreuves, <b>toutes</b>, évaluées ou non
     * @param competences   bloc 3. 🛑 Verrouillé pour un compte gratuit
     */
    public record Tcf(
            boolean disponible,
            NiveauCecrl niveauActuel,
            NiveauCecrl objectif,
            List<Estimation> historique,
            List<Epreuve> epreuves,
            Competences competences
    ) {
    }

    /** Un point de l'historique des estimations. */
    public record Estimation(UUID sessionId, NiveauCecrl niveau, Instant mesureA) {
    }

    /**
     * Une épreuve, son palier d'aujourd'hui et ce qui a bougé.
     *
     * @param niveau        le palier <b>actuel</b> (meilleur résultat, toutes
     *                      sources). {@code null} = jamais évaluée
     * @param niveauInitial le palier au <b>premier</b> diagnostic clos
     * @param evolution     🛑 {@code INCONNUE} n'est <b>pas</b> {@code STABLE} :
     *                      une épreuve non évaluée d'un côté n'a ni progressé ni
     *                      tenu. Et {@code BAISSE} existe et se sert
     */
    public record Epreuve(
            EpreuveType epreuve,
            NiveauCecrl niveau,
            NiveauCecrl niveauInitial,
            NiveauEvolution evolution
    ) {
    }

    /**
     * Bloc 3 — « 4 compétences maîtrisées sur 11 travaillées ».
     *
     * <p>🛑 <b>Les compteurs sont servis même verrouillés.</b> C'est le
     * <b>détail</b> qui est premium, pas le fait d'avoir progressé : cacher le
     * nombre reviendrait à cacher au candidat ce qu'il a lui-même produit.
     *
     * @param travaillees  compétences sur lesquelles au moins une observation
     *                     existe
     * @param maitrisees   dont l'état agrégé est solide
     * @param dernieres    les plus récemment tenues, avec la date de la preuve.
     *                     Vide quand {@code locked}
     * @param locked       le détail est-il réservé ?
     */
    public record Competences(
            int travaillees,
            int maitrisees,
            List<CompetenceAcquise> dernieres,
            boolean locked
    ) {
    }

    /**
     * Une compétence tenue.
     *
     * @param preuveA la date de la <b>dernière observation solide</b>, et c'est
     *                ainsi qu'il faut la dire. 🛑 Ce n'est <b>pas</b> une « date
     *                d'acquisition » : le moteur agrège plusieurs observations,
     *                aucune ne marque un instant d'acquisition
     */
    public record CompetenceAcquise(
            UUID skillId,
            String code,
            String titre,
            SkillSection section,
            Instant preuveA
    ) {
    }

    /**
     * Le mouvement côté <b>civique</b>.
     *
     * <p>🛑 <b>Aucune métrique CECRL ici</b> ({@code 20_} §12) : le civique se
     * mesure en points sur 40 et en notions tenues, jamais en paliers.
     *
     * @param disponible   {@code false} tant qu'aucun diagnostic civique n'est
     *                     clos
     * @param historique   les diagnostics clos, du plus ancien au plus récent
     * @param travaillees  cibles sur lesquelles au moins une réponse existe
     * @param maitrisees   dont l'état servi est « maîtrisée »
     * @param grainNotion  le plan travaille-t-il déjà par notion ? L'écran doit
     *                     pouvoir nommer ce qu'il compte
     */
    public record Civique(
            boolean disponible,
            List<Score> historique,
            int travaillees,
            int maitrisees,
            boolean grainNotion
    ) {
    }

    /**
     * Un résultat civique, directement comparable au seuil.
     *
     * @param seuil  32, la règle de l'épreuve — servi pour que l'écran le DISE
     * @param format 40, le format de l'épreuve
     */
    public record Score(
            UUID sessionId,
            int bonnes,
            int posees,
            int seuil,
            int format,
            Instant mesureA
    ) {
    }
}
