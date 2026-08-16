package com.sejourfr.app.service.competence.niveauvise;

import com.sejourfr.app.util.SegmentsSurlignage;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE LE BLOC « POUR VISER X » PERD EN CHEMIN, compte par motif.
 *
 * <p>Famille de compteurs volontairement <b>separee</b> des autres — les melanger
 * rendrait chacune illisible :
 * <ul>
 *   <li>{@code EvaluationRefusalMetrics} : un <b>refus</b> rejette la sortie du
 *       correcteur et peut couter la tache au candidat ;</li>
 *   <li>{@code EvaluationPurgeMetrics} : une <b>purge</b> retire une phrase d'un
 *       rapport par ailleurs intact ;</li>
 *   <li>{@code VersionCibleeMetrics} : la meme mesure, mais sur le second appel
 *       des <b>productions</b>. Deux ecrans differents, deux compteurs — sinon on
 *       ne saurait plus lequel des deux perd son bloc ;</li>
 *   <li>ici : le bloc de confort du module <b>Competences</b> qui n'arrive pas
 *       jusqu'a l'ecran, un <b>appel de reparation paye</b>, un <b>segment de
 *       surlignage retire</b>. Rien de tout cela ne touche le verdict, le niveau
 *       ni l'analyse.</li>
 * </ul>
 *
 * <p><b>Pourquoi ils existent.</b> Le bloc « pour viser » disparaissait de l'ecran
 * sans qu'on puisse dire combien de candidats le perdaient, ni pourquoi : deux
 * {@code log.warn} et rien d'autre. Aucune des decisions prises dessus (tolerance
 * reelle des petits plafonds, segments rendus facultatifs, comparaison apres
 * normalisation) ne pourra etre jugee sur des chiffres sans eux. C'est la doctrine
 * du depot : un filet muet ne peut ni se durcir ni se desarmer.
 */
@Component
public class CompetenceNiveauViseMetrics {

    /** POURQUOI le bloc est tombe, ou ce qu'une reparation a redemande. */
    public enum Motif {
        /** Sortie vide ou sans aucune des trois cles : rien n'est exploitable. */
        SORTIE_HORS_CONTRAT,
        /** Champ absent, vide, mal type, cle en trop, cardinalite fausse, plafond depasse. */
        STRUCTURE,
        /** Leviers retires par le filet des marqueurs A2, sous leur minimum. */
        PURGE_LEVIERS,
        /**
         * Texte modele au-dela des bornes du sujet
         * ({@code skill_prompts.recommended_max_words}). Seul motif MECANIQUE de la
         * section {@code exemple_cible}, donc le seul qui vaille une reparation.
         */
        TEXTE_HORS_BORNES
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    /**
     * Le bloc ENTIER n'arrive pas a l'ecran : une section FATALE est en defaut
     * (sortie hors contrat, ou leviers — un plan d'action sans levier n'a aucun
     * interet).
     */
    public void blocAbandonne(Motif motif) {
        ajouter("BLOC_ABANDONNE/" + motif.name());
    }

    /**
     * UNE section facultative tombe seule, le reste du bloc etant servi.
     *
     * <p>Ce compteur n'existait pas : le contrat n'avait aucune partie
     * facultative, donc le bloc tombait d'un bloc. Depuis que le texte modele est
     * borde en longueur, un exemple cible inexploitable ne doit plus emporter les
     * leviers ni la tournure a retenir, qui ne dependent d'aucun texte — meme
     * arbitrage que {@code VersionCibleeMetrics.sectionAbandonnee} sur l'ecran des
     * productions.
     */
    public void sectionAbandonnee(CompetenceNiveauViseValidator.Section section, Motif motif) {
        ajouter("SECTION_ABANDONNEE/" + section.name() + "/" + motif.name());
    }

    /**
     * Un MARQUEUR DE PALIER est retire, le texte modele restant servi. C'est la
     * preuve du palier qu'on perd, jamais le texte : un marqueur ne coute que sa
     * propre mise en evidence, comme un segment de surlignage.
     */
    public void marqueurRetire(CompetenceNiveauViseMarqueurFilter.Motif motif) {
        ajouter("MARQUEUR_RETIRE/" + motif.name());
    }

    /**
     * UN LEVIER A ETE SERVI SANS PROCEDE OPPOSABLE — et il a bien ete servi.
     *
     * <p>Contrat v3 : chaque levier declare l'operation de langue qu'il met en
     * œuvre, ce qui est la seule façon fiable d'empecher un conseil de <b>ton</b>
     * (« rends ton invitation plus chaleureuse ») de se faire passer pour un
     * levier de <b>palier</b>. 🛑 Ce compteur ne mesure <b>jamais</b> une purge :
     * un procede manquant, inconnu ou qui sur-vend le palier cible ne coute pas
     * son levier au candidat — les leviers portent le bloc entier, et le vider
     * pour une etiquette serait l'inverse du but. Il ne coute pas non plus un
     * appel de reparation.
     *
     * <p>Sans ce compteur, la contrainte de schema serait invisible : on ne
     * saurait pas si le modele la respecte, donc on ne pourrait ni la durcir ni
     * la desarmer. Aucune ligne n'existe sous les contrats v1 et v2, ou le champ
     * n'est pas demande.
     */
    public void procedeAnormal(CompetenceNiveauViseProcedeAudit.Motif motif) {
        ajouter("PROCEDE_ANORMAL/" + motif.name());
    }

    /** UN appel de reparation a ete paye. Le motif dit ce qu'on a redemande. */
    public void reparationPayee(Motif motif) {
        ajouter("REPARATION/" + motif.name());
    }

    /**
     * Un passage a surligner est retire, le texte modele restant servi. Le motif
     * vient du filet PARTAGE avec les productions : la mecanique du surlignage est
     * commune aux deux surfaces, le comptage reste propre a chacune.
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
     * Motif DOMINANT d'une liste de violations. Une sortie hors contrat prime sur
     * un champ fautif : les deux abandonnent le bloc, mais ne se corrigent pas de
     * la meme façon.
     */
    static Motif motif(List<String> violations) {
        if (violations == null || violations.isEmpty()) return Motif.PURGE_LEVIERS;
        for (String violation : violations) {
            if (violation != null
                && violation.startsWith(CompetenceNiveauViseValidator.VIOLATION_SORTIE_VIDE)) {
                return Motif.SORTIE_HORS_CONTRAT;
            }
        }
        // La longueur ne l'emporte que si TOUTES les violations en relevent :
        // melangee a une faute de structure, c'est la structure qui decide, car
        // c'est elle qui interdit la reparation.
        if (CompetenceNiveauViseValidator.uniquementReparables(violations)) {
            return Motif.TEXTE_HORS_BORNES;
        }
        return Motif.STRUCTURE;
    }
}
