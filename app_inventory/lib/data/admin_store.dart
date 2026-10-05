import 'package:flutter/material.dart';

class InventoryItem {
  InventoryItem({
    required this.name,
    required this.category,
    required this.totalStock,
    required this.condition,
    required this.icon,
  });

  String name;
  String category;
  int totalStock;
  String condition;
  IconData icon;
  int borrowedStock = 0;

  int get availableStock => (totalStock - borrowedStock).clamp(0, totalStock);
  String get status => availableStock == 0 ? 'Habis' : 'Tersedia';
}

class AdminLoan {
  AdminLoan({
    String? id,
    required this.borrower,
    required this.borrowerPhone,
    required this.itemName,
    required this.quantity,
    required this.borrowDate,
    required this.returnDate,
    required this.status,
    this.onStatusChanged,
    this.adminBeforePhotoPath,
    this.borrowerReturnPhotoPath,
    this.returnNote,
    this.adminIssueNote,
    this.returnDateConfirmed,
  }) : id = id ?? 'loan_${DateTime.now().microsecondsSinceEpoch}';

  final String id;
  final String borrower;
  final String borrowerPhone;
  final String itemName;
  final int quantity;
  final DateTime borrowDate;
  final DateTime returnDate;
  final void Function(String status)? onStatusChanged;
  String status;
  String? adminBeforePhotoPath;
  String? borrowerReturnPhotoPath;
  String? returnNote;
  String? adminIssueNote;
  DateTime? returnDateConfirmed;
}

class ProcurementRecord {
  ProcurementRecord({
    required this.itemName,
    required this.quantity,
    required this.date,
    required this.supplier,
    required this.status,
  });

  String itemName;
  int quantity;
  DateTime date;
  String supplier;
  String status;
  bool receivedApplied = false;
}

class AdminHistoryRecord {
  AdminHistoryRecord({
    required this.title,
    required this.detail,
    required this.type,
    required this.date,
  });

  final String title;
  final String detail;
  final String type;
  final DateTime date;
}

