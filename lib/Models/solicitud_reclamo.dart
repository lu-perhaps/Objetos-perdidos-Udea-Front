class SolicitudReclamo {
  final int id;
  final String? descripcion;
  final DateTime? fecha;
  final int idObjeto;
  final int idPersona;
  final int? idReporte;
  final int? idLugarAproxPerdida;
  final DateTime? fechaAproxPerdida;
  final int idEstado;

  SolicitudReclamo({
    required this.id,
    this.descripcion,
    this.fecha,
    required this.idObjeto,
    required this.idPersona,
    this.idReporte,
    this.idLugarAproxPerdida,
    this.fechaAproxPerdida,
    required this.idEstado,
  });

  factory SolicitudReclamo.fromMap(Map<String, dynamic> map) {
    return SolicitudReclamo(
      id: map['id'],
      descripcion: map['descripcion'],
      fecha: map['fecha'] != null ? DateTime.tryParse(map['fecha']) : null,
      idObjeto: map['id_objeto'],
      idPersona: map['id_persona'],
      idReporte: map['id_reporte'],
      idLugarAproxPerdida: map['id_lugar_aprox_perdida'],
      fechaAproxPerdida: map['fecha_aprox_perdida'] != null
          ? DateTime.tryParse(map['fecha_aprox_perdida'])
          : null,
      idEstado: map['id_estado'],
    );
  }
}