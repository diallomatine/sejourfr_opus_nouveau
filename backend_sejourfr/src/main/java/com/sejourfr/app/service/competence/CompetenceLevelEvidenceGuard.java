package com.sejourfr.app.service.competence;

import com.sejourfr.app.enums.NiveauCecrl;
import com.sejourfr.app.service.EvaluationProductionSegments;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * REND LE NIVEAU OPPOSABLE : un B1 ou un B2 annonce par le correcteur doit etre
 * <b>demontre</b> par un passage reel de la production, sinon le serveur abaisse.
 *
 * <h2>Le probleme, mesure en base</h2>
 * Le contrat v3 a donne au correcteur un {@code level_reached}, et rien d'autre :
 * le niveau etait <b>nomme a vue</b> sur cinq lignes de descripteurs, sans note,
 * sans seuil, sans ancre chiffree, et surtout <b>sans aucun controle serveur en
 * aval</b>. A l'oppose, une production complete DERIVE son niveau d'une note
 * elle-meme contrainte par un couplage et des plafonds, tous appliques serveur.
 * Deux grandeurs portaient donc le nom de la meme echelle CECRL sans etre
 * commensurables.
 *
 * <h2>La technique : preuve par NUMERO, pas par citation</h2>
 * Le depot a deja resolu ce probleme deux fois, et la lecon est ecrite : la
 * citation litterale a ete le premier poste de refus ({@code PREUVE_NON_RATTACHEE},
 * 42,9 % des appels sur les productions orales), et le contrat v12 des
 * productions l'a remplacee par une <b>designation par numero de segment</b>.
 * On reutilise ici la meme classe de decoupage
 * ({@link EvaluationProductionSegments}) : elle n'est pas recopiee, elle est
 * appelee. Inventer une preuve devient impossible <b>par construction</b> — le
 * seul defaut possible est un entier hors bornes ou un non-entier.
 *
 * <h2>Ce que ce garde-fou peut, et ce qu'il ne peut pas</h2>
 * <ul>
 *   <li>il <b>ne peut qu'ABAISSER</b>, d'un seul palier, une seule fois, et
 *       jamais relever — meme philosophie que {@code applyCouplage},
 *       {@code applyPlafonds}, {@code applyConfiance} et
 *       {@code applyObjectifCoherence}. Un garde-fou qui ne peut qu'abaisser est
 *       un garde-fou sur : au pire il est prudent ;</li>
 *   <li>il <b>ne fait JAMAIS echouer l'analyse</b>. Une analyse perdue coute au
 *       candidat sa production et son quota ; un niveau prudent ne lui coute
 *       qu'un palier d'affichage. C'est la doctrine constante du depot (cf.
 *       {@code EvaluationAccentAudit}, qui mesure sans jamais refuser) ;</li>
 *   <li>il <b>ne sanctionne rien en dessous du B1</b> — voir ci-dessous ;</li>
 *   <li>il n'exige rien quand la production ne produit <b>aucun segment
 *       citable</b> (texte sans le moindre mot) : on ne reproche pas au
 *       correcteur de n'avoir pas designe ce qui n'existe pas.</li>
 * </ul>
 *
 * <h2>L'EFFORT est symetrique, la SANCTION ne l'est pas (contrat v5)</h2>
 * Sous v4, annoncer un B1 ou un B2 coutait un numero de segment, et un numero
 * absent coutait un palier ; annoncer un A2 ne coutait <b>rien</b> et ne risquait
 * <b>rien</b>. Le mecanisme rendait donc le A2 confortable et le B2 risque,
 * quelles que soient les ancres du prompt — mesure en base : zero B2 sur 18
 * tentatives. Depuis v5, le tool-schema exige la preuve <b>a tous les paliers</b>
 * : l'effort de production est le meme partout, et c'est la que vit l'incitation.
 *
 * <p><b>La sanction, elle, reste ou elle protege.</b> Une preuve manquante sur un
 * A2 ne peut pas raisonnablement faire tomber a A1 : ce serait punir la prudence,
 * exactement l'inverse du but. Elle est donc <b>comptee</b>
 * ({@code CompetenceLevelDowngradeMetrics.enregistrerSansSanction}) et jamais
 * appliquee. Elle ne vaut pas non plus de reparation payee : le correcteur ne
 * l'anticipe pas au moment de produire, et payer un appel pour un champ sans
 * consequence serait de l'argent jete.
 *
 * <p>Sous v4 et anterieurs, tout ce paragraphe est <b>inerte</b> : la preuve
 * n'est attendue que sur B1/B2, exactement comme avant.
 *
 * <p><b>Le numero est resolu en texte avant persistance</b> (comme
 * {@code AiEvaluationService.resolvePreuveSegments}) : {@code analysis_json} ne
 * porte jamais l'entier, donc aucun miroir DTO des trois fronts n'a a le
 * transporter. Le passage resolu <b>n'est expose a aucun front</b> : rien ne
 * l'affiche, et une API morte est une dette. Il est en revanche <b>persiste</b>,
 * parce que c'est la seule facon de repondre plus tard, en une requete SQL, a
 * « sur quoi le correcteur a-t-il fonde ce B2 ? ».
 *
 * <p><b>Aucune campagne de mesure n'appuie ce garde-fou et il faut le dire</b> :
 * le corpus de calibration (48 cas) est celui des productions completes, il
 * n'existe aucun corpus pour la voie Competences. Ce qui tient la regle, c'est
 * la contrainte dure — pas une mesure a posteriori.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CompetenceLevelEvidenceGuard {

    /**
     * Les seuls paliers dont un defaut de preuve est <b>SANCTIONNE</b>. Depuis
     * v5 la preuve est attendue partout, mais seule une revendication de B1/B2
     * peut couter un palier : c'est elle qui, non etayee, ferait afficher au
     * candidat un niveau que sa production ne montre pas.
     */
    static final Set<NiveauCecrl> NIVEAUX_A_DEMONTRER = Set.of(NiveauCecrl.B1, NiveauCecrl.B2);

    private final CompetenceLevelDowngradeMetrics metrics;
    private final CompetenceRubricsProvider rubrics;

    /** Ce que le serveur reproche a la preuve, ou {@code null} si elle tient. */
    enum Defaut {
        ABSENTE(CompetenceLevelDowngradeMetrics.Motif.PREUVE_ABSENTE),
        HORS_BORNES(CompetenceLevelDowngradeMetrics.Motif.PREUVE_HORS_BORNES),
        NON_ENTIERE(CompetenceLevelDowngradeMetrics.Motif.PREUVE_NON_ENTIERE);

        final CompetenceLevelDowngradeMetrics.Motif motif;

        Defaut(CompetenceLevelDowngradeMetrics.Motif motif) {
            this.motif = motif;
        }
    }

    /**
     * Ce qu'il faut dire au correcteur pour qu'il repare — jamais le libelle brut
     * de la violation. Le depot a mesure que renvoyer la seule violation ne
     * reparait rien (0 preuve reparee sur 8) : le message doit nommer ce qui a
     * ete refuse, rappeler les bornes REELLES et redonner la regle.
     *
     * @return liste vide quand il n'y a rien a reparer.
     */
    public List<String> violations(Map<String, Object> sortie,
                                   EvaluationProductionSegments segments) {
        // SEULS les paliers sanctionnes valent une reparation. Sous le B1 le
        // defaut ne coute rien au candidat : payer un appel pour le corriger
        // serait de l'argent depense sans contrepartie.
        if (!estSanctionnable(sortie)) return List.of();
        Defaut defaut = defaut(sortie, segments);
        if (defaut == null) return List.of();
        return List.of(libelle(defaut, sortie, segments));
    }

    /**
     * Applique la regle sur la sortie ACCEPTEE (donc apres l'unique reparation) :
     * resout le numero en texte, ou abaisse le niveau d'un palier.
     *
     * <p>La sortie est mutee sur place. Elle n'est jamais rejetee.
     *
     * @return true si le niveau a ete abaisse.
     */
    public boolean applique(Map<String, Object> analyse, EvaluationProductionSegments segments) {
        if (analyse == null) return false;

        // Le defaut se lit AVANT toute mutation, sinon le motif du compteur se
        // reduirait a « absente » : on ne saurait plus distinguer un numero
        // invente d'un champ oublie, donc on ne saurait plus quoi durcir.
        Defaut defaut = defaut(analyse, segments);

        Optional<String> passage = passage(analyse, segments);
        if (passage.isPresent()) {
            // Le numero devient le TEXTE : rien en base ne porte l'entier.
            analyse.put(CompetenceAnalysisFields.LEVEL_EVIDENCE, passage.get());
            return false;
        }
        analyse.remove(CompetenceAnalysisFields.LEVEL_EVIDENCE);

        if (defaut == null) return false;

        NiveauCecrl avant = niveau(analyse);
        if (!aDemontrer(avant)) {
            // Sous le B1 : on MESURE, on ne sanctionne pas. Faire tomber un A2
            // a A1 faute de preuve punirait la prudence, c'est-a-dire
            // exactement le comportement qu'on cherche a rendre confortable.
            metrics.enregistrerSansSanction(defaut.motif, avant);
            log.info("Preuve du niveau refusee sans consequence : palier {} conserve ({}). "
                    + "La sanction reste reservee au B1/B2.", avant, defaut);
            return false;
        }

        NiveauCecrl apres = unPalierEnDessous(avant);
        analyse.put(CompetenceAnalysisFields.LEVEL_REACHED, apres.name());
        metrics.enregistrer(defaut.motif, avant, apres);
        log.warn("Niveau abaisse faute de preuve : {} -> {} ({}, {} segment(s) disponibles). "
                + "Le serveur n'echoue pas et ne releve jamais.",
            avant, apres, defaut, segments == null ? 0 : segments.taille());
        return true;
    }

    // ------------------------------------------------------------------ regle

    /**
     * Le palier annonce est-il de ceux dont un defaut de preuve coute un cran ?
     * Independant de la version du contrat : c'est une question de risque pour
     * le candidat, pas de rang.
     */
    private static boolean estSanctionnable(Map<String, Object> sortie) {
        // `Set.of` est hostile au null : un palier illisible n'est pas
        // sanctionnable, et surtout ne doit pas faire lever ce garde-fou.
        return sortie != null && aDemontrer(niveau(sortie));
    }

    private static boolean aDemontrer(NiveauCecrl niveau) {
        return niveau != null && NIVEAUX_A_DEMONTRER.contains(niveau);
    }

    /**
     * La preuve est-elle attendue pour ce palier ? Sous v5, oui pour les cinq ;
     * sous v4, seulement pour B1 et B2 — c'est ce qui garde le retour arriere
     * reel, un {@code COMPETENCE_TOOL_SCHEMA_VERSION=v4} devant se comporter
     * exactement comme avant.
     */
    private boolean preuveAttendue(NiveauCecrl niveau) {
        if (CompetenceAnalysisFields.exigeLaPreuveSurTousLesPaliers(
                rubrics.getToolSchemaVersion())) {
            return true;
        }
        return aDemontrer(niveau);
    }

    /**
     * @return le defaut a reprocher, ou {@code null} quand il n'y a rien a
     *         exiger (palier dispense par le contrat, production sans segment
     *         citable) ou quand la preuve tient.
     */
    private Defaut defaut(Map<String, Object> sortie, EvaluationProductionSegments segments) {
        if (sortie == null) return null;
        NiveauCecrl niveau = niveau(sortie);
        if (niveau == null || !preuveAttendue(niveau)) return null;
        if (segments == null || segments.taille() < 1) return null;

        Object brut = sortie.get(CompetenceAnalysisFields.LEVEL_EVIDENCE);
        if (brut == null) return Defaut.ABSENTE;

        Integer numero = numero(brut);
        if (numero == null) return Defaut.NON_ENTIERE;
        return segments.texte(numero).isPresent() ? null : Defaut.HORS_BORNES;
    }

    /** Passage designe, s'il est resolvable — quel que soit le niveau annonce. */
    private static Optional<String> passage(Map<String, Object> sortie,
                                            EvaluationProductionSegments segments) {
        if (segments == null) return Optional.empty();
        Integer numero = numero(sortie.get(CompetenceAnalysisFields.LEVEL_EVIDENCE));
        return numero == null ? Optional.empty() : segments.texte(numero);
    }

    /**
     * Un numero de segment est un ENTIER. Un decimal, une chaine ou un booleen
     * n'en est pas un ; en revanche {@code "2"} rendu comme chaine par un
     * fournisseur qui serialise mal reste un 2 — refuser la sortie sur une
     * question de type de JSON couterait une analyse pour rien.
     */
    private static Integer numero(Object brut) {
        if (brut instanceof Integer i) return i;
        if (brut instanceof Number n) {
            double d = n.doubleValue();
            return d == Math.floor(d) && !Double.isInfinite(d) ? (int) d : null;
        }
        if (brut instanceof String s) {
            try {
                return Integer.valueOf(s.trim());
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    private static NiveauCecrl niveau(Map<String, Object> sortie) {
        Object brut = sortie.get(CompetenceAnalysisFields.LEVEL_REACHED);
        if (brut == null) return null;
        try {
            return NiveauCecrl.valueOf(brut.toString().trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /**
     * UN palier, jamais deux, et jamais en dessous du plancher. B2 sans preuve
     * redescend en B1 : on retire ce qui n'est pas montre, on ne punit pas.
     */
    private static NiveauCecrl unPalierEnDessous(NiveauCecrl niveau) {
        int rang = Math.max(0, niveau.ordinal() - 1);
        return NiveauCecrl.values()[rang];
    }

    // ------------------------------------------------------------- reparation

    private static String libelle(Defaut defaut, Map<String, Object> sortie,
                                  EvaluationProductionSegments segments) {
        int taille = segments.taille();
        String niveau = String.valueOf(sortie.get(CompetenceAnalysisFields.LEVEL_REACHED));
        return switch (defaut) {
            case ABSENTE -> "level_evidence est absent alors que tu annonces " + niveau
                + " : ce palier doit etre demontre par un segment de la production "
                + "(numero entre 1 et " + taille + ")";
            case HORS_BORNES -> "level_evidence vaut "
                + sortie.get(CompetenceAnalysisFields.LEVEL_EVIDENCE)
                + ", qui ne designe aucun segment de cette production : les numeros vont de 1 a "
                + taille;
            case NON_ENTIERE -> "level_evidence doit etre un ENTIER (le numero d'un segment, "
                + "entre 1 et " + taille + "), pas "
                + apercu(sortie.get(CompetenceAnalysisFields.LEVEL_EVIDENCE));
        };
    }

    private static String apercu(Object valeur) {
        String texte = String.valueOf(valeur);
        return texte.length() > 60 ? "« " + texte.substring(0, 60) + "… »" : "« " + texte + " »";
    }
}
