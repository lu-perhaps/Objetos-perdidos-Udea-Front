import 'dart:ui';
import 'package:flutter/material.dart';

import '../Constants/app_colors.dart';
import '../Constants/estados.dart';
import '../Repositories/objeto_repository.dart';
import 'header_udea.dart';

class ObjetosVencidosPage extends StatefulWidget {
  const ObjetosVencidosPage({super.key});

  @override
  State<ObjetosVencidosPage> createState() => _ObjetosVencidosPageState();
}

class _ObjetosVencidosPageState extends State<ObjetosVencidosPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _objetos = [];
  bool _cargando = true;

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

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOut,
      ),
    );

    _animCtrl.forward();
    _cargarVencidos();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarVencidos() async {
    final data = await ObjetoRepository.obtenerObjetosVencidos();

    if (mounted) {
      setState(() {
        _objetos = data;
        _cargando = false;
      });
    }
  }

  Future<void> _refrescar() async {
    setState(() => _cargando = true);
    await _cargarVencidos();
  }

  int _diasAlmacenado(String? fechaStr) {
    if (fechaStr == null) return 0;

    final fecha = DateTime.tryParse(fechaStr);

    if (fecha == null) return 0;

    return DateTime.now().difference(fecha).inDays;
  }

  int _tiempoMax(Map<String, dynamic> obj) {
    return obj['tiempoMaximoAlmacenamiento'] as int? ??
        obj['tiempo_maximo_almacenamiento'] as int? ??
        obj['tbl_categoria']?['tiempo_maximo_almacenamiento'] as int? ??
        0;
  }

  Future<void> _mostrarDialogoDisposicion(
    Map<String, dynamic> obj,
    int nuevoEstado,
  ) async {
    final esDonacion = nuevoEstado == Estados.objetoDonado;

    final color = esDonacion ? const Color(0xFF7C3AED) : const Color(0xFFDC2626);

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                esDonacion
                    ? Icons.volunteer_activism
                    : Icons.delete_outline_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                esDonacion ? 'Marcar como donado' : 'Marcar como desecho',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objeto: ${obj['nombre'] ?? 'Sin nombre'}',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              esDonacion
                  ? 'El objeto será marcado como donado y dejará de estar disponible para reclamos.'
                  : 'El objeto será marcado como desecho y dejará de estar disponible para reclamos.',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              esDonacion ? 'Confirmar donación' : 'Confirmar desecho',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final exito = await ObjetoRepository.registrarDisposicionFinal(
      idObjeto: obj['id'] as int,
      nuevoEstado: nuevoEstado,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito
              ? (esDonacion
                  ? 'Objeto marcado como donado'
                  : 'Objeto marcado como desecho')
              : 'Error al actualizar el objeto',
        ),
        backgroundColor: exito ? color : const Color(0xFFDC2626),
      ),
    );

    if (exito) await _cargarVencidos();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 760;

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
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 26 : 22,
                        vertical: 18,
                      ),
                      child: Column(
                        children: [
                          _HeaderPage(
                            total: _objetos.length,
                            onRefresh: _refrescar,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ResumenCard(
                                  titulo: 'Objetos vencidos',
                                  valor: '${_objetos.length}',
                                  color: const Color(0xFFD97706),
                                  icono: Icons.hourglass_disabled_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ResumenCard(
                                  titulo: 'Acción requerida',
                                  valor: _objetos.isEmpty ? 'No' : 'Sí',
                                  color: _objetos.isEmpty
                                      ? const Color(0xFF0A8F4D)
                                      : const Color(0xFFDC2626),
                                  icono: _objetos.isEmpty
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.warning_amber_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _cargando
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.verde,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : _objetos.isEmpty
                                    ? RefreshIndicator(
                                        color: AppColors.verde,
                                        onRefresh: _refrescar,
                                        child: ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          children: const [
                                            SizedBox(height: 100),
                                            _EstadoVacio(),
                                          ],
                                        ),
                                      )
                                    : RefreshIndicator(
                                        color: AppColors.verde,
                                        onRefresh: _refrescar,
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount: _objetos.length,
                                          itemBuilder: (_, i) {
                                            final obj = _objetos[i];

                                            final dias = _diasAlmacenado(
                                              (obj['fechaHallazgo'] ??
                                                      obj['fecha_hallazgo'])
                                                  ?.toString(),
                                            );

                                            final tiempoMax = _tiempoMax(obj);
                                            final diasVencido = dias - tiempoMax;

                                            final fotoUrl =
                                                (obj['fotografia'] ?? '')
                                                    .toString();

                                            return _TarjetaVencido(
                                              obj: obj,
                                              fotoUrl: fotoUrl,
                                              dias: dias,
                                              tiempoMax: tiempoMax,
                                              diasVencido: diasVencido,
                                              onDonar: () =>
                                                  _mostrarDialogoDisposicion(
                                                obj,
                                                Estados.objetoDonado,
                                              ),
                                              onDesechar: () =>
                                                  _mostrarDialogoDisposicion(
                                                obj,
                                                Estados.objetoDesecho,
                                              ),
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

class _HeaderPage extends StatelessWidget {
  final int total;
  final Future<void> Function() onRefresh;

  const _HeaderPage({
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
            child: HeaderUdeaAdmin(
              titulo: 'Objetos vencidos',
              subtitulo: 'Disposición final',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFD97706).withOpacity(0.25),
              ),
            ),
            child: Text(
              '$total vencido(s)',
              style: const TextStyle(
                color: Color(0xFF92400E),
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

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withOpacity(0.18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaVencido extends StatelessWidget {
  final Map<String, dynamic> obj;
  final String fotoUrl;
  final int dias;
  final int tiempoMax;
  final int diasVencido;
  final VoidCallback onDonar;
  final VoidCallback onDesechar;

  const _TarjetaVencido({
    required this.obj,
    required this.fotoUrl,
    required this.dias,
    required this.tiempoMax,
    required this.diasVencido,
    required this.onDonar,
    required this.onDesechar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = (obj['nombre'] ?? 'Sin nombre').toString();

    final categoria =
        (obj['categoria'] ?? obj['tbl_categoria']?['nombre'] ?? 'Sin categoría')
            .toString();

    final lugarActual =
        (obj['lugarActual'] ?? obj['lugar_actual']?['nombre'] ?? 'Sin lugar')
            .toString();

    final diasVencidoSeguro = diasVencido < 0 ? 0 : diasVencido;

    return _WhiteCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      borderColor: const Color(0xFFD97706).withOpacity(0.25),
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
                      texto: 'Vencido',
                      color: const Color(0xFFD97706),
                      icono: Icons.hourglass_disabled_outlined,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      texto: '+$diasVencidoSeguro días',
                      color: const Color(0xFFDC2626),
                      icono: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                _InfoLine(
                  icono: Icons.category_outlined,
                  texto: categoria,
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  icono: Icons.timer_outlined,
                  texto: 'Límite: $tiempoMax días · Almacenado: $dias días',
                ),
                const SizedBox(height: 6),
                _InfoLine(
                  icono: Icons.location_on_outlined,
                  texto: 'Custodia: $lugarActual',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _BotonAccion(
                        icono: Icons.volunteer_activism,
                        texto: 'Donar',
                        color: const Color(0xFF7C3AED),
                        onTap: onDonar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BotonAccion(
                        icono: Icons.delete_outline_rounded,
                        texto: 'Desechar',
                        color: const Color(0xFFDC2626),
                        onTap: onDesechar,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenObjeto extends StatelessWidget {
  final String url;

  const _ImagenObjeto({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD97706).withOpacity(0.25),
        ),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFFD97706),
        size: 32,
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icono,
        color: Colors.white,
        size: 16,
      ),
      label: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
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
        Icon(
          icono,
          color: const Color(0xFF6B7280),
          size: 14,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            color: color,
            size: 12,
          ),
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

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.all(28),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF0A8F4D),
            size: 46,
          ),
          SizedBox(height: 14),
          Text(
            'Sin objetos vencidos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Todos los objetos están dentro del tiempo permitido de almacenamiento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
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