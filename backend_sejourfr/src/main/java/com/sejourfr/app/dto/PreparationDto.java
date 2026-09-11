package com.sejourfr.app.dto;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PreparationEtape;

import java.util.UUID;

/**
 * <b>Ou en sont les deux preparations</b> — l'etat unique que l'Accueil, le
 * Plan et les Examens lisent tous les trois.
 *
 * <p>🛑 <b>Trois portes, un seul etat.</b> L'Accueil montre la prochaine
 * action, le Plan explique pourquoi il n'est pas encore pret, les Examens
 * gardent le diagnostic a cote des examens blancs. Les trois ecrans ne creent
 * pas trois parcours : ils rendent le meme fait, servi ici (arbitrage du
 * proprietaire, 2026-09-10).
 *
 * <p>🛑 <b>Le serveur expose des FAITS.</b> Les phrases (« Premiere estimation
 * terminee », « Votre plan civique commence par un diagnostic ») appartiennent
 * aux fronts, comme partout ailleurs dans ce depot.
 */
public record PreparationDto(
        ModulePreparation tcf,
        ModulePreparation civique
) {
    /**
     * L'etat d'un module.
     *
     * @param etape      ou en est la preparation. C'est LE fait
     * @param fait       avancement, quand il y en a un (2 epreuves, 14
     *                   questions). {@code null} si la notion n'a pas de sens a
     *                   cette etape.
     *                   <b>TCF</b> : ce sont les epreuves du diagnostic
     *                   <b>COMPLET</b>, et elles sont servies <b>des que le
     *                   Plan existe</b> — {@code 0 / 4} quand le complet n'a
     *                   jamais demarre. Ce n'est pas un decor : la carte
     *                   « affiner mon Plan » se lit sur ce compte, et un front
     *                   qui inventerait le denominateur « 4 » finirait par
     *                   l'afficher faux le jour ou le diagnostic changera de
     *                   forme
     * @param total      le denominateur du meme avancement
     * @param sessionId  le diagnostic a reprendre ou a relire. {@code null} si
     *                   aucun n'a ete ouvert
     * @param niveau     <b>TCF</b> : le palier mesure. 🛑 {@code null} =
     *                   <b>pas encore mesure</b>, jamais A1
     * @param cible      <b>TCF</b> : le palier vise, plancher de la demarche
     *                   applique
     * @param aRenforcer <b>CIVIQUE</b> : combien de themes sont a renforcer ou
     *                   faibles. 🛑 {@code null} tant qu'aucun diagnostic n'est
     *                   clos — {@code 0} voudrait dire « tout est solide »
     * @param estimationSessionId <b>TCF</b> : la session du diagnostic
     *                   <b>RAPIDE</b> deja clos, s'il y en a une.
     *                   🛑 <b>Servie a TOUTES les etapes</b>, independamment de
     *                   {@code etape} et de {@code sessionId} : des que le
     *                   diagnostic complet est ouvert, {@code sessionId}
     *                   designe le complet, et le rapport du rapide — le seul
     *                   resultat que le candidat possede alors — devenait
     *                   introuvable pour les fronts. Champ <b>nomme
     *                   distinctement</b> plutot qu'un {@code sessionId}
     *                   surcharge : deux sens sur un meme champ finissent
     *                   toujours par se contredire. {@code null} = aucun
     *                   diagnostic rapide clos, donc rien a relire
     * @param planDisponible 🛑 <b>Le Plan du module est-il constructible
     *                   MAINTENANT ?</b> C'est le seul fait sur lequel un front
     *                   a le droit d'ouvrir la page Plan.
     *                   <p><b>Arbitrage du proprietaire, 2026-09-12</b> : le
     *                   diagnostic complet <b>n'est plus un prerequis</b>
     *                   d'acces au Plan, seulement un moyen de le rendre plus
     *                   precis. Des que le diagnostic rapide est clos, le Plan
     *                   existe — provisoire mais reel, bati <b>uniquement</b>
     *                   sur ce que le rapide a mesure.
     *                   <p>🛑 <b>Il ne se deduit pas de {@code etape}.</b> Il
     *                   rend, mot pour mot, la condition de
     *                   {@code LearningPlanService.get()} / {@code
     *                   CivicPlanService} : deux lectures de « le Plan
     *                   existe-t-il ? » auraient fini par se contredire, un
     *                   ecran promettant un plan que le moteur refuse de
     *                   construire
     * @param prochaineEpreuve <b>TCF</b> : la prochaine epreuve du diagnostic
     *                   <b>COMPLET</b>, celle par laquelle « Continuer le
     *                   diagnostic » reprend. 🛑 {@code null} quand il n'y a
     *                   rien a reprendre — complet jamais demarre (il n'a pas
     *                   encore d'epreuves tirees, et en promettre une serait
     *                   l'inventer) ou complet termine. Un front ne la deduit
     *                   jamais d'un compteur : l'ordre des epreuves est une
     *                   donnee serveur ({@code TcfDiagnosticReadService.EPREUVES})
     */
    public record ModulePreparation(
            PreparationEtape etape,
            Integer fait,
            Integer total,
            UUID sessionId,
            NiveauCecrl niveau,
            NiveauCecrl cible,
            Integer aRenforcer,
            UUID estimationSessionId,
            boolean planDisponible,
            EpreuveType prochaineEpreuve
    ) {}
}
