import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Constants/api_config.dart';

class NotificacionRepository {
  static Future<List<Map<String, dynamic>>> obtenerNotificaciones({
    required String correo,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notificaciones/$correo'),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerNotificaciones API: $e');
      return [];
    }
  }

  static Future<bool> marcarComoLeida({
    required int idNotificacion,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notificaciones/$idNotificacion/leer',
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR marcarComoLeida API: $e');
      return false;
    }
  }

  static Future<int> contarNoLeidas({
    required String correo,
  }) async {
    final notificaciones = await obtenerNotificaciones(correo: correo);

    return notificaciones.where((n) => n['leida'] == false).length;
  }
}