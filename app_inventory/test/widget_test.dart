// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_inventory/data/admin_store.dart';
import 'package:app_inventory/data/loan_store.dart';
import 'package:app_inventory/pages/admin_dashboard_page.dart';
import 'package:app_inventory/pages/catalog_page.dart';

void main() {
  testWidgets('Admin dashboard renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminDashboardPage()),
    );

    expect(find.text('Admin Dashboard.'), findsOneWidget);
    expect(find.text('Peminjaman Terbaru'), findsOneWidget);
  });

  test('Return proof submission moves the loan to waiting admin confirmation', () {
    LoanStore.instance.records.clear();
    AdminStore.instance.loans.clear();

    final loan = LoanRecord(
      id: 'loan-1',
      item: const CatalogItem(
        name: 'Arduino Uno',
        category: 'Mikrokontroler',
        description: 'Board',
        quantity: 1,
        icon: Icons.memory_outlined,
      ),
      quantity: 1,
      borrowerName: 'Sinta',
      borrowerPhone: '+628123456789',
      itemName: 'Arduino Uno',
      purpose: 'Prototyping',
      borrowDate: DateTime.now().subtract(const Duration(days: 4)),
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: 'Sedang Dipinjam',
    );
    final adminLoan = AdminLoan(
      id: loan.id,
      borrower: 'Sinta',
      borrowerPhone: '+628123456789',
      itemName: 'Arduino Uno',
      quantity: 1,
      borrowDate: loan.borrowDate,
      returnDate: loan.dueDate,
      status: 'Sedang Dipinjam',
    );

    LoanStore.instance.records.add(loan);
    AdminStore.instance.loans.add(adminLoan);

    final updated = LoanStore.instance.submitReturnProof(
      loanId: loan.id,
      photoPath: '/tmp/return.jpg',
      note: 'Barang dikembalikan dalam kondisi baik',
    );
    final adminUpdated = AdminStore.instance.submitReturnProof(
      loanId: loan.id,
      photoPath: '/tmp/return.jpg',
      note: 'Barang dikembalikan dalam kondisi baik',
    );

    expect(updated, isTrue);
    expect(adminUpdated, isTrue);
    expect(loan.status, 'Menunggu Konfirmasi Admin');
    expect(loan.returnNote, 'Barang dikembalikan dalam kondisi baik');
    expect(adminLoan.status, 'Menunggu Konfirmasi Admin');
  });
}
