package com.sejourfr.app.dto;

import com.sejourfr.app.enums.AdminAccessOperationType;

/** Une action proposée pour un produit dans l'état où il est (servie, jamais déduite par le front). */
public record AdminAccessOperationOptionDto(AdminAccessOperationType code, String label) {}
