package com.sejourfr.app.service.competence;

import com.sejourfr.app.dto.SkillLevelProgressDto;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SituationNiveauVise;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;

import java.util.ArrayList;
import java.util.List;

/**
 * DERIVE SERVEUR de « ou en est le candidat par rapport a son objectif », a
 * partir du niveau demontre par une micro-production et du palier que sa
 * demarche exige.
 *
 * <p><b>Aucun front ne recalcule ça</b> — meme philosophie que
 * {@code SkillStatusResolver} (statut d'un sujet) et {@link SituationNiveauVise}
 * (les libelles). Trois raisons, toutes vecues dans ce depot :
 * <ul>
 *   <li>le palier vise n'est PAS le {@code targetLevel} stocke : la demarche fait
 *       plancher ({@link TargetProcedure#niveauVise}). Un candidat NAT portant un
 *       {@code targetLevel} herite a B1 vise B2. Cette table a existe en six
 *       copies, et c'est ainsi qu'un candidat s'est retrouve tire vers le B1 ;</li>
 *   <li>l'ordre des paliers est celui de {@link NiveauCecrl}, pas l'ordre
 *       alphabetique — qui donne {@code B1 > A2} par chance ;</li>
 *   <li>les libelles sont geles et recopies a la main sur chaque front : les
 *       laisser deduire d'un calcul local, c'est la garantie de trois
 *       formulations differentes, ce qui est deja arrive sur les verdicts.</li>
 * </ul>
 *
 * <p><b>La jauge</b> compte TROIS crans qui se terminent sur le niveau vise
 * (objectif B2 → A2 · B1 · B2 ; objectif A2 → A1 non atteint · A1 · A2). Un
 * niveau demontre sous le premier cran est ramene au premier ; au-dessus du
 * dernier, au dernier — la barre reste lisible, et la phrase au-dessus dit la
 * verite (« Tu as atteint ton objectif »).
 */
public final class SkillLevelProgressResolver {

    /** Nombre de crans de la jauge. Trois : c'est ce que la maquette affiche. */
    static final int CRANS = 3;

    private SkillLevelProgressResolver() {
    }

    /**
     * @param constate niveau demontre par la production ({@code level_reached}).
     * @param user     candidat, pour sa demarche et son palier declare.
     * @param skill    competence, dont le palier editorial sert de repli.
     * @return {@code null} quand la question n'a pas de sens : pas de niveau
     *         constate (analyse ancienne, contrat v1/v2), ou palier vise
     *         introuvable (ni demarche, ni palier declare, ni palier de
     *         competence lisible). Un front n'affiche alors simplement pas la
     *         jauge.
     */
    public static SkillLevelProgressDto resolve(NiveauCecrl constate, User user, Skill skill) {
        if (constate == null) return null;
        TargetLevel vise = niveauVise(user, skill);
        if (vise == null) return null;
        return resolve(constate, vise);
    }

    /** Variante sans entites, pour les appelants qui ont deja resolu le palier vise. */
    public static SkillLevelProgressDto resolve(NiveauCecrl constate, TargetLevel vise) {
        if (constate == null || vise == null) return null;

        NiveauCecrl objectif = NiveauCecrl.valueOf(vise.name());
        SituationNiveauVise situation = situation(constate, objectif);
        List<NiveauCecrl> echelle = echelle(objectif);
        int curseur = curseur(constate, echelle);

        return new SkillLevelProgressDto(
            constate, vise, situation, situation.getLabel(), echelle, curseur);
    }

    /**
     * Palier VISE : celui qu'exige la demarche, plancher sur le palier declare ;
     * a defaut, le palier editorial de la competence.
     */
    static TargetLevel niveauVise(User user, Skill skill) {
        TargetLevel duCandidat = user == null
            ? null
            : TargetProcedure.niveauVise(user.getTargetProcedure(), user.getTargetLevel());
        if (duCandidat != null) return duCandidat;
        if (skill == null || skill.getTargetLevel() == null) return null;
        try {
            return TargetLevel.valueOf(skill.getTargetLevel().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            // Le referentiel des competences descend jusqu'a A1, que TargetLevel
            // ne connait pas : ce n'est pas une anomalie, il n'y a simplement pas
            // d'objectif a afficher.
            return null;
        }
    }

    /**
     * Distance a l'objectif, en paliers CECRL. Atteint ou depasse, un palier en
     * dessous, deux ou plus.
     */
    static SituationNiveauVise situation(NiveauCecrl constate, NiveauCecrl objectif) {
        int ecart = objectif.ordinal() - constate.ordinal();
        if (ecart <= 0) return SituationNiveauVise.OBJECTIF_ATTEINT;
        if (ecart == 1) return SituationNiveauVise.PROCHE;
        return SituationNiveauVise.EN_CHEMIN;
    }

    /**
     * Les trois crans, du plus bas au plus haut, le dernier etant l'objectif. On
     * descend dans l'ordre de {@link NiveauCecrl} et on s'arrete au plancher
     * ({@code A1_NON_ATTEINT}) : viser A2 donne donc une echelle de trois crans
     * qui commence au plancher, jamais une echelle tronquee.
     */
    static List<NiveauCecrl> echelle(NiveauCecrl objectif) {
        List<NiveauCecrl> crans = new ArrayList<>(CRANS);
        int premier = Math.max(0, objectif.ordinal() - (CRANS - 1));
        for (int i = premier; i <= objectif.ordinal(); i++) {
            crans.add(NiveauCecrl.values()[i]);
        }
        return List.copyOf(crans);
    }

    /**
     * Position du niveau demontre DANS l'echelle. En dessous du premier cran :
     * ramene a 0 — la barre reste lisible, et la phrase au-dessus dit deja qu'il
     * reste du chemin. Au-dessus du dernier (objectif depasse) : ramene au
     * dernier.
     */
    static int curseur(NiveauCecrl constate, List<NiveauCecrl> echelle) {
        int index = echelle.indexOf(constate);
        if (index >= 0) return index;
        return constate.ordinal() < echelle.get(0).ordinal() ? 0 : echelle.size() - 1;
    }
}
