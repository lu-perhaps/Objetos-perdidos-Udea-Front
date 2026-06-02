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
    ).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );

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

  Future<void> _refrescar() async {
    setState(() => _cargando = true);
    await _cargarNotificaciones();
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
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
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
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${local.day} ${meses[local.month]} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  int get _noLeidas {
    return _notificaciones.where((n) => n['leida'] != true).length;
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 560 : 520,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 22,
                        vertical: 18,
                      ),
                      child: Column(
                        children: [
                          _HeaderPage(
                            titulo: 'Notificaciones',
                            subtitulo: 'Alertas sobre tus objetos y reportes',
                            total: _notificaciones.length,
                            noLeidas: _noLeidas,
                            onRefresh: _refrescar,
                            onDeleteAll:
                                _notificaciones.isEmpty ? null : _borrarTodas,
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: RefreshIndicator(
                              color: AppColors.verde,
                              onRefresh: _refrescar,
                              child: _buildContenido(),
                            ),
                          ),
                        ],
                      ),
                    ),
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
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          _EstadoVacio(),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _notificaciones.length,
      itemBuilder: (_, i) {
        final n = _notificaciones[i];
        final leida = n['leida'] == true;

        final idNotificacion = int.tryParse(
          n['id']?.toString() ?? '',
        );

        return _TarjetaNotificacion(
          notificacion: n,
          leida: leida,
          fecha: _formatearFecha(n['fechaEnvio']),
          onTap: leida || idNotificacion == null
              ? null
              : () => _marcarComoLeidaYRecargar(idNotificacion),
          onDelete: idNotificacion == null
              ? null
              : () => _eliminarNotificacion(idNotificacion),
        );
      },
    );
  }
}

class _HeaderPage extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int total;
  final int noLeidas;
  final Future<void> Function() onRefresh;
  final VoidCallback? onDeleteAll;

  const _HeaderPage({
    required this.titulo,
    required this.subtitulo,
    required this.total,
    required this.noLeidas,
    required this.onRefresh,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _HeaderButton(
            icono: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OBJETOS PERDIDOS',
                  style: TextStyle(
                    color: Color(0xFF0A8F4D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (total > 0) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: noLeidas > 0
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: noLeidas > 0
                      ? const Color(0xFFDC2626).withOpacity(0.22)
                      : const Color(0xFF0A8F4D).withOpacity(0.22),
                ),
              ),
              child: Text(
                noLeidas > 0 ? '$noLeidas nueva(s)' : '$total',
                style: TextStyle(
                  color: noLeidas > 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF065F46),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          _HeaderButton(
            icono: Icons.refresh_rounded,
            onTap: () async => onRefresh(),
          ),
          if (onDeleteAll != null) ...[
            const SizedBox(width: 8),
            _HeaderButton(
              icono: Icons.delete_sweep_outlined,
              color: const Color(0xFFDC2626),
              onTap: onDeleteAll!,
            ),
          ],
        ],
      ),
    );
  }
}

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
    final Color colorAccent = leida ? const Color(0xFF6B7280) : AppColors.verde;

    final mensaje = (notificacion['mensaje'] ?? 'Sin mensaje').toString();

    final mensajeAdicional = (notificacion['mensajeAdicional'] ??
            notificacion['mensaje_adicional'] ??
            '')
        .toString()
        .trim();

    return GestureDetector(
      onTap: onTap,
      child: _WhiteCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        borderColor: colorAccent.withOpacity(leida ? 0.16 : 0.28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: colorAccent.withOpacity(0.25),
                ),
              ),
              child: Icon(
                leida
                    ? Icons.notifications_outlined
                    : Icons.notifications_active_rounded,
                color: colorAccent,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!leida) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verde.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.verde.withOpacity(0.22),
                            ),
                          ),
                          child: const Text(
                            'Nueva',
                            style: TextStyle(
                              color: AppColors.verde,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          fecha,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mensaje,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: leida ? FontWeight.w700 : FontWeight.w900,
                      height: 1.4,
                    ),
                  ),
                  if (mensajeAdicional.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.verde.withOpacity(0.20),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.message_outlined,
                            color: AppColors.verde,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mensajeAdicional,
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (!leida)
                        const Text(
                          'Toca para marcar como leída',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const Spacer(),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7280),
                            size: 17,
                          ),
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
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(28),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: Color(0xFF0A8F4D),
            size: 44,
          ),
          SizedBox(height: 14),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Aquí aparecerán tus alertas sobre objetos, reportes y solicitudes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const _WhiteCard({
    required this.child,
    required this.padding,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  final Color color;

  const _HeaderButton({
    required this.icono,
    required this.onTap,
    this.color = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          icono,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}