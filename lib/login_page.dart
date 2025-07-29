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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: emailController.text, password: passwordController.text);

      if (response.session != null) {
        final user = response.user;
        if (user != null) {
          // Chequea si ya existe en la tabla users
          final existing = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('id', user.id)
              .maybeSingle();

          String rol;
          if (existing == null) {
            // Asigna rol admin si el email coincide con uno especial, sino topografo
            rol = 'topografo';
            if (user.email == 'admin@admin.com') { // Cambia por el email real del admin
              rol = 'admin';
            }
            await Supabase.instance.client.from('users').insert({
              'id': user.id,
              'email': user.email,
              'rol': rol,
            });
          } else {
            // Consulta el rol si ya existe
            final datos = await Supabase.instance.client
                .from('users')
                .select('rol')
                .eq('id', user.id)
                .maybeSingle();
            rol = datos?['rol'] ?? 'topografo';
          }

          // Redirige según el rol
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
      } else {
        setState(() => error = 'Credenciales incorrectas');
      }
    } catch (e) {
      setState(() => error = 'Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Login Topógrafos', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 20),
              if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: loading ? null : login,
                child: loading ? const CircularProgressIndicator() : const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
