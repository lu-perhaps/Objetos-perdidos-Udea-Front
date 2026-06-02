import 'dart:ui';
import 'package:flutter/material.dart';

import '../Constants/estados.dart';
import '../Repositories/objeto_repository.dart';
import 'objeto_detail_page.dart';

class ObjetosAdminPage extends StatefulWidget {
  const ObjetosAdminPage({super.key});

  @override
  State<ObjetosAdminPage> createState() => _ObjetosAdminPageState();
}

class _ObjetosAdminPageState extends State<ObjetosAdminPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> objetos = [];
  bool cargando = true;
  String busqueda = '';

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
    cargarObjetos();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarObjetos() async {
    try {
      final data = await ObjetoRepository.obtenerObjetosAdmin();

      if (!mounted) return;

      setState(() {
        objetos = data;
        cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR CARGANDO INVENTARIO ADMIN: $e');

      if (!mounted) return;

      setState(() => cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando inventario: $e')),
      );
    }
  }

  Future<void> _refrescar() async {
    setState(() => cargando = true);
    await cargarObjetos();
  }

  String _nombreEstado(dynamic idEstado) {
    return Estados.nombreEstadoObjeto(idEstado);
  }

  Color _estadoChipColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'disponible':
        return const Color(0xFF0A8F4D);
      case 'en custodia':
        return const Color(0xFF2563EB);
      case 'entregado':
        return const Color(0xFFD97706);
      case 'donado':
        return const Color(0xFF7C3AED);
      case 'desechado':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _estadoIcono(String estado) {
    switch (estado.toLowerCase()) {
      case 'disponible':
        return Icons.check_circle_outline_rounded;
      case 'en custodia':
        return Icons.inventory_2_outlined;
      case 'entregado':
        return Icons.handshake_outlined;
      case 'donado':
        return Icons.volunteer_activism_outlined;
      case 'desechado':
        return Icons.delete_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  bool _puedeOcultarPublicacion(Map<String, dynamic> objeto) {
    final idEstado = int.tryParse(
      (objeto['idEstado'] ?? objeto['id_estado'] ?? '').toString(),
    );

    final estado =
        (objeto['estado'] ?? _nombreEstado(idEstado)).toString().toLowerCase();

    return idEstado == Estados.objetoDisponible || estado == 'disponible';
  }

  Future<void> _ocultarPublicacion(Map<String, dynamic> objeto) async {
    final idObjeto = int.tryParse(
      (objeto['id'] ?? objeto['id_objeto'] ?? '').toString(),
    );

    if (idObjeto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de objeto inválido')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ocultar publicación'),
        content: const Text(
          '¿Seguro que quieres ocultar esta publicación? El objeto seguirá en el inventario, pero ya no aparecerá disponible para reclamos.',
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

    final ok = await ObjetoRepository.ocultarPublicacion(idObjeto);

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
      await _refrescar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = objetos.where((obj) {
      final nombre = (obj['nombre'] ?? '').toString().toLowerCase();
      final categoria =
          (obj['categoria'] ?? obj['tbl_categoria']?['nombre'] ?? '')
              .toString()
              .toLowerCase();
      final descripcion =
          (obj['descripcionGeneral'] ?? obj['descripcion_general'] ?? '')
              .toString()
              .toLowerCase();

      final texto = '$nombre $categoria $descripcion';
      return texto.contains(busqueda.toLowerCase());
    }).toList();

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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            total: filtrados.length,
                            onRefresh: _refrescar,
                          ),
                          const SizedBox(height: 18),
                          _Buscador(
                            onChanged: (value) {
                              setState(() => busqueda = value);
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
                                : filtrados.isEmpty
                                    ? const _EmptyState()
                                    : RefreshIndicator(
                                        color: const Color(0xFF0A8F4D),
                                        onRefresh: _refrescar,
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount: filtrados.length,
                                          itemBuilder: (context, index) {
                                            final objeto = filtrados[index];

                                            final estado = objeto['estado']
                                                    ?.toString() ??
                                                _nombreEstado(
                                                  objeto['idEstado'] ??
                                                      objeto['id_estado'],
                                                );

                                            return _ObjetoAdminCard(
                                              objeto: objeto,
                                              estado: estado,
                                              estadoColor:
                                                  _estadoChipColor(estado),
                                              estadoIcono:
                                                  _estadoIcono(estado),
                                              puedeOcultar:
                                                  _puedeOcultarPublicacion(
                                                objeto,
                                              ),
                                              onOcultar: () =>
                                                  _ocultarPublicacion(objeto),
                                            );
                                          },
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
                  'ADMIN · INVENTARIO',
                  style: TextStyle(
                    color: Color(0xFF0A8F4D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Inventario completo',
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
              border: Border.all(
                color: const Color(0xFF0A8F4D).withOpacity(0.22),
              ),
            ),
            child: Text(
              '$total objeto(s)',
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

class _Buscador extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _Buscador({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
        cursorColor: const Color(0xFF0A8F4D),
        decoration: InputDecoration(
          hintText: 'Buscar en el inventario...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ObjetoAdminCard extends StatelessWidget {
  final Map<String, dynamic> objeto;
  final String estado;
  final Color estadoColor;
  final IconData estadoIcono;
  final bool puedeOcultar;
  final VoidCallback onOcultar;

  const _ObjetoAdminCard({
    required this.objeto,
    required this.estado,
    required this.estadoColor,
    required this.estadoIcono,
    required this.puedeOcultar,
    required this.onOcultar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = (objeto['nombre'] ?? 'Sin nombre').toString();

    final descripcion =
        (objeto['descripcionGeneral'] ??
                objeto['descripcion_general'] ??
                'Sin descripción')
            .toString();

    final categoria =
        (objeto['categoria'] ?? objeto['tbl_categoria']?['nombre'] ?? 'Sin categoría')
            .toString();

    final fecha =
        (objeto['fechaHallazgo'] ?? objeto['fecha_hallazgo'] ?? '').toString();

    final lugarActual =
        (objeto['lugarActual'] ?? objeto['lugar_actual'] ?? 'No registrado')
            .toString();

    final lugarEncontrado =
        (objeto['lugarEncontrado'] ?? objeto['lugar_encontrado'] ?? '')
            .toString();

    final fotoUrl = (objeto['fotografia'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        final idObjeto = int.tryParse(
          (objeto['id'] ?? objeto['id_objeto'] ?? '').toString(),
        );

        if (idObjeto == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ObjetoDetailPage(idObjeto: idObjeto),
          ),
        );
      },
      child: _WhiteCard(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        borderColor: estadoColor.withOpacity(0.20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagenObjeto(url: fotoUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(
                        texto: estado,
                        color: estadoColor,
                        icono: estadoIcono,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _Badge(
                          texto: categoria,
                          color: const Color(0xFF2563EB),
                          icono: Icons.category_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (fecha.isNotEmpty)
                    _InfoLine(
                      icono: Icons.calendar_today_outlined,
                      texto: 'Hallado: $fecha',
                    ),
                  const SizedBox(height: 5),
                  _InfoLine(
                    icono: Icons.place_outlined,
                    texto: 'Ubicación actual: $lugarActual',
                  ),
                  if (lugarEncontrado.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _InfoLine(
                      icono: Icons.location_on_outlined,
                      texto: 'Encontrado en: $lugarEncontrado',
                    ),
                  ],
                  if (puedeOcultar) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOcultar,
                        icon: const Icon(Icons.visibility_off_outlined),
                        label: const Text('Ocultar publicación'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD97706),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagenObjeto extends StatelessWidget {
  final String url;

  const _ImagenObjeto({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0A8F4D).withOpacity(0.20),
        ),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF0A8F4D),
        size: 32,
      ),
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
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
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

class _InfoLine extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _InfoLine({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: const Color(0xFF6B7280), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
              Icons.inventory_2_outlined,
              color: Color(0xFF0A8F4D),
              size: 44,
            ),
            SizedBox(height: 14),
            Text(
              'No hay objetos en el inventario',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Registra objetos o actualiza la lista.',
              textAlign: TextAlign.center,
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