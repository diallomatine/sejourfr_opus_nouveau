import { createContext, useCallback, useContext, useMemo, useState } from "react";
import type { ReactNode } from "react";
import styles from "./Toast.module.css";

interface Toast {
  id: number;
  message: string;
  detail?: string;
  tone: "info" | "success" | "error";
}

interface ToastContextValue {
  show: (message: string, tone?: Toast["tone"], detail?: string) => void;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const show = useCallback((message: string, tone: Toast["tone"] = "info", detail?: string) => {
    const id = Date.now() + Math.random();
    setToasts((current) => [...current, { id, message, detail, tone }]);
    setTimeout(() => {
      setToasts((current) => current.filter((t) => t.id !== id));
    }, 3500);
  }, []);

  const value = useMemo(() => ({ show }), [show]);

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className={styles.container} role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`${styles.toast} ${styles[t.tone]}`}>
            <strong className={styles.message}>{t.message}</strong>
            {t.detail && <span className={styles.detail}>{t.detail}</span>}
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast doit etre utilise dans un ToastProvider");
  return ctx;
}