class AdminStore extends ChangeNotifier {
  AdminStore._() {
    final now = DateTime.now();
    inventory.addAll([
      InventoryItem(
        name: 'Arduino Uno',
        category: 'Mikrokontroler',
        totalStock: 17,
        condition: 'Baik',
        icon: Icons.memory_outlined,
      ),
      InventoryItem(
        name: 'LED',
        category: 'Elektronik',
        totalStock: 40,
        condition: 'Baik',
        icon: Icons.lightbulb_outline,
      ),
      InventoryItem(
        name: 'Kabel Jumper',
        category: 'Kabel',
        totalStock: 25,
        condition: 'Baik',
        icon: Icons.cable_outlined,
      ),
      InventoryItem(
        name: 'Sensor Ultrasonik',
        category: 'Sensor',
        totalStock: 8,
        condition: 'Baik',
        icon: Icons.sensors_outlined,
      ),
      InventoryItem(
        name: 'ESP32',
        category: 'Mikrokontroler',
        totalStock: 6,
        condition: 'Baik',
        icon: Icons.developer_board_outlined,
      ),
      InventoryItem(
        name: 'Rfid (putih)',
        category: 'Security',
        totalStock: 5,
        condition: 'Baik',
        icon: Icons.credit_card_outlined,
      ),
      InventoryItem(
        name: 'Rfid (biru)',
        category: 'Security',
        totalStock: 14,
        condition: 'Baik',
        icon: Icons.vpn_key_outlined,
      ),
      InventoryItem(
        name: 'Rfid mesin',
        category: 'Security',
        totalStock: 17,
        condition: 'Baik',
        icon: Icons.sensors_outlined,
      ),
      InventoryItem(
        name: 'Keypad',
        category: 'Input',
        totalStock: 1,
        condition: 'Baik',
        icon: Icons.dialpad_outlined,
      ),
      InventoryItem(
        name: 'Oled',
        category: 'Display',
        totalStock: 25,
        condition: 'Baik',
        icon: Icons.desktop_windows_outlined,
      ),
      InventoryItem(
        name: 'LED Traffic light',
        category: 'Display/LED',
        totalStock: 19,
        condition: 'Baik',
        icon: Icons.traffic_outlined,
      ),
      InventoryItem(
        name: 'Motor driver',
        category: 'Driver',
        totalStock: 3,
        condition: 'Baik',
        icon: Icons.settings_input_component_outlined,
      ),
      InventoryItem(
        name: 'touch sensor',
        category: 'Sensor',
        totalStock: 19,
        condition: 'Baik',
        icon: Icons.touch_app_outlined,
      ),
      InventoryItem(
        name: 'Infrared',
        category: 'Sensor',
        totalStock: 25,
        condition: 'Baik',
        icon: Icons.wifi_tethering_outlined,
      ),
      InventoryItem(
        name: 'Ultrasonik',
        category: 'Sensor',
        totalStock: 33,
        condition: 'Baik',
        icon: Icons.radar_outlined,
      ),
      InventoryItem(
        name: 'Dht 22',
        category: 'Sensor',
        totalStock: 2,
        condition: 'Baik',
        icon: Icons.thermostat_outlined,
      ),
      InventoryItem(
        name: 'Dht 11',
        category: 'Sensor',
        totalStock: 14,
        condition: 'Baik',
        icon: Icons.device_thermostat_outlined,
      ),
    ]);

    loans.addAll([
      AdminLoan(
        borrower: 'Nadia Putri',
        borrowerPhone: '+628123456789',
        itemName: 'Arduino Uno',
        quantity: 2,
        borrowDate: now.subtract(const Duration(days: 1)),
        returnDate: now.add(const Duration(days: 6)),
        status: 'Menunggu',
      ),
      AdminLoan(
        borrower: 'Rafi Pratama',
        borrowerPhone: '+628112233445',
        itemName: 'ESP32',
        quantity: 1,
        borrowDate: now.subtract(const Duration(days: 2)),
        returnDate: now.add(const Duration(days: 5)),
        status: 'Menunggu',
      ),
      AdminLoan(
        borrower: 'Dimas Saputra',
        borrowerPhone: '+628556677889',
        itemName: 'Sensor Ultrasonik',
        quantity: 2,
        borrowDate: now.subtract(const Duration(days: 5)),
        returnDate: now.add(const Duration(days: 2)),
        status: 'Sedang Dipinjam',
      ),
      AdminLoan(
        borrower: 'Alya Rahma',
        borrowerPhone: '+628998877665',
        itemName: 'Kabel Jumper',
        quantity: 3,
        borrowDate: now.subtract(const Duration(days: 8)),
        returnDate: now.subtract(const Duration(days: 1)),
        status: 'Selesai',
      ),
      AdminLoan(
        borrower: 'Bima Akbar',
        borrowerPhone: '+628777666555',
        itemName: 'LED',
        quantity: 5,
        borrowDate: now.subtract(const Duration(days: 3)),
        returnDate: now.add(const Duration(days: 4)),
        status: 'Disetujui',
      ),
    ]);
    for (final loan in loans) {
      if (loan.status == 'Disetujui' || loan.status == 'Sedang Dipinjam') {
        final item = inventoryItem(loan.itemName);
        if (item != null) item.borrowedStock += loan.quantity;
      }
    }

    procurements.addAll([
      ProcurementRecord(
        itemName: 'ESP32',
        quantity: 10,
        date: now.subtract(const Duration(days: 2)),
        supplier: 'Tekno Sumber',
        status: 'Diajukan',
      ),
      ProcurementRecord(
        itemName: 'LED',
        quantity: 50,
        date: now.subtract(const Duration(days: 6)),
        supplier: 'Komponen Kita',
        status: 'Diproses',
      ),
      ProcurementRecord(
        itemName: 'Arduino Uno',
        quantity: 5,
        date: now.subtract(const Duration(days: 12)),
        supplier: 'Elektronik Jaya',
        status: 'Diterima',
      )..receivedApplied = true,
    ]);
    history.addAll([
      AdminHistoryRecord(
        title: 'Peminjaman diajukan',
        detail: 'Nadia Putri • Arduino Uno',
        type: 'Peminjaman',
        date: now.subtract(const Duration(hours: 3)),
      ),
      AdminHistoryRecord(
        title: 'Persetujuan diberikan',
        detail: 'Bima Akbar • LED',
        type: 'Persetujuan',
        date: now.subtract(const Duration(days: 1)),
      ),
      AdminHistoryRecord(
        title: 'Barang dikembalikan',
        detail: 'Alya Rahma • Kabel Jumper',
        type: 'Pengembalian',
        date: now.subtract(const Duration(days: 2)),
      ),
      AdminHistoryRecord(
        title: 'Pengadaan diterima',
        detail: 'Arduino Uno • 5 unit',
        type: 'Pengadaan',
        date: now.subtract(const Duration(days: 3)),
      ),
    ]);
  }

