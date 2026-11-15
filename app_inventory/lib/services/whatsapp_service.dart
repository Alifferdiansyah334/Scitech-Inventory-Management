import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  WhatsAppService._();

  static String _normalizePhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '').replaceAll(RegExp(r'^[+]*'), '').trim();
    return digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
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

  static String _buildBorrowRequestMessage({
    required String borrowerName,
    required String itemName,
    required int quantity,
    required String purpose,
    required DateTime borrowDate,
    required DateTime dueDate,
  }) {
    return '''[SIMS - PENGAJUAN PINJAM BARANG]

Halo Admin, saya $borrowerName ingin mengajukan peminjaman inventaris:

📦 Barang: $itemName ($quantity unit)
🎯 Keperluan: $purpose
📅 Tanggal Pinjam: ${_formatDate(borrowDate)}
📅 Estimasi Kembali: ${_formatDate(dueDate)}

Mohon kesediaannya untuk meninjau dan menyetujui pengajuan ini di aplikasi SIMS. Terima kasih.''';
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

  static Future<bool> sendBorrowRequestMessage({
    required String phoneNumber,
    required String borrowerName,
    required String itemName,
    required int quantity,
    required String purpose,
    required DateTime borrowDate,
    required DateTime dueDate,
  }) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final message = _buildBorrowRequestMessage(
      borrowerName: borrowerName,
      itemName: itemName,
      quantity: quantity,
      purpose: purpose,
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
    if (!RegExp(r'^\d{8,15}$').hasMatch(phoneNumber)) return false;
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$encoded');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return launched;
  }

  static Uri? contactUri(String phone, String message) {
    final normalized = _normalizePhoneNumber(phone);
    if (!RegExp(r'^\d{8,15}$').hasMatch(normalized)) return null;
    return Uri.https('wa.me', '/$normalized', {'text': message});
  }

  static Future<bool> contact(String phone, String message) async {
    final uri = contactUri(phone, message);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
