import 'package:flutter/material.dart' show DateUtils;

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// 05/11/2026
String shortDate(DateTime value) =>
    '${_two(value.day)}/${_two(value.month)}/${value.year}';

/// 05/11/2026 17:00
String stamp(DateTime date) =>
    '${shortDate(date)} ${_two(date.hour)}:${_two(date.minute)}';

/// Rab, 5 Nov
String dayDate(DateTime value) =>
    '${_days[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]}';

/// 17.00
String clockTime(DateTime value) => '${_two(value.hour)}.${_two(value.minute)}';

/// Whole calendar days from today until [date]; negative when it has passed.
int daysUntil(DateTime date) => DateUtils.dateOnly(
  date,
).difference(DateUtils.dateOnly(DateTime.now())).inDays;
