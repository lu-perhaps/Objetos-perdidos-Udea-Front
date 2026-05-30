import 'package:flutter/material.dart';
import '../main.dart';
import '../Constants/estados.dart';

class EntregaRepository {
  static Future<bool> registrarEntrega({
    required int idObjeto,
    required int idPersonaRecibe,
    required int idPersonaEntrega,
    required int idSolicitudReclamo,
    String? observaciones,
  }) async {
    try {
      // 1. Crear registro de entrega
      await supabase.from('tbl_entrega_objeto').insert({
        'id_objeto': idObjeto,
        'id_persona_recibe': idPersonaRecibe,
        'id_persona_entrega': idPersonaEntrega,
        'id_solicitud_reclamo': idSolicitudReclamo,
        'observaciones': observaciones,
      });

      // 2. Cambiar estado del objeto a entregado
      await supabase
          .from('tbl_objeto')
          .update({'id_estado': Estados.objetoEntregado})
          .eq('id', idObjeto);

      // 3. Ocultar publicación del objeto
      await supabase
          .from('tbl_publicacion')
          .update({'id_estado': Estados.publicacionOculta})
          .eq('id_objeto', idObjeto);

      // 4. Cambiar estado de la solicitud a entregada
      await supabase
          .from('tbl_solicitud_reclamo')
          .update({'id_estado': Estados.solicitudEntregada})
          .eq('id', idSolicitudReclamo);

      return true;
    } catch (e) {
      debugPrint('ERROR registrarEntrega: $e');
      return false;
    }
  }
}