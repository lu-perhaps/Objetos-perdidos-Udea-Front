import 'dart:ui';
import 'package:flutter/material.dart';

import '../main.dart';
import '../Repositories/notificacion_repository.dart';

import 'registro_objeto_page.dart';
import 'solicitudes_admin_page.dart';
import 'objetos_admin_page.dart';
import 'objetos_list_page.dart';
import 'reportes_admin_page.dart';
import 'objetos_vencidos_page.dart';
import 'directorio_personas_page.dart';
import 'notificaciones_page.dart';
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

  int _notificacionesNoLeidas = 0;

  static const int _numOpciones = 8;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnims = List.generate(_numOpciones, (i) {
      final start = i * 0.07;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_numOpciones, (i) {
      final start = i * 0.07;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _animCtrl.forward();
    _cargarNotificacionesNoLeidas();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarNotificacionesNoLeidas() async {
    final user = supabase.auth.currentUser;

    if (user == null || user.email == null) return;

    final total = await NotificacionRepository.contarNoLeidas(
      correo: user.email!.toLowerCase().trim(),
    );

    if (mounted) {
      setState(() => _notificacionesNoLeidas = total);
    }
  }

  Future<void> _abrirNotificaciones() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificacionesPage(),
      ),
    );

    await _cargarNotificacionesNoLeidas();
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

    final nombreCapitalizado = nombre.isNotEmpty
        ? nombre[0].toUpperCase() + nombre.substring(1)
        : 'Admin';

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 760;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: const SizedBox.expand(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.56),
                  Colors.black.withOpacity(0.36),
                  const Color(0xFF0A3D24).withOpacity(0.34),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.22 : 20,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBarAdmin(
                      notificacionesNoLeidas: _notificacionesNoLeidas,
                      onNotificaciones: _abrirNotificaciones,
                      onCerrarSesion: _cerrarSesion,
                    ),
                    const SizedBox(height: 30),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hola, $nombreCapitalizado ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
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
                    const SizedBox(height: 8),
                    const Text(
                      'Gestiona objetos, solicitudes y personas del campus universitario.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (_notificacionesNoLeidas > 0) ...[
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _abrirNotificaciones,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFDC2626).withOpacity(0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFDC2626).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tienes $_notificacionesNoLeidas notificación(es) nueva(s)',
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const Text(
                      'OPCIONES DEL SISTEMA',
                      style: TextStyle(
                        color: Color(0xFF9EF0C0),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    isWide
                        ? _GridOpciones(
                            fadeAnims: _fadeAnims,
                            slideAnims: _slideAnims,
                            context: context,
                            onNotificaciones: _abrirNotificaciones,
                            notificacionesNoLeidas: _notificacionesNoLeidas,
                          )
                        : _ListaOpciones(
                            fadeAnims: _fadeAnims,
                            slideAnims: _slideAnims,
                            context: context,
                            onNotificaciones: _abrirNotificaciones,
                            notificacionesNoLeidas: _notificacionesNoLeidas,
                          ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Colors.white70,
                            size: 12,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'UdeA 2024 · Panel Seguro',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
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

class _TopBarAdmin extends StatelessWidget {
  final int notificacionesNoLeidas;
  final VoidCallback onNotificaciones;
  final VoidCallback onCerrarSesion;

  const _TopBarAdmin({
    required this.notificacionesNoLeidas,
    required this.onNotificaciones,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    final tieneNuevas = notificacionesNoLeidas > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: HeaderUdeaAdmin(
              titulo: 'Panel Administrativo',
              subtitulo: 'Objetos Perdidos',
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0A8F4D).withOpacity(0.30),
              ),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onNotificaciones,
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tieneNuevas
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tieneNuevas
                          ? const Color(0xFFDC2626).withOpacity(0.35)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Icon(
                    tieneNuevas
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_outlined,
                    color: tieneNuevas
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                    size: 18,
                  ),
                ),
                if (tieneNuevas)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notificacionesNoLeidas > 9
                            ? '9+'
                            : '$notificacionesNoLeidas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onCerrarSesion,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF6B7280),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_OpcionData> _opciones(
  BuildContext context, {
  required VoidCallback onNotificaciones,
  required int notificacionesNoLeidas,
}) =>
    [
      _OpcionData(
        icono: Icons.assignment_outlined,
        titulo: 'Solicitudes de reclamo',
        subtitulo: 'Aprobar, rechazar o entregar objetos',
        color: const Color(0xFF0A8F4D),
        bgColor: const Color(0xFFE1F5EE),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SolicitudesAdminPage()),
        ),
      ),
      _OpcionData(
        icono: notificacionesNoLeidas > 0
            ? Icons.notifications_active_rounded
            : Icons.notifications_outlined,
        titulo: 'Notificaciones',
        subtitulo: notificacionesNoLeidas > 0
            ? '$notificacionesNoLeidas nueva(s) por revisar'
            : 'Alertas del sistema',
        color: notificacionesNoLeidas > 0
            ? const Color(0xFFDC2626)
            : const Color(0xFF0891B2),
        bgColor: notificacionesNoLeidas > 0
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFE0F2FE),
        onTap: onNotificaciones,
      ),
      _OpcionData(
        icono: Icons.add_box_outlined,
        titulo: 'Registrar objeto',
        subtitulo: 'Agregar nuevo objeto encontrado',
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFDBEAFE),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegistroObjetoPage()),
        ),
      ),
      _OpcionData(
        icono: Icons.inventory_2_outlined,
        titulo: 'Objetos publicados',
        subtitulo: 'Ver objetos disponibles en el sistema',
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFEDE9FE),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ObjetosListPage()),
        ),
      ),
      _OpcionData(
        icono: Icons.inventory_outlined,
        titulo: 'Inventario completo',
        subtitulo: 'Ver todos los objetos guardados',
        color: const Color(0xFF0A8F4D),
        bgColor: const Color(0xFFE1F5EE),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ObjetosAdminPage()),
        ),
      ),
      _OpcionData(
        icono: Icons.people_outline,
        titulo: 'Directorio estudiantes',
        subtitulo: 'Buscar y ver info de estudiantes',
        color: const Color(0xFFD97706),
        bgColor: const Color(0xFFFEF3C7),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DirectorioPersonasPage()),
        ),
      ),
      _OpcionData(
        icono: Icons.hourglass_disabled_outlined,
        titulo: 'Objetos vencidos',
        subtitulo: 'Gestionar disposición final',
        color: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEE2E2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ObjetosVencidosPage()),
        ),
      ),
      _OpcionData(
        icono: Icons.search_off_outlined,
        titulo: 'Reportes de pérdida',
        subtitulo: 'Ver reportes de estudiantes',
        color: const Color(0xFF0891B2),
        bgColor: const Color(0xFFE0F2FE),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportesAdminPage()),
        ),
      ),
    ];

