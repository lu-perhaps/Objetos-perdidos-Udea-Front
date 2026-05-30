import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'login_page.dart';
import 'home_admin_page.dart';
import 'home_usuario_page.dart';
import 'unauthorized_page.dart';
import 'completar_perfil_page.dart';
import '../Repositories/persona_repository.dart';
import '../services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        final user = supabase.auth.currentUser;
        final email = user?.email?.toLowerCase().trim() ?? '';

        if (session == null) return const LoginPage();

        if (!email.endsWith('@udea.edu.co')) {
          Future.microtask(() async => await supabase.auth.signOut());
          return const UnauthorizedPage();
        }

        return FutureBuilder<_DatosAcceso>(
          future: Future.microtask(() async {
            await PersonaRepository.crearSiNoExiste(user!);
            final rol = await AuthService.obtenerRol();
            final completo = await PersonaRepository.perfilCompleto();
            return _DatosAcceso(rol: rol, perfilCompleto: completo);
          }),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final datos = snap.data;

            if (datos == null || !datos.perfilCompleto) {
              return const CompletarPerfilPage();
            }

            if (datos.rol == 2) return const HomeAdminPage();
            return const HomeUsuarioPage();
          },
        );
      },
    );
  }
}

// ── Pantalla de carga estilizada ──────────────────────────────────────────────
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
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/udea_bg.jpeg', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Color(0xEE011208)],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: const SizedBox.expand(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A8F4D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A8F4D).withOpacity(0.5),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'UNIVERSIDAD DE ANTIOQUIA',
                  style: TextStyle(
                    color: Color(0xFF0A8F4D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Objetos Perdidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: const Color(0xFF0A8F4D).withOpacity(0.8),
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

// ── Clase auxiliar ────────────────────────────────────────────────────────────
class _DatosAcceso {
  final int? rol;
  final bool perfilCompleto;
  const _DatosAcceso({required this.rol, required this.perfilCompleto});
}