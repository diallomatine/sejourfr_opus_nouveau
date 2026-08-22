package com.sejourfr.app.service;

import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * <b>LA</b> regle d'acces du module Competences : quelles micro-competences et
 * quels petits sujets un candidat donne peut travailler.
 *
 * <p><b>Regle en vigueur depuis le 2026-08-10</b>, pour un compte SANS acces TCF
 * ({@code hasTcf == false}) :
 * <ol>
 *   <li>une seule competence ouverte par tache — la premiere de sa
 *       {@code SkillTaskCode} — soit 6 competences pour les 6 taches ;</li>
 *   <li><b>plus la competence de la priorite n&deg;1 de son Plan</b>, si elle
 *       n'est pas deja dans ce lot — <b>quelle que soit sa nature</b>, y compris
 *       une competence « a acquerir » que le candidat n'a jamais travaillee
 *       ({@link PlanFocusResolver}) ;</li>
 *   <li>dans une competence ouverte, seuls les {@value #FREE_PROMPTS_PER_SKILL}
 *       premiers sujets actifs sont ouverts ;</li>
 *   <li><b>plus, pour la COMPREHENSION, la premiere competence de chaque
 *       domaine</b> — soit {@code CO-A2} et {@code CE-A2} sur le contenu
 *       publie. Les niveaux B1 et B2 sont verrouilles.</li>
 * </ol>
 * Un abonne TCF n'a aucun verrou. Les <b>3 analyses IA offertes a vie</b> ne
 * changent pas : elles restent gerees par {@link SkillAnalysisAccessService} et
 * s'appliquent, inchangees, aux sujets ouverts.
 *
 * <p><b>Pourquoi le A2 de chaque domaine, et pas « une competence par
 * domaine » au hasard.</b> La compréhension n'a ni tache ni petit sujet : les
 * deux grains sur lesquels s'appuyait la regle EE/EO n'existent pas. Ce qui la
 * structure, c'est le NIVEAU, et la progression y est sequentielle (A2 solide
 * avant de travailler B1). Ouvrir l'entree de gamme de chaque domaine donne
 * donc au compte gratuit exactement ce que la regle EE/EO lui donne ailleurs :
 * de quoi commencer, jamais de quoi finir. Techniquement c'est le <b>rang actif
 * le plus bas</b> de chaque domaine qui est ouvert — meme definition que « la
 * premiere competence d'une tache », pour la meme raison : desactiver le rang 1
 * depuis la console ne doit pas fermer le domaine entier. Sur le contenu publie
 * (V318) ce rang est le A2.
 *
 * <p><b>Ce qui n'est PAS une regle d'acces</b> : une competence de comprehension
 * ouverte ne dispense d'aucun prerequis de progression. Le Plan reste libre de
 * ne pas la proposer ; ce service dit seulement ce que le candidat a le droit de
 * travailler.
 *
 * <p><b>Pourquoi la priorite du Plan est ouverte d'office.</b> Le diagnostic
 * peut designer une competence de rang 5 ; sans cette exception l'etape 1 du
 * Plan serait cadenassee et le Plan entier deviendrait inutilisable, alors que
 * c'est la colonne vertebrale du produit. On ouvre donc la competence que le
 * serveur lui-meme designe comme « a faire maintenant ».
 *
 * <p>⚠️ <b>Cette regle vaut pour les TROIS natures d'action</b> depuis le
 * 2026-08-21 (arbitrage du proprietaire : « un candidat non abonne pourra
 * travailler sa priorite 1, vu qu'elle est visible »). Elle s'appuyait jusque-la
 * sur {@code LearningPlanPriorityResolver.currentPrioritySkillId}, qui ne connait
 * que les <b>fragilites observees</b> : une competence « a acquerir » — jamais
 * travaillee, donc absente de l'historique — pouvait etre premiere du Plan et
 * rester verrouillee. {@link PlanFocusResolver} repond desormais pour les deux
 * natures, <b>sans rien couter de plus dans le cas courant</b> : une acquisition
 * ne passe premiere que si le candidat n'a aucune fragilite.
 *
 * <p><b>Cette regle ne vit qu'ici.</b> Ni un mapper, ni un controller, ni un
 * front ne la reimplemente : les DTO portent un simple {@code locked} calcule a
 * partir de {@link SkillAccess}, et la production est <b>refusee serveur</b> par
 * {@link #assertCanProduce} — meme philosophie que
 * {@code AttemptService.enforceMockExamSlotAccess} et
 * {@code ProductionAccessService}.
 *
 * <p><b>Cout constant, quel que soit l'ecran.</b> Un ecran de catalogue affiche
 * 24 competences x 15 sujets ; resoudre le verrou ligne par ligne serait un N+1
 * pur. {@link #resolve(UUID)} coute donc <b>4 requetes</b> dans le cas courant —
 * abonnement, premiere competence de chaque tache (6 lignes), priorite du Plan,
 * sujets actifs des 7 competences ouvertes au plus — et <b>une seule</b> pour un
 * abonne, qui court-circuite tout le reste. Seul le candidat <b>sans aucune
 * fragilite</b> paie en plus le cycle de palier, borne, jamais par competence
 * (cf. {@link PlanFocusResolver}).
 *
 * <p><b>Un appelant qui connait deja la premiere place la passe</b> :
 * {@link #resolve(UUID, UUID)}. C'est le cas du Plan, qui vient de la calculer —
 * il ne la fait donc pas recalculer, et son cout est <b>inchange</b>.
 */
@Service
@RequiredArgsConstructor
public class SkillAccessService {

    /**
     * Sujets ouverts au debut de chaque competence ouverte, pour un compte
     * gratuit.
     *
     * <p><b>Ne pas l'aligner sur</b> {@link LearningPlanStep#PROMPTS_PAR_ETAPE}
     * (5), qui dit tout autre chose : combien de sujets composent une etape du
     * Plan. Consequence assumee et voulue — un compte gratuit plafonne a 2/5 sur
     * son etape n&deg;1, et <b>aucune etape n'est finissable sans abonnement</b>.
     * Le Plan reste integralement <b>visible</b> et sa priorite n&deg;1 reste
     * <b>ouverte</b> ; c'est l'achevement, pas la lecture, qui est premium.
     */
    public static final int FREE_PROMPTS_PER_SKILL = 2;

    /**
     * Message de refus, ecrit pour etre <b>affichable tel quel par un paywall</b> :
     * il dit ce qui reste ouvert avant de dire ce qui manque.
     */
    public static final String LOCKED_MESSAGE =
            "Ce sujet fait partie du contenu réservé. Votre accès gratuit ouvre la première "
                    + "compétence de chaque tâche (ses 2 premiers sujets) et la compétence de la "
                    + "priorité n°1 de votre Plan. L'accès TCF ouvre les 48 compétences et leurs "
                    + "720 sujets.";

    /**
     * Refus d'une competence entiere, et non d'un sujet : c'est la forme que
     * prend le verrou en COMPREHENSION, ou il n'existe pas de petit sujet a
     * nommer. Ecrit pour etre affichable tel quel par un paywall.
     */
    public static final String LOCKED_SKILL_MESSAGE =
            "Cette compétence fait partie du contenu réservé. Votre accès gratuit ouvre le "
                    + "niveau A2 de la compréhension orale et de la compréhension écrite, ainsi "
                    + "que la compétence de la priorité n°1 de votre Plan. L'accès TCF ouvre "
                    + "tous les niveaux.";

    private final SubscriptionService subscriptionService;
    private final SkillManager skillManager;
    private final SkillPromptManager promptManager;
    private final PlanFocusResolver focusResolver;

    /**
     * L'ensemble de ce qui est ouvert a ce candidat, a resoudre <b>une fois par
     * ecran</b> puis a interroger en memoire.
     */
    @Transactional(readOnly = true)
    public SkillAccess resolve(UUID userId) {
        if (subscriptionService.hasTcf(userId)) {
            return SkillAccess.UNLIMITED;
        }
        return ouvert(focusResolver.currentFocusSkillId(userId).orElse(null));
    }

    /**
     * Meme regle, avec la <b>premiere place du Plan deja connue</b> de
     * l'appelant.
     *
     * <p>Reservee a {@link LearningPlanService}, qui vient de l'etablir a partir
     * de ses priorites et de ses acquisitions ({@link PlanFocusResolver#focus}) :
     * la lui faire recalculer ferait tourner le cycle de palier une seconde fois
     * dans la meme lecture, et rendrait le cout du Plan dependant du nombre de
     * fragilites du candidat — exactement ce que ses deux tests de cout
     * interdisent.
     *
     * @param focusSkillId competence de la premiere place, ou {@code null} quand
     *                     le Plan n'en designe aucune.
     */
    @Transactional(readOnly = true)
    public SkillAccess resolve(UUID userId, UUID focusSkillId) {
        if (subscriptionService.hasTcf(userId)) {
            return SkillAccess.UNLIMITED;
        }
        return ouvert(focusSkillId);
    }

    /** Le lot ouvert a un compte gratuit, l'abonnement etant deja tranche. */
    private SkillAccess ouvert(UUID focusSkillId) {
        Set<UUID> openSkillIds =
                new LinkedHashSet<>(skillManager.findFirstActiveIdPerTaskCode().values());
        // La comprehension n'a pas de tache : son entree de gamme est le rang
        // actif le plus bas de chaque domaine (CO-A2 / CE-A2 sur le publie).
        openSkillIds.addAll(skillManager.findFirstActiveIdPerComprehensionSection().values());
        if (focusSkillId != null) openSkillIds.add(focusSkillId);

        Set<UUID> openPromptIds = new LinkedHashSet<>();
        Map<UUID, List<SkillPrompt>> promptsBySkill =
                promptManager.findActiveBySkillIds(openSkillIds);
        for (List<SkillPrompt> prompts : promptsBySkill.values()) {
            // findActiveBySkillIds rend les sujets par rang croissant : les
            // deux premiers de cette liste SONT les deux premiers rangs actifs.
            prompts.stream().limit(FREE_PROMPTS_PER_SKILL)
                    .forEach(prompt -> openPromptIds.add(prompt.getId()));
        }
        return new SkillAccess(false, openSkillIds, openPromptIds);
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
