package com.sejourfr.app.util;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;

/**
 * La correspondance <b>domaine de competence ⇄ epreuve du TCF</b>, et l'echelle
 * commune des paliers — <b>autorite unique</b>.
 *
 * <p><b>Pourquoi ici et pas sur les enums.</b> {@link SkillSection} dit
 * explicitement etre « volontairement distinct de {@link EpreuveType} », parce
 * que melanger les deux « inviterait a reutiliser le pipeline de notation des
 * productions, ce qu'on refuse ». Les enums restent donc separes, et c'est la
 * <b>traduction</b> qui vit a un seul endroit.
 *
 * <p><b>Extrait le 2026-09-17.</b> Elle vivait en deux copies dans
 * {@code PlanCycleResolver} (une privee dans chaque sens) et le parcours TCF en
 * aurait fait une troisieme. Regle du depot : a la 2<sup>e</sup> occurrence, on
 * extrait — la table des paliers a deja vecu en six copies.
 */
public final class TcfDomaine {

    private TcfDomaine() {
    }

    /**
     * Le domaine d'une competence, dit dans le vocabulaire des epreuves.
     *
     * @return {@code null} si la section est {@code null} — <b>inconnu, jamais
     *         un repli sur EE</b> : une competence sans domaine n'appartient a
     *         aucune epreuve, et lui en inventer une la rangerait dans un lot
     *         qui n'est pas le sien.
     */
    public static EpreuveType epreuve(SkillSection section) {
        if (section == null) return null;
        return switch (section) {
            case CO -> EpreuveType.TCF_CO;
            case CE -> EpreuveType.TCF_CE;
            case EO -> EpreuveType.TCF_EO;
            case EE -> EpreuveType.TCF_EE;
        };
    }

    /**
     * L'inverse, pour les <b>quatre epreuves du TCF IRN</b> et elles seules.
     *
     * @return {@code null} pour {@code CIVIQUE}, {@code TCF_STRUCTURE} et
     *         {@code TCF_COMPLET}. 🛑 {@code TCF_STRUCTURE} n'est <b>pas</b> une
     *         cinquieme epreuve — c'est un module d'entrainement complementaire,
     *         sans competence au referentiel — et {@code TCF_COMPLET} est un
     *         conteneur. Les faire retomber sur un domaine par defaut leur
     *         attribuerait des priorites qui n'existent pas.
     */
    public static SkillSection section(EpreuveType epreuve) {
        if (epreuve == null) return null;
        return switch (epreuve) {
            case TCF_CO -> SkillSection.CO;
            case TCF_CE -> SkillSection.CE;
            case TCF_EO -> SkillSection.EO;
            case TCF_EE -> SkillSection.EE;
            case CIVIQUE, TCF_STRUCTURE, TCF_COMPLET -> null;
        };
    }

    /**
     * Le palier vise, place sur l'echelle CECRL — pour comparer un objectif
     * ({@link TargetLevel}) et un niveau mesure ({@link NiveauCecrl}) sans jamais
     * comparer deux enums differents par leur {@code ordinal()}.
     */
    public static NiveauCecrl niveau(TargetLevel palier) {
        if (palier == null) return null;
        return switch (palier) {
            case A2 -> NiveauCecrl.A2;
            case B1 -> NiveauCecrl.B1;
            case B2 -> NiveauCecrl.B2;
        };
    }

    /**
     * <b>L'ecart au niveau cible</b> : de combien de crans CECRL cette epreuve
     * est-elle <b>sous</b> l'objectif (R10 bis).
     *
     * <p>Positif = du retard, {@code 0} = objectif atteint ou depasse.
     *
     * @param mesure  le niveau de l'epreuve, <b>lecture Plan</b>
     *                ({@code TcfProfileService.levelProfile} — arbitrage D-2).
     *                🛑 {@code null} = <b>jamais mesuree</b>, donc <b>inconnu</b>.
     * @return {@code null} quand l'ecart n'est pas calculable. R10 bis place
     *         alors l'epreuve <b>apres</b> celles dont l'ecart est connu : une
     *         mesure absente ne devient pas l'urgence maximale par defaut, ce qui
     *         serait la confusion « null = mauvais » que le depot a deja payee
     *         (V040/V041/V042).
     */
    public static Integer ecartAuNiveauCible(NiveauCecrl mesure, TargetLevel objectif) {
        NiveauCecrl cible = niveau(objectif);
        if (mesure == null || cible == null) return null;
        return Math.max(0, cible.ordinal() - mesure.ordinal());
    }
}
