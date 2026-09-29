package com.sejourfr.app.progression.manager;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.entity.LearningEvidenceRecord;
import com.sejourfr.app.progression.repository.LearningEvidenceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Le seul accès au registre des preuves. */
@Component
@RequiredArgsConstructor
@Slf4j
public class LearningEvidenceManager {

    private final LearningEvidenceRepository repository;

    /**
     * Enregistre la preuve, ou <b>ne fait rien</b> si sa clé naturelle existe
     * déjà (§42, T12).
     *
     * <p><b>Deux garde-fous, et ils ne sont pas redondants.</b>
     *
     * <ul>
     *   <li>Le contrôle applicatif couvre le cas réel et fréquent — le même
     *       retry rejoué séquentiellement — sans jamais salir la transaction en
     *       cours.</li>
     *   <li>La contrainte {@code learning_evidence_natural_key_unique} couvre la
     *       course : deux requêtes vraiment simultanées passent toutes les deux
     *       le contrôle, et c'est la base qui tranche.</li>
     * </ul>
     *
     * <p>On ne rattrape <b>pas</b> cette violation ici : sous PostgreSQL, une
     * contrainte violée avorte toute la transaction, et continuer dedans échoue
     * sur la requête suivante avec un message qui ne parle plus du vrai
     * problème. Le perdant de la course remonte donc son erreur — l'appelant
     * est best-effort et la journalise — pendant que le gagnant a déjà écrit
     * exactement la même preuve. La progression, elle, est juste dans les deux
     * cas.
     *
     * @return la preuve enregistrée, ou vide si c'était un doublon connu
     */
    public Optional<LearningEvidenceRecord> enregistrerSiNouvelle(LearningEvidenceRecord record) {
        if (repository.existsByUserIdAndNaturalKey(record.getUserId(), record.getNaturalKey())) {
            log.debug("Preuve déjà enregistrée, ignorée : user={} key={}",
                    record.getUserId(), record.getNaturalKey());
            return Optional.empty();
        }
        return Optional.of(repository.saveAndFlush(record));
    }

    public boolean existe(UUID userId, String naturalKey) {
        return repository.existsByUserIdAndNaturalKey(userId, naturalKey);
    }

    public List<LearningEvidenceRecord> historiqueDomaine(UUID userId, SkillSection section) {
        return repository.findByUserIdAndSectionOrderByOccurredAtAsc(userId, section);
    }

    public List<LearningEvidenceRecord> historiqueCompetence(UUID userId, SkillSection section,
                                                             String skillId) {
        return repository.findByUserIdAndSectionAndSkillIdOrderByOccurredAtAsc(
                userId, section, skillId);
    }

    public List<LearningEvidenceRecord> historiqueComplet(UUID userId) {
        return repository.findByUserIdOrderByOccurredAtAsc(userId);
    }

    public List<LearningEvidenceRecord> seriesRecentes(UUID userId, SkillSection section,
                                                       TargetLevel level, Instant depuis) {
        return repository.findSeriesRecentes(userId, section, level, depuis);
    }

    public List<LearningEvidenceRecord> examensQualifiants(UUID userId, SkillSection section,
                                                           TargetLevel level,
                                                           Instant apres, Instant avant) {
        return repository.findExamensQualifiants(userId, section, level, apres, avant);
    }
}
