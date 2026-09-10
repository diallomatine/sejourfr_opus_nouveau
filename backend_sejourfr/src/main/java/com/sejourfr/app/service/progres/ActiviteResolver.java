package com.sejourfr.app.service.progres;

import com.sejourfr.app.dto.ProgressDto;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * L'activité récente, repliée sur les <b>jours travaillés</b> ({@code 30_} §7
 * bloc 4).
 *
 * <p>🛑 <b>Pas de flamme, pas de record, pas d'objectif hebdomadaire.</b> La
 * spec l'interdit en toutes lettres (« pas de série de flammes, pas de
 * gamification agressive »), et la raison tient en une phrase : un compteur
 * qu'on peut <b>casser</b> transforme une mesure en dette. Le streak existe
 * déjà sur le tableau de bord, où il est une information ; le ramener ici en
 * ferait un enjeu.
 *
 * <p>🛑 <b>Pur</b>, et {@code aujourdHui} est <b>passé</b> — jamais lu d'une
 * horloge cachée : c'est ce qui rend le repli reproductible en test.
 */
@Component
public class ActiviteResolver {

    private static final int JOURS_PAR_SEMAINE = 7;

    /** Semaines de la frise. */
    private static final int SEMAINES = 4;

    /**
     * La fenêtre du bloc 4 — <b>28 jours</b>, soit quatre semaines pleines.
     *
     * <p>⚠️ {@code 30_} §7 écrit « sur 30 jours ». On sert 28, délibérément :
     * 30 jours ne font pas un nombre entier de semaines, et une frise de quatre
     * semaines dont la somme <b>ne vaut pas</b> le compteur affiché au-dessus
     * est un défaut bien pire qu'un ordre de grandeur arrondi. Les deux derniers
     * jours seraient tombés hors de la frise tout en comptant dans le total.
     *
     * <p>🛑 La fenêtre est <b>servie</b> ({@code fenetreJours}) : aucun écran
     * n'écrit « 30 » en dur, donc aucun ne peut mentir sur ce qu'il compte.
     */
    public static final int FENETRE_JOURS = SEMAINES * JOURS_PAR_SEMAINE;

    /**
     * @param joursActifs les dates d'activité distinctes, dans n'importe quel
     *                    ordre. Hors fenêtre, elles sont simplement ignorées
     */
    public ProgressDto.Activite resoudre(Collection<LocalDate> joursActifs, LocalDate aujourdHui) {
        LocalDate debut = aujourdHui.minusDays(FENETRE_JOURS - 1L);
        Set<LocalDate> dansLaFenetre = new HashSet<>();
        if (joursActifs != null) {
            for (LocalDate jour : joursActifs) {
                if (jour == null) continue;
                if (jour.isBefore(debut) || jour.isAfter(aujourdHui)) continue;
                dansLaFenetre.add(jour);
            }
        }

        // Les semaines vont de la plus ANCIENNE a la plus recente : c'est le
        // sens de lecture d'une frise, et l'ecran ne doit pas avoir a la
        // retourner.
        List<ProgressDto.Semaine> semaines = new ArrayList<>();
        for (int i = 0; i < SEMAINES; i++) {
            LocalDate debutSemaine = debut.plusDays((long) i * JOURS_PAR_SEMAINE);
            LocalDate finSemaine = debutSemaine.plusDays(JOURS_PAR_SEMAINE - 1L);
            int jours = (int) dansLaFenetre.stream()
                    .filter(j -> !j.isBefore(debutSemaine) && !j.isAfter(finSemaine))
                    .count();
            semaines.add(new ProgressDto.Semaine(debutSemaine, jours));
        }

        return new ProgressDto.Activite(dansLaFenetre.size(), FENETRE_JOURS, semaines);
    }
}
