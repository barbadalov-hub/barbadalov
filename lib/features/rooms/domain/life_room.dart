import 'package:flutter/material.dart';

/// The four rooms of the app — one per Life Score pillar. The home screen shows
/// them as a 2×2 grid with the score itself sitting where they meet, because
/// the score is literally computed from these four.
enum RoomId { money, body, mind, goals }

class LifeRoom {
  final RoomId id;
  final String titleKey;
  final IconData icon;

  /// Ink-strength colour for the paper skin (dark enough to read on cream).
  final Color paper;

  /// Brightened colour for the night skin (light enough to read on black).
  final Color night;

  const LifeRoom({
    required this.id,
    required this.titleKey,
    required this.icon,
    required this.paper,
    required this.night,
  });

  /// The room's accent resolved against the active theme.
  Color colorFor(Brightness brightness) =>
      brightness == Brightness.dark ? night : paper;
}

/// Reading order: money, body (top row), mind, goals (bottom row).
const kLifeRooms = <LifeRoom>[
  LifeRoom(
    id: RoomId.money,
    titleKey: 'room.money',
    icon: Icons.account_balance_wallet_outlined,
    paper: Color(0xFF0F6E56),
    night: Color(0xFF5DCAA5),
  ),
  LifeRoom(
    id: RoomId.body,
    titleKey: 'room.body',
    icon: Icons.favorite_outline,
    paper: Color(0xFF993C1D),
    night: Color(0xFFF0997B),
  ),
  LifeRoom(
    id: RoomId.mind,
    titleKey: 'room.mind',
    icon: Icons.psychology_outlined,
    paper: Color(0xFF185FA5),
    night: Color(0xFF85B7EB),
  ),
  LifeRoom(
    id: RoomId.goals,
    titleKey: 'room.goals',
    icon: Icons.flag_outlined,
    paper: Color(0xFF854F0B),
    night: Color(0xFFEF9F27),
  ),
];

LifeRoom roomById(RoomId id) => kLifeRooms.firstWhere((r) => r.id == id);

/// What a room shows on the home grid: one hero figure and a line of context.
class RoomSummary {
  final RoomId id;

  /// The single number that matters now, already formatted ("$42", "3/5").
  final String hero;

  /// One short line under it ("осталось потратить").
  final String subtitleKey;

  /// Params for [subtitleKey] when it needs them.
  final Map<String, Object> params;

  const RoomSummary({
    required this.id,
    required this.hero,
    required this.subtitleKey,
    this.params = const {},
  });
}
