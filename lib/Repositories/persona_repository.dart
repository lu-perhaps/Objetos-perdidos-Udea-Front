import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Constants/api_config.dart';
import '../services/auth_service.dart';
import '../models/persona.dart';
import '../main.dart';

class PersonaRepository {
  static Future<void> crearSiNoExiste(User user) async {
    try {
      await AuthService.obtenerUsuarioActualBackend();
    } catch (e) {
      debugPrint('ERROR crearSiNoExiste backend: $e');
    }
  }

  static Future<bool> perfilCompleto() async {
    try {
      final data = await AuthService.obtenerUsuarioActualBackend();
      if (data == null) return false;

      return data['perfilCompleto'] == true;
    } catch (e) {
      debugPrint('ERROR perfilCompleto backend: $e');
      return false;
    }
  }

  static Future<bool> actualizarPerfil({
    required String nombre,
    required String celular,
    required String numDocumento,
    required int idTipoDocumento,
  }) async {
    try {
      final session = supabase.auth.currentSession;

      if (session == null || session.accessToken.isEmpty) {
        debugPrint('ERROR actualizarPerfil: no hay sesión activa');
        return false;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/me/perfil'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre.trim(),
          'celular': celular.trim(),
          'numDocumento': numDocumento.trim(),
          'idTipoDocumento': idTipoDocumento,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR actualizarPerfil backend: ${response.statusCode} ${response.body}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('ERROR actualizarPerfil backend: $e');
      return false;
    }
  }

  static Future<Persona?> obtenerPersonaActual() async {
    try {
      final data = await AuthService.obtenerUsuarioActualBackend();
      if (data == null) return null;

      final mapAdaptado = {
        'id': data['id'],
        'nombre': data['nombre'],
        'correo': data['correo'],
        'id_rol': data['idRol'],
        'id_estado': data['idEstado'],
        'celular': data['celular'],
        'num_documento': data['numDocumento'],
        'id_tipo_documento': data['idTipoDocumento'],
      };

      return Persona.fromMap(mapAdaptado);
    } catch (e) {
      debugPrint('ERROR obtenerPersonaActual backend: $e');
      return null;
    }
  }

  static Future<int?> obtenerIdPersonaActual() async {
    try {
      final data = await AuthService.obtenerUsuarioActualBackend();
      if (data == null) return null;

      return int.tryParse(data['id'].toString());
    } catch (e) {
      debugPrint('ERROR obtenerIdPersonaActual backend: $e');
      return null;
    }
  }
}