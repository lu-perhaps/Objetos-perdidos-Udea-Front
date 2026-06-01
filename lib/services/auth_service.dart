import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/api_config.dart';
import '../main.dart';

class AuthService {
  static Future<Map<String, dynamic>?> obtenerUsuarioActualBackend() async {
    try {
      final session = supabase.auth.currentSession;

      if (session == null || session.accessToken.isEmpty) {
        debugPrint('ERROR auth/me: no hay sesión activa');
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR auth/me: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (e) {
      debugPrint('ERROR auth/me: $e');
      return null;
    }
  }

  static Future<int?> obtenerRol() async {
    final data = await obtenerUsuarioActualBackend();
    if (data == null) return null;

    return int.tryParse(data['idRol'].toString());
  }

  static Future<int?> obtenerIdPersona() async {
    final data = await obtenerUsuarioActualBackend();
    if (data == null) return null;

    return int.tryParse(data['id'].toString());
  }

  static Future<bool> esAdmin() async {
    final rol = await obtenerRol();
    return rol == 2;
  }

  static Future<void> cerrarSesion() async {
    await supabase.auth.signOut();
  }
}