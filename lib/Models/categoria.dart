class Categoria {
  final int id;
  final String nombre;
  final int? tiempoMaximoAlmacenamiento;

  Categoria({
    required this.id,
    required this.nombre,
    this.tiempoMaximoAlmacenamiento,
  });

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'],
      tiempoMaximoAlmacenamiento: map['tiempo_maximo_almacenamiento'],
    );
  }
}