class PasswordPolicy {
  const PasswordPolicy(this.value);
  final String value;
  bool get longEnough => value.length >= 8;
  bool get uppercase => RegExp(r'[A-Z]').hasMatch(value);
  bool get lowercase => RegExp(r'[a-z]').hasMatch(value);
  bool get number => RegExp(r'[0-9]').hasMatch(value);
  bool get symbol => RegExp(r'[^A-Za-z0-9\s]').hasMatch(value);
  bool get valid => longEnough && uppercase && lowercase && number && symbol && value.length <= 128;
  int get score => [longEnough, uppercase, lowercase, number, symbol].where((v) => v).length;
  String get strength => !valid
      ? 'Lemah'
      : value.length < 12
      ? 'Sedang'
      : 'Kuat';
  String? get error => valid ? null : 'Gunakan 8–128 karakter dengan huruf besar, huruf kecil, angka, dan simbol.';
}
