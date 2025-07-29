import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'admin/admin_home_page.dart';
import 'topo/topografo_home_page.dart';
const String supabaseUrl = 'https://smgkcwgeyotbjujruzuj.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtZ2tjd2dleW90Ymp1anJ1enVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2MDY5MzQsImV4cCI6MjA2ODE4MjkzNH0.dl64I9eCBxnWajBy_s3rGMad5x03b40aVq8Rt5a7V-w'; // Reemplaza con tu clave

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
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

    final rol = userData?['rol'] ?? 'topografo'; // Por defecto topógrafo si no existe
    if (rol == 'admin') return const AdminHomePage();
    return const TopografoHomePage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rastreo Topógrafos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: FutureBuilder<Widget>(
        future: _getStartPage(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}