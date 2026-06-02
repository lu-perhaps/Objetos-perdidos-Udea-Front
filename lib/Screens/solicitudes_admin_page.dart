import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/api_config.dart';
import '../Repositories/solicitud_repository.dart';

class SolicitudesAdminPage extends StatefulWidget {
  const SolicitudesAdminPage({super.key});

  @override
  State<SolicitudesAdminPage> createState() => _SolicitudesAdminPageState();
}

class _SolicitudesAdminPageState extends State<SolicitudesAdminPage> {
  List<Map<String, dynamic>> solicitudes = [];
  bool cargando = true;

  int filtroEstado = 8;

  @override
  void initState() {
    super.initState();
    cargarSolicitudes();
  }

  Future<void> cargarSolicitudes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/solicitudes/admin'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        solicitudes = List<Map<String, dynamic>>.from(data);
        cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR CARGANDO SOLICITUDES: $e');

      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando solicitudes: $e')),
      );
    }
  }

  Future<void> actualizarEstado(int id, String accion) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/solicitudes/$id/$accion'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      await cargarSolicitudes();
    } catch (e) {
      debugPrint('ERROR ACTUALIZANDO ESTADO: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando estado: $e')),
      );
    }
  }

  Future<void> registrarEntrega(int idSolicitud) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar entrega'),
        content: const Text(
          '¿Confirmas que el objeto fue entregado al solicitante?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A8F4D),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final success = await SolicitudRepository.entregarSolicitud(idSolicitud);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega registrada con éxito')),
      );
      await cargarSolicitudes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error registrando entrega')),
      );
    }
  }

  Future<void> cancelarAprobacion(int idSolicitud) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar aprobación'),
        content: const Text(
          '¿Deseas cancelar esta aprobación y volver a publicar el objeto? Usa esta opción si el usuario no reclamó el objeto o si la aprobación fue incorrecta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sí, republicar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final success = await SolicitudRepository.cancelarAprobacion(idSolicitud);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aprobación cancelada y objeto republicado'),
        ),
      );
      await cargarSolicitudes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error cancelando la aprobación'),
        ),
      );
    }
  }

  String estadoTexto(int estado) {
    if (estado == 8) return 'Pendiente';
    if (estado == 9) return 'Aprobado';
    if (estado == 10) return 'Rechazado';
    if (estado == 13) return 'Anulado';
    if (estado == 2) return 'Entregado';
    return 'Desconocido';
  }

  Color estadoColor(int estado) {
    if (estado == 8) return const Color(0xFFD97706);
    if (estado == 9) return const Color(0xFF0A8F4D);
    if (estado == 10) return const Color(0xFFDC2626);
    if (estado == 13) return const Color(0xFF6B7280);
    if (estado == 2) return const Color(0xFF2563EB);
    return Colors.grey;
  }

  IconData estadoIcono(int estado) {
    if (estado == 8) return Icons.hourglass_top_rounded;
    if (estado == 9) return Icons.check_circle_outline_rounded;
    if (estado == 10) return Icons.cancel_outlined;
    if (estado == 13) return Icons.block_rounded;
    if (estado == 2) return Icons.inventory_2_outlined;
    return Icons.help_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final solicitudesFiltradas = filtroEstado == 0
        ? solicitudes
        : solicitudes.where((s) => s['idEstado'] == filtroEstado).toList();

    final pendientes = solicitudes.where((s) => s['idEstado'] == 8).length;
    final aprobadas = solicitudes.where((s) => s['idEstado'] == 9).length;
    final rechazadas = solicitudes.where((s) => s['idEstado'] == 10).length;

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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      _Header(
                        total: solicitudes.length,
                        onRefresh: () async {
                          setState(() => cargando = true);
                          await cargarSolicitudes();
                        },
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
                              titulo: 'Aprobadas',
                              valor: '$aprobadas',
                              color: const Color(0xFF0A8F4D),
                              icono: Icons.check_circle_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ResumenCard(
                              titulo: 'Rechazadas',
                              valor: '$rechazadas',
                              color: const Color(0xFFDC2626),
                              icono: Icons.cancel_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _Filtros(
                        filtroEstado: filtroEstado,
                        onChanged: (estado) {
                          setState(() => filtroEstado = estado);
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: cargando
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0A8F4D),
                                ),
                              )
                            : solicitudesFiltradas.isEmpty
                                ? const _EmptyState()
                                : ListView.builder(
                                    itemCount: solicitudesFiltradas.length,
                                    itemBuilder: (context, index) {
                                      final s = solicitudesFiltradas[index];

                                      final estado = int.tryParse(
                                            (s['idEstado'] ?? '').toString(),
                                          ) ??
                                          -1;

                                      return _SolicitudCard(
                                        solicitud: s,
                                        estado: estado,
                                        estadoTexto: estadoTexto(estado),
                                        estadoColor: estadoColor(estado),
                                        estadoIcono: estadoIcono(estado),
                                        onAprobar: () => actualizarEstado(
                                          s['id'],
                                          'aprobar',
                                        ),
                                        onRechazar: () => actualizarEstado(
                                          s['id'],
                                          'rechazar',
                                        ),
                                        onEntregar: () =>
                                            registrarEntrega(s['id']),
                                        onCancelarAprobacion: () =>
                                            cancelarAprobacion(s['id']),
                                      );
                                    },
                                  ),
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
                  'ADMIN · SOLICITUDES',
                  style: TextStyle(
                    color: Color(0xFF0A8F4D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Solicitudes de reclamo',
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
            ),
            child: Text(
              '$total total',
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

class _Filtros extends StatelessWidget {
  final int filtroEstado;
  final ValueChanged<int> onChanged;

  const _Filtros({
    required this.filtroEstado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(7),
      child: Row(
        children: [
          _FiltroButton(
            texto: 'Pendientes',
            estado: 8,
            activo: filtroEstado == 8,
            onTap: onChanged,
          ),
          _FiltroButton(
            texto: 'Aprobadas',
            estado: 9,
            activo: filtroEstado == 9,
            onTap: onChanged,
          ),
          _FiltroButton(
            texto: 'Rechazadas',
            estado: 10,
            activo: filtroEstado == 10,
            onTap: onChanged,
          ),
          _FiltroButton(
            texto: 'Todas',
            estado: 0,
            activo: filtroEstado == 0,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FiltroButton extends StatelessWidget {
  final String texto;
  final int estado;
  final bool activo;
  final ValueChanged<int> onTap;

  const _FiltroButton({
    required this.texto,
    required this.estado,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => onTap(estado),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              activo ? const Color(0xFF0A8F4D) : const Color(0xFFF3F4F6),
          foregroundColor: activo ? Colors.white : const Color(0xFF4B5563),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final int estado;
  final String estadoTexto;
  final Color estadoColor;
  final IconData estadoIcono;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;
  final VoidCallback onEntregar;
  final VoidCallback onCancelarAprobacion;

  const _SolicitudCard({
    required this.solicitud,
    required this.estado,
    required this.estadoTexto,
    required this.estadoColor,
    required this.estadoIcono,
    required this.onAprobar,
    required this.onRechazar,
    required this.onEntregar,
    required this.onCancelarAprobacion,
  });

  @override
  Widget build(BuildContext context) {
    final esCoincidencia =
        solicitud['idReporte'] != null || solicitud['id_reporte'] != null;

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
              const SizedBox(width: 8),
              if (esCoincidencia)
                const _SmallBadge(
                  texto: 'Coincidencia admin',
                  color: Color(0xFFD97706),
                  icono: Icons.bolt_rounded,
                ),
              const Spacer(),
              Text(
                '#${solicitud['id'] ?? '-'}',
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
            solicitud['objeto'] ?? 'Objeto sin nombre',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icono: Icons.person_outline_rounded,
            label: 'Usuario',
            valor: solicitud['correoUsuario'] ?? 'Sin correo',
          ),
          const SizedBox(height: 7),
          _InfoLine(
            icono: Icons.location_on_outlined,
            label: 'Lugar pérdida',
            valor: solicitud['lugar'] ?? 'Sin lugar',
          ),
          const SizedBox(height: 7),
          _InfoLine(
            icono: Icons.calendar_today_outlined,
            label: 'Fecha pérdida',
            valor: solicitud['fechaAproxPerdida']?.toString() ?? 'Sin fecha',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              solicitud['descripcion'] ?? 'Sin descripción',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (estado == 8) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAprobar,
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: const Text(
                      'Aprobar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A8F4D),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRechazar,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    label: const Text(
                      'Rechazar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (estado == 9) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEntregar,
                    icon: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Registrar entrega',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCancelarAprobacion,
                    icon: const Icon(
                      Icons.undo_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Republicar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

class _SmallBadge extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;

  const _SmallBadge({
    required this.texto,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 10,
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
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
              Icons.assignment_outlined,
              color: Color(0xFF0A8F4D),
              size: 44,
            ),
            SizedBox(height: 14),
            Text(
              'No hay solicitudes en este estado',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Cambia el filtro o actualiza la lista.',
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