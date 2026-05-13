import type { ButtonHTMLAttributes, ReactNode } from "react";
import styles from "./Button.module.css";

type Variant = "primary" | "ghost" | "red" | "danger" | "default";
type Size = "sm" | "md";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  children: ReactNode;
}

export function Button({
  variant = "default",
  size = "md",
  className,
  children,
  ...props
}: ButtonProps) {
  const classes = [
    styles.btn,
    styles[variant],
    size === "sm" ? styles.sm : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <button className={classes} {...props}>
      {children}
    </button>
  );
}
