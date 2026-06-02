import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../Repositories/objeto_repository.dart';
import 'solicitud_reclamo_page.dart';
import 'header_udea.dart';

class ObjetoDetailPage extends StatefulWidget {
  final int idObjeto;

  const ObjetoDetailPage({super.key, required this.idObjeto});

  @override
  State<ObjetoDetailPage> createState() => _ObjetoDetailPageState();
}

class _ObjetoDetailPageState extends State<ObjetoDetailPage>
    with SingleTickerProviderStateMixin {
  bool _esAdmin = false;
  Map<String, dynamic>? _objeto;
  bool _cargandoObjeto = true;

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

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _verificarRol();
    _cargarObjeto();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarObjeto() async {
    setState(() => _cargandoObjeto = true);

    final data = await ObjetoRepository.obtenerObjetoPorId(widget.idObjeto);

    if (!mounted) return;

    setState(() {
      _objeto = data;
      _cargandoObjeto = false;
    });

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error cargando detalle del objeto')),
      );
    }
  }

  Future<void> _verificarRol() async {
    final admin = await AuthService.esAdmin();
    if (mounted) setState(() => _esAdmin = admin);
  }

  bool _puedeOcultarPublicacion(Map<String, dynamic> objeto) {
    final idEstado = int.tryParse(
      (objeto['idEstado'] ?? objeto['id_estado'] ?? '').toString(),
    );

    final estado = (objeto['estado'] ?? '').toString().toLowerCase();

    return idEstado == 3 || estado == 'disponible';
  }

  Future<void> _ocultarPublicacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ocultar publicación'),
        content: const Text(
          '¿Seguro que quieres ocultar esta publicación? El objeto seguirá en inventario, pero ya no aparecerá disponible para reclamos.',
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
              'Ocultar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await ObjetoRepository.ocultarPublicacion(widget.idObjeto);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Publicación ocultada correctamente'
              : 'No se pudo ocultar la publicación',
        ),
      ),
    );

    if (ok) {
      await _cargarObjeto();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoObjeto) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.45)),
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A8F4D)),
            ),
          ],
        ),
      );
    }

    final objeto = _objeto ?? {};

    final categoria =
        (objeto['categoria'] ??
                objeto['tbl_categoria']?['nombre'] ??
                'Objeto encontrado')
            .toString();

    final descripcionGeneral =
        (objeto['descripcionGeneral'] ??
                objeto['descripcion_general'] ??
                'Sin descripción')
            .toString();

    final descripcionDetallada =
        (objeto['descripcionDetallada'] ??
                objeto['descripcion_detallada'] ??
                '')
            .toString();

    final fechaHallazgo =
        (objeto['fechaHallazgo'] ?? objeto['fecha_hallazgo'] ?? '').toString();

    final lugarEncontrado =
        (objeto['lugarEncontrado'] ??
                objeto['lugar_encontrado'] ??
                objeto['lugarEncontradoNombre'] ??
                'No registrado')
            .toString();

    final lugarActual =
        (objeto['lugarActual'] ??
                objeto['lugar_actual'] ??
                objeto['lugarActualNombre'] ??
                'No registrado')
            .toString();

    final fotoUrl =
        (objeto['fotografia'] ?? objeto['fotografiaUrl'] ?? '').toString();

    final nombre = (objeto['nombre'] ?? 'Sin nombre').toString();

    final estado = (objeto['estado'] ?? '').toString();

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
                      maxWidth: isWide ? 980 : 560,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 26 : 22,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(nombre: nombre),
                          const SizedBox(height: 20),
                          _ImageCard(fotoUrl: fotoUrl),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _Badge(
                                texto: categoria,
                                color: const Color(0xFF0A8F4D),
                                icono: Icons.category_outlined,
                              ),
                              if (_esAdmin && estado.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _Badge(
                                  texto: estado,
                                  color: const Color(0xFFD97706),
                                  icono: Icons.info_outline_rounded,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _TarjetaInfo(
                            titulo: 'Información general',
                            icono: Icons.info_outline_rounded,
                            color: const Color(0xFF0A8F4D),
                            children: [
                              _FilaInfo(
                                icono: Icons.category_outlined,
                                label: 'Tipo de objeto',
                                valor: categoria,
                              ),
                              _FilaInfo(
                                icono: Icons.description_outlined,
                                label: 'Descripción',
                                valor: descripcionGeneral,
                              ),
                              _FilaInfo(
                                icono: Icons.calendar_today_outlined,
                                label: 'Fecha del hallazgo',
                                valor: fechaHallazgo.isEmpty
                                    ? 'No registrada'
                                    : fechaHallazgo,
                              ),
                              if (_esAdmin) ...[
                                _FilaInfo(
                                  icono: Icons.location_on_outlined,
                                  label: 'Lugar encontrado',
                                  valor: lugarEncontrado,
                                ),
                                _FilaInfo(
                                  icono: Icons.place_outlined,
                                  label: 'Ubicación actual',
                                  valor: lugarActual,
                                ),
                              ] else
                                const _FilaInfo(
                                  icono: Icons.lock_outline_rounded,
                                  label: 'Ubicación de custodia',
                                  valor:
                                      'Disponible únicamente si tu solicitud de reclamo es aprobada.',
                                ),
                            ],
                          ),
                          if (_esAdmin) ...[
                            const SizedBox(height: 14),
                            _TarjetaInfo(
                              titulo: 'Información privada',
                              icono: Icons.lock_outline_rounded,
                              color: const Color(0xFFD97706),
                              children: [
                                _FilaInfo(
                                  icono: Icons.notes_rounded,
                                  label: 'Descripción detallada',
                                  valor: descripcionDetallada.isEmpty
                                      ? 'No registrada'
                                      : descripcionDetallada,
                                ),
                              ],
                            ),
                          ],
                          if (_esAdmin && _puedeOcultarPublicacion(objeto)) ...[
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _ocultarPublicacion,
                                icon: const Icon(
                                  Icons.visibility_off_outlined,
                                ),
                                label: const Text('Ocultar publicación'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  side: const BorderSide(
                                    color: Color(0xFFD97706),
                                  ),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.94),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (!_esAdmin) ...[
                            const SizedBox(height: 24),
                            const Text(
                              '¿ES TUYO ESTE OBJETO?',
                              style: TextStyle(
                                color: Color(0xFF9EF0C0),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _WhiteCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Si reconoces este objeto como tuyo, inicia una solicitud de reclamo. No se muestra la ubicación exacta para proteger el proceso de verificación.',
                                    style: TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 14,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SolicitudReclamoPage(
                                            objeto: objeto,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.handshake_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Reclamar este objeto',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0A8F4D),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
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
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String nombre;

  const _Header({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BotonVolver(onTap: () => Navigator.pop(context)),
        const SizedBox(width: 14),
        Expanded(
          child: HeaderUdea(
            titulo: 'Detalle del objeto',
            subtitulo: nombre,
            oscuro: true,
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String fotoUrl;

  const _ImageCard({required this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: double.infinity,
          height: 285,
          child: fotoUrl.isNotEmpty
              ? Image.network(
                  fotoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const _SinImagen(),
                )
              : const _SinImagen(),
        ),
      ),
    );
  }
}

class _TarjetaInfo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<Widget> children;

  const _TarjetaInfo({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(18),
      borderColor: color.withOpacity(0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                titulo.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: const Color(0xFF6B7280), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label\n',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: valor,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
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

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;

  const _Badge({
    required this.texto,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 12),
          const SizedBox(width: 5),
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

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const _WhiteCard({
    required this.child,
    required this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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

class _SinImagen extends StatelessWidget {
  const _SinImagen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 8),
          Text(
            'Sin fotografía',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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