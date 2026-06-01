import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Constants/api_config.dart';

class ReporteRepository {
  static Future<bool> crearReporte({
    required String correoUsuario,
    required String descripcionObjeto,
    required int idLugarAproxPerdida,
    required DateTime fechaAproxPerdida,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/reportes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'descripcionObjeto': descripcionObjeto,
          'correoUsuario': correoUsuario.toLowerCase().trim(),
          'idLugarAproxPerdida': idLugarAproxPerdida,
          'fechaAproxPerdida':
              '${fechaAproxPerdida.year}-'
              '${fechaAproxPerdida.month.toString().padLeft(2, '0')}-'
              '${fechaAproxPerdida.day.toString().padLeft(2, '0')}',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('ERROR crearReporte API: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerReportes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/reportes/admin'),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerReportes API: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerLugares() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/lugares'),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerLugares API: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerObjetosPublicados() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos'),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerObjetosPublicados API: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerReportesDePersona({
    required int idPersona,
  }) async {
    return [];
  }

  static Future<List<Map<String, dynamic>>> obtenerReportesDeUsuario({
    required String correo,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/reportes/usuario/$correo'),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR obtenerReportesDeUsuario API: ${response.statusCode} ${response.body}',
        );
        return [];
      }

      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerReportesDeUsuario API: $e');
      return [];
    }
  }

  static Future<bool> anularReporte(int idReporte) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/reportes/$idReporte/anular'),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR anularReporte API: ${response.statusCode} ${response.body}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('ERROR anularReporte API: $e');
      return false;
    }
  }
}