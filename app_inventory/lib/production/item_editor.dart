import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_state.dart';
import '../models.dart';
import '../ui/button_feedback.dart';
import '../ui/components.dart';
import '../ui/controls.dart';
import '../ui/physics.dart';
import '../ui/shapes.dart';
import '../ui/springs.dart';
import '../ui/theme.dart';
import '../ui/tokens.dart';

part 'item_editor_fields.dart';
part 'item_editor_inputs.dart';
part 'item_editor_toggle.dart';

/// Opens the item editor as a full page; resolves to true after a save.
Future<bool?> openItemEditor(BuildContext context, AppState state, [InventoryItem? item]) =>
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ItemEditor(state: state, item: item),
      ),
    );

/// Add or change an inventory item, after AgroLens' article editor: app bar
/// title, a 16:9 cover photo, the name, category chips (or a new category),
/// the description, the total in a stepper group and the 'Bisa dipinjam'
/// toggle card; one wide 'Simpan barang' button at the bottom.
class ItemEditor extends StatefulWidget {
  const ItemEditor({required this.state, this.item, super.key});
  final AppState state;
  final InventoryItem? item;
  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  final form = GlobalKey<FormState>();
  final _saveKey = GlobalKey();
  late final name = TextEditingController(text: widget.item?.name),
      description = TextEditingController(text: widget.item?.description);
  late final category = TextEditingController(text: widget.item?.category),
      total = TextEditingController(text: '${widget.item?.total ?? 1}');
  late bool enabled = widget.item?.enabled ?? true;
  bool saving = false;
  XFile? photo;
  Future<Uint8List>? photoBytes;
  String? error;

  int get reserved => widget.item?.reserved ?? 0;

  @override
  void dispose() {
    for (final c in [name, description, category, total]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    if (!form.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final count = int.parse(total.text.trim());
      var imageId = widget.item?.imageId;
      if (photo != null) {
        imageId = await widget.state.api.upload(photo!, bucket: 'item-images');
      }
      await widget.state.mutate(
        widget.item == null ? 'api/items' : 'api/items/${widget.item!.id}',
        method: widget.item == null ? 'POST' : 'PATCH',
        data: {
          'name': name.text.trim(),
          'description': description.text.trim(),
          'category': category.text.trim(),
          'quantity_total': count,
          'quantity_available': count - reserved,
          'is_available': enabled,
          'image_id': imageId ?? '',
        },
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        final origin = _saveKey.currentContext;
        if (origin != null && origin.mounted) {
          final scheme = context.colors;
          ShapeBurst.show(
            context,
            origin: ShapeBurst.centerOf(origin),
            count: 22,
            colors: [scheme.primary, scheme.tertiary, scheme.secondary, context.palette.hero],
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 75);
    if (mounted && picked != null) {
      setState(() {
        photo = picked;
        photoBytes = picked.readAsBytes();
      });
    }
  }

  String? _required(String? value) => (value?.trim().isEmpty ?? true) ? 'Kolom ini wajib diisi.' : null;

  String? _total(String? value) {
    final count = int.tryParse(value?.trim() ?? '');
    if (value?.trim().isEmpty ?? true) return 'Kolom ini wajib diisi.';
    if (count == null || count < 0) return 'Masukkan stok 0 atau lebih.';
    if (count < reserved) return 'Minimal $reserved unit masih digunakan.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    final scheme = context.colors;
    final categories = {
      for (final item in widget.state.items)
        if (item.category.trim().isNotEmpty) item.category.trim(),
    }.toList()..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
    Widget limit(Widget child) => Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child),
    );
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: Text(editing ? 'Ubah barang' : 'Barang baru')),
        body: Form(
          key: form,
          child: limit(
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _CoverPicker(
                  photo: photoBytes,
                  current: widget.item?.imageUrl ?? '',
                  state: widget.state,
                  onTap: saving ? null : pickPhoto,
                ),
                const SizedBox(height: 20),
                ExpressiveTextField(
                  controller: name,
                  label: 'Nama barang',
                  icon: Icons.inventory_2_outlined,
                  shape: ExpressiveShape.cookie9,
                  enabled: !saving,
                  maxLength: 160,
                  capitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                _CategoryCard(controller: category, options: categories, enabled: !saving, validator: _required),
                const SizedBox(height: 12),
                ExpressiveTextField(
                  controller: description,
                  label: 'Deskripsi',
                  icon: Icons.notes_rounded,
                  shape: ExpressiveShape.sunny8,
                  hint: 'Kelengkapan, kondisi, atau cara pakai (opsional)',
                  enabled: !saving,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 2000,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 12),
                GroupCard(
                  title: 'Jumlah total',
                  icon: Icons.numbers_rounded,
                  shape: ExpressiveShape.flower8,
                  value: reserved > 0 ? '$reserved unit sedang dipinjam atau dipesan' : null,
                  child: _CountStepper(controller: total, min: reserved, enabled: !saving, validator: _total),
                ),
                const SizedBox(height: 12),
                _LendableToggle(value: enabled, onChanged: saving ? null : (value) => setState(() => enabled = value)),
                if (error != null) ...[const SizedBox(height: 16), _ErrorNote(error!)],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: limit(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                key: _saveKey,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: saving ? null : save,
                icon: saving
                    ? SizedBox.square(
                        dimension: 28,
                        child: ExpressiveLoadingIndicator(size: 28, color: scheme.onSurfaceVariant),
                      )
                    : ShapeIcon(
                        icon: Icons.check_rounded,
                        shape: ExpressiveShape.cookie9,
                        size: 28,
                        fill: scheme.onPrimary,
                        foreground: scheme.primary,
                        iconScale: .6,
                      ),
                label: Text(saving ? 'Menyimpan...' : 'Simpan barang'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
