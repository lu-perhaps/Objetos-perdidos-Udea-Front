import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Constants/api_config.dart';

class SolicitudesAdminPage extends StatefulWidget {
  const SolicitudesAdminPage({super.key});

  @override
  State<SolicitudesAdminPage> createState() => _SolicitudesAdminPageState();
}

class _SolicitudesAdminPageState extends State<SolicitudesAdminPage> {
  List<Map<String, dynamic>> solicitudes = [];
  bool cargando = true;

  int filtroEstado = 8;

  @override
  void initState() {
    super.initState();
    cargarSolicitudes();
  }

  Future<void> cargarSolicitudes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/solicitudes/admin'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        solicitudes = List<Map<String, dynamic>>.from(data);
        cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR CARGANDO SOLICITUDES: $e');

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando solicitudes: $e')),
      );
    }
  }

  Future<void> actualizarEstado(int id, String accion) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/solicitudes/$id/$accion'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      await cargarSolicitudes();
    } catch (e) {
      debugPrint('ERROR ACTUALIZANDO ESTADO: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando estado: $e')),
      );
    }
  }

  String estadoTexto(int estado) {
    if (estado == 8) return 'Pendiente';
    if (estado == 9) return 'Aprobado';
    if (estado == 10) return 'Rechazado';
    return 'Desconocido';
  }

  Color estadoColor(int estado) {
    if (estado == 8) return Colors.orange;
    if (estado == 9) return Colors.green;
    if (estado == 10) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final solicitudesFiltradas = filtroEstado == 0
        ? solicitudes
        : solicitudes.where((s) => s['idEstado'] == filtroEstado).toList();

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
            child: Padding(
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
                          'SOLICITUDES DE RECLAMO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: cargarSolicitudes,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _botonFiltro('Pendientes', 8),
                      const SizedBox(width: 8),
                      _botonFiltro('Aprobadas', 9),
                      const SizedBox(width: 8),
                      _botonFiltro('Rechazadas', 10),
                    ],
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          filtroEstado = 0;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text(
                        'Ver todas',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : solicitudesFiltradas.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay solicitudes en este estado',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: solicitudesFiltradas.length,
                                itemBuilder: (context, index) {
                                  final s = solicitudesFiltradas[index];
                                  final estado = s['idEstado'];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: estadoColor(estado),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s['objeto'] ?? 'Objeto sin nombre',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          'Usuario: ${s['correoUsuario'] ?? 'Sin correo'}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),

                                        Text(
                                          'Lugar pérdida: ${s['lugar'] ?? 'Sin lugar'}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),

                                        Text(
                                          'Fecha pérdida: ${s['fechaAproxPerdida'] ?? 'Sin fecha'}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          'Descripción: ${s['descripcion'] ?? 'Sin descripción'}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: estadoColor(estado)
                                                .withOpacity(0.25),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: estadoColor(estado),
                                            ),
                                          ),
                                          child: Text(
                                            estadoTexto(estado),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        if (estado == 8) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      actualizarEstado(
                                                    s['id'],
                                                    'aprobar',
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                  child: const Text(
                                                    'Aprobar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      actualizarEstado(
                                                    s['id'],
                                                    'rechazar',
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: const Text(
                                                    'Rechazar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
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

  Widget _botonFiltro(String texto, int estado) {
    final activo = filtroEstado == estado;

    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            filtroEstado = estado;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              activo ? const Color(0xFF0A8F4D) : Colors.white.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}