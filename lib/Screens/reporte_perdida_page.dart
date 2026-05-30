import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../Repositories/reporte_repository.dart';
import 'header_udea.dart';
import '../main.dart';

class ReportePerdidaPage extends StatefulWidget {
  const ReportePerdidaPage({super.key});

  @override
  State<ReportePerdidaPage> createState() => _ReportePerdidaPageState();
}

class _ReportePerdidaPageState extends State<ReportePerdidaPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();

  int? _idLugar;
  DateTime? _fechaAproxPerdida;
  bool _enviando = false;
  bool _cargando = true;

  List<Map<String, dynamic>> _lugares = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOut,
      ),
    );

    _cargarLugares();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarLugares() async {
    final data = await ReporteRepository.obtenerLugares();

    if (mounted) {
      setState(() {
        _lugares = data;
        _cargando = false;
      });
      _animCtrl.forward();
    }
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: hoy,
      firstDate: DateTime(2020),
      lastDate: hoy,
      locale: const Locale('es', 'CO'),
    );

    if (fecha != null) {
      setState(() => _fechaAproxPerdida = fecha);
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idLugar == null) {
      _mostrarError('Selecciona el lugar aproximado de pérdida');
      return;
    }

    if (_fechaAproxPerdida == null) {
      _mostrarError('Selecciona la fecha aproximada de pérdida');
      return;
    }

    setState(() => _enviando = true);

    final user = supabase.auth.currentUser;

    if (user == null || user.email == null) {
      _mostrarError('No se pudo obtener el usuario');
      if (mounted) setState(() => _enviando = false);
      return;
    }

    final exito = await ReporteRepository.crearReporte(
      correoUsuario: user.email!,
      descripcionObjeto: _descripcionCtrl.text.trim(),
      idLugarAproxPerdida: _idLugar!,
      fechaAproxPerdida: _fechaAproxPerdida!,
    );

    if (!mounted) return;

    setState(() => _enviando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado correctamente'),
          backgroundColor: AppColors.verde,
        ),
      );
      Navigator.pop(context);
    } else {
      _mostrarError('Error al enviar el reporte. Intenta de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _fechaTexto() {
    if (_fechaAproxPerdida == null) return 'Fecha aproximada de pérdida';

    final f = _fechaAproxPerdida!;
    return '${f.day.toString().padLeft(2, '0')}/'
        '${f.month.toString().padLeft(2, '0')}/'
        '${f.year}';
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
                  Color(0xDD03140B),
                  Color(0xF0011208),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.verde,
                      strokeWidth: 2,
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? size.width * 0.22 : 20,
                      vertical: 16,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _HeaderReporte(),
                              const SizedBox(height: 22),
                              _GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DETALLES DEL OBJETO',
                                      style: TextStyle(
                                        color: AppColors.verde,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Describe el objeto perdido, el lugar donde crees que lo perdiste y la fecha aproximada.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 22),

                                    _CampoGlass(
                                      child: TextFormField(
                                        controller: _descripcionCtrl,
                                        maxLines: 4,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        validator: (v) {
                                          if (v == null ||
                                              v.trim().isEmpty) {
                                            return 'Describe el objeto perdido';
                                          }
                                          return null;
                                        },
                                        decoration: _inputDecoration(
                                          label:
                                              'Descripción del objeto perdido',
                                          icono: Icons.description_outlined,
                                          alignLabel: true,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    _CampoGlass(
                                      child: DropdownButtonFormField<int>(
                                        value: _idLugar,
                                        dropdownColor:
                                            const Color(0xFF0D1F16),
                                        iconEnabledColor: Colors.white54,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        decoration: _inputDecoration(
                                          label:
                                              'Lugar aproximado de pérdida',
                                          icono: Icons.location_on_outlined,
                                        ),
                                        items: _lugares.map((lugar) {
                                          return DropdownMenuItem<int>(
                                            value: lugar['id'] as int,
                                            child: Text(
                                              lugar['nombre'].toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (v) {
                                          setState(() => _idLugar = v);
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    GestureDetector(
                                      onTap: _seleccionarFecha,
                                      child: _CampoGlass(
                                        activo:
                                            _fechaAproxPerdida != null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                color: _fechaAproxPerdida !=
                                                        null
                                                    ? AppColors.verde
                                                    : Colors.white38,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _fechaTexto(),
                                                  style: TextStyle(
                                                    color:
                                                        _fechaAproxPerdida ==
                                                                null
                                                            ? Colors.white38
                                                            : Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                color: Colors.white24,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 28),

                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _enviando ? null : _enviar,
                                        icon: _enviando
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                        label: Text(
                                          _enviando
                                              ? 'ENVIANDO...'
                                              : 'ENVIAR REPORTE',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.verde,
                                          disabledBackgroundColor:
                                              Colors.white.withOpacity(0.15),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Text(
                                  'UdeA 2024 · Objetos Perdidos',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.22),
                                    fontSize: 11,
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
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icono,
    bool alignLabel = false,
  }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabel,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icono,
        color: Colors.white38,
        size: 18,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFFF6B6B),
        fontSize: 12,
      ),
    );
  }
}

class _HeaderReporte extends StatelessWidget {
  const _HeaderReporte();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BotonVolver(onTap: () => Navigator.pop(context)),
        const SizedBox(width: 12),
        const Expanded(child: HeaderUdea(titulo: 'Reportar pérdida')),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CampoGlass extends StatelessWidget {
  final Widget child;
  final bool activo;

  const _CampoGlass({
    required this.child,
    this.activo = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: activo
                  ? AppColors.verde.withOpacity(0.45)
                  : Colors.white.withOpacity(0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BotonVolver extends StatelessWidget {
  final VoidCallback onTap;

  const _BotonVolver({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
    );
  }
}