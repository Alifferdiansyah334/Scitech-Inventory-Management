import '../pages/catalog_page.dart';

class LoanRecord {
  LoanRecord({
    String? id,
    required this.item,
    required this.itemName,
    required this.borrowerName,
    required this.borrowerPhone,
    required this.quantity,
    required this.purpose,
    required this.borrowDate,
    required this.dueDate,
    this.status = 'Diajukan',
    this.returnDate,
    this.adminBeforePhotoPath,
    this.borrowerReturnPhotoPath,
    this.returnNote,
    this.adminIssueNote,
    this.returnConfirmed = false,
  }) : id = id ?? 'loan_${DateTime.now().microsecondsSinceEpoch}';

  final String id;
  final CatalogItem item;
  final String itemName;
  final String borrowerName;
  final String borrowerPhone;
  final int quantity;
  final String purpose;
  final DateTime borrowDate;
  final DateTime dueDate;
  DateTime? returnDate;
  String status;
  String? adminBeforePhotoPath;
  String? borrowerReturnPhotoPath;
  String? returnNote;
  String? adminIssueNote;
  bool returnConfirmed;

  bool get isBorrowingActive => const {
    'Diajukan',
    'Disetujui',
    'Sedang Dipinjam',
    'Menunggu Pengembalian',
    'Menunggu Konfirmasi Admin',
  }.contains(status);

  bool get isAwaitingConfirmation => status == 'Menunggu Konfirmasi Admin';
}

class LoanStore {
  LoanStore._();

  static final instance = LoanStore._();
  final List<LoanRecord> records = [];

  String generateId() => 'loan_${DateTime.now().microsecondsSinceEpoch}';

  void add(LoanRecord record) {
    records.insert(0, record);
  }

  LoanRecord? findById(String loanId) {
    for (final loan in records) {
      if (loan.id == loanId) return loan;
    }
    return null;
  }

  bool submitReturnProof({
    required String loanId,
    required String photoPath,
    required String note,
  }) {
    final loan = findById(loanId);
    if (loan == null) return false;
    loan.borrowerReturnPhotoPath = photoPath;
    loan.returnNote = note.trim();
    loan.returnDate = DateTime.now();
    loan.status = 'Menunggu Konfirmasi Admin';
    loan.returnConfirmed = false;
    return true;
  }

  bool confirmReturn({required String loanId}) {
    final loan = findById(loanId);
    if (loan == null) return false;
    loan.status = 'Dikembalikan';
    loan.returnConfirmed = true;
    loan.returnDate ??= DateTime.now();
    return true;
  }

  bool flagIssue({required String loanId, required String issueNote}) {
    final loan = findById(loanId);
    if (loan == null) return false;
    loan.status = 'Perlu Tindak Lanjut';
    loan.adminIssueNote = issueNote.trim();
    return true;
  }

  bool updateStatus({
    required String loanId,
    required String status,
    String? beforePhotoPath,
  }) {
    final loan = findById(loanId);
    if (loan == null) return false;
    loan.status = status;
    if (beforePhotoPath != null) {
      loan.adminBeforePhotoPath = beforePhotoPath;
    }
    if (status == 'Disetujui' || status == 'Sedang Dipinjam') {
      loan.status = 'Sedang Dipinjam';
    }
    return true;
  }
}
