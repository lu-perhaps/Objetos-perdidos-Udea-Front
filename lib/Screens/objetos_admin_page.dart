import 'dart:ui';

import 'package:flutter/material.dart';

import '../Constants/estados.dart';
import '../Repositories/objeto_repository.dart';
import 'objeto_detail_page.dart';

class ObjetosAdminPage extends StatefulWidget {
  const ObjetosAdminPage({super.key});

  @override
  State<ObjetosAdminPage> createState() => _ObjetosAdminPageState();
}

class _ObjetosAdminPageState extends State<ObjetosAdminPage> {
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
      final data = await ObjetoRepository.obtenerObjetosAdmin();

      if (!mounted) return;

      setState(() {
        objetos = data;
        cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR CARGANDO INVENTARIO ADMIN: $e');

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando inventario: $e')),
      );
    }
  }

  String _nombreEstado(dynamic idEstado) {
    return Estados.nombreEstadoObjeto(idEstado);
  }

  Color _estadoChipColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'disponible':
        return const Color(0xFF2E7D32);
      case 'en custodia':
        return const Color(0xFF1565C0);
      case 'entregado':
        return const Color(0xFFEF6C00);
      case 'donado':
        return const Color(0xFF6A1B9A);
      case 'desechado':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF455A64);
    }
  }

  bool _puedeOcultarPublicacion(Map<String, dynamic> objeto) {
    final idEstado = int.tryParse(
      (objeto['idEstado'] ?? objeto['id_estado'] ?? '').toString(),
    );

    final estado = (
      objeto['estado'] ??
      _nombreEstado(idEstado)
    ).toString().toLowerCase();

    return idEstado == Estados.objetoDisponible ||
        estado == 'disponible';
  }

  Future<void> _ocultarPublicacion(Map<String, dynamic> objeto) async {
    final idObjeto = int.tryParse(
      (objeto['id'] ?? objeto['id_objeto'] ?? '').toString(),
    );

    if (idObjeto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de objeto inválido')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ocultar publicación'),
        content: const Text(
          '¿Seguro que quieres ocultar esta publicación? El objeto seguirá en el inventario, pero ya no aparecerá disponible para reclamos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ocultar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await ObjetoRepository.ocultarPublicacion(idObjeto);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Publicación ocultada correctamente'
              : 'No se pudo ocultar la publicación',
        ),
      ),
    );

    if (ok) {
      setState(() => cargando = true);
      await cargarObjetos();
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
                          'INVENTARIO COMPLETO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          setState(() => cargando = true);
                          await cargarObjetos();
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
                      hintText: 'Buscar en el inventario...',
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
                                  'No hay objetos en el inventario',
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

                                  final nombre =
                                      (objeto['nombre'] ?? 'Sin nombre')
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

                                  final estado = objeto['estado']?.toString() ??
                                      _nombreEstado(
                                        objeto['idEstado'] ??
                                            objeto['id_estado'],
                                      );

                                  final puedeOcultar =
                                      _puedeOcultarPublicacion(objeto);

                                  return GestureDetector(
                                    onTap: () {
                                      final idObjeto = int.tryParse(
                                        (objeto['id'] ??
                                                objeto['id_objeto'] ??
                                                '')
                                            .toString(),
                                      );

                                      if (idObjeto == null) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ObjetoDetailPage(
                                            idObjeto: idObjeto,
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
                                          const SizedBox(height: 8),
                                          Chip(
                                            label: Text(
                                              estado,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            backgroundColor:
                                                _estadoChipColor(estado),
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
                                          if (puedeOcultar) ...[
                                            const SizedBox(height: 14),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _ocultarPublicacion(objeto),
                                                icon: const Icon(
                                                  Icons.visibility_off_outlined,
                                                ),
                                                label: const Text(
                                                  'Ocultar publicación',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.orange,
                                                  side: const BorderSide(
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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