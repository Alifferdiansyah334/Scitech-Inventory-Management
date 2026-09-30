class UserProfile {
  UserProfile({
    required this.name,
    required this.email,
    this.role = 'client',
    this.department = '',
    this.avatarUrl = '',
    this.avatarPath,
  });

  String name;
  String email;
  String role;
  String department;
  String avatarUrl;
  String? avatarPath;

  String get roleLabel => role == 'admin' ? 'Admin' : 'User';

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class ProfileStore {
  ProfileStore._();

  static final instance = ProfileStore._();
  UserProfile profile = UserProfile(name: 'User', email: '');

  void startSession(String email) {
    final localName = email.split('@').first.trim();
    profile = UserProfile(
      name: localName.isEmpty ? 'User' : localName,
      email: email,
    );
  }

  void clearSession() {
    profile = UserProfile(name: 'User', email: '');
  }
}
