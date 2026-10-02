package com.sejourfr.app.dto;

import com.sejourfr.app.enums.ModuleAccess;
import com.sejourfr.app.enums.Module;

import java.util.List;

/**
 * Un produit sur lequel l'admin peut agir (GO §1) : les produits réellement
 * vendus, jamais une liste codée en dur dans le front. {@code modules} dit ce
 * que le produit ouvre (Intégral = TCF + Civique).
 */
public record AdminAccessProductDto(
        ModuleAccess code,
        String label,
        List<Module> modules,
        String modulesLabel
) {}
