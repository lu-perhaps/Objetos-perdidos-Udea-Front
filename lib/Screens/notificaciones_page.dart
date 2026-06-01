import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../Repositories/notificacion_repository.dart';
import '../main.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _cargarNotificaciones();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarNotificaciones() async {
    final user = supabase.auth.currentUser;
    if (user == null || user.email == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }

    final data = await NotificacionRepository.obtenerNotificaciones(
      correo: user.email!.toLowerCase().trim(),
    );

    if (mounted) {
      setState(() {
        _notificaciones = data;
        _cargando = false;
      });
    }
  }

  Future<void> _marcarComoLeidaYRecargar(int idNotificacion) async {
    await NotificacionRepository.marcarComoLeida(
      idNotificacion: idNotificacion,
    );
    await _cargarNotificaciones();
  }

  Future<void> _eliminarNotificacion(int idNotificacion) async {
    final success =
        await NotificacionRepository.eliminarNotificacion(idNotificacion);
    if (success && mounted) {
      await _cargarNotificaciones();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación eliminada')),
      );
    }
  }

  Future<void> _borrarTodas() async {
    final user = supabase.auth.currentUser;
    if (user == null || user.email == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todas las notificaciones?'),
        content: const Text(
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final success = await NotificacionRepository.eliminarTodas(
      user.email!.toLowerCase().trim(),
    );

    if (success && mounted) {
      await _cargarNotificaciones();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas las notificaciones eliminadas')),
      );
    }
  }

  String _formatearFecha(String? fechaStr) {
    if (fechaStr == null) return '';
    final fecha = DateTime.tryParse(fechaStr);
    if (fecha == null) return '';
    final local = fecha.toLocal();
    final meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${local.day} ${meses[local.month]} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo ──────────────────────────────────────────────────
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xBB000000), Color(0xEE011208)],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),

          // ── Contenido ───────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.22 : 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // ── Header ─────────────────────────────────────
                      _HeaderPage(titulo: 'Notificaciones'),

                      const SizedBox(height: 20),

                      // ── Contador y botón borrar todas ──────────────
                      if (!_cargando && _notificaciones.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.verde.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.verde.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${_notificaciones.length} notificaciones',
                                  style: const TextStyle(
                                    color: AppColors.verde,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _borrarTodas,
                              icon: const Icon(
                                Icons.delete_sweep_outlined,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: 'Borrar todas',
                            ),
                          ],
                        ),

                      if (!_cargando && _notificaciones.isNotEmpty)
                        const SizedBox(height: 14),

                      // ── Lista ───────────────────────────────────────
                      Expanded(child: _buildContenido()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.verde,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_notificaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                color: Colors.white24,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin notificaciones',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aquí aparecerán tus alertas\nsobre objetos y solicitudes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white30, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _notificaciones.length,
      itemBuilder: (_, i) {
        final n = _notificaciones[i];
        final leida = n['leida'] == true;
        return _TarjetaNotificacion(
          notificacion: n,
          leida: leida,
          fecha: _formatearFecha(n['fechaEnvio']),
          onTap: leida
              ? null
              : () => _marcarComoLeidaYRecargar(n['id']),
          onDelete: () => _eliminarNotificacion(n['id']),
        );
      },
    );
  }
}

// ── Tarjeta notificación ──────────────────────────────────────────────────────
class _TarjetaNotificacion extends StatelessWidget {
  final Map<String, dynamic> notificacion;
  final bool leida;
  final String fecha;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TarjetaNotificacion({
    required this.notificacion,
    required this.leida,
    required this.fecha,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color colorAccent =
        leida ? Colors.white24 : AppColors.verde;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: leida
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.verde.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorAccent.withOpacity(leida ? 0.15 : 0.35),
                  width: leida ? 1 : 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ícono ─────────────────────────────────────────
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorAccent.withOpacity(0.25),
                      ),
                    ),
                    child: Icon(
                      leida
                          ? Icons.notifications_outlined
                          : Icons.notifications_active_rounded,
                      color: colorAccent,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ── Texto y acciones ──────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notificacion['mensaje'] ?? 'Sin mensaje',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: leida
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (!leida)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.verde,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Nueva',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fecha,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            GestureDetector(
                              onTap: onDelete,
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
                                size: 18,
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
        ),
      ),
    );
  }
}

// ── Header reutilizable ───────────────────────────────────────────────────────
class _HeaderPage extends StatelessWidget {
  final String titulo;
  final String? breadcrumb;

  const _HeaderPage({required this.titulo, this.breadcrumb});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (breadcrumb != null)
              Text(
                breadcrumb!,
                style: const TextStyle(
                  color: Color(0xFF0A8F4D),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}