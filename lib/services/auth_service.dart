import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  // Obtiene el rol del usuario actual desde tbl_persona
  static Future<int?> obtenerRol() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final data = await supabase
          .from('tbl_persona')
          .select('id_rol')
          .eq('correo', user.email!.toLowerCase())
          .single();

      return data['id_rol'] as int?;
    } catch (e) {
      debugPrint('ERROR obtenerRol: $e');
      return null;
    }
  }

  // Obtiene el id de la persona actual desde tbl_persona
  static Future<int?> obtenerIdPersona() async {
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
      debugPrint('ERROR obtenerIdPersona: $e');
      return null;
    }
  }

  // Verifica si el usuario actual es admin
  static Future<bool> esAdmin() async {
    final rol = await obtenerRol();
    return rol == 2;
  }

  // Cierra sesión
  static Future<void> cerrarSesion() async {
    await supabase.auth.signOut();
  }
}