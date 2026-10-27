import 'package:flutter/foundation.dart';
import '../models.dart';
import 'api.dart';
import 'vault.dart';

class AppState extends ChangeNotifier {
  AppState({required this.api, required this.vault});
  final ApiClient api;
  final TokenVault vault;
  Profile? profile;
  List<InventoryItem> items = [];
  List<Loan> loans = [];
  List<Procurement> procurements = [];
  List<Profile> users = [];
  List<TeamLoan> activity = [];
  List<AdminContact> adminContacts = [];
  bool restoring = true, loading = false, busy = false;
  String? error;
  DateTime? updatedAt;
  int _generation = 0;
  bool get isAdmin => profile?.isAdmin ?? false;
  Future<void> restore() async {
    try {
      api.token = await vault.read();
      if (api.token != null) {
        profile = Profile.fromJson(
          (await api.request('api/mobile/auth/session'))['profile'] as Json,
        );
        await refresh();
      }
    } on ApiException catch (e) {
      error = e.message;
      if (e.status == 401 || e.status == 403) {
        await vault.clear();
        api.token = null;
      }
    } catch (_) {
      error = 'Sesi belum dapat dipulihkan. Periksa koneksi lalu coba lagi.';
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> authenticate(
    Json data, {
    bool register = false,
    bool remember = true,
  }) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result =
          await api.request(
                'api/mobile/auth/${register ? 'register' : 'login'}',
                method: 'POST',
                data: data,
                authenticated: false,
              )
              as Json;
      if (result['verification_required'] == true) {
        throw const ApiException(
          'Periksa email dan masukkan kode verifikasi untuk melanjutkan.',
        );
      }
      final token = result['token'] as String;
      if (remember) {
        await vault.write(token);
      } else {
        await vault.clear();
      }
      api.token = token;
      profile = Profile.fromJson(result['profile'] as Json);
      await refresh();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> registerAccount(Json data) async {
    error = null;
    notifyListeners();
    await api.request(
      'api/mobile/auth/register',
      method: 'POST',
      data: data,
      authenticated: false,
    );
  }

  Future<void> sendCode(String email, String purpose) async {
    error = null;
    notifyListeners();
    await api.request(
      'api/mobile/auth/send-otp',
      method: 'POST',
      data: {'email': email, 'purpose': purpose},
      authenticated: false,
    );
  }

  Future<void> authenticateOtp(
    String email,
    String code,
    String purpose, {
    bool remember = true,
  }) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result =
          await api.request(
                'api/mobile/auth/login-otp',
                method: 'POST',
                data: {'email': email, 'otp': code, 'purpose': purpose},
                authenticated: false,
              )
              as Json;
      final token = result['token'] as String;
      if (remember) {
        await vault.write(token);
      } else {
        await vault.clear();
      }
      api.token = token;
      profile = Profile.fromJson(result['profile'] as Json);
      await refresh();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (profile == null || loading) return;
    final version = _generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final session = await api.request('api/mobile/auth/session') as Json;
      if (version != _generation) return;
      profile = Profile.fromJson(session['profile'] as Json);
      final data = await Future.wait([
        api.request('api/items'),
        api.request(isAdmin ? 'api/admin/loans' : 'api/loans/me'),
        if (isAdmin) api.request('api/admin/procurements'),
        if (isAdmin) api.request('api/admin/users'),
        if (!isAdmin) api.request('api/mobile/workspace'),
      ]);
      if (version != _generation) return;
      items = (data[0] as List)
          .map((j) => InventoryItem.fromJson(j as Json))
          .toList();
      loans = (data[1] as List).map((j) => Loan.fromJson(j as Json)).toList();
      if (isAdmin) {
        procurements = (data[2] as List)
            .map((j) => Procurement.fromJson(j as Json))
            .toList();
        users = (data[3] as List)
            .map((j) => Profile.fromJson(j as Json))
            .toList();
      } else {
        procurements = [];
        users = [];
        final workspace = data[2] as Json;
        activity = (workspace['activity'] as List)
            .map((j) => TeamLoan.fromJson(j as Json))
            .toList();
        adminContacts = (workspace['admin_contacts'] as List? ?? [])
            .map((j) => AdminContact.fromJson(j as Json))
            .toList();
      }
      updatedAt = DateTime.now();
    } on ApiException catch (e) {
      if (version != _generation) return;
      error = e.message;
      if (e.status == 401 || e.status == 403) await signOut(remote: false);
    } catch (_) {
      if (version == _generation) {
        error = 'Data belum dapat dimuat. Tarik layar untuk mencoba lagi.';
      }
    } finally {
      if (version == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<dynamic> mutate(
    String path, {
    String method = 'POST',
    Json? data,
  }) async {
    if (busy) throw const ApiException('Tunggu proses sebelumnya selesai.');
    busy = true;
    notifyListeners();
    try {
      final result = await api.request(path, method: method, data: data);
      await refresh();
      return result;
    } on ApiException catch (e) {
      if (e.status == 401) await signOut(remote: false);
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Json data) async {
    final result = await mutate('api/mobile/auth/profile', data: data) as Json;
    profile = Profile.fromJson(result['data'] as Json);
    notifyListeners();
  }

  Future<void> signOut({bool remote = true}) async {
    _generation++;
    loading = false;
    final token = api.token;
    await vault.clear();
    try {
      if (remote && token != null) {
        await api.request('api/mobile/auth/logout', method: 'POST', data: {});
      }
    } finally {
      api.token = null;
      profile = null;
      items = [];
      loans = [];
      procurements = [];
      users = [];
      activity = [];
      adminContacts = [];
      updatedAt = null;
      notifyListeners();
    }
  }
}
