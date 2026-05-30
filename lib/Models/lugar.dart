class Lugar {
  final int id;
  final String nombre;

  Lugar({required this.id, required this.nombre});

  factory Lugar.fromMap(Map<String, dynamic> map) {
    return Lugar(id: map['id'], nombre: map['nombre']);
  }
}