import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importa tus páginas de home personalizadas
import 'admin/admin_home_page.dart';
import 'topo/topografo_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); // Key para el formulario
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  bool _loading = false;
  String _error = '';
  bool _isPasswordObscured = true; // Estado para controlar la visibilidad del password

  // Tu lógica de login está perfecta, no la tocamos.
  // Solo renombramos las variables para que coincidan.
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return; // Valida el formulario

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: emailController.text.trim(), password: passwordController.text.trim());

      if (response.session != null) {
        final user = response.user;
        if (user != null) {
          final datos = await Supabase.instance.client
              .from('users')
              .select('rol')
              .eq('id', user.id)
              .maybeSingle();
          
          // La lógica de redirección se mantiene igual
          final rol = datos?['rol'] ?? 'topografo';

          if (!mounted) return;

          if (rol == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TopografoHomePage()),
            );
          }
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Ocurrió un error inesperado.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. FONDO CON GRADIENTE ATRACTIVO
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005A9C), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              // 2. TARJETA PARA EL FORMULARIO CON EFECTO FROSTY
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3. TÍTULO E ÍCONO ESTILIZADOS
                    const Icon(Icons.map_outlined, color: Colors.white, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'GeoMapper',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Bienvenido de nuevo',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),

                    // 4. CAMPO DE EMAIL MEJORADO
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        // ... más estilos
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Por favor, ingrese un email válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 5. CAMPO DE CONTRASEÑA CON "OJO"
                    TextFormField(
                      controller: passwordController,
                      obscureText: _isPasswordObscured,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                        // ... más estilos
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Muestra de error
                    if (_error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(_error, style: const TextStyle(color: Colors.amberAccent)),
                      ),
                      
                    // 6. BOTÓN DE LOGIN CON ESTILO Y ESTADO DE CARGA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32), // Verde bosque
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loading ? null : login,
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

