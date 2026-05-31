import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Constants/api_config.dart';
import '../main.dart';

class SolicitudRepository {
  static Future<List<Map<String, dynamic>>> obtenerSolicitudesDePersona({
    required int idPersona,
  }) async {
    try {
      final data = await supabase
          .from('tbl_solicitud_reclamo')
          .select('''
            id,
            descripcion,
            fecha,
            fecha_aprox_perdida,
            id_estado,
            id_reporte,
            tbl_objeto (
              id,
              nombre,
              fotografia,
              descripcion_general,
              id_lugar_actual,
              lugar_actual:tbl_lugar!fk_objeto_lugar_actual (
                id,
                nombre
              )
            ),
            tbl_lugar (
              nombre
            )
          ''')
          .eq('id_persona', idPersona)
          .order('fecha', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerSolicitudesDePersona: $e');
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

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/solicitudes/$idSolicitud/entregar');
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

      debugPrint('ERROR entregarSolicitud: status=${response.statusCode} body=${response.body}');
      return false;
    } catch (e) {
      debugPrint('ERROR entregarSolicitud: $e');
      return false;
    }
  }
}