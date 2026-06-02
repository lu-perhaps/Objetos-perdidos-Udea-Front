import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/api_config.dart';
import '../main.dart';

class SolicitudReclamoPage extends StatefulWidget {
  final Map<String, dynamic> objeto;

  const SolicitudReclamoPage({super.key, required this.objeto});

  @override
  State<SolicitudReclamoPage> createState() => _SolicitudReclamoPageState();
}

class _SolicitudReclamoPageState extends State<SolicitudReclamoPage> {
  final descripcionController = TextEditingController();
  final fechaController = TextEditingController();

  bool enviando = false;
  bool cargandoLugares = true;

  int? lugarSeleccionado;
  List<Map<String, dynamic>> lugares = [];

  DateTime? fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    cargarLugares();
  }

  @override
  void dispose() {
    descripcionController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  Future<void> cargarLugares() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/lugares'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error cargando lugares: ${response.statusCode}');
      }

      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        lugares = List<Map<String, dynamic>>.from(data);
        cargandoLugares = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargandoLugares = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando lugares: $e')),
      );
    }
  }

  Future<void> seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'CO'),
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
        fechaController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  String? fechaParaBackend() {
    if (fechaSeleccionada == null) return null;

    return '${fechaSeleccionada!.year}-'
        '${fechaSeleccionada!.month.toString().padLeft(2, '0')}-'
        '${fechaSeleccionada!.day.toString().padLeft(2, '0')}';
  }

  Future<void> enviarSolicitud() async {
    if (descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una descripción del objeto')),
      );
      return;
    }

    if (lugarSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un lugar aproximado')),
      );
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/solicitudes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'descripcion': descripcionController.text.trim(),
          'idObjeto': widget.objeto['id'],
          'correoUsuario': user.email!.toLowerCase().trim(),
          'idLugarAproxPerdida': lugarSeleccionado,
          'fechaAproxPerdida': fechaParaBackend(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Error del servidor: ${response.statusCode} - ${response.body}',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar solicitud: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreObjeto = (widget.objeto['nombre'] ?? 'Objeto').toString();
    final categoria = (widget.objeto['categoria'] ?? 'Objeto encontrado').toString();

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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(nombreObjeto: nombreObjeto),
                      const SizedBox(height: 26),
                      const Text(
                        'Solicitud de reclamo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ayúdanos a validar que este objeto realmente te pertenece.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(22),
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
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1F5EE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF0A8F4D),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombreObjeto,
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    categoria,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(22),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _LabelCampo(texto: 'DESCRIPCIÓN DEL OBJETO'),
                            const SizedBox(height: 7),
                            _CampoTexto(
                              controller: descripcionController,
                              hint:
                                  'Describe detalles que ayuden a verificar que el objeto es tuyo...',
                              icono: Icons.description_outlined,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 18),
                            const _LabelCampo(
                              texto: 'LUGAR APROXIMADO DE PÉRDIDA',
                            ),
                            const SizedBox(height: 7),
                            cargandoLugares
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF0A8F4D),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : _DropdownLugar(
                                    value: lugarSeleccionado,
                                    lugares: lugares,
                                    onChanged: (value) {
                                      setState(() {
                                        lugarSeleccionado = value;
                                      });
                                    },
                                  ),
                            const SizedBox(height: 18),
                            const _LabelCampo(
                              texto: 'FECHA APROXIMADA DE PÉRDIDA',
                            ),
                            const SizedBox(height: 7),
                            GestureDetector(
                              onTap: seleccionarFecha,
                              child: AbsorbPointer(
                                child: _CampoTexto(
                                  controller: fechaController,
                                  hint: 'Selecciona una fecha',
                                  icono: Icons.calendar_today_outlined,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: enviando ? null : enviarSolicitud,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8F4D),
                            disabledBackgroundColor:
                                const Color(0xFF0A8F4D).withOpacity(0.45),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: enviando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Enviar solicitud',
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
                            Icons.verified_user_outlined,
                            color: Colors.white70,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tu solicitud será revisada por un administrador',
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
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String nombreObjeto;

  const _Header({required this.nombreObjeto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
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
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECLAMO DE OBJETO',
                style: TextStyle(
                  color: Color(0xFF9EF0C0),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                nombreObjeto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icono;
  final int maxLines;

  const _CampoTexto({
    required this.controller,
    required this.hint,
    required this.icono,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: const Color(0xFF0A8F4D),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            top: maxLines > 1 ? 12 : 0,
          ),
          child: Icon(
            icono,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: Color(0xFF0A8F4D), width: 1.6),
        ),
      ),
    );
  }
}

class _DropdownLugar extends StatelessWidget {
  final int? value;
  final List<Map<String, dynamic>> lugares;
  final ValueChanged<int?> onChanged;

  const _DropdownLugar({
    required this.value,
    required this.lugares,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = lugares.any(
      (lugar) => int.tryParse(lugar['id'].toString()) == value,
    )
        ? value
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: validValue,
          dropdownColor: Colors.white,
          isExpanded: true,
          iconEnabledColor: const Color(0xFF6B7280),
          hint: const Text(
            'Selecciona un lugar',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          items: lugares.map((lugar) {
            return DropdownMenuItem<int>(
              value: int.tryParse(lugar['id'].toString()),
              child: Text(lugar['nombre'].toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}