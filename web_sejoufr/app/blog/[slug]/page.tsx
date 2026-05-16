import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { MDXRemote } from "next-mdx-remote/rsc";
import rehypeSlug from "rehype-slug";
import rehypeAutolinkHeadings from "rehype-autolink-headings";
import remarkGfm from "remark-gfm";
import {
  getAllSlugs,
  getArticleBySlug,
  getRelatedArticles,
} from "@/lib/blog/articles";
import { mdxComponents } from "@/lib/blog/mdx-components";
import { ArticleHeader } from "@/components/blog/ArticleHeader";
import { ArticleFooter } from "@/components/blog/ArticleFooter";
import { ArticleProgressBar } from "@/components/blog/ArticleProgressBar";
import { RelatedArticles } from "@/components/blog/RelatedArticles";
import { NewsletterCTA } from "@/components/blog/NewsletterCTA";
import { SITE } from "@/lib/site";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export function generateStaticParams() {
  return getAllSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const article = getArticleBySlug(slug);
  if (!article) {
    return { title: "Article introuvable" };
  }
  const url = `${SITE.url}/blog/${article.slug}`;
  const title = article.seo?.title ?? `${article.title} | Blog ${SITE.name}`;
  const description = article.seo?.description ?? article.excerpt;
  return {
    title,
    description,
    alternates: { canonical: `/blog/${article.slug}` },
    keywords: article.tags,
    authors: [{ name: article.author.name }],
    openGraph: {
      type: "article",
      url,
      title,
      description,
      publishedTime: article.publishedAt,
      modifiedTime: article.updatedAt ?? article.publishedAt,
      authors: [article.author.name],
      tags: article.tags,
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
    },
  };
}

export default async function BlogArticlePage({ params }: PageProps) {
  const { slug } = await params;
  const article = getArticleBySlug(slug);
  if (!article) notFound();

  const url = `${SITE.url}/blog/${article.slug}`;
  const related = getRelatedArticles(
    { slug: article.slug, category: article.category },
    3,
  );

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: article.title,
    description: article.excerpt,
    datePublished: article.publishedAt,
    dateModified: article.updatedAt ?? article.publishedAt,
    author: { "@type": "Person", name: article.author.name },
    publisher: {
      "@type": "Organization",
      name: SITE.name,
      url: SITE.url,
    },
    mainEntityOfPage: { "@type": "WebPage", "@id": url },
    inLanguage: "fr-FR",
    keywords: article.tags.join(", "),
    articleSection: article.category,
  };

  return (
    <>
      <ArticleProgressBar />
      <article className="blog-article container-x">
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        <ArticleHeader article={article} />

        <div className="mdx-prose">
          <MDXRemote
            source={article.content}
            components={mdxComponents}
            options={{
              mdxOptions: {
                remarkPlugins: [remarkGfm],
                rehypePlugins: [
                  rehypeSlug,
                  [
                    rehypeAutolinkHeadings,
                    {
                      behavior: "wrap",
                      properties: { className: ["heading-anchor"] },
                    },
                  ],
                ],
              },
            }}
          />
        </div>

        <ArticleFooter article={article} url={url} />

        <div className="blog-article-newsletter">
          <NewsletterCTA source={`blog-${article.slug}`} variant="inline" />
        </div>
      </article>

      <div className="blog-article-related container-x">
        <RelatedArticles articles={related} />
      </div>

      <style>{`
        .blog-article {
          padding-top: 28px;
          padding-bottom: 48px;
          max-width: 780px;
        }
        @media (min-width: 768px) {
          .blog-article {
            padding-top: 40px;
            padding-bottom: 64px;
          }
        }
        .blog-article-newsletter {
          margin-top: 48px;
        }
        @media (min-width: 1024px) {
          .blog-article-newsletter {
            margin-top: 56px;
          }
        }
        .blog-article-related {
          max-width: 1180px;
          padding-bottom: 72px;
        }
        @media (min-width: 1024px) {
          .blog-article-related {
            padding-bottom: 96px;
          }
        }
      `}</style>
    </>
  );
}
