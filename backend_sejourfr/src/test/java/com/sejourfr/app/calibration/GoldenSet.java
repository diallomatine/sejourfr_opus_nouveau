package com.sejourfr.app.calibration;

import com.sejourfr.app.enums.ConfianceEvaluation;
import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.enums.NiveauCecrl;
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
 * Corpus de reference du banc de mesure ({@code calibration/golden-set-v1.json}).
 *
 * <p>Fichier en LECTURE SEULE : c'est la verite de reference. Le banc ne
 * l'ajuste jamais pour ameliorer ses chiffres.
 */
final class GoldenSet {

    static final String RESOURCE = "calibration/golden-set-v1.json";

    private GoldenSet() {
    }

    static List<Cas> load() {
        ObjectMapper om = new ObjectMapper();
        Map<String, Object> root;
        try (InputStream is = new ClassPathResource(RESOURCE).getInputStream()) {
            String json = StreamUtils.copyToString(is, StandardCharsets.UTF_8);
            root = om.readValue(json, new TypeReference<Map<String, Object>>() {
            });
        } catch (Exception e) {
            throw new IllegalStateException("Corpus de calibration illisible : " + RESOURCE, e);
        }
        if (!(root.get("cas") instanceof List<?> cas)) {
            throw new IllegalStateException("Corpus sans tableau 'cas' : " + RESOURCE);
        }
        List<Cas> out = new ArrayList<>();
        for (Object o : cas) {
            if (o instanceof Map<?, ?> m) out.add(toCas(m));
        }
        if (out.isEmpty()) throw new IllegalStateException("Corpus vide : " + RESOURCE);
        return List.copyOf(out);
    }

    private static Cas toCas(Map<?, ?> m) {
        Map<?, ?> a = m.get("attendu") instanceof Map<?, ?> am ? am : Map.of();
        Attendu attendu = new Attendu(
            NiveauCecrl.valueOf(str(a.get("niveau"))),
            strings(a.get("niveau_tolerance")).stream().map(NiveauCecrl::valueOf).toList(),
            num(a.get("note_min")),
            num(a.get("note_max")),
            ConfianceEvaluation.parse(a.get("confiance")),
            Boolean.TRUE.equals(a.get("accomplissement_obligatoire_traite")),
            strings(a.get("points_oublies_attendus")),
            strings(a.get("pieges")));
        return new Cas(
            str(m.get("id")),
            EpreuveType.valueOf(str(m.get("epreuve"))),
            (int) num(m.get("tache")),
            str(m.get("niveau_cible")),
            str(m.get("consigne")),
            str(m.get("production")),
            attendu);
    }

    private static String str(Object o) {
        return o == null ? null : o.toString();
    }

    private static double num(Object o) {
        return o instanceof Number n ? n.doubleValue() : Double.NaN;
    }

    private static List<String> strings(Object o) {
        if (!(o instanceof List<?> l)) return List.of();
        List<String> out = new ArrayList<>();
        for (Object e : l) if (e != null) out.add(e.toString());
        return List.copyOf(out);
    }

    /**
     * Zone d'acceptation d'un cas : le corpus donne des fourchettes, pas des
     * verites ponctuelles.
     */
    record Attendu(
        NiveauCecrl niveau,
        List<NiveauCecrl> tolerance,
        double noteMin,
        double noteMax,
        ConfianceEvaluation confiance,
        boolean obligatoireTraite,
        List<String> pointsOublies,
        List<String> pieges) {

        double centre() {
            return (noteMin + noteMax) / 2.0;
        }
    }

    record Cas(
        String id,
        EpreuveType epreuve,
        int tache,
        String niveauCible,
        String consigne,
        String production,
        Attendu attendu) {

        /** Cle de regroupement des 6 taches : {@code EE_T1} … {@code EO_T3}. */
        String groupe() {
            return (epreuve == EpreuveType.TCF_EE ? "EE" : "EO") + "_T" + tache;
        }
    }
}
