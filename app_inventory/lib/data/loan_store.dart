import '../pages/catalog_page.dart';

class LoanRecord {
  LoanRecord({
    required this.item,
    required this.quantity,
    required this.purpose,
    required this.borrowDate,
    required this.returnDate,
  });

  final CatalogItem item;
  final int quantity;
  final String purpose;
  final DateTime borrowDate;
  final DateTime returnDate;
  String status = 'pending';
}

class LoanStore {
  LoanStore._();

  static final instance = LoanStore._();
  final List<LoanRecord> records = [];

  void add(LoanRecord record) {
    records.insert(0, record);
  }
}
