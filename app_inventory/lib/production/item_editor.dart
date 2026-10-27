import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_state.dart';
import '../models.dart';

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

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Tambah barang' : 'Ubah barang'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              for (final pair in [
                (name, 'Nama barang'),
                (category, 'Kategori'),
                (description, 'Deskripsi'),
                (total, 'Stok total'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: pair.$1,
                    enabled: !saving,
                    maxLength: pair.$1 == description ? 2000 : 160,
                    keyboardType: pair.$1 == total
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: pair.$2,
                      counterText: '',
                    ),
                    validator: (value) {
                      if (pair.$1 != description &&
                          (value?.trim().isEmpty ?? true)) {
                        return 'Kolom ini wajib diisi.';
                      }
                      if (pair.$1 == total &&
                          (int.tryParse(value!) == null ||
                              int.parse(value) < 0)) {
                        return 'Masukkan stok 0 atau lebih.';
                      }
                      return null;
                    },
                  ),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dapat dipinjam'),
                value: enabled,
                onChanged: saving
                    ? null
                    : (value) => setState(() => enabled = value),
              ),
              OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1600,
                          imageQuality: 75,
                        );
                        if (mounted && picked != null) {
                          setState(() => photo = picked);
                        }
                      },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  photo == null
                      ? 'Pilih foto barang (maks. 2 MB)'
                      : photo!.name,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
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
