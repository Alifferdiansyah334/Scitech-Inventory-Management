import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import 'image_compressor.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  String? token;
  bool get configured {
    final uri = Uri.tryParse(baseUrl);
    if (kReleaseMode && uri != null && uri.scheme != 'https' && !const ['localhost', '127.0.0.1'].contains(uri.host)) {
      return false;
    }
    return uri != null && uri.host.isNotEmpty && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  Uri uri(String path) {
    if (!configured) {
      throw const ApiException('Layanan belum dikonfigurasi. Hubungi pengelola aplikasi.');
    }
    final relative = Uri.parse(path);
    if (relative.hasScheme || relative.hasAuthority || relative.hasFragment || relative.pathSegments.contains('..')) {
      throw const ApiException('Alamat layanan tidak diizinkan.');
    }
    return Uri.parse(
      '${baseUrl.replaceFirst(RegExp(r"/+$"), "")}/${relative.path.replaceFirst(RegExp(r"^/+"), "").replaceFirst(RegExp(r"/+$"), "")}/',
    ).replace(query: relative.hasQuery ? relative.query : null);
  }

  Map<String, String> get authHeaders => token == null ? {} : {'Authorization': 'Bearer $token'};
  Future<dynamic> request(String path, {String method = 'GET', Json? data, bool authenticated = true}) async {
    final request = http.Request(method, uri(path));
    request.headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authenticated) ...authHeaders,
    });
    if (data != null) request.body = jsonEncode(data);
    try {
      final response = await _client.send(request).then(http.Response.fromStream).timeout(const Duration(seconds: 25));
      return _decode(response);
    } on TimeoutException {
      throw const ApiException('Koneksi terlalu lama. Periksa status transaksi sebelum mencoba kembali.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat menjangkau server aplikasi. Coba kembali beberapa saat lagi. Jika berlanjut, hubungi pengelola.',
      );
    }
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      throw ApiException('Layanan mengirim respons yang tidak dapat dibaca.', response.statusCode);
    }
    if (response.statusCode >= 400 || (data is Map && data['success'] == false)) {
      final message = data is Map ? (data['error'] ?? data['message']) : null;
      throw ApiException(
        response.statusCode >= 500
            ? 'Layanan sedang bermasalah. Coba kembali beberapa saat lagi.'
            : message?.toString() ?? 'Permintaan tidak dapat diproses.',
        response.statusCode,
      );
    }
    return data;
  }

  Future<String> upload(XFile file, {required String bucket}) async {
    final rawBytes = await file.readAsBytes();
    final bytes = await ImageCompressor.compressBytes(rawBytes);
    if (bytes.length > 2 * 1024 * 1024) {
      throw const ApiException('Ukuran foto maksimal 2 MB. Pilih foto yang lebih kecil.');
    }
    final request = http.MultipartRequest('POST', uri('api/images'));
    request.headers.addAll(authHeaders);
    request.fields['bucket'] = bucket;
    final name = file.name.toLowerCase();
    final type = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: file.name, contentType: http.MediaType.parse(type)),
    );
    try {
      final response = await _client.send(request).then(http.Response.fromStream).timeout(const Duration(seconds: 45));
      return (_decode(response) as Json)['fileId'] as String;
    } on TimeoutException {
      throw const ApiException('Unggah foto terlalu lama. Silakan ulangi.');
    } on http.ClientException {
      throw const ApiException('Foto belum terkirim. Periksa koneksi internet.');
    }
  }

  String imageUrl(String value) {
    final target = Uri.parse(value);
    if (target.hasScheme) {
      final origin = Uri.parse(baseUrl);
      return target.origin == origin.origin ? value : '';
    }
    return Uri.parse(baseUrl).resolve(value).toString();
  }

  void close() => _client.close();
}
