package com.sejourfr.app.service.diagnostic;

import com.sejourfr.app.enums.EpreuveType;
import com.sejourfr.app.service.EvaluationOralForme;
import com.sejourfr.app.service.EvaluationPurgeMetrics;
import com.sejourfr.app.service.EvaluationTexte;
import com.sejourfr.app.service.TranscriptionQualityAudit;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * FILET DETERMINISTE du volet ORAL du DIAGNOSTIC : il retire du rapport les
 * reproches batis sur un mot que NOTRE transcription a fabrique.
 *
 * <h2>Le trou qu'il bouche</h2>
 * Le diagnostic bifurque tres tot ({@code production_submissions.is_diagnostic})
 * vers {@link DiagnosticProductionAnalysisService} et ne traverse <b>aucun</b>
 * des filets de {@code AiEvaluationService} — ni le volet FORME oral, ni le
 * garde-fou de langue etrangere, ni le filet marqueurs A2. Verbatim reel, sur
 * une session jouee : le candidat avait dit « horaires », la transcription a
 * rendu « horreurs », et l'observation {@code EO2-C3} lui reprochait
 * <i>« « horreurs » pour « horaires » est une erreur lexicale qui peut
 * gener »</i>. On lui imputait un defaut de notre chaine technique, sur le tout
 * premier ecran du produit.
 *
 * <h2>Pourquoi la regle des productions ne se transpose pas telle quelle</h2>
 * Sur une production complete, le volet FORME ne s'applique qu'au critere
 * {@code morphosyntaxe} et ne touche <b>jamais</b> {@code lexique} : la meme
 * mesure y produit des faux positifs reels ({@code chronoposte}, {@code ESN}).
 * <b>Le diagnostic n'a pas cet axe</b> : ses observations sont des competences
 * ({@code EO2-C3}...), pas des criteres, il n'y a donc rien sur quoi restreindre.
 *
 * <p>Arbitrage du proprietaire, applique ici : sur le volet ORAL du diagnostic,
 * un reproche dont toute la substance est <b>une forme de mot</b> est purge
 * <b>meme s'il se dit lexical</b>, parce que les deux lectures possibles menent
 * a la meme conclusion — soit notre transcripteur a mal entendu, soit le
 * candidat a mal prononce, et la grille nous interdit deja de noter la
 * prononciation. Le cout est assume et le compteur dedie
 * ({@link EvaluationPurgeMetrics.Filtre#ARTEFACT_ORAL_FORME_DIAGNOSTIC}) est la
 * pour le mesurer.
 *
 * <h2>Ce qu'il ne touche JAMAIS</h2>
 * <ul>
 *   <li><b>l'ECRIT.</b> Le diagnostic a deux productions ; l'ecrite ne subit
 *       rien. A l'ecrit le candidat tape chaque mot : l'asymetrie vient de la
 *       machine, pas du niveau exige ;</li>
 *   <li><b>aucun verdict</b> : ni {@code status}, ni {@code priority}, ni
 *       {@code level_estimate}, ni {@code task_completion}, ni
 *       {@code communication_status}, ni {@code confidence}, ni l'ordre des
 *       priorites. On retire une PHRASE, pas un jugement ;</li>
 *   <li><b>aucune observation n'est supprimee</b> : une explication entierement
 *       purgee laisse l'observation en place, sans explication. Le champ est
 *       nullable de bout en bout ({@code learning_plan_observations.explanation},
 *       {@code DiagnosticSkillObservationDto.explanation}) ;</li>
 *   <li><b>{@code strengths}</b> : un point fort n'est pas un reproche, et le
 *       marqueur de reproche ne l'atteint pas. On ne prend pas le risque
 *       d'effacer un compliment ;</li>
 *   <li><b>{@code evidence}</b> : le passage cite est la preuve, resolue par le
 *       serveur depuis un numero de segment. La retirer rendrait le reste
 *       incomprehensible.</li>
 * </ul>
 *
 * <h2>Une purge ne peut pas faire echouer une analyse</h2>
 * Deux raisons, cumulatives et structurelles :
 * <ol>
 *   <li><b>l'emplacement</b> — il tourne <b>apres</b>
 *       {@code DiagnosticAnalysisValidator}, sur la sortie deja validee et
 *       normalisee. Il n'est appele par aucun validateur, et rien ne revalide
 *       apres lui. Le mettre dans le validateur aurait rendu une session
 *       {@code FAILED} sur une purge — exactement le defaut qui a deja detruit
 *       un diagnostic reel (cf. {@link DiagnosticAnalysisReconciler}) ;</li>
 *   <li><b>le contrat de la methode</b> — {@link #purge} ne leve jamais : toute
 *       exception est avalee et journalisee, la sortie repart telle quelle.</li>
 * </ol>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DiagnosticOralArtifactFilter {

    /**
     * Remplace un {@code summary} entierement purge. Ce champ pilote le haut de
     * l'ecran de resultat et ne peut pas rester vide : on ne le supprime pas, on
     * le remplace — meme pratique que les commentaires de remplacement du filet
     * des productions.
     *
     * <p><b>Il RASSURE, il n'explique plus.</b> C'est le premier ecran de
     * quelqu'un qui decouvre son niveau : la premiere phrase lui dit que son
     * travail a bien ete traite, la seconde lui dit ce qui le concerne — des
     * remarques ont ete ecartees, et ce n'etait pas de sa faute. Notre mecanique
     * de filtrage n'y figure plus : elle ne lui apprend rien et sa trace vit dans
     * {@link EvaluationPurgeMetrics.Filtre#ARTEFACT_ORAL_FORME_DIAGNOSTIC}.
     * Meme mouvement que les trois avertissements de l'ecran de resultat d'une
     * production orale, ramenes a un seul.
     */
    static final String SUMMARY_PURGE =
            "Votre production a bien été analysée. Certaines remarques portaient sur la "
                    + "transcription, pas sur vous : elles n'ont pas été retenues.";

    private final EvaluationPurgeMetrics purgeMetrics;

    /**
     * Purge en place les champs de restitution d'une analyse diagnostique ORALE.
     *
     * <p><b>Ne leve jamais.</b> Un incident de filtrage ne doit pas coûter au
     * candidat sa session : dans le pire des cas le rapport repart non filtre.
     *
     * @param analysis   sortie deja validee et normalisee, modifiee en place
     * @param epreuve    epreuve de la tache ; tout sauf {@link EpreuveType#TCF_EO}
     *                   ressort intact
     * @param production transcription servie au correcteur (tours recolles)
     */
    public void purge(Map<String, Object> analysis, EpreuveType epreuve, String production) {
        if (epreuve != EpreuveType.TCF_EO) return;
        if (analysis == null || analysis.isEmpty()) return;
        if (production == null || production.isBlank()) return;
        try {
            appliquer(analysis, production);
        } catch (RuntimeException e) {
            // Volontairement avale : cf. javadoc de classe. Une purge est un
            // confort de restitution, jamais une condition de validite.
            log.warn("Filet oral du diagnostic inoperant, rapport servi tel quel : {}",
                    e.toString());
        }
    }

    private void appliquer(Map<String, Object> analysis, String production) {
        boolean degradee = TranscriptionQualityAudit.degradee(production);
        int remarques = 0;
        int entrees = 0;

        if (analysis.get("summary") instanceof String summary) {
            Purge purge = purgerPhrases(summary, production, degradee);
            if (purge.retirees() > 0) {
                remarques += purge.retirees();
                analysis.put("summary", purge.reste().isBlank() ? SUMMARY_PURGE : purge.reste());
            }
        }

        if (analysis.get("weaknesses") instanceof List<?> weaknesses) {
            List<Object> gardees = new ArrayList<>();
            for (Object raw : weaknesses) {
                if (!(raw instanceof String valeur)) {
                    gardees.add(raw);
                    continue;
                }
                Purge purge = purgerPhrases(valeur, production, degradee);
                if (purge.retirees() == 0) {
                    gardees.add(raw);
                    continue;
                }
                remarques += purge.retirees();
                // Une faiblesse reduite a rien n'a plus rien a dire : on la
                // retire plutot que de servir une phrase amputee.
                if (purge.reste().isBlank()) entrees++;
                else gardees.add(purge.reste());
            }
            analysis.put("weaknesses", gardees);
        }

        if (analysis.get("skills") instanceof List<?> skills) {
            for (Object raw : skills) {
                if (!(raw instanceof Map<?, ?> skill)) continue;
                if (!(skill.get("explanation") instanceof String explanation)) continue;
                Purge purge = purgerPhrases(explanation, production, degradee);
                if (purge.retirees() == 0) continue;
                remarques += purge.retirees();
                // L'OBSERVATION SURVIT SANS SON EXPLICATION. On ne retire jamais
                // l'entree : son status, sa priorite et sa confiance sont le
                // jugement, et le jugement ne bouge pas.
                @SuppressWarnings("unchecked")
                Map<String, Object> mutable = (Map<String, Object>) skill;
                mutable.put("explanation", purge.reste());
            }
        }

        purgeMetrics.enregistrer(
                EvaluationPurgeMetrics.Filtre.ARTEFACT_ORAL_FORME_DIAGNOSTIC, remarques, entrees);
        if (remarques > 0 || entrees > 0) {
            log.info("Diagnostic oral : {} remarque(s) et {} entree(s) retirees "
                    + "(reproche adosse a une forme de la transcription).", remarques, entrees);
        }
    }

    /**
     * Retire les PHRASES qui ne tiennent que par un reproche adosse a une forme
     * de la transcription ; les autres sont recopiees telles quelles. Le
     * decoupage est celui de {@link EvaluationTexte#phrases(String)} et la regle
     * celle de {@link EvaluationOralForme} : deux surfaces qui purgent « la
     * phrase, pas le champ » doivent lire un texte de la meme facon.
     */
    private static Purge purgerPhrases(String texte, String production, boolean degradee) {
        if (texte == null || texte.isBlank()) return new Purge(texte == null ? "" : texte, 0);
        List<String> gardees = new ArrayList<>();
        int retirees = 0;
        for (String phrase : EvaluationTexte.phrases(texte)) {
            if (EvaluationOralForme.reprocheAncreSurUneForme(phrase, production, degradee)) {
                retirees++;
            } else {
                gardees.add(phrase.strip());
            }
        }
        if (retirees == 0) return new Purge(texte, 0);
        return new Purge(String.join(" ", gardees).strip(), retirees);
    }

    /** Ce qui reste d'un champ, et combien de phrases en sont parties. */
    private record Purge(String reste, int retirees) {}
}
