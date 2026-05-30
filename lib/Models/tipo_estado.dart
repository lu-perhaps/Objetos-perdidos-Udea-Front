class TipoEstado {
  final int id;
  final String nombre;

  TipoEstado({required this.id, required this.nombre});

  factory TipoEstado.fromMap(Map<String, dynamic> map) {
    return TipoEstado(id: map['id'], nombre: map['nombre']);
  }
}