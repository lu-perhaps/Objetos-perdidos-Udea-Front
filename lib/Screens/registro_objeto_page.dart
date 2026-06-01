import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../Repositories/objeto_repository.dart';
import '../Repositories/persona_repository.dart';
import 'header_udea.dart';

class RegistroObjetoPage extends StatefulWidget {
  const RegistroObjetoPage({super.key});

  @override
  State<RegistroObjetoPage> createState() => _RegistroObjetoPageState();
}

class _RegistroObjetoPageState extends State<RegistroObjetoPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descGeneralCtrl = TextEditingController();
  final _descDetalladaCtrl = TextEditingController();

  int? _idCategoria;
  int? _idLugarEncontrado;
  int? _idLugarActual;
  DateTime? _fechaHallazgo;
  bool _publicar = true;
  bool _guardando = false;

  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes;

  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _lugares = [];
  bool _cargando = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _cargarDatos();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nombreCtrl.dispose();
    _descGeneralCtrl.dispose();
    _descDetalladaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final categorias = await ObjetoRepository.obtenerCategorias();
    final lugares = await ObjetoRepository.obtenerLugares();
    if (mounted) {
      setState(() {
        _categorias = categorias;
        _lugares = lugares;
        _cargando = false;
      });
      _animCtrl.forward();
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final opcion = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0D1F16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seleccionar imagen',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _OpcionImagen(
              icono: Icons.photo_library_outlined,
              texto: 'Desde la galería',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            _OpcionImagen(
              icono: Icons.camera_alt_outlined,
              texto: 'Tomar foto',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (opcion == null) return;

    final imagen = await picker.pickImage(
      source: opcion,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      setState(() {
        _imagenSeleccionada = imagen;
        _imagenBytes = bytes;
      });
    }
  }

  Future<String?> _subirImagen(int idObjeto) async {
    if (_imagenSeleccionada == null || _imagenBytes == null) return null;

    try {
      final nombreArchivo = _imagenSeleccionada!.name.toLowerCase();

      String extension = 'jpg';

      if (nombreArchivo.endsWith('.png')) {
        extension = 'png';
      } else if (nombreArchivo.endsWith('.webp')) {
        extension = 'webp';
      } else if (nombreArchivo.endsWith('.jpeg')) {
        extension = 'jpeg';
      } else if (nombreArchivo.endsWith('.jpg')) {
        extension = 'jpg';
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ruta = 'objetos/$idObjeto-$timestamp.$extension';

      await ObjetoRepository.subirImagenBytes(
        rutaStorage: ruta,
        bytes: _imagenBytes!,
        nombreArchivo: _imagenSeleccionada!.name,
      );

      return ObjetoRepository.obtenerUrlPublica(ruta);
    } catch (e) {
      debugPrint('ERROR subiendo imagen: $e');
      return null;
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
    if (fecha != null) setState(() => _fechaHallazgo = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCategoria == null) {
      _mostrarError('Selecciona una categoría');
      return;
    }
    if (_idLugarEncontrado == null) {
      _mostrarError('Selecciona el lugar donde fue encontrado');
      return;
    }
    if (_idLugarActual == null) {
      _mostrarError('Selecciona el lugar actual del objeto');
      return;
    }
    if (_fechaHallazgo == null) {
      _mostrarError('Selecciona la fecha de hallazgo');
      return;
    }

    setState(() => _guardando = true);

    final idPersona = await PersonaRepository.obtenerIdPersonaActual();
    if (idPersona == null) {
      _mostrarError('No se pudo obtener el usuario actual');
      setState(() => _guardando = false);
      return;
    }

    final idObjeto = await ObjetoRepository.registrarObjeto(
      nombre: _nombreCtrl.text.trim(),
      descripcionGeneral: _descGeneralCtrl.text.trim(),
      descripcionDetallada: _descDetalladaCtrl.text.trim(),
      idCategoria: _idCategoria!,
      idLugarEncontrado: _idLugarEncontrado!,
      idLugarActual: _idLugarActual!,
      fechaHallazgo: _fechaHallazgo!,
      fotografia: null,
      publicar: _publicar,
      idPersonaAdmin: idPersona,
    );

    if (idObjeto == null) {
      _mostrarError('Error al guardar el objeto. Intenta de nuevo.');
      setState(() => _guardando = false);
      return;
    }

    if (_imagenSeleccionada != null) {
      final url = await _subirImagen(idObjeto);
      if (url != null) {
        await ObjetoRepository.actualizarFotografia(
            idObjeto: idObjeto, url: url);
      }
    }

    setState(() => _guardando = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _publicar
              ? 'Objeto registrado y publicado correctamente'
              : 'Objeto registrado en custodia',
        ),
        backgroundColor: AppColors.verde,
      ),
    );
    Navigator.pop(context, true);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
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
          // ── Fondo ────────────────────────────────────────────────
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBB000000),
                  Color(0xCC021008),
                  Color(0xEE011208),
                ],
                stops: [0.0, 0.5, 1.0],
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
                      color: Color(0xFF0A8F4D),
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
                          // ── Header ──────────────────────────────
                          Row(
                            children: [
                              _BotonVolver(onTap: () => Navigator.pop(context)),
                              const SizedBox(width: 12),
                              const Expanded(child: HeaderUdea(titulo: 'Registrar objeto')),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── Sección imagen ───────────────────────
                          const Text(
                            'SUBIR FOTOGRAFÍA',
                            style: TextStyle(
                              color: Color(0xFF0A8F4D),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _seleccionarImagen,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: double.infinity,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: _imagenBytes != null
                                          ? const Color(0xFF0A8F4D)
                                              .withOpacity(0.6)
                                          : Colors.white.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _imagenBytes != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(17),
                                          child: Image.memory(
                                            _imagenBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0A8F4D)
                                                    .withOpacity(0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add_a_photo_outlined,
                                                color: Color(0xFF0A8F4D),
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Toca para agregar foto',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Mínimo 1 foto, máximo 3',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.25),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          if (_imagenBytes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () => setState(() {
                                  _imagenSeleccionada = null;
                                  _imagenBytes = null;
                                }),
                                icon: const Icon(Icons.close_rounded,
                                    color: Colors.red, size: 16),
                                label: const Text(
                                  'Quitar imagen',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // ── Detalles generales ───────────────────
                          const Text(
                            'DETALLES GENERALES',
                            style: TextStyle(
                              color: Color(0xFF0A8F4D),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _CampoGlass(
                            child: TextFormField(
                              controller: _nombreCtrl,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Campo requerido'
                                  : null,
                              decoration: _inputDeco(
                                label: 'Nombre del objeto',
                                icono: Icons.label_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CampoGlass(
                            child: TextFormField(
                              controller: _descGeneralCtrl,
                              maxLines: 3,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Campo requerido'
                                  : null,
                              decoration: _inputDeco(
                                label: 'Descripción pública (visible)',
                                icono: Icons.description_outlined,
                                alignHint: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CampoGlass(
                            child: TextFormField(
                              controller: _descDetalladaCtrl,
                              maxLines: 3,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: _inputDeco(
                                label: 'Descripción detallada (privada)',
                                icono: Icons.lock_outline_rounded,
                                alignHint: true,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Ubicación y categoría ────────────────
                          const Text(
                            'UBICACIÓN Y CATEGORÍA',
                            style: TextStyle(
                              color: Color(0xFF0A8F4D),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _CampoGlass(
                            child: DropdownButtonFormField<int>(
                              value: _idCategoria,
                              dropdownColor: const Color(0xFF0D1F16),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: _inputDeco(
                                label: 'Tipo de objeto',
                                icono: Icons.category_outlined,
                              ),
                              items: _categorias
                                  .map((c) => DropdownMenuItem<int>(
                                        value: c['id'] as int,
                                        child: Text(c['nombre'].toString()),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _idCategoria = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CampoGlass(
                            child: DropdownButtonFormField<int>(
                              value: _idLugarEncontrado,
                              dropdownColor: const Color(0xFF0D1F16),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: _inputDeco(
                                label: 'Lugar donde fue encontrado',
                                icono: Icons.place_outlined,
                              ),
                              items: _lugares
                                  .map((l) => DropdownMenuItem<int>(
                                        value: l['id'] as int,
                                        child: Text(l['nombre'].toString()),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _idLugarEncontrado = v),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CampoGlass(
                            child: DropdownButtonFormField<int>(
                              value: _idLugarActual,
                              dropdownColor: const Color(0xFF0D1F16),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: _inputDeco(
                                label: 'Lugar actual / custodia',
                                icono: Icons.store_outlined,
                              ),
                              items: _lugares
                                  .map((l) => DropdownMenuItem<int>(
                                        value: l['id'] as int,
                                        child: Text(l['nombre'].toString()),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _idLugarActual = v),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Fecha hallazgo ───────────────────────
                          GestureDetector(
                            onTap: _seleccionarFecha,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _fechaHallazgo != null
                                          ? const Color(0xFF0A8F4D)
                                              .withOpacity(0.5)
                                          : Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        color: _fechaHallazgo != null
                                            ? const Color(0xFF0A8F4D)
                                            : Colors.white38,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _fechaHallazgo == null
                                              ? 'Fecha de hallazgo'
                                              : '${_fechaHallazgo!.day.toString().padLeft(2, '0')}/${_fechaHallazgo!.month.toString().padLeft(2, '0')}/${_fechaHallazgo!.year}',
                                          style: TextStyle(
                                            color: _fechaHallazgo == null
                                                ? Colors.white38
                                                : Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded,
                                          color: Colors.white24, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Toggle publicar ──────────────────────
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _publicar
                                        ? const Color(0xFF0A8F4D)
                                            .withOpacity(0.35)
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _publicar
                                            ? const Color(0xFF0A8F4D)
                                                .withOpacity(0.15)
                                            : Colors.white.withOpacity(0.05),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _publicar
                                            ? Icons.public_rounded
                                            : Icons.public_off_rounded,
                                        color: _publicar
                                            ? const Color(0xFF0A8F4D)
                                            : Colors.white38,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Publicar objeto',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            _publicar
                                                ? 'Visible para todos los usuarios'
                                                : 'Solo en custodia interna',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.4),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _publicar,
                                      onChanged: (v) =>
                                          setState(() => _publicar = v),
                                      activeColor: const Color(0xFF0A8F4D),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Botón guardar ────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _guardando ? null : _guardar,
                              icon: _guardando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                              label: Text(
                                _guardando
                                    ? 'GUARDANDO...'
                                    : 'GUARDAR OBJETO',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A8F4D),
                                disabledBackgroundColor:
                                    Colors.white.withOpacity(0.15),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              'UdeA 2024 · Panel Seguro',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.2),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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

  InputDecoration _inputDeco({
    required String label,
    required IconData icono,
    bool alignHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
      prefixIcon: Icon(icono, color: Colors.white38, size: 18),
      alignLabelWithHint: alignHint,
      border: InputBorder.none,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Campo glassmorphism ───────────────────────────────────────────────────────
class _CampoGlass extends StatelessWidget {
  final Widget child;
  const _CampoGlass({required this.child});

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
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Opción imagen (bottom sheet) ──────────────────────────────────────────────
class _OpcionImagen extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _OpcionImagen({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF0A8F4D).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, color: const Color(0xFF0A8F4D), size: 20),
      ),
      title: Text(
        texto,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

// ── Botón volver ──────────────────────────────────────────────────────────────
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
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}