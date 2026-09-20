import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import type { HistoryFilters, Item, Loan, Profile, ReportRow } from "@/types";

export function buildPreviewUrl(bucketId: string, filePath: string) {
  if (!filePath) return "";
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl) return "";
  
  // Note: if bucket is public, we can just return the public URL
  return `${supabaseUrl}/storage/v1/object/public/${bucketId}/${filePath}`;
}

export async function getCatalogItems() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("items")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Error fetching items:", error);
    return [];
  }
  
  return data.map(item => ({
    ...item,
    image_url: item.image_url || (item.image_id ? buildPreviewUrl("item-images", item.image_id) : "")
  })) as Item[];
}

export async function getItemById(itemId: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("items")
    .select("*")
    .eq("id", itemId)
    .single();

  if (error || !data) {
    console.error(`Failed to fetch item ${itemId}:`, error);
    return null;
  }

  return {
    ...data,
    image_url: data.image_url || (data.image_id ? buildPreviewUrl("item-images", data.image_id) : "")
  } as Item;
}

export async function getMyLoans(userId: string) {
  const supabase = await createClient();
  
  const { data, error } = await supabase
    .from("loans")
    .select(`
      *,
      item:item_id (*),
      borrower:borrower_id (*),
      admin:admin_id (*)
    `)
    .eq("borrower_id", userId)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Error fetching my loans:", error);
    return [];
  }

  return data.map((loan: any) => ({
    ...loan,
    return_image_url: loan.return_image_url || (loan.return_image_id ? buildPreviewUrl("return-images", loan.return_image_id) : undefined)
  })) as Loan[];
}

export async function getProfiles() {
  const supabase = await createAdminClient();
  const { data, error } = await supabase
    .from("profiles")
    .select("*");

  if (error) {
    console.error("Error fetching profiles:", error);
    return [];
  }
  return data as Profile[];
}

export async function getAllLoans() {
  const supabase = await createAdminClient();
  
  const { data, error } = await supabase
    .from("loans")
    .select(`
      *,
      item:item_id (*),
      borrower:borrower_id (*),
      admin:admin_id (*)
    `)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Error fetching all loans:", error);
    return [];
  }

  return data.map((loan: any) => ({
    ...loan,
    return_image_url: loan.return_image_url || (loan.return_image_id ? buildPreviewUrl("return-images", loan.return_image_id) : undefined)
  })) as Loan[];
}

