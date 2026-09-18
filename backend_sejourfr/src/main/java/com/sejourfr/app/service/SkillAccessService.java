package com.sejourfr.app.service;

import com.sejourfr.app.entity.SkillPrompt;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;
import java.util.UUID;

/**
 * <b>LA</b> regle d'acces du module Competences : quelles micro-competences et
 * quels petits sujets un candidat donne peut travailler.
 *
 * <h2>🛑 Regle en vigueur depuis le 2026-09-18 (D-18) : travailler une
 * competence est PREMIUM, sans exception</h2>
 * <p>Un compte <b>sans</b> acces TCF ({@code hasTcf == false}) n'a
 * <b>aucune</b> competence et <b>aucun</b> sujet ouverts. Un abonne TCF n'a
 * aucun verrou.
 *
 * <h2>Ce que D-18 a revoque, et il l'a revoque verbatim</h2>
 * <p>Quatre ouvertures d'office existaient, arbitrees les 2026-08-10 et
 * 2026-08-21. Elles sont <b>toutes supprimees</b> :
 * <ol>
 *   <li>« une seule competence ouverte par tache — la premiere de sa
 *       {@code SkillTaskCode} — soit 6 competences pour les 6 taches » ;</li>
 *   <li>« <b>plus la competence de la priorite n&deg;1 de son Plan</b>, si elle
 *       n'est pas deja dans ce lot — quelle que soit sa nature » ;</li>
 *   <li>« dans une competence ouverte, seuls les 2 premiers sujets actifs sont
 *       ouverts » ({@code FREE_PROMPTS_PER_SKILL = 2}, devenu sans objet : il
 *       n'y a plus de competence ouverte a borner) ;</li>
 *   <li>« plus, pour la COMPREHENSION, la premiere competence de chaque
 *       domaine » — soit {@code CO-A2} et {@code CE-A2}. 🛑 Les rangs CO/CE
 *       sont traites <b>dans la meme passe</b> que les rangs EE/EO, par
 *       coherence avec la meme regle : D-18 ne connait pas de domaine
 *       d'exception.</li>
 * </ol>
 * <p>Et avec elles, l'<b>exemption du 2026-08-21</b>, citee ici parce que c'est
 * l'endroit qu'elle occupait :
 * <blockquote>« un candidat non abonne pourra travailler sa priorite 1, vu
 * qu'elle est visible »</blockquote>
 *
 * <h2>Ce qui reste GRATUIT, et ce n'est pas ici</h2>
 * <p>Le diagnostic rapide, <b>un</b> examen blanc d'expression ecrite et
 * <b>un</b> examen blanc d'expression orale (analyse IA complete incluse,
 * {@link FreeExamEntitlementService}), et les examens QCM CO/CE — dont le
 * <b>slot 1 reste offert ET rejouable a volonte</b>
 * ({@code AttemptService.enforceMockExamSlotAccess}, inchange). 🛑 Ce service ne
 * decide <b>rien</b> de tout cela : il ne parle que du travail de competence.
 *
 * <h2>🛑 La contradiction #1 du depot n'est PAS rouverte</h2>
 * <p>« On floute l'ACTION pas encore accessible, jamais le RESULTAT mesure »
 * reste la regle. Le Plan, le parcours, les priorites, les niveaux mesures et
 * les compteurs <b>restent lisibles et servis</b> : ce service pose un
 * {@code locked}, il ne masque <b>aucune</b> donnee. Ce qui se ferme est
 * l'<b>execution</b>, et le cycle visible est l'argument de vente.
 *
 * <h2>La circularite que D-1 avait resolue disparait avec l'exemption</h2>
 * <p>{@code JourneyReadService} devait lui passer la <b>premiere etape non
 * cloturee</b>, verrous ignores, pour que l'exemption tombe sur la vraie
 * priorite n&deg;1 sans dependre de {@code locked} — qui depend de l'acces.
 * Sans exemption, il n'y a plus rien a deverrouiller : {@link #resolve(UUID)}
 * suffit, et la surcharge qui recevait cette etape est <b>supprimee</b>.
 * Consequence <b>voulue</b> : pour un compte gratuit, aucune etape n'est
 * executable, donc {@code current == null} et
 * {@code JourneyState.LOCKED} est permanent (D-18).
 *
 * <p><b>Cette regle ne vit qu'ici.</b> Ni un mapper, ni un controller, ni un
 * front ne la reimplemente : les DTO portent un simple {@code locked} calcule a
 * partir de {@link SkillAccess}, et la production est <b>refusee serveur</b> par
 * {@link #assertCanProduce} — meme philosophie que
 * {@code AttemptService.enforceMockExamSlotAccess} et
 * {@code ProductionAccessService}.
 *
 * <p><b>Cout constant, quel que soit l'ecran, et desormais d'UNE requete.</b>
 * {@link #resolve(UUID)} ne lit plus que l'abonnement : ni les premieres
 * competences de chaque tache, ni les rangs de comprehension, ni la premiere
 * place du Plan, ni les sujets actifs. Un ecran de catalogue de 24 competences x
 * 15 sujets resout donc son verrou en une lecture, abonne ou pas.
 */
