package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.ObservationConfidence;
import com.sejourfr.app.enums.PlanActionNature;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.service.plan.PlanConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * <b>L'ordre du pool d'actions, et la composition de la journee.</b>
 *
 * <p>Le Plan calcule desormais <b>toutes</b> les actions vraies avant de couper
 * quoi que ce soit. Ce composant repond aux deux questions qui suivent :
 * <b>dans quel ordre</b>, et <b>qu'est-ce qui a le droit d'entrer dans une
 * seance</b>.
 *
 * <h2>🛑 Aucun poids n'est ecrit ici</h2>
 * Tous viennent de {@code plan-config-vN.json}. Un poids en dur aurait
 * transforme chaque reglage produit en deploiement, et rendu impossible de
 * savoir quel classement a produit un ecran donne.
 *
 * <h2>Pas d'horloge, donc pas de « recence » ponderee</h2>
 * Le Plan ne lit jamais l'heure courante — c'est ce qui rend la stickiness de la
 * seance gratuite ({@code PlanSeanceBuilder}, § « Pourquoi il n'y a ni table, ni
 * colonne, ni graine »). La recence ne peut donc pas etre un <b>poids</b> : elle
 * reste un <b>departage</b>, sur la date d'observation deja portee par
 * l'historique. Deux lectures sans action du candidat rendent le meme ordre.
 *
 * <h2>La premiere place est epinglee, jamais recalculee</h2>
 * {@code PlanFocusResolver} decide quelle competence occupe la premiere place —
 * et {@code SkillAccessService} en tire la competence ouverte d'office a un
 * compte gratuit. Si le classement pouvait la deplacer, un compte gratuit
 * verrait son etape n&deg;1 <b>cadenassee</b> : exactement ce que cette
 * ouverture existe pour eviter. Elle est donc <b>epinglee en tete</b>, et le
 * classement ordonne tout le reste.
 */
@Component
@RequiredArgsConstructor
public class PlanActionRanker {

    private final PlanConfig config;

    /**
     * Une action du pool, reduite a ce qui sert a la classer.
     *
     * @param skillId    la competence
     * @param skillCode  son code, <b>departage ultime</b> : deux lectures
     *                   rendent le meme ordre, jamais un ordre d'insertion
     * @param section    son domaine — c'est lui qui porte l'urgence et l'ecart
     * @param nature     ce que le Plan demande dessus
     * @param confidence la confiance de l'observation, {@code null} sur une
     *                   acquisition : rien n'a ete constate, il n'y a aucune
     *                   confiance a lire
     * @param observedAt la date de l'observation, {@code null} sur une
     *                   acquisition
     */
    public record Action(
            UUID skillId,
            String skillCode,
            SkillSection section,
            PlanActionNature nature,
            ObservationConfidence confidence,
            Instant observedAt) {}