  static final instance = AdminStore._();

  final List<InventoryItem> inventory = [];
  final List<AdminLoan> loans = [];
  final List<ProcurementRecord> procurements = [];
  final List<AdminHistoryRecord> history = [];
  String adminName = 'Admin Scitech';
  String adminEmail = 'admin@scitech.id';
  String adminPassword = 'admin123';
  String adminPhone = '+628123456789';

  int get totalStock => inventory.fold(0, (sum, item) => sum + item.totalStock);
  int get availableStock =>
      inventory.fold(0, (sum, item) => sum + item.availableStock);
  int get borrowedStock =>
      inventory.fold(0, (sum, item) => sum + item.borrowedStock);
  int get pendingLoans => loans
      .where(
        (loan) => loan.status == 'Menunggu' || loan.status == 'Diajukan',
      )
      .length;

  AdminLoan? findLoanById(String loanId) {
    for (final loan in loans) {
      if (loan.id == loanId) return loan;
    }
    return null;
  }

  void updateAdminProfile({required String name, required String email}) {
    adminName = name;
    adminEmail = email;
    notifyListeners();
  }

  InventoryItem? inventoryItem(String name) {
    for (final item in inventory) {
      if (item.name.toLowerCase() == name.toLowerCase()) return item;
    }
    if (name == 'Sensor Ultrasonik') {
      for (final item in inventory) {
        if (item.name == 'Ultrasonik') return item;
      }
    }
    return null;
  }

  int availableFor(String name) => inventoryItem(name)?.availableStock ?? 0;

  bool approveLoan(AdminLoan loan) {
    final item = inventoryItem(loan.itemName);
    if ((loan.status != 'Menunggu' && loan.status != 'Diajukan') ||
        item == null ||
        item.availableStock < loan.quantity) {
      return false;
    }
    item.borrowedStock += loan.quantity;
    loan.status = 'Disetujui';
    loan.onStatusChanged?.call('Disetujui');
    _record(
      'Peminjaman disetujui',
      '${loan.borrower} • ${loan.itemName}',
      'Persetujuan',
    );
    notifyListeners();
    return true;
  }

  void rejectLoan(AdminLoan loan) {
    if (loan.status != 'Menunggu' && loan.status != 'Diajukan') return;
    loan.status = 'Ditolak';
    loan.onStatusChanged?.call('Ditolak');
    _record(
      'Peminjaman ditolak',
      '${loan.borrower} • ${loan.itemName}',
      'Persetujuan',
    );
    notifyListeners();
  }

  bool submitReturnProof({
    required String loanId,
    required String photoPath,
    required String note,
  }) {
    final loan = findLoanById(loanId);
    if (loan == null) return false;
    loan.borrowerReturnPhotoPath = photoPath;
    loan.returnNote = note.trim();
    loan.status = 'Menunggu Konfirmasi Admin';
    loan.returnDateConfirmed = DateTime.now();
    notifyListeners();
    return true;
  }

  bool confirmReturn({required String loanId, required String? issueNote}) {
    final loan = findLoanById(loanId);
    if (loan == null) return false;
    final item = inventoryItem(loan.itemName);
    if (item != null) {
      item.borrowedStock = (item.borrowedStock - loan.quantity).clamp(0, item.totalStock);
    }
    loan.status = 'Dikembalikan';
    loan.returnDateConfirmed = DateTime.now();
    if (issueNote != null && issueNote.trim().isNotEmpty) {
      loan.adminIssueNote = issueNote.trim();
    }
    notifyListeners();
    return true;
  }

