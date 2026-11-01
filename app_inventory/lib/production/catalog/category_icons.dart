import 'package:flutter/material.dart';

const _rules = <(List<String>, IconData)>[
  (['kamera', 'camera', 'foto', 'lensa'], Icons.photo_camera_outlined),
  (['drone'], Icons.flight_outlined),
  (['audio', 'mic', 'suara', 'sound', 'speaker'], Icons.mic_none_rounded),
  (['proyektor', 'projector', 'presentasi'], Icons.slideshow_outlined),
  (['laptop', 'komputer', 'computer'], Icons.laptop_outlined),
  (['video', 'monitor', 'layar', 'tv'], Icons.tv_outlined),
  (['lampu', 'light', 'cahaya'], Icons.lightbulb_outline_rounded),
  (['tripod', 'stand'], Icons.camera_outdoor_outlined),
  (['kabel', 'cable', 'adaptor', 'charger'], Icons.cable_outlined),
  (['jaringan', 'network', 'router', 'wifi'], Icons.router_outlined),
  (['elektronik', 'electronic', 'gadget'], Icons.devices_other_outlined),
  (['alat', 'tool', 'perkakas'], Icons.handyman_outlined),
  (['furnitur', 'meja', 'kursi', 'furniture'], Icons.chair_outlined),
  (['buku', 'book', 'dokumen'], Icons.menu_book_outlined),
  (['kendaraan', 'mobil', 'motor', 'vehicle'], Icons.directions_car_outlined),
  (['olahraga', 'sport'], Icons.sports_soccer_outlined),
];

/// Icon for a category name by keyword, falling back to a generic box.
IconData categoryIcon(String category) {
  final name = category.toLowerCase();
  for (final (words, icon) in _rules) {
    if (words.any(name.contains)) return icon;
  }
  return Icons.inventory_2_outlined;
}
