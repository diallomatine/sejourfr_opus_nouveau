package com.sejourfr.app.service.plancivique;

import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;

/**
 * Le <b>repli</b> de l'historique d'une cible sur son état Leitner.
 *
 * <p>🛑 <b>C'est un dérivé, pas un état.</b> Rien n'est écrit : on rejoue les
 * réponses dans l'ordre et la boîte tombe. Trois conséquences qui valent la
 * relecture d'un historique à chaque lecture :
 *
 * <ul>
 *   <li>🛑 <b>Le tagging est rétroactif.</b> Le jour où une question reçoit sa
 *       notion, les réponses déjà données comptent pour elle. Au lancement de ce
 *       lot, 0 question sur 1 016 est taguée : une table de progression serait
 *       née vide et le serait restée pour tout l'historique.</li>
 *   <li>🛑 <b>Recalibrer ne demande aucune migration</b> — changer un intervalle
 *       relit tout l'historique au prochain appel.</li>
 *   <li>Aucun job quotidien : une échéance calculée à la lecture se franchit
 *       toute seule ({@code 20_} §5.4 en prévoyait un).</li>
 * </ul>
 *
 * <p>🛑 <b>L'ordre fait la boîte.</b> On trie sur l'instant de réponse, et non
 * sur l'ordre de la requête : deux réponses inversées donnent deux boîtes
 * différentes, et un {@code ORDER BY} oublié se verrait comme un plan qui
 * change sans raison.
 */
@Component
public class CivicLeitnerResolver {

    /**
     * L'état d'une cible d'après ses réponses.
     *
     * @param reponses        les réponses de CETTE cible, dans n'importe quel ordre
     * @param fenetreErreurs  la fenêtre sur laquelle {@code erreursRecentes} est
     *                        comptée ({@code 20_} §5.3 : 30 jours)
     * @param maintenant      l'instant de lecture — passé, jamais lu d'une
     *                        horloge cachée : c'est ce qui rend le repli
     *                        reproductible en test
     */
    public CivicEtatCible resoudre(
            List<CivicReponse> reponses, Duration fenetreErreurs, Instant maintenant) {
        if (reponses == null || reponses.isEmpty()) {
            return CivicEtatCible.vierge();
        }

        List<CivicReponse> ordonnees = reponses.stream()
                .sorted(Comparator.comparing(
                        CivicReponse::repondueA,
                        Comparator.nullsFirst(Comparator.naturalOrder())))
                .toList();

        int boite = CivicLeitner.PREMIERE;
        int correctes = 0;
        int consecutives = 0;
        Instant derniereVue = null;
        Instant derniereErreur = null;

        for (CivicReponse reponse : ordonnees) {
            boite = CivicLeitner.suivante(boite, reponse.correcte());
            if (reponse.correcte()) {
                correctes++;
                consecutives++;
            } else {
                consecutives = 0;
                derniereErreur = reponse.repondueA();
            }
            derniereVue = reponse.repondueA();
        }

        Instant debutFenetre = maintenant.minus(fenetreErreurs);
        int erreursRecentes = (int) ordonnees.stream()
                .filter(r -> !r.correcte())
                .filter(r -> r.repondueA() != null && r.repondueA().isAfter(debutFenetre))
                .count();

        boolean derniereCorrecte = ordonnees.getLast().correcte();
        return new CivicEtatCible(
                boite,
                ordonnees.size(),
                correctes,
                consecutives,
                derniereVue,
                derniereErreur,
                erreursRecentes,
                CivicLeitner.echeance(derniereVue, boite),
                CivicMaitrise.of(ordonnees.size(), boite, derniereCorrecte));
    }
}