  bool markIssue({required String loanId, required String issueNote}) {
    final loan = findLoanById(loanId);
    if (loan == null) return false;
    loan.status = 'Perlu Tindak Lanjut';
    loan.adminIssueNote = issueNote.trim();
    notifyListeners();
    return true;
  }

  void addBorrowRequest({
    required String id,
    required String borrower,
    required String borrowerPhone,
    required String itemName,
    required int quantity,
    required DateTime borrowDate,
    required DateTime returnDate,
    void Function(String status)? onStatusChanged,
  }) {
    loans.insert(
      0,
      AdminLoan(
        id: id,
        borrower: borrower,
        borrowerPhone: borrowerPhone,
        itemName: itemName,
        quantity: quantity,
        borrowDate: borrowDate,
        returnDate: returnDate,
        status: 'Menunggu',
        onStatusChanged: onStatusChanged,
      ),
    );
    _record('Peminjaman diajukan', '$borrower • $itemName', 'Peminjaman');
    notifyListeners();
  }

  bool saveInventory(InventoryItem item, {InventoryItem? previous}) {
    if (item.totalStock < (previous?.borrowedStock ?? item.borrowedStock)) {
      return false;
    }
    if (previous == null) {
      inventory.add(item);
    } else if (previous != item) {
      final index = inventory.indexOf(previous);
      if (index < 0) return false;
      inventory[index] = item..borrowedStock = previous.borrowedStock;
    }
    notifyListeners();
    return true;
  }

  bool deleteInventory(InventoryItem item) {
    if (item.borrowedStock > 0) return false;
    inventory.remove(item);
    notifyListeners();
    return true;
  }

  void addProcurement(ProcurementRecord record) {
    procurements.insert(0, record);
    if (record.status == 'Diterima') _applyProcurement(record);
    _record(
      'Pengadaan ditambahkan',
      '${record.itemName} • ${record.quantity} unit',
      'Pengadaan',
    );
    notifyListeners();
  }

  bool saveProcurement(
    ProcurementRecord record, {
    ProcurementRecord? previous,
  }) {
    if (previous == null) {
      addProcurement(record);
      return true;
    }
    final index = procurements.indexOf(previous);
    if (index < 0) return false;
    if (previous.receivedApplied) {
      final oldItem = inventoryItem(previous.itemName);
      if (oldItem != null &&
          oldItem.totalStock - previous.quantity < oldItem.borrowedStock) {
        return false;
      }
      if (oldItem != null) oldItem.totalStock -= previous.quantity;
      record.receivedApplied = false;
    }
    procurements[index] = record;
    if (record.status == 'Diterima') _applyProcurement(record);
    _record(
      'Pengadaan diperbarui',
      '${record.itemName} • ${record.quantity} unit',
      'Pengadaan',
    );
    notifyListeners();
    return true;
  }

  void deleteProcurement(ProcurementRecord record) {
    procurements.remove(record);
    notifyListeners();
  }

  void updateProcurementStatus(ProcurementRecord record, String status) {
    record.status = status;
    if (status == 'Diterima' && !record.receivedApplied) {
      _applyProcurement(record);
    }
    notifyListeners();
  }

  void _applyProcurement(ProcurementRecord record) {
    final item = inventoryItem(record.itemName);
    if (item != null) {
      item.totalStock += record.quantity;
    } else {
      inventory.add(
        InventoryItem(
          name: record.itemName,
          category: 'Lainnya',
          totalStock: record.quantity,
          condition: 'Baik',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }
    record.receivedApplied = true;
    _record(
      'Pengadaan diterima',
      '${record.itemName} • ${record.quantity} unit',
      'Pengadaan',
    );
  }

  void _record(String title, String detail, String type) {
    history.insert(
      0,
      AdminHistoryRecord(
        title: title,
        detail: detail,
        type: type,
        date: DateTime.now(),
      ),
    );
  }
}
