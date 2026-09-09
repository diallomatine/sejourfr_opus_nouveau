package com.sejourfr.app.service;

import com.sejourfr.app.dto.PlanDomainDto;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.PlanDomainPriority;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.service.ProgressionPlanBridge;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>LE palier qu'un domaine construit</b> — une seule porte d'entree, deux
 * implementations derriere.
 *
 * <h2>Pourquoi ce composant existe</h2>
 * Le Plan lisait le palier a construire sur le niveau <b>global</b>
 * ({@code PlanCycleDto.targetLevel}, plancher des domaines evalues). Consequence
 * mesuree le 2026-08-25 sur un compte reel : un candidat <b>EE A2 / EO B1</b>
 * visant le B2 construisait <b>B1 partout</b>. Ses six competences B2 d'oral
 * n'etaient candidates a rien, l'ecran d'expression orale affichait « rien a
 * travailler », et le domaine le plus avance attendait le plus faible.
 *
 * <p>🛑 <b>Ce n'est pas le §93 qui disait ca.</b> Le §93 interdit de faire
 * <b>redescendre</b> un domaine avance (« ne pas forcer CE a travailler B1 ») —
 * il n'a jamais dit qu'un domaine avance ne recoit <b>rien</b>. C'est
 * l'implementation qui avait durci « pas prioritaire » en « zero action ».
 * L'amendement porte donc sur le §37 et le §39 (le palier se lisait sur le
 * niveau global), pas sur le §93.
 *
 * <h2>Une seule autorite : le pont</h2>
 * Le moteur V4.2 sait deja repondre a cette question — {@code prescriptionLevel}
 * est decrit comme <b>« le seul niveau que le Plan a le droit de proposer »</b>
 * pour un domaine (§19, §20, invariant I15). Ecrire une seconde regle a cote
 * aurait recree le defaut le plus cher du depot : deux autorites qui finissent
 * par designer deux paliers differents.
 *
 * <p>Ce composant <b>appelle</b> donc le pont d'abord, exactement comme
 * {@code PlanCycleResolver} le fait deja pour le palier bloquant de la
 * comprehension, et ne retombe sur la regle simple que lorsqu'il rend
 * {@code empty()}.
 *
 * <p>⚠️ <b>Aujourd'hui le pont rend TOUJOURS {@code empty()} en expression</b> :
 * il est en {@code SHADOW}, et bride a la comprehension. C'est donc le repli qui
 * decide pour EE/EO — et c'est bien la que vit le correctif, puisqu'il lit
 * desormais le niveau <b>du domaine</b>. Deux decisions explicites du
 * proprietaire (2026-08-26) :
 * <ul>
 *   <li>le pont <b>reste en SHADOW</b> : cette porte est une couture, pas une
 *       promotion du moteur ;</li>
 *   <li>l'extension du pont a EE/EO est un <b>chantier separe</b>. Quand elle
 *       arrivera, elle se branchera ici sans toucher au reste du Plan.</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class PlanDomainTargetLevelResolver {

    /** Les paliers, du plus bas au plus haut : l'ordre <b>est</b> la regle. */
    private static final List<TargetLevel> PALIERS =
            List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);

    private final ProgressionPlanBridge bridge;

    /**
     * Le palier que ce domaine construit, ou {@code null} quand il n'y a rien a
     * construire — domaine jamais mesure, ou objectif <b>deja atteint
     * localement</b>. {@code null} n'est pas un defaut : c'est « ce domaine n'a
     * plus de palier a apprendre », et le Plan l'entretient au lieu de le faire
     * redescendre (§17, §93).
     *
     * @param userId      le candidat, pour interroger le pont ; {@code null}
     *                    passe directement au repli
     * @param section     le domaine
     * @param niveau      le niveau <b>mesure de ce domaine</b>
     *                    ({@code TcfProfileService}, autorite unique) —
     *                    <b>jamais</b> le niveau global
     * @param objectif    le palier vise par le candidat
     *                    ({@code TargetProcedure.niveauVise}) ; {@code null}
     *                    quand il n'a rien declare, et on ne devine pas a sa
     *                    place
     */
    public TargetLevel pour(UUID userId, SkillSection section,
                            NiveauCecrl niveau, TargetLevel objectif) {
        if (section == null || objectif == null) return null;
        return bridge.prescriptionLevel(userId, section, objectif)
                .orElseGet(() -> suivant(niveau, objectif));
    }

    /**
     * Le repli : <b>le premier cran strictement au-dessus du niveau DU
     * DOMAINE</b>, plafonne par l'objectif.
     *
     * <p>🛑 Cette table est de la <b>doctrine pedagogique deterministe</b>, pas
     * un reglage : elle ne va pas dans {@code plan-config}
     * (arbitrage du proprietaire, 2026-08-26). On ne saute jamais un palier
     * (A2 &rarr; B2 directement est interdit) et on ne propose jamais plus haut
     * que ce dont le candidat a besoin.
     *
     * <ul>
     *   <li>niveau inconnu &rarr; {@code A2} : on commence par le bas, on ne
     *       suppose pas un niveau ;</li>
     *   <li>niveau &ge; objectif &rarr; {@code null} : objectif atteint
     *       localement, plus rien a acquerir ici.</li>
     * </ul>
     */
    static TargetLevel suivant(NiveauCecrl niveau, TargetLevel objectif) {
        if (objectif == null) return null;
        if (niveau == null) return TargetLevel.A2.ordinal() <= objectif.ordinal()
                ? TargetLevel.A2 : objectif;
        if (niveau.ordinal() >= niveau(objectif).ordinal()) return null;
        for (TargetLevel palier : PALIERS) {
            if (niveau(palier).ordinal() > niveau.ordinal()) {
                return palier.ordinal() > objectif.ordinal() ? objectif : palier;
            }
        }
        return null;
    }

    /**
     * Le palier de <b>chacun</b> des quatre domaines, resolu <b>une seule
     * fois</b> par lecture du Plan.
     *
     * <p>Trois lecteurs en ont besoin — le selecteur d'acquisitions, la vue
     * par epreuve servie aux fronts, et le classement. Les laisser interroger
     * chacun de leur cote aurait multiplie les appels au pont et, le jour ou il
     * passera en {@code ACTIVE}, ouvert la porte a trois reponses differentes
     * dans la meme reponse HTTP.
     *
     * <p>Un domaine <b>jamais mesure</b> est absent de la table : il se mesure
     * avant de s'apprendre, et {@code domainesAEvaluer} porte deja cette action.
     * Un domaine <b>a l'objectif</b> l'est aussi — il n'a plus de palier a
     * construire.
     */
    public Map<SkillSection, TargetLevel> parSection(
            UUID userId, List<PlanDomainDto> domaines, TargetLevel objectif) {
        Map<SkillSection, TargetLevel> paliers = new EnumMap<>(SkillSection.class);
        if (domaines == null || objectif == null) return paliers;
        for (PlanDomainDto domaine : domaines) {
            if (domaine == null || !domaine.evaluated()
                    || domaine.priority() == PlanDomainPriority.A_EVALUER) {
                continue;
            }
            SkillSection section = PlanCycleResolver.section(domaine.epreuve());
            if (section == null || paliers.containsKey(section)) continue;
            // 🛑 LA COMPREHENSION GARDE SON PALIER BLOQUANT : sa progression est
            // SEQUENTIELLE (A2 solide avant B1), et ce prerequis peut la tenir
            // sous le cran suivant de son niveau estime. Les deux paliers ne
            // sont pas le meme, et c'est voulu.
            TargetLevel palier = section.isComprehension()
                    ? domaine.blockingLevel()
                    : pour(userId, section, domaine.niveau(), objectif);
            if (palier != null) paliers.put(section, palier);
        }
        return paliers;
    }

    /** Le {@link NiveauCecrl} homonyme d'un palier — la table vit dans l'enum. */
    private static NiveauCecrl niveau(TargetLevel palier) {
        return NiveauCecrl.valueOf(palier.name());
    }
}
