import 'package:flutter/material.dart';
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
}