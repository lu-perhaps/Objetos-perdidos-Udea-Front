class TipoDocumento {
  final int id;
  final String nombre;

  TipoDocumento({required this.id, required this.nombre});

  factory TipoDocumento.fromMap(Map<String, dynamic> map) {
    return TipoDocumento(id: map['id'], nombre: map['nombre']);
  }
}