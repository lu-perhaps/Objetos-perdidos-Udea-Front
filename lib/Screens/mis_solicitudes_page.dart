import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/estados.dart';
import '../Repositories/solicitud_repository.dart';
import '../main.dart';

class MisSolicitudesPage extends StatefulWidget {
  const MisSolicitudesPage({super.key});

  @override
  State<MisSolicitudesPage> createState() => _MisSolicitudesPageState();
}

class _MisSolicitudesPageState extends State<MisSolicitudesPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _solicitudes = [];
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
    _cargarSolicitudes();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarSolicitudes() async {
    final user = supabase.auth.currentUser;

    if (user == null || user.email == null) {
      if (mounted) {
        setState(() => _cargando = false);
      }
      return;
    }

    final data = await SolicitudRepository.obtenerSolicitudesDeUsuario(
      correo: user.email!.toLowerCase().trim(),
    );

    if (mounted) {
      setState(() {
        _solicitudes = data;
        _cargando = false;
      });
    }
  }

  String _estadoTexto(int estado) {
    if (estado == Estados.solicitudPendiente) return 'Pendiente';
    if (estado == Estados.solicitudAprobada) return 'Aprobada';
    if (estado == Estados.solicitudRechazada) return 'Rechazada';
    if (estado == Estados.solicitudAnulada) return 'Anulada';
    if (estado == Estados.solicitudEntregada) return 'Entregada';
    return 'Estado desconocido';
  }

  Color _estadoColor(int estado) {
    if (estado == Estados.solicitudPendiente) {
      return const Color(0xFFE07B2A);
    }
    if (estado == Estados.solicitudAprobada) {
      return const Color(0xFF0A8F4D);
    }
    if (estado == Estados.solicitudRechazada) {
      return const Color(0xFFDC2626);
    }
    if (estado == Estados.solicitudAnulada) {
      return const Color(0xFF9CA3AF);
    }
    if (estado == Estados.solicitudEntregada) {
      return const Color(0xFF2563EB);
    }

    return Colors.grey;
  }

  IconData _estadoIcono(int estado) {
    if (estado == Estados.solicitudPendiente) {
      return Icons.hourglass_top_rounded;
    }
    if (estado == Estados.solicitudAprobada) {
      return Icons.check_circle_outline_rounded;
    }
    if (estado == Estados.solicitudRechazada) {
      return Icons.cancel_outlined;
    }
    if (estado == Estados.solicitudAnulada) {
      return Icons.block_rounded;
    }
    if (estado == Estados.solicitudEntregada) {
      return Icons.inventory_2_outlined;
    }

    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/udea_bg.jpeg',
            fit: BoxFit.cover,
          ),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBB000000),
                  Color(0xEE011208),
                ],
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HeaderBack(
                        breadcrumb: 'MIS SOLICITUDES',
                        titulo: 'Estado de reclamos',
                      ),

                      const SizedBox(height: 20),

                      if (!_cargando && _solicitudes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A8F4D).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    const Color(0xFF0A8F4D).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '${_solicitudes.length} solicitud(es)',
                              style: const TextStyle(
                                color: Color(0xFF0A8F4D),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      Expanded(
                        child: _buildContenido(),
                      ),
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
          color: Color(0xFF0A8F4D),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_solicitudes.isEmpty) {
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
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Colors.white24,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin solicitudes aún',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando reclames un objeto,\naparecerá aquí su estado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white30,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _solicitudes.length,
      itemBuilder: (_, i) {
        final s = _solicitudes[i];

        final estado = int.tryParse(
              (s['idEstado'] ?? s['id_estado'] ?? -1).toString(),
            ) ??
            -1;

        return _TarjetaSolicitud(
          solicitud: s,
          estado: estado,
          estadoTexto: _estadoTexto(estado),
          estadoColor: _estadoColor(estado),
          estadoIcono: _estadoIcono(estado),
        );
      },
    );
  }
}

class _TarjetaSolicitud extends StatefulWidget {
  final Map<String, dynamic> solicitud;
  final int estado;
  final String estadoTexto;
  final Color estadoColor;
  final IconData estadoIcono;

  const _TarjetaSolicitud({
    required this.solicitud,
    required this.estado,
    required this.estadoTexto,
    required this.estadoColor,
    required this.estadoIcono,
  });

  @override
  State<_TarjetaSolicitud> createState() => _TarjetaSolicitudState();
}

