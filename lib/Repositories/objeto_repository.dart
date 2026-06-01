import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../constants/estados.dart';
import '../Constants/api_config.dart';

class ObjetoRepository {
  // Crea el objeto y opcionalmente lo publica
  static Future<int?> registrarObjeto({
    required String nombre,
    required String descripcionGeneral,
    required String descripcionDetallada,
    required int idCategoria,
    required int idLugarEncontrado,
    required int idLugarActual,
    required DateTime fechaHallazgo,
    String? fotografia,
    required bool publicar,
    required int idPersonaAdmin,
  }) async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null || user.email == null) {
        debugPrint('ERROR registrarObjeto API: usuario no autenticado');
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
          'descripcionGeneral': descripcionGeneral,
          'descripcionDetallada': descripcionDetallada,
          'idCategoria': idCategoria,
          'fechaHallazgo':
              '${fechaHallazgo.year}-'
              '${fechaHallazgo.month.toString().padLeft(2, '0')}-'
              '${fechaHallazgo.day.toString().padLeft(2, '0')}',
          'fotografia': fotografia,
          'idLugarEncontrado': idLugarEncontrado,
          'idLugarActual': idLugarActual,
          'correoAdmin': user.email!.toLowerCase().trim(),
          'publicar': publicar,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          'ERROR registrarObjeto API: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      return data['id'] as int?;
    } catch (e) {
      debugPrint('ERROR registrarObjeto API: $e');
      return null;
    }
  }

  // Carga categorías para el dropdown
  static Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/categorias'),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerCategorias API: $e');
      return [];
    }
  }

  // Carga lugares para los dropdowns
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

  static Future<List<Map<String, dynamic>>> obtenerObjetosAdmin() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos/admin'),
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerObjetosAdmin API: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> obtenerObjetoPorId(int idObjeto) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos/$idObjeto'),
      );

      if (response.statusCode != 200) {
        debugPrint('ERROR obtenerObjetoPorId API: ${response.statusCode} ${response.body}');
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('ERROR obtenerObjetoPorId API: $e');
      return null;
    }
  }

    // Sube la imagen al Storage y retorna la ruta
  static Future<void> subirImagen({
    required String rutaStorage,
    required File archivo,
  }) async {
    await supabase.storage
        .from('objetos-imagenes')
        .upload(rutaStorage, archivo);
  }
  // Actualiza la fotografía de un objeto ya guardado
  static Future<bool> actualizarFotografia({
      required int idObjeto,
      required String url,
    }) async {
      try {
        final response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/objetos/$idObjeto/fotografia'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'url': url,
          }),
        );

        if (response.statusCode != 200) {
          debugPrint(
            'ERROR actualizarFotografia API: ${response.statusCode} ${response.body}',
          );
          return false;
        }

        return true;
      } catch (e) {
        debugPrint('ERROR actualizarFotografia API: $e');
        return false;
      }
      
  }

  static Future<void> subirImagenBytes({
    required String rutaStorage,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final mimeType = lookupMimeType(nombreArchivo) ?? 'image/jpeg';
    
    await supabase.storage
        .from('objetos-imagenes')
        .uploadBinary(
          rutaStorage,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
  }
  // Obtiene la URL pública de una imagen en Storage
  static String obtenerUrlPublica(String rutaStorage) {
    return supabase.storage
        .from('objetos-imagenes')
        .getPublicUrl(rutaStorage);
  }
  // Obtiene objetos vencidos desde la API de backend
  static Future<List<Map<String, dynamic>>> obtenerObjetosVencidos() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos/vencidos'),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR obtenerObjetosVencidos API: ${response.statusCode} ${response.body}',
        );
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('ERROR obtenerObjetosVencidos API: $e');
      return [];
    }
  }

  // Cambia disposición final por API
  static Future<bool> registrarDisposicionFinal({
    required int idObjeto,
    required int nuevoEstado,
  }) async {
    try {
      final endpoint = nuevoEstado == Estados.objetoDonado
          ? 'donar'
          : 'desechar';

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos/$idObjeto/$endpoint'),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ERROR registrarDisposicionFinal API: ${response.statusCode} ${response.body}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('ERROR registrarDisposicionFinal API: $e');
      return false;
    }
  }
  // PARA OCULTAR PUBLICACIONES
  static Future<bool> ocultarPublicacion(int idObjeto) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos/$idObjeto/ocultar-publicacion'),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint(
          'ERROR ocultarPublicacion API: ${response.statusCode} ${response.body}',
        );
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('ERROR ocultarPublicacion API: $e');
      return false;
    }
  }
}