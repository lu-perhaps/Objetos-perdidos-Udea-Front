import 'dart:ui';
import 'package:flutter/material.dart';

import '../Repositories/reporte_repository.dart';
import '../main.dart';

class MisReportesPage extends StatefulWidget {
  const MisReportesPage({super.key});

  @override
  State<MisReportesPage> createState() => _MisReportesPageState();
}

class _MisReportesPageState extends State<MisReportesPage>
    with SingleTickerProviderStateMixin {
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _reportes = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOut,
      ),
    );

    _animCtrl.forward();
    _cargarReportes();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarReportes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final user = supabase.auth.currentUser;
    final correo = user?.email?.toLowerCase().trim();

    if (correo == null || correo.isEmpty) {
      setState(() {
        _cargando = false;
        _error = 'No se encontró el usuario autenticado.';
      });
      return;
    }

    final datos = await ReporteRepository.obtenerReportesDeUsuario(
      correo: correo,
    );

    if (!mounted) return;

    setState(() {
      _cargando = false;
      _reportes = datos;
      if (_reportes.isEmpty) {
        _error = null;
      }
    });
  }

  String _estadoTexto(int idEstado) {
    switch (idEstado) {
      case 6:
        return 'Pendiente';
      case 7:
        return 'Resuelto';
      case 22:
        return 'Anulado';
      default:
        return 'Estado desconocido';
    }
  }

  Color _estadoColor(int idEstado) {
    switch (idEstado) {
      case 6:
        return const Color(0xFFD97706);
      case 7:
        return const Color(0xFF0A8F4D);
      case 22:
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _estadoIcono(int idEstado) {
    switch (idEstado) {
      case 6:
        return Icons.hourglass_top_rounded;
      case 7:
        return Icons.check_circle_outline_rounded;
      case 22:
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _anularReporte(int idReporte) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Anular reporte'),
          content: const Text(
            '¿Deseas anular este reporte? Solo deberías hacerlo si ya encontraste el objeto por otro medio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
              ),
              child: const Text(
                'Anular',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final ok = await ReporteRepository.anularReporte(idReporte);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Reporte anulado correctamente' : 'No se pudo anular el reporte',
        ),
      ),
    );

    if (ok) {
      await _cargarReportes();
    }
  }

  int _obtenerIdEstado(Map<String, dynamic> reporte) {
    return int.tryParse(
          reporte['idEstado']?.toString() ??
              reporte['id_estado']?.toString() ??
              '',
        ) ??
        -1;
  }

  int? _obtenerIdReporte(Map<String, dynamic> reporte) {
    return int.tryParse(
      reporte['id']?.toString() ?? reporte['idReporte']?.toString() ?? '',
    );
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderPage(
                            titulo: 'Mis reportes',
                            subtitulo: 'Reportes de pérdida registrados',
                            total: _reportes.length,
                            onRefresh: _cargarReportes,
                          ),
                          const SizedBox(height: 22),
                          Expanded(
                            child: RefreshIndicator(
                              color: const Color(0xFF0A8F4D),
                              onRefresh: _cargarReportes,
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
          color: Color(0xFF0A8F4D),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          _EstadoVacio(
            icono: Icons.error_outline_rounded,
            titulo: 'No se pudo cargar',
            mensaje: _error!,
            accionTexto: 'Reintentar',
            onAccion: _cargarReportes,
          ),
        ],
      );
    }

    if (_reportes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 90),
          _EstadoVacio(
            icono: Icons.article_outlined,
            titulo: 'No tienes reportes aún',
            mensaje: 'Cuando registres un reporte de pérdida, aparecerá aquí.',
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _reportes.length,
      itemBuilder: (context, index) {
        final reporte = _reportes[index];

        final idEstado = _obtenerIdEstado(reporte);
        final descripcion =
            reporte['descripcion'] ??
                reporte['descripcionReporte'] ??
                reporte['descripcionObjeto'] ??
                'Sin descripción';

        final lugar =
            reporte['lugar'] ??
                reporte['nombreLugar'] ??
                reporte['tbl_lugar']?['nombre'] ??
                'No especificado';

        final fecha =
            reporte['fechaReporte'] ??
                reporte['fecha_reporte'] ??
                reporte['fechaAproxPerdida'] ??
                reporte['fecha_aprox_perdida'] ??
                'Sin fecha';

        return _ReporteCard(
          descripcion: descripcion.toString(),
          lugar: lugar.toString(),
          fecha: fecha.toString(),
          idEstado: idEstado,
          estadoTexto: _estadoTexto(idEstado),
          estadoColor: _estadoColor(idEstado),
          estadoIcono: _estadoIcono(idEstado),
          onAnular: idEstado == 6
              ? () async {
                  final idReporte = _obtenerIdReporte(reporte);

                  if (idReporte == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID de reporte inválido.'),
                      ),
                    );
                    return;
                  }

                  await _anularReporte(idReporte);
                }
              : null,
        );
      },
    );
  }
}