class _TarjetaSolicitudState extends State<_TarjetaSolicitud> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.solicitud;

    final fotoUrl = (
      s['fotografia'] ??
      s['tbl_objeto']?['fotografia'] ??
      ''
    ).toString();

    final nombreLugar = (
      s['lugar'] ??
      s['tbl_objeto']?['lugar_actual']?['nombre'] ??
      'la oficina correspondiente'
    ).toString();

    final esCoincidencia = s['idReporte'] != null || s['id_reporte'] != null;

    final descripcionSolicitud =
        (s['descripcion'] ?? 'Sin descripción').toString();

    final descripcionObjeto = (
      s['descripcionObjeto'] ??
      s['tbl_objeto']?['descripcion_general'] ??
      ''
    ).toString();

    final nombreObjeto = (
      s['objeto'] ??
      s['tbl_objeto']?['nombre'] ??
      'Objeto'
    ).toString();

    final fechaPerdida = (
      s['fechaAproxPerdida'] ??
      s['fecha_aprox_perdida'] ??
      'No especificada'
    ).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.estadoColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _expandida = !_expandida),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: fotoUrl.isNotEmpty
                              ? Image.network(
                                  fotoUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _IconoObjeto(
                                    color: widget.estadoColor,
                                  ),
                                )
                              : _IconoObjeto(
                                  color: widget.estadoColor,
                                ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (esCoincidencia)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE07B2A)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFE07B2A)
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    '⚡ Coincidencia admin',
                                    style: TextStyle(
                                      color: Color(0xFFE07B2A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Solicitud manual',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                              Text(
                                nombreObjeto,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.estadoColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.estadoColor.withOpacity(0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.estadoIcono,
                                      color: widget.estadoColor,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.estadoTexto,
                                      style: TextStyle(
                                        color: widget.estadoColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        AnimatedRotation(
                          turns: _expandida ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white38,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: _expandida
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color: Colors.white.withOpacity(0.08),
                                height: 1,
                              ),

                              const SizedBox(height: 14),

                              _FilaInfo(
                                icono: Icons.description_outlined,
                                label: esCoincidencia
                                    ? 'Descripción del reporte'
                                    : 'Tu descripción',
                                valor: descripcionSolicitud,
                              ),

                              if (descripcionObjeto.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _FilaInfo(
                                  icono: Icons.inventory_2_outlined,
                                  label: 'Objeto encontrado',
                                  valor: descripcionObjeto,
                                ),
                              ],

                              const SizedBox(height: 10),

                              _FilaInfo(
                                icono: Icons.location_on_outlined,
                                label: 'Ubicación',
                                valor: nombreLugar,
                              ),

                              const SizedBox(height: 10),

                              _FilaInfo(
                                icono: Icons.calendar_today_outlined,
                                label: 'Fecha aprox. pérdida',
                                valor: fechaPerdida,
                              ),

                              if (widget.estado ==
                                  Estados.solicitudAprobada) ...[
                                const SizedBox(height: 14),
                                _BannerEstado(
                                  color: const Color(0xFF0A8F4D),
                                  icono: Icons.check_circle_outline_rounded,
                                  mensaje:
                                      'Solicitud aprobada. Dirígete a $nombreLugar para recoger tu objeto.',
                                ),
                              ],

                              if (widget.estado ==
                                  Estados.solicitudRechazada) ...[
                                const SizedBox(height: 14),
                                _BannerEstado(
                                  color: const Color(0xFFDC2626),
                                  icono: Icons.cancel_outlined,
                                  mensaje:
                                      'Solicitud rechazada. Los datos no coinciden con el objeto registrado.',
                                ),
                              ],

                              if (widget.estado ==
                                  Estados.solicitudAnulada) ...[
                                const SizedBox(height: 14),
                                _BannerEstado(
                                  color: const Color(0xFF9CA3AF),
                                  icono: Icons.block_rounded,
                                  mensaje:
                                      'Solicitud anulada. Este reclamo ya no está activo.',
                                ),
                              ],

                              if (widget.estado ==
                                  Estados.solicitudEntregada) ...[
                                const SizedBox(height: 14),
                                _BannerEstado(
                                  color: const Color(0xFF2563EB),
                                  icono: Icons.inventory_2_outlined,
                                  mensaje:
                                      'Objeto entregado. El proceso de reclamo fue finalizado.',
                                ),
                              ],

                              if (widget.estado ==
                                  Estados.solicitudPendiente) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final confirmar = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Anular solicitud'),
                                          content: const Text(
                                            '¿Seguro que quieres anular esta solicitud? Solo deberías hacerlo si ya no necesitas reclamar este objeto.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Anular'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmar != true) return;

                                      final idSolicitud = int.tryParse(
                                        widget.solicitud['id']?.toString() ?? '',
                                      );

                                      if (idSolicitud == null) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'ID de solicitud inválido, no se puede anular.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final ok = await SolicitudRepository.anularSolicitud(
                                        idSolicitud,
                                      );

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok
                                                ? 'Solicitud anulada correctamente'
                                                : 'No se pudo anular la solicitud',
                                          ),
                                        ),
                                      );

                                      if (ok) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Anular solicitud'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconoObjeto extends StatelessWidget {
  final Color color;

  const _IconoObjeto({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: color,
        size: 26,
      ),
    );
  }
}

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          color: Colors.white30,
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: valor,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BannerEstado extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String mensaje;

  const _BannerEstado({
    required this.color,
    required this.icono,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBack extends StatelessWidget {
  final String titulo;
  final String? breadcrumb;

  const _HeaderBack({
    required this.titulo,
    this.breadcrumb,
  });

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
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
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