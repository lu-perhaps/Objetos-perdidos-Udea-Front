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
        backgroundColor: const Color(0xFFDC2626),
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
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.verde,
                      strokeWidth: 2.5,
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 560 : 520,
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 24 : 22,
                          vertical: 18,
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
                                  const SizedBox(height: 28),
                                  const Text(
                                    'Reportar pérdida',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 31,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Registra la información del objeto que perdiste para que el administrador pueda ayudarte a encontrar coincidencias.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _WhiteCard(
                                    padding: const EdgeInsets.all(22),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _SectionTitle(
                                          titulo: 'Detalles del objeto',
                                          icono: Icons.article_outlined,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Describe el objeto perdido, el lugar donde crees que lo perdiste y la fecha aproximada.',
                                          style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 13,
                                            height: 1.45,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _CampoTexto(
                                          controller: _descripcionCtrl,
                                          label:
                                              'Descripción del objeto perdido',
                                          icono: Icons.description_outlined,
                                          maxLines: 4,
                                          validator: (v) {
                                            if (v == null ||
                                                v.trim().isEmpty) {
                                              return 'Describe el objeto perdido';
                                            }

                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        _DropdownLugar(
                                          value: _idLugar,
                                          lugares: _lugares,
                                          onChanged: (v) {
                                            setState(() => _idLugar = v);
                                          },
                                        ),
                                        const SizedBox(height: 14),
                                        GestureDetector(
                                          onTap: _seleccionarFecha,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 15,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: _fechaAproxPerdida !=
                                                        null
                                                    ? const Color(0xFF0A8F4D)
                                                        .withOpacity(0.42)
                                                    : const Color(0xFFE5E7EB),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  color: _fechaAproxPerdida !=
                                                          null
                                                      ? AppColors.verde
                                                      : const Color(0xFF6B7280),
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _fechaTexto(),
                                                    style: TextStyle(
                                                      color: _fechaAproxPerdida ==
                                                              null
                                                          ? const Color(
                                                              0xFF9CA3AF)
                                                          : const Color(
                                                              0xFF111827),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          _fechaAproxPerdida ==
                                                                  null
                                                              ? FontWeight.w600
                                                              : FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE1F5EE),
                                            borderRadius:
                                                BorderRadius.circular(13),
                                            border: Border.all(
                                              color: AppColors.verde
                                                  .withOpacity(0.20),
                                            ),
                                          ),
                                          child: const Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.privacy_tip_outlined,
                                                color: AppColors.verde,
                                                size: 17,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Esta información solo será revisada por administración para buscar posibles coincidencias.',
                                                  style: TextStyle(
                                                    color: Color(0xFF065F46),
                                                    fontSize: 12,
                                                    height: 1.35,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _enviando ? null : _enviar,
                                      icon: _enviando
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
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
                                            ? 'Enviando...'
                                            : 'Enviar reporte',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.verde,
                                        disabledBackgroundColor:
                                            AppColors.verde.withOpacity(0.45),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Center(
                                    child: Text(
                                      'UdeA 2024 · Objetos Perdidos',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              ),
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

class _HeaderReporte extends StatelessWidget {
  const _HeaderReporte();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BotonVolver(onTap: () => Navigator.pop(context)),
        const SizedBox(width: 14),
        const Expanded(
          child: HeaderUdea(
            titulo: 'Objetos Perdidos',
            subtitulo: 'Reportar pérdida',
            oscuro: true,
          ),
        ),
      ],
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final int maxLines;
  final String? Function(String?)? validator;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.icono,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: AppColors.verde,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
          child: Icon(
            icono,
            color: const Color(0xFF6B7280),
            size: 18,
          ),
        ),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.verde, width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownLugar extends StatelessWidget {
  final int? value;
  final List<Map<String, dynamic>> lugares;
  final ValueChanged<int?> onChanged;

  const _DropdownLugar({
    required this.value,
    required this.lugares,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = lugares.any(
      (lugar) => int.tryParse(lugar['id'].toString()) == value,
    )
        ? value
        : null;

    return DropdownButtonFormField<int>(
      value: validValue,
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: 'Lugar aproximado de pérdida',
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFF6B7280),
          size: 18,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.verde, width: 1.5),
        ),
      ),
      items: lugares
          .map(
            (lugar) => DropdownMenuItem<int>(
              value: int.tryParse(lugar['id'].toString()),
              child: Text(lugar['nombre'].toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String titulo;
  final IconData icono;

  const _SectionTitle({
    required this.titulo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          color: AppColors.verde,
          size: 15,
        ),
        const SizedBox(width: 8),
        Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            color: AppColors.verde,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BotonVolver extends StatelessWidget {
  final VoidCallback onTap;

  const _BotonVolver({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.75)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF111827),
          size: 18,
        ),
      ),
    );
  }
}