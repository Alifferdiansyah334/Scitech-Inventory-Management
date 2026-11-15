typedef Json = Map<String, dynamic>;

class AdminContact {
  const AdminContact({required this.id, required this.name, required this.phone});
  final String id, name, phone;
  factory AdminContact.fromJson(Json j) {
    final phone = j['phone'] as String;
    if (!RegExp(r'^\d{8,15}$').hasMatch(phone)) throw const FormatException('Kontak admin tidak valid.');
    return AdminContact(id: j['id'] as String, name: j['name'] as String, phone: phone);
  }
}

class TeamLoan {
  const TeamLoan({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.borrowerName,
    required this.department,
    required this.quantity,
    required this.status,
    required this.dueDate,
    required this.isMine,
  });
  final String id, itemId, itemName, borrowerName, department, status;
  final int quantity;
  final DateTime dueDate;
  final bool isMine;
  factory TeamLoan.fromJson(Json j) => TeamLoan(
    id: j['id'] as String,
    itemId: j['item_id'] as String,
    itemName: j['item_name'] as String,
    borrowerName: j['borrower_name'] as String,
    department: j['department'] as String? ?? '',
    quantity: j['quantity'] as int,
    status: j['status'] as String,
    dueDate: DateTime.parse(j['return_date'] as String).toLocal(),
    isMine: j['is_mine'] as bool,
  );
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department = '',
    this.phone = '',
    this.active = true,
  });
  final String id, name, email, role, department, phone;
  final bool active;
  bool get isAdmin => role == 'admin';
  String get initials =>
      name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
  factory Profile.fromJson(Json j) => Profile(
    id: j['user_id'] as String,
    name: j['full_name'] as String,
    email: j['email'] as String,
    role: j['role'] as String,
    department: j['department'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    active: j['is_active'] as bool? ?? true,
  );
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.total,
    required this.available,
    required this.enabled,
    this.description = '',
    this.imageUrl = '',
    this.imageId,
  });
  final String id, name, category, description, imageUrl;
  final String? imageId;
  final int total, available;
  final bool enabled;
  bool get canBorrow => enabled && available > 0;
  int get reserved => total - available;
  factory InventoryItem.fromJson(Json j) => InventoryItem(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String,
    total: j['quantity_total'] as int,
    available: j['quantity_available'] as int,
    enabled: j['is_available'] as bool,
    description: j['description'] as String? ?? '',
    imageUrl: j['image_url'] as String? ?? '',
    imageId: j['image_id'] as String?,
  );
}

class Loan {
  const Loan({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.status,
    required this.purpose,
    required this.borrowDate,
    required this.dueDate,
    this.borrower = '',
    this.phone = '',
    this.adminNote = '',
    this.userNote = '',
    this.issueNote = '',
    this.beforeId,
    this.afterId,
  });
  final String id, itemId, name, status, purpose, borrower, phone, adminNote, userNote, issueNote;
  final String? beforeId, afterId;
  final int quantity;
  final DateTime borrowDate, dueDate;
  bool get closed => const ['returned', 'rejected', 'cancelled'].contains(status);
  bool get late => !closed && const ['borrowed', 'overdue'].contains(status) && dueDate.isBefore(DateTime.now());
  bool get canReturn => const ['borrowed', 'overdue', 'needs_review'].contains(status);
  String get label => late ? 'Terlambat' : statusLabels[status] ?? 'Status tidak dikenal';
  factory Loan.fromJson(Json j) => Loan(
    id: j['id'] as String,
    itemId: j['item_id'] as String,
    name: (j['item'] as Json?)?['name'] as String? ?? 'Barang tidak tersedia',
    quantity: j['quantity'] as int,
    status: j['status'] as String,
    purpose: j['purpose'] as String,
    borrowDate: DateTime.parse(j['borrow_date'] as String).toLocal(),
    dueDate: DateTime.parse(j['return_date'] as String).toLocal(),
    borrower: (j['borrower'] as Json?)?['full_name'] as String? ?? '',
    phone: (j['borrower'] as Json?)?['phone'] as String? ?? '',
    adminNote: j['admin_note'] as String? ?? '',
    userNote: j['user_note'] as String? ?? '',
    issueNote: j['issue_note'] as String? ?? '',
    beforeId: j['admin_image_id'] as String?,
    afterId: j['return_image_id'] as String?,
  );
}

const statusLabels = {
  'pending': 'Menunggu persetujuan',
  'approved': 'Siap diambil',
  'borrowed': 'Sedang dipinjam',
  'returning': 'Menunggu pemeriksaan',
  'returned': 'Selesai',
  'rejected': 'Ditolak',
  'overdue': 'Terlambat',
  'cancelled': 'Dibatalkan',
  'needs_review': 'Perlu tindak lanjut',
};

class Procurement {
  const Procurement({
    required this.id,
    required this.name,
    required this.supplier,
    required this.status,
    required this.quantity,
    required this.cost,
  });
  final String id, name, supplier, status;
  final int quantity;
  final double cost;
  factory Procurement.fromJson(Json j) => Procurement(
    id: j['id'] as String,
    name: j['item_name'] as String,
    supplier: j['supplier'] as String,
    status: j['status'] as String,
    quantity: j['quantity'] as int,
    cost: double.parse(j['unit_cost'].toString()),
  );
}