class _HeaderPage extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final int total;
  final Future<void> Function() onRefresh;

  const _HeaderPage({
    required this.titulo,
    required this.subtitulo,
    required this.total,
    required this.onRefresh,
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
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF0A8F4D).withOpacity(0.22),
              ),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _HeaderButton(
            icono: Icons.refresh_rounded,
            onTap: () async => onRefresh(),
          ),
        ],
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  final String descripcion;
  final String lugar;
  final String fecha;
  final int idEstado;
  final String estadoTexto;
  final Color estadoColor;
  final IconData estadoIcono;
  final VoidCallback? onAnular;

  const _ReporteCard({
    required this.descripcion,
    required this.lugar,
    required this.fecha,
    required this.idEstado,
    required this.estadoTexto,
    required this.estadoColor,
    required this.estadoIcono,
    this.onAnular,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      borderColor: estadoColor.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BadgeEstado(
                texto: estadoTexto,
                color: estadoColor,
                icono: estadoIcono,
              ),
              const Spacer(),
              if (idEstado == 6)
                const _MiniLabel(
                  texto: 'Activo',
                  color: Color(0xFFD97706),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          _DetalleLinea(
            icono: Icons.location_on_outlined,
            label: 'Lugar aproximado',
            texto: lugar,
          ),
          const SizedBox(height: 8),
          _DetalleLinea(
            icono: Icons.calendar_today_outlined,
            label: 'Fecha',
            texto: fecha,
          ),
          if (idEstado == 6) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFFD97706).withOpacity(0.22),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Puedes anular este reporte si ya encontraste tu objeto por otro medio.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAnular,
                icon: const Icon(Icons.block_rounded),
                label: const Text('Anular reporte'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  side: const BorderSide(color: Color(0xFFD97706)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ] else if (idEstado == 7) ...[
            const SizedBox(height: 14),
            const _MiniBanner(
              color: Color(0xFF0A8F4D),
              icono: Icons.check_circle_outline,
              mensaje:
                  'Este reporte fue resuelto. Revisa tus solicitudes o notificaciones para ver la información relacionada.',
            ),
          ] else if (idEstado == 22) ...[
            const SizedBox(height: 14),
            const _MiniBanner(
              color: Color(0xFF6B7280),
              icono: Icons.block,
              mensaje: 'Este reporte fue anulado y ya no está activo.',
            ),
          ],
        ],
      ),
    );
  }
}

class _DetalleLinea extends StatelessWidget {
  final IconData icono;
  final String label;
  final String texto;

  const _DetalleLinea({
    required this.icono,
    required this.label,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniBanner extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String mensaje;

  const _MiniBanner({
    required this.color,
    required this.icono,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;

  const _BadgeEstado({
    required this.texto,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String texto;
  final Color color;

  const _MiniLabel({
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? accionTexto;
  final VoidCallback? onAccion;

  const _EstadoVacio({
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accionTexto,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            color: const Color(0xFF0A8F4D),
            size: 44,
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (accionTexto != null && onAccion != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8F4D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  accionTexto!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
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

  const _HeaderButton({
    required this.icono,
    required this.onTap,
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
          color: const Color(0xFF111827),
          size: 18,
        ),
      ),
    );
  }
}