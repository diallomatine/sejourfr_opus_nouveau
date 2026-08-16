package com.sejourfr.app.dto;

import com.sejourfr.app.enums.TargetProcedure;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Création de compte ({@code POST /api/auth/register}).
 *
 * <p><b>{@code targetProcedure} est FACULTATIF</b>, et c'est volontaire : le web
 * fait choisir la démarche sur l'écran de compte qui clôt le diagnostic (le
 * candidat vient de produire, on lui demande son objectif au même endroit),
 * alors que le mobile a son écran de parcours dédié ({@code /target-path}) et
 * n'envoie donc rien ici. Une inscription sans démarche reste parfaitement
 * valide — on ne devine jamais une démarche à la place du candidat.
 *
 * <p><b>Le palier de français n'est PAS dans ce payload</b> et ne le sera
 * jamais : il est posé par le serveur depuis la démarche
 * ({@link TargetProcedure#getRequiredTcfLevel()}), par l'unique point d'écriture
 * {@code MeService.updateTargetProcedure}. Une valeur de démarche inconnue est
 * refusée en 400 par la désérialisation — jamais persistée, jamais ignorée en
 * silence : c'est ce silence (le champ n'existait pas côté serveur) qui a créé
 * des comptes sans objectif alors que le candidat en avait choisi un.
 */
public record RegisterRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(min = 8, message = "Le mot de passe doit faire au moins 8 caractères") String password,
        @NotBlank String firstName,
        @NotBlank String lastName,
        TargetProcedure targetProcedure
) {}
