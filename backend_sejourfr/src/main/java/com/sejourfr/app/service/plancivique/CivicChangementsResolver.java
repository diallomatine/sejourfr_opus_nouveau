package com.sejourfr.app.service.plancivique;

import com.sejourfr.app.dto.CivicPlanDto;
import com.sejourfr.app.enums.PlanRecentChangesWindow;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Ce qui a bouge depuis peu</b> dans le plan civique — le bloc « Progression
 * detectee », pendant de {@code PlanRecentChangesResolver} cote TCF.
 *
 * <h2>Pourquoi rien n'est persiste</h2>
 *
 * <p>🛑 Le module civique ne stocke aucun etat ({@link CivicLeitnerResolver}) :
 * la boite et la maitrise se <b>replient</b> sur l'historique a chaque lecture.
 * Un bloc « ce qui a change » aurait pu justifier une table de snapshots — on ne
 * l'a pas prise, et c'est deliberé : elle serait nee vide, elle aurait fige un
 * etat calcule avec le referentiel du jour, et elle aurait casse la
 * <b>retroactivite du tagging</b> (le jour ou une question recoit sa notion, les
 * reponses deja donnees comptent pour elle).
 *
 * <p>L'etat d'il y a une semaine se <b>rejoue</b> donc exactement comme l'etat
 * courant : mêmes reponses, tronquees au debut de la fenetre, meme resolveur.
 *
 * <h2>Ce qui fait un changement, et ce qui n'en fait pas</h2>
 *
 * <ul>
 *   <li>🛑 <b>Le temps seul n'est pas un changement.</b> Sans reponse nouvelle
 *       dans la fenetre, une cible est ignoree — sinon une echeance Leitner qui
 *       se franchit toute seule s'annoncerait comme une progression.</li>
 *   <li>🛑 <b>Le rabat au grain THEME s'applique aux DEUX bouts.</b> Sans lui,
 *       on annoncerait « passe a Maitrise » sur un theme, palier que le plan
 *       lui-meme refuse ({@link CivicMaitrise#rabattueAuGrainTheme()}).</li>
 *   <li>Une <b>baisse</b> est une transition comme une autre : elle est servie,
 *       avec {@code progres = false}. Le plan dit ce qui s'est passe, il ne
 *       raconte pas que des bonnes nouvelles.</li>
 * </ul>
 */
@Component
public class CivicChangementsResolver {

    private final CivicLeitnerResolver leitnerResolver;

    public CivicChangementsResolver(CivicLeitnerResolver leitnerResolver) {
        this.leitnerResolver = leitnerResolver;
    }

    /**
     * Les changements, sur la <b>plus courte</b> fenetre qui contienne quelque
     * chose de reel. {@link Optional#empty()} quand rien n'a bouge — le cas
     * normal, et de loin le plus frequent.
     *
     * @param cibles           les cibles du plan, deja construites et deja
     *                         rabattues : on lit leur etat courant, on ne le
     *                         recalcule pas
     * @param reponsesParCible les reponses de chaque cible, indexees par son id
     * @param prochaine        la cible de rang 1, ou {@code null}. Elle vient de
     *                         l'ordre du plan, seule autorite : ce bloc ne
     *                         reclasse rien
     * @param fenetreErreurs   la fenetre du score, passee au resolveur pour que
     *                         le rejeu soit strictement le meme
     * @param maintenant       l'instant de lecture
     */
    public Optional<CivicPlanDto.Changements> resoudre(
            List<CivicPlanDto.Cible> cibles,
            Map<UUID, List<CivicReponse>> reponsesParCible,
            CivicPlanDto.Cible prochaine,
            Duration fenetreErreurs,
            Instant maintenant) {

        if (cibles == null || cibles.isEmpty()) return Optional.empty();

        for (PlanRecentChangesWindow fenetre : PlanRecentChangesWindow.values()) {
            Instant depuis = maintenant.minus(Duration.ofDays(fenetre.getDays()));
            List<CivicPlanDto.Transition> transitions =
                    transitions(cibles, reponsesParCible, fenetreErreurs, depuis);
            CivicPlanDto.CibleRef nouvelle =
                    nouvellePriorite(prochaine, reponsesParCible, depuis);
            if (transitions.isEmpty() && nouvelle == null) continue;
            return Optional.of(new CivicPlanDto.Changements(
                    fenetre, depuis, transitions, nouvelle));
        }
        return Optional.empty();
    }

    private List<CivicPlanDto.Transition> transitions(
            List<CivicPlanDto.Cible> cibles,
            Map<UUID, List<CivicReponse>> reponsesParCible,
            Duration fenetreErreurs,
            Instant depuis) {

        List<CivicPlanDto.Transition> out = new ArrayList<>();
        for (CivicPlanDto.Cible cible : cibles) {
            List<CivicReponse> toutes =
                    reponsesParCible.getOrDefault(cible.id(), List.of());

            // 🛑 Aucune preuve nouvelle : le temps seul ne fait pas un changement.
            Instant derniere = derniereReponseDansLaFenetre(toutes, depuis);
            if (derniere == null) continue;

            List<CivicReponse> avantLaFenetre = toutes.stream()
                    .filter(r -> r.repondueA() != null && !r.repondueA().isAfter(depuis))
                    .toList();

            CivicMaitrise avant = leitnerResolver
                    .resoudre(avantLaFenetre, fenetreErreurs, depuis)
                    .maitrise();
            // Le rabat s'applique des DEUX cotes, sinon on annoncerait une
            // transition vers un palier que le plan refuse au grain theme.
            if (cible.grain() == CivicPlanGrain.THEME) {
                avant = avant.rabattueAuGrainTheme();
            }

            CivicMaitrise apres = cible.maitrise();
            if (avant == apres) continue;

            out.add(new CivicPlanDto.Transition(
                    cible.id(), cible.code(), cible.label(), cible.grain(),
                    avant, apres, avant.progresseVers(apres), derniere));
        }

        // De la plus recemment travaillee a la plus ancienne : ce que le
        // candidat vient de faire se lit en premier.
        out.sort(Comparator.comparing(
                CivicPlanDto.Transition::observeeA,
                Comparator.nullsLast(Comparator.reverseOrder())));
        return List.copyOf(out);
    }

    /**
     * La priorite n&deg;1 <b>seulement si elle vient d'etre travaillee</b> : une
     * cible en tete depuis trois semaines n'est pas une nouvelle.
     */
    private CivicPlanDto.CibleRef nouvellePriorite(
            CivicPlanDto.Cible prochaine,
            Map<UUID, List<CivicReponse>> reponsesParCible,
            Instant depuis) {

        if (prochaine == null) return null;
        List<CivicReponse> siennes =
                reponsesParCible.getOrDefault(prochaine.id(), List.of());
        if (derniereReponseDansLaFenetre(siennes, depuis) == null) return null;
        return new CivicPlanDto.CibleRef(
                prochaine.id(), prochaine.code(), prochaine.label(), prochaine.grain());
    }

    private static Instant derniereReponseDansLaFenetre(
            List<CivicReponse> reponses, Instant depuis) {
        return reponses.stream()
                .map(CivicReponse::repondueA)
                .filter(java.util.Objects::nonNull)
                .filter(instant -> instant.isAfter(depuis))
                .max(Comparator.naturalOrder())
                .orElse(null);
    }
}