export async function getAdminDashboardData() {
  try {
    const [loans, items, profiles] = await Promise.all([
      getAllLoans(),
      getCatalogItems(),
      getProfiles()
    ]);

    // 1. Calculate Status Distribution
    const statusCounts: Record<string, number> = {
      pending: 0,
      approved: 0,
      rejected: 0,
      returned: 0,
      overdue: 0
    };
    loans.forEach((loan) => {
      if (statusCounts[loan.status] !== undefined) {
        statusCounts[loan.status]++;
      }
    });

    const statusDistribution = Object.entries(statusCounts).map(([label, value]) => ({
      label: label.charAt(0).toUpperCase() + label.slice(1),
      value
    }));

    // 2. Calculate Monthly Trend (Last 6 Months)
    const last6Months = Array.from({ length: 6 }, (_, i) => {
      const d = new Date();
      d.setMonth(d.getMonth() - i);
      return {
        month: d.getMonth(),
        year: d.getFullYear(),
        label: d.toLocaleString("id-ID", { month: "short" }),
        value: 0
      };
    }).reverse();

    loans.forEach((loan) => {
      const loanDate = new Date(loan.borrow_date);
      const m = loanDate.getMonth();
      const y = loanDate.getFullYear();
      const monthData = last6Months.find((lm) => lm.month === m && lm.year === y);
      if (monthData) {
        monthData.value++;
      }
    });

    // 3. Calculate Return Trend
    const returnTrend = last6Months.map((m) => ({
      label: m.label,
      value: loans.filter((l) => {
        const d = new Date(l.actual_return_date || l.return_date);
        return d.getMonth() === m.month && d.getFullYear() === m.year && l.status === "returned";
      }).length
    }));

    // 4. Calculate Top Borrowers (Top 5)
    const borrowerCounts: Record<string, { name: string; count: number }> = {};
    loans.forEach((loan) => {
      const name = loan.borrower?.full_name || "Unknown";
      const id = loan.borrower_id;
      if (!borrowerCounts[id]) {
        borrowerCounts[id] = { name, count: 0 };
      }
      borrowerCounts[id].count++;
    });

    const topBorrowers = Object.values(borrowerCounts)
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map((b) => ({ label: b.name, value: b.count }));

    // 5. Calculate Frequent Late Returns (Top 5)
    const lateCounts: Record<string, { name: string; count: number }> = {};
    loans
      .filter((l) => l.status === "overdue" || (l.actual_return_date && new Date(l.actual_return_date) > new Date(l.return_date)))
      .forEach((loan) => {
        const name = loan.borrower?.full_name || "Unknown";
        const id = loan.borrower_id;
        if (!lateCounts[id]) {
          lateCounts[id] = { name, count: 0 };
        }
        lateCounts[id].count++;
      });

    const frequentLateReturns = Object.values(lateCounts)
      .sort((a, b) => b.count - a.count)
      .slice(0, 5)
      .map((b) => ({ label: b.name, value: b.count }));

    return {
      stats: [
        { label: "Total Barang", value: items.length, helper: "Item dalam inventaris", icon: "Boxes" },
        {
          label: "Pinjaman Aktif",
          value: loans.filter((loan) => loan.status === "approved" || loan.status === "overdue").length,
          helper: "Sedang dipinjam",
          icon: "ClipboardList"
        },
        { label: "Pengajuan Pending", value: loans.filter((loan) => loan.status === "pending").length, helper: "Menunggu review", icon: "Clock" },
        { label: "Pengguna", value: profiles.length, helper: "Akun perusahaan", icon: "Users" }
      ],
      recentLoans: loans.slice(0, 5),
      monthlyLoans: last6Months.map(({ label, value }) => ({ label, value })),
      statusDistribution,
      returnTrend,
      topBorrowers,
      frequentLateReturns
    };
  } catch (error) {
    console.error("Dashboard data fetch failed:", error);
    return {
      stats: [],
      recentLoans: [],
      monthlyLoans: [],
      statusDistribution: [],
      returnTrend: [],
      topBorrowers: [],
      frequentLateReturns: []
    };
  }
}

export async function getHistory(filters: HistoryFilters = {}) {
  const loans = await getAllLoans();

  return loans.filter((loan) => {
    if (filters.status && loan.status !== filters.status) return false;
    if (filters.borrowerId && loan.borrower_id !== filters.borrowerId) return false;
    if (filters.itemId && loan.item_id !== filters.itemId) return false;
    
    if (filters.search) {
      const search = filters.search.toLowerCase();
      const itemName = loan.item?.name?.toLowerCase() || "";
      const borrowerName = loan.borrower?.full_name?.toLowerCase() || "";
      if (!itemName.includes(search) && !borrowerName.includes(search)) return false;
    }

    if (filters.from) {
      const fromDate = new Date(filters.from);
      fromDate.setHours(0, 0, 0, 0);
      const loanDate = new Date(loan.borrow_date);
      if (loanDate < fromDate) return false;
    }

    if (filters.to) {
      const toDate = new Date(filters.to);
      toDate.setHours(23, 59, 59, 999);
      const loanDate = new Date(loan.borrow_date);
      if (loanDate > toDate) return false;
    }

    return true;
  });
}

export async function getReports(): Promise<ReportRow[]> {
  const loans = await getAllLoans();
  return loans.map((loan) => ({
    loanId: loan.id,
    itemName: loan.item?.name ?? loan.item_id,
    borrowerName: loan.borrower?.full_name ?? loan.borrower_id,
    status: loan.status,
    quantity: loan.quantity,
    borrowDate: loan.borrow_date,
    returnDate: loan.return_date,
    actualReturnDate: loan.actual_return_date
  })) as any[]; // Type assertion for compatibility if ReportRow diverges
}

export async function getActiveLoans() {
  const loans = await getAllLoans();
  return loans.filter((loan) => loan.status === "approved" || loan.status === "overdue");
}

export async function getCurrentUserProfile() {
  const supabase = await createClient();
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  
  if (authError || !user) {
    return null;
  }

  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("user_id", user.id)
    .single();

  if (error) {
    console.error("Failed to fetch user profile:", error);
    return null;
  }

  return data as Profile;
}
