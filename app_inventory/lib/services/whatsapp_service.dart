import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  WhatsAppService._();

  static String _normalizePhoneNumber(String phoneNumber) {
    final digits = phoneNumber
        .replaceAll(RegExp(r'[^0-9+]'), '')
        .replaceAll(RegExp(r'^[+]*'), '')
        .trim();
    return digits.isEmpty ? '628123456789' : digits;
  }

  static String _buildBorrowApprovalMessage({
    required String borrowerName,
    required String itemName,
    required DateTime borrowDate,
    required DateTime dueDate,
  }) {
    return '''[SIMS - PEMINJAMAN BARANG]

Halo, $borrowerName.

Peminjaman barang kamu telah disetujui.

📦 Barang: $itemName
📅 Tanggal Pinjam: ${_formatDate(borrowDate)}
📅 Batas Pengembalian: ${_formatDate(dueDate)}

📸 Foto kondisi barang sebelum diserahkan telah didokumentasikan.

Mohon menjaga kondisi barang dan mengembalikannya sesuai jadwal.

Terima kasih.
SIMS Scitech''';
  }

  static String _buildReturnProofMessage({
    required String borrowerName,
    required String itemName,
    required DateTime borrowDate,
    required DateTime dueDate,
    required String note,
  }) {
    return '''[SIMS - PENGEMBALIAN BARANG]

Halo Admin,

Saya $borrowerName ingin mengembalikan barang berikut:

📦 Barang: $itemName
📅 Tanggal Pinjam: ${_formatDate(borrowDate)}
📅 Tanggal Pengembalian: ${_formatDate(dueDate)}

📸 Saya melampirkan foto kondisi barang setelah digunakan.

Keterangan:
$note

Mohon dilakukan pemeriksaan dan konfirmasi pengembalian.

Terima kasih.''';
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static Future<bool> sendBorrowApprovalMessage({
    required String phoneNumber,
    required String borrowerName,
    required String itemName,
    required DateTime borrowDate,
    required DateTime dueDate,
  }) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final message = _buildBorrowApprovalMessage(
      borrowerName: borrowerName,
      itemName: itemName,
      borrowDate: borrowDate,
      dueDate: dueDate,
    );
    return _openWhatsApp(normalizedPhone, message);
  }

  static Future<bool> sendReturnProofMessage({
    required String phoneNumber,
    required String borrowerName,
    required String itemName,
    required DateTime borrowDate,
    required DateTime dueDate,
    required String note,
  }) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final message = _buildReturnProofMessage(
      borrowerName: borrowerName,
      itemName: itemName,
      borrowDate: borrowDate,
      dueDate: dueDate,
      note: note,
    );
    return _openWhatsApp(normalizedPhone, message);
  }

  static Future<bool> _openWhatsApp(String phoneNumber, String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$encoded');
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return launched;
  }
}
