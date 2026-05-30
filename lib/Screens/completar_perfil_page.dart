import 'dart:ui';
import 'package:flutter/material.dart';
import '../Constants/app_colors.dart';
import '../Repositories/persona_repository.dart';
import '../main.dart';
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
      final data =
          await supabase.from('tbl_tipo_documento').select('id, nombre');
      setState(() {
        _tiposDocumento = List<Map<String, dynamic>>.from(data);
        _cargandoTipos = false;
      });
    } catch (e) {
      setState(() => _cargandoTipos = false);
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
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } else {
      _mostrarSnack('Error al guardar. Intenta de nuevo.', esError: true);
    }
  }

  void _mostrarSnack(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline_rounded : Icons.check_circle_outline,
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
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo UdeA ─────────────────────────────────────────────
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),

          // ── Overlay gradiente ───────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBB000000),
                  Color(0xDD011208),
                ],
              ),
            ),
          ),

          // ── Blur ────────────────────────────────────────────────────
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const SizedBox.expand(),
          ),

          // ── Contenido ───────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.28 : 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header con logo ──────────────────────────
                        Row(
                          children: const [
                            Expanded(child: HeaderUdea(titulo: 'Objetos Perdidos')),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── Título ───────────────────────────────────
                        const Text(
                          'Completa tu perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Necesitamos estos datos para procesar tus solicitudes de reclamo.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Card glassmorphism con formulario ─────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Nombre ───────────────────────
                                  _LabelCampo(texto: 'NOMBRE COMPLETO'),
                                  const SizedBox(height: 6),
                                  _Campo(
                                    ctrl: _nombreCtrl,
                                    hint: 'Ej. Juan Pérez García',
                                    icono: Icons.person_outline_rounded,
                                    tipo: TextInputType.name,
                                  ),

                                  const SizedBox(height: 18),

                                  // ── Celular ──────────────────────
                                  _LabelCampo(texto: 'CELULAR'),
                                  const SizedBox(height: 6),
                                  _Campo(
                                    ctrl: _celularCtrl,
                                    hint: '300 000 0000',
                                    icono: Icons.phone_outlined,
                                    tipo: TextInputType.phone,
                                  ),

                                  const SizedBox(height: 18),

                                  // ── Tipo documento ────────────────
                                  _LabelCampo(texto: 'TIPO DE DOCUMENTO'),
                                  const SizedBox(height: 6),
                                  _cargandoTipos
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                              color: AppColors.verde,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : _DropdownDocumento(
                                          value: _idTipoDocumento,
                                          items: _tiposDocumento,
                                          onChanged: (v) => setState(
                                              () => _idTipoDocumento = v),
                                        ),

                                  const SizedBox(height: 18),

                                  // ── Número documento ──────────────
                                  _LabelCampo(texto: 'NÚMERO DE DOCUMENTO'),
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
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Botón guardar ────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _guardando ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.verde,
                              disabledBackgroundColor:
                                  AppColors.verde.withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              shadowColor:
                                  AppColors.verde.withOpacity(0.4),
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
                                          fontWeight: FontWeight.w700,
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

                        // ── Nota seguridad ───────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white38,
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Tus datos están protegidos por UdeA',
                              style: TextStyle(
                                color: Colors.white38,
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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

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
        fontWeight: FontWeight.w700,
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: AppColors.verde,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        prefixIcon: Icon(icono, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.verde, width: 1.5),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          dropdownColor: const Color(0xFF0D2A1A),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          isExpanded: true,
          iconEnabledColor: Colors.white54,
          hint: Text(
            'Selecciona un tipo',
            style: TextStyle(color: Colors.white.withOpacity(0.25)),
          ),
          items: items
              .map((t) => DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Text(t['nombre'].toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}