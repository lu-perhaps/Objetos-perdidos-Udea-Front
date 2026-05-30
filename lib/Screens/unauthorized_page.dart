import 'package:flutter/material.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Solo se permite acceso con correo institucional @udea.edu.co',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}