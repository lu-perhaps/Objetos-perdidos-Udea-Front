class Persona {
  final int id;
  final String nombre;
  final String correo;
  final String? numDocumento;
  final String? celular;
  final int idEstado;
  final int? idTipoDocumento;
  final int idRol;

  Persona({
    required this.id,
    required this.nombre,
    required this.correo,
    this.numDocumento,
    this.celular,
    required this.idEstado,
    this.idTipoDocumento,
    required this.idRol,
  });

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      id: map['id'],
      nombre: map['nombre'],
      correo: map['correo'],
      numDocumento: map['num_documento'],
      celular: map['celular'],
      idEstado: map['id_estado'],
      idTipoDocumento: map['id_tipo_documento'],
      idRol: map['id_rol'],
    );
  }
}