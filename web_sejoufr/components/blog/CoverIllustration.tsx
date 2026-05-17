import Image from "next/image";
import {
  Building2,
  Compass,
  FileText,
  Flag,
  GraduationCap,
  Landmark,
  Lightbulb,
  MessagesSquare,
  Newspaper,
  Scale,
  ScrollText,
  Sparkles,
  type LucideIcon,
} from "lucide-react";
import { categoryTone, getCategory } from "@/lib/blog/categories";
import type { ArticleCategorySlug } from "@/lib/blog/types";

const ICONS: Record<string, LucideIcon> = {
  building: Building2,
  compass: Compass,
  fileText: FileText,
  flag: Flag,
  graduation: GraduationCap,
  landmark: Landmark,
  lightbulb: Lightbulb,
  messages: MessagesSquare,
  newspaper: Newspaper,
  scale: Scale,
  scroll: ScrollText,
  sparkles: Sparkles,
};

interface Props {
  category: ArticleCategorySlug;
  iconKey?: string;
  /** "card" : ratio 16/10 + petite icône. "hero" : 21/9 + icône XL. */
  variant?: "card" | "hero";
  title?: string;
  fillHeight?: boolean;
  /** URL d'une image de couverture (ex: Unsplash). Si fournie, remplace l'icône. */
  imageUrl?: string;
  /** Alt textuel pour l'image. Fallback : `title`. */
  imageAlt?: string;
}

/**
 * Couverture éditoriale d'article.
 *
 * Si `imageUrl` est fourni → `next/image` en `fill` avec `object-fit: cover`
 * et un léger voile de scrim sombre pour garantir la lisibilité d'un éventuel
 * overlay.
 *
 * Sinon → gradient catégorie + icône Lucide centrée + motif radial décoratif
 * (fallback 100 % CSS, pas d'image externe, pas de CLS).
 */
export function CoverIllustration({
  category,
  iconKey,
  variant = "card",
  title,
  fillHeight = false,
  imageUrl,
  imageAlt,
}: Props) {
  const meta = getCategory(category);
  const tone = categoryTone(meta.color);
  const Icon = (iconKey && ICONS[iconKey]) || ICONS.newspaper;

  const className =
    "cover-illustration cover-illustration--" +
    variant +
    (fillHeight ? " cover-illustration--fill" : "");

  if (imageUrl) {
    const alt = imageAlt ?? title ?? "";
    return (
      <div
        aria-hidden={!alt}
        role={alt ? "img" : undefined}
        aria-label={alt}
        className={className}
      >
        <Image
          src={imageUrl}
          alt={alt}
          fill
          sizes={
            variant === "hero"
              ? "(min-width: 1024px) 900px, 100vw"
              : "(min-width: 1024px) 400px, 100vw"
          }
          className="cover-illustration-image"
          priority={variant === "hero"}
        />
        <span aria-hidden className="cover-illustration-scrim" />
        {variant === "hero" && (
          <span className="cover-illustration-tag cover-illustration-tag--image">
            {meta.name}
          </span>
        )}
        <CoverStyles />
      </div>
    );
  }

  return (
    <div
      aria-hidden={!title}
      role={title ? "img" : undefined}
      aria-label={title}
      className={className}
      style={{
        background: `linear-gradient(135deg, ${tone.coverFrom}, ${tone.coverTo})`,
      }}
    >
      <span aria-hidden className="cover-illustration-glow" />
      <span aria-hidden className="cover-illustration-shadow" />
      <div className="cover-illustration-inner">
        <span className="cover-illustration-icon-wrap">
          <Icon className="cover-illustration-icon" strokeWidth={1.6} />
        </span>
        {variant === "hero" && (
          <span className="cover-illustration-tag">{meta.name}</span>
        )}
      </div>
      <CoverStyles />
    </div>
  );
}

function CoverStyles() {
  return (
    <style>{`
      .cover-illustration {
        position: relative;
        overflow: hidden;
        color: #fff;
        width: 100%;
      }
      .cover-illustration--card {
        aspect-ratio: 16 / 10;
      }
      .cover-illustration--hero {
        aspect-ratio: 21 / 9;
      }
      .cover-illustration--fill {
        height: 100%;
        aspect-ratio: auto;
        min-height: 240px;
      }
      @media (min-width: 1024px) {
        .cover-illustration--fill {
          min-height: 320px;
        }
      }
      .cover-illustration-glow {
        position: absolute;
        inset: 0;
        pointer-events: none;
        background:
          radial-gradient(
            circle at 85% -10%,
            rgba(255, 255, 255, 0.22),
            transparent 60%
          ),
          radial-gradient(
            circle at -10% 110%,
            rgba(0, 0, 0, 0.18),
            transparent 60%
          );
      }
      .cover-illustration-shadow {
        position: absolute;
        inset: 0;
        background: linear-gradient(
          180deg,
          transparent 40%,
          rgba(0, 0, 0, 0.18) 100%
        );
        pointer-events: none;
      }
      .cover-illustration-inner {
        position: relative;
        height: 100%;
        width: 100%;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 18px;
        gap: 16px;
      }
      @media (min-width: 1024px) {
        .cover-illustration-inner {
          padding: 24px;
        }
      }
      .cover-illustration-icon-wrap {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 72px;
        height: 72px;
        border-radius: 18px;
        background: rgba(255, 255, 255, 0.16);
        backdrop-filter: blur(6px);
      }
      .cover-illustration--hero .cover-illustration-icon-wrap {
        width: 104px;
        height: 104px;
        border-radius: 24px;
      }
      @media (min-width: 1024px) {
        .cover-illustration--hero .cover-illustration-icon-wrap {
          width: 136px;
          height: 136px;
        }
      }
      .cover-illustration-icon {
        width: 36px;
        height: 36px;
      }
      .cover-illustration--hero .cover-illustration-icon {
        width: 56px;
        height: 56px;
      }
      @media (min-width: 1024px) {
        .cover-illustration--hero .cover-illustration-icon {
          width: 72px;
          height: 72px;
        }
      }
      .cover-illustration-tag {
        display: inline-flex;
        padding: 5px 12px;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.16);
        backdrop-filter: blur(6px);
        font-family: var(--font-mono);
        font-size: 11px;
        letter-spacing: 0.18em;
        text-transform: uppercase;
        font-weight: 600;
      }
      .cover-illustration-image {
        object-fit: cover;
      }
      .cover-illustration-scrim {
        position: absolute;
        inset: 0;
        pointer-events: none;
        background: linear-gradient(
          180deg,
          rgba(15, 24, 57, 0) 55%,
          rgba(15, 24, 57, 0.35) 100%
        );
      }
      .cover-illustration-tag--image {
        position: absolute;
        bottom: 16px;
        left: 16px;
        background: rgba(15, 24, 57, 0.7);
      }
      @media (min-width: 1024px) {
        .cover-illustration-tag--image {
          bottom: 20px;
          left: 20px;
        }
      }
    `}</style>
  );
}
