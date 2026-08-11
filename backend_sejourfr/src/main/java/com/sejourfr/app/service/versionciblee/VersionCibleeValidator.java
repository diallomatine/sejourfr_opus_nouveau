package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Valide la sortie BRUTE du second appel, avant toute normalisation.
 *
 * <p>Le tool-schema borde déjà la forme côté fournisseur, mais rien ne garantit
 * qu'il soit respecté : un modèle peut renvoyer un champ vide, une clé en trop,
 * un seul levier, une étiquette de douze mots ou un numéro de segment qui
 * n'existe pas. Sans ce contrôle, le candidat verrait un encart à moitié blanc.
 *
 * <p><b>Ordre de préférence du dépôt respecté</b> : le tool-schema d'abord
 * ({@code additionalProperties:false}, {@code minItems}/{@code maxItems},
 * {@code maxLength}), un contrôle serveur déterministe ensuite, la consigne en
 * dernier. Ce validateur est le deuxième étage.
 *
 * <h2>Les deux contrôles qui n'existent nulle part ailleurs</h2>
 * <ul>
 *   <li><b>ÉCRIT — l'extrait est DANS le texte.</b> Le front SURLIGNE chaque
 *       {@code segments[].extrait} dans {@code exemple_cible.texte}. Un extrait
 *       qui n'y figure pas ne se surligne pas : au mieux il ne s'affiche nulle
 *       part, au pire il s'affiche comme une citation du texte modèle alors
 *       qu'il n'en fait pas partie — c'est-à-dire une phrase inventée présentée
 *       comme un extrait ;</li>
 *   <li><b>ORAL — le numéro de segment existe.</b> Le modèle ne recopie rien, il
 *       DÉSIGNE : le seul défaut possible est un entier hors bornes, et c'est un
 *       entier à comparer à une taille de liste (technique du contrat de
 *       correction v12, qui a supprimé la catégorie entière des citations
 *       introuvables).</li>
 * </ul>
 * Ces deux violations-là ouvrent droit à la seule réparation payée : elles sont
 * mécaniques et nommables.
 *
 * <p>Toutes les violations sont collectées, jamais la première seulement : le
 * message de réparation doit être complet, sinon on paie un appel par violation.
 *
 * <h2>Elles sont RANGÉES PAR SECTION, et c'est le cœur du contrat</h2>
 * Une violation dit quelle <b>partie</b> du bloc est inexploitable, pas que le
 * bloc entier l'est. Un extrait introuvable condamne l'exemple cible ; il ne
 * condamne ni les leviers ni la tournure à retenir, qui ne dépendent d'aucune
 * citation. Le service sert donc les sections saines et abandonne les autres
 * ({@link Section}) — sauf {@link Section#RACINE}, qui décrit une sortie hors
 * contrat de bout en bout, et {@link Section#LEVIERS}, qui porte le bloc.
 */
@Component
public class VersionCibleeValidator {

    /**
     * Partie du bloc à laquelle se rattache une violation. Sert à décider ce qui
     * tombe : une section, ou le bloc.
     */
    public enum Section {
        /**
         * La sortie elle-même : vide, clé inconnue à la racine, ou contrat v1
         * (dont le texte modèle n'est pas une section facultative mais l'objet
         * même du bloc). <b>Fatale</b> : rien n'est exploitable.
         */
        RACINE,
        /**
         * Les leviers. <b>Fatale</b> aussi, mais pour une raison de fond : un
         * plan d'action sans levier n'a aucun intérêt.
         */
        LEVIERS,
        /**
         * L'illustration : {@code exemple_cible} à l'écrit,
         * {@code reformulations} à l'oral. <b>Facultative.</b>
         */
        ILLUSTRATION,
        /** La tournure {@code a_retenir}. <b>Facultative.</b> */
        A_RETENIR
    }

    /**
     * Les violations d'une sortie, rangées par section. Vide = sortie conforme.
     */
    public record Rapport(Map<Section, List<String>> parSection) {

        public Rapport {
            Map<Section, List<String>> fige = new EnumMap<>(Section.class);
            parSection.forEach((section, violations) -> fige.put(section, List.copyOf(violations)));
            parSection = Map.copyOf(fige);
        }

        /** Violations de cette section, jamais null. */
        public List<String> de(Section section) {
            return parSection.getOrDefault(section, List.of());
        }

        /** Toutes les violations, sections confondues, dans l'ordre des sections. */
        public List<String> toutes() {
            List<String> out = new ArrayList<>();
            for (Section section : Section.values()) {
                out.addAll(de(section));
            }
            return out;
        }
    }

    /** Nombre minimal de leviers : un seul ne montre pas un chemin, il montre un détail. */
    static final int MIN_LEVIERS = 2;
    /** Deux segments au minimum : un seul ne montre pas une différence, il montre un mot. */
    static final int MIN_SEGMENTS = 2;
    static final int MAX_SEGMENTS = 3;
    /** Idem à l'oral : deux passages redits, sinon ce n'est pas un chemin. */
    static final int MIN_REFORMULATIONS = 2;
    static final int MAX_REFORMULATIONS = 3;

    /**
     * Tolérance appliquée aux plafonds de longueur avant rejet, identique à
     * celle du module Compétences : un plafond est une consigne pédagogique
     * (« trois mots »), pas un contrat machine. Perdre le bloc parce qu'une
     * étiquette fait quatre mots au lieu de trois serait absurde ; à huit mots,
     * en revanche, ce n'est plus une étiquette.
     */
    static final double TOLERANCE_LONGUEUR = 1.2;

    /**
     * Prefixe des violations de LONGUEUR DU TEXTE MODELE. Il permet de les
     * distinguer des violations de structure, seules les premieres ouvrant droit
     * a une reparation (cf. {@link #uniquementReparables(List)}).
     */
    static final String VIOLATION_LONGUEUR = "texte fait ";

    /** Prefixe des violations « extrait introuvable dans le texte modele ». */
    static final String VIOLATION_EXTRAIT = "extrait introuvable";

    /** Prefixe des violations « numero de segment hors bornes ». */
    static final String VIOLATION_SEGMENT = "numero de segment";

    private final VersionCibleeRubricsProvider rubrics;

    public VersionCibleeValidator(VersionCibleeRubricsProvider rubrics) {
        this.rubrics = rubrics;
    }

    /**
     * @param bornes     bornes de la tache ({@code production_tasks.mots_min/mots_max}
     *                   croisees avec les garde-fous de configuration). Jamais null
     *                   a l'ecrit : c'est ce qui garantit qu'un texte modele est
     *                   SOUMETTABLE sur la plateforme qui l'affiche.
     * @param variante   ecrit ou oral : deux contrats de sortie distincts.
     * @param nbSegments nombre de passages CITABLES de la production orale ;
     *                   ignore a l'ecrit.
     * @return les violations rangees par section, vides si la sortie est conforme.
     */
    public Rapport violations(Map<String, Object> sortie, int maxLeviers,
                              ProductionTextBounds bornes, VersionCibleeVariante variante,
                              int nbSegments) {
        Map<Section, List<String>> parSection = new EnumMap<>(Section.class);
        for (Section section : Section.values()) {
            parSection.put(section, new ArrayList<>());
        }
        List<String> racine = parSection.get(Section.RACINE);
        if (sortie == null || sortie.isEmpty()) {
            racine.add("sortie vide : le contrat attend " + String.join(", ", attendus(variante)));
            return new Rapport(parSection);
        }
        if (!rubrics.contrat().planDAction()) {
            // Sous v1, le texte modele EST le bloc : sa perte ne laisse rien a
            // servir. Tout est donc fatal, comme avant l'introduction des sections.
            validerContratV1(sortie, maxLeviers, bornes, racine);
            return new Rapport(parSection);
        }

        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        attendus(variante).forEach(vues::remove);

        validerLeviers(sortie.get(VersionCibleeFields.LEVIERS), maxLeviers,
            parSection.get(Section.LEVIERS));
        List<String> illustration = parSection.get(Section.ILLUSTRATION);
        if (variante == VersionCibleeVariante.ORAL) {
            validerReformulations(sortie.get(VersionCibleeFields.REFORMULATIONS), nbSegments,
                illustration);
        } else {
            validerExempleCible(sortie.get(VersionCibleeFields.EXEMPLE_CIBLE), bornes, illustration);
        }
        validerARetenir(sortie.get(VersionCibleeFields.A_RETENIR), parSection.get(Section.A_RETENIR));

        for (String enTrop : vues) {
            racine.add("cle hors contrat : " + enTrop);
        }
        return new Rapport(parSection);
    }

    /** Clés attendues à la racine, par variante. */
    private List<String> attendus(VersionCibleeVariante variante) {
        if (!rubrics.contrat().planDAction()) {
            return List.of(VersionCibleeFields.TEXTE, VersionCibleeFields.CE_QUI_MANQUE);
        }
        return List.of(VersionCibleeFields.LEVIERS,
            variante == VersionCibleeVariante.ORAL
                ? VersionCibleeFields.REFORMULATIONS : VersionCibleeFields.EXEMPLE_CIBLE,
            VersionCibleeFields.A_RETENIR);
    }

    /**
     * Vrai quand TOUTES les violations sont MECANIQUES et nommables : longueur du
     * texte modele, extrait introuvable, numero de segment hors bornes. Ce sont
     * les seules qui ouvrent droit a la reparation payee — on peut dire au modele
     * ce qui a ete refuse et l'operation exacte a faire, et le depot a mesure
     * qu'un reessai non actionnable repare zero cas sur huit.
     *
     * <p>Une sortie structurellement fausse (cle en trop, levier vide, un seul
     * segment) n'ouvre droit a aucun second appel : le bloc reste un confort.
     */
    static boolean uniquementReparables(List<String> violations) {
        return !violations.isEmpty() && violations.stream().allMatch(VersionCibleeValidator::reparable);
    }

    private static boolean reparable(String violation) {
        return violation != null && (violation.startsWith(VIOLATION_LONGUEUR)
            || violation.startsWith(VIOLATION_EXTRAIT)
            || violation.startsWith(VIOLATION_SEGMENT));
    }

    // -------------------------------------------------------------- contrat v1

    private void validerContratV1(Map<String, Object> sortie, int maxLeviers,
                                  ProductionTextBounds bornes, List<String> violations) {
        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        vues.remove(VersionCibleeFields.TEXTE);
        vues.remove(VersionCibleeFields.CE_QUI_MANQUE);

        Object texte = sortie.get(VersionCibleeFields.TEXTE);
        if (!(texte instanceof String s)) {
            violations.add(VersionCibleeFields.TEXTE + " doit etre une chaine de caracteres");
        } else if (s.isBlank()) {
            violations.add(VersionCibleeFields.TEXTE + " est vide");
        } else {
            validerLongueurTexte(s, bornes, violations);
        }

        Object leviers = sortie.get(VersionCibleeFields.CE_QUI_MANQUE);
        if (!(leviers instanceof List<?> liste)) {
            violations.add(VersionCibleeFields.CE_QUI_MANQUE + " doit etre une liste");
        } else {
            validerLeviersTexte(liste, maxLeviers, violations);
        }

        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + enTrop);
        }
    }

    private void validerLeviersTexte(List<?> liste, int maxLeviers, List<String> violations) {
        validerCardinalite(VersionCibleeFields.CE_QUI_MANQUE, liste.size(), MIN_LEVIERS, maxLeviers,
            violations);
        Integer plafond = rubrics.contraintesLongueur().get(VersionCibleeFields.CE_QUI_MANQUE);
        int i = 0;
        for (Object levier : liste) {
            i++;
            String chemin = VersionCibleeFields.CE_QUI_MANQUE + "[" + i + "]";
            if (!(levier instanceof String texte)) {
                violations.add(chemin + " doit etre une chaine de caracteres");
                continue;
            }
            if (texte.isBlank()) {
                violations.add(chemin + " est vide");
                continue;
            }
            validerPlafond(chemin, texte, plafond, violations);
        }
    }

    /**
     * LONGUEUR DU TEXTE MODELE — controle DUR, sans tolerance.
     *
     * <p>La tolerance de 20 % appliquee aux plafonds pedagogiques ne vaut PAS
     * ici : un levier est une consigne, le texte modele est une PRODUCTION, et
     * {@code ProductionEvaluationService.validateTextWordCount} refuse la
     * soumission d'un candidat au mot pres depuis que la tolerance historique a
     * ete supprimee (bornes EE strictes TCF IRN). Accorder ici 20 % de marge
     * reviendrait a rendre au candidat un modele que la plateforme refuserait de
     * recevoir — le defaut exact que ce controle corrige (63 et 64 mots rendus
     * sur une tache plafonnee a 60).
     *
     * <p>Le comptage est celui de la soumission ({@link ProductionPayloadSupport#countWords}) :
     * deux comptages differents suffiraient a laisser passer un texte refuse.
     */
    private static void validerLongueurTexte(String texte, ProductionTextBounds bornes,
                                             List<String> violations) {
        if (bornes == null) return;
        int mots = ProductionPayloadSupport.countWords(texte);
        if (bornes.accepte(mots)) return;
        violations.add(VIOLATION_LONGUEUR + mots + " mots, la tache en attend " + bornes.libelle());
    }

    // ----------------------------------------------------------------- leviers

    private void validerLeviers(Object brut, int maxLeviers, List<String> violations) {
        if (!(brut instanceof List<?> liste)) {
            violations.add(VersionCibleeFields.LEVIERS + " doit etre une liste");
            return;
        }
        validerCardinalite(VersionCibleeFields.LEVIERS, liste.size(), MIN_LEVIERS, maxLeviers,
            violations);
        int i = 0;
        for (Object item : liste) {
            i++;
            String prefixe = VersionCibleeFields.LEVIERS + "[" + i + "]";
            Map<String, Object> levier = asMap(item, prefixe, violations);
            if (levier == null) continue;
            champTexte(levier, VersionCibleeFields.ACTION, prefixe, violations);
            champTexte(levier, VersionCibleeFields.EXEMPLE, prefixe, violations);
            clesEnTrop(levier, prefixe, violations,
                VersionCibleeFields.ACTION, VersionCibleeFields.EXEMPLE);
        }
    }

    // ----------------------------------------------------------- exemple cible

    private void validerExempleCible(Object brut, ProductionTextBounds bornes,
                                     List<String> violations) {
        String prefixe = VersionCibleeFields.EXEMPLE_CIBLE;
        Map<String, Object> bloc = asMap(brut, prefixe, violations);
        if (bloc == null) return;
        clesEnTrop(bloc, prefixe, violations,
            VersionCibleeFields.TEXTE, VersionCibleeFields.SEGMENTS);

        String texte = champTexte(bloc, VersionCibleeFields.TEXTE, prefixe, violations);
        if (texte != null) validerLongueurTexte(texte, bornes, violations);

        Object segments = bloc.get(VersionCibleeFields.SEGMENTS);
        if (!(segments instanceof List<?> liste)) {
            violations.add(prefixe + "." + VersionCibleeFields.SEGMENTS + " doit etre une liste");
            return;
        }
        validerCardinalite(prefixe + "." + VersionCibleeFields.SEGMENTS, liste.size(),
            MIN_SEGMENTS, MAX_SEGMENTS, violations);
        int i = 0;
        for (Object item : liste) {
            i++;
            String p = prefixe + "." + VersionCibleeFields.SEGMENTS + "[" + i + "]";
            Map<String, Object> segment = asMap(item, p, violations);
            if (segment == null) continue;
            clesEnTrop(segment, p, violations,
                VersionCibleeFields.EXTRAIT, VersionCibleeFields.APPORT);
            String extrait = champTexte(segment, VersionCibleeFields.EXTRAIT, p, violations);
            champTexte(segment, VersionCibleeFields.APPORT, p, violations);
            // LE controle central : le front surligne cet extrait DANS le texte.
            // On ne compare ni a la casse pres relachee, ni apres normalisation :
            // le surlignage se fait sur la chaine exacte, la verification aussi.
            if (extrait != null && texte != null && !texte.contains(extrait)) {
                violations.add(VIOLATION_EXTRAIT + " dans le texte modele — " + p + " : \""
                    + extrait + "\"");
            }
        }
    }

    // --------------------------------------------------------- reformulations

    private void validerReformulations(Object brut, int nbSegments, List<String> violations) {
        String prefixe = VersionCibleeFields.REFORMULATIONS;
        if (!(brut instanceof List<?> liste)) {
            violations.add(prefixe + " doit etre une liste");
            return;
        }
        validerCardinalite(prefixe, liste.size(), MIN_REFORMULATIONS, MAX_REFORMULATIONS,
            violations);
        Set<Integer> numerosVus = new LinkedHashSet<>();
        int i = 0;
        for (Object item : liste) {
            i++;
            String p = prefixe + "[" + i + "]";
            Map<String, Object> reformulation = asMap(item, p, violations);
            if (reformulation == null) continue;
            clesEnTrop(reformulation, p, violations, VersionCibleeFields.SEGMENT_NUMERO,
                VersionCibleeFields.REFORMULE, VersionCibleeFields.APPORT);
            champTexte(reformulation, VersionCibleeFields.REFORMULE, p, violations);
            champTexte(reformulation, VersionCibleeFields.APPORT, p, violations);
            validerNumero(reformulation.get(VersionCibleeFields.SEGMENT_NUMERO), p, nbSegments,
                numerosVus, violations);
        }
    }

    /**
     * LE NUMERO DE SEGMENT. Un entier hors bornes est MECANIQUE : on peut le
     * nommer et donner l'intervalle valide, donc il vaut une reparation. Un
     * non-entier ne vaut rien : le modele n'a pas repondu au contrat.
     *
     * <p>Un meme passage designe deux fois n'est pas une erreur de format mais un
     * appauvrissement : deux reformulations du meme tour ne montrent pas deux
     * choses. Elle est comptee comme non reparable, comme toute violation de
     * structure.
     */
    private static void validerNumero(Object brut, String chemin, int nbSegments,
                                      Set<Integer> dejaVus, List<String> violations) {
        String champ = chemin + "." + VersionCibleeFields.SEGMENT_NUMERO;
        if (brut == null) {
            violations.add(champ + " est absent");
            return;
        }
        if (!(brut instanceof Number n) || n.doubleValue() != Math.floor(n.doubleValue())) {
            violations.add(champ + " doit etre un entier");
            return;
        }
        int numero = n.intValue();
        if (numero < 1 || numero > nbSegments) {
            violations.add(VIOLATION_SEGMENT + " hors bornes — " + champ + " vaut " + numero
                + ", la production en compte " + nbSegments + " (numeros 1 a " + nbSegments + ")");
            return;
        }
        if (!dejaVus.add(numero)) {
            violations.add(champ + " designe le passage " + numero
                + ", deja reformule : deux reformulations du meme passage ne montrent qu'une chose");
        }
    }

    // ------------------------------------------------------------- a retenir

    private void validerARetenir(Object brut, List<String> violations) {
        String prefixe = VersionCibleeFields.A_RETENIR;
        Map<String, Object> bloc = asMap(brut, prefixe, violations);
        if (bloc == null) return;
        clesEnTrop(bloc, prefixe, violations,
            VersionCibleeFields.FORMULE, VersionCibleeFields.EXPLICATION);
        champTexte(bloc, VersionCibleeFields.FORMULE, prefixe, violations);
        champTexte(bloc, VersionCibleeFields.EXPLICATION, prefixe, violations);
    }

    // ---------------------------------------------------------------- outils

    private static void validerCardinalite(String chemin, int taille, int min, int max,
                                           List<String> violations) {
        if (taille < min) {
            violations.add(chemin + " compte " + taille + " element(s), il en faut au moins " + min);
        }
        if (taille > max) {
            violations.add(chemin + " compte " + taille + " elements, le maximum est " + max);
        }
    }

    /**
     * Verifie qu'un champ terminal est une chaine non vide et sous son plafond de
     * mots, et le retourne. Null quand il est absent, mal type ou vide — l'appelant
     * n'a alors plus rien a en faire.
     */
    private String champTexte(Map<String, Object> parent, String cle, String prefixe,
                              List<String> violations) {
        Object valeur = parent.get(cle);
        String chemin = prefixe + "." + cle;
        if (valeur == null) {
            violations.add(chemin + " est absent");
            return null;
        }
        if (!(valeur instanceof String texte)) {
            violations.add(chemin + " doit etre une chaine de caracteres");
            return null;
        }
        if (texte.isBlank()) {
            violations.add(chemin + " est vide");
            return null;
        }
        validerPlafond(chemin, texte, rubrics.contraintesLongueur().get(cle), violations);
        return texte;
    }

    private static void validerPlafond(String chemin, String texte, Integer plafond,
                                       List<String> violations) {
        if (plafond == null) return;
        int max = (int) Math.floor(plafond * TOLERANCE_LONGUEUR);
        int mots = compterMots(texte);
        if (mots > max) {
            violations.add(chemin + " fait " + mots + " mots, le maximum est " + plafond
                + " (tolere jusqu'a " + max + ")");
        }
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> asMap(Object brut, String chemin, List<String> violations) {
        if (brut == null) {
            violations.add(chemin + " est absent");
            return null;
        }
        if (!(brut instanceof Map<?, ?> m)) {
            violations.add(chemin + " doit etre un objet");
            return null;
        }
        return (Map<String, Object>) m;
    }

    private static void clesEnTrop(Map<String, Object> bloc, String chemin,
                                   List<String> violations, String... attendues) {
        Set<String> vues = new LinkedHashSet<>(bloc.keySet());
        for (String attendue : attendues) {
            vues.remove(attendue);
        }
        for (String enTrop : vues) {
            violations.add("cle hors contrat : " + chemin + "." + enTrop);
        }
    }

    static int compterMots(String texte) {
        String normalise = texte.trim();
        if (normalise.isEmpty()) return 0;
        return normalise.split("\\s+").length;
    }
}
