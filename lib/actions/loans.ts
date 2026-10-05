"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUserProfile } from "@/lib/supabase/queries";
import { loanDecisionSchema, loanRequestSchema, requestReturnSchema, returnLoanSchema } from "@/lib/validators/loans";
import type { ActionResult, LoanStatus, Loan } from "@/types";

export async function uploadReturnImage(formData: FormData): Promise<ActionResult<string>> {
  try {
    const file = formData.get("file") as File;
    if (!file) return { success: false, error: "Tidak ada file yang diunggah." };

    const supabase = await createAdminClient();
    const fileExt = file.name.split('.').pop();
    const fileName = `${Math.random().toString(36).substring(2)}_${Date.now()}.${fileExt}`;

    const { data, error } = await supabase
      .storage
      .from("return-images")
      .upload(fileName, file);

    if (error) {
      return { success: false, error: error.message };
    }

    return { success: true, data: data.path };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal mengunggah gambar." };
  }
}

async function updateLoanStatus(
  loanId: string, 
  status: LoanStatus, 
  admin_note?: string, 
  actual_return_date?: string, 
  admin_image_id?: string,
  extras?: object
) {
  const profile = await getCurrentUserProfile();
  
  const payload = {
    status,
    admin_id: profile?.user_id || null,
    admin_note: admin_note || null,
    ...(actual_return_date ? { actual_return_date } : {}),
    ...(admin_image_id ? { admin_image_id } : {}),
    ...extras
  };

  const supabase = await createAdminClient();
  const { data, error } = await supabase
    .from("loans")
    .update(payload)
    .eq("id", loanId)
    .select()
    .single();
    
  if (error) throw new Error(error.message);
  return data;
}

export async function createLoanRequest(input: unknown): Promise<ActionResult> {
  try {
    const values = loanRequestSchema.parse(input);
    const profile = await getCurrentUserProfile();

    if (!profile) {
      return { success: false, error: "Sesi pengguna tidak ditemukan." };
    }

    const supabase = await createClient();
    const { data, error } = await supabase
      .from("loans")
      .insert({
        ...values,
        borrower_id: profile.user_id,
        status: "pending",
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal membuat pengajuan pinjaman." };
  }
}

export async function approveLoan(input: unknown): Promise<ActionResult> {
  try {
    const values = loanDecisionSchema.parse(input);

    const supabase = await createAdminClient();
    
    // Get loan
    const { data: loan, error: loanError } = await supabase
      .from("loans")
      .select("*")
      .eq("id", values.loanId)
      .single();
      
    if (loanError || !loan) throw new Error(loanError?.message || "Loan not found");

    // Get item
    const { data: item, error: itemError } = await supabase
      .from("items")
      .select("*")
      .eq("id", loan.item_id)
      .single();
      
    if (itemError || !item) throw new Error(itemError?.message || "Item not found");

    const nextAvailable = Number(item.quantity_available) - Number(loan.quantity);

    if (nextAvailable < 0) {
      return { success: false, error: "Stok tersedia tidak mencukupi." };
    }

    // Update item
    await supabase
      .from("items")
      .update({ quantity_available: nextAvailable })
      .eq("id", item.id);

    const updatedLoan = await updateLoanStatus(values.loanId, "approved", values.admin_note, undefined, values.admin_image_id);
    return { success: true, data: updatedLoan };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal menyetujui pinjaman." };
  }
}

export async function rejectLoan(input: unknown): Promise<ActionResult> {
  try {
    const values = loanDecisionSchema.parse(input);

    const updatedLoan = await updateLoanStatus(values.loanId, "rejected", values.admin_note, undefined, values.admin_image_id);
    return { success: true, data: updatedLoan };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal menolak pinjaman." };
  }
}

export async function markLoanReturned(input: unknown): Promise<ActionResult> {
  try {
    const values = returnLoanSchema.parse(input);

    const supabase = await createAdminClient();
    
    // Get loan
    const { data: loan } = await supabase
      .from("loans")
      .select("*")
      .eq("id", values.loanId)
      .single();
      
    // Get item
    const { data: item } = await supabase
      .from("items")
      .select("*")
      .eq("id", loan.item_id)
      .single();

    // Update item quantity
    await supabase
      .from("items")
      .update({ quantity_available: Number(item.quantity_available) + Number(loan.quantity) })
      .eq("id", item.id);

    const updatedLoan = await updateLoanStatus(values.loanId, "returned", values.admin_note, values.actual_return_date);
    return { success: true, data: updatedLoan };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal mengonfirmasi pengembalian." };
  }
}

export async function requestReturn(input: unknown): Promise<ActionResult> {
  try {
    const values = requestReturnSchema.parse(input);

    const updatedLoan = await updateLoanStatus(values.loanId, "returning", undefined, undefined, undefined, {
      return_image_id: values.return_image_id,
      user_note: values.user_note
    });

    return { success: true, data: updatedLoan };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal mengajukan pengembalian." };
  }
}

export async function deleteLoan(loanId: string): Promise<ActionResult> {
  try {
    const supabase = await createAdminClient();
    const { error } = await supabase
      .from("loans")
      .delete()
      .eq("id", loanId);

    if (error) throw new Error(error.message);

    return { success: true };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal menghapus data pinjaman." };
  }
}

export async function deleteAllLoans(): Promise<ActionResult> {
  try {
    const supabase = await createAdminClient();
    
    // Delete all loans without condition isn't supported directly safely in Postgrest unless explicitly allowed
    // But we can delete where id is not null
    const { error } = await supabase
      .from("loans")
      .delete()
      .neq("id", "00000000-0000-0000-0000-000000000000"); // Just a dummy condition to match everything

    if (error) throw new Error(error.message);

    return { success: true };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal menghapus semua data pinjaman." };
  }
}
