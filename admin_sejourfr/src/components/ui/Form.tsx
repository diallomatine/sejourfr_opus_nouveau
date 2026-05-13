import type {
  InputHTMLAttributes,
  SelectHTMLAttributes,
  TextareaHTMLAttributes,
  ReactNode,
} from "react";
import styles from "./Form.module.css";

interface FormRowProps {
  label?: string;
  htmlFor?: string;
  error?: string;
  children: ReactNode;
  twoCol?: boolean;
}

export function FormRow({ label, htmlFor, error, children, twoCol }: FormRowProps) {
  return (
    <div className={`${styles.row} ${twoCol ? styles.twoCol : ""}`}>
      {label && (
        <label className={styles.label} htmlFor={htmlFor}>
          {label}
        </label>
      )}
      {children}
      {error && <div className={styles.error}>{error}</div>}
    </div>
  );
}

export function Input(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={`${styles.input} ${props.className ?? ""}`} />;
}

export function Select(props: SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select {...props} className={`${styles.input} ${props.className ?? ""}`} />
  );
}

export function Textarea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea {...props} className={`${styles.textarea} ${props.className ?? ""}`} />
  );
}
