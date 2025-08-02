import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'admin/admin_home_page.dart';
import 'topo/topografo_home_page.dart';

const String supabaseUrl = 'https://ravcaucagfhfpxmhjznv.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJhdmNhdWNhZ2ZoZnB4bWhqem52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQwOTEwNDMsImV4cCI6MjA2OTY2NzA0M30.Z1GimsGjSkHgITG3-wAqTlXd7jQXPsK12q7ruu6jinI';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartPage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const LoginPage();

    // Trae el rol de la tabla users
    final userData = await Supabase.instance.client
        .from('users')
        .select('rol')
        .eq('id', user.id)
        .maybeSingle();

    final rol =
        userData?['rol'] ?? 'topografo'; // Por defecto topógrafo si no existe
    if (rol == 'admin') return const AdminHomePage();
    return const TopografoHomePage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mapeo Movil',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch:
            Colors.green, // <-- 1. CAMBIAMOS ESTO a un color que combine

        inputDecorationTheme: InputDecorationTheme(
          // Estilo para la etiqueta cuando flota arriba (al seleccionar el campo)
          floatingLabelStyle: const TextStyle(
            color: Colors.white,
          ), // <-- 2. AÑADIMOS ESTA LÍNEA
          // Estilo para la etiqueta en reposo
          labelStyle: const TextStyle(color: Colors.white70),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            // Aseguramos que el borde sea blanco y un poco más grueso al seleccionar
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amberAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.amberAccent, width: 2),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
