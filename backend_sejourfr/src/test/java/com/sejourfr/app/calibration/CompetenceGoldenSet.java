package com.sejourfr.app.calibration;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.enums.SkillCriterionStatus;
import com.sejourfr.app.enums.SkillDifficulty;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import org.springframework.core.io.ClassPathResource;
import org.springframework.util.StreamUtils;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Corpus de reference du banc du module « Competences TCF »
 * ({@code calibration/golden-set-competences-v1.json}).
 *
 * <p>Jumeau de {@link GoldenSet}, jamais un remplacant : celui-ci porte des
 * MICRO-productions de quelques phrases jugees sur un critere unique, l'autre
 * des productions completes notees sur 20. Les deux corpus ne se melangent
 * jamais, ni dans un fichier, ni dans un rapport.
 *
 * <p><b>Fichier en LECTURE SEULE</b> : c'est la verite de reference. Le banc ne
 * l'ajuste jamais pour ameliorer ses chiffres — on corrige le systeme, pas le
 * corpus.
 *
 * <p><b>Deux populations, strictement separees.</b> {@link #load()} rend les
 * <b>90 cas synthetiques</b> annotes, les seuls qui comptent. {@link #temoins()}
 * rend les productions <b>REELLES</b> relevees en base : elles n'ont aucune
 * verite terrain, portent {@code horsScore = true} et sont exclues de tous les
 * agregats. Elles ne servent qu'a verifier que les cas synthetiques ressemblent
 * a ce que les candidats ecrivent vraiment.
 */
final class CompetenceGoldenSet {

    static final String RESOURCE = "calibration/golden-set-competences-v1.json";

    private CompetenceGoldenSet() {
    }

    /** Les cas ANNOTES, seuls a entrer dans les agregats. */
    static List<Cas> load() {
        List<Cas> out = new ArrayList<>();
        for (Object o : tableau("cas")) {
            if (o instanceof Map<?, ?> m) out.add(toCas(m, false));
        }
        if (out.isEmpty()) throw new IllegalStateException("Corpus vide : " + RESOURCE);
        return List.copyOf(out);
    }

    /**
     * Productions REELLES, <b>hors score</b>. Aucune verite terrain : le bloc
     * {@code connu_en_base} rapporte ce que le correcteur avait deja repondu, ce
     * n'est pas une reference contre laquelle mesurer quoi que ce soit.
     */
    static List<Cas> temoins() {
        List<Cas> out = new ArrayList<>();
        for (Object o : tableau("temoins_reels")) {
            if (o instanceof Map<?, ?> m) out.add(toCas(m, true));
        }
        return List.copyOf(out);
    }

    private static List<?> tableau(String cle) {
        ObjectMapper om = new ObjectMapper();
        Map<String, Object> root;
        try (InputStream is = new ClassPathResource(RESOURCE).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            root = om.readValue(json, new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception e) {
            throw new IllegalStateException("Corpus de calibration illisible : " + RESOURCE, e);
        }
        if (!(root.get(cle) instanceof List<?> l)) {
            throw new IllegalStateException("Corpus sans tableau '" + cle + "' : " + RESOURCE);
        }
        return l;
    }

    private static Cas toCas(Map<?, ?> m, boolean temoin) {
        Map<?, ?> a = m.get("attendu") instanceof Map<?, ?> am ? am : Map.of();
        Attendu attendu = temoin ? null : new Attendu(
            NiveauCecrl.valueOf(str(a.get("niveau"))),
            strings(a.get("niveau_tolerance")).stream().map(NiveauCecrl::valueOf).toList(),
            SkillCriterionStatus.valueOf(str(a.get("statut_critere"))),
            strings(a.get("statut_tolerance")).stream().map(SkillCriterionStatus::valueOf).toList(),
            strings(a.get("pieges")));

        SkillTaskCode tache = SkillTaskCode.valueOf(str(m.get("task_code")));
        return new Cas(
            str(m.get("id")),
            temoin,
            tache,
            SkillSection.valueOf(str(m.get("section"))),
            str(m.get("skill_code")),
            defaut(str(m.get("skill_title")), tache.getTitle()),
            defaut(str(m.get("skill_description")), ""),
            defaut(str(m.get("skill_general_criterion")), ""),
            defaut(str(m.get("skill_target_level")), tache.getTargetLevel()),
            str(m.get("prompt_code")),
            defaut(str(m.get("prompt_title")), str(m.get("prompt_code"))),
            difficulte(m.get("difficulty_level")),
            defaut(str(m.get("context")), ""),
            defaut(str(m.get("instruction")), ""),
            defaut(str(m.get("unique_criterion")), ""),
            entier(m.get("recommended_min_words")),
            entier(m.get("recommended_max_words")),
            entier(m.get("recommended_duration_seconds")),
            str(m.get("echelle")),
            defaut(str(m.get("production")), ""),
            attendu);
    }

    private static SkillDifficulty difficulte(Object brut) {
        String v = str(brut);
        return v == null ? SkillDifficulty.EASY : SkillDifficulty.valueOf(v);
    }

    private static String defaut(String v, String repli) {
        return v == null || v.isBlank() ? repli : v;
    }

    private static String str(Object o) {
        return o == null ? null : o.toString();
    }

    private static Integer entier(Object o) {
        return o instanceof Number n ? n.intValue() : null;
    }

    private static List<String> strings(Object o) {
        if (!(o instanceof List<?> l)) return List.of();
        List<String> out = new ArrayList<>();
        for (Object e : l) if (e != null) out.add(e.toString());
        return List.copyOf(out);
    }

    /**
     * Zone d'acceptation d'un cas. Comme cote productions completes, le corpus
     * donne des FOURCHETTES, pas des verites ponctuelles — mais ici il n'y a
     * <b>aucune note</b> : le module n'en produit pas, et le contrat de sortie
     * n'a aucun champ ou la loger.
     *
     * @param statut le verdict de critere, <b>independant</b> du palier : une
     *               production peut etre B2 et ne pas remplir son critere. Les
     *               cas {@code HORS_SUJET_RICHE} du corpus existent pour ca.
     */
    record Attendu(
        NiveauCecrl niveau,
        List<NiveauCecrl> tolerance,
        SkillCriterionStatus statut,
        List<SkillCriterionStatus> statutTolerance,
        List<String> pieges) {
    }

    /**
     * @param horsScore production REELLE relevee en base : aucune verite
     *                  terrain, exclue de tous les agregats.
     * @param echelle   code du sujet quand le cas appartient a une ECHELLE — une
     *                  serie de productions du <b>meme sujet</b> a des paliers
     *                  differents. C'est le materiau de la mesure de
     *                  sensibilite : sur un sujet identique, le correcteur
     *                  rend-il des niveaux differents ?
     */
    record Cas(
        String id,
        boolean horsScore,
        SkillTaskCode taskCode,
        SkillSection section,
        String skillCode,
        String skillTitle,
        String skillDescription,
        String skillGeneralCriterion,
        String skillTargetLevel,
        String promptCode,
        String promptTitle,
        SkillDifficulty difficulte,
        String contexte,
        String consigne,
        String critereUnique,
        Integer motsMin,
        Integer motsMax,
        Integer dureeSec,
        String echelle,
        String production,
        Attendu attendu) {

        /** Cle de regroupement : {@code EE1} … {@code EO3}. */
        String groupe() {
            return taskCode.name();
        }

        boolean orale() {
            return section == SkillSection.EO;
        }
    }
}
