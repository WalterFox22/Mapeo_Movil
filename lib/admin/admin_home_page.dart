import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import '../mapeo/mapa_topografos_page.dart';
import '../mapeo/terrenos_page.dart';
import '../mapeo/tracking_page.dart';
import '../testeo/prueba_terreno_page.dart';
import '../mapeo/galeria_terrenos_page.dart'; // <--- Asegúrate de tener este archivo

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Administrador'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Galería de terrenos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GaleriaTerrenosPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Mapa de topógrafos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapaTopografosPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Ver terrenos guardados'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TerrenosPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Probar rastreo de ubicación'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrackingPageSimple()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.polyline),
              title: const Text('Polígono con topógrafos simulados'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PruebaTerrenoPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          '¡Bienvenido, ${user?.email ?? ''}!',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