    /**
     * Le pool classe, puis compose : les {@code display.todayMaxActions}
     * premieres lignes respectent le plafond de domaines secondaires, le reste
     * garde l'ordre du classement.
     *
     * @param pool          toutes les actions vraies, sans plafond
     * @param domaines      les quatre domaines resolus, par section : ils
     *                      portent l'urgence <b>deja decidee par le serveur</b>
     *                      et le niveau du domaine. On ne recalcule aucune
     *                      urgence ici.
     * @param objectif      le palier vise, pour l'ecart au domaine
     * @param focusSkillId  la premiere place, telle que {@code PlanFocusResolver}
     *                      l'a designee ; {@code null} quand il n'y en a pas
     */
    public List<Action> classer(
            List<Action> pool,
            Map<SkillSection, PlanDomainDto> domaines,
            TargetLevel objectif,
            UUID focusSkillId) {
        if (pool == null || pool.isEmpty()) return List.of();
        List<Action> classe = new ArrayList<>(pool);
        classe.sort(Comparator
                .comparingInt((Action action) -> action.skillId().equals(focusSkillId) ? 0 : 1)
                .thenComparingInt(action -> -score(action, domaines, objectif))
                .thenComparing(Action::observedAt,
                        Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(Action::skillCode,
                        Comparator.nullsLast(Comparator.naturalOrder())));
        return composer(classe, domaines);
    }

    /**
     * Le score d'une action : additif, entier, entierement lu en configuration.
     *
     * <p>Quatre termes, dans l'ordre de leur poids : <b>ce qu'on fait</b>
     * (mesurer, reparer, verifier, apprendre), <b>l'urgence du domaine</b>,
     * <b>l'ecart au palier vise</b>, et <b>la confiance</b> de ce qu'on a
     * observe.
     */
    private int score(Action action, Map<SkillSection, PlanDomainDto> domaines,
                      TargetLevel objectif) {
        PlanConfig.Ranking poids = config.ranking();
        PlanDomainDto domaine = domaines == null ? null : domaines.get(action.section());
        PlanDomainPriority urgence = domaine == null || domaine.priority() == null
                ? PlanDomainPriority.A_EVALUER : domaine.priority();
        int total = poids.natureWeights().getOrDefault(action.nature(), 0)
                + poids.domainPriorityWeights().getOrDefault(urgence, 0)
                + poids.levelGapWeight() * ecart(domaine, objectif);
        if (action.confidence() != null) {
            total += poids.confidenceWeights().getOrDefault(action.confidence(), 0);
        }
        return total;
    }

    /**
     * Combien de crans separent ce domaine de l'objectif. Un domaine jamais
     * mesure vaut <b>zero</b> : son niveau est inconnu, et <i>null = inconnu,
     * jamais mauvais</i> — on ne lui fabrique pas une urgence a partir d'une
     * absence de mesure.
     */
    private static int ecart(PlanDomainDto domaine, TargetLevel objectif) {
        if (domaine == null || domaine.niveau() == null || objectif == null) return 0;
        int vise = NiveauCecrl.valueOf(objectif.name()).ordinal();
        return Math.max(0, vise - domaine.niveau().ordinal());
    }

    /**
     * <b>Regle dure de composition</b> : au plus
     * {@code display.todayMaxSecondaryDomainActions} action(s) de domaine
     * <b>secondaire</b> parmi les {@code display.todayMaxActions} premieres.
     *
     * <p>Sans elle, un pool de vingt actions ferait d'« Aujourd'hui » une liste
     * de courses a quatre epreuves — et on perdrait exactement ce que la
     * doctrine « un palier a la fois » protegeait : la coherence pedagogique.
     *
     * <p>🛑 C'est un <b>maximum</b>, pas un minimum : si le classement ne place
     * aucun domaine secondaire en tete, la seance reste sur un seul domaine, et
     * c'est legitime. On ne force pas de la diversite pour faire joli.
     *
     * <p>Les actions repoussees ne sont pas perdues : elles gardent leur rang
     * relatif juste apres la fenetre.
     */
    private List<Action> composer(List<Action> classe, Map<SkillSection, PlanDomainDto> domaines) {
        int fenetre = config.display().todayMaxActions();
        int plafondSecondaire = config.display().todayMaxSecondaryDomainActions();
        Set<SkillSection> primaires = primaires(classe, domaines);
        List<Action> tete = new ArrayList<>(fenetre);
        List<Action> reste = new ArrayList<>();
        int secondaires = 0;
        for (Action action : classe) {
            if (tete.size() >= fenetre) {
                reste.add(action);
                continue;
            }
            boolean secondaire = !primaires.contains(action.section());
            if (secondaire && secondaires >= plafondSecondaire) {
                reste.add(action);
                continue;
            }
            if (secondaire) secondaires++;
            tete.add(action);
        }
        tete.addAll(reste);
        return List.copyOf(tete);
    }

    /**
     * Les domaines <b>primaires</b> : ceux qui portent l'urgence la plus haute
     * parmi les domaines reellement presents dans le pool. A urgence egale, ils
     * sont primaires ensemble — deux domaines « Priorite forte » ne se
     * departagent pas ici.
     */
    private static Set<SkillSection> primaires(
            List<Action> classe, Map<SkillSection, PlanDomainDto> domaines) {
        Set<SkillSection> presentes = EnumSet.noneOf(SkillSection.class);
        classe.forEach(action -> presentes.add(action.section()));
        int meilleure = Integer.MAX_VALUE;
        for (SkillSection section : presentes) {
            PlanDomainDto domaine = domaines == null ? null : domaines.get(section);
            int rang = domaine == null || domaine.priority() == null
                    ? PlanDomainPriority.values().length : domaine.priority().ordinal();
            meilleure = Math.min(meilleure, rang);
        }
        Set<SkillSection> primaires = EnumSet.noneOf(SkillSection.class);
        for (SkillSection section : presentes) {
            PlanDomainDto domaine = domaines == null ? null : domaines.get(section);
            int rang = domaine == null || domaine.priority() == null
                    ? PlanDomainPriority.values().length : domaine.priority().ordinal();
            if (rang == meilleure) primaires.add(section);
        }
        return primaires;
    }
}
