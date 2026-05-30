class Objeto {
  final int id;
  final String nombre;
  final String? descripcionGeneral;
  final String? descripcionDetallada;
  final int idCategoria;
  final DateTime? fechaHallazgo;
  final String? fotografia;
  final int idLugarEncontrado;
  final int idLugarActual;
  final int idEstado;

  Objeto({
    required this.id,
    required this.nombre,
    this.descripcionGeneral,
    this.descripcionDetallada,
    required this.idCategoria,
    this.fechaHallazgo,
    this.fotografia,
    required this.idLugarEncontrado,
    required this.idLugarActual,
    required this.idEstado,
  });

  factory Objeto.fromMap(Map<String, dynamic> map) {
    return Objeto(
      id: map['id'],
      nombre: map['nombre'],
      descripcionGeneral: map['descripcion_general'],
      descripcionDetallada: map['descripcion_detallada'],
      idCategoria: map['id_categoria'],
      fechaHallazgo: map['fecha_hallazgo'] != null
          ? DateTime.tryParse(map['fecha_hallazgo'])
          : null,
      fotografia: map['fotografia'],
      idLugarEncontrado: map['id_lugar_encontrado'],
      idLugarActual: map['id_lugar_actual'],
      idEstado: map['id_estado'],
    );
  }
}