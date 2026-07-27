import 'package:flutter/material.dart';

import 'ui/vn_screen.dart';

/// Root of the "Пропущенный вызов" prototype.
///
/// The game is a first-person anime visual novel: an insomniac wakes at 03:14
/// to a call and pieces together, through his phone, what happened to his
/// brother. This build ships the Act I prologue as a playable vertical slice.
class MissedCallApp extends StatelessWidget {
  const MissedCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Пропущенный вызов',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF06070B),
      ),
      home: const VnScreen(),
    );
  }
}
