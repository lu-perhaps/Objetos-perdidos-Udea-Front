// ═══════════════════════════════════════════════════════════════════
// objetos_vencidos_page.dart  —  UI mejorada
// ═══════════════════════════════════════════════════════════════════
import 'dart:ui';
import 'package:flutter/material.dart';
import '../Constants/app_colors.dart';
import '../Constants/estados.dart';
import '../Repositories/objeto_repository.dart';
import 'header_udea.dart';

class ObjetosVencidosPage extends StatefulWidget {
  const ObjetosVencidosPage({super.key});

  @override
  State<ObjetosVencidosPage> createState() => _ObjetosVencidosPageState();
}

class _ObjetosVencidosPageState extends State<ObjetosVencidosPage> {
  List<Map<String, dynamic>> _objetos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVencidos();
  }

  Future<void> _cargarVencidos() async {
    final data = await ObjetoRepository.obtenerObjetosVencidos();
    if (mounted) {
      setState(() {
        _objetos = data;
        _cargando = false;
      });
    }
  }

  int _diasAlmacenado(String? fechaStr) {
    if (fechaStr == null) return 0;
    final fecha = DateTime.tryParse(fechaStr);
    if (fecha == null) return 0;
    return DateTime.now().difference(fecha).inDays;
  }

  int _tiempoMax(Map<String, dynamic> obj) =>
      obj['tiempoMaximoAlmacenamiento'] as int? ??
      obj['tiempo_maximo_almacenamiento'] as int? ??
      obj['tbl_categoria']?['tiempo_maximo_almacenamiento'] as int? ??
      0;

  Future<void> _mostrarDialogoDisposicion(
      Map<String, dynamic> obj, int nuevoEstado) async {
    final esDonacion = nuevoEstado == Estados.objetoDonado;
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              esDonacion
                  ? Icons.volunteer_activism
                  : Icons.delete_outline,
              color: esDonacion ? Colors.purple : Colors.red,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              esDonacion ? 'Marcar como donado' : 'Marcar como desecho',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objeto: ${obj['nombre']}',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              esDonacion
                  ? 'El objeto será marcado como donado y dejará de estar disponible.'
                  : 'El objeto será marcado como desecho y dejará de estar disponible.',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: esDonacion ? Colors.purple : Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              esDonacion ? 'Confirmar donación' : 'Confirmar desecho',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final exito = await ObjetoRepository.registrarDisposicionFinal(
      idObjeto: obj['id'] as int,
      nuevoEstado: nuevoEstado,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(exito
            ? (esDonacion
                ? 'Objeto marcado como donado'
                : 'Objeto marcado como desecho')
            : 'Error al actualizar el objeto'),
        backgroundColor: exito
            ? (esDonacion ? Colors.purple : Colors.red)
            : Colors.red,
      ),
    );
    if (exito) await _cargarVencidos();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBB000000),
                  Color(0xCC021008),
                  Color(0xEE011208),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? size.width * 0.18 : 20,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  Row(
                    children: [
                      _BotonVolver(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UNIVERSIDAD DE ANTIOQUIA',
                              style: TextStyle(
                                color: Color(0xFF0A8F4D),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Objetos vencidos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge naranja
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'VENCIDOS',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Objetos que superaron su tiempo máximo de almacenamiento.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Lista ────────────────────────────────────────
                  Expanded(
                    child: _cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0A8F4D),
                              strokeWidth: 2,
                            ),
                          )
                        : _objetos.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A8F4D)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF0A8F4D),
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Sin objetos vencidos',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Todos los objetos están dentro del tiempo permitido.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _objetos.length,
                                itemBuilder: (_, i) {
                                  final obj = _objetos[i];
                                  final dias = _diasAlmacenado(
                                    (obj['fechaHallazgo'] ?? obj['fecha_hallazgo'])?.toString(),
                                  );
                                  final tiempoMax = _tiempoMax(obj);
                                  final diasVencido = dias - tiempoMax;
                                  final fotoUrl =
                                      (obj['fotografia'] ?? '').toString();

                                  return _TarjetaVencido(
                                    obj: obj,
                                    fotoUrl: fotoUrl,
                                    dias: dias,
                                    tiempoMax: tiempoMax,
                                    diasVencido: diasVencido,
                                    onDonar: () => _mostrarDialogoDisposicion(
                                        obj, Estados.objetoDonado),
                                    onDesechar: () =>
                                        _mostrarDialogoDisposicion(
                                            obj, Estados.objetoDesecho),
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

class _TarjetaVencido extends StatelessWidget {
  final Map<String, dynamic> obj;
  final String fotoUrl;
  final int dias;
  final int tiempoMax;
  final int diasVencido;
  final VoidCallback onDonar;
  final VoidCallback onDesechar;

  const _TarjetaVencido({
    required this.obj,
    required this.fotoUrl,
    required this.dias,
    required this.tiempoMax,
    required this.diasVencido,
    required this.onDonar,
    required this.onDesechar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.35), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              if (fotoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    fotoUrl,
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            obj['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Text(
                            '+$diasVencido días',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Info
                    _InfoChip(
                      icono: Icons.category_outlined,
                      texto: (obj['categoria'] ??
                              obj['tbl_categoria']?['nombre'] ??
                              'Sin categoría')
                          .toString(),
                    ),
                    const SizedBox(height: 4),
                    _InfoChip(
                      icono: Icons.timer_outlined,
                      texto:
                          'Límite: $tiempoMax días · Almacenado: $dias días',
                    ),
                    _InfoChip(
                      icono: Icons.location_on_outlined,
                      texto: (obj['lugarActual'] ??
                              obj['lugar_actual']?['nombre'] ??
                              'Sin lugar')
                          .toString(),
                    ),

                    const SizedBox(height: 14),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: _BotonAccion(
                            icono: Icons.volunteer_activism,
                            texto: 'Donar',
                            color: Colors.purple,
                            onTap: onDonar,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BotonAccion(
                            icono: Icons.delete_outline_rounded,
                            texto: 'Desechar',
                            color: Colors.red,
                            onTap: onDesechar,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _InfoChip({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icono, color: Colors.white38, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icono, color: Colors.white, size: 16),
      label:
          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.85),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}

class _BotonVolver extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonVolver({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: Colors.white70, size: 18),
      ),
    );
  }
}