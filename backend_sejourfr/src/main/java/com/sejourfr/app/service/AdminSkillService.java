package com.sejourfr.app.service;

import com.sejourfr.app.dto.AdminSkillCreateRequest;
import com.sejourfr.app.dto.AdminSkillDetailDto;
import com.sejourfr.app.dto.AdminSkillDto;
import com.sejourfr.app.dto.AdminSkillPromptCreateRequest;
import com.sejourfr.app.dto.AdminSkillPromptDto;
import com.sejourfr.app.dto.AdminSkillPromptUpdateRequest;
import com.sejourfr.app.dto.AdminSkillReferencesRequest;
import com.sejourfr.app.dto.AdminSkillStatsDto;
import com.sejourfr.app.dto.AdminSkillUpdateRequest;
import com.sejourfr.app.dto.PageResponse;
import com.sejourfr.app.dto.SkillConstraintTagInput;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.SkillConstraintTag;
import com.sejourfr.app.entity.SkillPrompt;
import com.sejourfr.app.entity.SkillReference;
import com.sejourfr.app.enums.SkillConstraintIcon;
import com.sejourfr.app.enums.SkillReferenceLevel;
import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.SkillTaskCode;
import com.sejourfr.app.exception.BusinessException;
import com.sejourfr.app.exception.NotFoundException;
import com.sejourfr.app.manager.SkillManager;
import com.sejourfr.app.manager.SkillPromptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager;
import com.sejourfr.app.manager.UserSkillAttemptManager.SkillUsage;
import com.sejourfr.app.mapper.AdminSkillMapper;
import com.sejourfr.app.specification.SkillSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * CRUD editorial du module « Competences TCF » pour la console admin :
 * competences, petits sujets et productions de reference.
 *
 * <p>Quatre principes le structurent.
 *
 * <ul>
 *   <li><b>Ce que le schema verrouille, le service le refuse d'abord.</b> Les
 *       contraintes de la base (coherence EE/EO, unicite des codes, unicite des
 *       rangs) restent le dernier mot, mais les laisser parler seules rendrait
 *       un 500 « Erreur interne » la ou l'editeur a besoin de savoir quel champ
 *       corriger. Le controle applicatif ne remplace pas la contrainte, il la
 *       traduit.</li>
 *   <li><b>Rien de structurant ne vient du client.</b> La {@code section} d'un
 *       sujet est deduite de sa competence parente, jamais lue dans le corps :
 *       elle est denormalisee et verrouillee par une cle etrangere composite,
 *       donc une valeur client ne pourrait qu'etre redondante ou fausse.</li>
 *   <li><b>On ne detruit jamais d'historique candidat.</b> Toute suppression
 *       est refusee (409) des qu'une tentative est rattachee, directement ou
 *       via un sujet. Le geste normal est la desactivation.</li>
 *   <li><b>Une requete par ecran, pas une par ligne.</b> Compteurs, references
 *       et agregats sont charges en lot puis croises en memoire.</li>
 * </ul>
 *
 * <p>La vue admin montre le catalogue ENTIER — contenus desactives compris — la
 * ou {@code SkillService} ne sert au candidat que ce qui est publie. C'est la
 * raison d'etre de ce service separe : y ajouter un drapeau « je suis admin »
 * aurait fait dependre la confidentialite des references d'un booleen d'appel.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminSkillService {

    /** Garde-fou de pagination : une console n'affiche pas 10 000 lignes d'un coup. */
    private static final int MAX_SIZE = 100;

    /**
     * Bornes du guidage de l'ecran de saisie. Elles vivent ici et non dans le
     * DDL : les colonnes ont ete ajoutees nullables sur 240 lignes existantes
     * (V026), et un sujet sans guidage reste legal.
     */
    private static final int CHECKLIST_MIN = 2;
    private static final int CHECKLIST_MAX = 4;
    private static final int TAGS_MIN = 1;
    private static final int TAGS_MAX = 3;

    private final SkillManager skillManager;
    private final SkillPromptManager promptManager;
    private final UserSkillAttemptManager attemptManager;
    private final AdminSkillMapper adminSkillMapper;

    // ------------------------------------------------------------------------
    // Competences
    // ------------------------------------------------------------------------

    /**
     * Liste paginee et filtree. Le tri est impose (tache puis rang) et non
     * negociable depuis le client : c'est l'ordre pedagogique du catalogue, et
     * le seul sous lequel « la 3e competence de EE2 » veut dire quelque chose.
     *
     * <p>Les quatre filtres sont appliques en SQL via {@link SkillSpecifications} :
     * filtrer en memoire ne verrait que la page courante et afficherait
     * « aucun resultat » sur un catalogue de 48 lignes.
     */
    public PageResponse<AdminSkillDto> list(SkillSection section,
                                            SkillTaskCode taskCode,
                                            Boolean active,
                                            String q,
                                            int page,
                                            int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), MAX_SIZE);

        Specification<Skill> spec = Specification
                .where(SkillSpecifications.hasSection(section))
                .and(SkillSpecifications.hasTaskCode(taskCode))
                .and(SkillSpecifications.hasActive(active))
                .and(SkillSpecifications.search(q));

        Page<Skill> result = skillManager.findAll(spec, PageRequest.of(safePage, safeSize,
                Sort.by(Sort.Order.asc("taskCode"), Sort.Order.asc("displayOrder"))));

        Map<UUID, Long> promptCounts = promptManager.countBySkillIds(
                result.getContent().stream().map(Skill::getId).toList());

        return PageResponse.from(result.map(
                skill -> adminSkillMapper.toDto(skill, promptCounts.getOrDefault(skill.getId(), 0L))));
    }

    /**
     * Detail d'une competence et de TOUS ses sujets, desactives compris, chacun
     * complet (references et compteur de tentatives). Charger les sujets a plat
     * puis croiser en memoire evite les 5 requetes de references et les 5
     * requetes de comptage qu'une boucle naive produirait.
     */
    public AdminSkillDetailDto getSkill(UUID id) {
        Skill skill = requireSkill(id);
        List<SkillPrompt> prompts = promptManager.findAllBySkillId(id);
        return new AdminSkillDetailDto(
                adminSkillMapper.toDto(skill, prompts.size()),
                toPromptDtos(prompts, skill));
    }

    @Transactional
    public AdminSkillDto createSkill(AdminSkillCreateRequest req) {
        SkillTaskCode taskCode = req.taskCode();
        SkillSection section = resolveSection(req.section(), taskCode);
        String code = req.code().trim();
        requireFreeSkillCode(code);
        requireFreeSkillOrder(section, taskCode, req.displayOrder(), null);

        Skill skill = new Skill();
        skill.setSection(section);
        skill.setTaskCode(taskCode);
        skill.setCode(code);
        skill.setTitle(req.title().trim());
        skill.setDescription(req.description().trim());
        skill.setGeneralCriterion(req.generalCriterion().trim());
        skill.setTargetLevel(req.targetLevel());
        skill.setDisplayOrder(req.displayOrder().shortValue());
        skill.setActive(req.active() == null || req.active());

        Skill saved = skillManager.save(skill);
        return adminSkillMapper.toDto(saved, 0L);
    }

    /**
     * Modification d'une competence. {@code code}, {@code section} et
     * {@code taskCode} ne figurent pas dans la requete et ne sont donc jamais
     * modifiables : les codes des sujets s'adossent au code de la competence, et
     * la deplacer d'une tache a l'autre invaliderait le palier de ses cinq
     * sujets.
     *
     * <p>Toutes les colonnes visees etant {@code NOT NULL}, un champ absent vaut
     * « ne touche pas » — un nul y demanderait un etat que la base refuse.
     */
    @Transactional
    public AdminSkillDto updateSkill(UUID id, AdminSkillUpdateRequest req) {
        Skill skill = requireSkill(id);

        if (req.title() != null) skill.setTitle(req.title().trim());
        if (req.description() != null) skill.setDescription(req.description().trim());
        if (req.generalCriterion() != null) skill.setGeneralCriterion(req.generalCriterion().trim());
        if (req.targetLevel() != null) skill.setTargetLevel(req.targetLevel());
        if (req.displayOrder() != null) {
            requireFreeSkillOrder(skill.getSection(), skill.getTaskCode(),
                    req.displayOrder(), skill.getId());
            skill.setDisplayOrder(req.displayOrder().shortValue());
        }
        if (req.active() != null) skill.setActive(req.active());

        Skill saved = skillManager.save(skill);
        return adminSkillMapper.toDto(saved, promptManager.countBySkillId(saved.getId()));
    }

    /**
     * Suppression definitive d'une competence, refusee des qu'un candidat a
     * produit sur N'IMPORTE LEQUEL de ses sujets : la supprimer emporterait ses
     * sujets en cascade, donc l'historique rattache. On ne detruit jamais le
     * travail d'un candidat pour une decision editoriale — la desactivation
     * retire la competence du catalogue et conserve tout.
     *
     * @throws IllegalStateException traduit en 409 par le handler global
     */
    @Transactional
    public void deleteSkill(UUID id) {
        Skill skill = requireSkill(id);
        if (attemptManager.existsForSkill(id)) {
            throw new IllegalStateException(
                    "Des candidats ont déjà travaillé cette compétence : elle ne peut plus être "
                            + "supprimée, seulement désactivée.");
        }
        skillManager.delete(skill);
    }

    /**
     * Usage reel du catalogue. Le taux de validation reste NUL tant qu'aucune
     * tentative n'a ete analysee — voir {@code AdminSkillStatsDto}.
     */
    public List<AdminSkillStatsDto> stats(SkillSection section) {
        List<Skill> skills = skillManager.findAllForAdmin(section);
        List<UUID> ids = skills.stream().map(Skill::getId).toList();
        Map<UUID, Long> promptCounts = promptManager.countBySkillIds(ids);
        Map<UUID, SkillUsage> usage = attemptManager.aggregateUsageBySkillIds(ids);

        return skills.stream()
                .map(skill -> adminSkillMapper.toStatsDto(
                        skill,
                        promptCounts.getOrDefault(skill.getId(), 0L),
                        usage.getOrDefault(skill.getId(), SkillUsage.EMPTY)))
                .toList();
    }

    // ------------------------------------------------------------------------
    // Petits sujets
    // ------------------------------------------------------------------------

    /**
     * Sujet complet, references comprises. C'est cet appel que font les modals
     * d'edition : le detail de la competence sert la liste, pas le formulaire —
     * rouvrir un formulaire sur une donnee mise en cache par la liste risquerait
     * d'ecraser une modification faite entre-temps.
     */
    public AdminSkillPromptDto getPrompt(UUID id) {
        SkillPrompt prompt = requirePrompt(id);
        return adminSkillMapper.toPromptDto(
                prompt,
                prompt.getSkill(),
                promptManager.findReferencesByPromptId(id),
                attemptManager.countByPrompt(id));
    }

    /**
     * Creation d'un sujet. La {@code section} est <b>deduite de la competence
     * parente</b> : c'est la seule source qui ne peut pas mentir, la cle
     * etrangere composite {@code (skill_id, section)} la verrouillant en base.
     */
    @Transactional
    public AdminSkillPromptDto createPrompt(AdminSkillPromptCreateRequest req) {
        Skill skill = requireSkill(req.skillId());
        String code = req.code().trim();
        if (promptManager.existsByCode(code)) {
            throw new BusinessException("Le code « " + code + " » est déjà utilisé par un autre sujet.");
        }
        requireFreePromptOrder(skill.getId(), req.displayOrder(), null);
        requireCoherentBounds(skill.getSection(), req.recommendedMinWords(),
                req.recommendedMaxWords(), req.recommendedDurationSeconds());

        SkillPrompt prompt = new SkillPrompt();
        prompt.setSkill(skill);
        prompt.setSection(skill.getSection());
        prompt.setCode(code);
        prompt.setTitle(req.title().trim());
        prompt.setContext(req.context().trim());
        prompt.setInstruction(req.instruction().trim());
        prompt.setUniqueCriterion(req.uniqueCriterion().trim());
        applyGuidance(prompt, req.checklist(), req.constraintTags(),
                req.answerStarter(), req.tip());
        prompt.setRecommendedMinWords(req.recommendedMinWords());
        prompt.setRecommendedMaxWords(req.recommendedMaxWords());
        prompt.setRecommendedDurationSeconds(req.recommendedDurationSeconds());
        prompt.setDifficultyLevel(req.difficultyLevel());
        prompt.setDisplayOrder(req.displayOrder().shortValue());
        prompt.setActive(req.active() == null || req.active());

        SkillPrompt saved = promptManager.save(prompt);
        return adminSkillMapper.toPromptDto(saved, skill, List.of(), 0L);
    }

    /**
     * Modification d'un sujet.
     *
     * <p><b>⚠ Les trois bornes de longueur sont REMPLACEES, pas fusionnees : un
     * nul les efface.</b> C'est le seul moyen de corriger un sujet dont les
     * bornes etaient fausses — sous une semantique de fusion, une borne posee
     * par erreur serait ineffacable depuis la console. C'est aussi ce qui rend
     * possible de basculer un sujet d'une epreuve a l'autre : le CHECK
     * {@code chk_skill_prompts_ee_eo_coherence} refuse tout etat ou une duree
     * cohabiterait avec une fourchette de mots, donc vider les unes et poser
     * l'autre doit se faire dans le meme appel.
     *
     * <p><b>Les quatre champs de guidage sont REMPLACES eux aussi</b> : leurs
     * colonnes sont nullables (V026), un nul y designe donc l'etat « ce sujet
     * n'a pas de guidage », qui doit rester atteignable depuis la console.
     *
     * <p>Les autres champs visent des colonnes {@code NOT NULL} : un nul y vaut
     * « ne touche pas ».
     */
    @Transactional
    public AdminSkillPromptDto updatePrompt(UUID id, AdminSkillPromptUpdateRequest req) {
        SkillPrompt prompt = requirePrompt(id);

        if (req.title() != null) prompt.setTitle(req.title().trim());
        if (req.context() != null) prompt.setContext(req.context().trim());
        if (req.instruction() != null) prompt.setInstruction(req.instruction().trim());
        if (req.uniqueCriterion() != null) prompt.setUniqueCriterion(req.uniqueCriterion().trim());
        if (req.difficultyLevel() != null) prompt.setDifficultyLevel(req.difficultyLevel());
        if (req.displayOrder() != null) {
            requireFreePromptOrder(prompt.getSkill().getId(), req.displayOrder(), prompt.getId());
            prompt.setDisplayOrder(req.displayOrder().shortValue());
        }
        if (req.active() != null) prompt.setActive(req.active());

        applyGuidance(prompt, req.checklist(), req.constraintTags(),
                req.answerStarter(), req.tip());

        requireCoherentBounds(prompt.getSection(), req.recommendedMinWords(),
                req.recommendedMaxWords(), req.recommendedDurationSeconds());
        prompt.setRecommendedMinWords(req.recommendedMinWords());
        prompt.setRecommendedMaxWords(req.recommendedMaxWords());
        prompt.setRecommendedDurationSeconds(req.recommendedDurationSeconds());

        SkillPrompt saved = promptManager.save(prompt);
        return adminSkillMapper.toPromptDto(
                saved,
                saved.getSkill(),
                promptManager.findReferencesByPromptId(saved.getId()),
                attemptManager.countByPrompt(saved.getId()));
    }

    /**
     * Suppression definitive d'un sujet, refusee des qu'un candidat a produit
     * dessus : ses tentatives partiraient en cascade.
     *
     * @throws IllegalStateException traduit en 409 par le handler global
     */
    @Transactional
    public void deletePrompt(UUID id) {
        SkillPrompt prompt = requirePrompt(id);
        if (attemptManager.existsForPrompt(id)) {
            throw new IllegalStateException(
                    "Des candidats ont déjà travaillé ce sujet : il ne peut plus être supprimé, "
                            + "seulement désactivé.");
        }
        promptManager.delete(prompt);
    }

    /**
     * Remplacement ATOMIQUE des trois references d'un sujet : les anciennes ne
     * sont supprimees qu'une fois les nouvelles validees, dans la meme
     * transaction. Un remplacement partiel laisserait un sujet publie avec deux
     * onglets sur trois cote candidat.
     *
     * <p>Les trois niveaux sont exiges sans doublon — la table impose
     * {@code UNIQUE (skill_prompt_id, level)}, et un niveau manquant n'est pas
     * un choix editorial que le serveur puisse faire a la place de l'editeur.
     */
    @Transactional
    public AdminSkillPromptDto replaceReferences(UUID promptId, AdminSkillReferencesRequest req) {
        SkillPrompt prompt = requirePrompt(promptId);
        requireExactlyThreeLevels(req.references());

        promptManager.deleteReferencesByPromptId(promptId);
        for (AdminSkillReferencesRequest.Item item : req.references()) {
            SkillReference reference = new SkillReference();
            reference.setSkillPrompt(prompt);
            reference.setLevel(item.level());
            reference.setText(item.text().trim());
            reference.setPedagogicalNote(item.pedagogicalNote().trim());
            promptManager.saveReference(reference);
        }

        return adminSkillMapper.toPromptDto(
                prompt,
                prompt.getSkill(),
                promptManager.findReferencesByPromptId(promptId),
                attemptManager.countByPrompt(promptId));
    }

    // ------------------------------------------------------------------------
    // Regles partagees
    // ------------------------------------------------------------------------

    private Skill requireSkill(UUID id) {
        return skillManager.findById(id)
                .orElseThrow(() -> new NotFoundException("Compétence introuvable : " + id));
    }

    /** Charge le sujet AVEC sa competence : le DTO admin expose le code du parent. */
    private SkillPrompt requirePrompt(UUID id) {
        return promptManager.findByIdWithSkill(id)
                .orElseThrow(() -> new NotFoundException("Sujet introuvable : " + id));
    }

    /**
     * La section vient de la tache (« EE1 » vit dans « EE »). Fournie par le
     * client, elle doit concorder : on refuse plutot que d'ignorer en silence,
     * sinon la console croirait avoir cree une competence orale la ou le serveur
     * en a range une ecrite.
     */
    private SkillSection resolveSection(SkillSection provided, SkillTaskCode taskCode) {
        if (taskCode == null) {
            // Aucune tache : la seule forme legale est une competence de
            // COMPREHENSION, qui n'en a pas. Refuser ici evite de laisser
            // remonter chk_skills_task_code_presence en 500.
            if (provided == null) {
                throw new BusinessException("Précisez la tâche (EE1 à EO3) pour une compétence "
                        + "d'expression, ou l'épreuve (section=CO ou CE) pour une compétence de "
                        + "compréhension.");
            }
            if (provided.isProduction()) {
                throw new BusinessException("Une compétence d'expression (" + provided
                        + ") appartient toujours à une tâche : précisez taskCode.");
            }
            return provided;
        }
        SkillSection derived = taskCode.getSection();
        if (provided != null && provided != derived) {
            throw new BusinessException("La tâche " + taskCode + " appartient à l'épreuve "
                    + derived + ", pas à " + provided + ".");
        }
        return derived;
    }

    private void requireFreeSkillCode(String code) {
        if (skillManager.existsByCode(code)) {
            throw new BusinessException(
                    "Le code « " + code + " » est déjà utilisé par une autre compétence.");
        }
    }

    /**
     * Le rang d'affichage est unique par tache (expression) ou par domaine
     * (comprehension, qui n'a pas de tache). Le verifier ici sert a rendre le
     * conflit lisible ; les contraintes {@code uq_skills_task_order} et
     * {@code uq_skills_section_order_comprehension} restent le dernier mot.
     *
     * <p>Ce n'est <b>pas</b> un rang « parking » deguise : la contrainte est
     * {@code DEFERRABLE INITIALLY DEFERRED} precisement pour qu'un echange de
     * deux rangs soit legal dans une transaction, et rien ici ne l'empeche. On
     * refuse seulement de poser, en une operation isolee, un rang deja occupe —
     * ce qui echouerait de toute facon au commit, mais en 500.
     */
    private void requireFreeSkillOrder(SkillSection section, SkillTaskCode taskCode,
                                       Integer displayOrder, UUID selfId) {
        if (displayOrder == null) return;
        // Le perimetre d'unicite suit celui de la base : par TACHE en
        // expression (uq_skills_task_order), par DOMAINE en comprehension
        // (uq_skills_section_order_comprehension, index partiel sur task_code
        // IS NULL). Interroger par tache avec un nul ne trouverait rien et
        // laisserait l'index parler en 500.
        List<Skill> voisines = taskCode != null
                ? skillManager.findAllByTaskCode(taskCode)
                : skillManager.findAllComprehensionBySection(section);
        String perimetre = taskCode != null ? taskCode.name() : section.name();
        for (Skill other : voisines) {
            if (other.getDisplayOrder() == displayOrder && !other.getId().equals(selfId)) {
                throw new BusinessException("Le rang " + displayOrder + " est déjà occupé dans "
                        + perimetre + " par la compétence « " + other.getCode() + " ».");
            }
        }
    }

    /** Meme regle, a l'interieur d'une competence ({@code uq_skill_prompts_skill_order}). */
    private void requireFreePromptOrder(UUID skillId, Integer displayOrder, UUID selfId) {
        if (displayOrder == null) return;
        for (SkillPrompt other : promptManager.findAllBySkillId(skillId)) {
            if (other.getDisplayOrder() == displayOrder && !other.getId().equals(selfId)) {
                throw new BusinessException("Le rang " + displayOrder + " est déjà occupé dans "
                        + "cette compétence par le sujet « " + other.getCode() + " ».");
            }
        }
    }

    /**
     * Traduction applicative de {@code chk_skill_prompts_ee_eo_coherence} : un
     * sujet ecrit se mesure en mots et jamais en secondes, un sujet oral
     * l'inverse. La contrainte de base reste la garantie ; ce controle existe
     * pour que l'editeur lise « un sujet oral ne porte pas de nombre de mots »
     * au lieu d'un 500.
     */
    private void requireCoherentBounds(SkillSection section,
                                       Integer minWords,
                                       Integer maxWords,
                                       Integer durationSeconds) {
        if (section == SkillSection.EE) {
            if (minWords == null || maxWords == null) {
                throw new BusinessException(
                        "Un sujet d'expression écrite doit porter un nombre de mots minimum et maximum.");
            }
            if (durationSeconds != null) {
                throw new BusinessException(
                        "Un sujet d'expression écrite ne porte pas de durée conseillée.");
            }
            if (minWords >= maxWords) {
                throw new BusinessException(
                        "Le nombre de mots minimum doit être strictement inférieur au maximum.");
            }
        } else {
            if (durationSeconds == null) {
                throw new BusinessException(
                        "Un sujet d'expression orale doit porter une durée conseillée.");
            }
            if (minWords != null || maxWords != null) {
                throw new BusinessException(
                        "Un sujet d'expression orale ne porte pas de nombre de mots.");
            }
        }
    }

    /**
     * Pose le guidage de l'ecran de saisie, en <b>remplacement</b> : ce qui
     * n'est pas fourni est efface. Utilise a la creation comme a la
     * modification, pour que les deux voies ne puissent pas diverger.
     *
     * <p>Une liste vide vaut un nul — « aucune etiquette » et « je n'en envoie
     * pas » decrivent le meme sujet, et refuser l'un des deux obligerait la
     * console a distinguer deux facons d'exprimer la meme intention.
     *
     * <p><b>Tout est valide avant qu'une seule valeur ne soit posee</b> : une
     * check-list valide suivie d'une etiquette invalide ne doit pas laisser le
     * sujet a moitie modifie en memoire. La transaction annulerait l'ecriture,
     * mais l'entite serait deja incoherente pour tout ce qui la relit avant.
     */
    private void applyGuidance(SkillPrompt prompt,
                               List<String> checklist,
                               List<SkillConstraintTagInput> constraintTags,
                               String answerStarter,
                               String tip) {
        List<String> actions = sanitizeChecklist(checklist);
        List<SkillConstraintTag> tags = sanitizeConstraintTags(constraintTags);

        prompt.setChecklist(actions);
        prompt.setConstraintTags(tags);
        prompt.setAnswerStarter(blankToNull(answerStarter));
        prompt.setTip(blankToNull(tip));
    }

    /**
     * La check-list compte 2 a 4 gestes. Moins de deux ne decoupe rien, plus de
     * quatre ne tient plus au-dessus de la zone de saisie sur un telephone —
     * c'est la contrainte d'ecran qui fixe la borne haute, pas une regle
     * pedagogique.
     */
    private List<String> sanitizeChecklist(List<String> checklist) {
        if (checklist == null || checklist.isEmpty()) return null;
        List<String> cleaned = new ArrayList<>(checklist.size());
        for (String item : checklist) {
            if (item == null || item.isBlank()) {
                throw new BusinessException("Une action de la check-list ne peut pas être vide.");
            }
            cleaned.add(item.trim());
        }
        if (cleaned.size() < CHECKLIST_MIN || cleaned.size() > CHECKLIST_MAX) {
            throw new BusinessException("La check-list doit compter entre " + CHECKLIST_MIN
                    + " et " + CHECKLIST_MAX + " actions (" + cleaned.size() + " fournie(s)).");
        }
        return cleaned;
    }

    /**
     * Les etiquettes sont 1 a 3, et leur icone appartient a une liste fermee :
     * une valeur inconnue n'afficherait rien cote front. On la refuse ici, en
     * enumerant les valeurs admises, plutot que de laisser une etiquette muette
     * atteindre l'ecran du candidat.
     */
    private List<SkillConstraintTag> sanitizeConstraintTags(List<SkillConstraintTagInput> tags) {
        if (tags == null || tags.isEmpty()) return null;
        List<SkillConstraintTag> cleaned = new ArrayList<>(tags.size());
        for (SkillConstraintTagInput tag : tags) {
            if (tag == null || tag.label() == null || tag.label().isBlank()) {
                throw new BusinessException("Le libellé d'une étiquette de contrainte est obligatoire.");
            }
            cleaned.add(new SkillConstraintTag(tag.label().trim(), parseIcon(tag.icon())));
        }
        if (cleaned.size() < TAGS_MIN || cleaned.size() > TAGS_MAX) {
            throw new BusinessException("Les étiquettes de contrainte doivent être entre " + TAGS_MIN
                    + " et " + TAGS_MAX + " (" + cleaned.size() + " fournie(s)).");
        }
        return cleaned;
    }

    private SkillConstraintIcon parseIcon(String icon) {
        if (icon == null || icon.isBlank()) {
            throw new BusinessException("L'icône d'une étiquette de contrainte est obligatoire. "
                    + "Valeurs acceptées : " + iconesAcceptees() + ".");
        }
        try {
            return SkillConstraintIcon.valueOf(icon.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new BusinessException("L'icône « " + icon + " » n'existe pas. "
                    + "Valeurs acceptées : " + iconesAcceptees() + ".");
        }
    }

    private static String iconesAcceptees() {
        return Arrays.stream(SkillConstraintIcon.values())
                .map(Enum::name)
                .collect(Collectors.joining(", "));
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private void requireExactlyThreeLevels(List<AdminSkillReferencesRequest.Item> references) {
        Set<SkillReferenceLevel> seen = EnumSet.noneOf(SkillReferenceLevel.class);
        for (AdminSkillReferencesRequest.Item item : references) {
            if (!seen.add(item.level())) {
                throw new BusinessException(
                        "Le niveau " + item.level() + " est fourni deux fois : un seul texte par niveau.");
            }
        }
        if (seen.size() != SkillReferenceLevel.values().length) {
            throw new BusinessException("Les trois références sont obligatoires : "
                    + "insuffisante, attendue et très réussie.");
        }
    }

    /** Croise sujets, references et compteurs en lot pour eviter une requete par ligne. */
    private List<AdminSkillPromptDto> toPromptDtos(List<SkillPrompt> prompts, Skill skill) {
        List<UUID> promptIds = prompts.stream().map(SkillPrompt::getId).toList();
        Map<UUID, List<SkillReference>> references = promptManager.findReferencesByPromptIds(promptIds);
        Map<UUID, Long> attemptCounts = attemptManager.countPerPromptForPromptIds(promptIds);

        List<AdminSkillPromptDto> dtos = new ArrayList<>(prompts.size());
        for (SkillPrompt prompt : prompts) {
            dtos.add(adminSkillMapper.toPromptDto(
                    prompt,
                    skill,
                    references.getOrDefault(prompt.getId(), List.of()),
                    attemptCounts.getOrDefault(prompt.getId(), 0L)));
        }
        return dtos;
    }
}
