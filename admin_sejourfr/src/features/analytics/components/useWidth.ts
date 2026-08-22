import { useLayoutEffect, useRef, useState } from "react";

/**
 * Largeur reellement occupee par un conteneur. Les graphes de cet ecran sont
 * du SVG calcule a la main : sans mesure, ils ne peuvent pas etre responsives.
 */
export function useWidth(fallback = 760) {
  const ref = useRef<HTMLDivElement | null>(null);
  const [width, setWidth] = useState(fallback);

  useLayoutEffect(() => {
    const element = ref.current;
    if (!element) return;

    const update = () => setWidth(element.clientWidth || fallback);
    update();

    const observer = new ResizeObserver(update);
    observer.observe(element);
    return () => observer.disconnect();
  }, [fallback]);

  return [ref, width] as const;
}
