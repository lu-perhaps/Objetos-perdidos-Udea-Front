class Notificacion {
  final int id;
  final String? mensaje;
  final DateTime? fechaEnvio;
  final int idPersonaRecibe;
  final int? idPersonaEnvia;
  final int idTipoNotificacion;

  Notificacion({
    required this.id,
    this.mensaje,
    this.fechaEnvio,
    required this.idPersonaRecibe,
    this.idPersonaEnvia,
    required this.idTipoNotificacion,
  });

  factory Notificacion.fromMap(Map<String, dynamic> map) {
    return Notificacion(
      id: map['id'],
      mensaje: map['mensaje'],
      fechaEnvio: map['fecha_envio'] != null
          ? DateTime.tryParse(map['fecha_envio'])
          : null,
      idPersonaRecibe: map['id_persona_recibe'],
      idPersonaEnvia: map['id_persona_envia'],
      idTipoNotificacion: map['id_tipo_notificacion'],
    );
  }
}