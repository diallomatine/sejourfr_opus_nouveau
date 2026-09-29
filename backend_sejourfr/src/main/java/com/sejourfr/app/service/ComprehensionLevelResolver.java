package com.sejourfr.app.service;

import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.enums.SkillMasteryState;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>LA</b> regle de derivation du niveau d'un domaine de COMPREHENSION a partir
 * de l'etat de ses trois competences (A2, B1, B2) — et la seule.
 *
 * <p>La progression y est <b>sequentielle</b> (brief §12) : A2 solide ouvre le
 * travail du B1, B1 solide celui du B2. Le niveau consolide d'un domaine est
 * donc le <b>plus haut palier tel que TOUS les paliers inferieurs sont solides
 * eux aussi</b> — autrement dit la longueur du prefixe ininterrompu de
 * {@code SOLID} en partant du bas.
 *
 * <p>C'est ce qui empeche des reussites hautes de contourner une base fragile
 * (brief §60) :
 * <pre>
 *   A2 solide · B1 solide · B2 fragile  -> B1
 *   A2 solide · B1 fragile · B2 reussi  -> A2   (et non B2)
 *   A2 fragile · ...                    -> rien de consolide
 * </pre>
 * Le second cas est le motif meme de cette classe : quelques bonnes reponses
 * sur des questions B2 ne prouvent rien tant que le B1 n'est pas tenu, et
 * conclure « B2 » enverrait le candidat a l'examen sur une base qui n'existe
 * pas.
 *
 * <p><b>Derive serveur, jamais persiste</b> — meme philosophie que
 * {@code SkillStatusResolver}, {@code SituationDansNiveau} et
 * {@link SkillMasteryEngine} : recalibrer un seuil de maitrise change ce niveau
 * au prochain appel, sans migration ni job de rattrapage. Et jamais recalcule
 * par un front : les trois miroirs liraient trois regles differentes.
 *
 * <p><b>Absent n'est pas mauvais.</b> Un domaine sans prefixe solide rend
 * {@link Optional#empty()}, qui se lit « rien n'est encore consolide » — pas
 * « A1 », pas « A1 non atteint ». Le niveau <i>estime</i> d'un candidat, lui,
 * continue de se lire sur {@code TcfProfileService} : celui-ci repond a une
 * autre question, « qu'est-ce qui est acquis ? », qui est celle du Plan.
 */
@Component
public class ComprehensionLevelResolver {

    /**
     * Les paliers de comprehension, <b>du plus bas au plus haut</b>. L'ordre est
     * la regle : c'est lui qui rend la progression sequentielle.
     */
    private static final List<TargetLevel> PALIERS =
            List.of(TargetLevel.A2, TargetLevel.B1, TargetLevel.B2);

    /**
     * Le niveau consolide d'un domaine.
     *
     * @param etatsParNiveau etat de maitrise de chaque palier du domaine ; un
     *                       palier absent, ou {@code null}, vaut « pas solide »
     *                       et interrompt la progression.
     * @return le plus haut palier solide dont tous les inferieurs le sont aussi,
     *         ou {@link Optional#empty()} si rien n'est consolide.
     */
    public Optional<TargetLevel> niveauConsolide(Map<TargetLevel, SkillMasteryState> etatsParNiveau) {
        TargetLevel consolide = null;
        for (TargetLevel palier : PALIERS) {
            // Un trou dans la chaine arrete tout : c'est exactement ce qui
            // empeche un B2 reussi de racheter un B1 fragile.
            if (etatsParNiveau == null
                    || etatsParNiveau.get(palier) != SkillMasteryState.SOLID) {
                break;
            }
            consolide = palier;
        }
        return Optional.ofNullable(consolide);
    }

    /**
     * Meme regle, appliquee d'un coup aux domaines presents dans un lot de
     * competences de comprehension.
     *
     * <p>Les competences d'EXPRESSION passees par erreur sont ignorees, ainsi
     * que celles dont le palier n'est pas un palier de comprehension
     * ({@code A1} : le referentiel descend plus bas que {@link TargetLevel}).
     *
     * @param competences  competences de comprehension, tous domaines confondus.
     * @param etatsParSkill etat de maitrise deja calcule de chacune ; une
     *                      competence absente vaut « pas solide ».
     * @return les domaines dont un niveau est consolide ; un domaine sans rien
     *         de consolide est <b>absent</b> de la map, jamais present a
     *         {@code null}.
     */
    public Map<SkillSection, TargetLevel> niveauxConsolides(
            Collection<Skill> competences,
            Map<UUID, SkillMasteryState> etatsParSkill) {
        Map<SkillSection, Map<TargetLevel, SkillMasteryState>> parDomaine =
                new EnumMap<>(SkillSection.class);
        for (Skill skill : competences) {
            if (skill.getSection() == null || !skill.getSection().isComprehension()) continue;
            TargetLevel palier = palier(skill.getTargetLevel());
            if (palier == null) continue;
            parDomaine
                    .computeIfAbsent(skill.getSection(), key -> new EnumMap<>(TargetLevel.class))
                    .put(palier, etatsParSkill == null ? null : etatsParSkill.get(skill.getId()));
        }
        Map<SkillSection, TargetLevel> niveaux = new EnumMap<>(SkillSection.class);
        parDomaine.forEach((domaine, etats) ->
                niveauConsolide(etats).ifPresent(niveau -> niveaux.put(domaine, niveau)));
        return niveaux;
    }

    /** {@code null} pour un palier hors {@code A2/B1/B2} — {@code A1} notamment. */
    private static TargetLevel palier(String targetLevel) {
        if (targetLevel == null) return null;
        for (TargetLevel palier : PALIERS) {
            if (palier.name().equals(targetLevel)) return palier;
        }
        return null;
    }
}
