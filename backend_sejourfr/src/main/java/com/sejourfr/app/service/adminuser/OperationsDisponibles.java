package com.sejourfr.app.service.adminuser;

import com.sejourfr.app.enums.AdminAccessOperationType;
import com.sejourfr.app.enums.ProductAccessStatus;

import java.util.ArrayList;
import java.util.List;

/**
 * Les actions proposées pour un produit selon son statut — exactement les
 * préconditions qu'{@link AdminAccessOperationService} oppose (409 sinon) :
 * le front n'en déduit rien, il affiche ce qui est servi.
 */
final class OperationsDisponibles {

    private OperationsDisponibles() {}

    /**
     * @param terminable faux pour Civique quand Intégral est actif : « Terminer
     *                   Civique » serait sans effet (Intégral l'ouvre), l'API le
     *                   refuse en 409 — on ne le propose pas.
     */
    static List<AdminAccessOperationType> pour(ProductAccessStatus statut, boolean terminable) {
        List<AdminAccessOperationType> out = new ArrayList<>();
        switch (statut) {
            case ACTIVE -> {
                out.add(AdminAccessOperationType.EXTEND);
                out.add(AdminAccessOperationType.SHORTEN);
                if (terminable) out.add(AdminAccessOperationType.END);
                out.add(AdminAccessOperationType.CORRECT_PRODUCT);
                out.add(AdminAccessOperationType.GRANT);
            }
            case SCHEDULED -> {
                out.add(AdminAccessOperationType.GRANT);
                if (terminable) out.add(AdminAccessOperationType.END);
            }
            case REVOKED, EXPIRED -> out.add(AdminAccessOperationType.REACTIVATE);
            case NONE -> out.add(AdminAccessOperationType.GRANT);
        }
        return out;
    }
}
