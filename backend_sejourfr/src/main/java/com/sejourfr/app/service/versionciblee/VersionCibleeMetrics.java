package com.sejourfr.app.service.versionciblee;

import com.sejourfr.app.util.SegmentsSurlignage;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE LE PLAN D'ACTION PERD EN CHEMIN, compte par section et par motif.
 *
 * <p>Troisieme famille de compteurs, volontairement <b>separee</b> des deux
 * autres — les melanger rendrait chacune illisible :
 * <ul>
 *   <li>{@code EvaluationRefusalMetrics} : un <b>refus</b> rejette la sortie du
 *       correcteur et peut couter la tache au candidat ;</li>
 *   <li>{@code EvaluationPurgeMetrics} : une <b>purge</b> retire une phrase d'un
 *       rapport par ailleurs intact ;</li>
 *   <li>ici : une <b>section de confort</b> qui n'arrive pas jusqu'a l'ecran, un
 *       <b>appel de reparation paye</b>, un <b>segment de surlignage retire</b>.
 *       Rien de tout cela ne touche la note, le niveau ni l'evaluation.</li>
 * </ul>
 *
 * <p><b>Pourquoi ils existent.</b> La section « Une version plus aboutie »
 * disparaissait par intermittence de l'ecran de resultat, et le depot n'avait que
 * deux {@code log.info} pour l'expliquer : impossible de dire combien de candidats
 * la perdaient, ni pourquoi. Aucune des decisions prises sur ce bloc (tolerance
 * reelle des petits plafonds, segments rendus facultatifs, comparaison apres
 * normalisation) ne pourra etre jugee sur des chiffres sans eux. C'est la doctrine
 * du depot : un filet muet ne peut ni se durcir ni se desarmer.
 */
@Component
public class VersionCibleeMetrics {

    /** POURQUOI quelque chose est tombe. Volontairement grossier. */
    public enum Motif {
        /** Sortie vide, cle inconnue a la racine : rien n'est exploitable. */
        SORTIE_HORS_CONTRAT,
        /** Champ absent, vide, mal type, cle en trop, cardinalite fausse, plafond depasse. */
        STRUCTURE,
        /** Texte modele hors des bornes de la tache — il serait irrecevable a la soumission. */
        TEXTE_HORS_BORNES,
        /** Numero de passage oral inexistant ou deja designe. */
        SEGMENT_HORS_BORNES,
        /** Leviers retires par le filet des marqueurs A2, sous leur minimum. */
        PURGE_LEVIERS,
        /** Reformulations orales retirees par le filet de forme, sous leur minimum. */
        PURGE_REFORMULATIONS
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    /**
     * Une SECTION n'est pas servie. {@code LEVIERS} et {@code RACINE} valent le
     * bloc entier — c'est la seule facon de distinguer « le candidat a perdu son
     * illustration » de « il n'a rien eu du tout ».
     */
    public void sectionAbandonnee(VersionCibleeValidator.Section section, Motif motif) {
        ajouter("SECTION/" + section.name() + "/" + motif.name());
    }

    /** UN appel de reparation a ete paye. Le motif dit ce qu'on a redemande. */
    public void reparationPayee(Motif motif) {
        ajouter("REPARATION/" + motif.name());
    }

    /**
     * Un passage a surligner est retire, le texte modele restant servi. Le motif
     * vient du filet PARTAGE avec le module Competences : la mecanique du
     * surlignage est commune, la <b>famille de compteurs</b> reste propre a
     * chaque surface — sinon on ne saurait plus lequel des deux ecrans perd ses
     * surlignages.
     */
    public void segmentRetire(SegmentsSurlignage.Motif motif) {
        ajouter("SEGMENT_RETIRE/" + motif.name());
    }

    private void ajouter(String cle) {
        compteurs.computeIfAbsent(cle, k -> new LongAdder()).increment();
    }

    /** Compteurs cumules, tries, pour le log. */
    public Map<String, Long> compteurs() {
        Map<String, Long> out = new LinkedHashMap<>();
        compteurs.entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .forEach(e -> out.put(e.getKey(), e.getValue().sum()));
        return out;
    }

    /** Remise a zero — reservee aux tests. */
    public void reset() {
        compteurs.clear();
    }

    /**
     * Motif DOMINANT d'une liste de violations. L'ordre n'est pas alphabetique
     * mais decroissant en gravite : ce qu'on veut lire dans un compteur, c'est la
     * raison pour laquelle une reparation a ete payee ou une section perdue, pas
     * la premiere ligne d'un rapport.
     */
    static Motif motif(List<String> violations) {
        if (violations == null || violations.isEmpty()) return Motif.STRUCTURE;
        for (String violation : violations) {
            if (violation != null
                && violation.startsWith(VersionCibleeValidator.VIOLATION_LONGUEUR)) {
                return Motif.TEXTE_HORS_BORNES;
            }
        }
        for (String violation : violations) {
            if (violation != null
                && violation.startsWith(VersionCibleeValidator.VIOLATION_SEGMENT)) {
                return Motif.SEGMENT_HORS_BORNES;
            }
        }
        return Motif.STRUCTURE;
    }
}
