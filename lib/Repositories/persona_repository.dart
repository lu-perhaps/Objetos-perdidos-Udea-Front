import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/persona.dart';
import '../main.dart';

class PersonaRepository {
  // Crea la persona en BD si no existe (sin nombre, se completa en Flujo 0)
  static Future<void> crearSiNoExiste(User user) async {
    try {
      final correo = user.email!.toLowerCase();
      await supabase.from('tbl_persona').upsert(
        {
          'correo': correo,
          'id_rol': 1,
          'id_estado': 4,
        },
        onConflict: 'correo', // si ya existe, no hace nada
        ignoreDuplicates: true,
      );
    } catch (e) {
      debugPrint('ERROR crearSiNoExiste: $e');
    }
  }

  // Verifica si el perfil está completo (nombre, teléfono, documento)
  static Future<bool> perfilCompleto() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final data = await supabase
          .from('tbl_persona')
          .select('nombre, celular, num_documento')
          .eq('correo', user.email!.toLowerCase())
          .single();

      final nombre = (data['nombre'] ?? '').toString().trim();
      final celular = (data['celular'] ?? '').toString().trim();
      final doc = (data['num_documento'] ?? '').toString().trim();

      return nombre.isNotEmpty && celular.isNotEmpty && doc.isNotEmpty;
    } catch (e) {
      debugPrint('ERROR perfilCompleto: $e');
      return false;
    }
  }

  // Actualiza los datos del perfil
  static Future<bool> actualizarPerfil({
    required String nombre,
    required String celular,
    required String numDocumento,
    required int idTipoDocumento,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('tbl_persona').update({
        'nombre': nombre.trim(),
        'celular': celular.trim(),
        'num_documento': numDocumento.trim(),
        'id_tipo_documento': idTipoDocumento,
      }).eq('correo', user.email!.toLowerCase());

      return true;
    } catch (e) {
      debugPrint('ERROR actualizarPerfil: $e');
      return false;
    }
  }

  // Obtiene la persona actual completa
  static Future<Persona?> obtenerPersonaActual() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final data = await supabase
          .from('tbl_persona')
          .select()
          .eq('correo', user.email!.toLowerCase())
          .single();

      return Persona.fromMap(data);
    } catch (e) {
      debugPrint('ERROR obtenerPersonaActual: $e');
      return null;
    }
  }

  // Obtiene solo el id de la persona actual
  static Future<int?> obtenerIdPersonaActual() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final data = await supabase
          .from('tbl_persona')
          .select('id')
          .eq('correo', user.email!.toLowerCase())
          .single();

      return data['id'] as int?;
    } catch (e) {
      debugPrint('ERROR obtenerIdPersonaActual: $e');
      return null;
    }
  }
}