class EntregaObjeto {
  final int id;
  final DateTime? fechaEntrega;
  final int idObjeto;
  final int idPersonaRecibe;
  final int idPersonaEntrega;
  final int idSolicitudReclamo;
  final String? observaciones;

  EntregaObjeto({
    required this.id,
    this.fechaEntrega,
    required this.idObjeto,
    required this.idPersonaRecibe,
    required this.idPersonaEntrega,
    required this.idSolicitudReclamo,
    this.observaciones,
  });

  factory EntregaObjeto.fromMap(Map<String, dynamic> map) {
    return EntregaObjeto(
      id: map['id'],
      fechaEntrega: map['fecha_entrega'] != null
          ? DateTime.tryParse(map['fecha_entrega'])
          : null,
      idObjeto: map['id_objeto'],
      idPersonaRecibe: map['id_persona_recibe'],
      idPersonaEntrega: map['id_persona_entrega'],
      idSolicitudReclamo: map['id_solicitud_reclamo'],
      observaciones: map['observaciones'],
    );
  }
}