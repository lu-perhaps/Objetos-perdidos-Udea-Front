import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/estados.dart';
import '../Repositories/reporte_repository.dart';
import '../Repositories/persona_repository.dart';
import '../services/coincidencia_service.dart';

class ReportesAdminPage extends StatefulWidget {
  const ReportesAdminPage({super.key});

  @override
  State<ReportesAdminPage> createState() => _ReportesAdminPageState();
}

class _ReportesAdminPageState extends State<ReportesAdminPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _reportes = [];
  bool _cargando = true;

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
    final data = await ReporteRepository.obtenerReportes();

    if (mounted) {
      setState(() {
        _reportes = data;
        _cargando = false;
      });
    }
  }

  Future<void> _refrescar() async {
    setState(() => _cargando = true);
    await _cargarReportes();
  }

  void _actualizarReporteLocal(int idReporte) {
    if (!mounted) return;

    final index = _reportes.indexWhere((r) {
      final rawId = r['id'];
      return rawId is int
          ? rawId == idReporte
          : int.tryParse(rawId?.toString() ?? '') == idReporte;
    });

    if (index < 0) return;

    setState(() {
      final reporte = _reportes[index];
      reporte['id_estado'] = 7;
      reporte['idEstado'] = 7;
      reporte['estado'] = 7;
      _reportes[index] = reporte;
    });
  }

  String _estadoTexto(int estado) {
    if (estado == Estados.reportePendiente) return 'Pendiente';
    if (estado == Estados.reporteResuelto) return 'Resuelto';
    if (estado == 8) return 'Pendiente';
    if (estado == 22) return 'Anulado';
    return 'Estado desconocido';
  }

  Color _estadoColor(int estado) {
    if (estado == Estados.reportePendiente || estado == 8) {
      return const Color(0xFFD97706);
    }
    if (estado == Estados.reporteResuelto) return const Color(0xFF0A8F4D);
    if (estado == 22) return const Color(0xFF6B7280);
    return Colors.grey;
  }

  IconData _estadoIcono(int estado) {
    if (estado == Estados.reportePendiente || estado == 8) {
      return Icons.hourglass_top_rounded;
    }
    if (estado == Estados.reporteResuelto) {
      return Icons.check_circle_outline_rounded;
    }
    if (estado == 22) return Icons.block_rounded;
    return Icons.help_outline_rounded;
  }

  Future<void> _mostrarDialogoCoincidencia(
    Map<String, dynamic> reporte,
  ) async {
    List<Map<String, dynamic>> objetos = [];

    try {
      objetos = await ReporteRepository.obtenerObjetosPublicados();
    } catch (e) {
      debugPrint('ERROR cargando objetos: $e');
    }

    if (!mounted) return;

    if (objetos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay objetos disponibles para hacer coincidencia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int? idObjetoSeleccionado;
    final mensajeCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          maxChildSize: 0.95,
          minChildSize: 0.55,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Seleccionar objeto coincidente',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reporte: ${reporte['descripcionObjeto'] ?? 'Sin descripción'}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: objetos.length,
                      itemBuilder: (_, i) {
                        final obj = objetos[i];
                        final seleccionado = idObjetoSeleccionado == obj['id'];

                        return GestureDetector(
                          onTap: () => setModalState(
                            () => idObjetoSeleccionado = obj['id'],
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? const Color(0xFFE1F5EE)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: seleccionado
                                    ? AppColors.verde
                                    : const Color(0xFFE5E7EB),
                                width: seleccionado ? 1.6 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  seleccionado
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: seleccionado
                                      ? AppColors.verde
                                      : const Color(0xFF9CA3AF),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        obj['nombre'].toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF111827),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if ((obj['descripcionGeneral'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Text(
                                            obj['descripcionGeneral']
                                                .toString(),
                                            style: const TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mensajeCtrl,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Mensaje adicional (opcional)',
                      hintText: 'Ej: Lleva tu documento de identidad.',
                      labelStyle: const TextStyle(color: Color(0xFF0A8F4D)),
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.verde, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: idObjetoSeleccionado == null
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _confirmarCoincidencia(
                                reporte: reporte,
                                idObjeto: idObjetoSeleccionado!,
                                mensajePersonalizado: mensajeCtrl.text,
                              );
                            },
                      icon: const Icon(
                        Icons.link_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Confirmar coincidencia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde,
                        disabledBackgroundColor:
                            AppColors.verde.withOpacity(0.35),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    mensajeCtrl.dispose();
  }

  Future<void> _confirmarCoincidencia({
    required Map<String, dynamic> reporte,
    required int idObjeto,
    required String mensajePersonalizado,
  }) async {
    final idPersonaAdmin = await PersonaRepository.obtenerIdPersonaActual();
    if (idPersonaAdmin == null) return;

    final exito = await CoincidenciaService.procesarCoincidencia(
      reporte: reporte,
      idObjeto: idObjeto,
      mensajePersonalizado: mensajePersonalizado,
      idPersonaAdmin: idPersonaAdmin,
    );

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    if (exito) {
      _actualizarReporteLocal(reporte['id'] as int);
      await _cargarReportes();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Coincidencia registrada y usuario notificado'),
          backgroundColor: AppColors.verde,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Error al procesar la coincidencia'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _reportes.where((r) {
      final raw = r['idEstado'] ?? r['id_estado'] ?? r['estado'];
      final estado = int.tryParse(raw?.toString() ?? '') ?? -1;
      return estado == Estados.reportePendiente || estado == 8;
    }).length;

    final resueltos = _reportes.where((r) {
      final raw = r['idEstado'] ?? r['id_estado'] ?? r['estado'];
      final estado = int.tryParse(raw?.toString() ?? '') ?? -1;
      return estado == Estados.reporteResuelto;
    }).length;

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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          _Header(
                            total: _reportes.length,
                            onRefresh: _refrescar,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ResumenCard(
                                  titulo: 'Pendientes',
                                  valor: '$pendientes',
                                  color: const Color(0xFFD97706),
                                  icono: Icons.hourglass_top_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ResumenCard(
                                  titulo: 'Resueltos',
                                  valor: '$resueltos',
                                  color: const Color(0xFF0A8F4D),
                                  icono: Icons.check_circle_outline_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ResumenCard(
                                  titulo: 'Total',
                                  valor: '${_reportes.length}',
                                  color: const Color(0xFF2563EB),
                                  icono: Icons.article_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _cargando
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.verde,
                                    ),
                                  )
                                : _reportes.isEmpty
                                    ? const _EmptyState()
                                    : RefreshIndicator(
                                        color: AppColors.verde,
                                        onRefresh: _refrescar,
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount: _reportes.length,
                                          itemBuilder: (_, i) {
                                            final r = _reportes[i];
                                            final rEstadoRaw =
                                                r['idEstado'] ??
                                                    r['id_estado'] ??
                                                    r['estado'];
                                            final estado = int.tryParse(
                                                  rEstadoRaw?.toString() ?? '',
                                                ) ??
                                                -1;
                                            final pendiente =
                                                estado ==
                                                        Estados
                                                            .reportePendiente ||
                                                    estado == 8;

                                            return _ReporteCard(
                                              reporte: r,
                                              estado: estado,
                                              estadoTexto:
                                                  _estadoTexto(estado),
                                              estadoColor:
                                                  _estadoColor(estado),
                                              estadoIcono:
                                                  _estadoIcono(estado),
                                              pendiente: pendiente,
                                              onCoincidencia: () =>
                                                  _mostrarDialogoCoincidencia(
                                                r,
                                              ),
                                            );
                                          },
                                        ),
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
}

class _Header extends StatelessWidget {
  final int total;
  final Future<void> Function() onRefresh;

  const _Header({
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN · REPORTES',
                  style: TextStyle(
                    color: Color(0xFF0A8F4D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Reportes de pérdida',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
              '$total reporte(s)',
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
  final Map<String, dynamic> reporte;
  final int estado;
  final String estadoTexto;
  final Color estadoColor;
  final IconData estadoIcono;
  final bool pendiente;
  final VoidCallback onCoincidencia;

  const _ReporteCard({
    required this.reporte,
    required this.estado,
    required this.estadoTexto,
    required this.estadoColor,
    required this.estadoIcono,
    required this.pendiente,
    required this.onCoincidencia,
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
              _Badge(
                texto: estadoTexto,
                color: estadoColor,
                icono: estadoIcono,
              ),
              const Spacer(),
              Text(
                '#${reporte['id'] ?? '-'}',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reporte['descripcionObjeto'] ?? 'Sin descripción',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icono: Icons.person_outline,
            label: 'Usuario',
            valor: reporte['correoUsuario'] ?? 'Sin correo',
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icono: Icons.location_on_outlined,
            label: 'Lugar',
            valor: reporte['lugar'] ?? 'No especificado',
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icono: Icons.calendar_today_outlined,
            label: 'Fecha aprox.',
            valor: reporte['fechaAproxPerdida']?.toString() ??
                'No especificada',
          ),
          if (pendiente) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCoincidencia,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.verde,
                  side: const BorderSide(color: AppColors.verde),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text(
                  'Encontré una coincidencia',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;

  const _Badge({
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

class _InfoLine extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _InfoLine({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: const Color(0xFF6B7280), size: 15),
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
            valor,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _WhiteCard(
        padding: const EdgeInsets.all(28),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              color: Color(0xFF0A8F4D),
              size: 44,
            ),
            SizedBox(height: 14),
            Text(
              'No hay reportes de pérdida',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Cuando los usuarios reporten pérdidas, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}