class TipoNotificacion {
  final int id;
  final String? nombre;

  TipoNotificacion({required this.id, this.nombre});

  factory TipoNotificacion.fromMap(Map<String, dynamic> map) {
    return TipoNotificacion(id: map['id'], nombre: map['nombre']);
  }
}