class Estado {
  final int id;
  final String nombre;
  final int? idTipoEstado;

  Estado({
    required this.id,
    required this.nombre,
    this.idTipoEstado,
  });

  factory Estado.fromMap(Map<String, dynamic> map) {
    return Estado(
      id: map['id'],
      nombre: map['nombre'],
      idTipoEstado: map['id_tipo_estado'],
    );
  }
}