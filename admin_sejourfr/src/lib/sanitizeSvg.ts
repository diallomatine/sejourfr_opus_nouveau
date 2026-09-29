import DOMPurify from "dompurify";

/**
 * Assainit un fragment SVG inline avant injection via
 * `dangerouslySetInnerHTML`. La source (drafts generes par IA, images
 * remplacees cote admin) n'est pas strictement fiable : un SVG peut porter
 * des handlers d'evenements ou un `<foreignObject>` avec du HTML executable.
 * Le profil SVG de DOMPurify retire scripts, attributs `on*` et balises
 * dangereuses tout en preservant le rendu du dessin.
 */
export function sanitizeSvg(svg: string | null | undefined): string {
  if (!svg) return "";
  return DOMPurify.sanitize(svg, {
    USE_PROFILES: { svg: true, svgFilters: true },
  });
}