class _OpcionData {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _OpcionData({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}

class _ListaOpciones extends StatelessWidget {
  final List<Animation<double>> fadeAnims;
  final List<Animation<Offset>> slideAnims;
  final BuildContext context;
  final VoidCallback onNotificaciones;
  final int notificacionesNoLeidas;

  const _ListaOpciones({
    required this.fadeAnims,
    required this.slideAnims,
    required this.context,
    required this.onNotificaciones,
    required this.notificacionesNoLeidas,
  });

  @override
  Widget build(BuildContext ctx) {
    final ops = _opciones(
      context,
      onNotificaciones: onNotificaciones,
      notificacionesNoLeidas: notificacionesNoLeidas,
    );

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

class _GridOpciones extends StatelessWidget {
  final List<Animation<double>> fadeAnims;
  final List<Animation<Offset>> slideAnims;
  final BuildContext context;
  final VoidCallback onNotificaciones;
  final int notificacionesNoLeidas;

  const _GridOpciones({
    required this.fadeAnims,
    required this.slideAnims,
    required this.context,
    required this.onNotificaciones,
    required this.notificacionesNoLeidas,
  });

  @override
  Widget build(BuildContext ctx) {
    final ops = _opciones(
      context,
      onNotificaciones: onNotificaciones,
      notificacionesNoLeidas: notificacionesNoLeidas,
    );

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
        scale: _presionado ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.data.color.withOpacity(0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.data.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.data.icono,
                  color: widget.data.color,
                  size: 22,
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
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.subtitulo,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.data.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.data.color,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}