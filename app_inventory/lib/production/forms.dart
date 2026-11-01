import 'package:flutter/material.dart';
import '../core/password_policy.dart';
import '../ui/tokens.dart';
import 'password_strength.dart';

class InputSpec {
  const InputSpec(
    this.key,
    this.label, {
    this.initial = '',
    this.optional = false,
    this.secret = false,
    this.numeric = false,
    this.decimal = false,
    this.min = 1,
    this.max = 2000,
    this.validatePassword = false,
  });
  final String key, label, initial;
  final bool optional, secret, numeric, decimal;
  final bool validatePassword;
  final int min, max;
}

const _dialogPadding = EdgeInsets.fromLTRB(24, 16, 24, 8);
const _actionsPadding = EdgeInsets.fromLTRB(24, 8, 24, 24);

Future<Map<String, String>?> promptForm(
  BuildContext context,
  String title,
  List<InputSpec> fields, {
  String submit = 'Simpan',
}) async {
  final form = GlobalKey<FormState>();
  final controllers = {
    for (final f in fields) f.key: TextEditingController(text: f.initial),
  };
  try {
    final route = DialogRoute<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        contentPadding: _dialogPadding,
        actionsPadding: _actionsPadding,
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in fields)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: controllers[f.key],
                            obscureText: f.secret,
                            keyboardType: f.numeric || f.decimal
                                ? const TextInputType.numberWithOptions(
                                    decimal: true,
                                  )
                                : TextInputType.text,
                            maxLength: f.max,
                            decoration: InputDecoration(
                              labelText: f.label,
                              counterText: '',
                            ),
                            validator: (value) {
                              if (f.validatePassword) {
                                return PasswordPolicy(value ?? '').error;
                              }
                              if (f.optional &&
                                  (value?.trim().isEmpty ?? true)) {
                                return null;
                              }
                              if ((value?.trim().length ?? 0) < f.min) {
                                return 'Isi minimal ${f.min} karakter.';
                              }
                              if (f.numeric && int.tryParse(value!) == null) {
                                return 'Masukkan bilangan bulat.';
                              }
                              if (f.decimal &&
                                  double.tryParse(value!) == null) {
                                return 'Masukkan angka yang valid.';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (f.validatePassword)
                          PasswordStrength(controller: controllers[f.key]!),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, {
                  for (final e in controllers.entries)
                    e.key: fields.firstWhere((f) => f.key == e.key).secret
                        ? e.value.text
                        : e.value.text.trim(),
                });
              }
            },
            child: Text(submit),
          ),
        ],
      ),
    );
    final result = await Navigator.of(context).push(route);
    await route.completed;
    return result;
  } finally {
    for (final c in controllers.values) {
      c.dispose();
    }
  }
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        contentPadding: _dialogPadding,
        actionsPadding: _actionsPadding,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Text(
            message,
            style: const TextStyle(fontSize: 15, color: AppColors.muted),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    ) ??
    false;
