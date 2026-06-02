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

  Future<void> _refrescar() async {
    if (mounted) {
      setState(() => _cargando = true);
    }

    await _cargarSolicitudes();
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
      return const Color(0xFFD97706);
    }

    if (estado == Estados.solicitudAprobada) {
      return const Color(0xFF0A8F4D);
    }

    if (estado == Estados.solicitudRechazada) {
      return const Color(0xFFDC2626);
    }

    if (estado == Estados.solicitudAnulada) {
      return const Color(0xFF6B7280);
    }

    if (estado == Estados.solicitudEntregada) {
      return const Color(0xFF2563EB);
    }

    return const Color(0xFF6B7280);
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

    return Icons.help_outline_rounded;
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
                            titulo: 'Mis solicitudes',
                            subtitulo: 'Estado de tus reclamos',
                            total: _solicitudes.length,
                            onRefresh: _refrescar,
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: RefreshIndicator(
                              color: const Color(0xFF0A8F4D),
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
          color: Color(0xFF0A8F4D),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_solicitudes.isEmpty) {
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
          onActualizada: _refrescar,
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
  final Future<void> Function() onActualizada;

  const _TarjetaSolicitud({
    required this.solicitud,
    required this.estado,
    required this.estadoTexto,
    required this.estadoColor,
    required this.estadoIcono,
    required this.onActualizada,
  });

  @override
  State<_TarjetaSolicitud> createState() => _TarjetaSolicitudState();
}

class _TarjetaSolicitudState extends State<_TarjetaSolicitud> {
  bool _expandida = false;
  bool _anulando = false;

  bool _tieneIdReporte(dynamic valor) {
    if (valor == null) return false;

    final texto = valor.toString().trim().toLowerCase();

    return texto.isNotEmpty && texto != 'null';
  }

  bool get _puedeVerUbicacion {
    return widget.estado == Estados.solicitudAprobada ||
        widget.estado == Estados.solicitudEntregada;
  }

