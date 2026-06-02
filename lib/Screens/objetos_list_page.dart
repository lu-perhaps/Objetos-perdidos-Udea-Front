import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/api_config.dart';
import '../Repositories/objeto_repository.dart';
import '../services/auth_service.dart';
import 'objeto_detail_page.dart';

class ObjetosListPage extends StatefulWidget {
  const ObjetosListPage({super.key});

  @override
  State<ObjetosListPage> createState() => _ObjetosListPageState();
}

class _ObjetosListPageState extends State<ObjetosListPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> objetos = [];
  bool cargando = true;
  bool _esAdmin = false;
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
    ).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );

    _animCtrl.forward();
    _verificarRol();
    cargarObjetos();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificarRol() async {
    final admin = await AuthService.esAdmin();
    if (mounted) {
      setState(() => _esAdmin = admin);
    }
  }

  Future<void> cargarObjetos() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/objetos'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        objetos = List<Map<String, dynamic>>.from(data);
        cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR CARGANDO OBJETOS DESDE BACKEND: $e');

      if (!mounted) return;

      setState(() => cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando objetos: $e')),
      );
    }
  }

  Future<void> _refrescar() async {
    setState(() => cargando = true);
    await cargarObjetos();
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 26 : 22,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            total: filtrados.length,
                            titulo: _esAdmin
                                ? 'Objetos publicados'
                                : 'Buscar objetos',
                            subtitulo: _esAdmin
                                ? 'Publicaciones visibles para estudiantes'
                                : 'Objetos encontrados en el campus',
                            onRefresh: _refrescar,
                          ),
                          const SizedBox(height: 20),
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

                                            return _ObjetoCard(
                                              objeto: objeto,
                                              esAdmin: _esAdmin,
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
  final String titulo;
  final String subtitulo;
  final Future<void> Function() onRefresh;

  const _Header({
    required this.total,
    required this.titulo,
    required this.subtitulo,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OBJETOS PERDIDOS',
                  style: TextStyle(
                    color: Color(0xFF0A8F4D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
              '$total',
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
          hintText: '¿Qué perdiste?',
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

class _ObjetoCard extends StatelessWidget {
  final Map<String, dynamic> objeto;
  final bool esAdmin;
  final VoidCallback onOcultar;

  const _ObjetoCard({
    required this.objeto,
    required this.esAdmin,
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
        (objeto['categoria'] ??
                objeto['tbl_categoria']?['nombre'] ??
                'Sin categoría')
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
        borderColor: const Color(0xFF0A8F4D).withOpacity(0.20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagenObjeto(url: fotoUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Badge(
                    texto: categoria,
                    color: const Color(0xFF0A8F4D),
                    icono: Icons.category_outlined,
                  ),
                  const SizedBox(height: 8),
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
                  if (esAdmin) ...[
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
                  ] else
                    const _InfoLine(
                      icono: Icons.lock_outline_rounded,
                      texto:
                          'Ubicación de custodia disponible solo si tu reclamo es aprobado',
                    ),
                  if (esAdmin) ...[
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
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 86,
      height: 86,
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
        size: 30,
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
              Icons.search_off_outlined,
              color: Color(0xFF0A8F4D),
              size: 44,
            ),
            SizedBox(height: 14),
            Text(
              'No hay objetos publicados',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Intenta actualizar o buscar con otro término.',
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