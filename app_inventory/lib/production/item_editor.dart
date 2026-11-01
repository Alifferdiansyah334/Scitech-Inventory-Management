import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_state.dart';
import '../models.dart';
import '../ui/tokens.dart';

class ItemEditor extends StatefulWidget {
  const ItemEditor({required this.state, this.item, super.key});
  final AppState state;
  final InventoryItem? item;
  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.item?.name),
      description = TextEditingController(text: widget.item?.description);
  late final category = TextEditingController(text: widget.item?.category),
      total = TextEditingController(text: '${widget.item?.total ?? 1}');
  late bool enabled = widget.item?.enabled ?? true;
  bool saving = false;
  XFile? photo;
  String? error;
  @override
  void dispose() {
    for (final c in [name, description, category, total]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final count = int.parse(total.text);
      final reserved = widget.item?.reserved ?? 0;
      if (count < reserved) {
        throw FormatException('Minimal $reserved unit masih digunakan.');
      }
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
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = e is FormatException ? e.message : e.toString());
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: !saving,
      maxLength: controller == description ? 2000 : 160,
      minLines: controller == description ? 2 : 1,
      maxLines: controller == description ? 4 : 1,
      keyboardType: controller == total
          ? TextInputType.number
          : controller == description
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) {
        if (controller != description && (value?.trim().isEmpty ?? true)) {
          return 'Kolom ini wajib diisi.';
        }
        if (controller == total &&
            (int.tryParse(value!) == null || int.parse(value) < 0)) {
          return 'Masukkan stok 0 atau lebih.';
        }
        return null;
      },
    ),
  );

  Future<void> pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (mounted && picked != null) setState(() => photo = picked);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Tambah barang' : 'Ubah barang'),
    contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
    actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.badSoft,
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: AppColors.bad,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              field(name, 'Nama barang'),
              field(category, 'Kategori'),
              field(description, 'Deskripsi'),
              field(total, 'Stok total'),
              Material(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadii.control),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                  title: const Text(
                    'Dapat dipinjam',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  value: enabled,
                  onChanged: saving
                      ? null
                      : (value) => setState(() => enabled = value),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: saving ? null : pickPhoto,
                icon: Icon(
                  photo == null
                      ? Icons.add_photo_alternate_outlined
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(
                  photo == null
                      ? 'Pilih foto barang (maks. 2 MB)'
                      : photo!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      OutlinedButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: Text(saving ? 'Menyimpan...' : 'Simpan'),
      ),
    ],
  );
}
