import 'package:flutter/material.dart';
import '../Repositories/reporte_repository.dart';
import '../main.dart';

class MisReportesPage extends StatefulWidget {
  const MisReportesPage({super.key});

  @override
  State<MisReportesPage> createState() => _MisReportesPageState();
}

class _MisReportesPageState extends State<MisReportesPage> {
  bool _cargando = true;
  String? _error;
  List<Map<String, dynamic>> _reportes = [];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
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

    final datos = await ReporteRepository.obtenerReportesDeUsuario(correo: correo);
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
        return const Color(0xFFE07B2A);
      case 7:
        return const Color(0xFF0A8F4D);
      case 22:
        return const Color(0xFF9CA3AF);
      default:
        return Colors.white54;
    }
  }

  Future<void> _anularReporte(int idReporte) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Anular reporte'),
          content: const Text(
            '¿Deseas anular este reporte? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Anular'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reportes'),
        backgroundColor: const Color(0xFF0B6E4F),
      ),
      backgroundColor: const Color(0xFF05130D),
      body: RefreshIndicator(
        color: const Color(0xFF0A8F4D),
        onRefresh: _cargarReportes,
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0A8F4D),
                  strokeWidth: 2.5,
                ),
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ElevatedButton(
                          onPressed: _cargarReportes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8F4D),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  )
                : _reportes.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          const Center(
                            child: Text(
                              'No tienes reportes registrados aún.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'Cuando registres un reporte, aparecerá en esta lista.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reportes.length,
                        itemBuilder: (context, index) {
                          final reporte = _reportes[index];
                          final idEstado = int.tryParse(
                                reporte['idEstado']?.toString() ??
                                    reporte['id_estado']?.toString() ??
                                    '',
                              ) ??
                              -1;
                          final descripcion =
                              reporte['descripcion'] ??
                                  reporte['descripcionReporte'] ??
                                  reporte['descripcionObjeto'] ??
                                  'Sin descripción';
                          final lugar = reporte['lugar'] ??
                              reporte['nombreLugar'] ??
                              reporte['tbl_lugar']?['nombre'] ??
                              'No especificado';
                          final fecha = reporte['fechaReporte'] ??
                              reporte['fecha_reporte'] ??
                              reporte['fechaAproxPerdida'] ??
                              reporte['fecha_aprox_perdida'] ??
                              'Sin fecha';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _estadoColor(idEstado).withOpacity(0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          descripcion.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _estadoColor(idEstado)
                                              .withOpacity(0.14),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          _estadoTexto(idEstado),
                                          style: TextStyle(
                                            color: _estadoColor(idEstado),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _DetalleLinea(
                                    icono: Icons.location_on_outlined,
                                    texto: lugar.toString(),
                                  ),
                                  const SizedBox(height: 8),
                                  _DetalleLinea(
                                    icono: Icons.calendar_today_outlined,
                                    texto: fecha.toString(),
                                  ),
                                  const SizedBox(height: 14),
                                  if (idEstado == 6) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final idReporte = int.tryParse(
                                            reporte['id']?.toString() ??
                                                reporte['idReporte']?.toString() ??
                                                '',
                                          );
                                          if (idReporte == null) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'ID de reporte inválido.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          await _anularReporte(idReporte);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFE07B2A),
                                          side: const BorderSide(
                                            color: Color(0xFFE07B2A),
                                          ),
                                        ),
                                        child: const Text('Anular reporte'),
                                      ),
                                    ),
                                  ] else if (idEstado == 7) ...[
                                    _MiniBanner(
                                      color: const Color(0xFF0A8F4D),
                                      icono: Icons.check_circle_outline,
                                      mensaje: 'Resuelto',
                                    ),
                                  ] else if (idEstado == 22) ...[
                                    _MiniBanner(
                                      color: const Color(0xFF9CA3AF),
                                      icono: Icons.block,
                                      mensaje: 'Anulado',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _DetalleLinea extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _DetalleLinea({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 16,
          color: Colors.white38,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            mensaje,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
