import 'package:flutter/material.dart';
import '../core/brand.dart';

/// The SIMS symbol, announced once as the app name. Used by the splash and
/// anywhere the full-colour mark sits on a light plate.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 96, super.key});
  final double size;

  static const asset = 'assets/brand/sims-symbol.png';

  @override
  Widget build(BuildContext context) => Semantics(
    label: appName,
    image: true,
    child: Image.asset(asset, width: size, height: size, fit: BoxFit.contain, excludeFromSemantics: true),
  );
}