@Service
@RequiredArgsConstructor
public class SkillAccessService {

    /**
     * Message de refus d'un <b>sujet</b>, ecrit pour etre <b>affichable tel quel
     * par un paywall</b>.
     */
    public static final String LOCKED_MESSAGE =
            "Travailler ce sujet demande un accès TCF. Votre plan, vos priorités et vos "
                    + "niveaux mesurés restent visibles ; l'accès TCF ouvre les 48 compétences "
                    + "et leurs 720 sujets.";

    /**
     * Refus d'une competence entiere, et non d'un sujet : c'est la forme que
     * prend le verrou en COMPREHENSION, ou il n'existe pas de petit sujet a
     * nommer. Ecrit pour etre affichable tel quel par un paywall.
     */
    public static final String LOCKED_SKILL_MESSAGE =
            "Travailler cette compétence demande un accès TCF. Votre plan, vos priorités et "
                    + "vos niveaux mesurés restent visibles ; l'accès TCF ouvre toutes les "
                    + "compétences et tous les niveaux.";

    private final SubscriptionService subscriptionService;

    /**
     * L'ensemble de ce qui est ouvert a ce candidat, a resoudre <b>une fois par
     * ecran</b> puis a interroger en memoire.
     *
     * <p>Depuis D-18, la reponse est binaire : {@link SkillAccess#UNLIMITED} pour
     * un abonne TCF, {@link SkillAccess#AUCUN} sinon.
     */
    @Transactional(readOnly = true)
    public SkillAccess resolve(UUID userId) {
        return subscriptionService.hasTcf(userId)
                ? SkillAccess.UNLIMITED
                : SkillAccess.AUCUN;
    }

    /**
     * Verrou <b>opposable</b> : le client ne decide jamais s'il peut produire.
     *
     * <p>Applique a la creation d'une tentative comme a la demande d'analyse et
     * a sa relance — une production nee du temps ou la competence etait ouverte
     * (abonnement expire depuis) ne rouvre pas la porte par la bande.
     *
     * @throws AccessDeniedException (403) avec {@link #LOCKED_MESSAGE}
     */
    @Transactional(readOnly = true)
    public void assertCanProduce(UUID userId, SkillPrompt prompt) {
        if (resolve(userId).isPromptLocked(prompt.getId())) {
            throw new AccessDeniedException(LOCKED_MESSAGE);
        }
    }

    /**
     * Verrou <b>opposable</b> au grain de la COMPETENCE, pour les entrainements
     * qui n'ont pas de petit sujet a nommer — c'est le cas de la comprehension,
     * dont l'entrainement est une serie ciblee de QCM.
     *
     * <p>Jumelle en lecture de {@link SkillAccess#isSkillLocked(UUID)} : le
     * client ne decide jamais s'il peut travailler une competence, exactement
     * comme {@link #assertCanProduce} pour un sujet. Il n'existe donc toujours
     * qu'<b>une</b> regle d'acces, appliquee a deux grains.
     *
     * @throws AccessDeniedException (403) avec {@link #LOCKED_SKILL_MESSAGE}
     */
    @Transactional(readOnly = true)
    public void assertCanTrain(UUID userId, UUID skillId) {
        if (resolve(userId).isSkillLocked(skillId)) {
            throw new AccessDeniedException(LOCKED_SKILL_MESSAGE);
        }
    }

    /**
     * Photographie de ce qui est ouvert. {@code unlimited} est le cas de
     * l'abonne : les deux ensembles sont alors vides et ne sont jamais
     * consultes — rien n'est verrouille.
     */
    public record SkillAccess(
            boolean unlimited,
            Set<UUID> openSkillIds,
            Set<UUID> openPromptIds) {

        /** L'abonne TCF : aucun verrou, aucune requete de plus. */
        public static final SkillAccess UNLIMITED = new SkillAccess(true, Set.of(), Set.of());

        /**
         * Le compte <b>sans</b> acces TCF : rien d'ouvert, et c'est l'effet
         * voulu de D-18. 🛑 Rien n'est <b>masque</b> pour autant — un
         * {@code locked} servi, jamais une donnee absente.
         */
        public static final SkillAccess AUCUN = new SkillAccess(false, Set.of(), Set.of());

        public SkillAccess {
            openSkillIds = Set.copyOf(openSkillIds);
            openPromptIds = Set.copyOf(openPromptIds);
        }

        /** {@code true} quand ce candidat ne peut produire sur aucun sujet de la competence. */
        public boolean isSkillLocked(UUID skillId) {
            return !unlimited && !openSkillIds.contains(skillId);
        }

        /** {@code true} quand ce candidat ne peut pas produire sur ce sujet. */
        public boolean isPromptLocked(UUID promptId) {
            return !unlimited && !openPromptIds.contains(promptId);
        }
    }
}
