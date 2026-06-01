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
  static Future<void> actualizarFotografia({
    required int idObjeto,
    required String url,
  }) async {
    await supabase
        .from('tbl_objeto')
        .update({'fotografia': url})
        .eq('id', idObjeto);
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
  // Obtiene objetos vencidos (fecha_hallazgo + tiempo_maximo > hoy)
  static Future<List<Map<String, dynamic>>> obtenerObjetosVencidos() async {
    try {
      final data = await supabase
          .from('tbl_objeto')
          .select('''
            id,
            nombre,
            descripcion_general,
            fotografia,
            fecha_hallazgo,
            id_estado,
            tbl_categoria (
              nombre,
              tiempo_maximo_almacenamiento
            ),
            lugar_actual:tbl_lugar!fk_objeto_lugar_actual (
              nombre
            )
          ''')
          .inFilter('id_estado', [
            Estados.objetoEnCustodia,
            Estados.objetoDisponible,
          ]);

      final hoy = DateTime.now();
      final vencidos = (data as List).where((obj) {
        final fechaStr = obj['fecha_hallazgo'];
        final tiempoMax =
            obj['tbl_categoria']?['tiempo_maximo_almacenamiento'] as int?;
        if (fechaStr == null || tiempoMax == null) return false;
        final fecha = DateTime.tryParse(fechaStr);
        if (fecha == null) return false;
        final fechaVencimiento = fecha.add(Duration(days: tiempoMax));
        return hoy.isAfter(fechaVencimiento);
      }).toList();

      return List<Map<String, dynamic>>.from(vencidos);
    } catch (e) {
      debugPrint('ERROR obtenerObjetosVencidos: $e');
      return [];
    }
  }

  // Cambia estado del objeto y oculta su publicación
  static Future<bool> registrarDisposicionFinal({
    required int idObjeto,
    required int nuevoEstado,
  }) async {
    try {
      await supabase
          .from('tbl_objeto')
          .update({'id_estado': nuevoEstado})
          .eq('id', idObjeto);

      await supabase
          .from('tbl_publicacion')
          .update({'id_estado': Estados.publicacionOculta})
          .eq('id_objeto', idObjeto);

      return true;
    } catch (e) {
      debugPrint('ERROR registrarDisposicionFinal: $e');
      return false;
    }
  }

}