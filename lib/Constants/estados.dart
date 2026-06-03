class Estados {
  // ── Objeto (id_tipo_estado = 1) ──────────────────
  static const int objetoEnCustodia = 1;
  static const int objetoEntregado = 2;
  static const int objetoDisponible = 3;
  static const int objetoDonado = 14;

  // Se dejan ambos nombres para no romper pantallas anteriores
  static const int objetoDesecho = 15;
  static const int objetoDesechado = 15;

  // ── Persona (id_tipo_estado = 2) ─────────────────
  static const int personaActiva = 4;
  static const int personaInactiva = 5;

  // ── Reporte de pérdida (id_tipo_estado = 3) ──────
  static const int reportePendiente = 6;
  static const int reporteResuelto = 7;
  static const int reporteAnulado = 22;

  // ── Solicitud de reclamo (id_tipo_estado = 4) ────
  static const int solicitudPendiente = 8;
  static const int solicitudAprobada = 9;
  static const int solicitudRechazada = 10;
  static const int solicitudEntregada = 2;
  static const int solicitudAnulada = 13;

  // ── Publicación (id_tipo_estado = 5) ─────────────
  static const int publicacionPublicada = 11;
  static const int publicacionOculta = 12;

  // ── Roles ────────────────────────────────────────
  static const int rolUsuario = 1;
  static const int rolAdmin = 2;

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

  static String nombreEstadoSolicitud(dynamic idEstado) {
    final id = int.tryParse(idEstado?.toString() ?? '') ?? -1;

    switch (id) {
      case solicitudPendiente:
        return 'Pendiente';
      case solicitudAprobada:
        return 'Aprobada';
      case solicitudRechazada:
        return 'Rechazada';
      case solicitudEntregada:
        return 'Entregada';
      case solicitudAnulada:
        return 'Anulada';
      default:
        return 'Sin estado';
    }
  }

  static String nombreEstadoReporte(dynamic idEstado) {
    final id = int.tryParse(idEstado?.toString() ?? '') ?? -1;

    switch (id) {
      case reportePendiente:
        return 'Pendiente';
      case reporteResuelto:
        return 'Resuelto';
      case reporteAnulado:
        return 'Anulado';
      default:
        return 'Sin estado';
    }
  }
}