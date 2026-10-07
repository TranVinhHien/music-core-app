import 'package:flutter/material.dart';

/// The neutral Material 3 theme used by the reference app.
ThemeData appTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  useMaterial3: true,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);
