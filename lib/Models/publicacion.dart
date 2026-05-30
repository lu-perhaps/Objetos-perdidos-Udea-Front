class Publicacion {
  final int id;
  final int idObjeto;
  final DateTime? fecha;
  final int idPersonaPublica;
  final int idEstado;

  Publicacion({
    required this.id,
    required this.idObjeto,
    this.fecha,
    required this.idPersonaPublica,
    required this.idEstado,
  });

  factory Publicacion.fromMap(Map<String, dynamic> map) {
    return Publicacion(
      id: map['id'],
      idObjeto: map['id_objeto'],
      fecha: map['fecha'] != null ? DateTime.tryParse(map['fecha']) : null,
      idPersonaPublica: map['id_persona_publica'],
      idEstado: map['id_estado'],
    );
  }
}