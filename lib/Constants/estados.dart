class Estados {
  // ── Objeto (id_tipo_estado = 1) ──────────────────
  static const int objetoEnCustodia = 1;
  static const int objetoEntregado  = 2;
  static const int objetoDisponible = 3;

  // ── Persona (id_tipo_estado = 2) ─────────────────
  static const int personaActiva   = 4;
  static const int personaInactiva = 5;

  // ── Reporte de pérdida (id_tipo_estado = 3) ──────
  static const int reportePendiente = 6;
  static const int reporteResuelto  = 7;

  // ── Solicitud de reclamo (id_tipo_estado = 4) ────
  static const int solicitudPendiente = 8;
  static const int solicitudAprobada  = 9;
  static const int solicitudRechazada = 10;
  static const int solicitudEntregada = 2;
  static const int solicitudAnulada   = 13;

  // ── Publicación (id_tipo_estado = 5) ─────────────
  static const int publicacionPublicada = 11;
  static const int publicacionOculta    = 12;

  // ── Roles ─────────────────────────────────────────
  static const int rolUsuario = 1;
  static const int rolAdmin   = 2;

  // ── Donación y Desecho ───────────────────────────────────────
  static const int objetoDonado = 14;
  static const int objetoDesecho = 15;

  static String nombreEstadoObjeto(dynamic idEstado) {
    final id = int.tryParse(idEstado?.toString() ?? '') ?? -1;
    switch (id) {
      case objetoEnCustodia:
        return 'En custodia';
      case objetoEntregado:
        return 'Entregado';
      case objetoDisponible:
        return 'Disponible';
      case objetoDonado:
        return 'Donado';
      case objetoDesecho:
        return 'Desechado';
      default:
        return 'Sin estado';
    }
  }
}