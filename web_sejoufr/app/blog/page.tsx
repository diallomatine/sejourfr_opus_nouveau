import type { Metadata } from "next";
import {
  BlogIndexView,
  BLOG_INDEX_DESCRIPTION,
} from "@/components/blog/BlogIndexView";
import { getBlogPage } from "@/lib/blog/articles";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Blog — Examen civique, TCF IRN, titre de séjour, naturalisation",
  description: BLOG_INDEX_DESCRIPTION,
  alternates: { canonical: "/blog" },
  openGraph: {
    title: `Blog ${SITE.name}`,
    description:
      "Guides et actualités pour le TCF IRN, le titre de séjour, la naturalisation et l'examen civique.",
    url: `${SITE.url}/blog`,
    type: "website",
  },
};

export default function BlogIndexPage() {
  return <BlogIndexView data={getBlogPage(1)} />;
}
