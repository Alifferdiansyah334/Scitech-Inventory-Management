part of '../forms.dart';

/// Shapes of successive editor cards (AgroLens article editor order), so
/// every field keeps one shape.
const _fieldShapes = [
  ExpressiveShape.cookie9,
  ExpressiveShape.sunny8,
  ExpressiveShape.flower8,
  ExpressiveShape.clover4,
  ExpressiveShape.gem,
  ExpressiveShape.cookie12,
];

class _PromptSheet extends StatefulWidget {
  const _PromptSheet({required this.title, required this.fields, required this.submit, required this.icon});
  final String title, submit;
  final List<InputSpec> fields;
  final IconData icon;

  @override
  State<_PromptSheet> createState() => _PromptSheetState();
}

class _PromptSheetState extends State<_PromptSheet> {
  final _form = GlobalKey<FormState>();
  late final _controllers = {for (final f in widget.fields) f.key: TextEditingController(text: f.initial)};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    Navigator.pop(context, {
      for (final f in widget.fields) f.key: f.secret ? _controllers[f.key]!.text : _controllers[f.key]!.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.fields;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EditorHeading(icon: widget.icon, shape: ExpressiveShape.cookie9, title: widget.title),
                      const SizedBox(height: 20),
                      for (final (i, f) in fields.indexed) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _PromptField(
                          spec: f,
                          controller: _controllers[f.key]!,
                          shape: _fieldShapes[i % _fieldShapes.length],
                          last: i == fields.length - 1,
                          onSubmit: _submit,
                        ),
                        if (f.validatePassword)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: PasswordStrength(controller: _controllers[f.key]!),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _EditorActions(submit: widget.submit, onSubmit: _submit, onCancel: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One [InputSpec] as an editor card; secrets get a show/hide toggle.
class _PromptField extends StatefulWidget {
  const _PromptField({
    required this.spec,
    required this.controller,
    required this.shape,
    required this.last,
    required this.onSubmit,
  });
  final InputSpec spec;
  final TextEditingController controller;
  final ExpressiveShape shape;
  final bool last;
  final VoidCallback onSubmit;

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  bool hidden = true;

  String? _validate(String? value) {
    final f = widget.spec;
    if (f.validatePassword) return PasswordPolicy(value ?? '').error;
    if (f.optional && (value?.trim().isEmpty ?? true)) return null;
    if ((value?.trim().length ?? 0) < f.min) {
      return 'Isi minimal ${f.min} karakter.';
    }
    if (f.numeric && int.tryParse(value!) == null) {
      return 'Masukkan bilangan bulat.';
    }
    if (f.decimal && double.tryParse(value!) == null) {
      return 'Masukkan angka yang valid.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.spec;
    final long = f.long;
    final plain = f.secret || f.numeric || f.decimal;
    return ExpressiveTextField(
      controller: widget.controller,
      label: f.optional ? '${f.label} (opsional)' : f.label,
      icon: f.badge,
      shape: widget.shape,
      obscureText: f.secret && hidden,
      minLines: long ? 3 : 1,
      maxLines: long ? 6 : 1,
      maxLength: f.max,
      capitalization: plain ? TextCapitalization.none : TextCapitalization.sentences,
      keyboardType: f.numeric
          ? TextInputType.number
          : f.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : long
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: long
          ? TextInputAction.newline
          : widget.last
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: widget.last && !long ? (_) => widget.onSubmit() : null,
      validator: _validate,
      trailing: f.secret
          ? IconButton(
              tooltip: hidden ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
              onPressed: () => setState(() => hidden = !hidden),
              icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            )
          : null,
    );
  }
}
