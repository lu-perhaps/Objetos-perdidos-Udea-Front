class ReportePerdida {
  final int id;
  final String? descripcionObjeto;
  final DateTime? fechaReporte;
  final DateTime? fechaAproxPerdida;
  final int? idLugarAproxPerdida;
  final int idPersona;
  final int idEstado;

  ReportePerdida({
    required this.id,
    this.descripcionObjeto,
    this.fechaReporte,
    this.fechaAproxPerdida,
    this.idLugarAproxPerdida,
    required this.idPersona,
    required this.idEstado,
  });

  factory ReportePerdida.fromMap(Map<String, dynamic> map) {
    return ReportePerdida(
      id: map['id'],
      descripcionObjeto: map['descripcion_objeto'],
      fechaReporte: map['fecha_reporte'] != null
          ? DateTime.tryParse(map['fecha_reporte'])
          : null,
      fechaAproxPerdida: map['fecha_aprox_perdida'] != null
          ? DateTime.tryParse(map['fecha_aprox_perdida'])
          : null,
      idLugarAproxPerdida: map['id_lugar_aprox_perdida'],
      idPersona: map['id_persona'],
      idEstado: map['id_estado'],
    );
  }
}