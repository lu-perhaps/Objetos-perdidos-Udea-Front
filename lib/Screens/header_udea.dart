import 'package:flutter/material.dart';

class HeaderUdea extends StatelessWidget {
  final String titulo;

  const HeaderUdea({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0A8F4D).withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0A8F4D).withOpacity(0.4),
            ),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Color(0xFF0A8F4D),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UNIVERSIDAD DE ANTIOQUIA',
              style: TextStyle(
                color: Color(0xFF0A8F4D),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
