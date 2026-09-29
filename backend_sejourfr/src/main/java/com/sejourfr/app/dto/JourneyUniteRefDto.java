package com.sejourfr.app.dto;

/**
 * <b>L'unite travaillable d'une etape, servie</b> — ce que le candidat travaille
 * a cette etape.
 *
 * <p>🛑 <b>Le patron du bloc servi</b> ({@link JourneyBlocRefDto}, D-47) : une
 * competence TCF et une unite officielle civique s'affichent par le <b>meme
 * chemin</b>. {@code JourneyStepDto} portait {@code skillCode} et
 * {@code skillTitle} — une etape civique n'a aucun {@code Skill}, et chaque
 * front aurait du brancher sur le module pour savoir quoi lire.
 *
 * <p>🛑 <b>{@code null} hors {@code TRAIN_SKILL}</b> : un examen ne travaille
 * aucune unite, un diagnostic non plus.
 *
 * @param code  l'identifiant stable — {@code EE1-C1}, {@code P2_LAICITE}. Une
 *              <b>cle</b>, jamais un affichage.
 * @param label ce que le <b>candidat lit</b> — « Decrire une experience »,
 *              « La laicite ».
 */
public record JourneyUniteRefDto(String code, String label) {}
