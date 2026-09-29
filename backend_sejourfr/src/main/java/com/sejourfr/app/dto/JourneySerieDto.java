package com.sejourfr.app.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * <b>Une CARTE de serie</b> de l'ecran d'etape — « Serie 1 », « Serie 2 ».
 *
 * <h2>🛑 {@link #validee()} est SERVI, et ce n'est pas negociable</h2>
 * <p>Sans lui, un front comparerait {@link #dernierScore()} au
 * {@code seuilReussite} de l'etape — c'est-a-dire qu'il <b>classerait un nombre
 * en etat pedagogique</b>, ce que le depot interdit explicitement (« aucun front
 * ne classe un nombre en etat pedagogique »). Le front <b>affiche</b> le score
 * et <b>lit</b> l'etat ; il ne compare jamais.
 *
 * <h2>🛑 Aucune phrase servie</h2>
 * <p>Ni {@code statusLabel}, ni {@code subtitle}. « À faire », « Verrouillée »,
 * « Réussie », « À refaire » sont composes par les fronts a partir de
 * {@link #locked()}, {@link #validee()} et de la nullite de
 * {@link #dernierScore()} — meme doctrine que {@code JourneyStepDto}, qui le dit
 * mot pour mot.
 *
 * @param index         le rang de la carte : 1, 2. Le nombre de cartes est le
 *                      {@code quota} de l'etape, servi a cote.
 * @param locked        <b>la carte precedente n'est pas REUSSIE</b> — pas
 *                      « pas faite » : reussie. La carte 1 n'est jamais
 *                      verrouillee par ce motif. 🛑 Le verrou <b>freemium</b> de
 *                      l'etape est servi a part
 *                      ({@code JourneyStepDetailDto.locked}) : ce sont deux
 *                      cadenas differents, et les confondre en un seul
 *                      empecherait l'ecran de dire lequel s'applique.
 * @param validee       <b>reussie au moins une fois — DEFINITIF</b>. Refaire la
 *                      serie et la rater ne la devalide pas : le travail acquis
 *                      reste acquis. C'est pourquoi {@link #dernierScore()} peut
 *                      etre sous le seuil sur une carte validee, et c'est voulu.
 * @param dernierScore  bonnes reponses du <b>dernier</b> essai, sur
 *                      {@code questionsParSerie}. {@code null} si la carte n'a
 *                      jamais ete jouee <b>ou</b> si l'essai en cours n'est pas
 *                      termine : 🛑 <b>{@code null} = inconnu, jamais mauvais</b>,
 *                      surtout pas zero.
 * @param dernierAttemptId la session du dernier essai — c'est par elle que le
 *                      candidat relit son resultat corrige, comme pour une serie
 *                      de « Réviser ». {@code null} si jamais jouee.
 * @param dernierEssaiAt quand le dernier essai a ete lance. {@code null} si
 *                      jamais jouee.
 */
public record JourneySerieDto(
        int index,
        boolean locked,
        boolean validee,
        Integer dernierScore,
        UUID dernierAttemptId,
        Instant dernierEssaiAt
) {}
