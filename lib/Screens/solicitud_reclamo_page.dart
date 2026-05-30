import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Constants/api_config.dart';
import '../main.dart';

class SolicitudReclamoPage extends StatefulWidget {
  final Map<String, dynamic> objeto;

  const SolicitudReclamoPage({super.key, required this.objeto});

  @override
  State<SolicitudReclamoPage> createState() => _SolicitudReclamoPageState();
}

class _SolicitudReclamoPageState extends State<SolicitudReclamoPage> {
  final descripcionController = TextEditingController();
  final fechaController = TextEditingController();

  bool enviando = false;
  bool cargandoLugares = true;

  int? lugarSeleccionado;
  List<Map<String, dynamic>> lugares = [];

  DateTime? fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    cargarLugares();
  }

  @override
  void dispose() {
    descripcionController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  Future<void> cargarLugares() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/lugares'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error cargando lugares: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        lugares = List<Map<String, dynamic>>.from(data);
        cargandoLugares = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoLugares = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando lugares: $e')),
      );
    }
  }

  Future<void> seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'CO'),
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
        fechaController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  String? fechaParaBackend() {
    if (fechaSeleccionada == null) return null;

    return '${fechaSeleccionada!.year}-'
        '${fechaSeleccionada!.month.toString().padLeft(2, '0')}-'
        '${fechaSeleccionada!.day.toString().padLeft(2, '0')}';
  }

  Future<void> enviarSolicitud() async {
    if (descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una descripción del objeto')),
      );
      return;
    }

    if (lugarSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un lugar aproximado')),
      );
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/solicitudes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'descripcion': descripcionController.text.trim(),
          'idObjeto': widget.objeto['id'],
          'correoUsuario': user.email!.toLowerCase().trim(),
          'idLugarAproxPerdida': lugarSeleccionado,
          'fechaAproxPerdida': fechaParaBackend(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar solicitud: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreObjeto = (widget.objeto['nombre'] ?? 'Objeto').toString();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/udea_bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.45)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'SOLICITUD DE RECLAMO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    nombreObjeto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _campo(
                    label: 'Descripción del objeto',
                    controller: descripcionController,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 16),

                  cargandoLugares
                      ? const CircularProgressIndicator(color: Colors.white)
                      : DropdownButtonFormField<int>(
                          value: lugarSeleccionado,
                          dropdownColor: const Color(0xFF1E1E1E),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Lugar aproximado de pérdida',
                            labelStyle:
                                const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A8F4D),
                                width: 2,
                              ),
                            ),
                          ),
                          items: lugares.map((lugar) {
                            return DropdownMenuItem<int>(
                              value: lugar['id'],
                              child: Text(
                                lugar['nombre'].toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              lugarSeleccionado = value;
                            });
                          },
                        ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: seleccionarFecha,
                    child: AbsorbPointer(
                      child: _campo(
                        label: 'Fecha aproximada de pérdida',
                        controller: fechaController,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: enviando ? null : enviarSolicitud,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A8F4D),
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        enviando ? 'ENVIANDO...' : 'ENVIAR SOLICITUD',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0A8F4D), width: 2),
        ),
      ),
    );
  }
}