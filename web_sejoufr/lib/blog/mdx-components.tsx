import Link from "next/link";
import type { ComponentPropsWithoutRef } from "react";
import type { MDXRemoteProps } from "next-mdx-remote/rsc";
import { Callout } from "@/components/blog/mdx/Callout";
import { PullQuote } from "@/components/blog/mdx/PullQuote";
import { CTABox } from "@/components/blog/mdx/CTABox";
import { ImageWithCaption } from "@/components/blog/mdx/ImageWithCaption";
import { Steps, Step } from "@/components/blog/mdx/Steps";

/**
 * Composants disponibles dans les .mdx (`<Callout>`, `<Steps>`, etc.).
 * La typographie de base (h2/h3, p, ul, blockquote, table…) est gérée par
 * `.mdx-prose` dans `globals.css` — pas besoin de remapper chaque tag ici.
 * On garde uniquement `a` pour router les liens internes via `next/link`.
 */

type AnchorProps = ComponentPropsWithoutRef<"a">;

function MdxAnchor({ href = "#", children, ...rest }: AnchorProps) {
  const isExternal = /^https?:\/\//.test(href);
  if (isExternal) {
    return (
      <a href={href} target="_blank" rel="noopener noreferrer" {...rest}>
        {children}
      </a>
    );
  }
  return <Link href={href}>{children}</Link>;
}

export const mdxComponents: MDXRemoteProps["components"] = {
  Callout,
  PullQuote,
  CTABox,
  ImageWithCaption,
  Steps,
  Step,
  a: MdxAnchor,
};
