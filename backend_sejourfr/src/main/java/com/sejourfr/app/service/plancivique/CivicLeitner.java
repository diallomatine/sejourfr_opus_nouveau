package com.sejourfr.app.service.plancivique;

import java.time.Duration;
import java.time.Instant;

/**
 * La <b>répétition espacée</b> du module civique — 5 boîtes ({@code 20_} §5.1,
 * arbitrage A11).
 *
 * <p>🛑 <b>Pure, et sans état.</b> Aucune boîte n'est persistée : elle se
 * <b>replie</b> sur l'historique des réponses ({@link CivicLeitnerResolver}).
 * C'est la doctrine du dépôt (« un dérivé se relit, il ne se persiste pas »),
 * et ici elle rapporte deux choses qu'une table n'aurait pas données :
 *
 * <ul>
 *   <li><b>le tagging rétroactif</b> — le jour où une question reçoit sa notion,
 *       <i>toutes</i> les réponses déjà données comptent pour elle. Une boîte
 *       persistée serait née vide et le serait restée : au lancement,
 *       0 question sur 1 016 est taguée ;</li>
 *   <li><b>aucun job quotidien</b> — {@code 20_} §5.4 en prévoit un pour les
 *       échéances franchies. Une échéance calculée à la lecture est franchie
 *       toute seule.</li>
 * </ul>
 */
public final class CivicLeitner {

    private CivicLeitner() {
    }

    /** La première boîte : ce qui vient d'être raté revient tout de suite. */
    public static final int PREMIERE = 1;

    /** La dernière. Au-delà, on ne repousse plus. */
    public static final int DERNIERE = 5;

    /**
     * L'attente avant nouvelle présentation, par boîte ({@code 20_} §5.1).
     *
     * <p>Index 0 inutilisé : les boîtes se comptent de 1 à 5, comme la spec les
     * nomme — renuméroter à 0 rendrait chaque lecture ambiguë.
     */
    private static final int[] JOURS = {0, 0, 1, 3, 7, 21};

    /** La boîte après une réponse. 🛑 Une erreur renvoie en boîte 1, toujours. */
    public static int suivante(int boite, boolean correcte) {
        if (!correcte) return PREMIERE;
        return Math.min(borne(boite) + 1, DERNIERE);
    }

    /** Le délai avant nouvelle présentation. Boîte 1 ⇒ immédiat. */
    public static Duration attente(int boite) {
        return Duration.ofDays(JOURS[borne(boite)]);
    }

    /**
     * Quand cette cible redevient à revoir.
     *
     * <p>{@code null} si elle n'a jamais été vue : rien à repousser. La borne
     * est calculée depuis la <b>dernière présentation</b>, pas depuis la
     * première — c'est la réponse la plus récente qui fait foi.
     */
    public static Instant echeance(Instant derniereVue, int boite) {
        return derniereVue == null ? null : derniereVue.plus(attente(boite));
    }

    /** L'échéance est-elle franchie ? Jamais vue ⇒ <b>non</b> : elle n'est pas en retard. */
    public static boolean echeanceDepassee(Instant derniereVue, int boite, Instant maintenant) {
        Instant echeance = echeance(derniereVue, boite);
        return echeance != null && !echeance.isAfter(maintenant);
    }

    /** Garde-fou de lecture : une boîte hors bornes ne doit jamais lever. */
    private static int borne(int boite) {
        return Math.min(Math.max(boite, PREMIERE), DERNIERE);
    }
}
