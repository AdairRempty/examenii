import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  final String message;
  final int fontSize;
  final String color;

  const MessageWidget({
    super.key,
    required this.message,
    required this.fontSize,
    required this.color,
  });

  // Funcion para obtener el color si la base lo guarda en formato hex
  // solo hay que quitar el # al inicio
  Color colorHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: fontSize.toDouble(),
        color: colorHex(color),
      ),
    );
  }
}
