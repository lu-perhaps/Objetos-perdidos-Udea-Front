import 'dart:ui';
import 'package:flutter/material.dart';

import '../main.dart';
import '../Repositories/notificacion_repository.dart';
import '../Repositories/persona_repository.dart';
import 'objetos_list_page.dart';
import 'reporte_perdida_page.dart';
import 'notificaciones_page.dart';
import 'mis_reportes_page.dart';
import 'mis_solicitudes_page.dart';
import 'header_udea.dart';

class HomeUsuarioPage extends StatefulWidget {
  const HomeUsuarioPage({super.key});

  @override
  State<HomeUsuarioPage> createState() => _HomeUsuarioPageState();
}

class _HomeUsuarioPageState extends State<HomeUsuarioPage>
    with SingleTickerProviderStateMixin {
  int _notificacionesNoLeidas = 0;
  bool _cargandoNotificaciones = false;
  String _nombre = 'Usuario';

  late AnimationController _animCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const int _numCards = 4;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(_numCards, (i) {
      final start = i * 0.13;
      final end = (start + 0.60).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_numCards, (i) {
      final start = i * 0.13;
      final end = (start + 0.60).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.10),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _animCtrl.forward();
    _cargarContadorNotificaciones();
    _cargarNombre();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarContadorNotificaciones() async {
    final user = supabase.auth.currentUser;

    if (mounted) {
      setState(() {
        _cargandoNotificaciones = true;
        _notificacionesNoLeidas = 0;
      });
    }

    if (user == null || user.email == null) {
      if (mounted) {
        setState(() {
          _notificacionesNoLeidas = 0;
          _cargandoNotificaciones = false;
        });
      }
      return;
    }

    final count = await NotificacionRepository.contarNoLeidas(
      correo: user.email!.toLowerCase().trim(),
    );

    if (mounted) {
      setState(() {
        _notificacionesNoLeidas = count;
        _cargandoNotificaciones = false;
      });
    }
  }

  Future<void> _cargarNombre() async {
    final persona = await PersonaRepository.obtenerPersonaActual();

    if (persona != null && persona.nombre.isNotEmpty) {
      if (mounted) {
        setState(() => _nombre = persona.nombre.split(' ').first);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_cargandoNotificaciones) {}

    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/udea_bg.jpeg',
            fit: BoxFit.cover,
          ),
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
                  Colors.black.withOpacity(0.58),
                  Colors.black.withOpacity(0.38),
                  const Color(0xFF0A3D24).withOpacity(0.35),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.25 : 22,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      noLeidas: _notificacionesNoLeidas,
                      onNotificaciones: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificacionesPage(),
                          ),
                        );
                        _cargarContadorNotificaciones();
                      },
                      onCerrarSesion: _cerrarSesion,
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _fadeAnims[0],
                      child: SlideTransition(
                        position: _slideAnims[0],
                        child: _Saludo(nombre: _nombre),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _fadeAnims[0],
                      child: const Text(
                        'QUÉ QUIERES HACER',
                        style: TextStyle(
                          color: Color(0xFF9EF0C0),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[0],
                      child: SlideTransition(
                        position: _slideAnims[0],
                        child: _TarjetaAccion(
                          icono: Icons.search_rounded,
                          titulo: 'Buscar objeto perdido',
                          subtitulo: 'Revisa los objetos encontrados en campus',
                          colorIcono: const Color(0xFF0A8F4D),
                          bgIcono: const Color(0xFFE1F5EE),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ObjetosListPage(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[1],
                      child: SlideTransition(
                        position: _slideAnims[1],
                        child: _TarjetaAccion(
                          icono: Icons.report_gmailerrorred_rounded,
                          titulo: 'Reportar pérdida',
                          subtitulo: 'Registra algo que hayas perdido en UdeA',
                          colorIcono: const Color(0xFFD97706),
                          bgIcono: const Color(0xFFFEF3C7),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportePerdidaPage(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[2],
                      child: SlideTransition(
                        position: _slideAnims[2],
                        child: _TarjetaAccion(
                          icono: Icons.assignment_outlined,
                          titulo: 'Mis solicitudes',
                          subtitulo: 'Consulta el estado de tus reclamos',
                          colorIcono: const Color(0xFF2563EB),
                          bgIcono: const Color(0xFFDBEAFE),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MisSolicitudesPage(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _fadeAnims[3],
                      child: SlideTransition(
                        position: _slideAnims[3],
                        child: _TarjetaAccion(
                          icono: Icons.article_outlined,
                          titulo: 'Mis reportes',
                          subtitulo: 'Revisa y anula tus reportes activos',
                          colorIcono: const Color(0xFF7C3AED),
                          bgIcono: const Color(0xFFEDE9FE),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MisReportesPage(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
                            'UdeA 2024 · Acceso seguro',
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

class _TopBar extends StatelessWidget {
  final int noLeidas;
  final VoidCallback onNotificaciones;
  final VoidCallback onCerrarSesion;

  const _TopBar({
    required this.noLeidas,
    required this.onNotificaciones,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: HeaderUdea(
            titulo: 'Objetos Perdidos',
            oscuro: true,
          ),
        ),
        const SizedBox(width: 16),
        Stack(
          children: [
            _BtnIcono(
              icono: Icons.notifications_outlined,
              onTap: onNotificaciones,
              tooltip: 'Notificaciones',
            ),
            if (noLeidas > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      noLeidas > 99 ? '99+' : '$noLeidas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        _BtnIcono(
          icono: Icons.logout_rounded,
          onTap: onCerrarSesion,
          tooltip: 'Cerrar sesión',
        ),
      ],
    );
  }
}

class _Saludo extends StatelessWidget {
  final String nombre;

  const _Saludo({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hola, $nombre ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const TextSpan(
                text: '👋',
                style: TextStyle(fontSize: 26),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Busca, reporta o entrega objetos perdidos en el campus.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TarjetaAccion extends StatefulWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color colorIcono;
  final Color bgIcono;
  final VoidCallback onTap;

  const _TarjetaAccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.colorIcono,
    required this.bgIcono,
    required this.onTap,
  });

  @override
  State<_TarjetaAccion> createState() => _TarjetaAccionState();
}

class _TarjetaAccionState extends State<_TarjetaAccion> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _presionado = true),
      onTapUp: (_) => setState(() => _presionado = false),
      onTapCancel: () => setState(() => _presionado = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _presionado ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.colorIcono.withOpacity(0.22),
              width: 1.2,
            ),
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.bgIcono,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.colorIcono.withOpacity(0.20),
                  ),
                ),
                child: Icon(
                  widget.icono,
                  color: widget.colorIcono,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.titulo,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitulo,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.bgIcono,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.colorIcono,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BtnIcono extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  final String tooltip;

  const _BtnIcono({
    required this.icono,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icono,
            color: const Color(0xFF111827),
            size: 20,
          ),
        ),
      ),
    );
  }
}