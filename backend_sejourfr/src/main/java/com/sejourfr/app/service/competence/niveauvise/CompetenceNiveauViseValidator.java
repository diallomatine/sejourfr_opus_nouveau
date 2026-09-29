package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.util.PlafondMots;
import com.sejourfr.app.util.ProductionPayloadSupport;
import com.sejourfr.app.util.ProductionTextBounds;
import com.sejourfr.app.util.SegmentsSurlignage;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Valide la sortie <b>BRUTE</b> du second appel, avant toute normalisation.
 *
 * <p>Le tool-schema borde deja la forme cote fournisseur, mais rien ne garantit
 * qu'il soit respecte : un modele peut renvoyer un levier vide, une etiquette de
 * douze mots ou une cle en trop. Sans ce controle, le candidat verrait un encart
 * a moitie blanc.
 *
 * <p><b>Ordre de preference du depot respecte</b> : le tool-schema d'abord
 * ({@code additionalProperties:false}, {@code minItems}/{@code maxItems},
 * {@code maxLength}), un controle serveur deterministe ensuite, la consigne en
 * dernier. Ce validateur est le deuxieme etage.
 *
 * <h2>Les violations sont RANGEES PAR SECTION</h2>
 * Une violation dit quelle <b>partie</b> du bloc est inexploitable, pas que le
 * bloc entier l'est — meme contrat que {@code VersionCibleeValidator}, qui porte
 * le meme plan d'action sur l'ecran des productions. Un texte modele fautif
 * condamne l'exemple cible ; il ne condamne ni les leviers ni la tournure a
 * retenir, qui ne dependent d'aucun texte. Seules {@link Section#RACINE} (rien
 * n'est exploitable) et {@link Section#LEVIERS} (un plan d'action sans levier
 * n'a aucun interet) emportent le bloc.
 *
 * <h2>Ni les {@code segments}, ni les {@code marqueurs_du_palier} ne sont juges ici</h2>
 * Les premiers sont un <b>confort de lecture</b> (2026-08-12), les seconds la
 * <b>preuve du palier</b> (contrat v2) : les deux passent par
 * {@link SegmentsSurlignage}, qui retire ce qu'il ne peut pas rattacher au texte
 * et laisse le texte servi. Aucun des deux ne peut faire tomber une section :
 * ce qui rend le palier exigible, c'est le tool-schema qui les <b>requiert</b>,
 * pas un refus a posteriori qui viderait l'ecran du candidat.
 *
 * <h2>Ni le {@code procede} d'un levier n'est juge ici</h2>
 * Contrat v3 : chaque levier declare l'operation de langue qu'il met en œuvre.
 * Le validateur l'<b>admet</b> comme cle du contrat, et rien de plus. Une
 * violation de la section {@link Section#LEVIERS} est FATALE ; un procede
 * manquant ou fantaisiste ne doit jamais vider l'ecran du candidat. Ce qu'il
 * vaut se compte dans {@link CompetenceNiveauViseProcedeAudit}, qui ne retire
 * jamais un levier.
 *
 * <p>Toutes les violations sont collectees, jamais la premiere seulement : le
 * message de reparation doit etre complet, sinon on paie un appel par violation.
 */
@Component
public class CompetenceNiveauViseValidator {

    /** Deux leviers au minimum : un seul ne montre pas un chemin, il montre un detail. */
    static final int MIN_LEVIERS = 2;

    /**
     * Tolerance appliquee aux plafonds de longueur avant rejet, resolue par
     * {@link PlafondMots#tolere(int)} — identique au reste du depot : un plafond
     * est une consigne pedagogique (« trois mots »), pas un contrat machine.
     * Perdre le bloc parce qu'une etiquette fait quatre mots au lieu de trois
     * serait absurde ; a huit mots, en revanche, ce n'est plus une etiquette.
     *
     * <p>⚠️ Elle ne vaut PAS pour les bornes du TEXTE MODELE, appliquees au mot
     * pres (cf. {@link #validerLongueurTexte}).
     */
    static final double TOLERANCE_LONGUEUR = PlafondMots.TOLERANCE;

    /**
     * Prefixe de LA violation qui dit « rien n'est exploitable ». Elle permet de
     * compter separement une sortie hors contrat d'un champ fautif — les deux
     * abandonnent le bloc, mais ne se corrigent pas de la meme facon.
     */
    static final String VIOLATION_SORTIE_VIDE = "sortie vide";

    /**
     * Prefixe des violations de LONGUEUR DU TEXTE MODELE. Elles sont les seules
     * de la section {@code exemple_cible} a ouvrir droit a une reparation payee :
     * elles sont mecaniques et nommables (compte obtenu, bornes attendues, mots a
     * retirer), donc reparables par un message actionnable.
     */
    static final String VIOLATION_LONGUEUR = "texte fait ";

    /** Partie du bloc a laquelle se rattache une violation. */
    public enum Section {
        /** La sortie elle-meme : vide, ou cle inconnue a la racine. <b>Fatale.</b> */
        RACINE,
        /** Les leviers. <b>Fatale</b> : un plan d'action sans levier n'a aucun interet. */
        LEVIERS,
        /** Le texte modele et sa forme. <b>Facultative.</b> */
        EXEMPLE_CIBLE,
        /** La tournure {@code a_retenir}. <b>Facultative.</b> */
        A_RETENIR
    }

    /** Les violations d'une sortie, rangees par section. Toutes vides = conforme. */
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

        /** Vrai quand une section fatale est en defaut : rien ne sera servi. */
        public boolean fatale() {
            return !de(Section.RACINE).isEmpty() || !de(Section.LEVIERS).isEmpty();
        }
    }

    private final CompetenceNiveauViseRubricsProvider rubrics;

    public CompetenceNiveauViseValidator(CompetenceNiveauViseRubricsProvider rubrics) {
        this.rubrics = rubrics;
    }

    /**
     * @param maxLeviers plafond SERVEUR du nombre de leviers.
     * @param bornes     bornes de longueur du sujet
     *                   ({@code skill_prompts.recommended_min/max_words}), ou
     *                   {@code null} quand il n'en declare pas — c'est le cas des
     *                   sujets ORAUX, qui portent une duree et non une fourchette
     *                   de mots.
     * @return les violations rangees par section, toutes vides si conforme.
     */
    public Rapport violations(Map<String, Object> sortie, int maxLeviers,
                              ProductionTextBounds bornes) {
        Map<Section, List<String>> parSection = new EnumMap<>(Section.class);
        for (Section section : Section.values()) {
            parSection.put(section, new ArrayList<>());
        }
        List<String> racine = parSection.get(Section.RACINE);
        if (sortie == null || sortie.isEmpty()) {
            racine.add(VIOLATION_SORTIE_VIDE
                + " : leviers, exemple_cible et a_retenir sont obligatoires");
            return new Rapport(parSection);
        }

        Set<String> vues = new LinkedHashSet<>(sortie.keySet());
        vues.remove(CompetenceNiveauViseFields.LEVIERS);
        vues.remove(CompetenceNiveauViseFields.EXEMPLE_CIBLE);
        vues.remove(CompetenceNiveauViseFields.A_RETENIR);

        validerLeviers(sortie.get(CompetenceNiveauViseFields.LEVIERS), maxLeviers,
            parSection.get(Section.LEVIERS));
        validerExempleCible(sortie.get(CompetenceNiveauViseFields.EXEMPLE_CIBLE), bornes,
            parSection.get(Section.EXEMPLE_CIBLE));
        validerARetenir(sortie.get(CompetenceNiveauViseFields.A_RETENIR),
            parSection.get(Section.A_RETENIR));

        for (String enTrop : vues) {
            racine.add("cle hors contrat : " + enTrop);
        }
        return new Rapport(parSection);
    }

    // ------------------------------------------------------------- leviers

    private void validerLeviers(Object brut, int maxLeviers, List<String> violations) {
        if (!(brut instanceof List<?> liste)) {
            violations.add(CompetenceNiveauViseFields.LEVIERS + " doit etre une liste");
            return;
        }
        if (liste.size() < MIN_LEVIERS) {
            violations.add(CompetenceNiveauViseFields.LEVIERS + " compte " + liste.size()
                + " element(s), il en faut au moins " + MIN_LEVIERS);
        }
        if (liste.size() > maxLeviers) {
            violations.add(CompetenceNiveauViseFields.LEVIERS + " compte " + liste.size()
                + " elements, le maximum est " + maxLeviers);
        }
        int i = 0;
        for (Object item : liste) {
            i++;
            String prefixe = CompetenceNiveauViseFields.LEVIERS + "[" + i + "]";
            Map<String, Object> levier = asMap(item, prefixe, violations);
            if (levier == null) continue;
            champTexte(levier, CompetenceNiveauViseFields.ACTION, prefixe, violations);
            champTexte(levier, CompetenceNiveauViseFields.EXEMPLE, prefixe, violations);
            // LE PROCEDE N'EST PAS JUGE ICI — contrat v3. Il est admis comme cle
            // du contrat, et rien de plus : ni sa presence, ni sa valeur ne sont
            // opposees. Une violation de la section LEVIERS est FATALE, elle
            // emporte le bloc entier ; faire tomber l'ecran d'un candidat parce
            // qu'une etiquette manque serait l'inverse du but recherche. Ce que
            // le procede vaut se compte dans CompetenceNiveauViseProcedeAudit.
            if (rubrics.leviersPortentUnProcede()) {
                clesEnTrop(levier, prefixe, violations,
                    CompetenceNiveauViseFields.ACTION, CompetenceNiveauViseFields.EXEMPLE,
                    CompetenceNiveauViseFields.PROCEDE);
            } else {
                clesEnTrop(levier, prefixe, violations,
                    CompetenceNiveauViseFields.ACTION, CompetenceNiveauViseFields.EXEMPLE);
            }
        }
    }

    // ------------------------------------------------------- exemple cible

    /**
     * L'EXEMPLE CIBLE SE JOUE SUR SON TEXTE, ET SUR LUI SEUL.
     *
     * <p>Seuls le texte modele — presence, forme, <b>longueur</b> — et la forme du
     * bloc sont juges ici : c'est le texte que le candidat vient chercher, et lui
     * seul doit pouvoir faire tomber la section. Les {@code segments} et les
     * {@code marqueurs_du_palier} passent par {@link SegmentsSurlignage}, qui
     * retire ce qu'il ne peut pas rattacher au texte et laisse le texte servi.
     */
    private void validerExempleCible(Object brut, ProductionTextBounds bornes,
                                     List<String> violations) {
        String prefixe = CompetenceNiveauViseFields.EXEMPLE_CIBLE;
        Map<String, Object> bloc = asMap(brut, prefixe, violations);
        if (bloc == null) return;
        if (rubrics.marqueursDuPalierExiges()) {
            clesEnTrop(bloc, prefixe, violations,
                CompetenceNiveauViseFields.TEXTE, CompetenceNiveauViseFields.SEGMENTS,
                CompetenceNiveauViseFields.MARQUEURS_PALIER);
        } else {
            clesEnTrop(bloc, prefixe, violations,
                CompetenceNiveauViseFields.TEXTE, CompetenceNiveauViseFields.SEGMENTS);
        }

        String texte = champTexte(bloc, CompetenceNiveauViseFields.TEXTE, prefixe, violations);
        if (texte != null) validerLongueurTexte(texte, bornes, violations);
    }

    /**
     * LONGUEUR DU TEXTE MODELE — controle DUR, sans tolerance, et <b>plafond
     * seul</b>.
     *
     * <p>La tolerance de 20 % des plafonds pedagogiques ne vaut PAS ici : un
     * levier est une consigne, le texte modele est une PRODUCTION que le candidat
     * est invite a rejouer. C'est ce controle qui manquait : un texte modele de
     * cinquante mots etait servi sur un sujet qui en attend quinze a trente-cinq,
     * et la consigne demandait meme de « garder la longueur » de la production —
     * ce qui, sur vingt-huit mots, est incompatible avec la demonstration d'un
     * palier.
     *
     * <p><b>Seul le plafond est oppose</b>, jamais le plancher : sur un
     * micro-exercice, un texte un peu plus court reste lisible et utile, alors
     * qu'un texte trop long noie le candidat et n'est plus « sa » reponse.
     *
     * <p>Le comptage est celui de la soumission
     * ({@link ProductionPayloadSupport#countWords}) : deux comptages differents
     * suffiraient a laisser passer un texte qu'on refuse par ailleurs.
     */
    private static void validerLongueurTexte(String texte, ProductionTextBounds bornes,
                                             List<String> violations) {
        if (bornes == null) return;
        int mots = ProductionPayloadSupport.countWords(texte);
        if (mots <= bornes.max()) return;
        violations.add(VIOLATION_LONGUEUR + mots + " mots, le sujet en attend "
            + bornes.libelle());
    }

    // ----------------------------------------------------------- a retenir

    private void validerARetenir(Object brut, List<String> violations) {
        String prefixe = CompetenceNiveauViseFields.A_RETENIR;
        Map<String, Object> bloc = asMap(brut, prefixe, violations);
        if (bloc == null) return;
        clesEnTrop(bloc, prefixe, violations,
            CompetenceNiveauViseFields.FORMULE, CompetenceNiveauViseFields.EXPLICATION);
        champTexte(bloc, CompetenceNiveauViseFields.FORMULE, prefixe, violations);
        champTexte(bloc, CompetenceNiveauViseFields.EXPLICATION, prefixe, violations);
    }

    // -------------------------------------------------------------- outils

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
        Integer plafond = rubrics.contraintesLongueur().get(cle);
        if (plafond != null) {
            int max = PlafondMots.tolere(plafond);
            int mots = compterMots(texte);
            if (mots > max) {
                violations.add(chemin + " fait " + mots + " mots, le maximum est " + plafond
                    + " (tolere jusqu'a " + max + ")");
            }
        }
        return texte;
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

    /**
     * Vrai quand ces violations sont TOUTES reparables par un message actionnable
     * — c'est-a-dire mecaniques et nommables. Aujourd'hui une seule l'est : la
     * longueur du texte modele. Une sortie structurellement fausse n'ouvre droit a
     * aucun second appel paye : le bloc reste un confort.
     */
    static boolean uniquementReparables(List<String> violations) {
        return !violations.isEmpty()
            && violations.stream().allMatch(v -> v != null && v.startsWith(VIOLATION_LONGUEUR));
    }

    static int compterMots(String texte) {
        return PlafondMots.compter(texte);
    }
}
