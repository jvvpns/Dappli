import 'package:flutter/material.dart';

InputDecoration buildInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white10,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.amber),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
