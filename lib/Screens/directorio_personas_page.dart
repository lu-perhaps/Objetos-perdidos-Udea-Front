import 'dart:ui';
import 'package:flutter/material.dart';
import '../Constants/app_colors.dart';
import '../main.dart';

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
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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
      final data = await supabase
          .from('tbl_persona')
          .select('''
            id, nombre, correo, celular,
            num_documento, id_rol,
            tbl_tipo_documento (nombre)
          ''')
          .eq('id_rol', 1)
          .order('nombre', ascending: true);

      setState(() {
        _todas = List<Map<String, dynamic>>.from(data);
        _filtradas = _todas;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('ERROR cargarPersonas: $e');
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
              final doc =
                  (p['num_documento'] ?? '').toString().toLowerCase();
              final correo = (p['correo'] ?? '').toString().toLowerCase();
              return nombre.contains(q) ||
                  doc.contains(q) ||
                  correo.contains(q);
            }).toList();
    });
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

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xBB000000), Color(0xEE011208)],
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),

          // ── Contenido ───────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? size.width * 0.22 : 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // ── Header ────────────────────────────────────
                      _Header(),

                      const SizedBox(height: 20),

                      // ── Buscador ──────────────────────────────────
                      _Buscador(ctrl: _busquedaCtrl, onClear: () {
                        _busquedaCtrl.clear();
                        _filtrar();
                      }),

                      const SizedBox(height: 10),

                      // ── Contador ──────────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            '${_filtradas.length} estudiante(s)',
                            key: ValueKey(_filtradas.length),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Lista ─────────────────────────────────────
                      Expanded(child: _buildContenido()),
                    ],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.white24,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron estudiantes',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta con otro nombre o documento',
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filtradas.length,
      itemBuilder: (_, i) => _TarjetaPersona(persona: _filtradas[i]),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
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
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Directorio de estudiantes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Buscador ──────────────────────────────────────────────────────────────────
class _Buscador extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onClear;

  const _Buscador({required this.ctrl, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: AppColors.verde,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, documento o correo...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Colors.white38, size: 20),
            suffixIcon: ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: Colors.white38, size: 18),
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.verde, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta persona ───────────────────────────────────────────────────────────
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
    final correo = (p['correo'] ?? '').toString();
    final celular = (p['celular'] ?? 'No registrado').toString();
    final doc = (p['num_documento'] ?? 'No registrado').toString();
    final tipoDoc = p['tbl_tipo_documento']?['nombre']?.toString() ?? '';
    final inicial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    // Color de avatar basado en inicial
    final colores = [
      const Color(0xFF0A8F4D),
      const Color(0xFF3A7BD5),
      const Color(0xFF8B5CF6),
      const Color(0xFFE07B2A),
      const Color(0xFF0891B2),
    ];
    final colorAvatar = colores[inicial.codeUnitAt(0) % colores.length];

    return GestureDetector(
      onTap: () => setState(() => _expandida = !_expandida),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _expandida
                      ? colorAvatar.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // ── Fila principal ──────────────────────────────
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorAvatar.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colorAvatar.withOpacity(0.5),
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            inicial,
                            style: TextStyle(
                              color: colorAvatar,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Nombre + correo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              correo,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Expandir
                      AnimatedRotation(
                        turns: _expandida ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white38,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  // ── Detalle expandido ──────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: _expandida
                        ? Column(
                            children: [
                              const SizedBox(height: 14),
                              Divider(
                                  color: Colors.white.withOpacity(0.08),
                                  height: 1),
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
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fila de detalle ───────────────────────────────────────────────────────────
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
        Icon(icono, color: Colors.white30, size: 16),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}