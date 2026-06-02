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
      duration: const Duration(milliseconds: 800),
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
      backgroundColor: const Color(0xFFF9FAFB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Agrega una fotografía clara del objeto encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              _OpcionImagen(
                icono: Icons.photo_library_outlined,
                texto: 'Desde la galería',
                subtitulo: 'Elegir una imagen guardada',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              _OpcionImagen(
                icono: Icons.camera_alt_outlined,
                texto: 'Tomar foto',
                subtitulo: 'Usar cámara del dispositivo',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
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

    if (fecha != null) {
      setState(() => _fechaHallazgo = fecha);
    }
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
          idObjeto: idObjeto,
          url: url,
        );
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
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  String _fechaTexto() {
    if (_fechaHallazgo == null) return 'Fecha de hallazgo';

    return '${_fechaHallazgo!.day.toString().padLeft(2, '0')}/'
        '${_fechaHallazgo!.month.toString().padLeft(2, '0')}/'
        '${_fechaHallazgo!.year}';
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
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0A8F4D),
                      strokeWidth: 2.5,
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 26 : 22,
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
                                  _HeaderRegistro(
                                    onVolver: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(height: 28),
                                  const Text(
                                    'Registrar objeto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 31,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Completa la información del objeto encontrado. La descripción detallada y la ubicación exacta son privadas para administración.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  isWide
                                      ? Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 4,
                                              child: Column(
                                                children: [
                                                  _ImagenCard(
                                                    imagenBytes: _imagenBytes,
                                                    onTap: _seleccionarImagen,
                                                    onRemove: () {
                                                      setState(() {
                                                        _imagenSeleccionada =
                                                            null;
                                                        _imagenBytes = null;
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  _PublicacionCard(
                                                    publicar: _publicar,
                                                    onChanged: (v) {
                                                      setState(
                                                        () => _publicar = v,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 18),
                                            Expanded(
                                              flex: 6,
                                              child: _FormularioCard(
                                                nombreCtrl: _nombreCtrl,
                                                descGeneralCtrl:
                                                    _descGeneralCtrl,
                                                descDetalladaCtrl:
                                                    _descDetalladaCtrl,
                                                categorias: _categorias,
                                                lugares: _lugares,
                                                idCategoria: _idCategoria,
                                                idLugarEncontrado:
                                                    _idLugarEncontrado,
                                                idLugarActual: _idLugarActual,
                                                fechaTexto: _fechaTexto(),
                                                fechaSeleccionada:
                                                    _fechaHallazgo != null,
                                                onCategoriaChanged: (v) {
                                                  setState(
                                                      () => _idCategoria = v);
                                                },
                                                onLugarEncontradoChanged: (v) {
                                                  setState(
                                                    () => _idLugarEncontrado =
                                                        v,
                                                  );
                                                },
                                                onLugarActualChanged: (v) {
                                                  setState(
                                                      () => _idLugarActual = v);
                                                },
                                                onFechaTap: _seleccionarFecha,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            _ImagenCard(
                                              imagenBytes: _imagenBytes,
                                              onTap: _seleccionarImagen,
                                              onRemove: () {
                                                setState(() {
                                                  _imagenSeleccionada = null;
                                                  _imagenBytes = null;
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 16),
                                            _FormularioCard(
                                              nombreCtrl: _nombreCtrl,
                                              descGeneralCtrl:
                                                  _descGeneralCtrl,
                                              descDetalladaCtrl:
                                                  _descDetalladaCtrl,
                                              categorias: _categorias,
                                              lugares: _lugares,
                                              idCategoria: _idCategoria,
                                              idLugarEncontrado:
                                                  _idLugarEncontrado,
                                              idLugarActual: _idLugarActual,
                                              fechaTexto: _fechaTexto(),
                                              fechaSeleccionada:
                                                  _fechaHallazgo != null,
                                              onCategoriaChanged: (v) {
                                                setState(
                                                    () => _idCategoria = v);
                                              },
                                              onLugarEncontradoChanged: (v) {
                                                setState(
                                                  () =>
                                                      _idLugarEncontrado = v,
                                                );
                                              },
                                              onLugarActualChanged: (v) {
                                                setState(
                                                    () => _idLugarActual = v);
                                              },
                                              onFechaTap: _seleccionarFecha,
                                            ),
                                            const SizedBox(height: 16),
                                            _PublicacionCard(
                                              publicar: _publicar,
                                              onChanged: (v) {
                                                setState(
                                                    () => _publicar = v);
                                              },
                                            ),
                                          ],
                                        ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
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
                                              size: 19,
                                            ),
                                      label: Text(
                                        _guardando
                                            ? 'Guardando...'
                                            : 'Guardar objeto',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0A8F4D),
                                        disabledBackgroundColor:
                                            const Color(0xFF0A8F4D)
                                                .withOpacity(0.45),
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
                                      'UdeA 2024 · Panel Seguro',
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

class _HeaderRegistro extends StatelessWidget {
  final VoidCallback onVolver;

  const _HeaderRegistro({
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BotonVolver(onTap: onVolver),
        const SizedBox(width: 14),
        const Expanded(
          child: HeaderUdea(
            titulo: 'Panel Administrativo',
            subtitulo: 'Registro de objetos',
            oscuro: true,
          ),
        ),
      ],
    );
  }
}

class _ImagenCard extends StatelessWidget {
  final Uint8List? imagenBytes;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImagenCard({
    required this.imagenBytes,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      borderColor: imagenBytes != null
          ? const Color(0xFF0A8F4D).withOpacity(0.25)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            titulo: 'Fotografía',
            icono: Icons.add_a_photo_outlined,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: imagenBytes != null
                      ? const Color(0xFF0A8F4D).withOpacity(0.35)
                      : const Color(0xFFE5E7EB),
                  width: 1.4,
                ),
              ),
              child: imagenBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.memory(
                        imagenBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: Color(0xFF0A8F4D),
                          size: 36,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Toca para agregar foto',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Imagen clara del objeto encontrado',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (imagenBytes != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Quitar imagen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormularioCard extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final TextEditingController descGeneralCtrl;
  final TextEditingController descDetalladaCtrl;
  final List<Map<String, dynamic>> categorias;
  final List<Map<String, dynamic>> lugares;
  final int? idCategoria;
  final int? idLugarEncontrado;
  final int? idLugarActual;
  final String fechaTexto;
  final bool fechaSeleccionada;
  final ValueChanged<int?> onCategoriaChanged;
  final ValueChanged<int?> onLugarEncontradoChanged;
  final ValueChanged<int?> onLugarActualChanged;
  final VoidCallback onFechaTap;

  const _FormularioCard({
    required this.nombreCtrl,
    required this.descGeneralCtrl,
    required this.descDetalladaCtrl,
    required this.categorias,
    required this.lugares,
    required this.idCategoria,
    required this.idLugarEncontrado,
    required this.idLugarActual,
    required this.fechaTexto,
    required this.fechaSeleccionada,
    required this.onCategoriaChanged,
    required this.onLugarEncontradoChanged,
    required this.onLugarActualChanged,
    required this.onFechaTap,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            titulo: 'Detalles generales',
            icono: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 14),
          _CampoTexto(
            controller: nombreCtrl,
            label: 'Nombre del objeto',
            icono: Icons.label_outline_rounded,
            validator: (v) => v!.trim().isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          _CampoTexto(
            controller: descGeneralCtrl,
            label: 'Descripción pública visible',
            icono: Icons.description_outlined,
            maxLines: 3,
            validator: (v) => v!.trim().isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          _CampoTexto(
            controller: descDetalladaCtrl,
            label: 'Descripción detallada privada',
            icono: Icons.lock_outline_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            titulo: 'Ubicación y categoría',
            icono: Icons.place_outlined,
          ),
          const SizedBox(height: 14),
          _DropdownCampo(
            label: 'Tipo de objeto',
            icono: Icons.category_outlined,
            value: idCategoria,
            items: categorias,
            onChanged: onCategoriaChanged,
          ),
          const SizedBox(height: 12),
          _DropdownCampo(
            label: 'Lugar donde fue encontrado',
            icono: Icons.location_on_outlined,
            value: idLugarEncontrado,
            items: lugares,
            onChanged: onLugarEncontradoChanged,
          ),
          const SizedBox(height: 12),
          _DropdownCampo(
            label: 'Lugar actual / custodia',
            icono: Icons.store_outlined,
            value: idLugarActual,
            items: lugares,
            onChanged: onLugarActualChanged,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onFechaTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: fechaSeleccionada
                      ? const Color(0xFF0A8F4D).withOpacity(0.42)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: fechaSeleccionada
                        ? const Color(0xFF0A8F4D)
                        : const Color(0xFF6B7280),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fechaTexto,
                      style: TextStyle(
                        color: fechaSeleccionada
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                        fontSize: 14,
                        fontWeight:
                            fechaSeleccionada ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 20,
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

class _PublicacionCard extends StatelessWidget {
  final bool publicar;
  final ValueChanged<bool> onChanged;

  const _PublicacionCard({
    required this.publicar,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(16),
      borderColor: publicar
          ? const Color(0xFF0A8F4D).withOpacity(0.25)
          : const Color(0xFFD97706).withOpacity(0.25),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: publicar
                  ? const Color(0xFFE1F5EE)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              publicar ? Icons.public_rounded : Icons.public_off_rounded,
              color: publicar
                  ? const Color(0xFF0A8F4D)
                  : const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publicar objeto',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  publicar
                      ? 'Visible para usuarios, sin mostrar ubicación exacta.'
                      : 'Solo quedará en custodia interna.',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: publicar,
            onChanged: onChanged,
            activeColor: const Color(0xFF0A8F4D),
          ),
        ],
      ),
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
      cursorColor: const Color(0xFF0A8F4D),
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
          borderSide: const BorderSide(color: Color(0xFF0A8F4D), width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownCampo extends StatelessWidget {
  final String label;
  final IconData icono;
  final int? value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<int?> onChanged;

  const _DropdownCampo({
    required this.label,
    required this.icono,
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

    return DropdownButtonFormField<int>(
      value: validValue,
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icono,
          color: const Color(0xFF6B7280),
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
          borderSide: const BorderSide(color: Color(0xFF0A8F4D), width: 1.5),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: int.tryParse(item['id'].toString()),
              child: Text(item['nombre'].toString()),
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
          color: const Color(0xFF0A8F4D),
          size: 15,
        ),
        const SizedBox(width: 8),
        Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF0A8F4D),
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

class _OpcionImagen extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String subtitulo;
  final VoidCallback onTap;

  const _OpcionImagen({
    required this.icono,
    required this.texto,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icono,
                color: const Color(0xFF0A8F4D),
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
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