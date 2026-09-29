import type { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { isAuthenticated, user } = useAuth();
  const location = useLocation();

  // Le garde reste cosmetique (la vraie barriere est ROLE_ADMIN cote backend
  // sur /api/admin/**), mais on aligne la condition sur le role pour la
  // coherence : un user non-ADMIN ne voit pas l'UI admin.
  if (!isAuthenticated || user?.role !== "ADMIN") {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  }

  return <>{children}</>;
}
