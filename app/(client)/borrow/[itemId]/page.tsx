import { notFound } from "next/navigation";
import { BorrowForm } from "@/components/forms/borrow-form";
import { BorrowSummary } from "@/components/client/borrow-summary";
import { getItemById } from "@/lib/supabase/queries";
import { getCurrentUserProfile } from "@/lib/supabase/queries";

export const dynamic = "force-dynamic";

export default async function BorrowPage({ params }: { params: Promise<{ itemId: string }> }) {
  const { itemId } = await params;
  const item = await getItemById(itemId);
  const user = await getCurrentUserProfile();

  if (!item || !user) {
    notFound();
  }

  return (
    <div className="grid gap-8 lg:grid-cols-[1.1fr,0.9fr]">
      <BorrowSummary item={item} />
      <BorrowForm item={item} userId={user.user_id} userName={user.full_name} />
    </div>
  );
}
