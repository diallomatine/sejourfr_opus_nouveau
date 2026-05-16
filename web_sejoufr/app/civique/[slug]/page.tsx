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
  const category = getCategory("CIVIQUE", slug);
  const title = category?.name ?? slug.replace(/-/g, " ");
  return {
    title: `Entraînement civique : ${title}`,
    description:
      category?.description ??
      `Entraînez-vous aux questions du module civique sur ${title}.`,
    alternates: { canonical: `/civique/${slug}` },
  };
}

export function generateStaticParams() {
  return getValidSlugs("CIVIQUE").map((slug) => ({ slug }));
}

export default async function CiviqueCategoryPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const category = getCategory("CIVIQUE", slug);
  if (!category) notFound();
  return (
    <CategoryLanding category={category} basePath="/civique" accent="blue" />
  );
}
