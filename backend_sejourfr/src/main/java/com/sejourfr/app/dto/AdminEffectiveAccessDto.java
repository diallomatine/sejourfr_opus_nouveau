package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.Module;

import java.util.List;

/**
 * Lecture « en 5 secondes » de l'accès effectif (GO §2) : « Produit effectif :
 * Intégral / Modules ouverts : TCF + Civique ». Calculé serveur.
 */
public record AdminEffectiveAccessDto(
        ModuleAccess effectiveProduct,
        String effectiveProductLabel,
        List<Module> openModules,
        String openModulesLabel
) {}
