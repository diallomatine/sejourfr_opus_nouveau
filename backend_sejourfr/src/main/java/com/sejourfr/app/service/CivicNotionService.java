package com.sejourfr.app.service;

import com.sejourfr.app.dto.CivicNotionDto;
import com.sejourfr.app.dto.QuestionTaggingDto;
import com.sejourfr.app.entity.CivicNotion;
import com.sejourfr.app.enums.NotionSuggestionVerdict;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.CivicNotionManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * <b>Le referentiel de notions civiques et son tagging</b> (lot L8).
 *
 * <h2>Ce que ce service refuse de faire</h2>
 * <ul>
 *   <li>🛑 <b>Appliquer un seuil de couverture.</b> La regle de {@code 50_}
 *       §6.1 degrade <b>par notion ET par mention</b> : une notion peut etre
 *       pleinement utilisable pour un candidat NAT et seulement visible en
 *       revision pour un CSP. Rendre un verdict global effacerait exactement
 *       cette nuance. On sert les comptes ; l'appelant tranche pour SA
 *       mention.</li>
 *   <li>🛑 <b>Compter une suggestion comme une couverture.</b> Une proposition
 *       de machine n'est pas un tag. Elles sont servies a part, et c'est
 *       volontairement visible.</li>
 *   <li>🛑 <b>Fusionner ou scinder tout seul.</b> {@code 50_} §6.1.3 :
 *       « Aucune fusion ni scission n'est appliquee automatiquement : le job
 *       propose, un humain valide. »</li>
 *   <li>🛑 <b>Appliquer une suggestion.</b> Aucun chemin, ici ni ailleurs, ne
 *       recopie une suggestion vers {@code questions.civic_notion_id} sans un
 *       geste humain qui nomme la notion retenue.</li>
 *   <li>🛑 <b>Appeler un LLM.</b> Rien ici n'en emet, et la table de
 *       suggestions reste vide tant que le proprietaire n'a pas autorise la
 *       depense.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CivicNotionService {

    private final CivicNotionManager manager;

    /** Le referentiel, avec la couverture <b>mesuree</b> de chaque notion. */
    @Transactional(readOnly = true)
    public List<CivicNotionDto> referentiel() {
        Map<UUID, Map<String, Long>> couverture = new LinkedHashMap<>();
        for (Object[] row : manager.couvertureParNotionEtMention()) {
            UUID notionId = (UUID) row[0];
            couverture.computeIfAbsent(notionId, k -> new LinkedHashMap<>())
                    .merge(String.valueOf(row[1]), ((Number) row[2]).longValue(), Long::sum);
        }
        Map<UUID, Long> suggestions = new LinkedHashMap<>();
        for (Object[] row : manager.suggestionsParNotion()) {
            suggestions.put((UUID) row[0], ((Number) row[1]).longValue());
        }

        List<CivicNotionDto> out = new ArrayList<>();
        for (CivicNotion notion : manager.findAllOrdonnees()) {
            Map<String, Long> parMention =
                    couverture.getOrDefault(notion.getId(), Map.of());
            List<CivicNotionDto.CouvertureMention> mentions = parMention.entrySet().stream()
                    .map(e -> new CivicNotionDto.CouvertureMention(e.getKey(), e.getValue()))
                    .sorted(Comparator.comparing(
                            CivicNotionDto.CouvertureMention::mention))
                    .toList();
            out.add(new CivicNotionDto(
                    notion.getId(),
                    notion.getCode(),
                    notion.getLabel(),
                    notion.getDescription(),
                    notion.getThemeCode(),
                    notion.getDisplayOrder(),
                    notion.isActive(),
                    notion.getMergedInto() == null ? null : notion.getMergedInto().getCode(),
                    mentions.stream()
                            .mapToLong(CivicNotionDto.CouvertureMention::questions).sum(),
                    mentions,
                    suggestions.getOrDefault(notion.getId(), 0L)));
        }
        return out;
    }

    /**
     * La file de tagging : ce qu'il reste a faire, la question <b>entiere</b>,
     * et ce qu'une machine proposait le cas echeant.
     *
     * <p>🛑 Les suggestions accompagnent, elles ne decident pas. Aucune n'est
     * pre-selectionnee : un tag valide est toujours un geste humain.
     *
     * <p>🛑 <b>La file ne propose que des questions de CONNAISSANCE</b> : les
     * mises en situation relevent des domaines {@code sit_*} ({@code 50_} §6.2)
     * et ne recoivent pas de notion. Une question deja taguee reste visible quel
     * que soit son type, pour qu'une erreur puisse etre defaite.
     *
     * @param theme  code de theme, ou {@code null} pour tous
     * @param tagged {@code false} = la file de travail ; {@code null} = les deux
     */
    @Transactional(readOnly = true)
    public FileDeTagging fileDeTagging(
            String theme, Boolean tagged, Boolean suggerees, int limit, int offset) {
        List<Object[]> rows = manager.fileDeTagging(theme, tagged, suggerees, limit, offset);
        List<UUID> ids = rows.stream().map(r -> (UUID) r[0]).toList();

        Map<UUID, List<QuestionTaggingDto.Suggestion>> suggestions = new LinkedHashMap<>();
        for (Object[] row : manager.suggestionsParQuestions(ids)) {
            suggestions.computeIfAbsent((UUID) row[0], k -> new ArrayList<>())
                    // 🛑 `notionCode` / `notionLabel` NULS quand le modele a
                    // conclu « aucune notion ne convient » (V057). Aucune
                    // sentinelle : une chaine « AUCUNE » finirait par
                    // s'afficher telle quelle, et le front ne pourrait plus
                    // distinguer sans deviner.
                    .add(new QuestionTaggingDto.Suggestion(
                            row[1] == null ? null : String.valueOf(row[1]),
                            row[2] == null ? null : String.valueOf(row[2]),
                            ((Number) row[3]).doubleValue(),
                            row[4] == null ? null : String.valueOf(row[4]),
                            row[5] == null ? null : String.valueOf(row[5])));
        }

        Map<UUID, List<QuestionTaggingDto.Choix>> choix = new LinkedHashMap<>();
        for (Object[] row : manager.choixDesQuestions(ids)) {
            choix.computeIfAbsent((UUID) row[0], k -> new ArrayList<>())
                    .add(new QuestionTaggingDto.Choix(
                            String.valueOf(row[1]), (Boolean) row[2]));
        }

        List<QuestionTaggingDto> questions = rows.stream()
                .map(row -> new QuestionTaggingDto(
                        (UUID) row[0],
                        String.valueOf(row[1]),
                        row[2] == null ? null : String.valueOf(row[2]),
                        choix.getOrDefault((UUID) row[0], List.of()),
                        String.valueOf(row[3]),
                        String.valueOf(row[4]),
                        row[5] == null ? null : String.valueOf(row[5]),
                        row[6] == null ? null : String.valueOf(row[6]),
                        suggestions.getOrDefault((UUID) row[0], List.of())))
                .toList();

        return new FileDeTagging(questions, manager.resteATaguer());
    }

    /**
     * @param resteATaguer questions civiques de CONNAISSANCE actives encore sans
     *                     notion, TOUS themes — jamais les mises en situation,
     *                     qui ne se taguent pas par notion
     */
    public record FileDeTagging(
            List<QuestionTaggingDto> questions,
            long resteATaguer) {}

    /**
     * Pose ou efface le tag <b>valide</b> d'une question.
     *
     * <p>Forme historique, conservee telle quelle : {@code notionCode} pose le
     * tag, {@code null} l'efface. 🛑 <b>Retrocompatibilite</b> — un client qui
     * n'envoie qu'un {@code notionCode} doit continuer de marcher exactement
     * comme avant V054.
     */
    @Transactional
    public NotionSuggestionVerdict taguer(UUID questionId, String notionCode) {
        return relire(questionId, notionCode, null, null);
    }

    /**
     * <b>La relecture d'une question de la file</b> : quatre gestes, quatre
     * etats distincts (V054).
     *
     * <table>
     *   <tr><th>geste</th><th>{@code civic_notion_id}</th><th>suggestions</th></tr>
     *   <tr><td>notion retenue = la mieux notee</td><td>posee</td><td>{@code VALIDATED}</td></tr>
     *   <tr><td>autre notion retenue</td><td>posee</td><td>{@code CORRECTED}</td></tr>
     *   <tr><td>{@code CONFIRM_NONE}</td><td>intacte</td><td>{@code VALIDATED}</td></tr>
     *   <tr><td>{@code REJECTED}</td><td>intacte</td><td>{@code REJECTED}</td></tr>
     *   <tr><td>{@code SKIPPED}</td><td>intacte</td><td>{@code SKIPPED}</td></tr>
     * </table>
     *
     * <h3>Les quatre gestes sur une suggestion « aucune notion » (V057)</h3>
     *
     * <table>
     *   <tr><th>geste du relecteur</th><th>requete</th><th>stocke</th><th>tag pose</th></tr>
     *   <tr><td><b>Valider</b> (« il y a bien un trou »)</td>
     *       <td>{@code CONFIRM_NONE}</td><td>{@code VALIDATED}</td><td>non</td></tr>
     *   <tr><td><b>Corriger</b> (« si, c'est cette notion-la »)</td>
     *       <td>{@code {notionCode: X}}</td><td>{@code CORRECTED}</td><td>oui</td></tr>
     *   <tr><td><b>Rejeter</b></td>
     *       <td>{@code REJECTED}</td><td>{@code REJECTED}</td><td>non</td></tr>
     *   <tr><td><b>Passer</b></td>
     *       <td>{@code SKIPPED}</td><td>{@code SKIPPED}</td><td>non</td></tr>
     * </table>
     *
     * <p>⚠️ <b>Corriger depuis une suggestion « aucune » donne bien
     * {@code CORRECTED}</b> : le modele s'etait trompe. La comparaison le fait
     * seule — poser une notion alors que la meilleure suggestion ne designe
     * aucune notion, ce sont deux choses differentes.
     *
     * <p>🛑 <b>SEULS {@code VALIDATED} et {@code CORRECTED} posent une
     * notion.</b> Rejeter et passer ne touchent jamais la question : rejeter dit
     * « aucune notion suggeree ne convient », passer dit « je ne tranche pas » —
     * ni l'un ni l'autre n'est un tag, et la question reste dans la file.
     *
     * <p>🛑 <b>Le serveur decide seul de {@code VALIDATED} vs
     * {@code CORRECTED}</b>, en comparant la notion retenue a la suggestion la
     * mieux notee. C'est la metrique de qualite du pre-tagging : un client qui
     * pourrait l'annoncer pourrait la mentir. Un client qui l'envoie quand meme
     * est refuse, plutot qu'ignore en silence.
     *
     * <p>🛑 <b>{@code notionCode} nul efface</b> : se tromper doit rester
     * rattrapable depuis l'ecran, sans passer par la base. Effacer ne dit pas
     * « cette question n'a pas de notion », mais « elle attend a nouveau ».
     *
     * <p>Une notion <b>desactivee</b> (fusionnee) est refusee : la poser
     * recreerait du travail a defaire au tour suivant.
     *
     * @param verdictDemande {@code null} ou {@code "TAG"} pour poser la notion,
     *                       {@code "CONFIRM_NONE"} pour confirmer qu'aucune ne
     *                       convient, {@code "REJECTED"} / {@code "SKIPPED"}
     *                       pour marquer sans poser
     * @param relecteurId    qui tranche, ou {@code null} pour une relecture
     *                       faite hors ecran (script, reprise) — on ne lui
     *                       invente pas un auteur
     * @return le verdict REELLEMENT inscrit, ou {@code null} quand il n'y avait
     *         rien a inscrire (effacement, ou aucune suggestion en base)
     */
    @Transactional
    public NotionSuggestionVerdict relire(UUID questionId, String notionCode,
                                          String verdictDemande, UUID relecteurId) {
        String demande = verdictDemande == null || verdictDemande.isBlank()
                ? null : verdictDemande.trim().toUpperCase();
        boolean tagExplicite = NotionSuggestionVerdict.DEMANDE_TAG.equals(demande);

        if (NotionSuggestionVerdict.DEMANDE_CONFIRM_NONE.equals(demande)) {
            return confirmerAucuneNotion(questionId, notionCode, relecteurId);
        }

        NotionSuggestionVerdict marquage =
                demande == null || tagExplicite ? null : verdictSansTag(demande);

        if (marquage != null) {
            return marquerSansPoser(questionId, notionCode, marquage, relecteurId);
        }

        CivicNotion notion = resoudreNotion(notionCode);
        if (notion == null) {
            if (tagExplicite) {
                // « TAG » sans notion n'est pas un effacement : c'est une
                // demande incomplete, et la traiter comme un effacement
                // supprimerait un tag que personne n'a demande de retirer.
                throw new BusinessException(
                        "Un verdict « TAG » exige la notion retenue.");
            }
            effacer(questionId);
            return null;
        }

        poser(questionId, notion);
        // 🛑 Deduit ici, jamais recu : c'est LA mesure du pre-tagging.
        CivicNotionManager.MeilleureSuggestion meilleure =
                manager.meilleureSuggestion(questionId);
        if (!meilleure.existe()) {
            // Aucune campagne n'a tourne sur cette question : il n'y a rien a
            // qualifier. L'etat NORMAL aujourd'hui, pas une anomalie.
            log.info("Tagging civique : question={} notion={} (sans suggestion)",
                    questionId, notionCode);
            return null;
        }
        // 🛑 `designe` est faux quand la meilleure suggestion conclut « aucune
        // notion » : poser une notion la-dessus CORRIGE le modele, ca ne le
        // valide pas.
        NotionSuggestionVerdict verdict = meilleure.designe(notion.getId())
                ? NotionSuggestionVerdict.VALIDATED
                : NotionSuggestionVerdict.CORRECTED;
        int marquees = manager.marquerVerdict(questionId, verdict, relecteurId);
        log.info("Tagging civique : question={} notion={} verdict={} suggestions={}",
                questionId, notionCode, verdict, marquees);
        return verdict;
    }

    /**
     * <b>{@code CONFIRM_NONE}</b> — le relecteur confirme qu'aucune notion ne
     * convient reellement : il est d'accord avec le modele (V057).
     *
     * <p>🛑 <b>Le serveur stocke {@code VALIDATED}</b>, parce que la
     * proposition du modele — « aucune » — etait juste. C'est exactement ce qui
     * rend la metrique mesurable : sans ce geste, confirmer un trou du
     * referentiel n'ecrivait rien, et un modele qui dit « non » a raison ne se
     * distinguait pas d'un modele qu'on ignore.
     *
     * <p>🛑 <b>Refuse si la meilleure suggestion n'est PAS « aucune notion »</b>
     * — y compris quand il n'y a aucune suggestion du tout : le client
     * affirmerait alors quelque chose de faux sur la qualite du modele. Meme
     * principe que l'interdiction d'annoncer {@code VALIDATED} directement, et
     * meme raison : cette ligne est une mesure, pas une preference d'ecran.
     *
     * <p>🛑 <b>Aucun tag n'est pose</b> : {@code civic_notion_id} reste nul.
     * Confirmer un trou n'est pas ranger la question quelque part.
     */
    private NotionSuggestionVerdict confirmerAucuneNotion(
            UUID questionId, String notionCode, UUID relecteurId) {

        if (notionCode != null && !notionCode.isBlank()) {
            // « aucune notion ne convient » et « c'est cette notion » sont deux
            // gestes contraires. Corriger le modele se demande avec le seul
            // notionCode, et donne CORRECTED.
            throw new BusinessException(
                    "Un verdict « CONFIRM_NONE » ne pose aucune notion : "
                            + "n'envoyez pas de notionCode avec lui.");
        }
        if (!manager.existeQuestionCivique(questionId)) {
            throw new NotFoundException("Question introuvable : " + questionId);
        }
        CivicNotionManager.MeilleureSuggestion meilleure =
                manager.meilleureSuggestion(questionId);
        if (!meilleure.conclutAucuneNotion()) {
            throw new BusinessException(
                    "« CONFIRM_NONE » confirme que le modele a eu raison de ne "
                            + "proposer aucune notion. Ici sa meilleure "
                            + (meilleure.existe()
                                    ? "suggestion en propose une : corrigez-la "
                                      + "en envoyant la notion retenue, ou rejetez."
                                    : "suggestion n'existe pas : cette question "
                                      + "n'a pas ete pre-taguee, rejetez-la ou "
                                      + "passez."));
        }
        int marquees = manager.marquerVerdict(
                questionId, NotionSuggestionVerdict.VALIDATED, relecteurId);
        log.info("Relecture civique : question={} CONFIRM_NONE -> VALIDATED suggestions={}",
                questionId, marquees);
        return NotionSuggestionVerdict.VALIDATED;
    }

    /** {@code REJECTED} / {@code SKIPPED} : on marque, on ne pose rien. */
    private NotionSuggestionVerdict marquerSansPoser(
            UUID questionId, String notionCode,
            NotionSuggestionVerdict verdict, UUID relecteurId) {

        if (notionCode != null && !notionCode.isBlank()) {
            // Refuser plutot qu'ignorer : « rejeter » et « poser cette notion »
            // sont deux gestes contraires, et deviner lequel l'emporte
            // produirait une base qui ne dit pas ce que le relecteur a fait.
            throw new BusinessException(
                    "Un verdict « " + verdict + " » ne pose aucune notion : "
                            + "n'envoyez pas de notionCode avec lui.");
        }
        if (!manager.existeQuestionCivique(questionId)) {
            throw new NotFoundException("Question introuvable : " + questionId);
        }
        int marquees = manager.marquerVerdict(questionId, verdict, relecteurId);
        log.info("Relecture civique : question={} verdict={} suggestions={}",
                questionId, verdict, marquees);
        return verdict;
    }

    /**
     * Le verdict qu'un client a le droit de nommer : {@code REJECTED} ou
     * {@code SKIPPED}, et rien d'autre.
     *
     * <p>🛑 {@code VALIDATED} et {@code CORRECTED} sont <b>refuses</b> : ils se
     * deduisent d'une comparaison serveur, ils ne s'annoncent pas. Les accepter
     * laisserait un client ecrire lui-meme la note du modele.
     */
    private NotionSuggestionVerdict verdictSansTag(String normalise) {
        NotionSuggestionVerdict verdict;
        try {
            verdict = NotionSuggestionVerdict.valueOf(normalise);
        } catch (IllegalArgumentException e) {
            throw new BusinessException("Verdict inconnu : " + normalise);
        }
        if (verdict.poseLaNotion()) {
            throw new BusinessException(
                    "VALIDATED et CORRECTED sont determines par le serveur : "
                            + "envoyez la notion retenue, ou « TAG ».");
        }
        return verdict;
    }

    private CivicNotion resoudreNotion(String notionCode) {
        if (notionCode == null || notionCode.isBlank()) return null;
        CivicNotion notion = manager.findByCode(notionCode)
                .orElseThrow(() -> new NotFoundException("Notion inconnue : " + notionCode));
        if (!notion.isActive()) {
            throw new BusinessException(
                    "La notion « " + notion.getLabel() + " » a été fusionnée : "
                            + "choisissez celle qui la reprend.");
        }
        return notion;
    }

    private void poser(UUID questionId, CivicNotion notion) {
        if (manager.poserNotion(questionId, notion) == 0) {
            throw new NotFoundException("Question introuvable : " + questionId);
        }
    }

    private void effacer(UUID questionId) {
        if (manager.poserNotion(questionId, null) == 0) {
            throw new NotFoundException("Question introuvable : " + questionId);
        }
        log.info("Tagging civique : question={} notion=null (effacement)", questionId);
    }
}
