import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'physics.dart';
import 'shapes.dart';
import 'springs.dart';
import 'theme.dart';

part 'controls/button_group.dart';
part 'controls/button_group_badge.dart';
part 'controls/filter_chip.dart';
part 'controls/navigation.dart';
part 'controls/search_bar.dart';
part 'controls/text_field.dart';
part 'controls/text_field_state.dart';
part 'controls/typing_glyphs.dart';

/// Material 3 Expressive controls: connected button groups that widen and
/// round on a spring, a docked navigation bar whose active pill stretches and
/// morphs each destination's shape, filter chips with morphing shape badges,
/// a search bar and tactile text fields that pop shaped letters as you type.

const _shapeCycle = [
  ExpressiveShape.cookie9,
  ExpressiveShape.sunny8,
  ExpressiveShape.flower8,
  ExpressiveShape.clover4,
  ExpressiveShape.gem,
  ExpressiveShape.softBurst,
  ExpressiveShape.cookie12,
];
