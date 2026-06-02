import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/api_config.dart';
import '../main.dart';

class SolicitudRepository {
  static Future<List<Map<String, dynamic>>> obtenerSolicitudesDeUsuario({
    required String correo,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/solicitudes/usuario/${Uri.encodeComponent(correo.toLowerCase().trim())}',
        ),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR obtenerSolicitudesDeUsuario: status=${response.statusCode} body=${response.body}',
        );
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerSolicitudesDeUsuario: $e');
      return [];
    }
  }

  static Future<bool> entregarSolicitud(int idSolicitud) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null || user.email == null) {
        debugPrint('ERROR entregarSolicitud: usuario no autenticado');
        return false;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/solicitudes/$idSolicitud/entregar',
      );

      final body = jsonEncode({
        'correoAdmin': user.email!.toLowerCase().trim(),
        'observaciones': 'Entrega registrada desde el sistema',
      });

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) return true;

      debugPrint(
        'ERROR entregarSolicitud: status=${response.statusCode} body=${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('ERROR entregarSolicitud: $e');
      return false;
    }
  }

  static Future<bool> anularSolicitud(int idSolicitud) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/solicitudes/$idSolicitud/anular',
        ),
      );

      if (response.statusCode == 200) return true;

      debugPrint(
        'ERROR anularSolicitud: status=${response.statusCode} body=${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('ERROR anularSolicitud: $e');
      return false;
    }
  }

  static Future<bool> cancelarAprobacion(int idSolicitud) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/solicitudes/$idSolicitud/cancelar-aprobacion',
        ),
      );

      if (response.statusCode == 200) return true;

      debugPrint(
        'ERROR cancelarAprobacion: status=${response.statusCode} body=${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('ERROR cancelarAprobacion: $e');
      return false;
    }
  }
}