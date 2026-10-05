import { CatalogView } from "@/components/client/catalog-view";
import { getCatalogItems } from "@/lib/supabase/queries";

export const dynamic = "force-dynamic";

export default async function CatalogPage() {
  const items = await getCatalogItems();

  return <CatalogView items={items} />;
}
