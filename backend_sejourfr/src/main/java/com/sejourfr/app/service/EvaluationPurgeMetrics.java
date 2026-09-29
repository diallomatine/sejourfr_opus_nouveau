package com.sejourfr.app.service;

import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.LongAdder;

/**
 * CE QUE NOS FILETS DE RESTITUTION RETIRENT, compte par filet.
 *
 * <p>Pendant du {@link EvaluationRefusalMetrics}, pour l'autre famille de
 * controles serveur. La distinction est volontaire et ne doit pas etre effacee :
 * <ul>
 *   <li>un <b>refus</b> ({@code EvaluationRefusalMetrics}) rejette la sortie du
 *       correcteur et peut coûter la tache au candidat — c'est lui que le banc
 *       rapporte en {@code sorties_refusees_pct} ;</li>
 *   <li>une <b>purge</b> (ici) ne rejette rien : elle retire une remarque du
 *       rapport et laisse la note, le niveau et l'evaluation intacts.</li>
 * </ul>
 * Les melanger fausserait la seule metrique qui decrit ce que vit un candidat.
 *
 * <p>Sans ce compteur, un filet est muet : on ne sait pas s'il agit une fois par
 * an ou sur une evaluation sur deux, donc on ne peut ni le durcir ni le desarmer
 * sur des chiffres. C'est la doctrine du depot.
 */
@Component
public class EvaluationPurgeMetrics {

    /** Quel filet a retire quelque chose. */
    public enum Filtre {
        /** Reproche adosse a UN mot de la transcription automatique. */
        ARTEFACT_ORAL_MOT,
        /** Reproche d'avoir parle une autre langue, produit par le transcripteur. */
        ARTEFACT_ORAL_LANGUE,
        /**
         * Reproche de GRAMMAIRE portant sur la forme d'un ou deux mots, la ou une
         * faute orale est une structure. Compte a part de
         * {@link #ARTEFACT_ORAL_MOT} : ce volet-la est le seul a purger des
         * reproches qui peuvent etre justes, et c'est ce compteur qui dira s'il
         * coute trop cher.
         */
        ARTEFACT_ORAL_FORME,
        /**
         * Meme defaut, AUTRE VOIE : un reproche du DIAGNOSTIC oral bati sur la
         * forme d'un ou deux mots de la transcription. Le diagnostic bifurque sur
         * son propre pipeline ({@code production_submissions.is_diagnostic}) et
         * ne traverse aucun filet de {@code AiEvaluationService} : il rendait donc
         * des reproches d'artefact que la voie standard purge depuis 2026-08-09
         * (verbatim reel : « « horreurs » pour « horaires » est une erreur
         * lexicale »).
         *
         * <p>Compte a part de {@link #ARTEFACT_ORAL_FORME} pour la raison qui
         * separe deja les quatre surfaces de {@code MARQUEUR_PALIER*} : le
         * contrat, le service et l'appel LLM sont differents, les melanger
         * empecherait de dire laquelle des deux voies derive. Et c'est le seul
         * volet qui purge SANS pouvoir se limiter au critere de grammaire : le
         * diagnostic n'a pas d'axe de criteres, ses observations sont des
         * competences — d'ou l'interet de le mesurer separement.
         */
        ARTEFACT_ORAL_FORME_DIAGNOSTIC,
        /** Marqueur classe A2 vendu comme le levier d'un palier superieur. */
        MARQUEUR_PALIER,
        /**
         * Meme defaut, autre surface : un levier {@code version_ciblee.ce_qui_manque}
         * qui designe un moyen A2 comme la marche vers le palier VISE. Compte a
         * part de {@link #MARQUEUR_PALIER} parce que le contrat, le service et
         * l'appel LLM sont differents : les melanger empecherait de dire laquelle
         * des deux surfaces derive.
         */
        MARQUEUR_PALIER_LEVIER,
        /**
         * Meme defaut, TROISIEME surface : un levier {@code pour_viser.leviers} du
         * module Competences qui designe un moyen A2 comme la marche vers le
         * palier VISE. Compte a part de {@link #MARQUEUR_PALIER_LEVIER} parce que
         * le contrat, le service et l'appel LLM sont differents : les melanger
         * empecherait de dire laquelle des surfaces derive.
         */
        MARQUEUR_PALIER_LEVIER_COMPETENCE,
        /**
         * Meme defaut, QUATRIEME surface : l'{@code apport} d'un passage surligne
         * du bloc « avant / apres » du diagnostic, qui presente un moyen A2 comme
         * ce que la reecriture apporte vers un palier superieur. Compte a part des
         * trois autres pour la meme raison : le contrat, le service et l'appel LLM
         * sont differents, les melanger empecherait de dire laquelle des surfaces
         * derive. Ici la purge retire le SEGMENT, jamais le texte reecrit.
         */
        MARQUEUR_PALIER_APPORT_DIAGNOSTIC,
        /**
         * Reformulation ORALE de {@code version_ciblee} dont tout l'apport tenait
         * a la forme d'un ou deux mots. Meme regle que
         * {@link #ARTEFACT_ORAL_FORME} ({@code EvaluationOralForme}), autre
         * surface : la premiere purge un reproche du correcteur, celle-ci retire
         * un conseil d'un second appel. Les melanger empecherait de dire laquelle
         * des deux derive.
         */
        REFORMULATION_ORALE_FORME
    }

    private final Map<String, LongAdder> compteurs = new ConcurrentHashMap<>();

    /**
     * @param remarques nombre de PHRASES retirees
     * @param entrees   nombre d'ENTREES de liste supprimees entierement
     */
    public void enregistrer(Filtre filtre, int remarques, int entrees) {
        if (remarques > 0) ajouter(filtre.name() + "/remarques", remarques);
        if (entrees > 0) ajouter(filtre.name() + "/entrees", entrees);
    }

    private void ajouter(String cle, int n) {
        compteurs.computeIfAbsent(cle, k -> new LongAdder()).add(n);
    }

    /** Compteurs cumules {@code "FILTRE/quoi" -> n}, tries, pour le log. */
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
}