  Future<void> _anularSolicitud() async {
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
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
            ),
            child: const Text(
              'Anular',
              style: TextStyle(color: Colors.white),
            ),
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
          content: Text('ID de solicitud inválido, no se puede anular.'),
        ),
      );

      return;
    }

    setState(() => _anulando = true);

    final ok = await SolicitudRepository.anularSolicitud(idSolicitud);

    if (!mounted) return;

    setState(() => _anulando = false);

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
      await widget.onActualizada();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.solicitud;

    final fotoUrl = (s['fotografia'] ?? s['tbl_objeto']?['fotografia'] ?? '')
        .toString();

    final nombreLugar = (s['lugar'] ??
            s['tbl_objeto']?['lugar_actual']?['nombre'] ??
            'la oficina correspondiente')
        .toString();

    final esCoincidencia =
        _tieneIdReporte(s['idReporte']) || _tieneIdReporte(s['id_reporte']);

    final descripcionSolicitud =
        (s['descripcion'] ?? 'Sin descripción').toString();

    final descripcionObjeto =
        (s['descripcionObjeto'] ?? s['tbl_objeto']?['descripcion_general'] ?? '')
            .toString();

    final nombreObjeto =
        (s['objeto'] ?? s['tbl_objeto']?['nombre'] ?? 'Objeto').toString();

    final fechaPerdida =
        (s['fechaAproxPerdida'] ?? s['fecha_aprox_perdida'] ?? 'No especificada')
            .toString();

    return _WhiteCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      borderColor: widget.estadoColor.withOpacity(0.25),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandida = !_expandida),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ImagenObjeto(
                    fotoUrl: fotoUrl,
                    color: widget.estadoColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EtiquetaTipoSolicitud(
                          esCoincidencia: esCoincidencia,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          nombreObjeto,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        _BadgeEstado(
                          texto: widget.estadoTexto,
                          color: widget.estadoColor,
                          icono: widget.estadoIcono,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expandida ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280),
                      size: 24,
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
                        const Divider(
                          color: Color(0xFFE5E7EB),
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
                            label: esCoincidencia
                                ? 'Objeto sugerido por el administrador'
                                : 'Objeto reclamado',
                            valor: descripcionObjeto,
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (_puedeVerUbicacion)
                          _FilaInfo(
                            icono: Icons.location_on_outlined,
                            label: 'Ubicación de custodia',
                            valor: nombreLugar,
                          )
                        else
                          const _FilaInfo(
                            icono: Icons.lock_outline_rounded,
                            label: 'Ubicación de custodia',
                            valor:
                                'Disponible únicamente si tu solicitud es aprobada.',
                          ),
                        const SizedBox(height: 10),
                        _FilaInfo(
                          icono: Icons.calendar_today_outlined,
                          label: 'Fecha aprox. pérdida',
                          valor: fechaPerdida,
                        ),
                        if (esCoincidencia) ...[
                          const SizedBox(height: 14),
                          const _BannerEstado(
                            color: Color(0xFFD97706),
                            icono: Icons.bolt_rounded,
                            mensaje:
                                'Esta solicitud fue creada automáticamente porque el administrador encontró una coincidencia con tu reporte de pérdida.',
                          ),
                        ],
                        if (widget.estado == Estados.solicitudAprobada) ...[
                          const SizedBox(height: 14),
                          _BannerEstado(
                            color: const Color(0xFF0A8F4D),
                            icono: Icons.check_circle_outline_rounded,
                            mensaje:
                                'Solicitud aprobada. Dirígete a $nombreLugar para continuar con la entrega.',
                          ),
                        ],
                        if (widget.estado == Estados.solicitudRechazada) ...[
                          const SizedBox(height: 14),
                          const _BannerEstado(
                            color: Color(0xFFDC2626),
                            icono: Icons.cancel_outlined,
                            mensaje:
                                'Solicitud rechazada. Los datos no coincidieron con el objeto registrado.',
                          ),
                        ],
                        if (widget.estado == Estados.solicitudAnulada) ...[
                          const SizedBox(height: 14),
                          const _BannerEstado(
                            color: Color(0xFF6B7280),
                            icono: Icons.block_rounded,
                            mensaje:
                                'Solicitud anulada. Este reclamo ya no está activo.',
                          ),
                        ],
                        if (widget.estado == Estados.solicitudEntregada) ...[
                          const SizedBox(height: 14),
                          const _BannerEstado(
                            color: Color(0xFF2563EB),
                            icono: Icons.inventory_2_outlined,
                            mensaje:
                                'Objeto entregado. El proceso de reclamo fue finalizado.',
                          ),
                        ],
                        if (widget.estado == Estados.solicitudPendiente) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color:
                                    const Color(0xFFD97706).withOpacity(0.22),
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
                                    'Puedes anular esta solicitud si ya no necesitas reclamar el objeto.',
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
                              onPressed: _anulando ? null : _anularSolicitud,
                              icon: _anulando
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cancel_outlined),
                              label: Text(
                                _anulando
                                    ? 'Anulando...'
                                    : 'Anular solicitud',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD97706),
                                side: const BorderSide(
                                  color: Color(0xFFD97706),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
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

class _ImagenObjeto extends StatelessWidget {
  final String fotoUrl;
  final Color color;

  const _ImagenObjeto({
    required this.fotoUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (fotoUrl.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Image.network(
        fotoUrl,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
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

class _EtiquetaTipoSolicitud extends StatelessWidget {
  final bool esCoincidencia;

  const _EtiquetaTipoSolicitud({
    required this.esCoincidencia,
  });

  @override
  Widget build(BuildContext context) {
    if (esCoincidencia) {
      return const _MiniLabel(
        texto: '⚡ Coincidencia admin',
        color: Color(0xFFD97706),
      );
    }

    return const _MiniLabel(
      texto: 'Solicitud manual',
      color: Color(0xFF2563EB),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
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
          color: const Color(0xFF6B7280),
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
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: valor,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
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
            Icons.assignment_outlined,
            color: Color(0xFF0A8F4D),
            size: 44,
          ),
          SizedBox(height: 14),
          Text(
            'Sin solicitudes aún',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Cuando reclames un objeto, aparecerá aquí el estado de tu solicitud.',
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