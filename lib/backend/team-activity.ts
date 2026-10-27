import type { Loan } from '@/types';

// Activity is visible to signed-in borrowers. Private loan details stay in the owner's API.
export function teamActivity(loans: Loan[], userId: string) {
  return loans.filter(loan => ['approved','borrowed','overdue','returning','needs_review'].includes(loan.status)).map(loan => ({
    id: loan.id, item_id: loan.item_id, item_name: loan.item?.name ?? 'Barang tidak tersedia',
    category: loan.item?.category ?? '', borrower_name: loan.borrower?.full_name ?? 'Anggota tim',
    department: loan.borrower?.department ?? '', is_mine: loan.borrower_id === userId,
    quantity: loan.quantity, status: loan.status, borrow_date: loan.borrow_date, return_date: loan.return_date,
  }));
}
