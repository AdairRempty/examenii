import 'package:flutter/material.dart';

class NameWidget extends StatelessWidget {
  final String name;

  const NameWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: 
      const TextStyle(
        fontSize: 24, 
        fontWeight: 
        FontWeight.bold,
        color: Color.fromARGB(255, 7, 41, 114),
        ),
    );
  }
}