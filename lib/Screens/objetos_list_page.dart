import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Constants/api_config.dart';
import 'objeto_detail_page.dart';

class ObjetosListPage extends StatefulWidget {
  const ObjetosListPage({super.key});

  @override
  State<ObjetosListPage> createState() => _ObjetosListPageState();
}

class _ObjetosListPageState extends State<ObjetosListPage> {
  List<Map<String, dynamic>> objetos = [];
  bool cargando = true;
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    cargarObjetos();
  }

  Future<void> cargarObjetos() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        objetos = List<Map<String, dynamic>>.from(data);
        cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR CARGANDO OBJETOS DESDE BACKEND: $e');

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando objetos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = objetos.where((obj) {
      final nombre = (obj['nombre'] ?? '').toString().toLowerCase();
      final categoria = (
        obj['categoria'] ??
        obj['tbl_categoria']?['nombre'] ??
        ''
      ).toString().toLowerCase();
      final descripcion = (
        obj['descripcionGeneral'] ??
        obj['descripcion_general'] ??
        ''
      ).toString().toLowerCase();
      final texto = '$nombre $categoria $descripcion';
      return texto.contains(busqueda.toLowerCase());
    }).toList();

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'BUSCAR OBJETOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            cargando = true;
                          });
                          cargarObjetos();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (value) {
                      setState(() {
                        busqueda = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '¿Qué perdiste?...',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Resultados (${filtrados.length} encontrados)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                        : filtrados.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay objetos publicados',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtrados.length,
                                itemBuilder: (context, index) {
                                  final objeto = filtrados[index];
                                  final nombre = (objeto['nombre'] ?? 'Sin nombre')
                                      .toString();
                                  final descripcion = (
                                    objeto['descripcionGeneral'] ??
                                    objeto['descripcion_general'] ??
                                    'Sin descripción'
                                  ).toString();
                                  final categoria = (
                                    objeto['categoria'] ??
                                    objeto['tbl_categoria']?['nombre'] ??
                                    'Sin categoría'
                                  ).toString();
                                  final fecha = (
                                    objeto['fechaHallazgo'] ??
                                    objeto['fecha_hallazgo'] ??
                                    ''
                                  ).toString();
                                  final lugarActual = (
                                    objeto['lugarActual'] ??
                                    objeto['lugar_actual'] ??
                                    'No registrado'
                                  ).toString();

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ObjetoDetailPage(
                                                idObjeto: objeto['id'] ?? objeto['id_objeto'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFF0A8F4D),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Categoría: $categoria',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            descripcion,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          if (fecha.isNotEmpty)
                                            Text(
                                              'Hallado: $fecha',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 15,
                                              ),
                                            ),
                                          Text(
                                            'Ubicación actual: $lugarActual',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
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
}