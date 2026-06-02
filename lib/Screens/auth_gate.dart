import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'login_page.dart';
import 'home_admin_page.dart';
import 'home_usuario_page.dart';
import 'unauthorized_page.dart';
import 'completar_perfil_page.dart';
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<_DatosAcceso>? _futureAcceso;
  String? _ultimoCorreo;

  Future<_DatosAcceso> _resolverAcceso(User user) async {
    final data = await AuthService.obtenerUsuarioActualBackend();

    if (data == null) {
      throw Exception('No se pudo conectar con el backend de autenticación.');
    }

    final rol = int.tryParse(data['idRol'].toString());
    final perfilCompleto = data['perfilCompleto'] == true;

    return _DatosAcceso(
      rol: rol,
      perfilCompleto: perfilCompleto,
    );
  }

  Future<void> _reintentar(User user) async {
    setState(() {
      _futureAcceso = _resolverAcceso(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        final user = supabase.auth.currentUser;
        final email = user?.email?.toLowerCase().trim() ?? '';

        if (session == null || user == null) {
          _futureAcceso = null;
          _ultimoCorreo = null;
          return const LoginPage();
        }

        if (!email.endsWith('@udea.edu.co')) {
          Future.microtask(() async => await supabase.auth.signOut());
          return const UnauthorizedPage();
        }

        if (_futureAcceso == null || _ultimoCorreo != email) {
          _ultimoCorreo = email;
          _futureAcceso = _resolverAcceso(user);
        }

        return FutureBuilder<_DatosAcceso>(
          future: _futureAcceso,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (snap.hasError) {
              return _ErrorBackendScreen(
                mensaje:
                    'No se pudo validar tu perfil con el backend. Verifica que el backend esté corriendo en localhost:8080.',
                onRetry: () => _reintentar(user),
              );
            }

            final datos = snap.data;

            if (datos == null) {
              return _ErrorBackendScreen(
                mensaje:
                    'No se pudo cargar tu información de acceso. Intenta nuevamente.',
                onRetry: () => _reintentar(user),
              );
            }

            if (!datos.perfilCompleto) {
              return const CompletarPerfilPage();
            }

            if (datos.rol == 2) {
              return const HomeAdminPage();
            }

            return const HomeUsuarioPage();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FondoInstitucional(
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A8F4D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'UNIVERSIDAD DE ANTIOQUIA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0A8F4D),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verificando acceso...',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              const CircularProgressIndicator(
                color: Color(0xFF0A8F4D),
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBackendScreen extends StatelessWidget {
  final String mensaje;
  final Future<void> Function() onRetry;

  const _ErrorBackendScreen({
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _FondoInstitucional(
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(26),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFDC2626),
                size: 42,
              ),
              const SizedBox(height: 18),
              const Text(
                'Error de conexión',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A8F4D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FondoInstitucional extends StatelessWidget {
  final Widget child;

  const _FondoInstitucional({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
            child: const SizedBox.expand(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.50),
                  Colors.black.withOpacity(0.35),
                  const Color(0xFF0A3D24).withOpacity(0.38),
                ],
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.94),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.75)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.22),
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
    ],
  );
}

class _DatosAcceso {
  final int? rol;
  final bool perfilCompleto;

  const _DatosAcceso({
    required this.rol,
    required this.perfilCompleto,
  });
}