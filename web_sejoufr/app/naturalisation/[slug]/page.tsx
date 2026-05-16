import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { CategoryLanding } from "@/features/modules/CategoryLanding";
import { getCategory, getValidSlugs } from "@/lib/modules-data";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const category = getCategory("NATURALISATION", slug);
  const title = category?.name ?? slug.replace(/-/g, " ");
  return {
    title: `Entraînement naturalisation : ${title}`,
    description:
      category?.description ??
      `Entraînez-vous aux questions de naturalisation sur ${title}.`,
    alternates: { canonical: `/naturalisation/${slug}` },
  };
}

export function generateStaticParams() {
  return getValidSlugs("NATURALISATION").map((slug) => ({ slug }));
}

export default async function NaturalisationCategoryPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const category = getCategory("NATURALISATION", slug);
  if (!category) notFound();
  return (
    <CategoryLanding category={category} basePath="/naturalisation" accent="red" />
  );
}
