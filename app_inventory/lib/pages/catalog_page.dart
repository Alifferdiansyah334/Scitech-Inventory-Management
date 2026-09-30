import 'package:flutter/material.dart';

import '../data/admin_store.dart';
import '../data/profile_store.dart';
import 'borrow_page.dart';
import 'my_loans_page.dart';
import '../widgets/profile_menu_button.dart';

class CatalogItem {
  const CatalogItem({
    required this.name,
    required this.category,
    required this.description,
    required this.quantity,
    required this.icon,
  });

  final String name;
  final String category;
  final String description;
  final int quantity;
  final IconData icon;
}

const catalogItems = <CatalogItem>[
  CatalogItem(
    name: 'Rfid (putih)',
    category: 'Security',
    description: 'Kartu RFID warna putih frekuensi 13.56 MHz.',
    quantity: 5,
    icon: Icons.credit_card_outlined,
  ),
  CatalogItem(
    name: 'Rfid (biru)',
    category: 'Security',
    description: 'Gantungan kunci RFID warna biru.',
    quantity: 14,
    icon: Icons.vpn_key_outlined,
  ),
  CatalogItem(
    name: 'Rfid mesin',
    category: 'Security',
    description: 'Modul reader RFID RC522 untuk membaca tag atau kartu RFID.',
    quantity: 17,
    icon: Icons.sensors_outlined,
  ),
  CatalogItem(
    name: 'Keypad',
    category: 'Input',
    description:
        'Keypad matriks 4x4 membran untuk input data pin atau password.',
    quantity: 1,
    icon: Icons.dialpad_outlined,
  ),
  CatalogItem(
    name: 'Oled',
    category: 'Display',
    description: 'Layar OLED 0.96 inch dengan interface I2C.',
    quantity: 25,
    icon: Icons.desktop_windows_outlined,
  ),
  CatalogItem(
    name: 'LED Traffic light',
    category: 'Display/LED',
    description: 'Modul LED indikator lalu lintas merah, kuning, dan hijau.',
    quantity: 19,
    icon: Icons.traffic_outlined,
  ),
  CatalogItem(
    name: 'Motor driver',
    category: 'Driver',
    description: 'Modul L298N H-Bridge dual motor driver untuk motor DC.',
    quantity: 3,
    icon: Icons.settings_input_component_outlined,
  ),
  CatalogItem(
    name: 'touch sensor',
    category: 'Sensor',
    description: 'Sensor sentuh TTP223 capacitive touch sensor module.',
    quantity: 19,
    icon: Icons.touch_app_outlined,
  ),
  CatalogItem(
    name: 'Infrared',
    category: 'Sensor',
    description: 'Sensor inframerah untuk deteksi rintangan.',
    quantity: 25,
    icon: Icons.wifi_tethering_outlined,
  ),
  CatalogItem(
    name: 'Ultrasonik',
    category: 'Sensor',
    description: 'Sensor ultrasonik HC-SR04 untuk pengukuran jarak.',
    quantity: 33,
    icon: Icons.radar_outlined,
  ),
  CatalogItem(
    name: 'Dht 22',
    category: 'Sensor',
    description: 'Sensor suhu dan kelembaban udara dengan akurasi tinggi.',
    quantity: 2,
    icon: Icons.thermostat_outlined,
  ),
  CatalogItem(
    name: 'Dht 11',
    category: 'Sensor',
    description: 'Sensor suhu dan kelembaban udara standar.',
    quantity: 14,
    icon: Icons.device_thermostat_outlined,
  ),
];

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String selectedCategory = 'Semua';
  String searchQuery = '';

  List<String> get categories => [
    'Semua',
    ...catalogItems.map((item) => item.category).toSet(),
  ];

  List<CatalogItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    return catalogItems
        .where((item) {
          final categoryMatch =
              selectedCategory == 'Semua' || item.category == selectedCategory;
          final queryMatch =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query);
          return categoryMatch && queryMatch;
        })
        .map(
          (item) => CatalogItem(
            name: item.name,
            category: item.category,
            description: item.description,
            quantity: AdminStore.instance.availableFor(item.name),
            icon: item.icon,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdminStore.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white.withValues(alpha: 0.96),
              surfaceTintColor: Colors.white,
              titleSpacing: 20,
              title: Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 30, height: 30),
                  const SizedBox(width: 10),
                  const Text(
                    'SIMS',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              actions: [
                const ProfileMenuButton(),
                IconButton(
                  key: const ValueKey('catalog_my_loans_button'),
                  tooltip: 'My Loans',
                  icon: const Icon(Icons.work_outline_rounded),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyLoansPage()),
                  ),
                ),
                IconButton(
                  key: const ValueKey('catalog_logout_button'),
                  tooltip: 'Keluar',
                  color: const Color(0xFFEF4444),
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () {
                    ProfileStore.instance.clearSession();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 38, 20, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'SIMS Catalog.',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Peralatan berkualitas untuk mendukung produktivitas tim Anda. Cari, pilih, dan ajukan peminjaman dengan satu klik.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildControls(),
                  const SizedBox(height: 26),
                  _buildGrid(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari barang, kategori, atau deskripsi...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final category = categories[index];
              final active = category == selectedCategory;
              return ChoiceChip(
                label: Text(category),
                selected: active,
                onSelected: (_) => setState(() => selectedCategory = category),
                selectedColor: const Color(0xFF4F46E5),
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide(
                  color: active
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFE2E8F0),
                ),
                labelStyle: TextStyle(
                  color: active ? Colors.white : const Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                shape: const StadiumBorder(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    if (filteredItems.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Text(
          'Tidak ada barang yang ditemukan.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 1.05 : 0.72,
          ),
          itemBuilder: (context, index) =>
              _ItemCard(item: filteredItems[index]),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: item.quantity > 0 ? () => _showItemDetails(context) : null,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        item.icon,
                        size: 54,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        child: Icon(
                          item.icon,
                          color: const Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item.category.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        '${item.quantity} Stok',
                        style: TextStyle(
                          color: item.quantity > 0
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 42,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.quantity > 0
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.quantity > 0 ? 'PINJAM SEKARANG' : 'STOK HABIS',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEEF2FF),
                    child: Icon(item.icon, color: const Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _DetailStat(
                    label: 'TOTAL STOK',
                    value: '${item.quantity} Unit',
                  ),
                  const SizedBox(width: 12),
                  _DetailStat(label: 'KATEGORI', value: item.category),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'DESKRIPSI BARANG',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: item.quantity > 0
                      ? () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BorrowPage(item: item),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    item.quantity > 0
                        ? 'Ajukan Peminjaman Sekarang'
                        : 'Stok sedang habis',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
