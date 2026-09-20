package com.sejourfr.app.dto;

import com.sejourfr.app.enums.JourneyStepType;
import com.sejourfr.app.enums.SkillSection;

import java.util.List;
import java.util.UUID;

/**
 * <b>L'ecran d'ETAPE</b> — les series a reussir pour valider une competence de
 * comprehension (CO/CE) ou une unite officielle civique (2026-09-20).
 *
 * <p>Jusqu'ici, une telle etape <b>lancait directement</b> une serie ciblee
 * depuis le Plan. Le candidat ne voyait ni combien de series il lui restait, ni
 * ce qu'il avait deja obtenu. L'ecran intermediaire montre les
 * {@link #quota()} cartes, leur etat, leur score, et permet de les lancer ou de
 * les refaire.
 *
 * <h2>🛑 Des faits, jamais des phrases</h2>
 * <p>Aucun {@code statusLabel}, aucun {@code subtitle}. Les fronts composent
 * « À faire », « Verrouillée », « Réussie », « À refaire » a partir de
 * {@link JourneySerieDto#locked()}, {@link JourneySerieDto#validee()} et de la
 * nullite de {@link JourneySerieDto#dernierScore()}. C'est la doctrine que
 * {@code JourneyStepDto} enonce deja.
 *
 * <h2>🛑 Le seuil de reussite est SERVI</h2>
 * <p>{@link #seuilReussite()} n'est jamais ecrit dans un front. Il se
 * <b>derive</b> cote serveur de {@code learning-plan.comprehension.solid-ratio}
 * et de {@link #questionsParSerie()} — 0,80 x 20 = 16 —, et c'est le <b>meme</b>
 * nombre qui decide de {@link JourneySerieDto#validee()}. Un « 16 » ecrit dans
 * deux fronts serait la 8<sup>e</sup> declaration de 0,80 du depot.
 *
 * @param stepId            l'etape, telle que {@code JourneyStepDto.id} la nomme.
 * @param type              toujours {@code TRAIN_SKILL} sur cet ecran : les
 *                          autres types d'etape ne se travaillent pas par
 *                          series. Servi quand meme, pour que le front n'ait
 *                          rien a supposer.
 * @param bloc              « Compréhension orale », ou la thematique civique.
 * @param unite             la competence TCF ou l'unite officielle civique —
 *                          code stable, libelle et <b>description</b>, meme
 *                          chemin d'affichage des deux cotes (D-47).
 * @param section           le domaine de la competence. 🛑 {@code null} en
 *                          civique : une unite officielle n'a pas de section.
 * @param objectif          ce vers quoi le candidat travaille — un palier
 *                          (« B2 ») ou une <b>mention</b> (« Naturalisation »),
 *                          <b>servi avec son libelle</b>. 🛑 C'est le patron
 *                          D-47 / A47 : une mention et un palier s'affichent par
 *                          le <b>meme chemin</b>, et aucun front ne branche sur
 *                          le module. Un {@code TargetLevel} ici aurait prive
 *                          l'ecran civique de son « Plan — Naturalisation ».
 *                          {@code null} si aucun objectif n'est declare.
 * @param priorite          cette etape vient d'une <b>priorite detectee par une
 *                          evaluation</b> ({@code severity_rank} pose a la
 *                          creation), par opposition a une etape ajoutee pour
 *                          une autre raison. C'est la pastille « Priorité ».
 * @param quota             cartes a reussir — {@code trainSeriesQuota} (2).
 * @param validees          cartes deja reussies, sur {@link #quota()}. 🛑 Servi,
 *                          et ce n'est pas un doublon des cartes : c'est le
 *                          <b>meme</b> nombre que le moteur compare au quota pour
 *                          clore l'etape ({@code JourneyReadService.etapesAuQuota}),
 *                          donc l'ecran ne peut pas annoncer « 1 sur 2 » sur une
 *                          etape que le serveur vient de clore. Le recompter cote
 *                          front aurait fait exister une seconde addition de la
 *                          meme chose.
 * @param questionsParSerie taille <b>nominale</b> d'une serie (20). C'est aussi
 *                          le denominateur de {@link JourneySerieDto#dernierScore()}.
 * @param seuilReussite     bonnes reponses qui rendent une serie reussie (16).
 * @param dureeEstimeeMin   ordre de grandeur annonce, en minutes — <b>jamais un
 *                          chrono</b> : rien ne chronometre une serie
 *                          d'entrainement. {@code null} si non calculable.
 * @param locked            le verrou <b>freemium</b> de l'etape, lu chez la meme
 *                          autorite que {@code JourneyStepDto.locked}. 🛑 Il est
 *                          distinct du verrou de <b>carte</b>
 *                          ({@link JourneySerieDto#locked()}) : l'un dit « vous
 *                          n'avez pas acces », l'autre « reussissez d'abord la
 *                          precedente ».
 * @param series            les cartes, dans l'ordre, <b>toujours {@link #quota()}
 *                          elements</b> — une carte jamais jouee est servie
 *                          quand meme, sinon l'ecran ne saurait pas combien il
 *                          en reste.
 */
public record JourneyStepDetailDto(
        UUID stepId,
        JourneyStepType type,
        JourneyBlocRefDto bloc,
        JourneyUniteDetailDto unite,
        SkillSection section,
        JourneyObjectifRefDto objectif,
        boolean priorite,
        int quota,
        int validees,
        int questionsParSerie,
        int seuilReussite,
        Integer dureeEstimeeMin,
        boolean locked,
        List<JourneySerieDto> series
) {}
