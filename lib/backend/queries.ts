import "server-only";
import { database } from "@/lib/supabase/db";
import { buildPreviewUrl } from "@/lib/backend/images";
import { currentProfile, requireProfile, requireAdmin } from "@/lib/auth/session";
import type { HistoryFilters, Item, Loan, Profile, ReportRow } from "@/types";
import { teamActivity } from "./team-activity";
import { adminContacts } from "./admin-contacts";

export async function getCurrentUserProfile() { return currentProfile(); }

function itemImages(item: Item): Item {
  return { ...item, image_url: item.image_id ? buildPreviewUrl("item-images", item.image_id) : item.image_url || "" };
}
function loanImages(loan: Loan): Loan {
  return { ...loan, item: loan.item ? itemImages(loan.item) : undefined,
    return_image_url: loan.return_image_id ? buildPreviewUrl("return-images", loan.return_image_id) : loan.return_image_url };
}
export async function getCatalogItems(): Promise<Item[]> {
  await requireProfile();
  const rows = await database()`SELECT * FROM items ORDER BY created_at DESC`;
  return (rows as Item[]).map(itemImages);
}
export async function getItemById(itemId: string): Promise<Item | null> {
  await requireProfile();
  const rows = await database()`SELECT * FROM items WHERE id = ${itemId}::uuid`;
  return rows[0] ? itemImages(rows[0] as Item) : null;
}
async function loansFor(borrowerId: string | null): Promise<Loan[]> {
  const rows = await database()`
    SELECT l.*, row_to_json(i) AS item, row_to_json(b) AS borrower, row_to_json(a) AS admin
    FROM loans l JOIN items i ON i.id = l.item_id
    JOIN profiles b ON b.user_id = l.borrower_id
    LEFT JOIN profiles a ON a.user_id = l.admin_id
    WHERE (${borrowerId}::text IS NULL OR l.borrower_id = ${borrowerId})
    ORDER BY l.created_at DESC
  `;
  return (rows as Loan[]).map(loanImages);
}
export async function getMyLoans(userId: string): Promise<Loan[]> {
  const profile = await requireProfile();
  if (profile.user_id !== userId && profile.role !== "admin") throw new Error("Akses ditolak.");
  return loansFor(userId);
}
export async function getProfiles(): Promise<Profile[]> {
  await requireAdmin();
  return await database()`SELECT * FROM profiles ORDER BY created_at DESC` as Profile[];
}
export async function getAllLoans(): Promise<Loan[]> {
  await requireAdmin();
  return loansFor(null);
}
export async function getAdminDashboardData() {
  await requireAdmin();
  try {
    const last6Months = Array.from({ length: 6 }, (_, i) => {
      const d = new Date();
      d.setMonth(d.getMonth() - i);
      return {
        key: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`,
        month: d.getMonth(),
        year: d.getFullYear(),
        label: d.toLocaleString("id-ID", { month: "short" }),
        value: 0
      };
    }).reverse();

    const [statsRows, statusRows, recentRows, monthlyRows, returnMonthRows, borrowerRows, lateRows] = await Promise.all([
      database()`
        SELECT
          (SELECT count(*)::int FROM items) AS total_items,
          (SELECT count(*)::int FROM profiles) AS total_profiles,
          (SELECT count(*)::int FROM loans WHERE status IN ('approved','borrowed','overdue','returning','needs_review')) AS active_loans,
          (SELECT count(*)::int FROM loans WHERE status = 'pending') AS pending_loans
      `,
      database()`
        SELECT status, count(*)::int AS count
        FROM loans
        GROUP BY status
      `,
      database()`
        SELECT l.*, row_to_json(i) AS item, row_to_json(b) AS borrower, row_to_json(a) AS admin
        FROM loans l JOIN items i ON i.id = l.item_id
        JOIN profiles b ON b.user_id = l.borrower_id
        LEFT JOIN profiles a ON a.user_id = l.admin_id
        ORDER BY l.created_at DESC
        LIMIT 5
      `,
      database()`
        SELECT to_char(date_trunc('month', borrow_date), 'YYYY-MM') AS month_key, count(*)::int AS count
        FROM loans
        WHERE borrow_date >= date_trunc('month', now() - interval '5 months')
        GROUP BY date_trunc('month', borrow_date)
      `,
      database()`
        SELECT to_char(date_trunc('month', COALESCE(actual_return_date, return_date)), 'YYYY-MM') AS month_key, count(*)::int AS count
        FROM loans
        WHERE status = 'returned' AND COALESCE(actual_return_date, return_date) >= date_trunc('month', now() - interval '5 months')
        GROUP BY date_trunc('month', COALESCE(actual_return_date, return_date))
      `,
      database()`
        SELECT COALESCE(b.full_name, 'Unknown') AS label, count(*)::int AS value
        FROM loans l
        JOIN profiles b ON b.user_id = l.borrower_id
        GROUP BY b.full_name
        ORDER BY value DESC
        LIMIT 5
      `,
      database()`
        SELECT COALESCE(b.full_name, 'Unknown') AS label, count(*)::int AS value
        FROM loans l
        JOIN profiles b ON b.user_id = l.borrower_id
        WHERE l.status = 'overdue' OR (l.actual_return_date IS NOT NULL AND l.actual_return_date > l.return_date)
        GROUP BY b.full_name
        ORDER BY value DESC
        LIMIT 5
      `
    ]);

    // 1. Stats Cards
    const s = statsRows[0] || {};
    const stats = [
      { label: "Total Barang", value: Number(s.total_items ?? 0), helper: "Item dalam inventaris", icon: "Boxes" },
      { label: "Pinjaman Aktif", value: Number(s.active_loans ?? 0), helper: "Sedang dipinjam", icon: "ClipboardList" },
      { label: "Pengajuan Pending", value: Number(s.pending_loans ?? 0), helper: "Menunggu review", icon: "Clock" },
      { label: "Pengguna", value: Number(s.total_profiles ?? 0), helper: "Akun perusahaan", icon: "Users" }
    ];

    // 2. Status Distribution
    const statusCounts: Record<string, number> = {
      pending: 0,
      approved: 0,
      rejected: 0,
      returned: 0,
      overdue: 0
    };
    for (const row of statusRows) {
      if (row.status && statusCounts[row.status] !== undefined) {
        statusCounts[row.status] = Number(row.count);
      }
    }
    const statusDistribution = Object.entries(statusCounts).map(([label, value]) => ({
      label: label.charAt(0).toUpperCase() + label.slice(1),
      value
    }));

    // 3. Monthly Loans Trend (Last 6 Months)
    for (const row of monthlyRows) {
      const m = last6Months.find(lm => lm.key === row.month_key);
      if (m) m.value = Number(row.count);
    }
    const monthlyLoans = last6Months.map(({ label, value }) => ({ label, value }));

    // 4. Return Trend (Last 6 Months)
    const returnTrend = last6Months.map((m) => {
      const found = returnMonthRows.find(r => r.month_key === m.key);
      return {
        label: m.label,
        value: found ? Number(found.count) : 0
      };
    });

    // 5. Top Borrowers
    const topBorrowers = borrowerRows.map((b) => ({
      label: String(b.label || "Unknown"),
      value: Number(b.value || 0)
    }));

    // 6. Frequent Late Returns
    const frequentLateReturns = lateRows.map((b) => ({
      label: String(b.label || "Unknown"),
      value: Number(b.value || 0)
    }));

    // 7. Recent 5 Loans
    const recentLoans = (recentRows as Loan[]).map(loanImages);

    return {
      stats,
      recentLoans,
      monthlyLoans,
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
  })) as any[];
}

export async function getActiveLoans() {
  const profile = await requireProfile();
  const loans = await loansFor(profile.role === "admin" ? null : profile.user_id);
  return loans.filter(loan => ["approved", "borrowed", "overdue", "returning", "needs_review"].includes(loan.status));
}

export async function getBorrowerWorkspace() {
  const profile = await requireProfile();
  return { activity: teamActivity(await loansFor(null), profile.user_id), admin_contacts: adminContacts };
}
