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
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notificaciones/${Uri.encodeComponent(correo.toLowerCase().trim())}',
        ),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR obtenerNotificaciones: status=${response.statusCode} body=${response.body}',
        );
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerNotificaciones: $e');
      return [];
    }
  }

  static Future<int> contarNoLeidas({
    required String correo,
  }) async {
    final notificaciones = await obtenerNotificaciones(correo: correo);

    return notificaciones.where((n) {
      final leida = n['leida'];

      if (leida is bool) return leida == false;

      return leida.toString().toLowerCase() == 'false';
    }).length;
  }

  static Future<bool> marcarComoLeida({
    required int idNotificacion,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notificaciones/$idNotificacion/leida',
        ),
      );

      if (response.statusCode == 200) return true;

      debugPrint(
        'ERROR marcarComoLeida: status=${response.statusCode} body=${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('ERROR marcarComoLeida: $e');
      return false;
    }
  }

  static Future<bool> eliminarNotificacion(int idNotificacion) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notificaciones/$idNotificacion',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      debugPrint(
        'ERROR eliminarNotificacion: status=${response.statusCode} body=${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('ERROR eliminarNotificacion: $e');
      return false;
    }
  }

  static Future<bool> eliminarTodas(String correo) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notificaciones/usuario/${Uri.encodeComponent(correo.toLowerCase().trim())}',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      debugPrint(
        'ERROR eliminarTodas: status=${response.statusCode} body=${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('ERROR eliminarTodas: $e');
      return false;
    }
  }
}