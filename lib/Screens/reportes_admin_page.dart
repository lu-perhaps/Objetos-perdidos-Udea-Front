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
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    final data = await ReporteRepository.obtenerReportes();
    if (mounted) {
      setState(() {
        _reportes = data;
        _cargando = false;
        _iniciarAnimaciones();
      });
    }
  }

  void _iniciarAnimaciones() {
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnims = List.generate(_reportes.length, (i) {
      final start = (i * 0.08).clamp(0.0, 0.6);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_reportes.length, (i) {
      final start = (i * 0.08).clamp(0.0, 0.6);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _estadoTexto(int estado) {
    if (estado == Estados.reportePendiente) return 'Pendiente';
    if (estado == Estados.reporteResuelto) return 'Resuelto';
    return 'Estado desconocido';
  }

  Color _estadoColor(int estado) {
    if (estado == Estados.reportePendiente) return Colors.orange;
    if (estado == Estados.reporteResuelto) return Colors.green;
    return Colors.grey;
  }

  Future<void> _mostrarDialogoCoincidencia(
      Map<String, dynamic> reporte) async {
    // Cargar objetos disponibles
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
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Seleccionar objeto coincidente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reporte: ${reporte['descripcionObjeto'] ?? 'Sin descripción'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Lista objetos
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
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? AppColors.verde.withOpacity(0.2)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: seleccionado
                                  ? AppColors.verde
                                  : Colors.white24,
                              width: seleccionado ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                seleccionado
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: seleccionado
                                    ? AppColors.verde
                                    : Colors.white38,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      obj['nombre'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if ((obj['descripcionGeneral'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(
                                        obj['descripcionGeneral'].toString(),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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

                // Mensaje personalizado
                TextField(
                  controller: mensajeCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mensaje adicional (opcional)',
                    hintText:
                        'Ej: Lleva tu documento de identidad.',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.verde),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón confirmar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verde,
                      disabledBackgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'CONFIRMAR COINCIDENCIA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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

    if (exito) {
      await _cargarReportes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coincidencia registrada y usuario notificado'),
          backgroundColor: AppColors.verde,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar la coincidencia'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/udea_bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.45)),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.transparent),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'REPORTES DE PÉRDIDA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Lista ───────────────────────────────────────────────
                  Expanded(
                    child: _cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _reportes.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay reportes de pérdida',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _reportes.length,
                                itemBuilder: (_, i) {
                                  final r = _reportes[i];
                                  final estado = r['idEstado'] as int;
                                  final pendiente =
                                      estado == Estados.reportePendiente;

                                  return FadeTransition(
                                    opacity: _fadeAnims[i],
                                    child: SlideTransition(
                                      position: _slideAnims[i],
                                      child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: _estadoColor(estado),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                r['correoUsuario'] ??
                                                    'Sin correo',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _estadoColor(estado)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _estadoColor(estado),
                                                ),
                                              ),
                                              child: Text(
                                                _estadoTexto(estado),
                                                style: TextStyle(
                                                  color: _estadoColor(estado),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          r['descripcionObjeto'] ??
                                              'Sin descripción',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Lugar: ${r['lugar'] ?? 'No especificado'}',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Fecha aprox: ${r['fechaAproxPerdida'] ?? 'No especificada'}',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13,
                                          ),
                                        ),

                                        if (pendiente) ...[
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _mostrarDialogoCoincidencia(
                                                      r),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                  color: AppColors.verde,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.link,
                                                color: AppColors.verde,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Encontré una coincidencia',
                                                style: TextStyle(
                                                  color: AppColors.verde,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}