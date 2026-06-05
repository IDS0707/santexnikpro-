import 'package:flutter/material.dart';

/// Bazadan keladigan ikon kalitini Material ikoniga aylantiradi.
IconData iconFor(String? key) {
  switch (key) {
    case 'fan':
      return Icons.air;
    case 'faucet':
      return Icons.water_drop;
    case 'shower':
      return Icons.shower;
    case 'gripLines':
      return Icons.plumbing;
    case 'syringe':
      return Icons.colorize;
    case 'fillDrip':
      return Icons.format_color_fill;
    case 'filter':
      return Icons.filter_alt;
    case 'toolbox':
      return Icons.handyman;
    case 'screwdriverWrench':
      return Icons.build;
    // PPR fitinglar
    case 'pipe':
      return Icons.plumbing;
    case 'mufta':
      return Icons.adjust;
    case 'adaptor':
      return Icons.settings_input_component;
    case 'troynik':
      return Icons.call_split;
    case 'burchak':
      return Icons.turn_right;
    case 'otish':
      return Icons.swap_horiz;
    case 'valve':
      return Icons.water_damage;
    case 'amerikanka':
      return Icons.join_full;
    case 'klipsa':
      return Icons.push_pin;
    case 'probka':
      return Icons.do_not_disturb_on;
    case 'radiator':
      return Icons.thermostat;
    default:
      return Icons.inventory_2_outlined;
  }
}
