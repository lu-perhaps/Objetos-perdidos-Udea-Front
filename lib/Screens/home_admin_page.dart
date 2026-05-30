import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import 'solicitudes_admin_page.dart';
import 'registro_objeto_page.dart';
import 'objetos_list_page.dart';
import 'reportes_admin_page.dart';
import 'objetos_vencidos_page.dart';
import 'directorio_personas_page.dart';
import 'header_udea.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const int _numOpciones = 6;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnims = List.generate(_numOpciones, (i) {
      final start = i * 0.1;
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, start + 0.5, curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(_numOpciones, (i) {
      final start = i * 0.1;
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, start + 0.5, curve: Curves.easeOut),
      ));
    });
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';
    final nombre =
        email.isNotEmpty ? email.split('@').first.split('.').first : 'Admin';
    final nombreCapitalizado =
        nombre.isNotEmpty ? nombre[0].toUpperCase() + nombre.substring(1) : 'Admin';

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo UdeA ─────────────────────────────────────────────
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),

          // ── Overlay gradiente ───────────────────────────────────────
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

          // ── Blur ────────────────────────────────────────────────────
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),

          // ── Contenido ───────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.22 : 22,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top bar ────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(child: HeaderUdea(titulo: 'Panel Administrativo')),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A8F4D).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0A8F4D).withOpacity(0.4),
                            ),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Color(0xFF0A8F4D),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _cerrarSesion,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Saludo ─────────────────────────────────────
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hola, $nombreCapitalizado ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const TextSpan(
                            text: '👋',
                            style: TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gestiona objetos, solicitudes y personas\ndel campus universitario.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Label sección ──────────────────────────────
                    const Text(
                      'OPCIONES DEL SISTEMA',
                      style: TextStyle(
                        color: Color(0xFF0A8F4D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Grid 2 columnas en web, lista en móvil ─────
                    isWide
                        ? _GridOpciones(
                            fadeAnims: _fadeAnims,
                            slideAnims: _slideAnims,
                            context: context,
                          )
                        : _ListaOpciones(
                            fadeAnims: _fadeAnims,
                            slideAnims: _slideAnims,
                            context: context,
                          ),

                    const SizedBox(height: 40),

                    // ── Footer ─────────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              color: Colors.white24, size: 12),
                          const SizedBox(width: 6),
                          const Text(
                            'UdeA 2024 · Panel Seguro',
                            style: TextStyle(
                                color: Colors.white24, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Datos de opciones ─────────────────────────────────────────────────────────
List<_OpcionData> _opciones(BuildContext context) => [
      _OpcionData(
        icono: Icons.assignment_outlined,
        titulo: 'Solicitudes de reclamo',
        subtitulo: 'Aprobar o rechazar solicitudes',
        color: const Color(0xFF0A8F4D),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SolicitudesAdminPage())),
      ),
      _OpcionData(
        icono: Icons.add_box_outlined,
        titulo: 'Registrar objeto',
        subtitulo: 'Agregar nuevo objeto encontrado',
        color: const Color(0xFF3A7BD5),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RegistroObjetoPage())),
      ),
      _OpcionData(
        icono: Icons.inventory_2_outlined,
        titulo: 'Objetos publicados',
        subtitulo: 'Ver objetos disponibles en el sistema',
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ObjetosListPage())),
      ),
      _OpcionData(
        icono: Icons.people_outline,
        titulo: 'Directorio estudiantes',
        subtitulo: 'Buscar y ver info de estudiantes',
        color: const Color(0xFFE07B2A),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const DirectorioPersonasPage())),
      ),
      _OpcionData(
        icono: Icons.hourglass_disabled_outlined,
        titulo: 'Objetos vencidos',
        subtitulo: 'Gestionar disposición final',
        color: const Color(0xFFDC2626),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ObjetosVencidosPage())),
      ),
      _OpcionData(
        icono: Icons.search_off_outlined,
        titulo: 'Reportes de pérdida',
        subtitulo: 'Ver reportes de estudiantes',
        color: const Color(0xFF0891B2),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ReportesAdminPage())),
      ),
    ];

class _OpcionData {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  const _OpcionData({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });
}

// ── Lista vertical (móvil) ────────────────────────────────────────────────────
class _ListaOpciones extends StatelessWidget {
  final List<Animation<double>> fadeAnims;
  final List<Animation<Offset>> slideAnims;
  final BuildContext context;

  const _ListaOpciones({
    required this.fadeAnims,
    required this.slideAnims,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final ops = _opciones(context);
    return Column(
      children: List.generate(ops.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FadeTransition(
            opacity: fadeAnims[i],
            child: SlideTransition(
              position: slideAnims[i],
              child: _TarjetaAdmin(data: ops[i]),
            ),
          ),
        );
      }),
    );
  }
}

// ── Grid 2 columnas (web) ─────────────────────────────────────────────────────
class _GridOpciones extends StatelessWidget {
  final List<Animation<double>> fadeAnims;
  final List<Animation<Offset>> slideAnims;
  final BuildContext context;

  const _GridOpciones({
    required this.fadeAnims,
    required this.slideAnims,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final ops = _opciones(context);
    final rows = (ops.length / 2).ceil();
    return Column(
      children: List.generate(rows, (row) {
        final i1 = row * 2;
        final i2 = i1 + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: fadeAnims[i1],
                  child: SlideTransition(
                    position: slideAnims[i1],
                    child: _TarjetaAdmin(data: ops[i1]),
                  ),
                ),
              ),
              if (i2 < ops.length) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FadeTransition(
                    opacity: fadeAnims[i2],
                    child: SlideTransition(
                      position: slideAnims[i2],
                      child: _TarjetaAdmin(data: ops[i2]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

// ── Tarjeta admin ─────────────────────────────────────────────────────────────
class _TarjetaAdmin extends StatefulWidget {
  final _OpcionData data;
  const _TarjetaAdmin({required this.data});

  @override
  State<_TarjetaAdmin> createState() => _TarjetaAdminState();
}

class _TarjetaAdminState extends State<_TarjetaAdmin> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) => setState(() => _presionado = false),
      onTapCancel: () => setState(() => _presionado = false),
      onTap: widget.data.onTap,
      child: AnimatedScale(
        scale: _presionado ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.data.color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.data.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.data.color.withOpacity(0.25),
                      ),
                    ),
                    child: Icon(
                      widget.data.icono,
                      color: widget.data.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.data.subtitulo,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.data.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: widget.data.color,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}