import 'dart:ui';
import 'package:flutter/material.dart';

import '../Constants/app_colors.dart';
import '../Repositories/persona_repository.dart';

class DirectorioPersonasPage extends StatefulWidget {
  const DirectorioPersonasPage({super.key});

  @override
  State<DirectorioPersonasPage> createState() => _DirectorioPersonasPageState();
}

class _DirectorioPersonasPageState extends State<DirectorioPersonasPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _todas = [];
  List<Map<String, dynamic>> _filtradas = [];
  bool _cargando = true;
  final _busquedaCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _cargarPersonas();
    _busquedaCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPersonas() async {
    try {
      final data = await PersonaRepository.obtenerEstudiantes();

      if (!mounted) return;

      setState(() {
        _todas = data;
        _filtradas = _todas;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR cargarPersonas API: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _filtrar() {
    final q = _busquedaCtrl.text.trim().toLowerCase();

    setState(() {
      _filtradas = q.isEmpty
          ? _todas
          : _todas.where((p) {
              final nombre = (p['nombre'] ?? '').toString().toLowerCase();
              final doc = (p['numDocumento'] ?? p['num_documento'] ?? '')
                  .toString()
                  .toLowerCase();
              final correo = (p['correo'] ?? '').toString().toLowerCase();
              final celular = (p['celular'] ?? '').toString().toLowerCase();

              return nombre.contains(q) ||
                  doc.contains(q) ||
                  correo.contains(q) ||
                  celular.contains(q);
            }).toList();
    });
  }

  Future<void> _refrescar() async {
    setState(() => _cargando = true);
    await _cargarPersonas();
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
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 28 : 20,
                        vertical: 18,
                      ),
                      child: Column(
                        children: [
                          _Header(
                            total: _filtradas.length,
                            onRefresh: _refrescar,
                          ),
                          const SizedBox(height: 22),
                          _Buscador(
                            ctrl: _busquedaCtrl,
                            onClear: () {
                              _busquedaCtrl.clear();
                              _filtrar();
                            },
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: _buildContenido()),
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

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.verde,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_filtradas.isEmpty) {
      return RefreshIndicator(
        color: AppColors.verde,
        onRefresh: _refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 110),
            Container(
              width: 86,
              height: 86,
              margin: const EdgeInsets.symmetric(horizontal: 420),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_outline,
                color: Color(0xFF0A8F4D),
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'No se encontraron usuarios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Intenta con otro nombre, documento o correo.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.verde,
      onRefresh: _refrescar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filtradas.length,
        itemBuilder: (_, i) => _TarjetaPersona(persona: _filtradas[i]),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF111827),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN · DIRECTORIO',
                  style: TextStyle(
                    color: Color(0xFF0A8F4D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Directorio de usuarios',
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
              border: Border.all(color: const Color(0xFF0A8F4D).withOpacity(0.22)),
            ),
            child: Text(
              '$total registro(s)',
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          InkWell(
            onTap: () async => onRefresh(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF6B7280),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Buscador extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onClear;

  const _Buscador({
    required this.ctrl,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: AppColors.verde,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, documento, correo o celular...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
            size: 20,
          ),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  onPressed: onClear,
                )
              : null,
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

class _TarjetaPersona extends StatefulWidget {
  final Map<String, dynamic> persona;

  const _TarjetaPersona({required this.persona});

  @override
  State<_TarjetaPersona> createState() => _TarjetaPersonaState();
}

class _TarjetaPersonaState extends State<_TarjetaPersona> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.persona;

    final nombre = (p['nombre'] ?? 'Sin nombre').toString();
    final correo = (p['correo'] ?? 'Sin correo').toString();
    final celular = (p['celular'] ?? 'No registrado').toString();

    final doc =
        (p['numDocumento'] ?? p['num_documento'] ?? 'No registrado').toString();

    final tipoDoc =
        (p['tipoDocumento'] ?? p['tbl_tipo_documento']?['nombre'] ?? '')
            .toString();

    final idEstado =
        int.tryParse((p['idEstado'] ?? p['id_estado'] ?? '').toString()) ?? -1;

    final estadoTexto = _estadoTexto(idEstado);
    final estadoColor = _estadoColor(idEstado);

    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    final colores = [
      const Color(0xFF0A8F4D),
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
      const Color(0xFF0891B2),
    ];

    final colorAvatar = colores[inicial.codeUnitAt(0) % colores.length];

    return GestureDetector(
      onTap: () => setState(() => _expandida = !_expandida),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expandida
                ? colorAvatar.withOpacity(0.32)
                : Colors.white.withOpacity(0.72),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorAvatar.withOpacity(0.13),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorAvatar.withOpacity(0.28),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      inicial,
                      style: TextStyle(
                        color: colorAvatar,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        correo,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (estadoTexto.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: estadoColor.withOpacity(0.28),
                      ),
                    ),
                    child: Text(
                      estadoTexto,
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                AnimatedRotation(
                  turns: _expandida ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6B7280),
                    size: 22,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _expandida
                  ? Column(
                      children: [
                        const SizedBox(height: 14),
                        const Divider(
                          color: Color(0xFFE5E7EB),
                          height: 1,
                        ),
                        const SizedBox(height: 14),
                        _FilaDetalle(
                          icono: Icons.phone_outlined,
                          label: 'Celular',
                          valor: celular,
                        ),
                        const SizedBox(height: 10),
                        _FilaDetalle(
                          icono: Icons.badge_outlined,
                          label: tipoDoc.isNotEmpty ? tipoDoc : 'Documento',
                          valor: doc,
                        ),
                        const SizedBox(height: 10),
                        _FilaDetalle(
                          icono: Icons.email_outlined,
                          label: 'Correo',
                          valor: correo,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _estadoTexto(int idEstado) {
    switch (idEstado) {
      case 4:
        return 'Activo';
      case 5:
        return 'Inactivo';
      default:
        return '';
    }
  }

  Color _estadoColor(int idEstado) {
    switch (idEstado) {
      case 4:
        return const Color(0xFF0A8F4D);
      case 5:
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _FilaDetalle({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: const Color(0xFF6B7280), size: 16),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}