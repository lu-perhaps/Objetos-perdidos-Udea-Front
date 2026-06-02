import 'package:flutter/material.dart';

class HeaderUdea extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final bool oscuro;

  const HeaderUdea({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.oscuro = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = oscuro ? Colors.white : const Color(0xFF111827);
    final subtitleColor = oscuro ? Colors.white70 : const Color(0xFF6B7280);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0A8F4D),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A8F4D).withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'UNIVERSIDAD DE ANTIOQUIA',
                style: TextStyle(
                  color: Color(0xFF0A8F4D),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitulo!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class HeaderUdeaAdmin extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final bool oscuro;

  const HeaderUdeaAdmin({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.oscuro = false,
  });

  @override
  Widget build(BuildContext context) {
    return HeaderUdea(
      titulo: titulo,
      subtitulo: subtitulo,
      oscuro: oscuro,
    );
  }
}