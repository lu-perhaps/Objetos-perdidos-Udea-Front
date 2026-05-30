class Rol {
  final int id;
  final String nombre;
  final String? descripcion;

  Rol({required this.id, required this.nombre, this.descripcion});

  factory Rol.fromMap(Map<String, dynamic> map) {
    return Rol(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
    );
  }
}