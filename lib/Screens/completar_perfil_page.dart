import 'dart:ui';
import 'package:flutter/material.dart';

import '../Constants/app_colors.dart';
import '../Repositories/persona_repository.dart';
import '../main.dart';
import 'auth_gate.dart';
import 'header_udea.dart';

class CompletarPerfilPage extends StatefulWidget {
  const CompletarPerfilPage({super.key});

  @override
  State<CompletarPerfilPage> createState() => _CompletarPerfilPageState();
}

class _CompletarPerfilPageState extends State<CompletarPerfilPage>
    with SingleTickerProviderStateMixin {
  final _nombreCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();

  int? _idTipoDocumento;
  List<Map<String, dynamic>> _tiposDocumento = [];

  bool _guardando = false;
  bool _cargandoTipos = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _cargarTiposDocumento();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nombreCtrl.dispose();
    _celularCtrl.dispose();
    _documentoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTiposDocumento() async {
    try {
      final data = await supabase
          .from('tbl_tipo_documento')
          .select('id, nombre')
          .order('id');

      if (!mounted) return;

      setState(() {
        _tiposDocumento = List<Map<String, dynamic>>.from(data);
        _cargandoTipos = false;
      });
    } catch (e) {
      debugPrint('ERROR cargar tipos documento: $e');
      if (!mounted) return;
      setState(() => _cargandoTipos = false);
      _mostrarSnack(
        'No se pudieron cargar los tipos de documento.',
        esError: true,
      );
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final celular = _celularCtrl.text.trim();
    final documento = _documentoCtrl.text.trim();

    if (nombre.isEmpty ||
        celular.isEmpty ||
        documento.isEmpty ||
        _idTipoDocumento == null) {
      _mostrarSnack('Por favor completa todos los campos.', esError: true);
      return;
    }

    setState(() => _guardando = true);

    final ok = await PersonaRepository.actualizarPerfil(
      nombre: nombre,
      celular: celular,
      numDocumento: documento,
      idTipoDocumento: _idTipoDocumento!,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } else {
      _mostrarSnack('Error al guardar. Intenta de nuevo.', esError: true);
    }
  }

  void _mostrarSnack(String mensaje, {bool esError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: esError ? Colors.red.shade700 : AppColors.verde,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 760;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.3, sigmaY: 1.3),
            child: const SizedBox.expand(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.56),
                  Colors.black.withOpacity(0.38),
                  const Color(0xFF0A3D24).withOpacity(0.32),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.30 : 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HeaderUdeaAdmin(
                          titulo: 'Objetos Perdidos',
                          subtitulo: 'Perfil institucional',
                          oscuro: true,
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          'Completa tu perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Necesitamos estos datos para procesar tus solicitudes de reclamo.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.75),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.22),
                                blurRadius: 28,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _LabelCampo(texto: 'NOMBRE COMPLETO'),
                              const SizedBox(height: 6),
                              _Campo(
                                ctrl: _nombreCtrl,
                                hint: 'Ej. Juan Pérez García',
                                icono: Icons.person_outline_rounded,
                                tipo: TextInputType.name,
                              ),
                              const SizedBox(height: 20),
                              const _LabelCampo(texto: 'CELULAR'),
                              const SizedBox(height: 6),
                              _Campo(
                                ctrl: _celularCtrl,
                                hint: '300 000 0000',
                                icono: Icons.phone_outlined,
                                tipo: TextInputType.phone,
                              ),
                              const SizedBox(height: 20),
                              const _LabelCampo(texto: 'TIPO DE DOCUMENTO'),
                              const SizedBox(height: 6),
                              _cargandoTipos
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF0A8F4D),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : _DropdownDocumento(
                                      value: _idTipoDocumento,
                                      items: _tiposDocumento,
                                      onChanged: (v) => setState(
                                        () => _idTipoDocumento = v,
                                      ),
                                    ),
                              const SizedBox(height: 20),
                              const _LabelCampo(texto: 'NÚMERO DE DOCUMENTO'),
                              const SizedBox(height: 6),
                              _Campo(
                                ctrl: _documentoCtrl,
                                hint: '1 000 000 000',
                                icono: Icons.badge_outlined,
                                tipo: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _guardando ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A8F4D),
                              disabledBackgroundColor:
                                  const Color(0xFF0A8F4D).withOpacity(0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _guardando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Guardar y continuar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white70,
                              size: 13,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tus datos están protegidos por UdeA',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
}

class _LabelCampo extends StatelessWidget {
  final String texto;

  const _LabelCampo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF0A8F4D),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icono;
  final TextInputType tipo;

  const _Campo({
    required this.ctrl,
    required this.hint,
    required this.icono,
    this.tipo = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 15,
      ),
      cursorColor: const Color(0xFF0A8F4D),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: Icon(icono, color: const Color(0xFF6B7280), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A8F4D), width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownDocumento extends StatelessWidget {
  final int? value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<int?> onChanged;

  const _DropdownDocumento({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = items.any(
      (item) => int.tryParse(item['id'].toString()) == value,
    )
        ? value
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: validValue,
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 15,
          ),
          isExpanded: true,
          iconEnabledColor: const Color(0xFF6B7280),
          hint: const Text(
            'Selecciona un tipo',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
          items: items
              .map(
                (t) => DropdownMenuItem<int>(
                  value: int.tryParse(t['id'].toString()),
                  child: Text(t['nombre'].toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}