import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Constants/api_config.dart';

class CoincidenciaService {
  static Future<bool> procesarCoincidencia({
    required Map<String, dynamic> reporte,
    required int idObjeto,
    required String mensajePersonalizado,
    required int idPersonaAdmin,
  }) async {
    try {
      final idReporte = reporte['id'] as int;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/coincidencias'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'idReporte': idReporte,
          'idObjeto': idObjeto,
          'mensajePersonalizado': mensajePersonalizado.trim(),
          'idPersonaAdmin': idPersonaAdmin,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ERROR procesarCoincidencia API: $e');
      return false;
    }
  }
}