import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _cargando = false;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOut,
      ),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _cargando = true);

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:3000',
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/udea_bg.jpeg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0xBB021A0D),
                  Color(0xEE011208),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? size.width * 0.3 : 28,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _LogoLogin(),

                        const SizedBox(height: 26),

                        const Text(
                          'UNIVERSIDAD DE ANTIOQUIA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF0A8F4D),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Objetos Perdidos\n',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              TextSpan(
                                text: 'UdeA',
                                style: TextStyle(
                                  color: Color(0xFF0A8F4D),
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Conectamos a la comunidad para recuperar lo tuyo.\nIngresa con tu cuenta institucional.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 30,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              child: _BotonGoogle(
                                cargando: _cargando,
                                onTap: _signInWithGoogle,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: const Color(0xFF0A8F4D).withOpacity(0.85),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Acceso seguro con @udea.edu.co',
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
          ),
        ],
      ),
    );
  }
}

class _LogoLogin extends StatelessWidget {
  const _LogoLogin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFF0A8F4D).withOpacity(0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF0A8F4D).withOpacity(0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A8F4D).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.school_rounded,
        color: Color(0xFF0A8F4D),
        size: 36,
      ),
    );
  }
}

class _BotonGoogle extends StatelessWidget {
  final bool cargando;
  final VoidCallback onTap;

  const _BotonGoogle({
    required this.cargando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: cargando ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0A8F4D),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDB4437),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Iniciar sesión con Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}