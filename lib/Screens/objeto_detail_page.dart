import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../Repositories/objeto_repository.dart';
import 'solicitud_reclamo_page.dart';
import 'header_udea.dart';

class ObjetoDetailPage extends StatefulWidget {
  final int idObjeto;

  const ObjetoDetailPage({super.key, required this.idObjeto});

  @override
  State<ObjetoDetailPage> createState() => _ObjetoDetailPageState();
}

class _ObjetoDetailPageState extends State<ObjetoDetailPage> {
  bool _esAdmin = false;
  Map<String, dynamic>? _objeto;
  bool _cargandoObjeto = true;

  @override
  void initState() {
    super.initState();
    _verificarRol();
    _cargarObjeto();
  }

  Future<void> _cargarObjeto() async {
    setState(() => _cargandoObjeto = true);
    final data = await ObjetoRepository.obtenerObjetoPorId(widget.idObjeto);
    if (!mounted) return;
    setState(() {
      _objeto = data;
      _cargandoObjeto = false;
    });
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error cargando detalle del objeto')),
      );
    }
  }

  Future<void> _verificarRol() async {
    final admin = await AuthService.esAdmin();
    if (mounted) setState(() => _esAdmin = admin);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoObjeto) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final objeto = _objeto ?? {};
    final categoria = (
      objeto['categoria'] ??
      objeto['tbl_categoria']?['nombre'] ??
      'Objeto encontrado'
    ).toString();
    final descripcionGeneral = (
      objeto['descripcionGeneral'] ??
      objeto['descripcion_general'] ??
      'Sin descripción'
    ).toString();
    final descripcionDetallada = (
      objeto['descripcionDetallada'] ??
      objeto['descripcion_detallada'] ??
      ''
    ).toString();
    final fechaHallazgo = (
      objeto['fechaHallazgo'] ??
      objeto['fecha_hallazgo'] ??
      ''
    ).toString();
    final lugarEncontrado = (
      objeto['lugarEncontrado'] ??
      objeto['lugar_encontrado'] ??
      objeto['lugarEncontradoNombre'] ??
      'No registrado'
    ).toString();
    final lugarActual = (
      objeto['lugarActual'] ??
      objeto['lugar_actual'] ??
      objeto['lugarActualNombre'] ??
      'No registrado'
    ).toString();
    final fotoUrl = (objeto['fotografia'] ?? objeto['fotografiaUrl'] ?? '').toString();
    final nombre = (objeto['nombre'] ?? 'Sin nombre').toString();

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo ────────────────────────────────────────────────
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

          // ── Contenido ────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
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
                      const Expanded(child: HeaderUdea(titulo: 'Detalle del objeto')),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Badge categoría
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A8F4D).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0A8F4D).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      categoria,
                      style: const TextStyle(
                        color: Color(0xFF0A8F4D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Imagen ──────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF0A8F4D).withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: fotoUrl.isNotEmpty
                          ? Image.network(
                              fotoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const _SinImagen(),
                            )
                          : const _SinImagen(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Nombre ──────────────────────────────────────
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Tarjeta info general ─────────────────────────
                  _TarjetaInfo(
                    titulo: 'INFORMACIÓN GENERAL',
                    icono: Icons.info_outline_rounded,
                    color: const Color(0xFF0A8F4D),
                    children: [
                      _FilaInfo(
                        icono: Icons.category_outlined,
                        label: 'Tipo de objeto',
                        valor: categoria,
                      ),
                      _FilaInfo(
                        icono: Icons.description_outlined,
                        label: 'Descripción',
                        valor: descripcionGeneral,
                      ),
                      _FilaInfo(
                        icono: Icons.location_on_outlined,
                        label: 'Lugar encontrado',
                        valor: lugarEncontrado,
                      ),
                      _FilaInfo(
                        icono: Icons.place_outlined,
                        label: 'Ubicación actual',
                        valor: lugarActual,
                      ),
                      _FilaInfo(
                        icono: Icons.calendar_today_outlined,
                        label: 'Fecha del hallazgo',
                        valor: fechaHallazgo,
                      ),
                    ],
                  ),

                  // ── Info privada (solo admin) ─────────────────────
                  if (_esAdmin) ...[
                    const SizedBox(height: 16),
                    _TarjetaInfo(
                      titulo: 'INFORMACIÓN PRIVADA',
                      icono: Icons.lock_outline_rounded,
                      color: Colors.orange,
                      children: [
                        _FilaInfo(
                          icono: Icons.notes_rounded,
                          label: 'Descripción detallada',
                          valor: descripcionDetallada.isEmpty
                              ? 'No registrada'
                              : descripcionDetallada,
                        ),
                      ],
                    ),
                  ],

                  // ── Sección reclamar (usuario normal) ─────────────
                  if (!_esAdmin) ...[
                    const SizedBox(height: 28),
                    const Text(
                      '¿ES TUYO ESTE OBJETO?',
                      style: TextStyle(
                        color: Color(0xFF0A8F4D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  const Color(0xFF0A8F4D).withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Si reconoces este objeto como tuyo, inicia una solicitud de reclamo. Deberás proporcionar detalles que verifiquen tu propiedad.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SolicitudReclamoPage(
                                          objeto: objeto),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.handshake_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'RECLAMAR ESTE OBJETO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0A8F4D),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Footer ───────────────────────────────────────
                  Center(
                    child: Text(
                      'UdeA 2024 · Objetos Perdidos',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.2), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de información ────────────────────────────────────────────────────
class _TarjetaInfo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<Widget> children;

  const _TarjetaInfo({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fila de info ─────────────────────────────────────────────────────────────
class _FilaInfo extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _FilaInfo({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: Colors.white38, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label\n',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: valor,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
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

// ── Sin imagen ────────────────────────────────────────────────────────────────
class _SinImagen extends StatelessWidget {
  const _SinImagen();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined,
            size: 48, color: Colors.white.withOpacity(0.25)),
        const SizedBox(height: 8),
        Text(
          'Sin fotografía',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3), fontSize: 13),
        ),
      ],
    );
  }
}

// ── Botón volver ──────────────────────────────────────────────────────────────
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
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}